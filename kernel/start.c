#include "type.h"
#include "const.h"
#include "proto.h"
#include "global.h"
#include "protect.h"

void showMsg()
{
    __asm__ ("movl $0x18, %eax;"
            "mov %ax,%gs \n "
            "mov $((80*3 + 0)*2), %edi \n"
            "mov $0x0C, %ah \n"
            "mov $'m', %al \n"
            "mov %ax, %gs:(%edi) \n"
    );
}


//init idt_desc
PUBLIC void init_gptr()
{
    u16* p_gdt_limit = (u16*) (&gdt_ptr[0]);
    u32* p_gdt_base  = (u32*) (&gdt_ptr[2]);
    *p_gdt_limit = GDT_SIZE * sizeof(DESCRIPTOR) - 1;
    *p_gdt_base = (u32) &gdt;
}


//init idt_desc
PUBLIC void init_iptr()
{
    u16* p_idt_limit = (u16*)(&idt_ptr[0]);
    u32* p_idt_base  = (u32*)(&idt_ptr[2]);
    *p_idt_limit = (IDT_SIZE*sizeof(GATE)) -1;
    *p_idt_base = (u32)&idt;
}

PUBLIC void cstart()
{
    showMsg();//set gs first, or you will get error when you show msg
    disp_str("\ncstart-start");
    disp_str("\n");

    set_gdt(0, 0x0000, 0x0000, 0x0000, 0x0000);
    set_gdt(1, 0x0FFF, 0x0000, 0x9A00, 0x00C0);        // code
    set_gdt(2, 0x0FFF, 0x0000, 0x9200, 0x00C0);        // data segment
    set_gdt(3, 0xFFFF, 0x8000, 0x920B|0x6000, 0x00C0); // GS, SET DPL = 3

    disp_int(0x67AB);

    init_gptr();
    init_iptr();
    init_prot();

    disp_str("\ncse");
}
