include ./makefile.header

SHOW_CMD = @

NASM = nasm
NASM_FLG = -I inc/ -f elf

ASMBFLAGS	= -I $(DIR_BOOTLOADER)/include/
ORANGESBOOT	=  $(DIR_BOOTLOADER)/boot.bin  $(DIR_BOOTLOADER)/loader.bin

#======== Folder =======
DIR_BOOT = ./boot
DIR_BOOTLOADER = ./bootloader
DIR_KERENL = ./kernel
DIR_LIB = ./lib
DIR_FS = ./fs
DIR_MM = ./mm


#======== Flag ========
LDFLAGS_BOOT = $(LDFLAGS) -Ttext 0
LDFLAGS_SYS = $(LDFLAGS) -Ttext 0 -e startup_32

ASMKFLAGS = -I $(INC_FD) 

OBJ_BOOT_BIN = \
	$(DIR_BOOTLOADER)/boot.asm  \
	$(DIR_BOOTLOADER)/include/load.inc \
	$(DIR_BOOTLOADER)/include/fat12hdr.inc \

OBJ_BOOT_LOADER = \
	$(DIR_BOOTLOADER)/loader.asm  \
	$(DIR_BOOTLOADER)/include/load.inc \
	$(DIR_BOOTLOADER)/include/fat12hdr.inc \
	$(DIR_BOOTLOADER)/include/pm.inc \

OBJ_FILES = \
	$(OBJDIR)/head.o  \
	$(OBJ_LIB) \
	$(OBJ_KERNEL) \
	$(OBJ_FS) \
	$(OBJ_MM) \
	
	
OBJ_LIB = \
	$(DIR_LIB)/kliba.o  \
	$(DIR_LIB)/klib.o  \
	$(DIR_LIB)/string.o  \
	$(DIR_LIB)/misc.o  \
	$(DIR_LIB)/open.o  \
	$(DIR_LIB)/close.o  \
	$(DIR_LIB)/read.o  \
	$(DIR_LIB)/write.o  \
	$(DIR_LIB)/syslog.o  \
	$(DIR_LIB)/getpid.o  \
	$(DIR_LIB)/unlink.o  \
	$(DIR_LIB)/fork.o  \
	
OBJ_KERNEL = \
	$(DIR_KERENL)/main.o  \
	$(DIR_KERENL)/sched.o  \
	$(DIR_KERENL)/start.o  \
	$(DIR_KERENL)/protect.o  \
	$(DIR_KERENL)/kernel.o  \
	$(DIR_KERENL)/i8259.o  \
	$(DIR_KERENL)/global.o  \
	$(DIR_KERENL)/clock.o  \
	$(DIR_KERENL)/syscall.o  \
	$(DIR_KERENL)/proc.o  \
	$(DIR_KERENL)/keyboard.o  \
	$(DIR_KERENL)/tty.o  \
	$(DIR_KERENL)/console.o  \
	$(DIR_KERENL)/printf.o  \
	$(DIR_KERENL)/vsprintf.o  \
	$(DIR_KERENL)/systask.o  \
	$(DIR_KERENL)/hd.o  \
	
OBJ_FS = \
	$(DIR_FS)/main.o  \
	$(DIR_FS)/open.o  \
	$(DIR_FS)/misc.o  \
	$(DIR_FS)/read_write.o  \
	$(DIR_FS)/disklog.o  \
	$(DIR_FS)/link.o  \
	
OBJ_MM = \
	$(DIR_MM)/main.o  \
	$(DIR_MM)/forkexit.o  \


OBJ_FILES += $(OBJ_UNIT_TEST)
DIR_UNIT_TEST = ./unit_test
OBJ_UNIT_TEST = \
	$(DIR_UNIT_TEST)/ericut.o  \
	
.PHONY : everything

# === Rule ===
all: clean mkdir system.img nm diasm

system.img: $(DIR_BOOT)/boot.bin $(DIR_BOOT)/setup.bin system.bin 
	$(SHOW_CMD)dd if=$(DIR_BOOT)/boot.bin    of=system.img bs=512 count=1 
	$(SHOW_CMD)dd if=$(DIR_BOOT)/setup.bin   of=system.img bs=512 count=4 seek=1
	$(SHOW_CMD)dd if=system.bin    of=system.img bs=512 count=2883 seek=5 conv=notrunc
	
buildimg: bootloader/boot.bin bootloader/loader.bin
	dd if=bootloader/boot.bin of=a.img bs=512 count=1 conv=notrunc
	sudo umount /mnt/floppy/
	sudo mount -o loop a.img /mnt/floppy/
	sudo cp -fv bootloader/loader.bin /mnt/floppy/
	sudo cp -fv system.bin /mnt/floppy
	sudo umount /mnt/floppy

bootloader/boot.bin : $(OBJ_BOOT_BIN)
	$(NASM) $(ASMBFLAGS) -o $@ $<

bootloader/loader.bin : $(OBJ_BOOT_LOADER)
	$(NASM) $(ASMBFLAGS) -o $@ $<
	
	
system.bin: head.o $(OBJ_FILES)
	$(SHOW_CMD)$(LD) $(LDFLAGS_SYS) $(OBJ_FILES) -o system.elf
	$(SHOW_CMD)$(OBJCOPY) $(TRIM_FLAGS) system.elf system.bin
	$(SHOW_CMD)$(OBJCOPY) --only-keep-debug system.elf system.sym
	
boot/boot.bin:
	$(SHOW_CMD)make -C boot
	
head.o: head.s
	$(SHOW_CMD)$(AS) $(ASFLAG) $(OBJDIR)/head.o head.s

# == rule for kernel/ ==
$(DIR_KERENL)/%.o: $(DIR_KERENL)/%.asm
	$(SHOW_CMD)$(NASM) $(NASM_FLG) $< -o $@

$(DIR_KERENL)/%.o: $(DIR_KERENL)/%.c
	$(SHOW_CMD)$(CC) $(CFLAGS) $< -o $@  
	
# == rule for lib/ ==
$(DIR_LIB)/%.o: $(DIR_LIB)/%.asm
	$(SHOW_CMD)$(NASM) $(NASM_FLG) $< -o $@
	
$(DIR_LIB)/%.o: $(DIR_LIB)/%.c
	$(SHOW_CMD)$(CC) $(CFLAGS) $< -o $@
	
# == rule for fs/*.c ==
$(DIR_FS)/%.o: $(DIR_FS)/%.c
	$(SHOW_CMD)$(CC) $(CFLAGS) $< -o $@

# == rule for mm/*.c ==
$(DIR_MM)/%.o: $(DIR_MM)/%.c
	$(SHOW_CMD)$(CC) $(CFLAGS) $< -o $@
	
	
# ut
$(DIR_UNIT_TEST)/%.o: $(DIR_UNIT_TEST)/%.c
	$(SHOW_CMD)$(CC) $(CFLAGS) $< -o $@    
	
# == rule for /*.c ==
%.o: %.c
	$(SHOW_CMD)$(CC) $(CFLAGS) $< -o $(OBJDIR)/$@  
	
nm:
	$(SHOW_CMD)nm system.elf |sort > system.nm
	$(SHOW_CMD)awk '{ print $$1" "$$3 }' system.nm > system.bsb
	
diasm:
	$(SHOW_CMD)objdump -S  system.elf > system.diasm

clean:
	$(SHOW_CMD)make -C boot clean
	$(SHOW_CMD)rm -rf *.o *.elf *.bin system.img *.nm *.bsb *.diasm
	$(SHOW_CMD)rm -rf $(OBJ_FILES)
	$(SHOW_CMD)rm -rf $(OBJDIR)

#=== make dir ===
$(OBJDIR):
	$(SHOW_CMD)mkdir -p $@
	
mkdir: $(OBJDIR)

#=== make dir ===
qemu: 
	sudo qemu-system-i386 -fda system.img -hda 80.img -boot a
	
