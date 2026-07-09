// C5 Max touchscreen UI — WiFi assessment front-end (LVGL)
// -----------------------------------------------------------------------------
// FOR AUTHORIZED USE ONLY. Drives the same scope-enforced capture backend as
// firmware/esp32-recon: it can only act on in-scope BSSIDs (scope.h).
//
// This file is the on-screen UI. It calls a small backend API (below) which you
// compile from the esp32-recon capture logic — see touchui/c5max/README.md for
// how to wire the two together and how to set up TFT_eSPI + LVGL for your panel.
// -----------------------------------------------------------------------------

#include <Arduino.h>
#include <lvgl.h>
#include <TFT_eSPI.h>
#include "scope.h"   // the SAME generated scope allowlist used by esp32-recon

// ---- Backend API (implemented in the esp32-recon-derived backend .cpp) ------
// These are the only actions the UI can trigger; every one is scope-enforced.
extern void        backend_begin();
extern int         backend_scan_count();       // run a passive scan, return APs
extern const char* backend_scan_line(int i);   // formatted line for AP i
extern void        backend_select_target(int idx);
extern void        backend_start_pmkid();       // clientless, no deauth
extern void        backend_start_handshake();   // deauth only if scope allows
extern void        backend_stop();
extern const char* backend_status_line();       // frames / M1..M4 / PMKID
extern bool        backend_capturing();

// ---- Display / touch glue (configure for your C5 Max panel) -----------------
static TFT_eSPI tft = TFT_eSPI();
static const uint16_t SCR_W = 480, SCR_H = 480;   // adjust to your panel
static lv_disp_draw_buf_t draw_buf;
static lv_color_t buf1[SCR_W * 10];

static void disp_flush(lv_disp_drv_t* d, const lv_area_t* a, lv_color_t* px) {
  uint32_t w = a->x2 - a->x1 + 1, h = a->y2 - a->y1 + 1;
  tft.startWrite();
  tft.setAddrWindow(a->x1, a->y1, w, h);
  tft.pushColors((uint16_t*)px, w * h, true);
  tft.endWrite();
  lv_disp_flush_ready(d);
}

// TODO: replace with your touch controller read (GT911 / FT6236 / XPT2046 ...).
extern bool touch_read(uint16_t* x, uint16_t* y);   // implement for your panel
static void touch_cb(lv_indev_drv_t* drv, lv_indev_data_t* data) {
  uint16_t x, y;
  if (touch_read(&x, &y)) { data->state = LV_INDEV_STATE_PR; data->point.x = x; data->point.y = y; }
  else data->state = LV_INDEV_STATE_REL;
}

// ---- UI widgets -------------------------------------------------------------
static lv_obj_t* status_label;
static lv_obj_t* target_dd;      // dropdown of in-scope targets
static lv_obj_t* scan_list;
static lv_timer_t* status_timer;

static void refresh_status(lv_timer_t*) {
  lv_label_set_text(status_label, backend_status_line());
}

static void ev_scan(lv_event_t*) {
  lv_obj_clean(scan_list);
  int n = backend_scan_count();
  for (int i = 0; i < n; i++)
    lv_list_add_text(scan_list, backend_scan_line(i));
  lv_label_set_text(status_label, "Scan complete");
}

static void ev_select(lv_event_t* e) {
  int idx = lv_dropdown_get_selected((lv_obj_t*)lv_event_get_target(e));
  backend_select_target(idx);
  lv_label_set_text_fmt(status_label, "Target: %s", SCOPE_TARGETS[idx].ssid);
}

static void ev_pmkid(lv_event_t*)     { backend_start_pmkid();     }
static void ev_handshake(lv_event_t*) { backend_start_handshake(); }
static void ev_stop(lv_event_t*)      { backend_stop();            }

static lv_obj_t* mk_btn(lv_obj_t* parent, const char* txt, lv_event_cb_t cb,
                        lv_coord_t x, lv_coord_t y, lv_color_t color) {
  lv_obj_t* b = lv_btn_create(parent);
  lv_obj_set_size(b, 150, 56);
  lv_obj_set_pos(b, x, y);
  lv_obj_set_style_bg_color(b, color, 0);
  lv_obj_add_event_cb(b, cb, LV_EVENT_CLICKED, NULL);
  lv_obj_t* l = lv_label_create(b);
  lv_label_set_text(l, txt);
  lv_obj_center(l);
  return b;
}

static void build_ui() {
  lv_obj_t* scr = lv_scr_act();
  lv_obj_set_style_bg_color(scr, lv_color_hex(0x101418), 0);

  lv_obj_t* title = lv_label_create(scr);
  lv_label_set_text(title, "WiFi Assessment  -  AUTHORIZED USE ONLY");
  lv_obj_set_style_text_color(title, lv_color_hex(0x9fd3ff), 0);
  lv_obj_set_pos(title, 12, 8);

  // In-scope target dropdown (built from the compiled allowlist).
  target_dd = lv_dropdown_create(scr);
  String opts;
  for (int i = 0; i < SCOPE_TARGET_COUNT; i++) {
    opts += SCOPE_TARGETS[i].ssid;
    if (i < SCOPE_TARGET_COUNT - 1) opts += "\n";
  }
  lv_dropdown_set_options(target_dd, opts.c_str());
  lv_obj_set_pos(target_dd, 12, 40);
  lv_obj_set_width(target_dd, 456);
  lv_obj_add_event_cb(target_dd, ev_select, LV_EVENT_VALUE_CHANGED, NULL);
  backend_select_target(0);

  mk_btn(scr, "Scan",       ev_scan,      12,  100, lv_color_hex(0x2d6cdf));
  mk_btn(scr, "PMKID",      ev_pmkid,     170, 100, lv_color_hex(0x2e9e5b));
  mk_btn(scr, "Handshake",  ev_handshake, 328, 100, lv_color_hex(0xb8862b));
  mk_btn(scr, "Stop",       ev_stop,      12,  164, lv_color_hex(0xb0403a));

  status_label = lv_label_create(scr);
  lv_obj_set_style_text_color(status_label, lv_color_hex(0xd0d6dc), 0);
  lv_obj_set_pos(status_label, 170, 176);
  lv_label_set_text(status_label, "Ready. Select an in-scope target.");

  scan_list = lv_list_create(scr);
  lv_obj_set_size(scan_list, 456, 240);
  lv_obj_set_pos(scan_list, 12, 228);

  status_timer = lv_timer_create(refresh_status, 700, NULL);
}

void setup() {
  Serial.begin(115200);
  lv_init();
  tft.begin();
  tft.setRotation(0);
  lv_disp_draw_buf_init(&draw_buf, buf1, NULL, SCR_W * 10);

  static lv_disp_drv_t ddrv; lv_disp_drv_init(&ddrv);
  ddrv.hor_res = SCR_W; ddrv.ver_res = SCR_H;
  ddrv.flush_cb = disp_flush; ddrv.draw_buf = &draw_buf;
  lv_disp_drv_register(&ddrv);

  static lv_indev_drv_t idrv; lv_indev_drv_init(&idrv);
  idrv.type = LV_INDEV_TYPE_POINTER; idrv.read_cb = touch_cb;
  lv_indev_drv_register(&idrv);

  backend_begin();     // SD, WiFi STA, scope banner
  build_ui();
}

void loop() {
  lv_timer_handler();
  delay(5);
}
