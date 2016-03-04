#include "type.h"
#include "const.h"
#include "proto.h"
#include "global.h"
#include "protect.h"

//init idt_desc
PUBLIC void init_idt()
{
    u16* p_idt_limit = (u16*)(&idt_ptr[0]);
    u32* p_idt_base  = (u32*)(&idt_ptr[2]);
    *p_idt_limit = (IDT_SIZE*sizeof(GATE)) -1;
    *p_idt_base = (u32)&idt;

}

PUBLIC void cstart()
{
    disp_str("cstart-start\n");
    disp_int(0x67AB);
    init_idt();
    init_prot();
    ldIdt();
    disp_str("cse\n");
}
