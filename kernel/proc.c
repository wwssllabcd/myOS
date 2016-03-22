
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

PUBLIC int send_recv(int function, int src_dest, MESSAGE* msg)
{
    int ret = 0;

    if (function == RECEIVE)
        memset(msg, 0, sizeof(MESSAGE));

    switch (function) {
    case BOTH:
        ret = sendrec(SEND, src_dest, msg);
        if (ret == 0)
            ret = sendrec(RECEIVE, src_dest, msg);
        break;
    case SEND:
    case RECEIVE:
        ret = sendrec(function, src_dest, msg);
        break;
    default:
        assert((function == BOTH) ||
               (function == SEND) || (function == RECEIVE));
        break;
    }

    return ret;
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

PUBLIC void reset_msg(MESSAGE* p)
{
    memset(p, 0, sizeof(MESSAGE));
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

PRIVATE int deadlock(int src, int dest)
{
    struct proc* p = proc_table + dest;
    while (1) {
        if (p->p_flags & SENDING) {
            if (p->p_sendto == src) {
                /* print the chain */
                p = proc_table + dest;
                printl("=_=%s", p->name);
                do {
                    assert(p->p_msg);
                    p = proc_table + p->p_sendto;
                    printl("->%s", p->name);
                } while (p != proc_table + src);
                printl("=_=");

                return 1;
            }
            p = proc_table + p->p_sendto;
        }
        else {
            break;
        }
    }
    return 0;
}

PRIVATE int msg_send(struct proc* current, int dest, MESSAGE* m)
{
    struct proc* sender = current;
    struct proc* p_dest = proc_table + dest; /* proc dest */

    assert(proc2pid(sender) != dest);

    /* check for deadlock here */
    if (deadlock(proc2pid(sender), dest)) {
        panic(">>DEADLOCK<< %s->%s", sender->name, p_dest->name);
    }

    if ((p_dest->p_flags & RECEIVING) && /* dest is waiting for the msg */
        (p_dest->p_recvfrom == proc2pid(sender) ||
         p_dest->p_recvfrom == ANY)) {
        assert(p_dest->p_msg);
        assert(m);

        phys_copy(va2la(dest, p_dest->p_msg),
              va2la(proc2pid(sender), m),
              sizeof(MESSAGE));
        p_dest->p_msg = 0;
        p_dest->p_flags &= ~RECEIVING; /* dest has received the msg */
        p_dest->p_recvfrom = NO_TASK;
        unblock(p_dest);

        assert(p_dest->p_flags == 0);
        assert(p_dest->p_msg == 0);
        assert(p_dest->p_recvfrom == NO_TASK);
        assert(p_dest->p_sendto == NO_TASK);
        assert(sender->p_flags == 0);
        assert(sender->p_msg == 0);
        assert(sender->p_recvfrom == NO_TASK);
        assert(sender->p_sendto == NO_TASK);
    }
    else { /* dest is not waiting for the msg */
        sender->p_flags |= SENDING;
        assert(sender->p_flags == SENDING);
        sender->p_sendto = dest;
        sender->p_msg = m;

        /* append to the sending queue */
        struct proc * p;
        if (p_dest->q_sending) {
            p = p_dest->q_sending;
            while (p->next_sending)
                p = p->next_sending;
            p->next_sending = sender;
        }
        else {
            p_dest->q_sending = sender;
        }
        sender->next_sending = 0;

        block(sender);

        assert(sender->p_flags == SENDING);
        assert(sender->p_msg != 0);
        assert(sender->p_recvfrom == NO_TASK);
        assert(sender->p_sendto == dest);
    }

    return 0;
}
