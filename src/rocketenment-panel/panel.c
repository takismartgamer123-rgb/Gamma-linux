#include "panel.h"

#include <stdlib.h>


RocketPanel *
rocket_panel_create(void)
{
    RocketPanel *panel;

    panel = calloc(
        1,
        sizeof(RocketPanel)
    );

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


    evas_object_move(
        panel->win,
        0,
        0
    );


    evas_object_resize(
        panel->win,
        1920,
        42
    );



    /*
     * Background
     */

    panel->bg = elm_bg_add(
        panel->win
    );


    elm_bg_color_set(
        panel->bg,
        10,
        20,
        45
    );


    elm_win_resize_object_add(
        panel->win,
        panel->bg
    );


    evas_object_show(
        panel->bg
    );



    /*
     * Main container
     */

    panel->main_box = elm_box_add(
        panel->win
    );


    elm_box_horizontal_set(
        panel->main_box,
        EINA_TRUE
    );


    elm_box_padding_set(
        panel->main_box,
        20,
        0
    );


    elm_win_resize_object_add(
        panel->win,
        panel->main_box
    );



    /*
     * Left side
     */

    panel->left_box = elm_box_add(
        panel->win
    );


    elm_box_horizontal_set(
        panel->left_box,
        EINA_TRUE
    );


    panel->title = elm_label_add(
        panel->win
    );


    elm_object_text_set(
        panel->title,
        "<font_size=18><color=#55aaff>Γ</color> Gamma</font_size>"
    );


    elm_box_pack_end(
        panel->left_box,
        panel->title
    );


    evas_object_show(
        panel->title
    );



    /*
     * Right side
     */

    panel->right_box = elm_box_add(
        panel->win
    );


    elm_box_horizontal_set(
        panel->right_box,
        EINA_TRUE
    );



    panel->network = elm_label_add(
        panel->win
    );

    elm_object_text_set(
        panel->network,
        "🌐"
    );


    elm_box_pack_end(
        panel->right_box,
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
        panel->right_box,
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
        panel->right_box,
        panel->battery
    );


    evas_object_show(
        panel->battery
    );



    elm_box_pack_end(
        panel->main_box,
        panel->left_box
    );


    elm_box_pack_end(
        panel->main_box,
        panel->right_box
    );


    evas_object_show(
        panel->left_box
    );


    evas_object_show(
        panel->right_box
    );


    evas_object_show(
        panel->main_box
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
