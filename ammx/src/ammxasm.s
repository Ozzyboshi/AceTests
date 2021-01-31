    XDEF _ammxmainloop:

DATAIN:
    dc.l $AAAAAAAA
    dc.l $BBBBBBBB
par1:
    dc.l 0

_ammxmainloop:
    move.l 4(sp),par1 ; bitplane poiner
	movem.l d0-d6/a0-a6,-(sp)
    move.l par1,a1

    lea DATAIN,A0
    LOAD    (A0),D1
    STORE   D1,(a1)
    
    movem.l (sp)+,d0-d6/a0-a6
    rts