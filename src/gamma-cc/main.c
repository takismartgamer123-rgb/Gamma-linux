#include <Eina.h>
#include <Evas.h>
#include <Elementary.h>
#include <Ecore.h>
#include <string.h>


static Evas_Object *win = NULL;

static Eina_Bool ctrl_left = EINA_FALSE;
static Eina_Bool ctrl_right = EINA_FALSE;



static void
_btn_clicked(void *data, Evas_Object *obj, void *event_info)
{
    const char *cmd = data;

    if (cmd)
        ecore_exe_run(cmd, NULL);

    if (win)
        evas_object_hide(win);
}



static void
_show_cc(void)
{
    if (win)
    {
        evas_object_show(win);
        elm_win_raise(win);
    }
}



static Eina_Bool
_key_down(void *data, int type, void *event)
{
    Ecore_Event_Key *ev = event;


    if (!ev || !ev->key)
        return ECORE_CALLBACK_PASS_ON;



    if (!strcmp(ev->key, "Control_L"))
        ctrl_left = EINA_TRUE;



    if (!strcmp(ev->key, "Control_R"))
        ctrl_right = EINA_TRUE;



    if (ctrl_left && ctrl_right)
    {
        _show_cc();

        return ECORE_CALLBACK_CANCEL;
    }


    return ECORE_CALLBACK_PASS_ON;
}




static Eina_Bool
_key_up(void *data, int type, void *event)
{
    Ecore_Event_Key *ev = event;


    if (!ev || !ev->key)
        return ECORE_CALLBACK_PASS_ON;



    if (!strcmp(ev->key, "Control_L"))
        ctrl_left = EINA_FALSE;



    if (!strcmp(ev->key, "Control_R"))
        ctrl_right = EINA_FALSE;



    return ECORE_CALLBACK_PASS_ON;
}





int
main(int argc, char **argv)
{
    elm_init(argc, argv);



    win = elm_win_util_standard_add(
        "gamma-cc",
        "Gamma Control Center"
    );


    if (!win)
        return 1;



    elm_win_alpha_set(win, EINA_TRUE);
    elm_win_borderless_set(win, EINA_TRUE);



    evas_object_resize(win, 600, 300);
    evas_object_move(win, 200, 400);




    Evas_Object *bg = elm_bg_add(win);


    elm_bg_color_set(
        bg,
        20,
        20,
        20
    );


    elm_win_resize_object_add(
        win,
        bg
    );


    evas_object_show(bg);




    Evas_Object *box = elm_box_add(win);


    elm_box_horizontal_set(
        box,
        EINA_TRUE
    );


    elm_win_resize_object_add(
        win,
        box
    );





    Evas_Object *btn = elm_button_add(win);


    elm_object_text_set(
        btn,
        "PERFORMANCE MODE"
    );



    evas_object_smart_callback_add(
        btn,
        "clicked",
        _btn_clicked,
        "pkexec gamma-cc --perf"
    );



    elm_box_pack_end(
        box,
        btn
    );


    evas_object_show(btn);
    evas_object_show(box);



    evas_object_hide(win);




    ecore_event_handler_add(
        ECORE_EVENT_KEY_DOWN,
        _key_down,
        NULL
    );


    ecore_event_handler_add(
        ECORE_EVENT_KEY_UP,
        _key_up,
        NULL
    );



    elm_run();


    elm_shutdown();


    return 0;
}
