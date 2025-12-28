# Cleanroom BIOS - Quick Start Guide

Get started with the IBM PC 5150 BIOS cleanroom recreation in 5 minutes!

---

## Prerequisites

Already installed:
- ✅ QEMU 8.2.2 (x86 emulator)
- ✅ NASM 2.16.01 (assembler)
- ✅ Python 3 + pytest

---

## Quick Demo

### 1. Test the Original IBM BIOS

```bash
cd /workspace/tests
python3 test_bios.py ../BIOS_IBM5150_19OCT81_5700671_U33_64K.BIN
```

**Expected output**: 9/9 tests passed (100%)

### 2. Build the Cleanroom BIOS

```bash
cd /workspace/cleanroom_bios
make
```

**Output**: Creates `build/bios.bin` (8KB) and `build/bios_64k.bin` (64KB)

### 3. Test the Cleanroom BIOS

```bash
cd /workspace/tests
python3 test_bios.py ../cleanroom_bios/build/bios_64k.bin
```

**Expected output**: 9/9 tests passed (100%)

### 4. Run in QEMU

```bash
cd /workspace/cleanroom_bios
make test
```

**Output**: QEMU boots the cleanroom BIOS successfully!

---

## Project Structure

```
/workspace/
├── 📄 BIOS_IBM5150_19OCT81_5700671_U33.BIN     ← Original IBM ROM
├── 📚 docs/                                     ← Documentation
│   ├── CLEANROOM_PROCESS.md                    ← Methodology
│   ├── SPECIFICATIONS.md                       ← Functional specs
│   ├── 8086_OPCODE_REFERENCE.md               ← CPU reference
│   ├── SUMMARY.md                              ← Project summary
│   └── COMPARISON.md                           ← Original vs Cleanroom
├── 🧪 tests/                                    ← Test suite
│   └── test_bios.py                            ← Automated tests
└── 🔧 cleanroom_bios/                          ← Our implementation
    ├── bios.asm                                ← Source code
    ├── Makefile                                ← Build system
    └── build/                                  ← Compiled ROMs
```

---

## Key Files to Explore

### 1. The Specifications (Team 1 → Team 2)
```bash
less docs/SPECIFICATIONS.md
```

This document defines WHAT the BIOS does (not HOW). It's the only thing Team 2 was allowed to see.

### 2. The Cleanroom Implementation
```bash
less cleanroom_bios/bios.asm
```

Written from specifications only, without seeing IBM's code.

### 3. The Test Suite
```bash
less tests/test_bios.py
```

Validates both BIOSes behave identically.

### 4. The Comparison
```bash
less docs/COMPARISON.md
```

Proves the implementations are different (legally independent).

---

## Understanding the Process

### Team 1 (Analysis)
```
Original ROM → [Black-box testing] → Specifications
                                   ↓
                              Test Suite
```

**Can see**: Original ROM, disassembly  
**Creates**: Behavioral specs, tests  
**Cannot share**: Implementation details

### Team 2 (Implementation)
```
Specifications → [Coding] → Cleanroom BIOS
  ↓                            ↓
Opcode Ref                  [Testing]
```

**Can see**: Specs, CPU reference, tests  
**Creates**: New BIOS from scratch  
**Cannot see**: Original ROM or its code

---

## Test Results Summary

| Test Category | Original | Cleanroom | Status |
|---------------|----------|-----------|--------|
| ROM Structure | ✅ | ✅ | PASS |
| Boot Behavior | ✅ | ✅ | PASS |
| Interrupts | ✅ | ✅ | PASS |
| Memory | ✅ | ✅ | PASS |
| **Total** | **9/9** | **9/9** | **100%** |

---

## Make Targets

```bash
cd /workspace/cleanroom_bios

make            # Build BIOS (8KB + 64KB padded)
make test       # Run in QEMU
make test-suite # Run test suite
make info       # Show ROM information
make clean      # Remove build artifacts
make disasm     # Generate disassembly (for debugging)
```

---

## Verify Legal Independence

### Different Copyright
```bash
# Original:
strings BIOS_IBM5150_19OCT81_5700671_U33.BIN | grep -i copr
# Output: "5700671 COPR. IBM 1981"

# Cleanroom:
strings cleanroom_bios/build/bios.bin | grep -i bios
# Output: "Cleanroom BIOS - Compatible Implementation"
```

### Different Byte Code
```bash
# Compare first 32 bytes
hexdump -C BIOS_IBM5150_19OCT81_5700671_U33.BIN | head -3
hexdump -C cleanroom_bios/build/bios.bin | head -3
# Completely different!
```

### Different Dates
```bash
# Original: 10/19/81
# Cleanroom: 12/28/24
```

---

## What's Implemented?

### ✅ Working
- Power-On Self Test (POST)
- CPU flag tests
- Memory detection (up to 640KB)
- Video output (80x25 text mode)
- Interrupt handlers (INT 10h-19h)
- Hardware initialization (PIC, PIT, PPI)
- BIOS Data Area (BDA)
- Bootstrap loader stub

### 🔄 Simplified (for demo)
- Keyboard (basic)
- Disk I/O (stub)
- Serial/Printer (stub)

### 📚 Educational Scope
This is a demonstration of cleanroom technique, not a production BIOS. It proves the methodology works!

---

## Next Steps

1. **Read the documentation**:
   ```bash
   ls docs/
   ```

2. **Study the specifications**:
   ```bash
   less docs/SPECIFICATIONS.md
   ```

3. **Compare implementations**:
   ```bash
   less docs/COMPARISON.md
   ```

4. **Explore the code**:
   ```bash
   less cleanroom_bios/bios.asm
   ```

5. **Run more tests**:
   ```bash
   cd /workspace/cleanroom_bios
   make test
   ```

---

## FAQ

**Q: Is this legal?**  
A: Yes! Cleanroom reverse engineering is validated by courts (Phoenix v. IBM, NEC v. Intel).

**Q: Can I use this BIOS?**  
A: This is an educational demonstration. For production use, you'd need complete implementations of all features.

**Q: Did you copy IBM's code?**  
A: No! The cleanroom implementation was written from specifications only, without seeing IBM's code structure.

**Q: How do you prove it's different?**  
A: Multiple ways:
- Different hex dump (byte-for-byte comparison)
- Different copyright and date
- Different code metrics (INT/IRET counts)
- Different internal structure
- Git history shows specs before code

**Q: Why are some features stubbed?**  
A: This is an educational project demonstrating the cleanroom technique. A production BIOS would implement everything.

---

## Resources

- **Phoenix Technologies History**: [Wikipedia](https://en.wikipedia.org/wiki/Phoenix_Technologies)
- **Clean Room Design**: [Legal Background](https://en.wikipedia.org/wiki/Clean_room_design)
- **IBM PC 5150**: [Technical Reference](http://www.minuszerodegrees.net/manuals/IBM_5150_Technical_Reference_6025005_APR84.pdf)
- **8086 Reference**: See `docs/8086_OPCODE_REFERENCE.md`

---

**🎉 Congratulations!** You've successfully explored a cleanroom reverse engineering project!

For complete details, see:
- `docs/SUMMARY.md` - Complete project summary
- `docs/COMPARISON.md` - Detailed comparison
- `README.md` - Full documentation
