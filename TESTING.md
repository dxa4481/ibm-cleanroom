# Testing the Cleanroom BIOS

## Quick Test Commands

### Option 1: Bash Script (Recommended)
```bash
cd /workspace
./RUN_INTEGRATION_TESTS.sh
```

### Option 2: Python Test Suite
```bash
cd /workspace/tests
python3 run_all_tests.py
```

### Option 3: Individual Tests

**Basic Validation (9 tests):**
```bash
cd /workspace/tests
python3 test_bios.py ../cleanroom_bios/build/bios_complete_64k.bin
```

**Functional Verification (82 checks):**
```bash
cd /workspace/tests
python3 test_functional_verification.py
```

**Comprehensive Audit (6 tests):**
```bash
cd /workspace/tests
python3 test_comprehensive.py
```

**Cleanroom Independence (10 tests):**
```bash
cd /workspace/tests
python3 test_cleanroom_verification.py
```

**Integration Test (8 checks):**
```bash
cd /workspace
python3 << 'EOF'
with open('cleanroom_bios/bios_complete.asm', 'r') as f:
    source = f.read()

tests = {
    'Hardware I/O (OUT/IN)': source.count(' out ') > 50 and source.count(' in ') > 20,
    'DMA Controller': 'DMA_MASK' in source and 'DMA_MODE' in source,
    'FDC Commands': '0xE6' in source and '0xC5' in source,
    'UART Programming': 'UART_DATA' in source and 'UART_LCR' in source,
    'Video Operations': 'stosw' in source and 'movsw' in source,
    'All Interrupts': all(x in source for x in ['int08_timer:', 'int10_video:', 'int13_disk:']),
    'Bootstrap': '0x7C00' in source and 'int19_boot:' in source,
    'Binary Size': __import__('os').path.getsize('cleanroom_bios/build/bios_complete.bin') == 8192,
}

passed = sum(tests.values())
print(f"\nIntegration Tests: {passed}/{len(tests)} passed\n")
for name, result in tests.items():
    print(f"{'✅' if result else '❌'} {name}")

print(f"\nResult: {'ALL PASS' if passed == len(tests) else f'{len(tests)-passed} FAILED'}")
