#include "const.h"
#include "protect.h"
#include "global.h"


void divide_error();

PRIVATE void init_idt_desc(u8 vector, u8 desc_type, int_handle handler, u8 privilege)
{
    GATE* p_gate = &idt[vector];
    u32 base = (u32)handler;

    p_gate->offset_low = base & 0xFFFF;
    p_gate->selector = SELECTOR_KERNEL_CS;
    p_gate->dcount = 0;
    p_gate->attr = desc_type | (privilege<<8);
    p_gate->offset_high = (base>>16) & 0xFFFF;
}

PUBLIC void init_prot()
{
    init_idt_desc(INT_VECTOR_DIVIDE, DA_386IGate, divide_error, PRIVILEGE_KRNL);

}

PUBLIC void exception_handle()
{

}



