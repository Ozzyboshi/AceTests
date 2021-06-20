	XDEF _ammxmainloop

	SECTION PROCESSING,CODE_F

	include "aprocessing/rasterizers/globaloptions.s"
	include "aprocessing/ammxmacros.i"
	include "aprocessing/matrix/matrix.s"
	include "aprocessing/trigtables.i"
	include "aprocessing/rasterizers/processingclearfunctions.s"
	include "aprocessing/rasterizers/point.s"
	include "aprocessing/rasterizers/square.s"
	include "aprocessing/rasterizers/triangle.s"
	include "aprocessing/rasterizers/processing_bitplanes_fast.s"
	include "aprocessing/rasterizers/processing_table_plotrefs.s"
	;include "aprocessing/rasterizers/processingclearfunctions.s"
	include "aprocessing/rasterizers/processingfill.s"

ANGLE:	dc.w 0

_ammxmainloop:
	move.l 4(sp),par1
	movem.l d0-d7/a0-a6,-(sp)	

	move.l par1,a0 ; argument address in a1 (bitplane 0 addr)
	move.l (a0)+,bitplane0
	move.l (a0),bitplane1

	PREPARESCREEN
	RESET_CURRENT_TRANSFORMATION_MATRIX_Q_10_6

	PUSHMATRIX

	move.w #240,d0
	move.w #128,d1
	bsr.w TRANSLATE
	addi.w #1,ANGLE
	cmp.w #359,ANGLE
	bls.s noresetanglew
	move.w #0,ANGLE
noresetanglew:
	
	ROTATE ANGLE


    ; Start of line 1
	move.l #-50,d0
	move.l #-50,d1
	move.l #100,d5

	STROKE #2

	bsr.w SQUARE ;#-5,#-5,#10

	POPMATRIX
	move.w #80,d0
	move.w #128,d1
	bsr.w TRANSLATE
	ROTATE ANGLE

	move.w #0,d0
	move.w #-50,d1

	move.w #-50,d6
	move.w #50,d3

	move.w #50,d4
	move.w #50,d5

	STROKE #1
	bsr.w TRIANGLE
	
	movem.l (sp)+,d0-d7/a0-a6
	rts
par1:
    dc.l 0
bitplane0:
	dc.l 0
bitplane1:
	dc.l 0

