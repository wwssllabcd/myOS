.equ SELECTOR_KERNEL_CS, 8

.extern	cstart
.extern	exception_handler
.extern	spurious_irq


.extern	gdt_ptr
.extern	idt_ptr
.extern	disp_pos

.global divide_error


	lidt idt_ptr
divide_error:
	jmp exception

exception:
	call exception_handle
	hlt
