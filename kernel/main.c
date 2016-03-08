#include "proto.h"
#include "protect.h"
#include "proc.h"
#include "global.h"


void TestA(void)
{
    int i=0;

    while(1){
        disp_str("\nA");
        disp_int(i++);
        disp_str(".");
        delay(1);
    }
}

void set_gdt(u8 itemNum, u16 data_0, u16 data_1, u16 data_2, u16 data_3)
{
    DESCRIPTOR* p_des = &gdt[itemNum];

    p_des->limit_low = data_0;
    p_des->base_low = data_1;

    p_des->base_mid = data_2 & 0xFF;
    p_des->attr1 = (data_2>>16)&0xFF;

    p_des->limit_high_attri = data_3 & 0xFF;
    p_des->base_high = (data_3>>16)&0xFF;


    disp_str("\nitem");
    disp_int(itemNum);
    disp_str(", addr=");
    disp_int(p_des);


}

void printMem(u32 addr, u32 len)
{
    u32 end = addr+len;
    u32 i;
    disp_str("\nMEM=");
    disp_int(addr);
    for(i=0; i<len; i++){
        if((i & 0xF) == 0){
            disp_str("\n");
            disp_int(addr+i);
            disp_str("|");
        }
        u8 tmp = (*(u8*)(addr+i));
        disp_u8(tmp);
        disp_str(",");
    }
}

void kernel_main(void)
{
    set_gdt(0, 0x0000, 0x0000, 0x0000, 0x0000);

    PROCESS* p_proc = proc_table;

    p_proc->ldt_sel = SELECTOR_LDT_FIRST;


    set_gdt(1, 0x0FFF, 0x0000, 0x9A00, 0x00C0);
    set_gdt(2, 0x0FFF, 0x0000, 0x9200, 0x00C0);
    set_gdt(3, 0x0FFF, 0x0000, 0x9200, 0x00C0);

    printMem( (u32)(&gdt), 0x20);
    disp_str("\nb");

    memcpy(&p_proc->ldts[0], &gdt[SELECTOR_KERNEL_CS >> 3], sizeof(DESCRIPTOR));
    p_proc->ldts[0].attr1 = DA_C | PRIVILEGE_TASK << 5; // change the DPL

    memcpy(&p_proc->ldts[1], &gdt[SELECTOR_KERNEL_DS >> 3], sizeof(DESCRIPTOR));
    p_proc->ldts[1].attr1 = DA_DRW | PRIVILEGE_TASK << 5;   // change the DPL

    printMem( (u32)(&gdt), 0x20);

    disp_str("\nKernel_main");

    //BIT 0~1: RPL
    //BIT2 :TIL: 1代表位在 LDT
    //BIT3~7: selector
    p_proc->regs.cs = (0 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
    p_proc->regs.ds = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
    p_proc->regs.es = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
    p_proc->regs.fs = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
    p_proc->regs.ss = (8 & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
    p_proc->regs.gs = (SELECTOR_KERNEL_GS & SA_RPL_MASK) | RPL_TASK;  // val = 0x19
    p_proc->regs.eip = (u32) TestA;
    p_proc->regs.esp = (u32) task_stack + STACK_SIZE_TOTAL;
    p_proc->regs.eflags = 0x1202;   // IF=1, IOPL=1, bit 2 is always 1.

    p_proc_ready = proc_table;
    restart();

    while( 1 )
    {
    }

}
