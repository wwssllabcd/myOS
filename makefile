include ./makefile.header

NASM = nasm
NASM_FLG = -I inc/ -f elf

#======== Folder =======
DIR_BOOT = ./boot
DIR_KERENL = ./kernel
DIR_LIB = ./lib


#======== Flag ========
LDFLAGS_BOOT = $(LDFLAGS) -Ttext 0
LDFLAGS_SYS = $(LDFLAGS) -Ttext 0 -e startup_32

ASMKFLAGS = -I $(INC_FD) 

OBJ_FILES = \
	$(OBJDIR)/head.o  \
	$(OBJ_LIB) \
	$(OBJ_KERNEL) \
	
OBJ_LIB = \
	$(DIR_LIB)/kliba.o  \
	$(DIR_LIB)/klib.o  \
	$(DIR_LIB)/string.o  \
	$(DIR_LIB)/misc.o  \
	
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
	
OBJ_FILES += $(OBJ_UNIT_TEST)
DIR_UNIT_TEST = ./unit_test
OBJ_UNIT_TEST = \
	$(DIR_UNIT_TEST)/ericut.o  \
	
.PHONY : clean

# === Rule ===
all: clean mkdir system.img nm diasm

system.img: boot/boot.bin boot/setup.bin system.bin 
	@dd if=$(DIR_BOOT)/boot.bin    of=system.img bs=512 count=1 
	@dd if=$(DIR_BOOT)/setup.bin   of=system.img bs=512 count=4 seek=1
	@dd if=system.bin    of=system.img bs=512 count=2883 seek=5 conv=notrunc

system.bin: head.o $(OBJ_FILES)
	$(LD) $(LDFLAGS_SYS) $(OBJ_FILES) -o system.elf
	$(OBJCOPY) $(TRIM_FLAGS) system.elf system.bin
	$(OBJCOPY) --only-keep-debug system.elf system.sym
	
boot/boot.bin:
	make -C boot
	
head.o: head.s
	$(AS) $(ASFLAG) $(OBJDIR)/head.o head.s

# == rule for kernel/ ==
$(DIR_KERENL)/%.o: $(DIR_KERENL)/%.asm
	$(NASM) $(NASM_FLG) $< -o $@

$(DIR_KERENL)/%.o: $(DIR_KERENL)/%.c
	$(CC) $(CFLAGS) $< -o $@  
	
# == rule for lib/ ==
$(DIR_LIB)/%.o: $(DIR_LIB)/%.asm
	$(NASM) $(NASM_FLG) $< -o $@
	
$(DIR_LIB)/%.o: $(DIR_LIB)/%.c
	$(CC) $(CFLAGS) $< -o $@
	
# ut
$(DIR_UNIT_TEST)/%.o: $(DIR_UNIT_TEST)/%.c
	$(CC) $(CFLAGS) $< -o $@    
	
# == rule for /*.c ==
%.o: %.c
	$(CC) $(CFLAGS) $< -o $(OBJDIR)/$@   

nm:
	nm system.elf |sort > system.nm
	
diasm:
	objdump -S  system.elf > system.diasm

clean:
	@make -C boot clean
	@rm -rf *.o *.elf *.bin *.img *.nm
	@rm -rf $(OBJ_FILES)
	@rm -rf $(OBJDIR)

#=== make dir ===
$(OBJDIR):
	@mkdir -p $@
	
mkdir: $(OBJDIR)
