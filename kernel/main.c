#include "proto.h"


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


void main(void)	
{
    //set gs first, or you will get error when you show msg
    showMsg();
    cstart();
}
