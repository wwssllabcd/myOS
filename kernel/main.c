#include "proto.h"

void testA(void)
{
    int i=0;

    while(1){
        disp_str("\nA");
        disp_int(i++);
        disp_str(".");
        delay(1);
    }

}

void testB(void)
{
    int i=0;

    while(1){
        disp_str("\nB");
        disp_int(i++);
        disp_str(".");
        delay(1);
    }

}
