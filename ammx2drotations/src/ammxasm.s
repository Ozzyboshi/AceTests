	XDEF _ammxmainloop

	SECTION PROCESSING,CODE_F

	include "aprocessing/rasterizers/globaloptions.s"
	include "aprocessing/ammxmacros.i"
	include "aprocessing/matrix/matrix.s"
	include "aprocessing/matrix/scale.s"
	include "aprocessing/matrix/shear.s"
	include "aprocessing/trigtables.i"
	include "aprocessing/rasterizers/processingclearfunctions.s"
	include "aprocessing/rasterizers/point.s"
	include "aprocessing/rasterizers/square.s"
	include "aprocessing/rasterizers/triangle.s"
	include "aprocessing/rasterizers/rectangle.s"
	include "aprocessing/rasterizers/circle.s"
	include "aprocessing/rasterizers/processing_bitplanes_fast.s"
	include "aprocessing/rasterizers/processing_table_plotrefs.s"
	;include "aprocessing/rasterizers/processingclearfunctions.s"
	include "aprocessing/rasterizers/processingfill.s"

ANGLE:	dc.w 0
SCALEX: dc.w 0
SCALEY: dc.w 0
SCALEDIRECTIONX: dc.w 1
SCALEDIRECTIONY: dc.w 1

_ammxmainloop:
	move.l 4(sp),par1
	movem.l d0-d7/a0-a6,-(sp)	

	IFD VAMPIRE
	move.w $00FF,$dff180
	ENDIF

	move.l par1,a0 ; argument address in a1 (bitplane 0 addr)
	move.l (a0)+,bitplane0
	move.l (a0),bitplane1

	PREPARESCREEN
	RESET_CURRENT_TRANSFORMATION_MATRIX_Q_10_6
	STROKE #2
	move.w                                        #160,d0
  move.w                                        #128,d1
  bsr.w                                         TRANSLATE

  move.w                                        #0,d0
  move.w                                        #0,d1

  move.w                                        #45,d2

  bsr.w                                         CIRCLE

	STROKE #1
  move.w                                        #-15,d0
  move.w                                        #-15,d1
  move.w                                        #30,d5

  bsr.w                                         SQUARE  

  STROKE #1

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


	;move.l #-50,d0
	;move.l #-50,d1
	;move.l #100,d5

	STROKE #2

	;bsr.w SQUARE ;#-5,#-5,#10

	move.w #-5,d0
	move.w #-10,d1

	move.w #10,d5
	move.w #20,d6

	bsr.w RECT

	POPMATRIX
	move.w #80,d0
	move.w #128,d1
	bsr.w TRANSLATE

	; start scaling
	move.w SCALEX,d0
	move.w SCALEY,d1
	add.w SCALEDIRECTIONX,d0
	add.w SCALEDIRECTIONY,d1
	
	cmp.w #0,d0
	bne.s resetx2
	move.w #1,SCALEDIRECTIONX
resetx2
	cmp.w #%0000000001000000,d0
	bne.s resetx
	;moveq #0,d0
	;neg.w SCALEDIRECTIONX
	move.w #-1,SCALEDIRECTIONX
resetx:

	cmp.w #0,d1
	bne.s resety2
	move.w #1,SCALEDIRECTIONY
resety2:
	cmp.w #%0000000001000000,d1
	bne.s resety
	;moveq #0,d1
	;neg.w d1
	move.w #-1,SCALEDIRECTIONY
resety
	move.w d0,SCALEX
	move.w d1,SCALEY
	;moveq #0,d1
	bsr.w SCALE
	;end scaling

	move.w SCALEX,d0
	move.w SCALEY,d1
	lsr.w #2,d0
	lsr.w #2,d1
	bsr.w SHEAR

	

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

