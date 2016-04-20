include ../makefile.header

LDFLAGS	+= -Ttext 0 -s
BOOT_DIR = ./boot
CLEAN_FILE = boot.o boot.bin setup.o setup.bin 

SHOW = @

# === Rule ===
all: clean boot.bin setup.bin

boot.bin: boot.s
	$(SHOW)$(AS) $(ASFLAG) boot.o boot.s
	$(SHOW)$(LD) $(LDFLAGS) -o boot.bin boot.o
	$(SHOW)$(OBJCOPY) $(TRIM_FLAGS) boot.bin

setup.bin: setup.s
	$(SHOW)$(AS) $(ASFLAG) setup.o setup.s
	$(SHOW)$(LD) $(LDFLAGS) -o setup.bin setup.o
	$(SHOW)$(OBJCOPY) $(TRIM_FLAGS) setup.bin
	
clean:
	$(SHOW)rm -f $(CLEAN_FILE)	

