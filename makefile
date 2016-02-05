CC = gcc
LD = ld
LDFILE = solrex_x86.ld
OBJCOPY = objcopy

CFLAGS = -c -g  -ggdb
TRIM_FLAGS = -R .pdr -R .comment -R.note -S -O binary


# === Rule ===

all: directories boot.img 

boot.img: boot.bin setup.bin head.bin
	@dd if=$(OBJDIR)/boot.bin of=boot.img bs=512 count=1
	@dd if=$(OBJDIR)/setup.bin of=boot.img seek=1 count=1
	@dd if=$(OBJDIR)/head.bin of=boot.img seek=5 count=1
	@dd if=/dev/zero of=boot.img seek=6 count=2879
	
boot.bin: boot.S boot.o
	#$(CC) $(CFLAGS) boot.S -o $(OBJDIR)/boot.o
	$(LD) $(OBJDIR)/boot.o -o $(OBJDIR)/boot.elf -e c -T $(LDFILE)
	@$(OBJCOPY) $(TRIM_FLAGS) $(OBJDIR)/boot.elf $(OBJDIR)/boot.bin

setup.bin: setup.S setup.o
	#$(CC) $(CFLAGS) setup.S -o $(OBJDIR)/setup.o
	$(LD) $(OBJDIR)/setup.o -o $(OBJDIR)/setup.elf -e c -Ttext=0x00
	@$(OBJCOPY) $(TRIM_FLAGS)  $(OBJDIR)/setup.elf $(OBJDIR)/setup.bin

head.bin: head.S head.o
	#$(CC) $(CFLAGS) head.S -o $(OBJDIR)/head.o
	$(LD) $(OBJDIR)/head.o -o $(OBJDIR)/head.elf -e c -Ttext=0x00
	@$(OBJCOPY) $(TRIM_FLAGS) $(OBJDIR)/head.elf $(OBJDIR)/head.bin

clean:
	@rm -rf *.o *.elf *.bin *.img
	@rm -rf $(OBJDIR)
	
%.o: %.S 
	@$(CC) $(CFLAGS) $< -o $(OBJDIR)/$@   
	
#=== make dir ===
OBJDIR = ./obj
$(OBJDIR):
	mkdir -p $@
	
directories: $(OBJDIR)
