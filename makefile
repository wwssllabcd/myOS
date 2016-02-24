CC = gcc
LD = ld
LDFILE = solrex_x86.ld
OBJCOPY = objcopy
CFLAGS = -c
LDFLAGS	+= -Ttext 0 

TRIM_FLAGS = -R .pdr -R .comment -R.note -S -O binary
OBJ_FILES = \
	$(OBJDIR)/head.o  \
	$(OBJDIR)/main.o  \
	$(OBJDIR)/sched.o \
	


# === Rule ===
all: clean mkdir boot.img nmFile

boot.img: boot.bin setup.bin system.bin 
	@dd if=$(OBJDIR)/boot.bin of=boot.img bs=512 count=1 conv=notrunc
	@dd if=$(OBJDIR)/setup.bin of=boot.img seek=1 count=1
	@dd if=$(OBJDIR)/system.bin of=boot.img seek=5 count=1
	@dd if=/dev/zero of=boot.img seek=6 count=2800
	
boot.o: boot.S
	@$(CC) $(CFLAGS) boot.S -o $(OBJDIR)/boot.o
	
boot.elf: boot.o
	@$(LD) $(OBJDIR)/boot.o -o $(OBJDIR)/boot.elf -e c -T$(LDFILE)
	
boot.bin: boot.elf
	@$(OBJCOPY) $(TRIM_FLAGS) $(OBJDIR)/boot.elf $(OBJDIR)/boot.bin
	

setup.bin: setup.S
	@$(CC) $(CFLAGS) setup.S -o $(OBJDIR)/setup.o 
	@$(LD) $(OBJDIR)/setup.o -o $(OBJDIR)/setup.elf $(LDFLAGS) 
	@$(OBJCOPY) $(TRIM_FLAGS)  $(OBJDIR)/setup.elf $(OBJDIR)/setup.bin

head.o: head.S
	@$(CC) $(CFLAGS) head.S -o $(OBJDIR)/head.o 
	
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
