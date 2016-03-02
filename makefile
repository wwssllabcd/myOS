include ./makefile.header

DIR_BOOT = ./boot
DIR_KERENL = ./kernel
DIR_LIB = ./lib

LDFLAGS_BOOT = $(LDFLAGS) -Ttext 0
LDFLAGS_SYS = $(LDFLAGS) -Ttext 0 -e startup_32


OBJ_FILES = \
	$(OBJDIR)/head.o  \
	$(OBJDIR)/main.o  \
	$(OBJDIR)/sched.o \
	$(OBJDIR)/start.o \
	$(OBJ_LIB) \
	
OBJ_LIB = \
	$(DIR_LIB)/kliba.o  \
	

# === Rule ===
all: clean mkdir system.img nmFile

system.img: boot/boot.bin boot/setup.bin system.bin 
	@dd if=$(DIR_BOOT)/boot.bin    of=system.img bs=512 count=1 
	@dd if=$(DIR_BOOT)/setup.bin   of=system.img bs=512 count=4 seek=1
	@dd if=$(OBJDIR)/system.bin  of=system.img bs=512 count=2883 seek=5 conv=notrunc

boot/boot.bin:
	make -C boot
	
head.o: head.s
	$(AS) -o $(OBJDIR)/head.o head.s

lib/kliba.o: lib/kliba.asm
	$(AS) $< -o $@  
	
start.o: start.c
	$(CC) $(CFLAGS) $< -o $(OBJDIR)/$@   
	
sched.o: sched.c
	$(CC) $(CFLAGS) $< -o $(OBJDIR)/$@   

system.bin: head.o sched.o lib/kliba.o start.o main.o 
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
