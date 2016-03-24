#ifndef _PROTO_H_
#define _PROTO_H_


#include "const.h"
#include "type.h"
#include "protect.h"
#include "console.h"
#include "proc.h"

//kliba
PUBLIC void out_byte(u16 port, u8 value);
PUBLIC u8   in_byte(u16 port);
PUBLIC void disp_str(char * info);
PUBLIC void disp_color_str(char * info, int color);
PUBLIC void disable_irq(int irq);
PUBLIC void enable_irq(int irq);
PUBLIC void disable_int();
PUBLIC void enable_int();
PUBLIC void port_read(u16 port, void* buf, int n);
PUBLIC void port_write(u16 port, void* buf, int n);
PUBLIC void glitter(int row, int col);

//PUBLIC void out_byte(u16 port, u8 value);


// cstart
PUBLIC void cstart();


/* proc.c */
//PUBLIC  int     sys_get_ticks();        /* sys_call */


/* syscall.asm */
PUBLIC  void    sys_call();             /* int_handler */
PUBLIC  int     get_ticks();



//klib
PUBLIC void disp_str(char* str);
//PUBLIC void delay(int time);



//protect.c
PUBLIC void init_prot();
PUBLIC u32 seg2phys(u16 seg);
//PRIVATE void init_descriptor(DESCRIPTOR *p_desc,u32 base,u32 limit,u16 attribute);


//main
void TestA(void);
void TestB(void);
void TestC(void);

//8259
PUBLIC void spurious_irq(int irq);


//clock
PUBLIC void clock_handler(int irq);

PUBLIC void task_tty();

/* systask.c */
PUBLIC void task_sys();

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
PUBLIC  void*   va2la(int pid, void* va);
PUBLIC  int ldt_seg_linear(struct proc* p, int idx);
PUBLIC  void    reset_msg(MESSAGE* p);
PUBLIC  void    dump_msg(const char * title, MESSAGE* m);
PUBLIC  void    dump_proc(struct proc * p);
PUBLIC  int send_recv(int function, int src_dest, MESSAGE* msg);

/* lib/misc.c */
PUBLIC void spin(char * func_name);
/* 系统调用 - 系统级 */
/* proc.c */
PUBLIC  int sys_sendrec(int function, int src_dest, MESSAGE* m, struct proc* p);
PUBLIC  int sys_printx(int _unused1, int _unused2, char* s, struct proc * p_proc);

/* syscall.asm */
PUBLIC  void    sys_call();             /* int_handler */


/* 系统调用 - 用户级 */
PUBLIC  int sendrec(int function, int src_dest, MESSAGE* p_msg);
PUBLIC  int printx(char* str);

//tty
PUBLIC int sys_write(char* buf, int len, PROCESS* p_proc);


// hd.c
PUBLIC void task_hd();

// fs/main.c
PUBLIC void task_fs();

#endif
