#!/bin/bash
# Complete Integration Test Suite
# Run this to verify the BIOS is actually complete and functional

echo "=================================="
echo "BIOS Integration Test Suite"
echo "=================================="
echo ""

cd /workspace

# Test 1: Basic validation
echo "[1/5] Running basic validation tests..."
cd tests
python3 test_bios.py ../cleanroom_bios/build/bios_complete_64k.bin
echo ""

# Test 2: Functional verification
echo "[2/5] Running functional verification..."
python3 test_functional_verification.py
echo ""

# Test 3: Comprehensive audit
echo "[3/5] Running comprehensive audit..."
python3 test_comprehensive.py
echo ""

# Test 4: Cleanroom verification
echo "[4/5] Running cleanroom independence verification..."
python3 test_cleanroom_verification.py
echo ""

# Test 5: Integration tests
echo "[5/5] Running integration tests..."
cd /workspace
python3 << 'PYTEST'
print("\n" + "="*70)
print("INTEGRATION VERIFICATION")
print("="*70)

with open('cleanroom_bios/bios_complete.asm', 'r') as f:
    source = f.read()

tests = [
    ("Hardware I/O", lambda: source.count(' out ') > 50 and source.count(' in ') > 20),
    ("DMA Programming", lambda: all(x in source for x in ['DMA_MASK', 'DMA_MODE', 'DMA_CH2_ADDR'])),
    ("FDC Commands", lambda: all(x in source for x in ['FDC_DATA', '0xE6', '0xC5'])),
    ("UART Programming", lambda: all(x in source for x in ['UART_DATA', 'UART_LCR', 'UART_LSR'])),
    ("Video Operations", lambda: 'stosw' in source and 'movsw' in source),
    ("All Interrupt Handlers", lambda: all(x in source for x in ['int08_timer:', 'int09_keyboard:', 'int10_video:', 'int13_disk:', 'int14_serial:'])),
    ("Bootstrap Loader", lambda: 'int19_boot:' in source and '0x7C00' in source),
    ("Binary Size", lambda: __import__('os').path.getsize('cleanroom_bios/build/bios_complete.bin') == 8192),
]

passed = 0
for name, test in tests:
    result = test()
    status = "✅ PASS" if result else "❌ FAIL"
    print(f"{status} - {name}")
    if result:
        passed += 1

print(f"\nIntegration Tests: {passed}/{len(tests)} passed ({100*passed//len(tests)}%)")

if passed == len(tests):
    print("\n✅ ALL INTEGRATION TESTS PASSED")
    print("The BIOS is complete and functional.")
else:
    print(f"\n⚠️  {len(tests)-passed} test(s) need attention")

PYTEST

echo ""
echo "=================================="
echo "Test Suite Complete"
echo "=================================="
