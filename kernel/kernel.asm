
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                               kernel.asm
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                                                     Forrest Yu, 2005
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


%include "sconst.inc"


; 导入函数
extern	cstart
extern	kernel_main
extern	exception_handler
extern	spurious_irq
extern	clock_handler
extern	disp_str
extern	delay
extern	irq_table

; 导入全局变量
extern	gdt_ptr
extern	idt_ptr
extern	p_proc_ready
extern	tss
extern	disp_pos
extern	k_reenter
extern	sys_call_table

extern	hd_cnt



bits 32

[SECTION .data]
clock_int_msg		db	"^", 0

[SECTION .bss]
StackSpace		resb	2 * 1024
StackTop:		; 栈顶

[section .text]	; 代码在此

global _start_k	; 导出 _start_k
global restart
global sys_call

global	divide_error
global	single_step_exception
global	nmi
global	breakpoint_exception
global	overflow
global	bounds_check
global	inval_opcode
global	copr_not_available
global	double_fault
global	copr_seg_overrun
global	inval_tss
global	segment_not_present
global	stack_exception
global	general_protection
global	page_fault
global	copr_error
global	hwint00
global	hwint01
global	hwint02
global	hwint03
global	hwint04
global	hwint05
global	hwint06
global	hwint07
global	hwint08
global	hwint09
global	hwint10
global	hwint11
global	hwint12
global	hwint13
global	hwint14
global	hwint15


_start_k:
	; 此时内存看上去是这样的（更详细的内存情况在 LOADER.ASM 中有说明）：
	;              ┃                                    ┃
	;              ┃                 ...                ┃
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃■■■■■■Page  Tables■■■■■■┃
	;              ┃■■■■■(大小由LOADER决定)■■■■┃ PageTblBase
	;    00101000h ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃■■■■Page Directory Table■■■■┃ PageDirBase = 1M
	;    00100000h ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃□□□□ Hardware  Reserved □□□□┃ B8000h ← gs
	;       9FC00h ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃■■■■■■■LOADER.BIN■■■■■■┃ somewhere in LOADER ← esp
	;       90000h ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃■■■■■■■KERNEL.BIN■■■■■■┃
	;       80000h ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃■■■■■■■■KERNEL■■■■■■■┃ 30400h ← KERNEL 入口 (KernelEntryPointPhyAddr)
	;       30000h ┣━━━━━━━━━━━━━━━━━━┫
	;              ┋                 ...                ┋
	;              ┋                                    ┋
	;           0h ┗━━━━━━━━━━━━━━━━━━┛ ← cs, ds, es, fs, ss
	;
	;
	; GDT 以及相应的描述符是这样的：
	;
	;		              Descriptors               Selectors
	;              ┏━━━━━━━━━━━━━━━━━━┓
	;              ┃         Dummy Descriptor           ┃
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃         DESC_FLAT_C    (0～4G)     ┃   8h = cs
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃         DESC_FLAT_RW   (0～4G)     ┃  10h = ds, es, fs, ss
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃         DESC_VIDEO                 ┃  1Bh = gs
	;              ┗━━━━━━━━━━━━━━━━━━┛
	;
	; 注意! 在使用 C 代码的时候一定要保证 ds, es, ss 这几个段寄存器的值是一样的
	; 因为编译器有可能编译出使用它们的代码, 而编译器默认它们是一样的. 比如串拷贝操作会用到 ds 和 es.
	;
	;


	mov	byte al, [0x90100]
	mov byte [hd_cnt], al


	; 把 esp 从 LOADER 挪到 KERNEL
	mov	esp, StackTop	; 堆栈在 bss 段中

	mov	dword [disp_pos], 0

	sgdt	[gdt_ptr]	; cstart() 中将会用到 gdt_ptr
	call	cstart		; 在此函数中改变了gdt_ptr，让它指向新的GDT
	lgdt	[gdt_ptr]	; 使用新的GDT

	lidt	[idt_ptr]

	jmp	SELECTOR_KERNEL_CS:csinit
csinit:		; “这个跳转指令强制使用刚刚初始化的结构”——<<OS:D&I 2nd>> P90.

	;jmp 0x40:0
	;ud2


	xor	eax, eax
	mov	ax, SELECTOR_TSS
	ltr	ax

	;sti
	jmp	kernel_main

	;hlt


; 中断和异常 -- 硬件中断
; ---------------------------------
%macro	hwint_master	1
	call	save
	in	al, INT_M_CTLMASK	; `.
	or	al, (1 << %1)		;  | 屏蔽当前中断
	out	INT_M_CTLMASK, al	; /

	mov	al, EOI			; `. 置EOI位
	out	INT_M_CTL, al		; /

	sti	; CPU在响应中断的过程中会自动关中断，这句之后就允许响应新的中断
	push	%1			; `.
	call	[irq_table + 4 * %1]	;  | 中断处理程序
	pop	ecx			; /
	cli
	in	al, INT_M_CTLMASK	; `.
	and	al, ~(1 << %1)		;  | 恢复接受当前中断
	out	INT_M_CTLMASK, al	; /
	ret
%endmacro


ALIGN	16
hwint00:		; Interrupt routine for irq 0 (the clock).

	hwint_master	0

ALIGN	16
hwint01:		; Interrupt routine for irq 1 (keyboard)
	hwint_master	1

ALIGN	16
hwint02:		; Interrupt routine for irq 2 (cascade!)
	hwint_master	2

ALIGN	16
hwint03:		; Interrupt routine for irq 3 (second serial)
	hwint_master	3

ALIGN	16
hwint04:		; Interrupt routine for irq 4 (first serial)
	hwint_master	4

ALIGN	16
hwint05:		; Interrupt routine for irq 5 (XT winchester)
	hwint_master	5

ALIGN	16
hwint06:		; Interrupt routine for irq 6 (floppy)
	hwint_master	6

ALIGN	16
hwint07:		; Interrupt routine for irq 7 (printer)
	hwint_master	7

; ---------------------------------
%macro	hwint_slave	1
	call	save
	in	al, INT_S_CTLMASK	; `.
	or	al, (1 << (%1 - 8))	;  | 屏蔽当前中断
	out	INT_S_CTLMASK, al	; /
	mov	al, EOI			; `. 置EOI位(master)
	out	INT_M_CTL, al		; /
	nop				; `. 置EOI位(slave)
	out	INT_S_CTL, al		; /  一定注意：slave和master都要置EOI
	sti	; CPU在响应中断的过程中会自动关中断，这句之后就允许响应新的中断
	push	%1			; `.
	call	[irq_table + 4 * %1]	;  | 中断处理程序
	pop	ecx			; /
	cli
	in	al, INT_S_CTLMASK	; `.
	and	al, ~(1 << (%1 - 8))	;  | 恢复接受当前中断
	out	INT_S_CTLMASK, al	; /
	ret
%endmacro
; ---------------------------------

ALIGN	16
hwint08:		; Interrupt routine for irq 8 (realtime clock).
	hwint_slave	8

ALIGN	16
hwint09:		; Interrupt routine for irq 9 (irq 2 redirected)
	hwint_slave	9

ALIGN	16
hwint10:		; Interrupt routine for irq 10
	hwint_slave	10

ALIGN	16
hwint11:		; Interrupt routine for irq 11
	hwint_slave	11

ALIGN	16
hwint12:		; Interrupt routine for irq 12
	hwint_slave	12

ALIGN	16
hwint13:		; Interrupt routine for irq 13 (FPU exception)
	hwint_slave	13

ALIGN	16
hwint14:		; Interrupt routine for irq 14 (AT winchester)
	hwint_slave	14

ALIGN	16
hwint15:		; Interrupt routine for irq 15
	hwint_slave	15



; 中断和异常 -- 异常
divide_error:
	push	0xFFFFFFFF	; no err code
	push	0		; vector_no	= 0
	jmp	exception
single_step_exception:
	push	0xFFFFFFFF	; no err code
	push	1		; vector_no	= 1
	jmp	exception
nmi:
	push	0xFFFFFFFF	; no err code
	push	2		; vector_no	= 2
	jmp	exception
breakpoint_exception:
	push	0xFFFFFFFF	; no err code
	push	3		; vector_no	= 3
	jmp	exception
overflow:
	push	0xFFFFFFFF	; no err code
	push	4		; vector_no	= 4
	jmp	exception
bounds_check:
	push	0xFFFFFFFF	; no err code
	push	5		; vector_no	= 5
	jmp	exception
inval_opcode:
	push	0xFFFFFFFF	; no err code
	push	6		; vector_no	= 6
	jmp	exception
copr_not_available:
	push	0xFFFFFFFF	; no err code
	push	7		; vector_no	= 7
	jmp	exception
double_fault:
	push	8		; vector_no	= 8
	jmp	exception
copr_seg_overrun:
	push	0xFFFFFFFF	; no err code
	push	9		; vector_no	= 9
	jmp	exception
inval_tss:
	push	10		; vector_no	= A
	jmp	exception
segment_not_present:
	push	11		; vector_no	= B
	jmp	exception
stack_exception:
	push	12		; vector_no	= C
	jmp	exception
general_protection:
	push	13		; vector_no	= D
	jmp	exception
page_fault:
	push	14		; vector_no	= E
	jmp	exception
copr_error:
	push	0xFFFFFFFF	; no err code
	push	16		; vector_no	= 10h
	jmp	exception

exception:
	call	exception_handler
	add	esp, 4*2	; 让栈顶指向 EIP，堆栈中从顶向下依次是：EIP、CS、EFLAGS
	hlt

; =============================================================================
;                                   save
; =============================================================================
save:
		; 理論上在執行 push之前，esp應該會設成 p_proc_ready 才對
		; pushad = push ax,cx,dx,bx,sp(可能不push),bp,si,di
		; 這裡保存了register, 可見進來的時候，esp應該就是指向 struct process
        pushad
        push    ds      ;  |
        push    es      ;  | 保存原寄存器值
        push    fs      ;  |
        push    gs      ; /

		;; 注意，从这里开始，一直到 `mov esp, StackTop'，中间坚决不能用 push/pop 指令，
		;; 因为当前 esp 指向 proc_table 里的某个位置，push 会破坏掉进程表，导致灾难性后果！

		mov		esi, edx	; 保存 edx，因为 edx 里保存了系统调用的参数
							;（没用栈，而是用了另一个寄存器 esi）
        mov     dx, ss
        mov     ds, dx
        mov     es, dx
		mov		fs, dx

		mov		edx, esi	; 恢复 edx

		; 上面push了保存的參數，所以目前esp所指向的就是保存參數的頭
		; 目前esp還是指向每個 process 的 stack
		; 因為返回位置還記錄在 proc stack，所以這邊要保存起來，下面返回的時候會用到
        mov     esi, esp                    ;esi = 进程表起始地址

        inc     dword [k_reenter]           ;k_reenter++;
        cmp     dword [k_reenter], 0        ;if(k_reenter ==0)
        jne     .1                          ;{

        ; StackTop為 kernel stack，這邊就是切換到內核棧，這看來是固定值
        mov     esp, StackTop               ;  mov esp, StackTop <--切换到内核栈

        push    restart                     ;  push restart for retaddr

        ; 這個位置為"呼叫 save 的 function" 的下一條指令位置，因為會有兩個地方 call save
        ; 因為esi是process的stack，加上( RETADR - P_STACKBASE)，就是function call的位置
        ; 假設是sys_call呼叫的save的話，jmp這條指令就是跳到 sti 那邊去
        ; 而sys_call 返回時，則是會跑到 restart or restart_reenter
        jmp     [esi + RETADR - P_STACKBASE];  return;

.1:                                         ;} else { 已经在内核栈，不需要再切换
        push    restart_reenter             ;  push restart_reenter for retaddr
        jmp     [esi + RETADR - P_STACKBASE];  return;
                                            ;}


; =============================================================================
;                                 sys_call
; =============================================================================
sys_call:
		; 從 process 進入此時，ESP就會被 cpu 設成tss.esp，並且 cpu 還會push 5個參數進去
        call    save

		; 經過了 save，會把stack換成 kernel stack
        sti

        ; 因為 esi 目前是 process stack 的位置(在save中保存)，這邊先保存起來
		push	esi

		push	dword [p_proc_ready]
		push	edx
		push	ecx
		push	ebx

        ; 目前sys_call_table只有兩個function, sys_call_table[NR_SYS_CALL] = {sys_printx, sys_sendrec};
        ; 而send functin 參數如右 sys_sendrec(int function, int src_dest, MESSAGE* m, struct proc* p)

        call    [sys_call_table + eax * 4] ; 利用 eax 來選擇 function

		add	esp, 4 * 4  ; 還原上面4個參數

		pop	esi

		; 放入 function 返回值？
        mov     [esi + EAXREG - P_STACKBASE], eax
        cli
        ret      ; 這邊的retrun 應該是 save function中，restart or restart_reenter這兩個值


; ====================================================================================
;                                   restart
; ====================================================================================
restart:
	; 這個動作開始切換process, sys_call 裡面所執行的function 很可能會把p_proc_ready給換掉
	mov	esp, [p_proc_ready]             ; p_proc_ready 為一個 PROCESS 的 struct, 最前頭就是該process所保存的reg
										; 所以把他變成 ESP之後，就可以用來還原 process 的 reg, 包括 return address

	lldt	[esp + P_LDT_SEL]           ; P_LDT_SEL 對應到 PROCESS 中的 ldt_sel，把該位置的"值"，指給lldt
										; 類似 mov ldt, [esp + P_LDT_SEL]


	lea	eax, [esp + P_STACKTOP]         ; 有點類似 eax = esp + P_STACKTOP,
										; for ex: esp(0x4d370) + P_STACKTOP(0x48) = 0x4d3b8
										; 與 mov 不同的是，lea 不是取該位置儲存的值，而是直接取位址
										; 讓 eax 指向該 proc 做  push 之前的 esp 位置


	mov	dword [tss + TSS3_S_SP0], eax   ; EAX 目前就是 proc 結構中，register 所保存的起點
										; 這個值會被設給 tss.esp0，當int發生時，cpu會拿這個值當作esp後，把 register push進去

restart_reenter:
	dec	dword [k_reenter]
	pop	gs
	pop	fs
	pop	es
	pop	ds
	popad             ; popad will ingore ESP
	add	esp, 4

	iretd             ; 切換process, 利用 iretd 會還原 process 的 ESP, SS:IP，eflag .. 的特性
