; =============================================================================
; IBM PC 5150 BIOS - Cleanroom Implementation
; =============================================================================
; Created by: Team 2 (Cleanroom Implementation)
; Based on: Functional specifications only (SPECIFICATIONS.md)
; Reference: 8086 opcode reference only (8086_OPCODE_REFERENCE.md)
; 
; This is an independent implementation created without access to the 
; original IBM BIOS source code or disassembly.
; =============================================================================

BITS 16                         ; 16-bit real mode
ORG 0xE000                      ; BIOS starts at F000:E000

; =============================================================================
; CONSTANTS
; =============================================================================

; Hardware I/O Ports
PORT_PIC_CMD        equ 0x20    ; 8259 PIC command
PORT_PIC_DATA       equ 0x21    ; 8259 PIC data
PORT_PIT_CH0        equ 0x40    ; 8253 PIT channel 0
PORT_PIT_CMD        equ 0x43    ; 8253 PIT command
PORT_PPI_PORTA      equ 0x60    ; 8255 PPI port A (keyboard)
PORT_PPI_PORTB      equ 0x61    ; 8255 PPI port B (system control)
PORT_PPI_PORTC      equ 0x62    ; 8255 PPI port C
PORT_PPI_CMD        equ 0x63    ; 8255 PPI command
PORT_DMA_PAGE       equ 0x83    ; DMA page register
PORT_CRTC_ADDR      equ 0x3D4   ; CRT controller address (CGA)
PORT_CRTC_DATA      equ 0x3D5   ; CRT controller data
PORT_CGA_MODE       equ 0x3D8   ; CGA mode control
PORT_CGA_COLOR      equ 0x3D9   ; CGA color select

; BIOS Data Area (BDA) offsets
BDA_SEGMENT         equ 0x0040
BDA_EQUIP_WORD      equ 0x0010  ; Equipment word
BDA_MEM_SIZE        equ 0x0013  ; Memory size in KB
BDA_KBD_FLAGS       equ 0x0017  ; Keyboard shift flags
BDA_KBD_BUFFER      equ 0x001E  ; Keyboard buffer (32 bytes)
BDA_VID_MODE        equ 0x0049  ; Current video mode
BDA_VID_COLS        equ 0x004A  ; Number of screen columns
BDA_VID_PAGE_SIZE   equ 0x004C  ; Video page size
BDA_VID_PAGE_OFF    equ 0x004E  ; Current page offset
BDA_CURSOR_POS      equ 0x0050  ; Cursor positions (8 pages)
BDA_CURSOR_SHAPE    equ 0x0060  ; Cursor shape
BDA_VID_PAGE        equ 0x0062  ; Active video page
BDA_CRTC_BASE       equ 0x0063  ; CRTC base port
BDA_TIMER_TICKS     equ 0x006C  ; Timer tick counter (dword)

; Video RAM
VRAM_TEXT_COLOR     equ 0xB800  ; Color text mode video RAM
VRAM_TEXT_MONO      equ 0xB000  ; Monochrome text mode video RAM

; =============================================================================
; RESET VECTOR AND ENTRY POINT
; =============================================================================

section .text

; This is where POST begins (jumped to from reset vector)
post_start:
    cli                         ; Disable interrupts during POST
    cld                         ; Clear direction flag (forward strings)
    
    ; Set up segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x0400              ; Stack below BDA

; =============================================================================
; POST: CPU TESTS
; =============================================================================

cpu_test:
    ; Test CPU flags register
    ; Set each flag and verify it can be read back
    
    ; Test carry flag
    stc                         ; Set carry
    jnc cpu_test_failed         ; Should be set
    clc                         ; Clear carry
    jc cpu_test_failed          ; Should be clear
    
    ; Test zero flag
    xor ax, ax                  ; Should set ZF
    jnz cpu_test_failed
    or ax, 1                    ; Should clear ZF
    jz cpu_test_failed
    
    ; CPU test passed
    jmp cpu_test_done

cpu_test_failed:
    hlt                         ; Halt on CPU test failure

cpu_test_done:

; =============================================================================
; POST: HARDWARE INITIALIZATION
; =============================================================================

hardware_init:
    ; Initialize 8255 PPI
    mov al, 0x99
    out PORT_PPI_CMD, al        ; Set PPI mode
    
    mov al, 0xFC
    out PORT_PPI_PORTB, al      ; Disable speaker, enable keyboard
    
    ; Clear DMA
    xor al, al
    out 0xA0, al                ; Clear DMA page register
    out PORT_DMA_PAGE, al       ; Clear DMA channel 0 page

; =============================================================================
; POST: MEMORY TEST
; =============================================================================

memory_test:
    ; Test first 16KB of RAM (critical for operation)
    mov ax, 0x0000
    mov es, ax
    mov di, 0x0500              ; Start after interrupt vectors and BDA
    mov cx, 0x3B00              ; Test ~15KB
    mov al, 0x55                ; Test pattern
    
.write_loop:
    mov [es:di], al
    inc di
    loop .write_loop
    
    ; Verify
    mov di, 0x0500
    mov cx, 0x3B00
    
.verify_loop:
    cmp byte [es:di], 0x55
    jne memory_test_failed
    inc di
    loop .verify_loop
    
    ; Determine total memory (scan in 16KB blocks up to 640KB)
    mov ax, 16                  ; Start at 16KB
    mov bx, 0x1000              ; Segment for 64KB
    
.mem_scan:
    cmp ax, 640                 ; Max 640KB
    jae .mem_done
    
    mov es, bx
    mov di, 0
    mov byte [es:di], 0xAA      ; Try to write
    cmp byte [es:di], 0xAA      ; Check if readable
    jne .mem_done               ; No more memory
    
    add ax, 16                  ; Next 16KB block
    add bx, 0x0400              ; Next segment (16KB)
    jmp .mem_scan
    
.mem_done:
    ; Store memory size in BDA
    push ds
    mov bx, BDA_SEGMENT
    mov ds, bx
    mov [BDA_MEM_SIZE], ax
    pop ds
    jmp memory_test_done

memory_test_failed:
    ; Display "PARITY CHECK 1" error (simplified - just halt for now)
    hlt

memory_test_done:

; =============================================================================
; POST: INTERRUPT VECTOR INITIALIZATION
; =============================================================================

int_vector_init:
    ; Set up interrupt vector table
    xor ax, ax
    mov es, ax
    
    ; INT 10h - Video Services
    mov word [es:0x0040], int10_handler
    mov word [es:0x0042], 0xF000
    
    ; INT 11h - Equipment Check
    mov word [es:0x0044], int11_handler
    mov word [es:0x0046], 0xF000
    
    ; INT 12h - Memory Size
    mov word [es:0x0048], int12_handler
    mov word [es:0x004A], 0xF000
    
    ; INT 13h - Disk Services
    mov word [es:0x004C], int13_handler
    mov word [es:0x004E], 0xF000
    
    ; INT 14h - Serial Communications
    mov word [es:0x0050], int14_handler
    mov word [es:0x0052], 0xF000
    
    ; INT 15h - System Services
    mov word [es:0x0054], int15_handler
    mov word [es:0x0056], 0xF000
    
    ; INT 16h - Keyboard Services
    mov word [es:0x0058], int16_handler
    mov word [es:0x005A], 0xF000
    
    ; INT 17h - Printer Services
    mov word [es:0x005C], int17_handler
    mov word [es:0x005E], 0xF000
    
    ; INT 19h - Bootstrap Loader
    mov word [es:0x0064], int19_handler
    mov word [es:0x0066], 0xF000

; =============================================================================
; POST: 8259 PIC INITIALIZATION
; =============================================================================

pic_init:
    ; Initialize 8259 Programmable Interrupt Controller
    mov al, 0x13                ; ICW1: edge triggered, cascade, ICW4
    out PORT_PIC_CMD, al
    
    mov al, 0x08                ; ICW2: map to INT 08h-0Fh
    out PORT_PIC_DATA, al
    
    mov al, 0x09                ; ICW4: 8086 mode, normal EOI
    out PORT_PIC_DATA, al
    
    mov al, 0xB8                ; OCW1: mask (enable timer, keyboard, floppy)
    out PORT_PIC_DATA, al

; =============================================================================
; POST: 8253 PIT INITIALIZATION
; =============================================================================

pit_init:
    ; Initialize 8253 Programmable Interval Timer
    ; Set channel 0 for 18.2Hz (system timer)
    mov al, 0x36                ; Channel 0, LSB then MSB, mode 3, binary
    out PORT_PIT_CMD, al
    
    xor al, al                  ; Divisor = 65536 (0x10000)
    out PORT_PIT_CH0, al        ; LSB = 0
    out PORT_PIT_CH0, al        ; MSB = 0

; =============================================================================
; POST: EQUIPMENT DETERMINATION
; =============================================================================

equipment_check:
    ; Build equipment word
    ; Bit 0: floppy present (assume yes)
    ; Bits 4-5: initial video mode (01 = 40x25 color, 10 = 80x25 color)
    ; Bits 14-15: number of printers (assume 1)
    
    mov ax, 0x4021              ; Floppy + 80x25 color video + 1 printer
    
    ; Store in BDA
    push ds
    mov bx, BDA_SEGMENT
    mov ds, bx
    mov [BDA_EQUIP_WORD], ax
    pop ds

; =============================================================================
; POST: VIDEO INITIALIZATION
; =============================================================================

video_init:
    ; Initialize video to 80x25 color text mode (mode 3)
    mov ax, 0x0003              ; AH=0 (set mode), AL=3 (80x25 color)
    int 0x10                    ; Call our own video interrupt

; =============================================================================
; POST: KEYBOARD INITIALIZATION
; =============================================================================

keyboard_init:
    ; Initialize keyboard buffer
    push ds
    mov ax, BDA_SEGMENT
    mov ds, ax
    
    ; Clear keyboard flags
    mov byte [BDA_KBD_FLAGS], 0
    
    ; Initialize buffer pointers
    mov word [0x001A], BDA_KBD_BUFFER  ; Buffer head
    mov word [0x001C], BDA_KBD_BUFFER  ; Buffer tail
    
    pop ds

; =============================================================================
; POST: ENABLE INTERRUPTS
; =============================================================================

enable_interrupts:
    sti                         ; Enable interrupts

; =============================================================================
; POST: DISPLAY COPYRIGHT MESSAGE
; =============================================================================

display_copyright:
    ; Display copyright message
    mov si, copyright_msg
.loop:
    lodsb                       ; Load character from SI
    or al, al                   ; Check for null terminator
    jz .done
    mov ah, 0x0E                ; Teletype output
    mov bx, 0x0007              ; Page 0, white on black
    int 0x10
    jmp .loop
.done:

; =============================================================================
; POST: CALL BOOTSTRAP
; =============================================================================

call_bootstrap:
    int 0x19                    ; Call bootstrap loader
    ; Should not return, but if it does, halt
    hlt

; =============================================================================
; DATA
; =============================================================================

copyright_msg:
    db "Cleanroom BIOS - Compatible Implementation", 0x0D, 0x0A, 0

; =============================================================================
; INTERRUPT HANDLERS
; =============================================================================

; -----------------------------------------------------------------------------
; INT 10h - Video Services
; -----------------------------------------------------------------------------
int10_handler:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push ds
    
    cmp ah, 0x00                ; Set video mode?
    je int10_set_mode
    cmp ah, 0x02                ; Set cursor position?
    je int10_set_cursor
    cmp ah, 0x0E                ; Write teletype?
    je int10_teletype
    cmp ah, 0x0F                ; Get video mode?
    je int10_get_mode
    
    ; Unimplemented function
    jmp int10_done

int10_set_mode:
    ; Set video mode (AL = mode)
    ; For simplicity, only support mode 3 (80x25 color text)
    and al, 0x7F                ; Clear high bit
    cmp al, 0x03
    jne int10_done              ; Ignore other modes for now
    
    ; Initialize CRTC for 80x25 text mode
    ; (Simplified - full implementation would program all CRTC registers)
    
    ; Clear screen
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov cx, 2000                ; 80x25 = 2000 characters
    mov ax, 0x0720              ; Space with gray on black
.clear_loop:
    stosw
    loop .clear_loop
    
    ; Update BDA
    mov ax, BDA_SEGMENT
    mov ds, ax
    mov byte [BDA_VID_MODE], 0x03
    mov word [BDA_VID_COLS], 80
    mov word [BDA_CRTC_BASE], PORT_CRTC_ADDR
    
    jmp int10_done

int10_set_cursor:
    ; Set cursor position (DH=row, DL=col, BH=page)
    ; Store in BDA
    mov ax, BDA_SEGMENT
    mov ds, ax
    
    xor bh, bh                  ; Only support page 0 for now
    mov bl, bh
    shl bl, 1                   ; 2 bytes per page
    add bl, BDA_CURSOR_POS & 0xFF
    mov [bx], dx                ; Store position
    
    jmp int10_done

int10_teletype:
    ; Write character in teletype mode (AL=char, BH=page, BL=color)
    push ax
    
    ; Get current cursor position
    mov ax, BDA_SEGMENT
    mov ds, ax
    mov bx, BDA_CURSOR_POS
    mov dx, [bx]                ; DH=row, DL=col
    
    pop ax
    
    ; Check for special characters
    cmp al, 0x0D                ; Carriage return?
    je .carriage_return
    cmp al, 0x0A                ; Line feed?
    je .line_feed
    cmp al, 0x08                ; Backspace?
    je .backspace
    
    ; Regular character - write to screen
    push ax
    mov ax, 0xB800
    mov es, ax
    
    ; Calculate offset: (row * 80 + col) * 2
    mov al, dh                  ; row
    mov bl, 80
    mul bl                      ; AX = row * 80
    xor bh, bh
    mov bl, dl                  ; col
    add ax, bx                  ; AX = row * 80 + col
    shl ax, 1                   ; * 2 for attribute
    mov di, ax
    
    pop ax
    mov ah, 0x07                ; White on black
    stosw                       ; Write char and attribute
    
    ; Advance cursor
    inc dl                      ; Next column
    cmp dl, 80
    jl .update_cursor
    
    ; Wrap to next line
    xor dl, dl
    inc dh
    cmp dh, 25
    jl .update_cursor
    
    ; Scroll needed (simplified - just wrap to top)
    xor dh, dh
    jmp .update_cursor

.carriage_return:
    xor dl, dl                  ; Column = 0
    jmp .update_cursor

.line_feed:
    inc dh                      ; Next row
    cmp dh, 25
    jl .update_cursor
    xor dh, dh                  ; Wrap to top
    jmp .update_cursor

.backspace:
    or dl, dl                   ; Already at column 0?
    jz .update_cursor
    dec dl                      ; Move back one column
    jmp .update_cursor

.update_cursor:
    ; Save new cursor position
    mov ax, BDA_SEGMENT
    mov ds, ax
    mov bx, BDA_CURSOR_POS
    mov [bx], dx
    
    jmp int10_done

int10_get_mode:
    ; Get current video mode
    mov ax, BDA_SEGMENT
    mov ds, ax
    mov al, [BDA_VID_MODE]
    mov ah, [BDA_VID_COLS]
    mov bh, [BDA_VID_PAGE]
    
    ; Return in original registers
    mov [bp+10], ax             ; Update saved AX on stack
    mov byte [bp+6], bh         ; Update saved BX on stack
    jmp int10_done

int10_done:
    pop ds
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop bp
    iret

; -----------------------------------------------------------------------------
; INT 11h - Equipment Determination
; -----------------------------------------------------------------------------
int11_handler:
    push ds
    mov ax, BDA_SEGMENT
    mov ds, ax
    mov ax, [BDA_EQUIP_WORD]
    pop ds
    iret

; -----------------------------------------------------------------------------
; INT 12h - Memory Size Determination
; -----------------------------------------------------------------------------
int12_handler:
    push ds
    mov ax, BDA_SEGMENT
    mov ds, ax
    mov ax, [BDA_MEM_SIZE]
    pop ds
    iret

; -----------------------------------------------------------------------------
; INT 13h - Disk Services
; -----------------------------------------------------------------------------
int13_handler:
    ; Simplified disk handler - just return success for now
    cmp ah, 0x00                ; Reset?
    je .reset
    cmp ah, 0x02                ; Read sectors?
    je .read
    
    ; Unsupported function
    mov ah, 0x01                ; Invalid command
    stc                         ; Set carry for error
    iret

.reset:
    xor ah, ah                  ; Success
    clc                         ; Clear carry
    iret

.read:
    ; Simplified - just return success without reading
    ; Real implementation would use DMA and floppy controller
    mov ah, 0x00                ; Success
    clc                         ; Clear carry
    iret

; -----------------------------------------------------------------------------
; INT 14h - Serial Communications
; -----------------------------------------------------------------------------
int14_handler:
    ; Simplified serial handler
    xor ah, ah                  ; Return success status
    iret

; -----------------------------------------------------------------------------
; INT 15h - System Services
; -----------------------------------------------------------------------------
int15_handler:
    ; Minimal INT 15h support
    stc                         ; Most functions not supported
    iret

; -----------------------------------------------------------------------------
; INT 16h - Keyboard Services
; -----------------------------------------------------------------------------
int16_handler:
    push ds
    push bx
    
    mov bx, BDA_SEGMENT
    mov ds, bx
    
    cmp ah, 0x00                ; Read character?
    je .read_char
    cmp ah, 0x01                ; Check for keystroke?
    je .check_key
    cmp ah, 0x02                ; Get shift status?
    je .get_shift
    
    ; Unsupported function
    pop bx
    pop ds
    iret

.read_char:
    ; Wait for key in buffer (simplified - just return dummy key)
    mov ax, 0x001C              ; Return space bar scan code
    pop bx
    pop ds
    iret

.check_key:
    ; Check if key available (simplified - always return no key)
    pop bx
    pop ds
    pushf                       ; Save flags
    push ax
    mov ax, [bp-2]              ; Get flags from stack
    or ax, 0x0040               ; Set ZF (no key available)
    mov [bp-2], ax
    pop ax
    popf
    iret

.get_shift:
    mov al, [BDA_KBD_FLAGS]
    pop bx
    pop ds
    iret

; -----------------------------------------------------------------------------
; INT 17h - Printer Services
; -----------------------------------------------------------------------------
int17_handler:
    ; Simplified printer handler
    mov ah, 0x90                ; Return "ready" status
    iret

; -----------------------------------------------------------------------------
; INT 19h - Bootstrap Loader
; -----------------------------------------------------------------------------
int19_handler:
    ; Bootstrap loader - attempt to load boot sector
    ; Simplified - just halt (would normally read from disk)
    
    ; In a full implementation:
    ; 1. Reset disk system (INT 13h, AH=00h)
    ; 2. Read sector (track 0, head 0, sector 1) to 0x0000:0x7C00
    ; 3. Check for 0x55AA signature
    ; 4. Jump to 0x0000:0x7C00 if valid
    ; 5. Call INT 18h if no bootable disk
    
    cli
    hlt

; =============================================================================
; PADDING AND RESET VECTOR
; =============================================================================

; Pad to fill ROM space up to 0xFFF0
times 0x1FF0-($-$$) db 0xFF

; Reset vector at 0xFFF0
reset_vector:
    jmp 0xF000:post_start       ; Far jump to POST start

; BIOS date
bios_date:
    db "12/28/24"                ; Our implementation date

; Padding and checksum
times 0x1FFF-($-$$) db 0xFF
db 0x00                         ; Checksum byte
