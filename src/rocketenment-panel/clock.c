#include "clock.h"

#include <time.h>
#include <stdio.h>



static Eina_Bool
_clock_update(void *data)
{
    RocketClock *clock = data;

    if (!clock || !clock->label)
        return ECORE_CALLBACK_CANCEL;


    time_t now;

    struct tm *time_info;

    char buffer[32];


    now = time(NULL);

    time_info = localtime(&now);


    strftime(
        buffer,
        sizeof(buffer),
        "%H:%M",
        time_info
    );


    elm_object_text_set(
        clock->label,
        buffer
    );


    return ECORE_CALLBACK_RENEW;
}





RocketClock *
rocket_clock_create(Evas_Object *parent)
{
    RocketClock *clock;


    clock = calloc(
        1,
        sizeof(RocketClock)
    );


    if (!clock)
        return NULL;



    clock->label = elm_label_add(
        parent
    );


    elm_object_text_set(
        clock->label,
        "00:00"
    );


    evas_object_show(
        clock->label
    );



    clock->timer = ecore_timer_add(
        1.0,
        _clock_update,
        clock
    );



    _clock_update(clock);



    return clock;
}





void
rocket_clock_destroy(RocketClock *clock)
{
    if (!clock)
        return;



    if (clock->timer)
    {
        ecore_timer_del(
            clock->timer
        );
    }



    if (clock->label)
    {
        evas_object_del(
            clock->label
        );
    }



    free(clock);
}
