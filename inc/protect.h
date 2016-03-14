#include "type.h"

#ifndef _PROTECT_H_
#define _PROTECT_H_

typedef struct s_descriptor
{
    u16 limit_low;
    u16 base_low;
    u8 base_mid;
    u8 attr1;
    u8 limit_high_attr2;
    u8 base_high;
}DESCRIPTOR;

typedef struct s_gate
{
    u16 offset_low;
    u16 selector;
    u8 dcount;
    u8 attr;
    u16 offset_high;
}GATE;


typedef struct s_tss {
    u32 backlink;
    u32 esp0;   /* stack pointer to use during interrupt */
    u32 ss0;    /*   "   segment  "  "    "        "     */
    u32 esp1;
    u32 ss1;
    u32 esp2;
    u32 ss2;
    u32 cr3;
    u32 eip;
    u32 flags;
    u32 eax;
    u32 ecx;
    u32 edx;
    u32 ebx;
    u32 esp;
    u32 ebp;
    u32 esi;
    u32 edi;
    u32 es;
    u32 cs;
    u32 ss;
    u32 ds;
    u32 fs;
    u32 gs;
    u32 ldt;
    u16 trap;
    u16 iobase; /* I/O位图基址大于或等于TSS段界限，就表示没有I/O许可位图 */
}TSS;


/* GDT */
/* 描述符索引 */
#define INDEX_DUMMY     0
#define INDEX_FLAT_C        1   /* | LOADER 里面已经确定了的 */
#define INDEX_FLAT_RW       2   /* |                         */
#define INDEX_VIDEO     3   /* /                         */
#define INDEX_TSS       4
#define INDEX_LDT_FIRST     5

/* 選擇子 */
#define SELECTOR_DUMMY         0        // ┐
#define SELECTOR_FLAT_C     0x08        // ├ LOADER 裡面已經確定了的.
#define SELECTOR_FLAT_RW    0x10        // │
#define SELECTOR_VIDEO      (0x18+3)    // ┘<-- RPL=3
#define SELECTOR_TSS        0x20    /* TSS                       */
#define SELECTOR_LDT_FIRST  0x28

#define SELECTOR_KERNEL_CS  SELECTOR_FLAT_C
#define SELECTOR_KERNEL_DS  SELECTOR_FLAT_RW
#define SELECTOR_KERNEL_GS  SELECTOR_VIDEO

/* 每个任务有一个单独的 LDT, 每个 LDT 中的描述符个数: */
#define LDT_SIZE        2

/* 选择子类型值说明 */
/* 其中, SA_ : Selector Attribute */
#define SA_RPL_MASK 0xFFFC
#define SA_RPL0     0
#define SA_RPL1     1
#define SA_RPL2     2
#define SA_RPL3     3

#define SA_TI_MASK  0xFFFB
#define SA_TIG      0
#define SA_TIL      4



/* 描述符類型值說明 */
#define DA_32           0x4000  /* 32 位段                */
#define DA_LIMIT_4K     0x8000  /* 段界限粒度為 4K 字節         */
#define DA_DPL0         0x00    /* DPL = 0              */
#define DA_DPL1         0x20    /* DPL = 1              */
#define DA_DPL2         0x40    /* DPL = 2              */
#define DA_DPL3         0x60    /* DPL = 3              */
/* 存儲段描述符類型值說明 */
#define DA_DR           0x90    /* 存在的只讀數據段類型值      */
#define DA_DRW          0x92    /* 存在的可讀寫數據段屬性值     */
#define DA_DRWA         0x93    /* 存在的已訪問可讀寫數據段類型值  */
#define DA_C            0x98    /* 存在的只執行代碼段屬性值     */
#define DA_CR           0x9A    /* 存在的可執行可讀代碼段屬性值       */
#define DA_CCO          0x9C    /* 存在的只執行一致代碼段屬性值       */
#define DA_CCOR         0x9E    /* 存在的可執行可讀一致代碼段屬性值 */
/* 系統段描述符類型值說明 */
#define DA_LDT          0x82    /* 局部描述符表段類型值           */
#define DA_TaskGate     0x85    /* 任務門類型值               */
#define DA_386TSS       0x89    /* 可用 386 任務狀態段類型值      */
#define DA_386CGate     0x8C    /* 386 調用門類型值           */
#define DA_386IGate     0x8E    /* 386 中斷門類型值           */
#define DA_386TGate     0x8F    /* 386 陷阱門類型值           */

/* 中斷向量 */
#define INT_VECTOR_DIVIDE       0x0
#define INT_VECTOR_DEBUG        0x1
#define INT_VECTOR_NMI          0x2
#define INT_VECTOR_BREAKPOINT       0x3
#define INT_VECTOR_OVERFLOW     0x4
#define INT_VECTOR_BOUNDS       0x5
#define INT_VECTOR_INVAL_OP     0x6
#define INT_VECTOR_COPROC_NOT       0x7
#define INT_VECTOR_DOUBLE_FAULT     0x8
#define INT_VECTOR_COPROC_SEG       0x9
#define INT_VECTOR_INVAL_TSS        0xA
#define INT_VECTOR_SEG_NOT      0xB
#define INT_VECTOR_STACK_FAULT      0xC
#define INT_VECTOR_PROTECTION       0xD
#define INT_VECTOR_PAGE_FAULT       0xE
#define INT_VECTOR_COPROC_ERR       0x10

/* 中斷向量 */
#define INT_VECTOR_IRQ0         0x20
#define INT_VECTOR_IRQ8         0x28

#define INT_VECTOR_SYS_CALL             0x90

/* 宏 */
/* 线性地址 → 物理地址 */
#define vir2phys(seg_base, vir) (u32)(((u32)seg_base) + (u32)(vir))


#endif
