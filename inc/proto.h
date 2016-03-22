#ifndef _PROTO_H_
#define _PROTO_H_


#include "const.h"
#include "type.h"
#include "protect.h"
#include "console.h"
#include "proc.h"



//PUBLIC void out_byte(u16 port, u8 value);


// cstart
PUBLIC void cstart();


/* proc.c */
PUBLIC  int     sys_get_ticks();        /* sys_call */


/* syscall.asm */
PUBLIC  void    sys_call();             /* int_handler */
PUBLIC  int     get_ticks();



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
void TestC(void);

//8259
PUBLIC void spurious_irq(int irq);


//clock
PUBLIC void clock_handler(int irq);

PUBLIC void task_tty();


PUBLIC void out_char(CONSOLE* p_con, char ch);
PUBLIC void scroll_screen(CONSOLE* p_con, int direction);

/* printf.c */
PUBLIC  int     printf(const char *fmt, ...);
#define printl  printf

//vsprintf
PUBLIC  int     vsprintf(char *buf, const char *fmt, va_list args);
PUBLIC  int sprintf(char *buf, const char *fmt, ...);


/* proc.c */
PUBLIC  void    schedule();

//tty
PUBLIC int sys_write(char* buf, int len, PROCESS* p_proc);


#endif
