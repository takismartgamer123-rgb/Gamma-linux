#ifndef ROCKETENMENT_CLOCK_H
#define ROCKETENMENT_CLOCK_H

#include <Elementary.h>
#include <Ecore.h>


typedef struct
{
    Evas_Object *label;
    Ecore_Timer *timer;

} RocketClock;



RocketClock *
rocket_clock_create(Evas_Object *parent);



void
rocket_clock_destroy(RocketClock *clock);



#endif
