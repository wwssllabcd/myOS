#include "const.h"
#include "type.h"
#include "global.h"


PUBLIC void delay_eric()
{
#ifdef ERIC
    int i, j, k;
    for (i = 0; i < 0x100; i++){
        for (j = 0; j < 0x200; j++){
            k++;
        }
    }
#endif
}


void ut_ck_idt_desc()
{
    u8 tmpIdt[0x100];
    memset(tmpIdt, 0, sizeof(tmpIdt));
    u8* pIdt = (u8*)&tmpIdt;
}

void printMem(u32 addr, u32 len)
{
    u32 end = addr + len;
    u32 i;
    for (i = 0; i < len; i++){
        if((i & 0xF) == 0){
            printf("\n");
            printf("%x", addr + i);
            printf("|");
        }
        u8 tmp = (*(u8*) (addr + i));
        printf("%x", tmp);
        printf(",");
    }
}

void showMsgType(MESSAGE* emsg)
{
    ERIC_DEBUG("\nMSG");
    ERIC_DEBUG(",io=%x", emsg->type);
    ERIC_DEBUG(",cnt=%x", emsg->CNT);
    ERIC_DEBUG(",p=%x", emsg->PROC_NR);
    ERIC_DEBUG(",dev=%x", emsg->DEVICE);
    ERIC_DEBUG(",pos=%x", emsg->POSITION);
    ERIC_DEBUG(",buf=%x", emsg->BUF);

    printMem((u32)emsg->BUF, 0x10);
}

