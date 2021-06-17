	XDEF _ammxmainloop

	SECTION PROCESSING,CODE_F

	include "aprocessing/rasterizers/globaloptions.s"
	include "aprocessing/ammxmacros.i"
	include "aprocessing/matrix/matrix.s"
	include "aprocessing/trigtables.i"
	include "aprocessing/rasterizers/processingclearfunctions.s"
	;include "aprocessing/rasterizers/square.s"
	include "aprocessing/rasterizers/point.s"
	include "aprocessing/rasterizers/processing_bitplanes_fast.s"
	include "aprocessing/rasterizers/processing_table_plotrefs.s"
	;include "aprocessing/rasterizers/processingclearfunctions.s"
	include "aprocessing/rasterizers/processingfill.s"

ANGLE:	dc.w 0

_ammxmainloop:
	move.l 4(sp),par1
	movem.l d0-d7/a0-a6,-(sp)

	;CLEARFASTBITPLANES ; Clear fast bitplanes
	

	move.l par1,a0 ; argument address in a1 (bitplane 0 addr)
	move.l (a0)+,bitplane0
	move.l (a0),bitplane1

	PREPARESCREEN
	RESET_CURRENT_TRANSFORMATION_MATRIX_Q_10_6

	;move.w #160,d0
	;move.w #128,d1
	;bsr.w TRANSLATE

	;ROTATE_INV_Q_5_11 #45
	;ROTATE #45

	;POINT_Q_10_6 #-5*64,#-5*64

	;POINT_Q_10_6 #-5*64,#5*64

	;POINT_Q_10_6 #5*64,#-5*64

	;POINT_Q_10_6 #5*64,#5*64

	;POINT #5,#5
	;POINT #5,#5
	;POINT #5,#5
	;POINT #5,#5

	; start plot routine
	move.l #5,d0
	move.l #5,d1

	;RESET_CURRENT_TRANSFORMATION_MATRIX_Q_10_6
	
	LOAD_CURRENT_TRANSFORMATION_MATRIX OPERATOR2_TR_MATRIX_ROW1
	move.w #$0000,OPERATOR1_TR_MATRIX_ROW1
	asl.w #6,d0
	asl.w #6,d1
	move.w d0,OPERATOR1_TR_MATRIX_ROW1+2
	move.w d1,OPERATOR1_TR_MATRIX_ROW1+4
	move.w #$0040,OPERATOR1_TR_MATRIX_ROW1+6

	bsr.w ammxmatrixmul1X3_q10_6

	move.w OPERATOR3_TR_MATRIX_ROW1+2,d0
	move.w OPERATOR3_TR_MATRIX_ROW1+4,d1

	asr.l #6,d0
	asr.l #6,d1

	;moveq #5,d0
	;moveq #5,d1

	lea PLOTREFS,a1
	add.w d1,d1
	move.w 0(a1,d1.w),d1
	move.w d0,d4
	lsr.w #3,d4
	add.w d4,d1
	not.b d0
	lea SCREEN_0,a0
	bset d0,(a0,d1.w)

	;movem.l (sp)+,d0-d7/a0-a6
	;rts

	move.w #160,d0
	move.w #128,d1
	bsr.w TRANSLATE

	addi.w #1,ANGLE
	
	cmp.w #359,ANGLE
	bls.s noresetanglew
	move.w #0,ANGLE
noresetanglew:


	;ROTATE_INV_Q_5_11 ANGLE

	;POINT_Q_10_6 #-5*64,#-5*64

	;POINT_Q_10_6 #-5*64,#5*64

	;POINT_Q_10_6 #5*64,#-5*64

	;POINT_Q_10_6 #5*64,#5*64

	ROTATE ANGLE
	
	POINT #-5,#-5
	POINT #5,#-5
	POINT #-5,#5
	POINT #5,#5

	; fill the square
	RESETFILLTABLE
    lea LINEVERTEX_START_FINAL,a1
    
    ; Start of line 1
	move.w #-50,d0
	move.w #-50,d1
	move.w #100,d5
	
    move.w d0,d6
    move.w d1,d7

	bsr.w point_execute_transformation

    ; save transformed values
    move.w d0,(a1)+
    move.w d1,(a1)+

    ; first point Y is min and max
    move.w d1,AMMXFILLTABLE_CURRENT_ROW
    move.w d1,AMMXFILLTABLE_END_ROW

    ; restore first point
    move.w d6,d0
    move.w d7,d1
    ; add width
    add.w d5,d0
    bsr.w point_execute_transformation
    ; save transformed values
    move.w d0,(a1)+
    move.w d1,(a1)+

    MINUWORD d1,AMMXFILLTABLE_CURRENT_ROW
    MAXUWORD d1,AMMXFILLTABLE_END_ROW

    bsr.w ammxlinefill

	; Start of line 2
    lea LINEVERTEX_START_FINAL,a1
    addq #4,a1

    ; restore first point
    move.w d6,d0
    move.w d7,d1
    ; add height
    add.w d5,d1

    bsr.w point_execute_transformation
    ; save transformed values
    move.w d0,(a1)
    move.w d1,2(a1)
    MINUWORD d1,AMMXFILLTABLE_CURRENT_ROW
    MAXUWORD d1,AMMXFILLTABLE_END_ROW
    bsr.w ammxlinefill
    ; End of line 2

	; Start of line 3
    lea LINEVERTEX_START_FINAL,a1
    ; restore first point
    move.w d6,d0
    move.w d7,d1
    ; add height and width
    add.w d5,d0
    add.w d5,d1
    bsr.w point_execute_transformation
    ; save transformed values
    move.w d0,(a1)+
    move.w d1,(a1)+
    MINUWORD d1,AMMXFILLTABLE_CURRENT_ROW
    MAXUWORD d1,AMMXFILLTABLE_END_ROW
    bsr.w ammxlinefill
    ; ENd of line 3

    lea LINEVERTEX_START_FINAL,a1
    addq #4,a1
    ; restore first point
    move.w d6,d0
    move.w d7,d1
    ; add width
    add.w d5,d0
    bsr.w point_execute_transformation
    ; save transformed values
    move.w d0,(a1)+
    move.w d1,(a1)+
    MINUWORD d1,AMMXFILLTABLE_CURRENT_ROW
    MAXUWORD d1,AMMXFILLTABLE_END_ROW
    bsr.w ammxlinefill

	bsr.w ammx_fill_table

	;move.w #-5,d0
	;move.w #-5,d1
	;move.w #10,d5

	;bsr.w SQUARE ;#-5,#-5,#10

	
	
	
	movem.l (sp)+,d0-d7/a0-a6
	rts
par1:
    dc.l 0
bitplane0:
	dc.l 0
bitplane1:
	dc.l 0

