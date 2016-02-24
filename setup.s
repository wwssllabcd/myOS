.code16
.equ INITSEG, 0x9000	# we move boot here - out of the way
.equ SYSSEG, 0x1000	    # system loaded at 0x10000 (65536).
.equ SETUPSEG, 0x9020	# this is the current segment

_start:
	ljmp $SETUPSEG, $_start_s	 # setup.s是放在 0x90200的位置

# string should be here
str_S0:      .ascii "0"
str_S1:      .ascii "1"
str_S2:      .ascii "2"
str_S3:      .ascii "3"

DispStr:
	push %ax
	push %es

	# reset es to SETUPSEG
	mov	$SETUPSEG, %ax
    mov %ax, %es

	mov $0x1301, %ax      # AH = 13, AL = 01h
	mov $0x000C, %bx      # 頁號為0(BH = 0) 黑底紅字(BL = 0Ch,高亮)
	int $0x10             # 10h 號中斷

	pop %es
	pop %ax
	ret

_start_s:
	#===================
	mov	$0x91000, %sp

	mov	$str_S0, %bp
	mov	$0x1, %cx
	mov	$0x0100, %dx
	call DispStr

	#init all segment
	mov	$INITSEG, %ax	# this is done in bootsect already, but...
	mov	%ax, %ds

	mov	$0x03, %ah	# read cursor pos
	xor	%bh, %bh
	int	$0x10		# save it in known place, con_init fetches # 使用int10, AH=3 先讀取 cursor 位置
	mov	%dx, %ds:0	# it from 0x90000.                         # 把 DX(XY軸) 存入 0x90000 的位置

# Get memory size (extended mem, kB)
	mov	$0x88, %ah      # int 15, AH = 0x88, 取得記憶體大小，為0x00FC
	int	$0x15
	mov	%ax, %ds:2      # 0x90002

# Get video-card data:
	mov	$0x0f, %ah      # int 10, AH= 0x0F = Get current video mode, return AL = Video Mode
	int	$0x10
	mov	%bx, %ds:4	# bh = display page, val=0x0C00
	mov	%ax, %ds:6	# al = video mode, ah = window width, val=0x0350

# check for EGA/VGA and some config parameters

	mov	$0x12, %ah
	mov	$0x10, %bl
	int	$0x10
	mov	%ax, %ds:8      # val=0x0312
	mov	%bx, %ds:10     # val=0x0300
	mov	%cx, %ds:12     # val=0x0900

	#===================
	mov	$str_S1, %bp
	mov	$0x1, %cx
	mov	$0x0101, %dx
	call DispStr

read_HDA0:
# Get hd0 data

	# 這邊取中斷向量編號 0x41 號的值, 因為一個中斷佔4個byte, 所以No 41h所在的offset其實就是41*4 = 0x104h
	# 其實 記憶體 0 ~ 0x3FF(共400H) 提供給中斷向量表使用,可搜尋關鍵字 "BIOS中斷向量表"
	
	mov	$0x0000, %ax
	mov	%ax, %ds
	lds	%ds:4*0x41, %si

	mov	$INITSEG, %ax
	mov	%ax, %es
	mov	$0x0080, %di   # 目的地ES:DI = 0x90080
	mov	$0x10, %cx     # cx register通常拿來當cnt, 也就是 for loop中的 i
	rep
	movsb              # 從 DS:SI->ES:DI，一次一個BYTE，共 copy 16 個 BYTE

# Get hd1 data
	mov	$0x0000, %ax
	mov	%ax, %ds
	lds	%ds:4*0x46, %si
	mov	$INITSEG, %ax
	mov	%ax, %es
	mov	$0x0090, %di   # 目的地ES:DI = 0x90090
	mov	$0x10, %cx
	rep
	movsb

	# Check that there IS a hd1 :-)
	# int 15, AH = 15 => Read Drive Type
	mov	$0x01500, %ax
	mov	$0x81, %dl      # DL = drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)
	int	$0x13


	# res => CF = 0
	jc	no_disk1        # CF = 0 if successful, CF = 1 if error
	cmp	$3, %ah         # AH = 03, 代表為HD, 01 = diskette, no change detection present(這邊的AH=0x01)
	je	is_disk1

no_disk1:
	mov	$INITSEG, %ax
	mov	%ax, %es
	mov	$0x0090, %di    # ES:DI = 0x90090
	mov	$0x10, %cx      # 當作 stosb 的 count
	mov	$0x00, %ax      # 準備要把ES:DI存成0
	rep
	stosb               # STOSB 是將 AX 存放到 ES:DI 的位置，並根據 DF 來遞增 (DF = 0) 或遞減 (DF = 1) DI，以指向下一個位置

is_disk1:
	#===================
	mov	$str_S2, %bp
	mov	$0x1, %cx
	mov	$0x0102, %dx
	call DispStr

# now we want to move to protected mode ...

	cli			      # clear interrupt, no interrupts allowed !

# first we move the system to it's rightful place

	mov	$0x0000, %ax
	cld			      # 'direction'=0, movs moves forward



do_move:
	mov	%ax, %es	  # ES設為0
	add	$0x1000, %ax  # ax從 0x1000開始，到0x9000結束，每次加0x1000
	cmp	$0x9000, %ax  # 是否到9000的位置了？
	jz	end_move

	mov	%ax, %ds	  # source segment
	mov $0x20, %cx    # cx當作cnt, 以word方式來移動，也就是一次移動0x1w byte，到9w為止
	sub	%di, %di      # clear di, si to 0
	sub	%si, %si
	rep
	movsw             # 從 [ds:si]->[es:di] ，把 0x1w ~ 0x9w 移到 0x0 ~ 0x8w, 平移1wh, 也就是說內核大小不會超過512k

	# 做完此動作後不能使用任何int，包括顯示用的 int 10，因為ISR被蓋過去了
	# 32保護模式的ISR會被idt取代
	jmp	do_move

# then we load the segment descriptors

end_move:
	mov	$SETUPSEG, %ax	# right, forgot this at first. didn't work :-)  #0x9020
	mov	%ax, %ds        # ds 設為 0x9020
	lidt	idt_48		# load idt with 0,0
	lgdt	gdt_48		# load gdt with whatever appropriate

# that was painless, now we enable A20

	#call	empty_8042	# 8042 is the keyboard controller
	#mov	$0xD1, %al	# command write
	#out	%al, $0x64
	#call	empty_8042
	#mov	$0xDF, %al	# A20 on
	#out	%al, $0x60
	#call	empty_8042
	inb     $0x92, %al	# open A20 line(Fast Gate A20).
	orb     $0b00000010, %al
	outb    %al, $0x92

# well, that went ok, I hope. Now we have to reprogram the interrupts :-(
# we put them right after the intel-reserved hardware interrupts, at
# int 0x20-0x2F. There they won't mess up anything. Sadly IBM really
# messed this up with the original PC, and they haven't been able to
# rectify it afterwards. Thus the bios puts interrupts at 0x08-0x0f,
# which is used for the internal hardware interrupts as well. We just
# have to reprogram the 8259's, and it isn't fun.

	mov	$0x11, %al		# initialization sequence(ICW1)
					# ICW4 needed(1),CASCADE mode,Level-triggered
	out	%al, $0x20		# send it to 8259A-1
	.word	0x00eb,0x00eb		# jmp $+2, jmp $+2
	out	%al, $0xA0		# and to 8259A-2
	.word	0x00eb,0x00eb
	mov	$0x20, %al		# start of hardware int's (0x20)(ICW2)
	out	%al, $0x21		# from 0x20-0x27
	.word	0x00eb,0x00eb
	mov	$0x28, %al		# start of hardware int's 2 (0x28)
	out	%al, $0xA1		# from 0x28-0x2F
	.word	0x00eb,0x00eb		#               IR 7654 3210
	mov	$0x04, %al		# 8259-1 is master(0000 0100) --\
	out	%al, $0x21		#				|
	.word	0x00eb,0x00eb		#			 INT	/
	mov	$0x02, %al		# 8259-2 is slave(       010 --> 2)
	out	%al, $0xA1
	.word	0x00eb,0x00eb
	mov	$0x01, %al		# 8086 mode for both
	out	%al, $0x21
	.word	0x00eb,0x00eb
	out	%al, $0xA1
	.word	0x00eb,0x00eb
	mov	$0xFF, %al		# mask off all interrupts for now
	out	%al, $0x21
	.word	0x00eb,0x00eb
	out	%al, $0xA1

# well, that certainly wasn't fun :-(. Hopefully it works, and we don't
# need no steenking BIOS anyway (except for the initial loading :-).
# The BIOS-routine wants lots of unnecessary data, and it's less
# "interesting" anyway. This is how REAL programmers do it.
#
# Well, now's the time to actually move into protected mode. To make
# things as simple as possible, we do no register set-up or anything,
# we let the gnu-compiled 32-bit programs do that. We just jump to
# absolute address 0x00000, in 32-bit protected mode.
	#mov	$0x0001, %ax	# protected mode (PE) bit
	#lmsw	%ax		# This is it!
	mov	%cr0, %eax	# get machine status(cr0|MSW)	
	bts	$0, %eax	# turn on the PE-bit 
	mov	%eax, %cr0	# protection enabled

jmp2Protect:
	# segment-descriptor        (INDEX:TI:RPL)
	.equ	sel_cs0, 0x0008 # select for code segment 0 (  001:0 :00) 
	# seg = 8 ，就是段 1的位置
	ljmp	$sel_cs0, $0	# jmp offset 0 of code segment 0 in gdt

# This routine checks that the keyboard command queue is empty
# No timeout is used - if this hangs there is something wrong with
# the machine, and we probably couldn't proceed anyway.
empty_8042:
	.word	0x00eb,0x00eb
	in	$0x64, %al	# 8042 status port
	test	$2, %al		# is input buffer full?
	jnz	empty_8042	# yes - loop
	ret

gdt:    # gdt table 目前設定如下, 每段為8個byte, 例如載入第一段，就是設 cS = 8, 而bit1~bit3拿來當作 flag
	#段0 = dummy
	.word	0,0,0,0		# dummy

	# 段1，這裡就是offset 8, code 的gdt,
	# 0x00C09A00: 一小部分的基底位置 + 權限，這邊設定是可讀寫的代碼段
	# 0x000007FF: 段限長為8MB，基底位置為0
	.word	0x07FF		# 8Mb - limit=2047 (2048*4096=8Mb)
	.word	0x0000		# base address=0
	.word	0x9A00		# code read/exec
	.word	0x00C0		# granularity=4096, 386

	#段2, 0x10
	.word	0xffFF		# 8Mb - limit=2047 (2048*4096=8Mb)
	.word	0x0000		# base address=0
	.word	0x9200		# data read/write
	.word	0x00C0		# granularity=4096, 386

	#段3, 0x18, Graphic Card
	.word	0xFFFF		# 8Mb - limit=2047 (2048*4096=8Mb)
	.word	0x8000		# base address=0
	.word	0x920B		# data read/write(DA_DRW)
	.word	0x00C0		# granularity=4096, 386




idt_48:
	.word	0			# idt limit=0
	.word	0,0			# idt base=0L

gdt_48:
	.word	0x800			# gdt limit=2048, 256 GDT entries
	.word   512+gdt, 0x9	# gdt base = 0X9xxxx,   # 加 512的原因是否為 0x90200 的 0x200，也就是 setup.s的位置
							# 逗號代表連續賦值,
	# 512+gdt is the real gdt after setup is moved to 0x9020 * 0x10
	
.text
endtext:
.data
enddata:
.bss
endbss:



