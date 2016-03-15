#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "string.h"
#include "proc.h"
#include "global.h"

PUBLIC void keyboard_handler(int irq)
{
	disp_str("*");
}

PUBLIC void init_keyboard()
{
    put_irq_handler(KEYBOARD_IRQ, keyboard_handler);/*设定键盘中断处理程序*/
    enable_irq(KEYBOARD_IRQ); /*开键盘中断*/
}

