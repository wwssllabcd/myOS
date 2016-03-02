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
1:
	lodsb                 # Load string byte, 會把SI所指的位置的值，拿出來放在al中, (ex: if (DF==0) AL = *SI++; else AL = *SI--)
	test %al, %al         # 測試(ex: TEST AL，80H；測試AL中最高位), 此句為改變ZF標誌位，測試AL是否為 0(0就是結束符號)
	jz 2
	cmp $0x0A, %al        # 是否為換行，否的話，執行 3:
	jnz 3

	# al: string ptr
	# edi: disp_pos
	push %eax
	mov %edi, %eax
	mov 160, %bl          # 貌似螢幕的大小 ，接下來除pos,好知道要顯示在第幾行?


	# div只有一个操作数，此操作数为除数，而被除数则为EDX:EAX中的内容（一个64位的整数），
	# 操作的结果有两部分：商和余数，其中商放在eax寄存器中，而余数则放在edx寄存器中。其语法如下所示：
	div %bl
	and 0xFF, %eax
	inc %eax              # 把eax加1
	mov 160, %bl
	mul %bl               # "MUL SRC" 無符號數的乘法, 當SRC為8位時  ：AX<----AL*SRC
	mov %eax, %edi        # 取得新的行數
	pop %eax              # 還原eax
	jmp 1
3:
	mov %ax, %gs:(%edi)   # 顯示字元
	add 2, %edi           # 移動一個字元
	jmp 1
2:
	mov %edi, (disp_pos)    # 備份 pos
	pop %ebp                # 還原 ebp
	ret













