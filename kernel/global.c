
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                            global.c
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                                                    Forrest Yu, 2005
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#define GLOBAL_VARIABLES_HERE

#include "type.h"
#include "const.h"
#include "protect.h"
#include "tty.h"
#include "console.h"
#include "proc.h"
#include "global.h"
#include "proto.h"


PUBLIC PROCESS proc_table[NR_TASKS + NR_PROCS];

PUBLIC char task_stack[STACK_SIZE_TOTAL];

PUBLIC TASK task_table[NR_TASKS] = {
        { task_tty, STACK_SIZE_TTY, "tty" }
};

PUBLIC TASK user_proc_table[NR_PROCS] = {
        { TestA, STACK_SIZE_TESTA, "TestA" }
        , { TestB, STACK_SIZE_TESTB, "TestB" }
        , { TestC, STACK_SIZE_TESTC, "TestC" }
};



PUBLIC	TTY		tty_table[NR_CONSOLES];
PUBLIC	CONSOLE		console_table[NR_CONSOLES];

PUBLIC	irq_handler	irq_table[NR_IRQ];

#undef GEN_SYS_CALL_FUN
#define GEN_SYS_CALL_FUN( NAME) sys_##NAME,
PUBLIC  system_call sys_call_table[CALL_TABLE_SIZE] = {
        #include "systemCallGen.h"
};



