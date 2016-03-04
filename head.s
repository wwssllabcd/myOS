/*
 *  linux/boot/head.s
 *
 *  (C) 1991  Linus Torvalds
 */

/*
 *  head.s contains the 32-bit startup code.
 *
 * NOTE!!! Startup happens at absolute address 0x00000000, which is also where
 * the page directory will exist. The startup code will be overwritten by
 * the page directory.
 */
.text
.globl idt_h, gdt_h, pg_dir, tmp_floppy_area
pg_dir:
.globl startup_32

startup_32:
	movl $0x10, %eax         # 0x10 代表載入 GDT segment 2
	mov %ax,%ds
	mov %ax,%es
	mov %ax,%fs
	mov %ax,%gs

	movl $0x18,%eax
	mov %ax, %gs
	mov $((80*2 + 0)*2), %edi
	mov $0x0C, %ah          #黑底紅字
	mov $'0', %al
	mov %ax, %gs:(%edi)

	# load ss, 把stack_start這個位置所存放的資料指ESP, +2byte的指給SS( ex: lee esp ds:74f8)
	# 但載入的值跟nm file 給出來的offset 差了0x1000，因為在給值的時候是故意給最尾端的值而非最前端，
	# 就像是 tmp=&user_stack 與 tmp=&user_stack[size] 的差異
	lss stack_start, %esp

	call setup_idt          # 初始IDT, 即把每個 interrup 都填成 ignore_int(即unknow interrup，啞中斷)的位置
	call setup_gdt          # 單純 load gdt desc

	movl $0x10,%eax		    # reload all the segment registers
	mov %ax,%ds		        # after changing gdt. CS was already
	mov %ax,%es		        # reloaded in 'setup_gdt'
	mov %ax,%fs
	mov %ax,%gs
	lss stack_start,%esp

	xorl %eax,%eax          # eax=0
1:	incl %eax		        # check that A20 really IS enabled
	movl %eax,0x000000	    # loop forever if it isn't
	cmpl %eax,0x100000      # 檢查 0x000000 與 0x100000 的值相, 如果相同，就跳到標號1, 代表沒開A20
	je 1b                   # 1b的B代表 back，1b 代表 back to tag 1

/*
 * NOTE! 486 should set bit 16, to check for write-protect in supervisor
 * mode. Then it would be unnecessary with the "verify_area()"-calls.
 * 486 users probably want to set the NE (#5) bit also, so as to use
 * int 16 for math errors.
 */
	movl %cr0,%eax		    # check math chip
	andl $0x80000011,%eax	# Save PG,PE,ET
/* "orl $0x10020,%eax" here for 486 might be good */
	orl $2,%eax		# set MP
	movl %eax,%cr0
	call check_x87
	jmp after_page_tables  #//最後一個指令，且不會再回來, jmp到0x5400

/*
 * We depend on ET to be correct. This checks for 287/387.
 */
check_x87:
	fninit
	fstsw %ax
	cmpb $0,%al
	je 1f			/* no coprocessor: have to set bits */
	movl %cr0,%eax
	xorl $6,%eax		/* reset MP, set EM */
	movl %eax,%cr0
	ret
.align 2
1:	.byte 0xDB,0xE4		/* fsetpm for 287, ignored by 387 */
	ret

/*
 *  setup_idt
 *
 *  sets up a idt with 256 entries pointing to
 *  ignore_int, interrupt gates. It then loads
 *  idt. Everything that wants to install itself
 *  in the idt-table may do so themselves. Interrupts
 *  are enabled elsewhere, when we can be relatively
 *  sure everything is ok. This routine will be over-
 *  written by the page tables.
 */
setup_idt:
	# 以下的動作為先把啞中斷的Segment Descriptor建立在eax中，再把這個中斷，填滿idt(256條)
	lea  ignore_int, %edx  # 把 ignore_int(ds:5428h，可由nm檔看出) 這標籤的 address 值，放到 edx 中
	movl $0x00080000, %eax # 設定 eax 的高2 byte, selector = 0x0008 = cs
	movw %dx, %ax		   # 設定 eax 的低2 byte，把 eax 組合成 segment selector(前2 byte) + offset(後2 byte)(idt 可見 linux 011, P222)
	movw $0x8E00, %dx	   # edx 的低 2 byte 是設定權限，固定為 0x8E00, interrupt gate - dpl=0, present
	lea idt_h, %edi          # 把 idt(ds:54b8h，可由nm檔看出)的位置，放到 edi 中, 以此例來說 edi=0x54b8
	mov $256, %ecx         # 設置repeat 256次, 因為idt最多256個, 而 idt 在本檔案的最後面，為256個item, 所以大小為 256*8 = 2048

rp_sidt:
	movl %eax,(%edi)       # 把 eax 的值(也就是啞中斷的Segment Descriptor)，放入到edi所指的"位置"中
	movl %edx,4(%edi)      # edx 目前是權限，放到 edi 後面 4 BYTE，可見idt結構應為 8 byte
	addl $8,%edi           # 移動edi+=8
	dec %ecx               # ecx為次數

	#會填成 ( low->high) 0008,5428,0000,8E00

	jne rp_sidt
	lidt idt_descr         # load idt table的位置到iDPTR(lidt ds:0x54a4，其內容為 FF,07,B8,54，即IDT位置)
	ret

/*
 *  setup_gdt
 *
 *  This routines sets up a new gdt and loads it.
 *  Only two entries are currently built, the same
 *  ones that were built in init.s. The routine
 *  is VERY complicated at two whole lines, so this
 *  rather long comment is certainly needed :-).
 *  This routine will beoverwritten by the page tables.
 */
setup_gdt:
	lgdt gdt_descr    # 使用lgdt 把 gdt_descr 的位置載入到 GDTR
	ret

/*
 * I put the kernel page tables right after the page directory,
 * using 4 of them to span 16 Mb of physical memory. People with
 * more than 16MB will have to expand this.
 */
.org 0x1000
pg0:

.org 0x2000
pg1:

.org 0x3000
pg2:

.org 0x4000
pg3:

.org 0x5000
/*
 * tmp_floppy_area is used by the floppy-driver when DMA cannot
 * reach to a buffer-block. It needs to be aligned, so that it isn't
 * on a 64kB border.
 */
tmp_floppy_area:
	.fill 1024,1,0

after_page_tables:
	# 這裡的ip值應為0x5400
	pushl $0		 # These are the parameters to main :-)
	pushl $0
	pushl $0
	pushl $L6		 # return address for main, if it decides to.(如果不小心從main return時，會jump到L6)
	pushl $start_k      # 預計返回的時候跳到main

	# 這邊使用 jmp 而不使用 call 的原因是因為 call 會把current ip壓入 stack, 而jmp不會，
	# 而ret指令會把stack pop出來，而setup_paging這邊結束時故意會寫ret，好讓之前push到stack的main可以pop出來到CS:IP
	jmp setup_paging
L6:
	jmp L6			 # main should never return here, but
				     # just in case, we know what happens.

/* This is the default interrupt "handler" :-) */
int_msg:
	.asciz "Unknown interrupt\n\r"
.align 2
ignore_int:
	pushl %eax  # backup register
	pushl %ecx
	pushl %edx  # end backup
	push %ds    # backup segment register
	push %es
	push %fs
	movl $0x10,%eax
	mov %ax,%ds
	mov %ax,%es
	mov %ax,%fs
	pushl $int_msg
	//call printk
	popl %eax
	pop %fs
	pop %es
	pop %ds
	popl %edx   # restore register
	popl %ecx
	popl %eax
	iret


/*
 * Setup_paging
 *
 * This routine sets up paging by setting the page bit
 * in cr0. The page tables are set up, identity-mapping
 * the first 16MB. The pager assumes that no illegal
 * addresses are produced (ie >4Mb on a 4Mb machine).
 *
 * NOTE! Although all physical memory should be identity
 * mapped by this routine, only the kernel page functions
 * use the >1Mb addresses directly. All "normal" functions
 * use just the lower 1Mb, or the local data space, which
 * will be mapped to some other place - mm keeps track of
 * that.
 *
 * For those with more memory than 16 Mb - tough luck. I've
 * not got it, why should you :-) The source is here. Change
 * it. (Seriously - it shouldn't be too difficult. Mostly
 * change some constants etc. I left it at 16Mb, as my machine
 * even cannot be extended past that (ok, but it was cheap :-)
 * I've tried to show which constants to change by having
 * some kind of marker at them (search for "16Mb"), but I
 * won't guarantee that's all :-( )
 */
.align 2
setup_paging:
	movl $1024*5,%ecx		#/* 5 pages - pg_dir+4 page tables , 這邊的cx應該是當作count */
	xorl %eax,%eax          # clear eax & edi
	xorl %edi,%edi			#/* pg_dir is at 0x000 */
	cld;                    # cld即告訴程序si，di向前移動
	rep;                    # cx當cnt,repeat下面動作

	# STOSL指令相當於將EAX中的值保存到ES:EDI指向的地址中，
	# 若設置了EFLAGS中的方向位置位(即在STOSL指令前使用STD指令)則EDI自減4，否則(使用CLD指令)EDI自增4。
	stosl

	# pg0~3與，各是0x1000~0x4FFF, pg_dir是本段的開頭
	# page table 是用來管理記憶體的，4byte 管理4k
	# pg0 = 0x1000, pg_dir=0
	movl $pg0+7,pg_dir		# 把每個 $page+7的位置，也就是把0x1007這個值，放到 addr=0的位置，7代表可讀寫
	movl $pg1+7,pg_dir+4	# pg_dir 位在 addr=0的位置，這邊把$pg0+7(也就是0x1007)，存入addr=0的位置
	movl $pg2+7,pg_dir+8	#  而這邊的 code 不會被蓋到的原因是因為 這段code 放在 .org 0x5000 的原因
	movl $pg3+7,pg_dir+12

	movl $pg3+4092,%edi     # 現在要把pageTable填滿，方法是從最後一項往前填，pg3+4092代表最後一項
	movl $0xfff007,%eax		#/*  16Mb - 4096 + 7 (r/w user,p) */
	std                     # 在STOSL指令前使用STD指令)則EDI自減4

	# 以下會把 0x4FFC ~ 0x1000都填成  00000007,00001007,00002007, ~ FFFD007,FFE007, FFF007
1:	stosl			        #/* fill pages backwards - more efficient :-) */
	subl $0x1000,%eax       #// 利用eax 遞減0x1000, 把所有的page table的值填正確, 如fff007,ffE007,fffD007等
	jge 1b
	cld
	xorl %eax,%eax		   #/* pg_dir is at 0x0000 */
	movl %eax,%cr3		   #/* cr3 - page directory start */
	movl %cr0,%eax
	orl $0x80000000,%eax
	movl %eax,%cr0		   #/* set paging (PG) bit */
	//跳到 main的位置
	ret			           #/* this also flushes prefetch-queue */

.align 2
.word 0

# the GDT Register, or simply the GDTR. The GDTR is 48 bits long.
# The lower 16 bits tell the size of the GDT, and the upper 32 bits tell the location of the GDT in memory.
idt_descr:          # 6 byte, 低的2 byte, 代表table長度, 高的4 byte為 table 所在的offset , 同 gdt descriptor
	.word 256*8-1	# idt contains 256 entries，其值為 0x7FF
	.long idt_h       # 大概是idt的 address

.align 2
.word 0
gdt_descr:          # 低的2 byte, 代表table長度, 高的4 byte為 table 所在的offset , 同 idt descriptor
	.word 256*8-1	# so does gdt (not that that's any
	.long gdt_h		# magic number, but it works for me :^)

	.align 8

idt_h:	.fill 256,8,0		# idt is uninitialized

gdt_h:
	# 見linux 011, P91
	.quad 0x0000000000000000	/* NULL descriptor */
	.quad 0x00c09a0000000fff	/* 16Mb */
	.quad 0x00c0920000000fff	/* 16Mb */

	//段3, 0x18, Graphic Card
	.quad 0x00C0920B8000FFFF

	.quad 0x0000000000000000	/* TEMPORARY - don't use */

	.fill 251,8,0			/* space for LDT's and TSS's etc */

/*
設定GDT, 每條Segment Descriptor 各8 BYTE, 如0x00c0,9a00,0000,0fff
LSM的最後16 bit為限制長度，這邊為0x0FFF代表限制4096個單位，也就是 4k*4096 = 16M

第0個段為NULL(規定)
第1個段的參數為0x9A，可知為 可執行/可讀的 code段
第2個段的參數為0x92，可知為 可讀/寫的 data段

而這兩個段的base都是指向0的位置，這裡的資料同setup.S所設定的一樣，不一樣的是，這個table是位在 address 0 的地方(setup的是在0x92000)
*/





