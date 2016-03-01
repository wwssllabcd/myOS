include ../makefile.header

LDFLAGS	+= -Ttext 0
BOOT_DIR = ./boot
CLEAN_FILE = boot.o boot.bin setup.o setup.bin 

# === Rule ===
all: clean boot.bin setup.bin

boot.bin: boot.s
	@$(AS) -o boot.o boot.s
	@$(LD) $(LDFLAGS) -o boot.bin boot.o
	@$(OBJCOPY) $(TRIM_FLAGS) boot.bin

setup.bin: setup.s
	@$(AS) -o setup.o setup.s
	@$(LD) $(LDFLAGS) -o setup.bin setup.o
	@$(OBJCOPY) $(TRIM_FLAGS) setup.bin
	
clean:
	@rm -f $(CLEAN_FILE)	

