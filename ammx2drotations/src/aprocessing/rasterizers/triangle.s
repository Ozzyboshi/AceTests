

RESETFILLTABLE_FN:
    movem.l d0-d7/a0-a1,-(sp)
	move.l #255,d3
	lea FILL_TABLE,a0
.resetfilltableclearlinefn:
	move.l #$FFFFFFFF,(a0)+
	dbra d3,.resetfilltableclearlinefn
    movem.l (sp)+,d0-d7/a0-a1
    rts

; first point d0,d1
; second point d6,d3
; third point d4,d5
SAVEDX: dc.w 0
SAVEDY: dc.w 0
TRIANGLE:
    movem.l d0-d7/a0-a1,-(sp)
    ;bsr.w RESETFILLTABLE_FN

    move.w d0,SAVEDX
    move.w d1,SAVEDY
    POINT_TRANSFORM_AND_STORE_IN_FILLTABLE_FIRST d0,d1,0
    POINT_TRANSFORM_AND_STORE_IN_FILLTABLE d6,d3,4
    bsr.w ammxlinefill
    
    ;move.w SAVEDX,d0
    ;move.w SAVEDY,d1
    ;POINT_TRANSFORM_AND_STORE_IN_FILLTABLE_FIRST d0,d1,0
    POINT_TRANSFORM_AND_STORE_IN_FILLTABLE d4,d5,4
    bsr.w ammxlinefill
    
    POINT_TRANSFORM_AND_STORE_IN_FILLTABLE d6,d3,0
    POINT_TRANSFORM_AND_STORE_IN_FILLTABLE d4,d5,4
    bsr.w ammxlinefill
    
    bsr.w ammx_fill_table

    movem.l (sp)+,d0-d7/a0-a1
    rts

