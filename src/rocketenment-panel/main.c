#include <Elementary.h>

#include "panel.h"
#include "clock.h"


EAPI_MAIN int
elm_main(int argc, char **argv)
{
    RocketPanel *panel;
    RocketClock *clock;


    elm_policy_set(
        ELM_POLICY_QUIT,
        ELM_POLICY_QUIT_LAST_WINDOW_CLOSED
    );



    panel = rocket_panel_create();


    if (!panel)
        return 1;



    clock = rocket_clock_create(
        panel->win
    );


    if (!clock)
        return 1;



    elm_box_pack_end(
        panel->box,
        clock->label
    );



    rocket_panel_show(
        panel
    );



    elm_run();



    rocket_clock_destroy(
        clock
    );


    rocket_panel_destroy(
        panel
    );


    return 0;
}


ELM_MAIN()
