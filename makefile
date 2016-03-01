include ./makefile.header

BOOT_DIR = ./boot
LDFLAGS_BOOT = $(LDFLAGS) -Ttext 0
LDFLAGS_SYS = $(LDFLAGS) -Ttext 0 -e startup_32

OBJ_FILES = \
	$(OBJDIR)/head.o  \
	$(OBJDIR)/main.o  \
	$(OBJDIR)/sched.o \
	$(OBJDIR)/start.o \

# === Rule ===
all: clean mkdir system.img nmFile

system.img: boot/boot.bin boot/setup.bin system.bin 
	@dd if=$(BOOT_DIR)/boot.bin    of=system.img bs=512 count=1 
	@dd if=$(BOOT_DIR)/setup.bin   of=system.img bs=512 count=4 seek=1
	@dd if=$(OBJDIR)/system.bin  of=system.img bs=512 count=2883 seek=5 conv=notrunc

boot/boot.bin:
	make -C boot
	
head.o: head.s
	$(AS) -o $(OBJDIR)/head.o head.s

kliba.o: kliba.asm
	$(AS) -o $(OBJDIR)/kliba.o kliba.asm
	
start.o: start.c
	$(CC) $(CFLAGS) $< -o $(OBJDIR)/$@   
	
sched.o: sched.c
	$(CC) $(CFLAGS) $< -o $(OBJDIR)/$@   

system.bin: head.o sched.o kliba.o start.o main.o 
	$(LD) $(LDFLAGS_SYS) $(OBJ_FILES) -o $(OBJDIR)/system.elf
	$(OBJCOPY) $(TRIM_FLAGS) $(OBJDIR)/system.elf $(OBJDIR)/system.bin

clean:
	@make -C boot clean
	@rm -rf *.o *.elf *.bin *.img *.nm
	@rm -rf $(OBJDIR)
	

# == rule for .c ==
%.o: %.c
	$(CC) $(CFLAGS) $< -o $(OBJDIR)/$@   

nmFile:
	@nm $(OBJDIR)/system.elf |sort > system.nm

#=== make dir ===

$(OBJDIR):
	@mkdir -p $@
	
mkdir: $(OBJDIR)
