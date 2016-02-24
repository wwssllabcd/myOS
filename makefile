CC = gcc
LD = ld
LDFILE = solrex_x86.ld
OBJCOPY = objcopy
CFLAGS = -c -W -nostdlib 
LDFLAGS	+= -Ttext 0 

TRIM_FLAGS = -R .pdr -R .comment -R.note -S -O binary
OBJ_FILES = \
	$(OBJDIR)/head.o  \
	$(OBJDIR)/sched.o \
	$(OBJDIR)/main.o  \


# === Rule ===
all: clean mkdir boot.img nmFile

boot.img: boot.bin setup.bin head.bin 
	@dd if=$(OBJDIR)/boot.bin of=boot.img bs=512 count=1
	@dd if=$(OBJDIR)/setup.bin of=boot.img seek=1 count=1
	@dd if=$(OBJDIR)/head.bin of=boot.img seek=5 count=1
	@dd if=/dev/zero of=boot.img seek=6 count=2879
	
boot.bin: boot.S
	@$(CC) $(CFLAGS) boot.S -o $(OBJDIR)/boot.o 
	@$(LD) $(OBJDIR)/boot.o -o $(OBJDIR)/boot.elf  -T $(LDFILE)
	@$(OBJCOPY) $(TRIM_FLAGS) $(OBJDIR)/boot.elf $(OBJDIR)/boot.bin

setup.bin: setup.S
	@$(CC) $(CFLAGS) setup.S -o $(OBJDIR)/setup.o 
	@$(LD) $(OBJDIR)/setup.o -o $(OBJDIR)/setup.elf $(LDFLAGS) 
	@$(OBJCOPY) $(TRIM_FLAGS)  $(OBJDIR)/setup.elf $(OBJDIR)/setup.bin

head.bin: head.S main.o sched.o
	@$(CC) $(CFLAGS) head.S -o $(OBJDIR)/head.o 
	@$(LD) $(OBJ_FILES) -o $(OBJDIR)/head.elf $(LDFLAGS) -e startup_32
	@$(OBJCOPY) $(TRIM_FLAGS) $(OBJDIR)/head.elf $(OBJDIR)/head.bin

clean:
	@rm -rf *.o *.elf *.bin *.img
	@rm -rf $(OBJDIR)
	

# == rule for .c ==
%.o: %.c
	@$(CC) $(CFLAGS) $< -o $(OBJDIR)/$@   

	
nmFile:
	@nm $(OBJDIR)/head.elf |sort > system.nm

	
#=== make dir ===
OBJDIR = ./obj
$(OBJDIR):
	@mkdir -p $@
	
mkdir: $(OBJDIR)
