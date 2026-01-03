# ======================================================================
# RISC-V Bare Metal Makefile
# ======================================================================

# --- Toolchain Configuration ---
# If you installed the 'unknown-elf' toolchain (standard):
PREFIX  = riscv64-unknown-elf-
# If you installed the 'linux-gnu' toolchain (alternative):
# PREFIX  = riscv64-linux-gnu-

CC      = $(PREFIX)gcc
OBJCOPY = $(PREFIX)objcopy
OBJDUMP = $(PREFIX)objdump

# --- Project Files ---
TARGET  = riscv
# IMPORTANT: start.s must be first so the entry point is at 0x00000000
SRCS    = start.s main.c

# --- Compiler Flags ---
# -march=rv32i  : Use the base 32-bit integer architecture (no float/multiply)
# -mabi=ilp32   : Use 32-bit integer ABI
# -nostdlib     : Do not use standard C libraries (printf, etc.)
# -T link.ld    : Use our custom memory map
# -g            : Generate debug info (for the .dump file)
# -O0           : Turn off optimization (makes debugging easier)
CFLAGS  = -march=rv32i -mabi=ilp32 -nostdlib -T link.ld -g -O0

# # --- Python Uploader Settings ---
# # Update this PORT to match Windows COM port (e.g., COM3, COM5)
# UPLOAD_SCRIPT = UART.py
# PORT          = COM3
# BAUD          = 9600

# ======================================================================
# Build Rules
# ======================================================================

all: $(TARGET).bin $(TARGET).dump

# 1. Compile ELF (The Executable)
$(TARGET).elf: $(SRCS)
	$(CC) $(CFLAGS) -o $@ $^

# 2. Extract Binary (The Machine Code for FPGA)
$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

# 3. Disassemble (The Readable Assembly for Debugging)
$(TARGET).dump: $(TARGET).elf
	$(OBJDUMP) -D -S $< > $@

# # 4. Flash Command
# flash: $(TARGET).bin
# 	python3 $(UPLOAD_SCRIPT) --port $(PORT) --baud $(BAUD) --load $(TARGET).bin --addr 0x00000000

# Clean Artifacts
clean:
	rm -f *.elf *.bin *.dump

# .PHONY: all flash clean