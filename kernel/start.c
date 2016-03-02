#include "type.h"
#include "const.h"
#include "protect.h"
#include "global.h"

void showMsg()
{
    __asm__ ("movl $0x20, %eax;"
            "mov %ax,%gs \n "
            "mov $((80*3 + 0)*2), %edi \n"
            "mov $0x0C, %ah \n"
            "mov $'m', %al \n"
            "mov %ax, %gs:(%edi) \n"
    );
}

PUBLIC void init_idt()
{
    u16* p_idt_limit = (u16*)(&idt_ptr[0]);
    u32* p_idt_base  = (u32*)(&idt_ptr[2]);
    *p_idt_limit = (IDT_SIZE*sizeof(GATE)) -1;
    *p_idt_base = (u32)&idt;

}

PUBLIC void cstart()
{
    showMsg();
    //init_idt();
}
