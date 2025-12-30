# Intel 8086/8088 Opcode Reference

This reference sheet is for **Team 2 (Implementation)** use only. It contains NO information about the original IBM ROM, only standard Intel 8086/8088 CPU instructions from public documentation.

## CPU Architecture

### Registers

**General Purpose (16-bit)**:
- **AX** (AH:AL) - Accumulator (arithmetic, I/O)
- **BX** (BH:BL) - Base register (addressing)
- **CX** (CH:CL) - Counter (loops, shifts)
- **DX** (DH:DL) - Data register (I/O, arithmetic)

**Segment Registers**:
- **CS** - Code Segment
- **DS** - Data Segment
- **SS** - Stack Segment
- **ES** - Extra Segment

**Index/Pointer Registers**:
- **SI** - Source Index
- **DI** - Destination Index
- **BP** - Base Pointer
- **SP** - Stack Pointer

**Special Registers**:
- **IP** - Instruction Pointer
- **FLAGS** - Status flags (16-bit)

### FLAGS Register

```
15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
 -  -  -  -  OF DF IF TF SF ZF  - AF  - PF  - CF
```

- **CF** - Carry Flag
- **PF** - Parity Flag
- **AF** - Auxiliary Carry Flag
- **ZF** - Zero Flag
- **SF** - Sign Flag
- **TF** - Trap Flag
- **IF** - Interrupt Enable Flag
- **DF** - Direction Flag
- **OF** - Overflow Flag

## Addressing Modes

**Immediate**: `MOV AX, 1234h`
**Register**: `MOV AX, BX`
**Direct**: `MOV AX, [1234h]`
**Register Indirect**: `MOV AX, [BX]`
**Based**: `MOV AX, [BX+10h]`
**Indexed**: `MOV AX, [SI+10h]`
**Based Indexed**: `MOV AX, [BX+SI]`
**Based Indexed + Displacement**: `MOV AX, [BX+SI+10h]`

## Data Transfer Instructions

### MOV - Move

```nasm
MOV dest, src          ; dest = src (does not affect flags)
```

**Opcodes**:
- `88 /r` - MOV r/m8, r8
- `89 /r` - MOV r/m16, r16
- `8A /r` - MOV r8, r/m8
- `8B /r` - MOV r16, r/m16
- `8C /r` - MOV r/m16, Sreg
- `8E /r` - MOV Sreg, r/m16
- `B0-B7 ib` - MOV r8, imm8
- `B8-BF iw` - MOV r16, imm16
- `C6 /0 ib` - MOV r/m8, imm8
- `C7 /0 iw` - MOV r/m16, imm16

### PUSH - Push onto Stack

```nasm
PUSH src               ; [SP-2] = src, SP = SP - 2
```

**Opcodes**:
- `50-57` - PUSH r16
- `06, 0E, 16, 1E` - PUSH Sreg
- `FF /6` - PUSH r/m16

### POP - Pop from Stack

```nasm
POP dest               ; dest = [SP], SP = SP + 2
```

**Opcodes**:
- `58-5F` - POP r16
- `07, 17, 1F` - POP Sreg
- `8F /0` - POP r/m16

### XCHG - Exchange

```nasm
XCHG dest, src         ; temp = dest, dest = src, src = temp
```

**Opcodes**:
- `90-97` - XCHG AX, r16
- `86 /r` - XCHG r8, r/m8
- `87 /r` - XCHG r16, r/m16

### IN - Input from Port

```nasm
IN AL, port            ; AL = input from port
IN AX, port            ; AX = input from port
IN AL, DX              ; AL = input from port DX
IN AX, DX              ; AX = input from port DX
```

**Opcodes**:
- `E4 ib` - IN AL, imm8
- `E5 ib` - IN AX, imm8
- `EC` - IN AL, DX
- `ED` - IN AX, DX

### OUT - Output to Port

```nasm
OUT port, AL           ; output AL to port
OUT port, AX           ; output AX to port
OUT DX, AL             ; output AL to port DX
OUT DX, AX             ; output AX to port DX
```

**Opcodes**:
- `E6 ib` - OUT imm8, AL
- `E7 ib` - OUT imm8, AX
- `EE` - OUT DX, AL
- `EF` - OUT DX, AX

### LEA - Load Effective Address

```nasm
LEA dest, src          ; dest = offset of src
```

**Opcode**: `8D /r`

### LDS - Load DS:reg

```nasm
LDS dest, src          ; dest = [src], DS = [src+2]
```

**Opcode**: `C5 /r`

### LES - Load ES:reg

```nasm
LES dest, src          ; dest = [src], ES = [src+2]
```

**Opcode**: `C4 /r`

### LAHF - Load AH from Flags

```nasm
LAHF                   ; AH = low byte of FLAGS
```

**Opcode**: `9F`

### SAHF - Store AH to Flags

```nasm
SAHF                   ; FLAGS low byte = AH
```

**Opcode**: `9E`

### PUSHF - Push Flags

```nasm
PUSHF                  ; PUSH FLAGS
```

**Opcode**: `9C`

### POPF - Pop Flags

```nasm
POPF                   ; POP FLAGS
```

**Opcode**: `9D`

## Arithmetic Instructions

### ADD - Add

```nasm
ADD dest, src          ; dest = dest + src (affects all flags)
```

**Opcodes**:
- `04 ib` - ADD AL, imm8
- `05 iw` - ADD AX, imm16
- `80 /0 ib` - ADD r/m8, imm8
- `81 /0 iw` - ADD r/m16, imm16
- `83 /0 ib` - ADD r/m16, imm8 (sign-extended)
- `00 /r` - ADD r/m8, r8
- `01 /r` - ADD r/m16, r16
- `02 /r` - ADD r8, r/m8
- `03 /r` - ADD r16, r/m16

### ADC - Add with Carry

```nasm
ADC dest, src          ; dest = dest + src + CF
```

**Similar opcodes to ADD**: `10-15, 80 /2, 81 /2, 83 /2`

### SUB - Subtract

```nasm
SUB dest, src          ; dest = dest - src
```

**Opcodes**:
- `2C ib` - SUB AL, imm8
- `2D iw` - SUB AX, imm16
- `80 /5 ib` - SUB r/m8, imm8
- `81 /5 iw` - SUB r/m16, imm16
- `83 /5 ib` - SUB r/m16, imm8
- `28 /r` - SUB r/m8, r8
- `29 /r` - SUB r/m16, r16
- `2A /r` - SUB r8, r/m8
- `2B /r` - SUB r16, r/m16

### SBB - Subtract with Borrow

```nasm
SBB dest, src          ; dest = dest - src - CF
```

**Similar opcodes to SUB**: `18-1D, 80 /3, 81 /3, 83 /3`

### INC - Increment

```nasm
INC dest               ; dest = dest + 1
```

**Opcodes**:
- `40-47` - INC r16
- `FE /0` - INC r/m8
- `FF /0` - INC r/m16

### DEC - Decrement

```nasm
DEC dest               ; dest = dest - 1
```

**Opcodes**:
- `48-4F` - DEC r16
- `FE /1` - DEC r/m8
- `FF /1` - DEC r/m16

### NEG - Negate

```nasm
NEG dest               ; dest = 0 - dest (two's complement)
```

**Opcodes**:
- `F6 /3` - NEG r/m8
- `F7 /3` - NEG r/m16

### CMP - Compare

```nasm
CMP dest, src          ; dest - src (affects flags, doesn't store)
```

**Opcodes**:
- `3C ib` - CMP AL, imm8
- `3D iw` - CMP AX, imm16
- `80 /7 ib` - CMP r/m8, imm8
- `81 /7 iw` - CMP r/m16, imm16
- `83 /7 ib` - CMP r/m16, imm8
- `38 /r` - CMP r/m8, r8
- `39 /r` - CMP r/m16, r16
- `3A /r` - CMP r8, r/m8
- `3B /r` - CMP r16, r/m16

### MUL - Unsigned Multiply

```nasm
MUL src                ; AX = AL * src (8-bit)
                       ; DX:AX = AX * src (16-bit)
```

**Opcodes**:
- `F6 /4` - MUL r/m8
- `F7 /4` - MUL r/m16

### IMUL - Signed Multiply

```nasm
IMUL src               ; Same as MUL but signed
```

**Opcodes**:
- `F6 /5` - IMUL r/m8
- `F7 /5` - IMUL r/m16

### DIV - Unsigned Divide

```nasm
DIV src                ; AL = AX / src, AH = remainder (8-bit)
                       ; AX = DX:AX / src, DX = remainder (16-bit)
```

**Opcodes**:
- `F6 /6` - DIV r/m8
- `F7 /6` - DIV r/m16

### IDIV - Signed Divide

```nasm
IDIV src               ; Same as DIV but signed
```

**Opcodes**:
- `F6 /7` - IDIV r/m8
- `F7 /7` - IDIV r/m16

### CBW - Convert Byte to Word

```nasm
CBW                    ; AH = sign extension of AL
```

**Opcode**: `98`

### CWD - Convert Word to Double Word

```nasm
CWD                    ; DX = sign extension of AX
```

**Opcode**: `99`

## Logic Instructions

### AND - Logical AND

```nasm
AND dest, src          ; dest = dest AND src
```

**Opcodes**: `24, 25, 80 /4, 81 /4, 83 /4, 20-23`

### OR - Logical OR

```nasm
OR dest, src           ; dest = dest OR src
```

**Opcodes**: `0C, 0D, 80 /1, 81 /1, 83 /1, 08-0B`

### XOR - Logical XOR

```nasm
XOR dest, src          ; dest = dest XOR src
```

**Opcodes**: `34, 35, 80 /6, 81 /6, 83 /6, 30-33`

**Note**: `XOR AX, AX` is common idiom for `MOV AX, 0` (smaller, faster)

### NOT - Logical NOT

```nasm
NOT dest               ; dest = ~dest (one's complement)
```

**Opcodes**:
- `F6 /2` - NOT r/m8
- `F7 /2` - NOT r/m16

### TEST - Logical Compare

```nasm
TEST dest, src         ; dest AND src (affects flags, doesn't store)
```

**Opcodes**: `A8, A9, F6 /0, F7 /0, 84, 85`

## Shift and Rotate Instructions

### SHL/SAL - Shift Left

```nasm
SHL dest, count        ; dest = dest << count
```

**Opcodes**:
- `D0 /4` - SHL r/m8, 1
- `D1 /4` - SHL r/m16, 1
- `D2 /4` - SHL r/m8, CL
- `D3 /4` - SHL r/m16, CL

### SHR - Shift Right (Logical)

```nasm
SHR dest, count        ; dest = dest >> count (zero fill)
```

**Opcodes**:
- `D0 /5` - SHR r/m8, 1
- `D1 /5` - SHR r/m16, 1
- `D2 /5` - SHR r/m8, CL
- `D3 /5` - SHR r/m16, CL

### SAR - Shift Right (Arithmetic)

```nasm
SAR dest, count        ; dest = dest >> count (sign extend)
```

**Opcodes**:
- `D0 /7` - SAR r/m8, 1
- `D1 /7` - SAR r/m16, 1
- `D2 /7` - SAR r/m8, CL
- `D3 /7` - SAR r/m16, CL

### ROL - Rotate Left

```nasm
ROL dest, count        ; Rotate dest left through all bits
```

**Opcodes**:
- `D0 /0` - ROL r/m8, 1
- `D1 /0` - ROL r/m16, 1
- `D2 /0` - ROL r/m8, CL
- `D3 /0` - ROL r/m16, CL

### ROR - Rotate Right

```nasm
ROR dest, count        ; Rotate dest right through all bits
```

**Opcodes**:
- `D0 /1` - ROR r/m8, 1
- `D1 /1` - ROR r/m16, 1
- `D2 /1` - ROR r/m8, CL
- `D3 /1` - ROR r/m16, CL

### RCL - Rotate Left through Carry

```nasm
RCL dest, count        ; Rotate dest left through CF
```

**Opcodes**:
- `D0 /2` - RCL r/m8, 1
- `D1 /2` - RCL r/m16, 1
- `D2 /2` - RCL r/m8, CL
- `D3 /2` - RCL r/m16, CL

### RCR - Rotate Right through Carry

```nasm
RCR dest, count        ; Rotate dest right through CF
```

**Opcodes**:
- `D0 /3` - RCR r/m8, 1
- `D1 /3` - RCR r/m16, 1
- `D2 /3` - RCR r/m8, CL
- `D3 /3` - RCR r/m16, CL

## String Instructions

### MOVSB/MOVSW - Move String

```nasm
MOVSB                  ; [ES:DI] = [DS:SI], SI++, DI++ (or -- if DF=1)
MOVSW                  ; Move word
```

**Opcodes**:
- `A4` - MOVSB
- `A5` - MOVSW

### STOSB/STOSW - Store String

```nasm
STOSB                  ; [ES:DI] = AL, DI++ (or -- if DF=1)
STOSW                  ; [ES:DI] = AX, DI += 2 (or -= 2)
```

**Opcodes**:
- `AA` - STOSB
- `AB` - STOSW

### LODSB/LODSW - Load String

```nasm
LODSB                  ; AL = [DS:SI], SI++ (or -- if DF=1)
LODSW                  ; AX = [DS:SI], SI += 2
```

**Opcodes**:
- `AC` - LODSB
- `AD` - LODSW

### CMPSB/CMPSW - Compare String

```nasm
CMPSB                  ; [DS:SI] - [ES:DI], SI++, DI++ (affects flags)
CMPSW                  ; Compare word
```

**Opcodes**:
- `A6` - CMPSB
- `A7` - CMPSW

### SCASB/SCASW - Scan String

```nasm
SCASB                  ; AL - [ES:DI], DI++ (affects flags)
SCASW                  ; AX - [ES:DI], DI += 2
```

**Opcodes**:
- `AE` - SCASB
- `AF` - SCASW

## Repeat Prefixes

These prefixes repeat string operations:

### REP - Repeat while CX != 0

```nasm
REP MOVSB              ; Repeat MOVSB CX times
```

**Opcode**: `F3`

### REPE/REPZ - Repeat while Equal/Zero

```nasm
REPE CMPSB             ; Repeat while ZF=1 and CX != 0
```

**Opcode**: `F3`

### REPNE/REPNZ - Repeat while Not Equal/Not Zero

```nasm
REPNE SCASB            ; Repeat while ZF=0 and CX != 0
```

**Opcode**: `F2`

## Control Transfer Instructions

### JMP - Unconditional Jump

```nasm
JMP target             ; IP = target (short, near, far)
JMP reg                ; IP = reg
JMP [mem]              ; IP = [mem]
```

**Opcodes**:
- `EB cb` - JMP rel8 (short, -128 to +127)
- `E9 cw` - JMP rel16 (near, within segment)
- `EA cd` - JMP ptr16:16 (far, different segment)
- `FF /4` - JMP r/m16 (indirect near)
- `FF /5` - JMP m16:16 (indirect far)

### Conditional Jumps (all rel8, -128 to +127)

```nasm
JE/JZ target           ; Jump if Equal/Zero (ZF=1)
JNE/JNZ target         ; Jump if Not Equal/Zero (ZF=0)
JL/JNGE target         ; Jump if Less (SF!=OF)
JLE/JNG target         ; Jump if Less or Equal (ZF=1 or SF!=OF)
JG/JNLE target         ; Jump if Greater (ZF=0 and SF=OF)
JGE/JNL target         ; Jump if Greater or Equal (SF=OF)
JA/JNBE target         ; Jump if Above (unsigned: CF=0 and ZF=0)
JAE/JNB target         ; Jump if Above or Equal (CF=0)
JB/JNAE target         ; Jump if Below (CF=1)
JBE/JNA target         ; Jump if Below or Equal (CF=1 or ZF=1)
JS target              ; Jump if Sign (SF=1)
JNS target             ; Jump if Not Sign (SF=0)
JO target              ; Jump if Overflow (OF=1)
JNO target             ; Jump if Not Overflow (OF=0)
JP/JPE target          ; Jump if Parity/Parity Even (PF=1)
JNP/JPO target         ; Jump if Not Parity/Parity Odd (PF=0)
JCXZ target            ; Jump if CX = 0
```

**Opcodes**: `70-7F, E3`

### CALL - Call Procedure

```nasm
CALL target            ; PUSH IP, JMP target (near)
                       ; PUSH CS, PUSH IP, JMP target (far)
```

**Opcodes**:
- `E8 cw` - CALL rel16 (near, relative)
- `9A cd` - CALL ptr16:16 (far, absolute)
- `FF /2` - CALL r/m16 (indirect near)
- `FF /3` - CALL m16:16 (indirect far)

### RET - Return from Procedure

```nasm
RET                    ; POP IP (near)
RET imm16              ; POP IP, SP = SP + imm16
RETF                   ; POP IP, POP CS (far)
RETF imm16             ; POP IP, POP CS, SP = SP + imm16
```

**Opcodes**:
- `C3` - RET (near)
- `C2 iw` - RET imm16 (near)
- `CB` - RETF (far)
- `CA iw` - RETF imm16 (far)

### LOOP - Loop while CX != 0

```nasm
LOOP target            ; CX--, if CX != 0 then JMP target
LOOPE/LOOPZ target     ; CX--, if CX != 0 and ZF=1 then JMP
LOOPNE/LOOPNZ target   ; CX--, if CX != 0 and ZF=0 then JMP
```

**Opcodes**:
- `E2 cb` - LOOP rel8
- `E1 cb` - LOOPE rel8
- `E0 cb` - LOOPNE rel8

### INT - Software Interrupt

```nasm
INT vector             ; PUSH FLAGS, PUSH CS, PUSH IP, 
                       ; IF=0, TF=0, JMP [vector*4]
```

**Opcodes**:
- `CD ib` - INT imm8
- `CC` - INT 3 (breakpoint)
- `CE` - INTO (interrupt on overflow, if OF=1)

### IRET - Return from Interrupt

```nasm
IRET                   ; POP IP, POP CS, POP FLAGS
```

**Opcode**: `CF`

## Processor Control Instructions

### CLC - Clear Carry Flag

```nasm
CLC                    ; CF = 0
```

**Opcode**: `F8`

### STC - Set Carry Flag

```nasm
STC                    ; CF = 1
```

**Opcode**: `F9`

### CMC - Complement Carry Flag

```nasm
CMC                    ; CF = ~CF
```

**Opcode**: `F5`

### CLD - Clear Direction Flag

```nasm
CLD                    ; DF = 0 (SI/DI increment)
```

**Opcode**: `FC`

### STD - Set Direction Flag

```nasm
STD                    ; DF = 1 (SI/DI decrement)
```

**Opcode**: `FD`

### CLI - Clear Interrupt Flag

```nasm
CLI                    ; IF = 0 (disable interrupts)
```

**Opcode**: `FA`

### STI - Set Interrupt Flag

```nasm
STI                    ; IF = 1 (enable interrupts)
```

**Opcode**: `FB`

### HLT - Halt

```nasm
HLT                    ; Halt processor until interrupt
```

**Opcode**: `F4`

### WAIT - Wait

```nasm
WAIT                   ; Wait for TEST pin active (for 8087 coprocessor)
```

**Opcode**: `9B`

### NOP - No Operation

```nasm
NOP                    ; Do nothing (actually XCHG AX, AX)
```

**Opcode**: `90`

### LOCK - Lock Bus

```nasm
LOCK prefix            ; Assert LOCK# signal (for multiprocessor)
```

**Opcode**: `F0` (prefix)

## Segment Override Prefixes

```nasm
CS:  ; 2E
DS:  ; 3E
ES:  ; 26
SS:  ; 36
```

## 8086/8088 Differences

The 8088 (used in IBM PC 5150) has:
- **8-bit external data bus** (vs 16-bit in 8086)
- **4-byte prefetch queue** (vs 6-byte in 8086)
- **Same instruction set** as 8086
- **Slightly slower** due to narrower bus

Both are **little-endian**: Low byte at low address.

## Reset Vector

On power-up or reset, the CPU:
1. Sets CS = 0xFFFF
2. Sets IP = 0x0000
3. Begins executing at physical address 0xFFFF0

BIOS ROM must be mapped to this address.

## Interrupt Vector Table (IVT)

Located at 0x00000 - 0x003FF (1KB):
- Each entry is 4 bytes: [IP:16][CS:16]
- INT N uses vector at address N * 4
- Example: INT 10h vector at 0x00040

## Common BIOS Idioms

**Zero register**:
```nasm
XOR AX, AX             ; Faster and smaller than MOV AX, 0
```

**Test for zero**:
```nasm
OR AX, AX              ; Set flags based on AX
JZ zero_label          ; Jump if AX = 0
```

**Save/restore all registers**:
```nasm
PUSH AX
PUSH BX
PUSH CX
PUSH DX
; ... do work ...
POP DX
POP CX
POP BX
POP AX
```

**Call far routine and return far**:
```nasm
CALL FAR [address]
RETF
```

## Timing Notes

Actual cycle counts vary by addressing mode and memory access:
- Register operations: fastest
- Memory operations: slower
- I/O operations: slowest
- String operations with REP: most efficient for bulk data

## Assembler Syntax (NASM)

**Sections**:
```nasm
ORG 0xE000             ; Origin address
SECTION .text          ; Code section
SECTION .data          ; Data section
```

**Labels**:
```nasm
label:                 ; Local label
global_label:          ; Global label
.local_label:          ; Local to previous label
```

**Constants**:
```nasm
CONSTANT EQU 0x1234    ; Define constant
```

**Data**:
```nasm
DB 0x12                ; Define byte
DW 0x1234              ; Define word
DD 0x12345678          ; Define dword
TIMES 10 DB 0          ; Repeat 10 times
```

## References

- Intel 8086 Family User's Manual (1979)
- Intel Microsystem Components Handbook (1984)
- IBM PC Technical Reference Manual (1981)
- 8086/8088 Assembly Language Programming (Willen & Krantz, 1983)

---

**Note for Team 2**: This reference is from public Intel documentation. Use this to implement BIOS functionality as described in the specifications. Do NOT reference the original IBM ROM code.
