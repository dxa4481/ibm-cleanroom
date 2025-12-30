# Cleanroom Implementation Strategy

## Project Goals

1. **Educational**: Demonstrate cleanroom reverse engineering technique
2. **Historical**: Recreate Phoenix Technologies' approach (1984-1986)
3. **Legal**: Show how to create compatible software without copyright infringement
4. **Practical**: Produce working BIOS that passes behavioral tests

## ROM Analysis Results

### Original IBM PC 5150 BIOS

- **Filename**: BIOS_IBM5150_19OCT81_5700671_U33.BIN
- **Date**: October 19, 1981 (visible in ROM: "10/19/81")
- **Copyright**: "COPR. IBM 1981"
- **Part Number**: 5700671
- **Size**: 8192 bytes (8KB)
- **Memory Address**: 0xF000:0xE000 to 0xF000:0xFFFF (ROM segment)
- **Reset Vector**: 0xFFFF0 (last 16 bytes)
- **Architecture**: Intel 8086/8088

### ROM Contents (High-Level Behavioral Analysis)

From black-box analysis, the ROM contains:

1. **Power-On Self Test (POST)**
   - Memory test
   - Hardware detection
   - Keyboard check
   - Video initialization

2. **BIOS Interrupts** (INT handlers)
   - INT 10h: Video services
   - INT 11h: Equipment check
   - INT 12h: Memory size
   - INT 13h: Disk services
   - INT 14h: Serial port
   - INT 15h: System services
   - INT 16h: Keyboard services
   - INT 17h: Printer services
   - INT 19h: Bootstrap loader

3. **Hardware Initialization**
   - 8259 Interrupt controller
   - 8253 Timer
   - 8255 PPI (keyboard, speaker)
   - 6845 Video controller

4. **Boot Process**
   - POST completion
   - Load boot sector from disk
   - Jump to loaded code

## Implementation Phases

### Phase 1: Documentation & Setup (Current)

**Team 1 Activities**:
- [x] Analyze ROM structure
- [ ] Document BIOS interrupt interfaces
- [ ] Create functional specifications
- [ ] Build test suite
- [ ] Create opcode reference

**Deliverables**:
- SPECIFICATIONS.md (behavioral documentation)
- 8086_OPCODE_REFERENCE.md
- test_bios.py (test suite)
- Emulator test harness

### Phase 2: Test-Driven Development

**Process**:
1. Create specific test for each function
2. Test against original ROM (should pass)
3. These tests become acceptance criteria for cleanroom implementation

**Example Test**:
```python
def test_int11_equipment_check():
    """INT 11h should return equipment word in AX"""
    # Setup: Boot ROM in emulator
    # Execute: INT 11h
    # Assert: AX contains valid equipment bits
    # Bit 0: Floppy drives present
    # Bit 4-5: Initial video mode
    # Bits 14-15: Number of floppy drives
```

### Phase 3: Cleanroom Implementation

**Team 2 Activities**:
- Read specifications ONLY
- Implement BIOS in 8086 assembly
- Run test suite
- Iterate until all tests pass

**Implementation Strategy**:
1. Start with minimal boot stub
2. Add interrupt handlers one by one
3. Implement POST sequence
4. Add hardware initialization
5. Complete bootstrap loader

### Phase 4: Validation

**Success Criteria**:
- All tests pass
- Boots real/emulated IBM PC
- Compatible with period software
- Demonstrably independent code structure

## Technical Approach

### Development Environment

**Tools**:
- **Assembler**: NASM (Netwide Assembler)
- **Emulator**: QEMU (qemu-system-i386)
- **Testing**: Python 3 + pytest
- **Disassembler** (Team 1 only): objdump, ndisasm
- **Debugger**: GDB with QEMU

**Build Process**:
```
bios.asm → [NASM] → bios.bin (8KB) → [QEMU] → Test Results
```

### Memory Layout

**IBM PC 5150 Memory Map**:
```
0x00000 - 0x003FF: Interrupt Vector Table (1KB)
0x00400 - 0x004FF: BIOS Data Area (256 bytes)
0x00500 - 0x9FFFF: Conventional Memory (640KB)
0xA0000 - 0xBFFFF: Video Memory (128KB)
0xC0000 - 0xEFFFF: ROM Extensions
0xF0000 - 0xFFFFF: System BIOS (64KB)
  0xFE000 - 0xFFFFF: Actual BIOS code (8KB)
```

### Critical BIOS Data Area (0x0400-0x04FF)

Team 1 will document expected locations:
- 0x0449: Current video mode
- 0x044A: Screen columns
- 0x044E: Video page offset
- 0x0450: Cursor positions
- 0x0463: CRT controller base address
- 0x046C: Timer tick counter
- 0x0410: Equipment word
- 0x0413: Memory size in KB

### Interrupt Vector Table (IVT)

Reset vectors must point to BIOS handlers:
- INT 10h @ 0x0040: Video services
- INT 11h @ 0x0044: Equipment check
- INT 12h @ 0x0048: Memory size
- INT 13h @ 0x004C: Disk services
- INT 14h @ 0x0050: Serial
- INT 15h @ 0x0054: System
- INT 16h @ 0x0058: Keyboard
- INT 17h @ 0x005C: Printer
- INT 19h @ 0x0064: Bootstrap

### Hardware I/O Ports

**Team 1 will document required hardware interactions**:

**8259 PIC (Interrupt Controller)**:
- Port 0x20: Command
- Port 0x21: Data

**8253 PIT (Timer)**:
- Port 0x40-0x43: Channels 0-2, Control

**8255 PPI (Parallel)**:
- Port 0x60: Keyboard data
- Port 0x61: System control
- Port 0x62: Configuration

**Video (CGA)**:
- Port 0x3D4-0x3D5: 6845 CRTC registers
- Port 0x3D8: Mode control
- Port 0x3D9: Color select
- Memory 0xB8000: Text mode buffer

## Testing Strategy

### Test Levels

**Level 1: Interrupt Tests**
- Call each INT with valid parameters
- Verify return values
- Check register preservation
- Test error conditions

**Level 2: Integration Tests**
- POST sequence completion
- Video initialization
- Keyboard input
- Boot sector loading

**Level 3: Compatibility Tests**
- Boot real DOS disk image
- Run period software
- Hardware detection accuracy

### Test Execution

**Against Original**:
```bash
qemu-system-i386 -bios BIOS_IBM5150_19OCT81_5700671_U33.BIN \
                 -monitor stdio -serial file:test_output.txt
```

**Against Cleanroom**:
```bash
qemu-system-i386 -bios cleanroom_bios/build/bios.bin \
                 -monitor stdio -serial file:test_output.txt
```

**Automated Testing**:
```python
# tests/test_bios.py
def run_bios_test(bios_path, test_case):
    qemu = start_qemu(bios_path)
    result = execute_test(qemu, test_case)
    qemu.terminate()
    return result
```

## Risk Mitigation

### Legal Risks

**Mitigation**:
- Strict team separation (simulated)
- Documentation before implementation
- No copying of code structure
- Independent design decisions
- Git commit history as audit trail

### Technical Risks

**Challenge**: Missing undocumented behavior
**Mitigation**: Thorough black-box testing, document all edge cases

**Challenge**: Hardware timing requirements
**Mitigation**: Test on real hardware if possible, document timing in specs

**Challenge**: Compatibility with software
**Mitigation**: Test with period DOS/games, refine specifications as needed

## Success Metrics

### Functional Success
- [ ] Passes all interrupt tests
- [ ] Completes POST sequence
- [ ] Boots DOS disk image
- [ ] Displays video correctly
- [ ] Accepts keyboard input
- [ ] Reads floppy disk

### Legal Success
- [ ] Specifications written before code
- [ ] No implementation details in specs
- [ ] Different code structure than original
- [ ] Independent algorithm choices
- [ ] Documentation trail in git history

### Educational Success
- [ ] Demonstrates cleanroom technique
- [ ] Documents historical context
- [ ] Shows test-driven approach
- [ ] Explains legal principles
- [ ] Provides working example

## Timeline

**Phase 1: Documentation** (Current)
- Opcode reference sheet
- ROM behavioral analysis
- Functional specifications
- Test suite creation

**Phase 2: Implementation** (Next)
- Basic boot stub
- Interrupt handlers
- POST sequence
- Hardware initialization
- Bootstrap loader

**Phase 3: Validation**
- Test execution
- Bug fixes
- Compatibility testing
- Documentation completion

## References for Team 2

**Allowed Documentation**:
- Intel 8086/8088 Programmer's Manual (public)
- IBM PC Technical Reference Manual (public)
- Hardware datasheets (6845, 8259, 8253, 8255)
- Our opcode reference sheet
- Our functional specifications

**NOT Allowed**:
- Disassembly of original ROM
- Implementation hints from Team 1
- Other BIOS source code
- Specific algorithm descriptions

## Conclusion

This strategy recreates Phoenix Technologies' successful cleanroom approach. By maintaining strict separation between analysis and implementation, we create a legally independent work while achieving functional compatibility.

The key is: **Document WHAT it does, not HOW it does it.**
