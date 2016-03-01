out_byte:
	mov 4(%esp), %edx
	mov 8(%esp), %al
	out %al, %dx
	nop
	nop
	ret

in_byte:
	mov 4(%esp), %edx
	xor %eax, %eax
	in %dx, %al
	nop
	nop
	ret
