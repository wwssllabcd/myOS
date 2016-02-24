CC = gcc
LD = ld
LDFILE = solrex_x86.ld
OBJCOPY = objcopy
CFLAGS = -c
LDFLAGS = -m elf_i386
LDFLAGS_BOOT = $(LDFLAGS) -Ttext 0
LDFLAGS_SYS = $(LDFLAGS) -Ttext 0 -e startup_32


TRIM_FLAGS = -R .pdr -R .comment -R.note -S -O binary
OBJ_FILES = \
	$(OBJDIR)/head.o  \
	$(OBJDIR)/main.o  \
	$(OBJDIR)/sched.o \
	


# === Rule ===
all: clean mkdir system.img nmFile

system.img: boot.bin setup.bin system.bin 
	@dd if=$(OBJDIR)/boot.bin    of=system.img bs=512 count=1 
	@dd if=$(OBJDIR)/setup.bin   of=system.img bs=512 count=4 seek=1
	@dd if=$(OBJDIR)/system.bin  of=system.img bs=512 count=2883 seek=5 conv=notrunc

boot.bin: boot.s
	@$(AS) -o $(OBJDIR)/boot.o boot.s
	@$(LD) $(LDFLAGS_BOOT) -o $(OBJDIR)/boot.bin $(OBJDIR)/boot.o
	@objcopy -R .pdr -R .comment -R.note -S -O binary $(OBJDIR)/boot.bin


setup.bin: setup.s
	@$(AS) -o $(OBJDIR)/setup.o setup.s
	@$(LD) $(LDFLAGS_BOOT) -o $(OBJDIR)/setup.bin $(OBJDIR)/setup.o
	@objcopy -R .pdr -R .comment -R.note -S -O binary $(OBJDIR)/setup.bin

head.o: head.s
	$(AS) -o $(OBJDIR)/head.o head.s
	
system.bin: head.o main.o sched.o
	@$(LD) $(LDFLAGS_SYS) $(OBJ_FILES) -o $(OBJDIR)/system.elf
	@$(OBJCOPY) $(TRIM_FLAGS) $(OBJDIR)/system.elf $(OBJDIR)/system.bin

clean:
	@rm -rf *.o *.elf *.bin *.img
	@rm -rf $(OBJDIR)
	

# == rule for .c ==
%.o: %.c
	@$(CC) $(CFLAGS) $< -o $(OBJDIR)/$@   

	
nmFile:
	@nm $(OBJDIR)/system.elf |sort > system.nm

	
#=== make dir ===
OBJDIR = ./obj
$(OBJDIR):
	@mkdir -p $@
	
mkdir: $(OBJDIR)
