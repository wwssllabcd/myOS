CC = gcc
LD = ld
LDFILE = solrex_x86.ld


OBJCOPY = objcopy

CFLAGS = -c 
LDFLAGS	+= -Ttext 0  -e startup_32

TRIM_FLAGS = -R .pdr -R .comment -R.note -S -O binary

OBJ_FILES = \
	$(OBJDIR)/head.o  \
	$(OBJDIR)/main.o  \
	$(OBJDIR)/sched.o \


# === Rule ===

all: directories boot.img 

boot.img: boot.bin setup.bin head.bin
	@dd if=$(OBJDIR)/boot.bin of=boot.img bs=512 count=1
	@dd if=$(OBJDIR)/setup.bin of=boot.img seek=1 count=1
	@dd if=$(OBJDIR)/head.bin of=boot.img seek=5 count=1
	@dd if=/dev/zero of=boot.img seek=6 count=2878
	
boot.bin: boot.S boot.o
	@$(OBJCOPY) $(TRIM_FLAGS) $(OBJDIR)/boot.elf $(OBJDIR)/boot.bin

setup.bin: setup.S setup.o
	@$(OBJCOPY) $(TRIM_FLAGS)  $(OBJDIR)/setup.elf $(OBJDIR)/setup.bin

head.bin: head.S head.o main.o sched.o
	@$(LD) $(OBJ_FILES) -o $(OBJDIR)/head.elf $(LDFLAGS) 
	@$(OBJCOPY) $(TRIM_FLAGS) $(OBJDIR)/head.elf $(OBJDIR)/head.bin

clean:
	@rm -rf *.o *.elf *.bin *.img
	@rm -rf $(OBJDIR)
	
%.o: %.S 
	@$(CC) $(CFLAGS) $<  -o $(OBJDIR)/$@   
	
nmFile:
	@$(LD) $(LDFLAGS) $(OBJDIR)/boot.o $(OBJDIR)/setup.o $(OBJDIR)/head.o $(OBJDIR)/main.o \
	-o $(OBJDIR)/nmfile

	
#=== make dir ===
OBJDIR = ./obj
$(OBJDIR):
	mkdir -p $@
	
directories: $(OBJDIR)
