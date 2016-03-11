

#ifdef  GLOBAL_VARIABLES_HERE
#undef  EXTERN
#define EXTERN
#endif

#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "proc.h"
#include "global.h"

PUBLIC  char            task_stack[STACK_SIZE_TOTAL];

PUBLIC	PROCESS			proc_table[NR_TASKS];



PUBLIC	TASK	task_table[NR_TASKS] =
{
        {TestA, STACK_SIZE_TESTA, "TestA"},
        {TestB, STACK_SIZE_TESTB, "TestB"}
};

PUBLIC  irq_handler     irq_table[NR_IRQ];
