#ifndef ROCKETENMENT_PANEL_H
#define ROCKETENMENT_PANEL_H

#include <Elementary.h>
#include <Eina.h>


typedef struct
{
    Evas_Object *win;
    Evas_Object *box;

    Evas_Object *title;
    Evas_Object *clock;

    Evas_Object *network;
    Evas_Object *sound;
    Evas_Object *battery;

} RocketPanel;



RocketPanel *
rocket_panel_create(void);



void
rocket_panel_show(RocketPanel *panel);



void
rocket_panel_destroy(RocketPanel *panel);



#endif
