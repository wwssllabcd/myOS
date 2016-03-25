#include "proto.h"
#include "protect.h"
#include "proc.h"
#include "global.h"
#include "const.h"
#include "ericut.h"

PUBLIC int get_ticks()
{
    MESSAGE msg;
    reset_msg(&msg);
    msg.type = GET_TICKS;
    // printf("\nGT=%x", proc2pid(p_proc_ready));
    // both 就是向 task_sys 先送"我要tick"，後收 tick
    send_recv(BOTH, TASK_SYS, &msg);
    return msg.RETVAL;
}

void TestA(void)
{
    while( 1 ){
        printf("\nA=%x", get_ticks());
        milli_delay(2000);
    }
}

void TestB(void)
{
    while( 1 ){
        printf("\nB=%x", CALL_TABLE_SIZE);
        milli_delay(2000);
    }
}

void TestC(void)
{
    while( 1 ){
        printf("\nC=%x", CALL_TABLE_SIZE);
        milli_delay(2000);
    }
}

void set_gdt(u8 itemNum, u16 data_0, u16 data_1, u16 data_2, u16 data_3)
{
    DESCRIPTOR* p_des = &gdt[itemNum];

    p_des->limit_low = data_0;
    p_des->base_low = data_1;

    p_des->base_mid = data_2 & 0xFF;
    p_des->attr1 = (data_2 >> 8) & 0xFF;

    p_des->limit_high_attr2 = data_3 & 0xFF;
    p_des->base_high = (data_3 >> 8) & 0xFF;
}

void printMem(u32 addr, u32 len)
{
    u32 end = addr + len;
    u32 i;
    for (i = 0; i < len; i++){
        if((i & 0xF) == 0){
            disp_str("\n");
            disp_int(addr + i);
            disp_str("|");
        }
        u8 tmp = (*(u8*) (addr + i));
        disp_u8(tmp);
        disp_str(",");
    }
}

void kernel_main(void)
{
    disp_str("\nKernel_main");
    compiler_time_assert(1, cast_fail);

    TASK* p_task = task_table;
    PROCESS* p_proc = proc_table;
    char* p_task_stack = task_stack + STACK_SIZE_TOTAL;
    u16 selector_ldt = SELECTOR_LDT_FIRST;
  
    u8 privilege;
    u8 rpl;
    int eflags;
	int   i;
	int   prio;
    for (i = 0; i < NR_TASKS + NR_PROCS; i++){
        if(i < NR_TASKS){ /* 任务 */
            p_task = task_table + i;
            privilege = PRIVILEGE_TASK;
            rpl = RPL_TASK;
            eflags = 0x1202; /* IF=1, IOPL=1, bit 2 is always 1 */
			prio      = 15;
        }else{ /* 用户进程 */
            p_task = user_proc_table + (i - NR_TASKS);
            privilege = PRIVILEGE_USER;
            rpl = RPL_USER;
            eflags = 0x202; /* IF=1, bit 2 is always 1 */
			prio      = 5;
        }

        strcpy(p_proc->name, p_task->name);   // name of the process
        p_proc->pid = i;            // pid

        p_proc->ldt_sel = selector_ldt;

        // GDT[1] copy 到 LDT[0]
        memcpy(&p_proc->ldts[0], &gdt[SELECTOR_KERNEL_CS >> 3], sizeof(DESCRIPTOR));
        p_proc->ldts[0].attr1 = DA_C | privilege << 5;

        // GDT[2] copy 到 LDT[1]
        memcpy(&p_proc->ldts[1], &gdt[SELECTOR_KERNEL_DS >> 3], sizeof(DESCRIPTOR));
        p_proc->ldts[1].attr1 = DA_DRW | privilege << 5;

		// BIT 0~1: RPL
        // BIT2 :TIL: 1代表位在 LDT
        // BIT3~7: selector
        // CS 指向 LDT 第0條
        // 如果GS,SS..等SS載入時，發現TIL被設成1，代表這條code 要去LDT去找
        p_proc->regs.cs = (0 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | rpl;
        p_proc->regs.ds = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | rpl;
        p_proc->regs.es = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | rpl;
        p_proc->regs.fs = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | rpl;
        p_proc->regs.ss = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | rpl;
        p_proc->regs.gs = (SELECTOR_KERNEL_GS & SA_RPL_MASK) | rpl;

        // initial_eip就是該process的 fun_ptr，會在restart中，被 iret還原
        p_proc->regs.eip = (u32) p_task->initial_eip;
        p_proc->regs.esp = (u32) p_task_stack;
        p_proc->regs.eflags = eflags;

        p_proc->nr_tty = 0;

		p_proc->p_flags = 0;
		p_proc->p_msg = 0;
		p_proc->p_recvfrom = NO_TASK;
		p_proc->p_sendto = NO_TASK;
		p_proc->has_int_msg = 0;
		p_proc->q_sending = 0;
		p_proc->next_sending = 0;

		p_proc->ticks = p_proc->priority = prio;

        p_task_stack -= p_task->stacksize;
        p_proc++;
        p_task++;
        selector_ldt += 1 << 3;
    }

        proc_table[NR_TASKS + 0].nr_tty = 0;
        proc_table[NR_TASKS + 1].nr_tty = 0;
        proc_table[NR_TASKS + 2].nr_tty = 0;

    k_reenter = 0;
    m_ticks = 0;

    p_proc_ready = proc_table;

    init_clock();
    init_keyboard();

    restart();

    while( 1 )
    {
        disp_str("should not be here");
    }

}

PUBLIC void panic(const char *fmt, ...)
{
    int i;
    char buf[256];

    /* 4 is the size of fmt in the stack */
    va_list arg = (va_list)((char*)&fmt + 4);

    i = vsprintf(buf, fmt, arg);

    printl("%c !!panic!! %s", MAG_CH_PANIC, buf);

    /* should never arrive here */
    __asm__ __volatile__("ud2");
}


