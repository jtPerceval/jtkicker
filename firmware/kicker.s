; INTSHOW test
; Starts up the board correctly, handling the watchdog
; counts the number of frames
; and produces a table with the value read
; from $200 at each NMI interrupt. There are
; 8 NMI interrupts per frame

IOW  equ $0
VCOL equ $3800
VRAM equ $3C00
PAL  equ $1800
SCR  equ $2000
VDMP equ $0200
WDOG equ $0100
ATTR equ $3

; RAM variables
FCNT equ $3200      ; frame counter
NCNT equ $3202      ; NMI counter
VRD  equ $3203      ; value read from $200 (VDMP), INTSHOW in schematics

ORCC equ $1A

    org $C000
RESET:
    dc.b ORCC,$50
    CLR IOW

    LDS #$3400
    LDA #$10    ; BLANK
    LDU #WDOG
    LDX #VCOL
    LDY #$1000
clr_vram:
    STA ,X+
    CLR ,U      ; watchdog
    LEAY ,-Y
    BNE clr_vram

    LDA #1
    STA PAL
    ANDCC #$AF
    LDA #6
    STA IOW

    LDX #str_jotego
    LDY #(VRAM+$210)       ; Middle of the screen
    BSR PRINT

END:
    CLR WDOG
    BRA END

PRINT:
    LDB #ATTR
.loop:
    LDA ,X+
    BEQ PRINT_RET
    SUBA #$30
    STA ,Y
    STB -$400,Y
    LEAY -$20,Y
    BRA .loop
PRINT_RET:
    RTS

PRINTHEX16:
    BSR PRINTHEX8
    LEAX 1,X
    BSR PRINTHEX8
    RTS

PRINTHEX8:
    LDB #ATTR
    LDA ,X
    LSRA
    LSRA
    LSRA
    LSRA
    CMPA #$A
    BCS .belowA
    ADDA #7
.belowA:
    STA ,Y
    STB -$400,Y
    LDA ,X
    ANDA #$F
    CMPA #$A
    BCS .belowA2
    ADDA #7
.belowA2:
    STA -$20,Y
    STB -$420,Y
    LEAY -$40,Y
    RTS

SWI: RTI
NMI:
    CLR ,U  ; watchdog
    LDA VDMP
    STA VRD
    LDA NCNT
    INCA
    STA NCNT
    LDY #(VRAM+$250)
    LEAY A,Y
    LDX #NCNT
    BSR PRINTHEX8
    LEAY -$40,Y
    LDX #VRD
    BSR PRINTHEX8
    ; clears the interrupt latch
    LDA #4
    STA IOW
    LDA #6
    STA IOW
    RTI

IRQ:
    LDD FCNT
    ADDD #1
    STD FCNT
    LDX #FCNT
    LDY #(VRAM+$241)
    BSR PRINTHEX16
    ; Restart the NMI counter
    CLR NCNT
    ; clears the interrupt latch
    LDA #2
    STA IOW
    LDA #6
    STA IOW
    RTI
FIRQ:
    RTI

; Messages
str_jotego:
    dc.b "JOTEGO",0
PROGEND:
    cnop $10000-$C-PROGEND,1
    dc.w SWI,FIRQ,IRQ,SWI,NMI,RESET
    end
