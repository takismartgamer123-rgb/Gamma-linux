#include "panel.h"


RocketPanel *
rocket_panel_create(void)
{
    RocketPanel *panel = calloc(1, sizeof(RocketPanel));

    if (!panel)
        return NULL;


    panel->win = elm_win_add(
        NULL,
        "rocketenment-panel",
        ELM_WIN_DOCK
    );


    elm_win_borderless_set(
        panel->win,
        EINA_TRUE
    );


    elm_win_alpha_set(
        panel->win,
        EINA_TRUE
    );


    elm_win_autodel_set(
        panel->win,
        EINA_TRUE
    );


    Ecore_Evas *ee;

int w, h;

ee = ecore_evas_new(
    NULL,
    0,
    0,
    0,
    0,
    NULL
);

if (ee)
{
    ecore_evas_screen_geometry_get(
        ee,
        NULL,
        NULL,
        &w,
        &h
    );

    ecore_evas_free(ee);

    evas_object_resize(
        panel->win,
        w,
        42
    );
}


    evas_object_move(
        panel->win,
        0,
        0
    );



    panel->box = elm_box_add(
        panel->win
    );


    elm_box_horizontal_set(
        panel->box,
        EINA_TRUE
    );


    elm_box_padding_set(
        panel->box,
        15,
        0
    );


    elm_win_resize_object_add(
        panel->win,
        panel->box
    );



    panel->title = elm_label_add(
        panel->win
    );


    elm_object_text_set(
        panel->title,
        "<font_size=18><color=#55aaff>Γ</color> Gamma</font_size>"
    );


    elm_box_pack_end(
        panel->box,
        panel->title
    );


    evas_object_show(
        panel->title
    );



    panel->clock = elm_label_add(
        panel->win
    );


    elm_object_text_set(
        panel->clock,
        "00:00"
    );


    elm_box_pack_end(
        panel->box,
        panel->clock
    );


    evas_object_show(
        panel->clock
    );



    panel->network = elm_label_add(
        panel->win
    );


    elm_object_text_set(
        panel->network,
        "🌐"
    );


    elm_box_pack_end(
        panel->box,
        panel->network
    );


    evas_object_show(
        panel->network
    );



    panel->sound = elm_label_add(
        panel->win
    );


    elm_object_text_set(
        panel->sound,
        "🔊"
    );


    elm_box_pack_end(
        panel->box,
        panel->sound
    );


    evas_object_show(
        panel->sound
    );



    panel->battery = elm_label_add(
        panel->win
    );


    elm_object_text_set(
        panel->battery,
        "🔋"
    );


    elm_box_pack_end(
        panel->box,
        panel->battery
    );


    evas_object_show(
        panel->battery
    );



    evas_object_show(
        panel->box
    );


    return panel;
}



void
rocket_panel_show(RocketPanel *panel)
{
    if (!panel)
        return;


    evas_object_show(
        panel->win
    );
}



void
rocket_panel_destroy(RocketPanel *panel)
{
    if (!panel)
        return;


    if (panel->win)
        evas_object_del(
            panel->win
        );


    free(panel);
}
