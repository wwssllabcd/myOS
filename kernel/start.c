#include "type.h"
#include "const.h"
#include "protect.h"

PUBLIC u8 gdt_ptr;
PUBLIC DESCRIPTOR gdtt[GDT_SIZE];

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

PUBLIC void cstart()
{
    showMsg();
}
