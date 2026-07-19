#include <Eina.h>
#include <Evas.h>
#include <Elementary.h>
#include <Ecore.h>
#include <string.h>

Evas_Object *win;

static void _btn_clicked(void *data, Evas_Object *obj, void *event_info) {
   ecore_exe_run(data, NULL); 
   elm_win_lower(win);
}

static Eina_Bool _key_down(void *data, int type, void *event) {
   Ecore_Event_Key *ev = event;
   if(!strcmp(ev->key, "Control_L")||!strcmp(ev->key, "Control_R")){
      elm_win_raise(win); 
      evas_object_show(win); 
      return ECORE_CALLBACK_CANCEL;
   }
   return ECORE_CALLBACK_PASS_ON;
}

int main(int argc, char **argv){
   elm_init(argc, argv);
   win = elm_win_util_standard_add("gamma-cc", "Gamma CC");
   elm_win_alpha_set(win, EINA_TRUE); 
   elm_win_borderless_set(win, EINA_TRUE);
   evas_object_resize(win, 600, 300); 
   evas_object_move(win, 200, 400);
   
   Evas_Object *bg = elm_bg_add(win); 
   elm_bg_color_set(bg, 20, 20, 20); 
   elm_bg_alpha_set(bg, 180);
   elm_win_resize_object_add(win, bg); 
   evas_object_show(bg);
   
   Evas_Object *box = elm_box_add(win); 
   elm_box_horizontal_set(box, EINA_TRUE);
   elm_win_resize_object_add(win, box);
   
   Evas_Object *btn1 = elm_button_add(win); 
   elm_object_text_set(btn1, "⚡ PERFORMANCE"); 
   evas_object_smart_callback_add(btn1, "clicked", _btn_clicked, "pkexec gamma-cc --perf"); 
   elm_box_pack_end(box, btn1); 
   evas_object_show(btn1);
   
   evas_object_show(box); 
   evas_object_hide(win);
   ecore_event_handler_add(ECORE_EVENT_KEY_DOWN, _key_down, NULL);
   elm_run(); 
   elm_shutdown(); 
   return 0;
}
