.code16       #使用16位模式彙編, AT&T( GAS )語法

.equ SETUPLEN, 4		# nr of setup-sectors，boot相關的使用4個sector
.equ BOOTSEG, 0x07C0		# original address of boot-sector
.equ INITSEG, 0x9000		# we move boot here - out of the way
.equ SETUPSEG, 0x9020

.equ SYSSEG, 0x1000		    # system loaded at 0x10000 (65536).
.equ SYSSIZE, 0x3000
.equ ENDSEG, SYSSEG + SYSSIZE	# where to stop loading

.equ ROOT_DEV, 0x301        # 這邊代表要讀取那個裝置，0x301是讀取/dev/hda1，也可以替換其他裝置

.equ DX_SAVE, 0x07C0

#保留給游標 X,Y 使用DX register
dx_reg: .word 0x0000



	#ljmp CS,IP: 因為目前就是在07C0的位置，所以若要跳到 _start這個位置，而這個位置就是0x7C00 + _start 的 offset 的地方
	#又因為CS是少一個0，所以這邊要填0x7C00變成0x07C0
	ljmp $BOOTSEG, $_start

_start:
	#CS 因為ljmp的關係，現在應該是0x07C0，他把所有的segment(ds,es)都設成CS所在的區段
	mov	%cs,%ax
	mov	%ax,%ds
	mov	%ax,%es
	mov	$0xFF00, %sp

MovDataTo9k:

	# %bp is string位置, %cx為長度
	mov	$str_0, %bp
	mov	$0x1, %cx
	mov	$0x0, %dx
	call DispStr

	# 從0x9000，也就是9w的地方開始，其原因是因為0~8FFFF的地方是之後系統使用
	# 所以init從9w開始就不會影響到系統，此處也是被規劃成RAM的位置
	mov	$BOOTSEG, %ax
	mov	%ax, %ds
	mov	$INITSEG, %ax
	mov	%ax, %es
	mov	$256, %cx        # cx = counter
	sub	%si, %si         # sub 是暫存器相減，清成0
	sub	%di, %di
	rep
	movsw                # 從 [ds:si]->[es:di]

	# show msg
	mov	$str_1, %bp
	mov	$0x1, %cx
	mov	$0x0001, %dx
	call DispStr


jumpTo9000:
	ljmp	$INITSEG, $go_9000

go_9000:
	mov	%cs, %ax
	mov	%ax, %ds
	mov	%ax, %es
	mov	%ax, %ss
	mov	$0xFF00, %sp   # 9FF00

ec_load_setup:
	# show msg
	mov	$str_2, %bp
	mov	$0x1, %cx
	mov	$0x0002, %dx
	call DispStr

    #不能直接指定數值給es, 否則編譯器會報錯
    # ES:BX是存放位置
    mov	$INITSEG, %ax
    mov %ax, %es

	mov	$0x0200, %bx        # addr=512, ES:BX=target, 由此可知這邊是要把data讀出來放到0x90200的位置
	mov	$0x0000, %dx        # drive 0, head 0
	mov	$0x0002, %cx        # sector 2, track 0, 把 sec 2 讀出來(chs mode 是以sec 1 作為開始)
	.equ    AX, 0x0200+SETUPLEN
	mov     $AX, %ax	    # 這邊的值為0x0204, AH是0x02號 service (把data放到ram), AL 為讀幾個 sector，代表讀4個sector出來
	int	$0x13		        # read it, INT 13H/AH=02H：讀取磁區

	jnc	ec_ok_load_setup  	    # ok - continue

	# if result = bad, 下reset disk cmd 之後，在跳到最前面，看起來沒有退路，讀到成功為止，否則就是死循環
	mov	$0x0000, %dx
	mov	$0x0000, %ax		# reset the diskette
	int	$0x13

ec_ok_load_setup:
	# set msg x,y
	# show msg
	mov	$str_3, %bp
	mov	$0x1, %cx
	mov	$0x0003, %dx
	call DispStr

ec_load_cy_sec:

# Get disk drive parameters, specifically nr of sectors/track
# 把CX的內容(也就是cy與 sec per track)存在cs:sectors+0 中，sector 為一位置，在最下面有定義
# 要知道目前硬碟的 sector 位在哪，才知道還剩多少沒有讀取
	mov	$0x00, %dl          # DL= drive No, int 13, AH=8 = get param
	mov	$0x0800, %ax		# AH=8 is get drive parameters
	int	$0x13               # INT 13h AH=08h: Read Drive Parameters, return dx,cx

	mov	$0x00, %ch          # clear high byte
	mov	%cx, %cs:sectors+0  # %cs means sectors per track, save SecPerTrack，這裡讀出來的是SecPerTrack = 0x12

# ok, we've written the message, now
# we want to load the system (at 0x10000)
	mov	$SYSSEG, %ax        # SYSSEG=0x1000,  system loaded at 0x10000 (65536)64k.
	mov	%ax, %es		    # segment of 0x010000

	call	read_it         # read_it 在下面
	call	kill_motor

	# After that we check which root-device to use. If the device is
	# defined (#= 0), nothing is done and the given device is used.
	# Otherwise, either /dev/PS0 (2,28) or /dev/at0 (2,8), depending
	# on the number of sectors that the BIOS reports currently.
	#seg cs

	mov	%cs:root_dev+0, %ax  # root_dev 使用code 的方式 hard code, 預設值為 0x301


	cmp	$0, %ax              # 檢查該直是否為 0   
	jne	root_defined         # jne (jump not equal) 	不等於則轉移 	檢查 zf=0
	#seg cs
	mov	%cs:sectors+0, %bx
	mov	$0x0208, %ax		# /dev/ps0 - 1.2Mb
	cmp	$15, %bx
	je	root_defined
	mov	$0x021c, %ax		# /dev/PS0 - 1.44Mb
	cmp	$18, %bx
	je	root_defined
undef_root:
	jmp undef_root
root_defined:
	#seg cs
	mov	%ax, %cs:root_dev+0

# after that (everyting loaded), we jump to
# the setup-routine loaded directly after
# the bootblock:

	# show msg
	mov	$str_4, %bp
	mov	$0x1, %cx
	mov	$0x0004, %dx
	call DispStr

jump_2_90200:
	ljmp	$SETUPSEG, $0  # 跳到0x90200，執行setup.S

# This routine loads the system at address 0x10000, making sure
# no 64kB boundaries are crossed. We try to load it as fast as
# possible, loading whole tracks whenever we can.
#
# in:	es - starting address segment (normally 0x1000)
#
sread:	.word 1+SETUPLEN	# sectors read of current track，預設值為 5(1+4)，因為前面4個是setup使用的，所以system的從sector 5號開始
head:	.word 0			    # current head
track:	.word 0			    # current track

#要把 system從磁碟讀到 0x10000 的位置，不讀到 0 的位置可能是怕蓋過 ISR
#之後要把 system 搬到 0 的位置時，是關閉 interrupt 的
read_it:
	mov		%es, %ax        # es已經被設定為 0x1000
	test	$0x0fff, %ax    # 測試 es 是否為 0x1000
die:	
	jne 	die				# es must be at 64kB boundary(也就是es = 0x1000)
	xor 	%bx, %bx		# bx 設為 0，代表資料存放位置為[ES:BX] = 0x1000:0
rp_read:
	#%es為目前讀了多少資料，ENDSEG為資料的尾端
	mov 	%es, %ax
 	cmp 	$ENDSEG, %ax	# have we loaded all yet? # sys_start = 0x1000, sts_end = 0x3000 ，所以大小為100個sector?
	jb		ok1_read        #
	ret
ok1_read:
	#這邊主要處理要讀多少sector, 還有讀完之後的offset為多少
	mov		%cs:sectors+0, %ax   # 讀取之前的 secPerTrack，值為12
	sub		sread, %ax       # ax = ax - sread, cs:sread = 5, 所以這邊ax會變成0x0d，還有0x0d個sector要讀，這邊先設好AL(要讀多少sector)
	mov		%ax, %cx

	shl		$9, %cx              # cx = cx*512 (這次讀多少 byte), shl = 左移9個bit
	add		%bx, %cx             # cx=cx+bx, cx代表這次讀了之後，offset會跑到哪裡(可能是之後要設回bx用)
	jnc 	ok2_read
	je 		ok2_read
	xor 	%ax, %ax
	sub 	%bx, %ax
	shr 	$9, %ax
ok2_read:
	call 	read_track
	mov 	%ax, %cx             # 本次讀多少sector 備份到 cx中，%ax = 0x000d, 第一次是讀  0xd個sector (0x12 - 5 )
	add 	sread, %ax       # ax = ax + sread , 應該會讀到sector 的尾巴，也就是0x12
	cmp 	%cs:sectors+0, %ax   # 比較ax，是否為secPerTrack(也就是判斷是否到尾巴)?如果相等，則ZF flag=1

	jne 	ok3_read             # 不等於，則jmp(x86中相對應的cmd為je)
	mov 	$1, %ax

	sub 	head, %ax
	jne 	ok4_read            # 如果cs:head==0，則jump 到 ok4_read
	incw    track
ok4_read:
	#設定 cs:head = 1，並清除ax
	mov	%ax, head
	xor	%ax, %ax
ok3_read:
	mov	%ax, sread
	shl	$9, %cx
	add	%cx, %bx              # 重新設定 bx(因為es:bx)到正確的offset
	jnc	rp_read
	mov	%es, %ax
	add	$0x1000, %ax
	mov	%ax, %es
	xor	%bx, %bx
	jmp	rp_read

read_track:
	push	%ax
	push	%bx
	push	%cx
	push	%dx

	mov	track, %dx   # cs:track 一開始是0, so dx=0
	mov	sread, %cx   # cx=5
	inc	%cx              # cx=cx+1, 這動作主要是設cl, 即把 sector+1 ( chs mode 以1為起始)
	mov	%dl, %ch         # dl 此時是 track, 設給ch

	mov	head, %dx    # 取 head
	mov	%dl, %dh		 # head 設到 %dh, DH = head number
	mov	$0, %dl          # DL = drive number ,DriveNo=0(means Drive A)
	and	$0x0100, %dx     # dx=dx&0x100, 跟0x100作 "&"動作, 這裡為限制 dl=0, dh不超過1

	#--------------------------------
	#INT 13h AH=02h: Read Sectors From Drive
	# AL 	Sectors To Read Count
	# CH 	Cylinder
	# CL 	Sector
	# DH 	Head
	# DL 	Drive
	# ES:BX 	Buffer Address Pointer
	mov	$2, %ah	         # int 13 (AH=2) , es:bx , AL = number of sectors to read (must be nonzero)
	int	$0x13

	jc	bad_rt

	pop	%dx
	pop	%cx
	pop	%bx
	pop	%ax
	ret
bad_rt:	mov	$0, %ax
	mov	$0, %dx
	int	$0x13
	pop	%dx
	pop	%cx
	pop	%bx
	pop	%ax
	jmp	read_track

#/*
# * This procedure turns off the floppy drive motor, so
# * that we enter the kernel in a known state, and
# * don't have to worry about it later.
# */
kill_motor:
	push	%dx
	mov		$0x3f2, %dx
	mov		$0, %al
	outsb
	pop		%dx
	ret




#=========================
#string addr= ES:BP = 串地址
#strLen = %cx
#screen X = %dl
#screen Y = %dH
DispStr:

	push %ax
	push %es

	#要把ES重設, 因為如果ES設離開了9000 or 7C0，string 會出不來，特別是經過load system那段組語，會改變ES的值
	mov	$BOOTSEG, %ax
    mov %ax, %es

	mov $0x1301, %ax      # AH = 13, AL = 01h
	mov $0x000C, %bx      # 頁號為0(BH = 0) 黑底紅字(BL = 0Ch,高亮)
	int $0x10             # 10h 號中斷

	pop %es
	pop %ax

	ret
sectors:
	.word 0

str_0:      .ascii "0"
str_1:      .ascii "1"
str_2:      .ascii "2"
str_3:      .ascii "3"
str_4:      .ascii "4"
str_5:      .ascii "5"
str_6:      .ascii "6"

.org 508
root_dev:
	.word ROOT_DEV
boot_flag:
	.word 0xAA55

	.text
	endtext:
	.data
	enddata:
	.bss
	endbss:


