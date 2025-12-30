# Quick Test Commands

Run these from the **git repo root directory**.

## Option 1: Run All Tests (Recommended)
```bash
./RUN_TESTS.sh
```

## Option 2: Individual Tests

### Basic Validation (9 tests)
```bash
cd tests
python3 test_bios.py ../cleanroom_bios/build/bios_complete_64k.bin
cd ..
```

### Functional Verification (82 checks)
```bash
cd tests
python3 test_functional_verification.py
cd ..
```

### Comprehensive Audit
```bash
cd tests
python3 test_comprehensive.py
cd ..
```

### Quick Integration Check
```bash
python3 -c "
with open('cleanroom_bios/bios_complete.asm', 'r') as f:
    s = f.read()
import os
tests = {
    'Hardware I/O': s.count(' out ') > 50,
    'DMA': 'DMA_MASK' in s,
    'FDC': '0xE6' in s,
    'UART': 'UART_LCR' in s,
    'Binary': os.path.getsize('cleanroom_bios/build/bios_complete.bin') == 8192,
}
passed = sum(tests.values())
print(f'{passed}/{len(tests)} checks pass')
for k, v in tests.items():
    print(f\"{'✅' if v else '❌'} {k}\")
"
```

## Build BIOS First
```bash
cd cleanroom_bios
make
cd ..
```

## Test in QEMU
```bash
qemu-system-i386 -M isapc -bios cleanroom_bios/build/bios_complete_64k.bin
```

## Expected Output
All tests should show **100% pass rate**.

## File Locations
```
repo_root/
├── RUN_TESTS.sh           # Run this
├── cleanroom_bios/
│   ├── bios_complete.asm  # 2,442 lines
│   ├── build/
│   │   ├── bios_complete.bin      # 8,192 bytes
│   │   └── bios_complete_64k.bin  # 65,536 bytes
│   └── Makefile
└── tests/
    ├── test_bios.py
    ├── test_functional_verification.py
    └── test_comprehensive.py
```
