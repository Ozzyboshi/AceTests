                  XDEF                                          _ammxmainloop
                  XDEF                                          _ammxmainloop2
                  XDEF                                          _ammxmainloop3


                  SECTION                                       PROCESSING,CODE_F

                  include                                       "aprocessing/rasterizers/globaloptions.s"
                  include                                       "aprocessing/ammxmacros.i"
                  include                                       "aprocessing/matrix/matrix.s"
                  include                                       "aprocessing/matrix/scale.s"
                  include                                       "aprocessing/matrix/shear.s"
                  include                                       "aprocessing/trigtables.i"
                  include                                       "aprocessing/rasterizers/processingclearfunctions.s"
                  include                                       "aprocessing/rasterizers/3dglobals.i"
                  include                                       "aprocessing/rasterizers/point.s"
                  include                                       "aprocessing/rasterizers/square.s"
                  include                                       "aprocessing/rasterizers/triangle.s"
                  include                                       "aprocessing/rasterizers/triangle3d.s"
                  include                                       "aprocessing/rasterizers/rectangle.s"
                  include                                       "aprocessing/rasterizers/circle.s"
                  include                                       "aprocessing/rasterizers/line.s"
                  include                                       "aprocessing/rasterizers/processing_bitplanes_fast.s"
                  include                                       "aprocessing/rasterizers/processing_table_plotrefs.s"
	;include "aprocessing/rasterizers/processingclearfunctions.s"
                  include                                       "aprocessing/rasterizers/processingfill.s"
                  include                                       "aprocessing/rasterizers/clipping.s"

ANGLE:            dc.w                                          0
ANGLE2:           dc.w                                          0
SCALEX:           dc.w                                          0
SCALEY:           dc.w                                          0
SCALEDIRECTIONX:  dc.w                                          1
SCALEDIRECTIONY:  dc.w                                          1

_ammxmainloop:
                  move.l                                        4(sp),par1
                  movem.l                                       d0-d7/a0-a6,-(sp)	

                  IFD                                           VAMPIRE
                  move.w                                        $00FF,$dff180
                  ENDIF

                  move.l                                        par1,a0                                                  ; argument address in a1 (bitplane 0 addr)
                  move.l                                        (a0)+,bitplane0
                  move.l                                        (a0),bitplane1

                  PREPARESCREEN
                 ; RESET_CURRENT_TRANSFORMATION_MATRIX_Q_10_6
                 ; STROKE                                        #2

                  ;ENABLE_CLIPPING

                  ;LINE                                          #319,#0-5,#319-5,#0+5
                  ;LINE                                          #319,#0-5,#319+5,#0+5
                  ;LINE                                          #319-5,#0+5,#319+5,#0+5


  ;                DISABLE_CLIPPING

                  bsr.w                                         ammx_fill_table_clip

                     ; Start of triangle rotating around 0,0
                  RESET_CURRENT_TRANSFORMATION_MATRIX_Q_10_6
                  ENABLE_CLIPPING
                  STROKE                                        #2

                  ROTATE                                        ANGLE
                  move.w                                        #160,d0
                  move.w                                        #128,d1
                  jsr                                         TRANSLATE

                 
                  ROTATE                                        ANGLE2
                  move.w                                        #0,d0
                  move.w                                        #0,d1
                  jsr                                         TRANSLATE


                  move.w                                        #0,d0
                  move.w                                        #-5,d1

                  move.w                                        #-5,d6
                  move.w                                        #5,d3

                  move.w                                        #5,d4
                  move.w                                        #5,d5
                  

                  bsr.w                                         TRIANGLE

                  STROKE                                        #1

                 

	
                  ;bsr.w                                         TRIANGLE


                  move.w                                        #0-10,d0
                  move.w                                        #0-10,d1
                  move.w                                        #20,d5

                  bsr.w                                         SQUARE      
                  DISABLE_CLIPPING
                  
               


                  STROKE                                        #2


                  RESET_CURRENT_TRANSFORMATION_MATRIX_Q_10_6

                  move.w                                        #160,d0
                  move.w                                        #128,d1
                  jsr                                           TRANSLATE
                  ROTATE                                        ANGLE

                  move.w                                        #0,d0
                  move.w                                        #0,d1

                  move.w                                        #45,d2

                  bsr.w                                         CIRCLE

                  STROKE                                        #1
                  move.w                                        #-15,d0
                  move.w                                        #-15,d1
                  move.w                                        #30,d5

                  bsr.w                                         SQUARE  

                  STROKE                                        #1

                  

                  RESET_CURRENT_TRANSFORMATION_MATRIX_Q_10_6

                  PUSHMATRIX

                  move.w                                        #240,d0
                  move.w                                        #128,d1
                  jsr                                           TRANSLATE
                  addi.w                                        #1,ANGLE
                  cmp.w                                         #359,ANGLE
                  bls.s                                         noresetanglew
                  move.w                                        #0,ANGLE
noresetanglew:


                  addi.w                                        #2,ANGLE2
                  cmp.w                                         #359,ANGLE2
                  bls.s                                         noresetanglew2
                  move.w                                        #0,ANGLE2
noresetanglew2:

	
                  ROTATE                                        ANGLE


	;move.l #-50,d0
	;move.l #-50,d1
	;move.l #100,d5

                  STROKE                                        #2

	;bsr.w SQUARE ;#-5,#-5,#10
   

                  move.w                                        #-5,d0
                  move.w                                        #-10,d1

                  move.w                                        #10,d5
                  move.w                                        #20,d6

                  bsr.w                                         RECT

                  POPMATRIX
                  
                  move.w                                        #80,d0
                  move.w                                        #128,d1
                  jsr                                           TRANSLATE

	; start scaling
                  move.w                                        SCALEX,d0
                  move.w                                        SCALEY,d1
                  add.w                                         SCALEDIRECTIONX,d0
                  add.w                                         SCALEDIRECTIONY,d1
	
                  cmp.w                                         #0,d0
                  bne.s                                         resetx2
                  move.w                                        #1,SCALEDIRECTIONX
resetx2
                  cmp.w                                         #%0000000001000000,d0
                  bne.s                                         resetx
	;moveq #0,d0
	;neg.w SCALEDIRECTIONX
                  move.w                                        #-1,SCALEDIRECTIONX
resetx:

                  cmp.w                                         #0,d1
                  bne.s                                         resety2
                  move.w                                        #1,SCALEDIRECTIONY
resety2:
                  cmp.w                                         #%0000000001000000,d1
                  bne.s                                         resety
	;moveq #0,d1
	;neg.w d1
                  move.w                                        #-1,SCALEDIRECTIONY
resety
                  move.w                                        d0,SCALEX
                  move.w                                        d1,SCALEY
	;moveq #0,d1
                  JSR                                           SCALE
	;end scaling

                  move.w                                        SCALEX,d0
                  move.w                                        SCALEY,d1
                  lsr.w                                         #2,d0
                  lsr.w                                         #2,d1
                  jsr                                           SHEAR

	

                  ROTATE                                        ANGLE

                  move.w                                        #0,d0
                  move.w                                        #-50,d1

                  move.w                                        #-50,d6
                  move.w                                        #50,d3

                  move.w                                        #50,d4
                  move.w                                        #50,d5

                  STROKE                                        #1
                  bsr.w                                         TRIANGLE




               
	
                  movem.l                                       (sp)+,d0-d7/a0-a6
                  rts

_ammxmainloop2:
                  move.l                                        4(sp),par1
                  movem.l                                       d0-d7/a0-a6,-(sp)	

                  IFD                                           VAMPIRE
                  move.w                                        $00FF,$dff180
                  ENDIF

                  move.l                                        par1,a0                                                  ; argument address in a1 (bitplane 0 addr)
                  move.l                                        (a0)+,bitplane0
                  move.l                                        (a0),bitplane1

                  PREPARESCREEN

                  CLEARFASTBITPLANES                                                                                     ; Clear fast bitplanes
                  RESETFILLTABLE
                  LOADIDENTITY

                  sub.w #1,ZCOORD
                  cmp.w #-235,ZCOORD
                  bne.s znoreset
                  move.w #0,ZCOORD

znoreset:

                  VERTEX_INIT                                   1,#0,#-5,#0
                  VERTEX_INIT                                   2,#10,#10,ZCOORD
                  VERTEX_INIT                                   3,#-10,#10,#0

                  bsr.w                                         TRIANGLE3D
                  movem.l                                       (sp)+,d0-d7/a0-a6
                  rts
ZCOORD:
   dc.w 0

_ammxmainloop3:
                  move.l                                        4(sp),par1
                  movem.l                                       d0-d7/a0-a6,-(sp)	
                  ENABLE_CLIPPING
                  

                  IFD                                           VAMPIRE
                  move.w                                        $00FF,$dff180
                  ELSE
                  move.w                                        $00F0,$dff180
                  ENDIF

                  move.l                                        par1,a0                                                  ; argument address in a1 (bitplane 0 addr)
                  move.l                                        (a0)+,bitplane0
                  move.l                                        (a0),bitplane1

                  ;PREPARESCREEN

                  ;CLEARFASTBITPLANES   
                                                                                          ; Clear fast bitplanes
                  COPYBITPLANESANDCLEAR
                       
                  RESETFILLTABLE
                  LOADIDENTITY
                  

                  move.w                                        #160,d0
                  move.w                                        #128,d1
                  ;jsr                                           TRANSLATE

                  add.w #1,ZCOORD
                  cmp.w #360,ZCOORD
                  bne.s znoreset2
                  move.w #0,ZCOORD

znoreset2:

                   ROTATE_X_INV_Q_5_11                                        ZCOORD
                  STROKE                                        #1


                  ;move.w                                        #160,d0
                  ;move.w                                        #128,d1
                  ;jsr                                           TRANSLATE

                  ;move.w                                        #0,d0
                  ;move.w                                        #-50,d1

                  ;move.w                                        #-50,d6
                  ;move.w                                        #50,d3

                  ;move.w                                        #50,d4
                  ;move.w                                        #50,d5
                  VERTEX_INIT           1,#0,#-50,#0
                  VERTEX_INIT           2,#50,#50,#0
                  VERTEX_INIT           3,#-50,#50,#0

                  bsr.w                 TRIANGLE3D

                  VERTEX_INIT           1,#0,#50,#0
                  VERTEX_INIT           2,#50,#-50,#0
                  VERTEX_INIT           3,#-50,#-50,#0
                  STROKE                                        #2
                  
                  bsr.w                 TRIANGLE3D

                  ;bsr.w                                         TRIANGLE
                  DISABLE_CLIPPING
                  movem.l                                       (sp)+,d0-d7/a0-a6
                  rts

par1:
                  dc.l                                          0
bitplane0:
                  dc.l                                          0
bitplane1:
                  dc.l                                          0

