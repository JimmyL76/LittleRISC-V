# --- Toolchain Configuration ---
# 'unknown-elf' toolchain:
PREFIX  = riscv64-unknown-elf-
# 'linux-gnu' toolchain:
# PREFIX  = riscv64-linux-gnu-

CC      = $(PREFIX)gcc
OBJCOPY = $(PREFIX)objcopy
OBJDUMP = $(PREFIX)objdump

# --- Project Files ---
TARGET  ?= riscv
# start.s first so the entry point is at 0x00000000
SRCS    = start.s main.c

# --- Output Directory ---
BUILD_DIR = Build

# --- Compiler Flags ---
# -march=rv32i  : use the base 32-bit integer architecture (no float/multiply)
# -mabi=ilp32   : use 32-bit integer ABI
# -nostdlib     : do not use standard C libraries (printf, etc.)
# -T link.ld    : use our custom memory map
# -g            : generate debug info (for the .dump file)
# -O0           : turn off optimization (makes debugging easier)
CFLAGS  = -march=rv32i -mabi=ilp32 -nostdlib -T link.ld -g -O0

# # --- Python Uploader Settings ---
# UPLOAD_SCRIPT = UART.py
# PORT          = COM3
# BAUD          = 9600

# --- Build Rules ---

all: $(BUILD_DIR)/$(TARGET).bin $(BUILD_DIR)/$(TARGET).dump

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# 1. Compile ELF (executable)
$(BUILD_DIR)/$(TARGET).elf: $(SRCS) | $(BUILD_DIR) # check that build dir exists
	$(CC) $(CFLAGS) -o $@ $^ -lgcc
# lgcc handles multiply using GCC math library

# 2. Extract Binary (FPGA machine code)
$(BUILD_DIR)/$(TARGET).bin: $(BUILD_DIR)/$(TARGET).elf
	$(OBJCOPY) -O binary $< $@

# 3. Disassemble (debugging readable assembly)
$(BUILD_DIR)/$(TARGET).dump: $(BUILD_DIR)/$(TARGET).elf
	$(OBJDUMP) -D -S $< > $@

# # 4. Flash Command
# flash: $(TARGET).bin
# 	python3 $(UPLOAD_SCRIPT) --port $(PORT) --baud $(BAUD) --load $(TARGET).bin --addr 0x00000000

clean:
	rm -f $(BUILD_DIR)/*.elf $(BUILD_DIR)/*.bin $(BUILD_DIR)/*.dump

.PHONY: all clean