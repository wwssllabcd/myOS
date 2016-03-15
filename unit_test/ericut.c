#include "type.h"



void ut_ck_idt_desc()
{
    u8 tmpIdt[0x100];
    memset_a(tmpIdt, 0, sizeof(tmpIdt));

    u8* pIdt = (u8*)&tmpIdt;

}

