# IBM PC 5150 BIOS Functional Specifications

**Document Type**: Team 1 Output - Behavioral Specification
**Target**: Team 2 Implementation Reference
**Date**: Based on IBM PC 5150 BIOS dated 10/19/81
**Purpose**: Define WHAT the BIOS does, not HOW it does it

---

## Overview

This document specifies the functional behavior of the IBM PC 5150 BIOS through black-box analysis. Implementation details are intentionally omitted to maintain cleanroom separation.

## Memory Map

### BIOS ROM Location
- **Physical Address**: 0xFE000 - 0xFFFFF (8KB at top of 64KB ROM space)
- **Segment:Offset**: F000:E000 - F000:FFFF
- **Size**: 8192 bytes

### BIOS Data Area (BDA)
Located at 0x0040:0x0000 - 0x0040:0x00FF (256 bytes)

**Critical BDA Locations**:
- `0x0449`: Current video mode (byte)
- `0x044A`: Number of screen columns (word)
- `0x044C`: Current video page size in bytes (word)
- `0x044E`: Current video page offset (word)
- `0x0450`: Cursor positions for 8 pages (16 bytes, 2 per page)
- `0x0460`: Cursor shape/size (word)
- `0x0462`: Current video page number (byte)
- `0x0463`: CRT controller base I/O address (word) - 0x3D4 for color, 0x3B4 for mono
- `0x0465`: CRT mode control register value (byte)
- `0x0466`: CRT color palette register value (byte)
- `0x0410`: Equipment word (word) - hardware configuration
- `0x0413`: Memory size in KB (word)
- `0x0417`: Keyboard shift flags (byte)
- `0x0419`: Alt-numeric keypad work area (byte)
- `0x041A`: Keyboard buffer head pointer (word)
- `0x041C`: Keyboard buffer tail pointer (word)
- `0x041E`: Keyboard buffer (32 bytes, 16 words)
- `0x046C`: Timer tick counter (dword) - increments 18.2 times per second
- `0x0471`: Break flag (byte)
- `0x0472`: Reset flag (word) - 0x1234 for warm boot
- `0x0475`: Number of hard drives (byte)
- `0x0478`: Printer timeout values (4 bytes)
- `0x047C`: Serial port timeout values (4 bytes)
- `0x0480`: Keyboard buffer start offset (word)
- `0x0482`: Keyboard buffer end offset (word)

### Interrupt Vector Table (IVT)
Located at 0x0000:0x0000 - 0x0000:0x03FF (1024 bytes)

Each vector is 4 bytes: [IP (word)][CS (word)]

## Power-On Self Test (POST)

### POST Sequence Behavior

When CPU resets, execution begins at 0xFFFF:0x0000 (physical 0xFFFF0).

**POST must perform these steps in order**:

1. **Disable Interrupts**
   - Clear IF flag
   - Ensure no interrupts during POST

2. **Test CPU Flags**
   - Verify all CPU flags work correctly
   - Test carry, zero, sign, overflow, parity flags
   - If any flag test fails, HALT (HLT instruction)

3. **Test Segment Registers**
   - Verify DS, ES, SS segment registers work
   - Test read/write functionality
   - If test fails, HALT

4. **Initialize Hardware**
   
   **8255 PPI (Programmable Peripheral Interface)**:
   - Port 0x61: Set to 0xFC (disable speaker, enable keyboard)
   - Port 0x63: Set to 0x99 (configuration)
   
   **DMA Controller**:
   - Port 0xA0: Clear DMA page register
   - Port 0x83: Clear DMA channel 0 page
   
   **Video Controller**:
   - Port 0x3D8: Initialize CRT mode control
   - Port 0x3D9: Initialize color select
   - Program 6845 CRTC registers for default text mode

5. **Test RAM**
   
   **Phase 1: First 16KB**
   - Test first 16KB of RAM (0x0000 - 0x3FFF)
   - Write test patterns and verify
   - This RAM must work for POST to continue
   - If test fails: Display error code and HALT
   
   **Phase 2: Determine Total RAM**
   - Test RAM in 16KB blocks up to 640KB
   - Write to each block to verify presence
   - Count total working RAM
   - Store total in BDA at 0x0413 (KB count)
   
   **Error Indication**:
   - If first 16KB fails: Show "PARITY CHECK 1" on screen
   - If error during expansion RAM: Show "PARITY CHECK 2" on screen

6. **Initialize Interrupt Vectors**
   
   Set up interrupt vector table entries:
   - INT 00h: Divide by zero
   - INT 01h: Single step
   - INT 02h: NMI (Non-Maskable Interrupt)
   - INT 08h: Timer tick
   - INT 09h: Keyboard
   - INT 0Eh: Diskette
   - INT 10h: Video services (→ F000:xxxx)
   - INT 11h: Equipment check (→ F000:xxxx)
   - INT 12h: Memory size (→ F000:xxxx)
   - INT 13h: Disk services (→ F000:xxxx)
   - INT 14h: Serial communications (→ F000:xxxx)
   - INT 15h: System services (→ F000:xxxx)
   - INT 16h: Keyboard services (→ F000:xxxx)
   - INT 17h: Printer services (→ F000:xxxx)
   - INT 18h: ROM BASIC (→ F600:0000, if available)
   - INT 19h: Bootstrap loader (→ F000:xxxx)
   - INT 1Ah: Time of day (→ F000:xxxx)
   - INT 1Ch: Timer tick user hook (→ IRET)
   - INT 1Dh: Video parameter table pointer
   - INT 1Eh: Disk parameter table pointer
   - INT 1Fh: Graphics character table pointer

7. **Initialize 8259 PIC (Programmable Interrupt Controller)**
   - Port 0x20: Send ICW1 (initialization command word 1)
   - Port 0x21: Send ICW2 (map INT 08h to IRQ0)
   - Port 0x21: Send ICW4 (8086 mode)
   - Port 0x21: Set interrupt mask (enable timer, keyboard, diskette)

8. **Initialize 8253 PIT (Programmable Interval Timer)**
   - Port 0x43: Control byte for channel 0
   - Port 0x40: Set counter value for 18.2Hz tick rate
   - This drives INT 08h timer tick

9. **Equipment Check**
   
   Detect and set equipment word at BDA 0x0410:
   
   **Bit 0**: Set if floppy drives present
   **Bits 1-2**: Unused
   **Bits 4-5**: Initial video mode
   - 00 = Reserved
   - 01 = 40x25 color
   - 10 = 80x25 color
   - 11 = 80x25 monochrome
   **Bits 6-7**: Number of floppy drives (00=1, 01=2, etc.)
   **Bit 8**: Unused (DMA chip)
   **Bits 9-11**: Number of RS232 serial ports
   **Bit 12**: Game adapter present
   **Bit 13**: Serial printer present (PCjr only)
   **Bits 14-15**: Number of printers

10. **Initialize Video**
    
    Based on equipment word bits 4-5:
    - Set video mode (INT 10h, AH=00h)
    - Clear screen
    - Initialize cursor position to (0,0)

11. **Initialize Keyboard**
    
    - Reset keyboard buffer (head = tail)
    - Clear shift flags at BDA 0x0417
    - Buffer starts at BDA 0x041E (32 bytes)
    - Set buffer pointers at BDA 0x041A, 0x041C

12. **Enable Interrupts**
    
    - Set IF flag (STI)
    - System now responsive to hardware

13. **Print Copyright Message**
    
    Display on screen:
    - "5700671 COPR. IBM 1981"
    - Or similar copyright notice

14. **Call INT 19h (Bootstrap)**
    
    - Attempt to load boot sector from diskette
    - If successful, jump to loaded code
    - If no bootable disk, call INT 18h (ROM BASIC)

## BIOS Interrupt Services

### INT 10h - Video Services

**Function AH=00h: Set Video Mode**
- **Input**: AL = video mode
  - 0x00: 40x25 B/W text
  - 0x01: 40x25 color text
  - 0x02: 80x25 B/W text
  - 0x03: 80x25 color text
  - 0x04: 320x200 4-color graphics (CGA)
  - 0x05: 320x200 4-color graphics (CGA, no color burst)
  - 0x06: 640x200 2-color graphics
  - 0x07: 80x25 monochrome text (MDA)
- **Output**: None
- **Action**:
  - Clear screen
  - Reset cursor to (0,0)
  - Program 6845 CRTC for mode
  - Set mode in BDA 0x0449
  - Set columns in BDA 0x044A
  - Set CRTC base in BDA 0x0463

**Function AH=01h: Set Cursor Type**
- **Input**: 
  - CH = cursor start line (bits 0-4)
  - CL = cursor end line (bits 0-4)
- **Output**: None
- **Action**: 
  - Program CRTC registers 10-11
  - Store in BDA 0x0460

**Function AH=02h: Set Cursor Position**
- **Input**:
  - BH = page number (0-7)
  - DH = row (0-24)
  - DL = column (0-79 or 0-39)
- **Output**: None
- **Action**:
  - Store position in BDA 0x0450 (2 bytes per page)
  - If active page, update CRTC registers 14-15

**Function AH=03h: Get Cursor Position**
- **Input**: BH = page number
- **Output**:
  - DH = row
  - DL = column
  - CH = cursor start line
  - CL = cursor end line
- **Action**: Read from BDA

**Function AH=05h: Select Active Display Page**
- **Input**: AL = page number (0-7 for text modes)
- **Output**: None
- **Action**:
  - Calculate page offset
  - Update CRTC start address registers
  - Store page in BDA 0x0462

**Function AH=06h: Scroll Window Up**
- **Input**:
  - AL = lines to scroll (0 = clear entire window)
  - BH = attribute for blank line
  - CH = row of upper left corner
  - CL = column of upper left corner
  - DH = row of lower right corner
  - DL = column of lower right corner
- **Output**: None
- **Action**: 
  - Move screen lines up
  - Fill bottom with blanks

**Function AH=07h: Scroll Window Down**
- **Input**: Same as AH=06h
- **Output**: None
- **Action**: 
  - Move screen lines down
  - Fill top with blanks

**Function AH=08h: Read Character and Attribute**
- **Input**: BH = page number
- **Output**:
  - AL = character
  - AH = attribute
- **Action**: Read from video RAM at cursor position

**Function AH=09h: Write Character and Attribute**
- **Input**:
  - AL = character
  - BH = page number
  - BL = attribute (text) or color (graphics)
  - CX = count (repeat count)
- **Output**: None
- **Action**: Write character CX times at cursor (doesn't advance cursor)

**Function AH=0Ah: Write Character Only**
- **Input**: Same as AH=09h, but doesn't modify attribute
- **Output**: None
- **Action**: Write character CX times, preserve existing attribute

**Function AH=0Eh: Write Teletype**
- **Input**:
  - AL = character
  - BH = page number
  - BL = foreground color (graphics modes)
- **Output**: None
- **Action**:
  - Write character at cursor
  - Advance cursor
  - Interpret control characters:
    - 0x07 (BEL): Beep speaker
    - 0x08 (BS): Move cursor left
    - 0x0A (LF): Move cursor down (scroll if needed)
    - 0x0D (CR): Move cursor to column 0

**Function AH=0Fh: Get Current Video Mode**
- **Input**: None
- **Output**:
  - AL = current mode
  - AH = number of columns
  - BH = active page
- **Action**: Read from BDA

### INT 11h - Equipment Determination

- **Input**: None
- **Output**: AX = equipment word from BDA 0x0410
- **Action**: Return hardware configuration bits

### INT 12h - Memory Size Determination

- **Input**: None
- **Output**: AX = memory size in KB (from BDA 0x0413)
- **Action**: Return conventional memory size (max 640)

### INT 13h - Disk Services

**Function AH=00h: Reset Disk System**
- **Input**: DL = drive (0x00 = A:, 0x80 = C:)
- **Output**: 
  - CF = 0 if success, 1 if error
  - AH = status
- **Action**: Reset disk controller

**Function AH=01h: Get Disk Status**
- **Input**: DL = drive
- **Output**: AH = status of last operation
- **Action**: Return error code

**Function AH=02h: Read Sectors**
- **Input**:
  - AL = number of sectors
  - CH = track/cylinder (0-79)
  - CL = sector (1-9, depending on format)
  - DH = head (0-1)
  - DL = drive (0x00-0x01 for floppies)
  - ES:BX = buffer address
- **Output**:
  - CF = 0 success, 1 error
  - AH = status
  - AL = number of sectors read
- **Action**: Read sectors from disk to memory

**Function AH=03h: Write Sectors**
- **Input**: Same as AH=02h
- **Output**: Same as AH=02h
- **Action**: Write sectors from memory to disk

**Function AH=04h: Verify Sectors**
- **Input**: Similar to AH=02h (no buffer)
- **Output**: CF, AH status
- **Action**: Verify sectors readable

**Function AH=05h: Format Track**
- **Input**:
  - AL = number of sectors
  - CH = track
  - DH = head
  - DL = drive
  - ES:BX = address field buffer
- **Output**: CF, AH status
- **Action**: Format track on diskette

**Disk Status Codes (AH return)**:
- 0x00: Success
- 0x01: Invalid command
- 0x02: Address mark not found
- 0x03: Write protect error
- 0x04: Sector not found
- 0x08: DMA overrun
- 0x09: DMA crosses 64KB boundary
- 0x0C: Media type not found
- 0x10: CRC error
- 0x20: Controller failure
- 0x40: Seek failed
- 0x80: Timeout

### INT 14h - Serial Communications

**Function AH=00h: Initialize Port**
- **Input**:
  - AL = parameters
    - Bits 0-1: Word length (10=7 bits, 11=8 bits)
    - Bit 2: Stop bits (0=1, 1=2)
    - Bits 3-4: Parity (00=none, 01=odd, 11=even)
    - Bits 5-7: Baud rate (000=110, 001=150, 010=300, 011=600, 100=1200, 101=2400, 110=4800, 111=9600)
  - DX = port number (0-3)
- **Output**: AX = port status
- **Action**: Initialize serial port

**Function AH=01h: Send Character**
- **Input**:
  - AL = character
  - DX = port number
- **Output**: AH = status (bit 7 = 1 if error)
- **Action**: Transmit character

**Function AH=02h: Receive Character**
- **Input**: DX = port number
- **Output**:
  - AL = character (if no error)
  - AH = status
- **Action**: Receive character

**Function AH=03h: Get Port Status**
- **Input**: DX = port number
- **Output**: AX = status
- **Action**: Return line and modem status

### INT 15h - System Services

**Function AH=4Fh: Keyboard Intercept** (if supported)
- **Input**: AL = scan code
- **Output**: 
  - CF = 0: process normally
  - CF = 1: key handled, ignore
- **Action**: Allow programs to intercept keyboard

**Function AH=88h: Get Extended Memory Size** (later BIOSes)
- **Input**: None
- **Output**: AX = KB above 1MB
- **Action**: Return extended memory (0 on PC 5150)

**Note**: Original PC 5150 BIOS has minimal INT 15h support.

### INT 16h - Keyboard Services

**Function AH=00h: Read Character**
- **Input**: None
- **Output**:
  - AH = scan code
  - AL = ASCII character
- **Action**: 
  - Wait until key available in buffer
  - Remove key from buffer
  - Return key code

**Function AH=01h: Check for Keystroke**
- **Input**: None
- **Output**:
  - ZF = 1: no key available
  - ZF = 0: key available
    - AH = scan code
    - AL = ASCII character
- **Action**: 
  - Check if key in buffer
  - Don't remove key
  - Set ZF based on result

**Function AH=02h: Get Shift Status**
- **Input**: None
- **Output**: AL = shift flags from BDA 0x0417
  - Bit 0: Right Shift pressed
  - Bit 1: Left Shift pressed
  - Bit 2: Ctrl pressed
  - Bit 3: Alt pressed
  - Bit 4: Scroll Lock on
  - Bit 5: Num Lock on
  - Bit 6: Caps Lock on
  - Bit 7: Insert mode on
- **Action**: Return keyboard shift state

**Keyboard Buffer**:
- Circular buffer at BDA 0x041E (32 bytes = 16 keys)
- Head pointer at BDA 0x041A
- Tail pointer at BDA 0x041C
- Full when (head+2) == tail
- Empty when head == tail

**Scan Codes** (examples):
- 0x01: ESC
- 0x02-0x0B: 1-0 keys
- 0x10-0x19: Q-P
- 0x1C: Enter
- 0x1D: Ctrl
- 0x1E-0x26: A-L
- 0x2A: Left Shift
- 0x2C-0x32: Z-M
- 0x36: Right Shift
- 0x38: Alt
- 0x39: Space
- 0x3A: Caps Lock
- 0x3B-0x44: F1-F10

### INT 17h - Printer Services

**Function AH=00h: Print Character**
- **Input**:
  - AL = character
  - DX = printer number (0-2)
- **Output**: AH = status
  - Bit 0: Timeout
  - Bit 3: I/O error
  - Bit 4: Selected
  - Bit 5: Out of paper
  - Bit 6: Acknowledge
  - Bit 7: Not busy
- **Action**: Send character to parallel port

**Function AH=01h: Initialize Printer**
- **Input**: DX = printer number
- **Output**: AH = status
- **Action**: Reset printer

**Function AH=02h: Get Printer Status**
- **Input**: DX = printer number
- **Output**: AH = status (same bits as AH=00h)
- **Action**: Return printer status

**Parallel Port I/O**:
- Port 0x378: Printer 0 data (LPT1)
- Port 0x379: Printer 0 status
- Port 0x37A: Printer 0 control

### INT 18h - ROM BASIC

- **Input**: None
- **Output**: Does not return
- **Action**: 
  - Jump to ROM BASIC at F600:0000 (if present)
  - On PC 5150 without BASIC ROM: HALT or display message

### INT 19h - Bootstrap Loader

- **Input**: None
- **Output**: Does not return (if successful)
- **Action**:
  1. Reset disk system (INT 13h, AH=00h, DL=00h)
  2. Read boot sector from drive A: (track 0, head 0, sector 1)
     - Use INT 13h, AH=02h
     - Load to 0x0000:0x7C00 (512 bytes)
  3. Check for boot signature:
     - Last two bytes must be 0x55AA
  4. If valid signature:
     - Jump to 0x0000:0x7C00
  5. If invalid or read fails:
     - Call INT 18h (ROM BASIC)

### INT 1Ah - Time of Day

**Function AH=00h: Read System Clock**
- **Input**: None
- **Output**:
  - CX:DX = tick count (32-bit)
  - AL = 0 if <24 hours since reset, else nonzero
- **Action**: Return timer tick count from BDA 0x046C

**Function AH=01h: Set System Clock**
- **Input**: CX:DX = tick count
- **Output**: None
- **Action**: Set timer tick count in BDA 0x046C

**Timer Tick Rate**: 18.2065 times per second (1193180 Hz / 65536)

## Hardware I/O Ports

### Video Controller (CGA at 0x3D4, MDA at 0x3B4)

**6845 CRTC Registers** (accessed via index/data ports):
- Port 0x3D4: Index register (select which CRTC register)
- Port 0x3D5: Data register (read/write selected register)
- Port 0x3D8: Mode control register
- Port 0x3D9: Color select register

**CRTC Register Functions**:
- Reg 0-7: Horizontal timing
- Reg 8-9: Vertical timing
- Reg 10-11: Cursor shape
- Reg 12-13: Display start address
- Reg 14-15: Cursor position
- Reg 16-17: Light pen position

### Keyboard (8255 PPI)

- Port 0x60: Keyboard data input
- Port 0x61: System control port
  - Bit 0: Timer 2 gate
  - Bit 1: Speaker data
  - Bit 5: Enable I/O check
  - Bit 6: Enable keyboard
  - Bit 7: Enable keyboard clock
- Port 0x62: Configuration (read system switches)
- Port 0x63: PPI control

### Timer (8253 PIT)

- Port 0x40: Counter 0 data (system timer)
- Port 0x41: Counter 1 data (RAM refresh)
- Port 0x42: Counter 2 data (speaker tone)
- Port 0x43: Control word register

**Timer 0 Programming**:
- Set to mode 3 (square wave)
- Count value 65536 (0x10000)
- Frequency: 1193180 Hz / 65536 = 18.2065 Hz
- Generates INT 08h

### Interrupt Controller (8259 PIC)

- Port 0x20: Command register
- Port 0x21: Data/mask register

**IRQ Mapping** (after initialization):
- IRQ 0 → INT 08h: Timer tick
- IRQ 1 → INT 09h: Keyboard
- IRQ 2 → INT 0Ah: Reserved
- IRQ 3 → INT 0Bh: COM2/COM4
- IRQ 4 → INT 0Ch: COM1/COM3
- IRQ 5 → INT 0Dh: Hard disk (XT)
- IRQ 6 → INT 0Eh: Diskette
- IRQ 7 → INT 0Fh: Printer

### DMA Controller (8237)

- Port 0x00-0x0F: DMA channels 0-3
- Port 0x80-0x8F: DMA page registers

**DMA Channel 2**: Used for floppy disk transfers

### Floppy Disk Controller (NEC μPD765)

- Port 0x3F0-0x3F7: Floppy controller registers
- Port 0x3F2: Digital output register (motor control, drive select)
- Port 0x3F4: Main status register
- Port 0x3F5: Data register (FIFO)
- Port 0x3F7: Digital input register / Configuration control

## Reset Vector

**Physical Address**: 0xFFFF0
**Instruction**: `JMP F000:E05B` (far jump to POST start)
**ROM Content at 0xFFF5**: Date string "10/19/81"
**ROM Content at 0xE000**: Copyright "5700671 COPR. IBM 1981"

## Character Set

Standard IBM PC character set (Code Page 437):
- 0x00-0x1F: Control characters and symbols
- 0x20-0x7E: ASCII printable characters
- 0x7F-0xFF: Extended characters (box drawing, international, etc.)

Font stored in ROM, character generator ROM at 0xF000:0xFA6E (approximate).

## Boot Sequence Summary

1. Power on → CPU starts at 0xFFFF0
2. Jump to POST start
3. Test CPU, RAM, hardware
4. Initialize interrupt vectors
5. Initialize hardware (PIC, PIT, video, keyboard)
6. Display copyright message
7. Call INT 19h
8. INT 19h loads boot sector to 0x0000:0x7C00
9. Verify signature 0x55AA
10. Jump to boot sector code
11. Operating system takes control

## Error Handling

**POST Errors**:
- Beep codes: Series of beeps indicate specific hardware failures
- Screen messages: "PARITY CHECK 1" or "PARITY CHECK 2"
- HALT: System stops if critical error

**Runtime Errors**:
- Disk errors: Return status code in AH
- Timeout errors: Return CF=1 or specific bit in status
- Invalid operations: May return error code or do nothing

## Timing Requirements

**Timer Tick**: Exactly 18.2065 Hz (critical for time keeping)
**Keyboard**: Scan at ~60 Hz
**Diskette Operations**: May take several seconds
**Serial Port**: Depends on baud rate (110 - 9600 bps)

## Compatibility Notes

The BIOS must:
- Preserve registers not explicitly returned (except where documented)
- Follow IBM's INT calling conventions
- Return with IRET for interrupt handlers
- Return with RETF for far calls (none in standard BIOS)
- Return with RET for near calls (internal only)
- Maintain BDA contents consistently
- Support warm boot via reset flag 0x1234 at BDA 0x0472

---

## Implementation Guidelines (Team 2)

1. **Read this specification only** - do not examine original ROM code
2. **Test-driven development** - implement to pass test suite
3. **Make independent choices** - your algorithms are your own
4. **Focus on behavior** - match inputs/outputs, not internal implementation
5. **Document your code** - with your own comments and style
6. **Ask for clarification** - if specifications are ambiguous (behavioral questions only)

---

**End of Functional Specification**

This document intentionally omits:
- Specific implementation algorithms
- Register usage patterns
- Code structure and organization
- Optimization techniques
- Internal subroutines and helpers

Team 2 must create these independently based on these behavioral requirements.
