#ifndef _PROTO_H_
#define _PROTO_H_


#include "const.h"
#include "type.h"
#include "protect.h"



//PUBLIC void out_byte(u16 port, u8 value);


// cstart
PUBLIC void cstart();


//kliba
//PUBLIC void disp_color_str(char * info, int color);

//klib
PUBLIC void disp_str(char* str);
//PUBLIC void delay(int time);



//protect.c
PUBLIC void init_prot();
PUBLIC u32 seg2phys(u16 seg);
PRIVATE void init_descriptor(DESCRIPTOR *p_desc,u32 base,u32 limit,u16 attribute);


//main
void TestA(void);
void TestB(void);



#endif
