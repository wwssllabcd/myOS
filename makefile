CC = gcc
LD = ld
LDFILE = solrex_x86.ld
OBJCOPY = objcopy

CFLAGS = -c -g
TRIM_FLAGS = -R .pdr -R .comment -R.note -S -O binary


# === Rule ===

all: directories boot.img 

boot.img: boot.bin setup.bin head.bin
	@dd if=boot.bin of=boot.img bs=512 count=1
	@dd if=setup.bin of=boot.img seek=1 count=1
	@dd if=head.bin of=boot.img seek=5 count=1
	@dd if=/dev/zero of=boot.img seek=6 count=2879
	
boot.bin: boot.S 
	$(CC) $(CFLAGS) boot.S -o $(OBJDIR)/boot.o
	$(LD) $(OBJDIR)/boot.o -o $(OBJDIR)/boot.elf -e c -T $(LDFILE)
	@$(OBJCOPY) $(TRIM_FLAGS) $(OBJDIR)/boot.elf boot.bin

setup.bin: setup.S
	$(CC) $(CFLAGS) setup.S -o $(OBJDIR)/setup.o
	$(LD) $(OBJDIR)/setup.o -o $(OBJDIR)/setup.elf -e c -Ttext=0x00
	@$(OBJCOPY) $(TRIM_FLAGS)  $(OBJDIR)/setup.elf setup.bin

head.bin: head.S
	$(CC) $(CFLAGS) head.S -o $(OBJDIR)/head.o
	$(LD) $(OBJDIR)/head.o -o $(OBJDIR)/head.elf -e c -Ttext=0x00
	@$(OBJCOPY) $(TRIM_FLAGS) $(OBJDIR)/head.elf head.bin

clean:
	@rm -rf *.o *.elf *.bin *.img
	@rm -rf $(OBJDIR)

#=== make dir ===
OBJDIR = ./obj
$(OBJDIR):
	mkdir -p $@
	
directories: ${OBJDIR}
