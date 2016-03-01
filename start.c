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

}

PUBLIC void cstart()
{
    showMsg();
}
