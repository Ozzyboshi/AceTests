	XDEF _ammxmainloop

	SECTION PROCESSING,CODE_F

	include "aprocessing/rasterizers/globaloptions.s"
	include "aprocessing/ammxmacros.i"
	include "aprocessing/matrix/matrix.s"
	include "aprocessing/trigtables.i"
	include "aprocessing/rasterizers/processingclearfunctions.s"
	include "aprocessing/rasterizers/square.s"
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

	move.w #160,d0
	move.w #128,d1
	bsr.w TRANSLATE

	addi.w #1,ANGLE
	cmp.w #359,ANGLE
	bls.s noresetanglew
	move.w #0,ANGLE
noresetanglew:


	
	ROTATE ANGLE

	POINT #-5,#-5
	POINT #5,#-5
	POINT #-5,#5
	POINT #5,#5
	
    
    ; Start of line 1
	move.w #-50,d0
	move.w #-50,d1
	move.w #100,d5

	STROKE #3

	bsr.w SQUARE ;#-5,#-5,#10
	
	movem.l (sp)+,d0-d7/a0-a6
	rts
par1:
    dc.l 0
bitplane0:
	dc.l 0
bitplane1:
	dc.l 0

