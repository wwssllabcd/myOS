
#include "type.h"
#include "const.h"
#include "protect.h"
#include "tty.h"
#include "console.h"
#include "string.h"
#include "fs.h"
#include "proc.h"
#include "global.h"
#include "proto.h"

PRIVATE void block(struct proc* p);
PRIVATE void unblock(struct proc* p);
PRIVATE int  msg_send(struct proc* current, int dest, MESSAGE* m);
PRIVATE int  msg_receive(struct proc* current, int src, MESSAGE* m);
PRIVATE int  deadlock(int src, int dest);

PUBLIC void schedule()
{
    PROCESS* p;
    int greatest_ticks = 0;

    //printf("\nSchS=%x",  proc2pid(p_proc_ready));

    while( !greatest_ticks ){
        for (p = &FIRST_PROC; p <= &LAST_PROC; p++){

            //printf(",p=%x-%x-%x", proc2pid(p), p->p_flags, p->ticks);

            if (p->p_flags == 0){
                if (p->ticks > greatest_ticks){
                    greatest_ticks = p->ticks;
                    p_proc_ready = p;
                    //printf(",CP=%x", proc2pid(p));
                }
            } else{
               // printf(",blk");
            }
        }

        //如果 greatest_ticks = 0，根據上述for loop. 代表所有的ticks都變成0
        if (!greatest_ticks){
            //printf("\n ------- RST Tick --------");
            for (p = &FIRST_PROC; p <= &LAST_PROC; p++){
                // 若是狀態在 SEND 或是 RECEIVE 的，將不會獲得tick (orange, P321)
                if (p->p_flags == 0){
            		p->ticks = p->priority;
            	}
            }
        }
    }

    //int i,j,k;
    //for(i=0; i<0x1000; i++){
    //    for(j=0; j<0x800; j++){
    //        k++;
    //    }
    //}

    //printf(",Sch_end, sel=%x", proc2pid(p_proc_ready));
    //printf("\n------- change Process = %x, Status=%x ------", proc2pid(p_proc_ready), p_proc_ready->p_flags);

}

/*****************************************************************************
 *                                sys_sendrec
 *****************************************************************************/
/**
 * <Ring 0> The core routine of system call `sendrec()'.
 * 
 * @param function SEND or RECEIVE
 * @param src_dest To/From whom the message is transferred.
 * @param m        Ptr to the MESSAGE body.
 * @param p        The caller proc.
 * 
 * @return Zero if success.
 *****************************************************************************/
PUBLIC int sys_sendrec(int function, int src_dest, MESSAGE* m, struct proc* p)
{
	assert(k_reenter == 0);	/* make sure we are not in ring0 */
	assert((src_dest >= 0 && src_dest < NR_TASKS + NR_PROCS) ||
	       src_dest == ANY ||
	       src_dest == INTERRUPT);

	int ret = 0;
	int caller = proc2pid(p);
	MESSAGE* mla = (MESSAGE*)va2la(caller, m);
	mla->source = caller;

	//printf("\nCall=%x", caller);

	assert(mla->source != src_dest);

	/**
	 * Actually we have the third message type: BOTH. However, it is not
	 * allowed to be passed to the kernel directly. Kernel doesn't know
	 * it at all. It is transformed into a SEND followed by a RECEIVE
	 * by `send_recv()'.
	 */
	if (function == SEND) {
		ret = msg_send(p, src_dest, m);
		if (ret != 0)
			return ret;
	}
	else if (function == RECEIVE) {
		ret = msg_receive(p, src_dest, m);
		if (ret != 0)
			return ret;
	}
	else {
		panic("{sys_sendrec} invalid function: "
		      "%d (SEND:%d, RECEIVE:%d).", function, SEND, RECEIVE);
	}

	return 0;
}

PUBLIC int send_recv(int function, int src_dest, MESSAGE* msg)
{
    int ret = 0;

    if (function == RECEIVE)
        memset(msg, 0, sizeof(MESSAGE));

    //1: send, 2 receive, 3:both
    switch (function) {
    case BOTH:
        ret = sendrec(SEND, src_dest, msg);
        if (ret == 0)
            ret = sendrec(RECEIVE, src_dest, msg);
        break;
    case SEND:
    case RECEIVE:
        ret = sendrec(function, src_dest, msg);
        //printf("\nb2_Send_Rcv, p=%x, F=%x", p_proc_ready-&FIRST_PROC, function);
        break;
    default:
        assert((function == BOTH) || (function == SEND) || (function == RECEIVE));
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

    //找出該 process的 phy memory address
    u32 seg_base = ldt_seg_linear(p, INDEX_LDT_RW);

    // va 應該就是message
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
    //printf(",C_Blk");
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
    //printf(",UnBLk=%x", proc2pid(p) );
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

    //printf(",SM,from=%x, dest=%x,d_sts=%X", proc2pid(sender), dest, p_dest->p_flags);

    if ((p_dest->p_flags & RECEIVING) && /* dest is waiting for the msg */
        (p_dest->p_recvfrom == proc2pid(sender) ||
         p_dest->p_recvfrom == ANY)) {

        //printf(",SM_2_Des_RDY");

        assert(p_dest->p_msg);
        assert(m);

        //找出實際上雙方的 message位置後，拷貝過去
        phys_copy(va2la(dest, p_dest->p_msg),
              va2la(proc2pid(sender), m),
              sizeof(MESSAGE));

        p_dest->p_msg = 0;

        // dest 再等 msg, 然後剛好sender又要送給他，所以就配對
        p_dest->p_flags &= ~RECEIVING; /* dest has received the msg */
        p_dest->p_recvfrom = NO_TASK;


        // unlock 遠端
        unblock(p_dest);

        assert(p_dest->p_flags == 0);
        assert(p_dest->p_msg == 0);
        assert(p_dest->p_recvfrom == NO_TASK);
        assert(p_dest->p_sendto == NO_TASK);
        assert(sender->p_flags == 0);
        assert(sender->p_msg == 0);
        assert(sender->p_recvfrom == NO_TASK);
        assert(sender->p_sendto == NO_TASK);
    }else { /* dest is not waiting for the msg */

        //printf(",SM_Des_NOT_RDY");

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

    //printf(",Send_E");
    return 0;
}


/*****************************************************************************
 *                                msg_receive
 *****************************************************************************/
/**
 * <Ring 0> Try to get a message from the src proc. If src is blocked sending
 * the message, copy the message from it and unblock src. Otherwise the caller
 * will be blocked.
 * 
 * @param current The caller, the proc who wanna receive.
 * @param src     From whom the message will be received.
 * @param m       The message ptr to accept the message.
 * 
 * @return  Zero if success.
 *****************************************************************************/
PRIVATE int msg_receive(struct proc* current, int src, MESSAGE* m)
{
	struct proc* p_who_wanna_recv = current; /**
						  * This name is a little bit
						  * wierd, but it makes me
						  * think clearly, so I keep
						  * it.
						  */
	struct proc* p_from = 0; /* from which the message will be fetched */
	struct proc* prev = 0;
	int copyok = 0;

	assert(proc2pid(p_who_wanna_recv) != src);


	//printf(",RM,int=%x,src=%x", p_who_wanna_recv->has_int_msg, src);


	if ((p_who_wanna_recv->has_int_msg) &&
	    ((src == ANY) || (src == INTERRUPT))) {
		/* There is an interrupt needs p_who_wanna_recv's handling and
		 * p_who_wanna_recv is ready to handle it.
		 */
	    // 如果 has_int_msg=1時

	    //printf(",A");

		MESSAGE msg;
		reset_msg(&msg);
		msg.source = INTERRUPT;
		msg.type = HARD_INT;

		assert(m);

		phys_copy(
		        va2la(proc2pid(p_who_wanna_recv), m)
		        , &msg
		        , sizeof(MESSAGE));

		p_who_wanna_recv->has_int_msg = 0;

		assert(p_who_wanna_recv->p_flags == 0);
		assert(p_who_wanna_recv->p_msg == 0);
		assert(p_who_wanna_recv->p_sendto == NO_TASK);
		assert(p_who_wanna_recv->has_int_msg == 0);

		return 0;
	}

	/* Arrives here if no interrupt for p_who_wanna_recv. */
	if (src == ANY) {
		/* p_who_wanna_recv is ready to receive messages from
		 * ANY proc, we'll check the sending queue and pick the
		 * first proc in it.
		 */
	    //sending 的queue，代表有多少人對這個process發送msg
	    //printf(",Rcv_Any,SND_PROC=%X", proc2pid(p_who_wanna_recv->q_sending));
		if (p_who_wanna_recv->q_sending) {

		    //設定從哪接收
			p_from = p_who_wanna_recv->q_sending;
			copyok = 1;

			assert(p_who_wanna_recv->p_flags == 0);
			assert(p_who_wanna_recv->p_msg == 0);
			assert(p_who_wanna_recv->p_recvfrom == NO_TASK);
			assert(p_who_wanna_recv->p_sendto == NO_TASK);
			assert(p_who_wanna_recv->q_sending != 0);
			assert(p_from->p_flags == SENDING);
			assert(p_from->p_msg != 0);
			assert(p_from->p_recvfrom == NO_TASK);
			assert(p_from->p_sendto == proc2pid(p_who_wanna_recv));
		}

	}else if (src >= 0 && src < NR_TASKS + NR_PROCS) {
		/* p_who_wanna_recv wants to receive a message from
		 * a certain proc: src.
		 */
		p_from = &proc_table[src];

		if ((p_from->p_flags & SENDING) &&
		    (p_from->p_sendto == proc2pid(p_who_wanna_recv))) {
			/* Perfect, src is sending a message to
			 * p_who_wanna_recv.
			 */
			copyok = 1;

			struct proc* p = p_who_wanna_recv->q_sending;

			assert(p); /* p_from must have been appended to the
				    * queue, so the queue must not be NULL
				    */

			while (p) {
				assert(p_from->p_flags & SENDING);

				if (proc2pid(p) == src) /* if p is the one */
					break;

				prev = p;
				p = p->next_sending;
			}

			assert(p_who_wanna_recv->p_flags == 0);
			assert(p_who_wanna_recv->p_msg == 0);
			assert(p_who_wanna_recv->p_recvfrom == NO_TASK);
			assert(p_who_wanna_recv->p_sendto == NO_TASK);
			assert(p_who_wanna_recv->q_sending != 0);
			assert(p_from->p_flags == SENDING);
			assert(p_from->p_msg != 0);
			assert(p_from->p_recvfrom == NO_TASK);
			assert(p_from->p_sendto == proc2pid(p_who_wanna_recv));
		}
	}

	//printf(",CPOK=%X", copyok);
	if (copyok) {
		/* It's determined from which proc the message will
		 * be copied. Note that this proc must have been
		 * waiting for this moment in the queue, so we should
		 * remove it from the queue.
		 */

		if (p_from == p_who_wanna_recv->q_sending) { /* the 1st one */
			assert(prev == 0);
			//換 q_send 成下個 send
			p_who_wanna_recv->q_sending = p_from->next_sending;
			p_from->next_sending = 0;
		}
		else {
			assert(prev);
			prev->next_sending = p_from->next_sending;
			p_from->next_sending = 0;
		}

		assert(m);
		assert(p_from->p_msg);

		//printf(",CpyMsg From=%x", proc2pid(p_from));
		/* copy the message */
		phys_copy(va2la(proc2pid(p_who_wanna_recv), m),
			  va2la(proc2pid(p_from), p_from->p_msg),
			  sizeof(MESSAGE));

		p_from->p_msg = 0;
		p_from->p_sendto = NO_TASK;
		p_from->p_flags &= ~SENDING;

		unblock(p_from);
	}else {  /* nobody's sending any msg */
		/* Set p_flags so that p_who_wanna_recv will not
		 * be scheduled until it is unblocked.
		 */

	    //printf(",NoMsg");

	    //這邊設定 p_flag 會讓 schedule 不把該 process 排入，造成該process阻塞
		p_who_wanna_recv->p_flags |= RECEIVING;

		//m是外部的msg pointer, receive的話就是代表最初呼叫者所提供的容器
		p_who_wanna_recv->p_msg = m;
		p_who_wanna_recv->p_recvfrom = src;

		// 會呼叫 schedule, 會選一個Tick最大的 process 出來，當作執行的對象
		// 如果沒人發給本身，則本身這個process會被block
		block(p_who_wanna_recv);

		assert(p_who_wanna_recv->p_flags == RECEIVING);
		assert(p_who_wanna_recv->p_msg != 0);
		assert(p_who_wanna_recv->p_recvfrom != NO_TASK);
		assert(p_who_wanna_recv->p_sendto == NO_TASK);
		assert(p_who_wanna_recv->has_int_msg == 0);
	}

	return 0;
}

/*****************************************************************************
 *                                inform_int
 *****************************************************************************/
/**
 * <Ring 0> Inform a proc that an interrupt has occured.
 * 
 * @param task_nr  The task which will be informed.
 *****************************************************************************/
PUBLIC void inform_int(int task_nr)
{
	struct proc* p = proc_table + task_nr;

	if ((p->p_flags & RECEIVING) && /* dest is waiting for the msg */
	    ((p->p_recvfrom == INTERRUPT) || (p->p_recvfrom == ANY))) {

	    p->p_msg->source = INTERRUPT;
		p->p_msg->type = HARD_INT;
		p->p_msg = 0;
		p->has_int_msg = 0;
		p->p_flags &= ~RECEIVING; /* dest has received the msg */
		p->p_recvfrom = NO_TASK;
		assert(p->p_flags == 0);
		unblock(p);

		assert(p->p_flags == 0);
		assert(p->p_msg == 0);
		assert(p->p_recvfrom == NO_TASK);
		assert(p->p_sendto == NO_TASK);
	}
	else {
		p->has_int_msg = 1;
	}
}

/*****************************************************************************
 *                                dump_proc
 *****************************************************************************/
PUBLIC void dump_proc(struct proc* p)
{
	char info[STR_DEFAULT_LEN];
	int i;
	int text_color = MAKE_COLOR(GREEN, RED);

	int dump_len = sizeof(struct proc);

	out_byte(CRTC_ADDR_REG, START_ADDR_H);
	out_byte(CRTC_DATA_REG, 0);
	out_byte(CRTC_ADDR_REG, START_ADDR_L);
	out_byte(CRTC_DATA_REG, 0);

	sprintf(info, "byte dump of proc_table[%d]:\n", p - proc_table); disp_color_str(info, text_color);
	for (i = 0; i < dump_len; i++) {
		sprintf(info, "%x.", ((unsigned char *)p)[i]);
		disp_color_str(info, text_color);
	}

	/* printl("^^"); */

	disp_color_str("\n\n", text_color);
	sprintf(info, "ANY: 0x%x.\n", ANY); disp_color_str(info, text_color);
	sprintf(info, "NO_TASK: 0x%x.\n", NO_TASK); disp_color_str(info, text_color);
	disp_color_str("\n", text_color);

	sprintf(info, "ldt_sel: 0x%x.  ", p->ldt_sel); disp_color_str(info, text_color);
	sprintf(info, "ticks: 0x%x.  ", p->ticks); disp_color_str(info, text_color);
	sprintf(info, "priority: 0x%x.  ", p->priority); disp_color_str(info, text_color);
	sprintf(info, "pid: 0x%x.  ", p->pid); disp_color_str(info, text_color);
	sprintf(info, "name: %s.  ", p->name); disp_color_str(info, text_color);
	disp_color_str("\n", text_color);
	sprintf(info, "p_flags: 0x%x.  ", p->p_flags); disp_color_str(info, text_color);
	sprintf(info, "p_recvfrom: 0x%x.  ", p->p_recvfrom); disp_color_str(info, text_color);
	sprintf(info, "p_sendto: 0x%x.  ", p->p_sendto); disp_color_str(info, text_color);
	sprintf(info, "nr_tty: 0x%x.  ", p->nr_tty); disp_color_str(info, text_color);
	disp_color_str("\n", text_color);
	sprintf(info, "has_int_msg: 0x%x.  ", p->has_int_msg); disp_color_str(info, text_color);
}


/*****************************************************************************
 *                                dump_msg
 *****************************************************************************/
PUBLIC void dump_msg(const char * title, MESSAGE* m)
{
	int packed = 0;
	printl("{%s}<0x%x>{%ssrc:%s(%d),%stype:%d,%s(0x%x, 0x%x, 0x%x, 0x%x, 0x%x, 0x%x)%s}%s",  //, (0x%x, 0x%x, 0x%x)}",
	       title,
	       (int)m,
	       packed ? "" : "\n        ",
	       proc_table[m->source].name,
	       m->source,
	       packed ? " " : "\n        ",
	       m->type,
	       packed ? " " : "\n        ",
	       m->u.m3.m3i1,
	       m->u.m3.m3i2,
	       m->u.m3.m3i3,
	       m->u.m3.m3i4,
	       (int)m->u.m3.m3p1,
	       (int)m->u.m3.m3p2,
	       packed ? "" : "\n",
	       packed ? "" : "\n"/* , */
		);
}

