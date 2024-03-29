; Fast bitplanes
; This bitplanes will be copied into chip ram by PREPARESCREEN MACRO

SCREEN_PTR_OTHER_0: dc.l SCREEN_00
SCREEN_PTR_OTHER_1: dc.l SCREEN_11

SCREEN_PTR_0: dc.l SCREEN_0
SCREEN_PTR_1: dc.l SCREEN_1

SCREEN_OFFSET: dc.l 40*256*2*-1

SWAP_BPL MACRO
    neg.l SCREEN_OFFSET
    move.l SCREEN_OFFSET,d1
    move.l SCREEN_PTR_0,SCREEN_PTR_OTHER_0
    move.l SCREEN_PTR_1,SCREEN_PTR_OTHER_1
    add.l d1,SCREEN_PTR_0
    add.l d1,SCREEN_PTR_1
    ENDM
	section	"CHIPDATA2",data_c

    IFD USE_VIDEOCHIP
    ;SECTION ".data_chip",data
    ENDIF

SCREEN_0
    dcb.b 40*256,$00

SCREEN_1
    dcb.b 40*256,$00

SCREEN_00
    dcb.b 40*256,$00

SCREEN_11
    dcb.b 40*256,$00


processing_bitplanes_fast_screen0:
	move.l #SCREEN_0,d0
	rts
