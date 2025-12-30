#!/bin/bash
# Run from git repo root
# Usage: ./RUN_TESTS.sh

echo "=================================="
echo "BIOS Integration Test Suite"
echo "=================================="

# Test 1: Basic validation
echo "[1/4] Basic validation tests..."
cd tests
python3 test_bios.py ../cleanroom_bios/build/bios_complete_64k.bin

# Test 2: Functional verification
echo "[2/4] Functional verification..."
python3 test_functional_verification.py

# Test 3: Comprehensive audit
echo "[3/4] Comprehensive audit..."
python3 test_comprehensive.py

# Test 4: Integration check
echo "[4/4] Integration check..."
cd ..
python3 << 'PYTEST'
with open('cleanroom_bios/bios_complete.asm', 'r') as f:
    s = f.read()
import os
tests = {
    'Hardware I/O': s.count(' out ') > 50,
    'DMA': 'DMA_MASK' in s,
    'FDC': '0xE6' in s,
    'UART': 'UART_LCR' in s,
    'Video': 'stosw' in s,
    'Interrupts': 'int10_video:' in s,
    'Bootstrap': '0x7C00' in s,
    'Binary': os.path.getsize('cleanroom_bios/build/bios_complete.bin') == 8192,
}
passed = sum(tests.values())
print(f"\nIntegration: {passed}/{len(tests)}")
for k, v in tests.items():
    print(f"  {'✅' if v else '❌'} {k}")
print(f"\n{'✅ ALL PASS' if passed == len(tests) else '❌ FAILED'}")
PYTEST

echo ""
echo "=================================="
echo "Test Suite Complete"
echo "=================================="
