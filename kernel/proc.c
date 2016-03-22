
#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "string.h"
#include "proc.h"
#include "global.h"

PRIVATE void block(struct proc* p);
PRIVATE void unblock(struct proc* p);
PRIVATE int  msg_send(struct proc* current, int dest, MESSAGE* m);
PRIVATE int  msg_receive(struct proc* current, int src, MESSAGE* m);
PRIVATE int  deadlock(int src, int dest);

PUBLIC void schedule()
{
    PROCESS* p;
    int greatest_ticks = 0;

    while( !greatest_ticks ){
        for (p = &FIRST_PROC; p <= &LAST_PROC; p++){
            if (p->p_flags == 0){
                if (p->ticks > greatest_ticks){
                    greatest_ticks = p->ticks;
                    p_proc_ready = p;
                }
            }
        }

        if (!greatest_ticks){
            for (p = &FIRST_PROC; p <= &LAST_PROC; p++)
            if (p->p_flags == 0)
            p->ticks = p->priority;
        }
    }
}

PUBLIC int sys_get_ticks()
{
	return ticks;
}

