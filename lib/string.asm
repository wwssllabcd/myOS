
.global	memcpy_a
.global	memset_a
.global strcpy_a

memcpy_a:
	push %ebp
	mov	%esp, %ebp

	push	%esi
	push	%edi
	push	%ecx

	mov	8(%ebp), %edi 	# Destination
	mov	12(%ebp), %esi  # Source
	mov	16(%ebp), %ecx  # Counter
1:
	cmp	$0, %ecx	 	# 判断计数器
	jz	2f		        # 计数器为零时跳出

	mov	%ds:(%esi), %al		      # ┓
	inc	%esi			          # ┃
					              # ┣ 逐字节移动
	mov	%al, %es:(%edi) 	      # ┃
	inc	%edi			          # ┛

	dec	%ecx		              # 计数器减一
	jmp	1b  		              # 循环
2:
	mov	8(%ebp), %eax 	          # 返回值
	pop	%ecx
	pop	%edi
	pop	%esi
	mov	%ebp, %esp
	pop	%ebp
	ret

memset_a:
	push	%ebp
	mov	%esp, %ebp

	push	%esi
	push	%edi
	push	%ecx

	mov	8(%ebp), %edi	# Destination
	mov	12(%ebp), %edx	# Char to be putted
	mov	16(%ebp), %ecx	# Counter
1:
	cmp	$0, %ecx		# 判断计数器
	jz	2f		# 计数器为零时跳出


	mov	%dl, (%edi)		# ┓
	inc	%edi			# ┛

	dec	%ecx		# 计数器减一
	jmp	1b		# 循环
2:

	pop	%ecx
	pop	%edi
	pop	%esi
	mov	%ebp, %esp
	pop	%ebp

	ret			# 函数结束，返回

strcpy_a:
	push    %ebp
	mov     %esp, %ebp

	mov     12(%ebp), %esi  # Source
	mov     8(%ebp), %edi   # Destination

1:
	mov     (%esi), %al             # ┓
	inc     %esi                    # ┃
					                # ┣ 逐字节移动
	movb    %al, (%edi)             # ┃
	inc     %edi                     # ┛

	cmp     $0, %al         # 是否遇到 '\0'
	jnz     1b              # 没遇到就继续循环，遇到就结束

	mov     8(%ebp), %eax   # 返回值

	pop     %ebp
	ret                     # 函数结束，返回

