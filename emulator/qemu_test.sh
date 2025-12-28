#!/bin/bash
# QEMU Test Harness for IBM PC 5150 BIOS Testing
# Usage: ./qemu_test.sh [original|cleanroom] [test_options]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"

# Default values
BIOS_TYPE="${1:-original}"
TEST_MODE="${2:-interactive}"

# BIOS paths
ORIGINAL_BIOS="$WORKSPACE_DIR/BIOS_IBM5150_19OCT81_5700671_U33.BIN"
CLEANROOM_BIOS="$WORKSPACE_DIR/cleanroom_bios/build/bios.bin"

# Select BIOS
case "$BIOS_TYPE" in
    original)
        BIOS_PATH="$ORIGINAL_BIOS"
        echo "Testing with ORIGINAL IBM BIOS"
        ;;
    cleanroom)
        BIOS_PATH="$CLEANROOM_BIOS"
        echo "Testing with CLEANROOM BIOS"
        ;;
    *)
        echo "Usage: $0 [original|cleanroom] [test_options]"
        exit 1
        ;;
esac

# Check BIOS exists
if [ ! -f "$BIOS_PATH" ]; then
    echo "ERROR: BIOS file not found: $BIOS_PATH"
    exit 1
fi

# Display BIOS info
echo "BIOS: $BIOS_PATH"
echo "Size: $(stat -c%s "$BIOS_PATH") bytes"
echo ""

# QEMU common options
QEMU_OPTS=(
    -M isapc                    # ISA-only PC (closest to IBM PC 5150)
    -cpu 486                    # CPU type (8086 not directly available, 486 works)
    -m 640                      # 640KB RAM (maximum for IBM PC)
    -bios "$BIOS_PATH"          # Use our BIOS
    -no-reboot                  # Don't reboot on reset
    -boot order=c               # Boot from floppy
)

# Test mode options
case "$TEST_MODE" in
    interactive)
        echo "Starting interactive QEMU session..."
        echo "Press Ctrl-Alt-2 for QEMU monitor"
        echo "Press Ctrl-Alt-Q to quit"
        qemu-system-i386 "${QEMU_OPTS[@]}" \
            -display gtk \
            -serial stdio
        ;;
    headless)
        echo "Starting headless QEMU session (serial output only)..."
        qemu-system-i386 "${QEMU_OPTS[@]}" \
            -nographic \
            -serial stdio
        ;;
    monitor)
        echo "Starting QEMU with monitor output..."
        qemu-system-i386 "${QEMU_OPTS[@]}" \
            -nographic \
            -monitor stdio
        ;;
    screenshot)
        echo "Capturing screenshot after 3 seconds..."
        timeout 3 qemu-system-i386 "${QEMU_OPTS[@]}" \
            -display none \
            -vnc :1 \
            || true
        ;;
    *)
        echo "Unknown test mode: $TEST_MODE"
        echo "Available modes: interactive, headless, monitor, screenshot"
        exit 1
        ;;
esac

echo ""
echo "QEMU test complete"
