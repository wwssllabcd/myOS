CC = gcc
LD = ld
LDFILE = solrex_x86.ld
OBJCOPY = objcopy
CFLAGS = -c
LDFLAGS = -m elf_i386 -Ttext 0 


TRIM_FLAGS = -R .pdr -R .comment -R.note -S -O binary
OBJ_FILES = \
	$(OBJDIR)/head.o  \
	$(OBJDIR)/main.o  \
	$(OBJDIR)/sched.o \
	


# === Rule ===
all: clean mkdir system.img nmFile

system.img: boot.bin setup.bin system.bin 
	@dd if=$(OBJDIR)/boot.bin of=system.img bs=512 count=1 conv=notrunc
	@dd if=$(OBJDIR)/setup.bin of=system.img seek=1 count=1
	@dd if=$(OBJDIR)/system.bin of=system.img seek=5 count=1
	@dd if=/dev/zero of=system.img seek=6 count=2800
	
boot.bin: boot.s
	@$(AS) -o $(OBJDIR)/boot.o boot.s
	@$(LD) $(LDFLAGS) -o $(OBJDIR)/boot.bin $(OBJDIR)/boot.o
	@objcopy -R .pdr -R .comment -R.note -S -O binary $(OBJDIR)/boot.bin


setup.bin: setup.s
	@$(AS) -o $(OBJDIR)/setup.o setup.s
	@$(LD) $(LDFLAGS) -o $(OBJDIR)/setup.bin $(OBJDIR)/setup.o
	@objcopy -R .pdr -R .comment -R.note -S -O binary $(OBJDIR)/setup.bin

head.o: head.s
	$(AS) -o $(OBJDIR)/head.o head.s
	
system.bin: head.o main.o sched.o
	@$(LD) $(OBJ_FILES) -o $(OBJDIR)/system.elf -Ttext 0x00 $(LDFLAGS) -e startup_32
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
