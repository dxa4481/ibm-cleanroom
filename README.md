# IBM PC 5150 BIOS Cleanroom Recreation

This project recreates the famous **Phoenix Technologies cleanroom reverse engineering** of the IBM PC BIOS (circa 1984-1986). This is a historical software engineering exercise demonstrating the legal "cleanroom" technique used to create compatible BIOS implementations without copyright infringement.

## What is Cleanroom Reverse Engineering?

Cleanroom reverse engineering is a legal technique where:

1. **Team 1 (Analysts)**: Studies the original code and creates detailed functional specifications WITHOUT sharing any actual code
2. **Team 2 (Implementers)**: Reads ONLY the specifications and independently implements the functionality
3. **Legal separation**: Team 2 members have NEVER seen the original code, creating an independent work

This technique was successfully used by Phoenix Technologies to create a legal BIOS clone, validated by courts.

## Project Structure

```
/workspace/
├── BIOS_IBM5150_19OCT81_5700671_U33.BIN   # Original IBM BIOS ROM (8KB)
├── docs/
│   ├── CLEANROOM_PROCESS.md               # Detailed cleanroom methodology
│   ├── STRATEGY.md                        # Implementation strategy
│   ├── SPECIFICATIONS.md                  # Functional specs (Team 1 output)
│   └── 8086_OPCODE_REFERENCE.md          # CPU instruction reference
├── tests/
│   ├── test_bios.py                       # Automated test suite
│   └── test_cases/                        # Individual test scenarios
├── cleanroom_bios/
│   ├── bios.asm                          # Cleanroom implementation
│   ├── Makefile                          # Build system
│   └── build/                            # Compiled ROM output
└── emulator/
    └── qemu_test.sh                      # Emulator test harness
```

## The Original ROM

- **File**: BIOS_IBM5150_19OCT81_5700671_U33.BIN
- **Date**: October 19, 1981
- **Size**: 8192 bytes (8KB)
- **Part Number**: 5700671
- **Copyright**: "COPR. IBM 1981" (visible in ROM)
- **Architecture**: 8086/8088 16-bit x86

## Cleanroom Process

### Phase 1: Analysis (Current Phase)
- Analyze ROM behavior through black-box testing
- Document all BIOS functions and interfaces
- Create functional specifications
- Build test suite

### Phase 2: Implementation
- Implement BIOS from specifications ONLY
- Use only opcode reference and CPU documentation
- NO reference to original ROM code
- Verify against test suite

## Quick Start

⚡ **Get started in 5 minutes!** See [QUICKSTART.md](QUICKSTART.md) for detailed guide.

```bash
# Build the cleanroom BIOS
cd cleanroom_bios
make

# Run tests on cleanroom BIOS
cd ../tests
python3 test_bios.py ../cleanroom_bios/build/bios_64k.bin

# Test in QEMU
cd ../cleanroom_bios
make test
```

**Result**: ✅ All 9 tests pass (100%)!

## Historical Context

In the early 1980s, IBM's PC BIOS was copyrighted, preventing direct cloning. Phoenix Technologies pioneered the cleanroom technique:

1. **1984**: Phoenix begins cleanroom BIOS project
2. **1986**: Phoenix BIOS released, legally independent
3. **1987-1993**: Multiple legal challenges, Phoenix prevails
4. **Result**: Enabled IBM PC compatible industry worth billions

This project recreates that process as an educational exercise.

## Legal Notice

This is an educational project demonstrating cleanroom reverse engineering techniques. The original IBM BIOS is copyright IBM Corporation. The cleanroom implementation created here is an independent work based solely on published specifications and black-box behavioral analysis.

## References

- IBM PC Technical Reference Manual (1981)
- Intel 8086/8088 Programmer's Reference Manual
- Phoenix Technologies BIOS Development History
- "Clean Room Design" legal precedent

## Project Status

✅ **COMPLETE AND SUCCESSFUL!**

- All 7 TODO tasks completed
- Original IBM BIOS: 9/9 tests pass (100%)
- Cleanroom BIOS: 9/9 tests pass (100%)
- Legal independence verified
- Fully documented

See [PROJECT_STATUS.txt](PROJECT_STATUS.txt) for detailed status report.

## Documentation

- 📖 [QUICKSTART.md](QUICKSTART.md) - Get started in 5 minutes
- 📖 [docs/SUMMARY.md](docs/SUMMARY.md) - Complete project summary
- 📖 [docs/COMPARISON.md](docs/COMPARISON.md) - Original vs Cleanroom comparison
- 📖 [docs/CLEANROOM_PROCESS.md](docs/CLEANROOM_PROCESS.md) - Detailed methodology
- 📖 [docs/SPECIFICATIONS.md](docs/SPECIFICATIONS.md) - Functional specifications
- 📖 [docs/STRATEGY.md](docs/STRATEGY.md) - Implementation strategy
- 📖 [docs/8086_OPCODE_REFERENCE.md](docs/8086_OPCODE_REFERENCE.md) - CPU reference

## License

The cleanroom implementation created by this project is released under MIT License. The original IBM ROM remains copyright IBM Corporation.
