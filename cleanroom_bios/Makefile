# Makefile for Cleanroom IBM PC 5150 BIOS
# Team 2 Implementation

AS = nasm
ASFLAGS = -f bin
PYTHON = python3

# Source and output files
SRC = bios.asm
OUTPUT_8K = build/bios.bin
OUTPUT_64K = build/bios_64k.bin

# Default target
all: $(OUTPUT_64K)

# Create build directory
build:
	mkdir -p build

# Assemble BIOS (8KB)
$(OUTPUT_8K): $(SRC) | build
	$(AS) $(ASFLAGS) -o $(OUTPUT_8K) $(SRC)
	@echo "Built 8KB BIOS: $(OUTPUT_8K)"
	@ls -lh $(OUTPUT_8K)

# Pad to 64KB for QEMU
$(OUTPUT_64K): $(OUTPUT_8K)
	@echo "Padding BIOS to 64KB for QEMU..."
	$(PYTHON) -c "import sys; \
		bios = open('$(OUTPUT_8K)', 'rb').read(); \
		padded = bytearray([0xFF] * (65536 - len(bios))) + bytearray(bios); \
		open('$(OUTPUT_64K)', 'wb').write(padded)"
	@echo "Built 64KB BIOS: $(OUTPUT_64K)"
	@ls -lh $(OUTPUT_64K)

# Test with QEMU
test: $(OUTPUT_64K)
	@echo "Testing BIOS in QEMU..."
	timeout 5 qemu-system-i386 -M isapc -cpu 486 -m 640 \
		-bios $(OUTPUT_64K) -nographic || true
	@echo "QEMU test complete"

# Run test suite
test-suite: $(OUTPUT_64K)
	@echo "Running test suite..."
	cd ../tests && python3 test_bios.py ../cleanroom_bios/$(OUTPUT_64K)

# Clean build artifacts
clean:
	rm -rf build/
	@echo "Cleaned build directory"

# Show ROM info
info: $(OUTPUT_8K)
	@echo "=== BIOS Information ==="
	@echo "Size: $$(stat -c%s $(OUTPUT_8K)) bytes"
	@echo "First 32 bytes:"
	@hexdump -C $(OUTPUT_8K) | head -3
	@echo ""
	@echo "Reset vector (last 16 bytes):"
	@hexdump -C $(OUTPUT_8K) | tail -2
	@echo ""
	@echo "Strings in ROM:"
	@strings $(OUTPUT_8K) | head -10

# Disassemble for review (Team 2 debugging only)
disasm: $(OUTPUT_8K)
	ndisasm -b 16 -o 0xE000 $(OUTPUT_8K) > build/bios.disasm.txt
	@echo "Disassembly saved to build/bios.disasm.txt"

.PHONY: all test test-suite clean info disasm
