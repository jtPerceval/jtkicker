IOW  equ $0
VCOL equ $3800
VRAM equ $3C00
PAL  equ $1800
SCR  equ $2000
VDMP equ $0200
WDOG equ $0100

FCNT equ $3200

ORCC equ $1A

    org $C000
RESET:
    dc.b ORCC,$50
    LDA #1
    STA IOW

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
    LDA #7
    STA IOW

    LDX #str_jotego
    LDY #(VRAM+$210)       ; Middle of the screen
    BSR PRINT

END:
    CLR WDOG
    BRA END

PRINT:
    LDA ,X+
    BEQ PRINT_RET
    SUBA #$30
    STA ,Y
    LEAY -$20,Y
    BRA PRINT
PRINT_RET:
    RTS

PRINTHEX16:
    BSR PRINTHEX8
    LEAX 1,X
    BSR PRINTHEX8
    RTS

PRINTHEX8:
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
    LDA ,X
    ANDA #$F
    CMPA #$A
    BCS .belowA2
    ADDA #7
.belowA2:
    STA -$20,Y
    LEAY -$40,Y
    RTS

SWI: RTI
NMI:
    CLR ,U  ; watchdog
    LDA #5
    STA IOW
    LDA #7
    STA IOW
    RTI
IRQ:
    LDD FCNT
    ADDD #1
    STD FCNT
    LDX #FCNT
    LDY #(VRAM+$241)
    BSR PRINTHEX16
    LDA #3
    STA IOW
    LDA #7
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
