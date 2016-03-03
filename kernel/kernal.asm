.global divide_error

extern idt_ptr
	lidt idt_ptr

divide_error:
	jmp exception

exception:
	call exception_handle
	hlt
