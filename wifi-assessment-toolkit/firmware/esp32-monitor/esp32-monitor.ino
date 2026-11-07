// esp32-monitor — passive WiFi monitoring / blue-team firmware for ESP32
// -----------------------------------------------------------------------------
// FOR AUTHORIZED USE ONLY. Passive receive-only monitor for an environment you
// are authorized to observe (your own network, or a client site under contract).
// It TRANSMITS NOTHING. It channel-hops and listens, writing:
//
//   * posture.csv  — per-AP encryption / WPS / PMF (feeds analysis/posture_report.py)
//   * probe.csv    — client probe requests   (feeds analysis/probe_analysis.py)
//   * alerts.log   — deauth-flood and rogue-AP / evil-twin alerts
//   * wardrive.csv — optional, with a GPS module (see WARDRIVE_GPS below)
//
// Rogue-AP detection uses your scope.h as the "known good" list: if a scope SSID
// appears on a BSSID that is NOT in scope, that's a likely evil twin and it
// alerts. Deauth detection watches the rate of deauth/disassoc frames.
//
// Drive over USB serial (115200): help | status | posture | alerts | clear
// -----------------------------------------------------------------------------

#include <Arduino.h>
#include <WiFi.h>
#include <SD.h>
#include <SPI.h>
#include "esp_wifi.h"
#include "scope.h"

#ifndef SD_CS_PIN
#define SD_CS_PIN 5
#endif

// Set to 1 and wire a UART GPS (NMEA) to enable wardrive.csv logging.
#define WARDRIVE_GPS 0
#if WARDRIVE_GPS
#include <HardwareSerial.h>
static HardwareSerial GPS(2);          // UART2
static double g_lat = 0, g_lon = 0;
static bool   g_fix = false;
#endif

// ---- Channel hopping --------------------------------------------------------
static const uint8_t CHANNELS[] = {1, 6, 11, 2, 7, 3, 8, 4, 9, 5, 10};
static uint8_t g_chan_idx = 0;
static const uint32_t HOP_MS = 350;
static uint32_t g_last_hop = 0;

// ---- Deauth-flood detection -------------------------------------------------
static const uint32_t DEAUTH_WINDOW_MS = 5000;
static const uint32_t DEAUTH_ALERT_THRESHOLD = 20;   // deauth/disassoc per window
static uint32_t g_deauth_count = 0;
static uint32_t g_deauth_win_start = 0;

// ---- Seen-AP table (dedup posture + rogue detection) ------------------------
struct ApRec { uint8_t bssid[6]; char ssid[33]; uint8_t channel; bool logged; };
static const int MAX_APS = 96;
static ApRec g_aps[MAX_APS];
static int g_ap_count = 0;

static File g_posture, g_probe, g_alerts;
#if WARDRIVE_GPS
static File g_wardrive;
#endif

static bool mac_eq(const uint8_t* a, const uint8_t* b) { return memcmp(a, b, 6) == 0; }

static void mac_str(const uint8_t* m, char* out) {
  snprintf(out, 18, "%02X:%02X:%02X:%02X:%02X:%02X",
           m[0], m[1], m[2], m[3], m[4], m[5]);
}

static void alert(const String& s) {
  Serial.println("[ALERT] " + s);
  if (g_alerts) { g_alerts.println(String(millis()) + " " + s); g_alerts.flush(); }
}

// ---- Beacon / IE parsing ----------------------------------------------------
struct Posture { const char* enc; const char* wps; const char* pmf; };

static Posture parse_beacon(const uint8_t* p, int len, char* ssid_out) {
  Posture po = {"OPEN", "off", "unknown"};
  ssid_out[0] = 0;
  if (len < 36) return po;
  uint16_t cap = p[34] | (p[35] << 8);
  bool privacy = cap & (1 << 4);
  bool have_rsn = false, have_wpa = false, sae = false;

  int i = 36;                              // start of tagged params
  while (i + 2 <= len) {
    uint8_t id = p[i], ln = p[i + 1];
    const uint8_t* d = p + i + 2;
    if (i + 2 + ln > len) break;
    if (id == 0) {                         // SSID
      int n = ln < 32 ? ln : 32;
      memcpy(ssid_out, d, n); ssid_out[n] = 0;
    } else if (id == 48) {                 // RSN
      have_rsn = true;
      // AKM suite list: skip version(2) + group cipher(4) + pairwise count(2)+list
      if (ln >= 8) {
        int off = 2 + 4;
        uint16_t pc = d[off] | (d[off + 1] << 8); off += 2 + 4 * pc;
        if (off + 2 <= ln) {
          uint16_t akmc = d[off] | (d[off + 1] << 8); int akm_off = off + 2;
          for (uint16_t k = 0; k < akmc && akm_off + 4 <= ln; k++, akm_off += 4)
            if (d[akm_off + 3] == 8) sae = true;       // AKM 00-0F-AC-08 = SAE (WPA3)
          off = akm_off;
          if (off + 2 <= ln) {                          // RSN capabilities
            uint16_t rsncap = d[off] | (d[off + 1] << 8);
            if (rsncap & 0x0040) po.pmf = "required";
            else if (rsncap & 0x0080) po.pmf = "capable";
            else po.pmf = "off";
          }
        }
      }
    } else if (id == 221 && ln >= 4) {     // vendor specific
      if (d[0] == 0x00 && d[1] == 0x50 && d[2] == 0xF2) {
        if (d[3] == 0x01) have_wpa = true; // WPA IE
        if (d[3] == 0x04) po.wps = "on";   // WPS IE
      }
    }
    i += 2 + ln;
  }

  if (have_rsn)      po.enc = sae ? "WPA3" : "WPA2";
  else if (have_wpa) po.enc = "WPA";
  else if (privacy)  po.enc = "WEP";
  else               po.enc = "OPEN";
  return po;
}

static bool ssid_in_scope(const char* ssid) {
  for (int j = 0; j < SCOPE_TARGET_COUNT; j++)
    if (strcmp(ssid, SCOPE_TARGETS[j].ssid) == 0) return true;
  return false;
}
static bool bssid_in_scope(const uint8_t* b) {
  for (int j = 0; j < SCOPE_TARGET_COUNT; j++)
    if (mac_eq(b, SCOPE_TARGETS[j].bssid)) return true;
  return false;
}

static void record_ap(const uint8_t* bssid, const char* ssid, uint8_t ch,
                      const Posture& po, int8_t rssi) {
  // Evil-twin heuristic: a scope SSID on a non-scope BSSID.
  if (ssid[0] && ssid_in_scope(ssid) && !bssid_in_scope(bssid)) {
    char b[18]; mac_str(bssid, b);
    alert(String("Possible EVIL TWIN: scope SSID '") + ssid +
          "' on unlisted BSSID " + b + " ch" + ch);
  }

  // Dedup + write posture once per BSSID.
  for (int i = 0; i < g_ap_count; i++)
    if (mac_eq(g_aps[i].bssid, bssid)) return;
  if (g_ap_count < MAX_APS) {
    ApRec& r = g_aps[g_ap_count++];
    memcpy(r.bssid, bssid, 6); strncpy(r.ssid, ssid, 32); r.ssid[32] = 0;
    r.channel = ch; r.logged = true;
    char b[18]; mac_str(bssid, b);
    if (g_posture) {
      g_posture.printf("%lu,%s,%s,%u,%d,%s,%s,%s,2.4GHz\n",
                       millis(), b, ssid, ch, rssi, po.enc, po.wps, po.pmf);
      g_posture.flush();
    }
    Serial.printf("[AP] %s ch%u %s wps=%s pmf=%s  %s\n",
                  b, ch, po.enc, po.wps, po.pmf, ssid);
#if WARDRIVE_GPS
    if (g_wardrive) {
      g_wardrive.printf("%lu,%s,%s,%u,%d,%s,%.6f,%.6f\n",
                        millis(), b, ssid, ch, rssi, po.enc,
                        g_fix ? g_lat : 0.0, g_fix ? g_lon : 0.0);
      g_wardrive.flush();
    }
#endif
  }
}

// ---- Promiscuous RX ---------------------------------------------------------
static void IRAM_ATTR rx_cb(void* buf, wifi_promiscuous_pkt_type_t type) {
  const wifi_promiscuous_pkt_t* pkt = (wifi_promiscuous_pkt_t*)buf;
  const uint8_t* p = pkt->payload;
  int len = pkt->rx_ctrl.sig_len;
  if (len < 24) return;
  uint8_t ftype = (p[0] >> 2) & 0x3;
  uint8_t subtype = (p[0] >> 4) & 0xF;

  if (ftype == 0x0) {                       // management
    if (subtype == 0x8) {                   // beacon
      char ssid[33];
      Posture po = parse_beacon(p, len, ssid);
      record_ap(p + 16 /*addr3=BSSID*/, ssid, CHANNELS[g_chan_idx],
                po, pkt->rx_ctrl.rssi);
    } else if (subtype == 0x4) {            // probe request
      if (g_probe) {
        char cm[18]; mac_str(p + 10, cm);   // addr2 = client
        char ssid[33] = {0};
        if (len >= 26 && p[24] == 0) {      // SSID IE first
          int ln = p[25]; if (ln > 32) ln = 32;
          if (26 + ln <= len) { memcpy(ssid, p + 26, ln); ssid[ln] = 0; }
        }
        g_probe.printf("%lu,%s,%s,%d\n", millis(), cm, ssid, pkt->rx_ctrl.rssi);
        g_probe.flush();
      }
    } else if (subtype == 0xC || subtype == 0xA) {  // deauth / disassoc
      uint32_t now = millis();
      if (now - g_deauth_win_start > DEAUTH_WINDOW_MS) {
        g_deauth_win_start = now; g_deauth_count = 0;
      }
      if (++g_deauth_count == DEAUTH_ALERT_THRESHOLD)
        alert(String("Deauth/disassoc flood: ") + g_deauth_count +
              " frames in " + (DEAUTH_WINDOW_MS / 1000) + "s (possible attack)");
    }
  }
}

// ---- GPS (optional) ---------------------------------------------------------
#if WARDRIVE_GPS
static void poll_gps() {
  static char line[100]; static int idx = 0;
  while (GPS.available()) {
    char c = GPS.read();
    if (c == '\n') {
      line[idx] = 0; idx = 0;
      if (!strncmp(line, "$GPGGA", 6) || !strncmp(line, "$GNGGA", 6)) {
        // Minimal GGA parse: fields lat, N/S, lon, E/W at positions 2..5
        char* f[15]; int nf = 0; char* t = strtok(line, ",");
        while (t && nf < 15) { f[nf++] = t; t = strtok(NULL, ","); }
        if (nf > 6 && strlen(f[2]) > 0 && atoi(f[6]) > 0) {
          double lat = atof(f[2]); int d = (int)(lat / 100);
          g_lat = d + (lat - d * 100) / 60.0; if (f[3][0] == 'S') g_lat = -g_lat;
          double lon = atof(f[4]); d = (int)(lon / 100);
          g_lon = d + (lon - d * 100) / 60.0; if (f[5][0] == 'W') g_lon = -g_lon;
          g_fix = true;
        } else g_fix = false;
      }
    } else if (idx < (int)sizeof(line) - 1) line[idx++] = c;
  }
}
#endif

// ---- Serial commands --------------------------------------------------------
static void handle_cmd(String c) {
  c.trim();
  if (c == "help")
    Serial.println("help | status | posture | alerts | clear");
  else if (c == "status")
    Serial.printf("[*] APs seen: %d  ch: %u  deauth(window): %lu\n",
                  g_ap_count, CHANNELS[g_chan_idx], g_deauth_count);
  else if (c == "posture") {
    for (int i = 0; i < g_ap_count; i++) {
      char b[18]; mac_str(g_aps[i].bssid, b);
      Serial.printf("  %s ch%u  %s\n", b, g_aps[i].channel, g_aps[i].ssid);
    }
  } else if (c == "alerts") {
    Serial.println("[*] See alerts.log on SD for the full record.");
  } else if (c == "clear") {
    g_ap_count = 0; Serial.println("[*] AP table cleared.");
  } else if (c.length())
    Serial.println("[!] Unknown. 'help'.");
}

void setup() {
  Serial.begin(115200);
  delay(300);
  Serial.println("== esp32-monitor (PASSIVE / AUTHORIZED USE ONLY) ==");
  Serial.printf("Scope: %d known-good target(s) for evil-twin detection\n",
                SCOPE_TARGET_COUNT);

  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  esp_wifi_set_promiscuous(false);

  if (!SD.begin(SD_CS_PIN)) {
    Serial.println("[!] SD init failed — logs cannot be saved. Fix SD_CS_PIN.");
  } else {
    bool newp = !SD.exists("/posture.csv");
    g_posture = SD.open("/posture.csv", FILE_APPEND);
    if (newp && g_posture)
      g_posture.println("timestamp,bssid,ssid,channel,rssi,encryption,wps,pmf,band");
    bool newq = !SD.exists("/probe.csv");
    g_probe = SD.open("/probe.csv", FILE_APPEND);
    if (newq && g_probe) g_probe.println("timestamp,client_mac,ssid,rssi");
    g_alerts = SD.open("/alerts.log", FILE_APPEND);
#if WARDRIVE_GPS
    bool neww = !SD.exists("/wardrive.csv");
    g_wardrive = SD.open("/wardrive.csv", FILE_APPEND);
    if (neww && g_wardrive)
      g_wardrive.println("timestamp,bssid,ssid,channel,rssi,encryption,lat,lon");
    GPS.begin(9600, SERIAL_8N1, 16, 17);   // adjust RX/TX pins for your GPS
#endif
    Serial.println("[*] SD ready. Logging posture.csv / probe.csv / alerts.log");
  }

  wifi_promiscuous_filter_t filt = { .filter_mask = WIFI_PROMIS_FILTER_MASK_ALL };
  esp_wifi_set_promiscuous_filter(&filt);
  esp_wifi_set_promiscuous_rx_cb(&rx_cb);
  esp_wifi_set_promiscuous(true);
  esp_wifi_set_channel(CHANNELS[0], WIFI_SECOND_CHAN_NONE);
  g_deauth_win_start = millis();
  Serial.println("[*] Monitoring. Type 'help'.");
}

void loop() {
  uint32_t now = millis();
  if (now - g_last_hop > HOP_MS) {
    g_last_hop = now;
    g_chan_idx = (g_chan_idx + 1) % (sizeof(CHANNELS) / sizeof(CHANNELS[0]));
    esp_wifi_set_channel(CHANNELS[g_chan_idx], WIFI_SECOND_CHAN_NONE);
  }
#if WARDRIVE_GPS
  poll_gps();
#endif
  static String line;
  while (Serial.available()) {
    char ch = Serial.read();
    if (ch == '\n' || ch == '\r') { if (line.length()) { handle_cmd(line); line = ""; } }
    else line += ch;
  }
  delay(2);
}
