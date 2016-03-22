
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

PUBLIC int ldt_seg_linear(struct proc* p, int idx)
{
    struct descriptor * d = &p->ldts[idx];

    return d->base_high << 24 | d->base_mid << 16 | d->base_low;
}

PUBLIC void* va2la(int pid, void* va)
{
    struct proc* p = &proc_table[pid];

    u32 seg_base = ldt_seg_linear(p, INDEX_LDT_RW);
    u32 la = seg_base + (u32)va;

    if (pid < NR_TASKS + NR_PROCS) {
        assert(la == (u32)va);
    }

    return (void*)la;
}

/*****************************************************************************
 *                                block
 *****************************************************************************/
/**
 * <Ring 0> This routine is called after `p_flags' has been set (!= 0), it
 * calls `schedule()' to choose another proc as the `proc_ready'.
 *
 * @attention This routine does not change `p_flags'. Make sure the `p_flags'
 * of the proc to be blocked has been set properly.
 *
 * @param p The proc to be blocked.
 *****************************************************************************/
PRIVATE void block(struct proc* p)
{
    assert(p->p_flags);
    schedule();
}

/*****************************************************************************
 *                                unblock
 *****************************************************************************/
/**
 * <Ring 0> This is a dummy routine. It does nothing actually. When it is
 * called, the `p_flags' should have been cleared (== 0).
 *
 * @param p The unblocked proc.
 *****************************************************************************/
PRIVATE void unblock(struct proc* p)
{
    assert(p->p_flags == 0);
}
