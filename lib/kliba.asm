

.extern	disp_pos

.text

.global disp_color_str
.global	out_byte
.global	in_byte
.global	memcpy

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

disp_color_str:
	push %ebp             # 保存呼叫者的ebp
	mov %esp, %ebp        # 重新設定EBP(把目前esp當作ebp)
	mov 8(%ebp), %esi     # 取出1號參數, 應該是string 的pointer
	mov (disp_pos), %edi
	mov 12(%ebp), %ah     # 取出2號參數 color
tag_1:
	lodsb                 # Load string byte, 會把SI所指的位置的值，拿出來放在al中, (ex: if (DF==0) AL = *SI++; else AL = *SI--)
	test %al, %al         # 測試(ex: TEST AL，80H；測試AL中最高位), 此句為改變ZF標誌位，測試AL是否為 0(0就是結束符號)
	jz tag_2
	cmp $0x0A, %al        # 是否為換行，否的話，執行 3:
	jnz tag_3

	# al: string ptr
	# edi: disp_pos
	push %eax
	mov %edi, %eax
	mov $160, %bl          # 貌似螢幕的大小 ，接下來除pos,好知道要顯示在第幾行?


	# div 指令，後面接除數，被除數為%ax, 如果除數為 8 位元，則 result stored in AL = Quotient, AH = Remainder.
	# 如果 ax=2 的話，這邊除下來會讓 AX= 0x0200
	div %bl
	and $0xFF, %eax
	inc %eax              # 把eax加1
	mov $160, %bl
	mul %bl               # "MUL SRC" 無符號數的乘法, 當SRC為8位時  ：AX<----AL*SRC
	mov %eax, %edi        # 取得新的行數
	pop %eax              # 還原eax
	jmp tag_1
tag_3:
	mov %ax, %gs:(%edi)   # 顯示字元
	add $2, %edi           # 移動一個字元
	jmp tag_1
tag_2:
	mov %edi, (disp_pos)    # 備份 pos
	pop %ebp                # 還原 ebp
	ret

memcpy:
	push %ebp
	mov	%esp, %ebp

	push	%esi
	push	%edi
	push	%ecx

	mov	8(%ebp), %edi 	# Destination
	mov	12(%ebp), %esi  # Source
	mov	16(%ebp), %ecx  # Counter
tag_11:
	cmp	$0, %ecx	 	# 判断计数器
	jz	tag_22		    # 计数器为零时跳出

	mov	%ds:(%esi), %al		      # ┓
	inc	%esi			          # ┃
					              # ┣ 逐字节移动
	mov	%al, %es:(%edi) 	      # ┃
	inc	%edi			          # ┛

	dec	%ecx		              # 计数器减一
	jmp	tag_11		              # 循环
tag_22:
	mov	8(%ebp), %eax 	          # 返回值
	pop	%ecx
	pop	%edi
	pop	%esi
	mov	%ebp, %esp
	pop	%ebp
	ret














