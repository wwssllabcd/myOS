include ./makefile.header

BOOT_DIR = ./boot
LDFLAGS_BOOT = $(LDFLAGS) -Ttext 0
LDFLAGS_SYS = $(LDFLAGS) -Ttext 0 -e startup_32

OBJDIR = ./obj
OBJDIR_K = ./kernel
OBJDIR_KLIB = ./lib

# obj file
OBJ_FILES = \
	$(KERNEL_FILE) \
	$(KLIB_FILE)   \
	$(OBJDIR)/head.o  \
	$(OBJDIR)/main.o  \

KERNEL_FILE = \
	$(OBJDIR_K)/sched.o \
	$(OBJDIR_K)/start.o \
	
KLIB_FILE = \
	$(OBJDIR_KLIB)/kliba.o \
	
	

# === Rule ===
all: clean mkdir system.img nmFile

system.img: boot/boot.bin boot/setup.bin system.bin 
	@dd if=$(BOOT_DIR)/boot.bin    of=system.img bs=512 count=1 
	@dd if=$(BOOT_DIR)/setup.bin   of=system.img bs=512 count=4 seek=1
	@dd if=$(OBJDIR)/system.bin  of=system.img bs=512 count=2883 seek=5 conv=notrunc

boot/boot.bin:
	make -C boot
	
obj/head.o: head.s
	$(AS) $< -o $@   
	
obj/main.o: main.c
	$(CC) $(CFLAGS) $< -o $@   
	   
lib/kliba.o: lib/kliba.asm
	$(AS) $< -o $@   
	
kernel/start.o: kernel/start.c
	$(CC) $(CFLAGS) $< -o $@   
	
kernel/sched.o: kernel/sched.c
	$(CC) $(CFLAGS) $< -o $@   

system.bin: $(OBJ_FILES)
	$(LD) $(LDFLAGS_SYS)  $(OBJ_FILES)  -o $(OBJDIR)/system.elf
	$(OBJCOPY) $(TRIM_FLAGS) $(OBJDIR)/system.elf $(OBJDIR)/system.bin

clean:
	@make -C boot clean
	@rm -rf *.o *.elf *.bin *.img *.nm
	@rm -rf $(OBJDIR)
	@rm -rf $(OBJ_FILES)
	
	

# == rule for .c ==
%.o: %.c
	$(CC) $(CFLAGS) $< -o $(OBJDIR)/$@   

nmFile:
	@nm $(OBJDIR)/system.elf |sort > system.nm

#=== make dir ===
$(OBJDIR):
	@mkdir -p $@
	
mkdir: $(OBJDIR)
