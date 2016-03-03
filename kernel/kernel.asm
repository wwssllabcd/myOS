.equ SELECTOR_KERNEL_CS, 8

.extern	cstart
.extern	exception_handler
.extern	spurious_irq


.extern	gdt_ptr
.extern	idt_ptr
.extern	disp_pos

.global divide_error


divide_error:
	push	$0xFFFFFFFF	# no err code
	push	$0		    # vector_no	= 0
	jmp	exception
single_step_exception:
	push	$0xFFFFFFFF	# no err code
	push	$1		# vector_no	= 1
	jmp	exception
nmi:
	push	$0xFFFFFFFF	# no err code
	push	$2		# vector_no	= 2
	jmp	exception
breakpoint_exception:
	push	$0xFFFFFFFF	# no err code
	push	$3		# vector_no	= 3
	jmp	exception
overflow:
	push	$0xFFFFFFFF	# no err code
	push	$4		# vector_no	= 4
	jmp	exception
bounds_check:
	push	$0xFFFFFFFF	# no err code
	push	$5		# vector_no	= 5
	jmp	exception
inval_opcode:
	push	$0xFFFFFFFF	# no err code
	push	$6		# vector_no	= 6
	jmp	exception
copr_not_available:
	push	$0xFFFFFFFF	# no err code
	push	$7		# vector_no	= 7
	jmp	exception
double_fault:
	push	$8		# vector_no	= 8
	jmp	exception
copr_seg_overrun:
	push	$0xFFFFFFFF	# no err code
	push	$9		# vector_no	= 9
	jmp	exception
inval_tss:
	push	$10		# vector_no	= A
	jmp	exception
segment_not_present:
	push	$11		# vector_no	= B
	jmp	exception
stack_exception:
	push	$12		# vector_no	= C
	jmp	exception
general_protection:
	push	$13		# vector_no	= D
	jmp	exception
page_fault:
	push	$14		# vector_no	= E
	jmp	exception
copr_error:
	push	$0xFFFFFFFF	# no err code
	push	$16		# vector_no	= 10h
	jmp	exception

exception:
	#call	exception_handler
	hlt
