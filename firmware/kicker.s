VRAM equ $2000


    org $8000
reset:
    LDX #VRAM
    LDY #$800
    CLRA
clr_vram:
    CLR ,X+
    LEAY ,-Y
    BNE clr_vram
END: BRA END

    cnop $7ffe,1
    dc.w $8000
    end
