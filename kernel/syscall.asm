%include "sconst.inc"

_NR_get_ticks       equ 0 ; 要跟 global.c 中 sys_call_table 的定义相对应！
INT_VECTOR_SYS_CALL equ 0x90

global	get_ticks ; 导出符号

bits 32
[section .text]

get_ticks:
	mov	eax, _NR_get_ticks
	int	INT_VECTOR_SYS_CALL
	ret

