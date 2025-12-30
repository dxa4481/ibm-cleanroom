# Cleanroom Reverse Engineering Process

## Overview

This document describes the cleanroom methodology used to create a legal, independent implementation of the IBM PC 5150 BIOS.

## Historical Background

### Phoenix Technologies v. IBM (1984-1986)

Phoenix Technologies successfully used cleanroom reverse engineering to create a legal BIOS clone:

1. **Problem**: IBM's BIOS was copyrighted, preventing direct copying
2. **Solution**: Separate teams with legal "Chinese Wall" between them
3. **Result**: Courts validated the technique as creating independent work
4. **Impact**: Enabled the IBM PC compatible industry

### Legal Principles

- **Copyright protects expression, not ideas**: The specific code is copyrighted, but the functionality it implements is not
- **Independent creation defense**: If created without copying, no infringement occurs
- **Clean room creates independence**: Proper separation proves no copying occurred

## Two-Team Structure

### Team 1: Specification Team (Analysts)

**Role**: Study original ROM and document behavior

**Allowed to**:
- Examine original ROM binary
- Run ROM in emulators/real hardware
- Observe all inputs and outputs
- Test edge cases and error conditions
- Document functional behavior
- Create test cases

**NOT allowed to**:
- Share disassembled code with Team 2
- Share specific implementation details
- Discuss algorithm implementations
- Provide code snippets or pseudocode resembling original

**Output**:
- Functional specifications (what it does, not how)
- Interface documentation (inputs/outputs)
- Test suite with expected behaviors
- Hardware interaction requirements

**Example Specification**:
```
GOOD (describes behavior):
"INT 10h, AH=0Eh: Write character to screen at cursor position.
 Input: AL = ASCII character, BL = foreground color
 Output: Character displayed, cursor advances
 Side effects: If at end of line, cursor wraps to next line"

BAD (describes implementation):
"Load AL into video memory at address ES:DI, then increment DI"
```

### Team 2: Implementation Team (Programmers)

**Role**: Implement BIOS from specifications ONLY

**Allowed to**:
- Read functional specifications from Team 1
- Read public documentation (Intel manuals, etc.)
- Use opcode reference sheets
- Write assembly code
- Run tests against their implementation
- Ask Team 1 for clarification on SPECIFICATIONS (not implementation)

**NOT allowed to**:
- See original ROM code or disassembly
- Ask "how did IBM do X?"
- Receive any implementation hints from those who saw original

**Output**:
- New BIOS implementation
- Source code (assembly)
- Build system
- Documentation of their implementation

## Process Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Phase 1: Analysis (Team 1)                                  │
│                                                              │
│  [Original ROM] → [Black-box Testing] → [Specifications]   │
│                         ↓                                    │
│                   [Test Suite]                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    ┌───────────────┐
                    │  CHINESE WALL │
                    │   (Legal)     │
                    └───────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 2: Implementation (Team 2)                            │
│                                                              │
│  [Specifications] → [Code Writing] → [Cleanroom BIOS]      │
│  [Opcode Ref]    ↙                      ↓                   │
│                                    [Run Tests]               │
│                                         ↓                    │
│                                    [Pass? → Done]           │
│                                    [Fail? → Debug & Retry]  │
└─────────────────────────────────────────────────────────────┘
```

## This Project's Approach

Since this is a solo educational project, we simulate the two-team process:

### Current Directory Structure

```
/workspace/
├── BIOS_IBM5150_19OCT81_5700671_U33.BIN  # Original (Team 1 access)
├── docs/
│   ├── SPECIFICATIONS.md                  # Team 1 → Team 2 handoff
│   └── 8086_OPCODE_REFERENCE.md          # Team 2 reference
├── tests/                                 # Team 1 creates, Team 2 uses
│   └── test_bios.py
└── cleanroom_bios/                        # Team 2 work product
    └── bios.asm
```

### Workflow Simulation

**Phase 1 (Team 1 - Analyst Role)**:
1. Analyze original ROM with disassembler/emulator
2. Document what each INT/function does
3. Create test cases
4. Write SPECIFICATIONS.md with NO implementation details
5. **STOP looking at original ROM code**

**Phase 2 (Team 2 - Implementer Role)**:
1. Read ONLY specifications and opcode reference
2. Implement functionality from scratch
3. Run tests
4. Debug using test output (not original ROM)
5. Iterate until tests pass

## Key Rules for Legal Cleanroom

### DO:
✓ Document behavior: "This function returns error code 1 if disk not ready"
✓ Document interfaces: "INT 13h, AH=02h reads disk sectors"
✓ Document data formats: "Disk parameter table has 11 bytes in this format..."
✓ Create test cases: "When AH=0, returns AX=0 on success"
✓ Use public CPU references
✓ Ask Team 1 to clarify ambiguous specifications

### DON'T:
✗ Copy code structure: "Use three nested loops like original"
✗ Copy algorithms: "Original uses binary search here"
✗ Copy register usage: "Store temp value in DI like original"
✗ Copy optimization tricks: "Original uses XOR AX,AX instead of MOV AX,0"
✗ Show disassembly to Team 2
✗ Describe implementation flow: "Original does X then Y then Z"

## Example: INT 10h Video Services

### Team 1 Specification (CORRECT):

```markdown
## INT 10h - Video Services

### Function AH=00h - Set Video Mode
**Input:**
  - AH = 00h
  - AL = desired video mode
    - 00h = 40x25 B/W text
    - 01h = 40x25 color text
    - 02h = 80x25 B/W text
    - 03h = 80x25 color text

**Output:**
  - None

**Behavior:**
  - Clears screen
  - Resets cursor to (0,0)
  - Initializes video hardware registers
  - Sets internal video mode variable

**Hardware:**
  - Programs 6845 CRT controller
  - Sets CGA mode register at I/O port 3D8h
```

### Team 1 Specification (INCORRECT - too specific):

```markdown
WRONG: "Store mode in byte at 0040:0049h, then loop through
        register table at offset F000:1234 writing to ports..."
        
This describes HOW, not WHAT!
```

## Validation

### How to Prove Cleanroom Success:

1. **Documentation trail**: Specifications exist before code
2. **Personnel isolation**: Team 2 never saw original
3. **Different structure**: Cleanroom code has different organization
4. **Independent decisions**: Different algorithms/approaches
5. **Test-driven**: Implementation driven by specs and tests, not original

### This Project:

- Git commits show specification written before implementation
- Implementation file has no comments copied from disassembly
- Different code structure (can prove by comparison later)
- Test suite exists independently

## Practical Tips

### For Specifications (Team 1):

1. Think like a user of the BIOS, not implementer
2. Focus on "what happens" not "how it happens"
3. Document edge cases and error conditions
4. Be precise about inputs, outputs, side effects
5. Include timing/performance requirements if critical
6. Test thoroughly before handing off

### For Implementation (Team 2):

1. Never ask to see original code
2. Make independent design decisions
3. Choose your own algorithms
4. If specs are unclear, ask for clarification (behavioral only)
5. Write different comments, variable names, structure
6. Use test failures to debug, not original code

## Legal Strength

Cleanroom defense strength depends on:

1. **Documentation**: Comprehensive audit trail
2. **Separation**: Strict adherence to team boundaries
3. **Independence**: Demonstrably different implementation choices
4. **Testing**: Test-driven vs. code-driven development

This project maintains all four for educational demonstration.

## References

- NEC v. Intel (1989) - Validated cleanroom microcode
- Sega v. Accolade (1992) - Reverse engineering for compatibility
- Phoenix Technologies BIOS development documentation
- "Clean Room Design: An Empirical Study" - IEEE Software
