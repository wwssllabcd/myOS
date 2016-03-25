#include "type.h"
#include "const.h"
#include "protect.h"
#include "proc.h"
#include "tty.h"
#include "console.h"
#include "fs.h"

#ifdef  GLOBAL_VARIABLES_HERE
#undef  EXTERN
#define EXTERN
#endif

EXTERN  u8      hd_cnt;

EXTERN  int     m_ticks;

EXTERN  int     disp_pos;
EXTERN  u8      gdt_ptr[6]; // 0~15:Limit  16~47:Base
EXTERN  DESCRIPTOR  gdt[GDT_SIZE];
EXTERN  u8      idt_ptr[6]; // 0~15:Limit  16~47:Base
EXTERN  GATE        idt[IDT_SIZE];

EXTERN  u32     k_reenter;
EXTERN  int nr_current_console;

EXTERN  TSS     tss;
EXTERN  PROCESS*    p_proc_ready;


extern  char        task_stack[];
extern  PROCESS     proc_table[];
extern  TASK            task_table[];
extern  TASK            user_proc_table[];
extern  irq_handler irq_table[];
extern  TTY     tty_table[];
extern  CONSOLE         console_table[];

/* FS */
extern	struct dev_drv_map	dd_map[];


//#undef GEN_SYS_CALL_FUN
//#define GEN_SYS_CALL_FUN( NAME) index_##NAME,
//
//enum sys_call_Fun
//{
//    #include "systemCallGen.h"
//    CALL_TABLE_SIZE
//};
//

