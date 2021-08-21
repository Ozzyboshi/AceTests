DEBUG_COLORS=1;
                  include                                       "aprocessing/rasterizers/processing_bitplanes_fast.s"

                  XDEF                                          _ammxmainloop
                  XDEF                                          _ammxmainloop2
                  XDEF                                          _ammxmainloop3
                    XDEF                                          _ammxmainloop3_init

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
                  IFD                                           VAMPIRE
                  move.w                                        #$0F00,$dff180
                  ELSE
                  move.w                                        #$00F0,$dff180
                  ENDIF
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
                  jsr                                           TRANSLATE

                 
                  ROTATE                                        ANGLE2
                  move.w                                        #0,d0
                  move.w                                        #0,d1
                  jsr                                           TRANSLATE


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
                  move.w                                        #$0000,$dff180
                  rts

_ammxmainloop2:
                  IFD                                           VAMPIRE
                  move.w                                        #$0F00,$dff180
                  ELSE
                  move.w                                        #$00F0,$dff180
                  ENDIF
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

                  sub.w                                         #1,ZCOORD
                  cmp.w                                         #-235,ZCOORD
                  bne.s                                         znoreset
                  move.w                                        #0,ZCOORD

znoreset:

                  VERTEX_INIT                                   1,#0,#-5,#0
                  VERTEX_INIT                                   2,#10,#10,ZCOORD
                  VERTEX_INIT                                   3,#-10,#10,#0

                  bsr.w                                         TRIANGLE3D
                  move.w                                        #$0000,$dff180
                  movem.l                                       (sp)+,d0-d7/a0-a6
                  rts
ZCOORD:
                  dc.w                                          0

_ammxmainloop3_init:
                    move.l  #ammx_fill_table_end_noreset,AMMX_FILL_FUNCT_ADDR
                    LOADIDENTITY
                     VERTEX_INIT                                   1,#0,#-50,#0
                  VERTEX_INIT                                   2,#50,#50,#0
                  VERTEX_INIT                                   3,#-50,#50,#0

                  bsr.w                                         TRIANGLE3D
                    rts
_ammxmainloop3:
                  IFD DEBUG_COLORS
                  IFD                                           VAMPIRE
                  move.w                                        #$0F00,$dff180
                  ELSE
                  move.w                                        #$00F0,$dff180
                  ENDIF
                  ENDIF
;.loop; Wait for vblank
;                  move.l                                        $dff004,d0
;                  and.l                                         #$1ff00,d0
;                  cmp.l                                         #303<<8,d0
;                  bne.b                                         .loop

                  move.l                                        4(sp),par1
                  ;movem.l                                       d0-d7/a0-a6,-(sp)	
                  ;ENABLE_CLIPPING

                  

                 

                  move.l                                        par1,a0                                                  ; argument address in a1 (bitplane 0 addr)
                  move.l                                        (a0)+,bitplane0
                  move.l                                        (a0),bitplane1
            
                  ;move.l #SCREEN_0,par1

                  ;CLEARFASTBITPLANES   
                                                                                          ; Clear fast bitplanes
                  ;COPYBITPLANESANDCLEAR

                  ;PREPARESCREEN
                  ;move.l                                        #5*255,d3
                  ;move.l                                        SCREEN_PTR_0,a4
                  ;move.l                                        SCREEN_PTR_1,a4
                  ;CLEARFASTBITPLANES   
                  IFD DEBUG_COLORS
                  move.w                                        #$00FF,$dff180
                  ENDIF
                  IFD PESANTE    
                  jsr F_PREPARESCREEN  
                  RESETFILLYVALS
                  ENDIF

                     IFD DEBUG_COLORS
                  IFD                                           VAMPIRE
                  move.w                                        #$0F00,$dff180
                  ELSE
                  move.w                                        #$00F0,$dff180
                  ENDIF
                  ENDIF
                  ;RESETFILLTABLE

    IFD PESANTE                  
                  LOADIDENTITY
                  add.w                                         #1,ZCOORD
                  cmp.w                                         #360,ZCOORD
                  bne.s                                         znoreset2
                  move.w                                        #0,ZCOORD

znoreset2:

                  ROTATE_X_INV_Q_5_11                           ZCOORD
    ENDIF
                  STROKE                                        #1
    IFD PESANTE    
                  VERTEX_INIT                                   1,#0,#-50,#0
                  VERTEX_INIT                                   2,#50,#50,#0
                  VERTEX_INIT                                   3,#-50,#50,#0

                  bsr.w                                         TRIANGLE3D

                  VERTEX_INIT                                   1,#0,#50,#0
                  VERTEX_INIT                                   2,#50,#-50,#0
                  VERTEX_INIT                                   3,#-50,#-50,#0
                  STROKE                                        #2
    ENDIF   
                  ;bsr.w                                         TRIANGLE3D

                  ;SWAP_BPL 


                  ;DISABLE_CLIPPING
                  ;movem.l                                       (sp)+,d0-d7/a0-a6
                  ;move.l                                        SCREEN_PTR,d0
                  IFD DEBUG_COLORS
                  move.w                                        #$0FF0,$dff180
                  ENDIF

;.loopend ; Wait to exit vblank row (for faster processors like 68040)
;                  move.l                                        $dff004,d0
;                  and.l                                         #$1ff00,d0
;                  cmp.l                                         #303<<8,d0
;                  beq.b                                         .loopend
                   ; move.w #255,AMMXFILLTABLE_END_ROW
                   ; move.w #10,AMMX_FILL_TABLE_FIRST_DRAW

                    jsr ammx_fill_table
                     IFD DEBUG_COLORS
                  move.w                                        #$0000,$dff180
                  ENDIF
                  rts

par1:
                  dc.l                                          0
bitplane0:
                  dc.l                                          0
bitplane1:
                  dc.l                                          0


F_PREPARESCREEN:
	movem.l d0/d1/d2/d3/a0-a4,-(sp) ; stack save

	;move.w #0+80,AMMXFILLTABLE_CURRENT_ROW
	;move.w #255-80,AMMXFILLTABLE_END_ROW

	add.w #7,FILLTABLE_FRAME_MAX_Y

	move.w FILLTABLE_FRAME_MIN_Y,d1
	;subq #4,d1
	move.w FILLTABLE_FRAME_MAX_Y,d3
	;addq #4,d3

	sub.w d1,d3
	;subq #1,d2
	;move.w d2,d3

	move.l SCREEN_PTR_0,a0
	move.l SCREEN_PTR_1,a4
	move.l bitplane0,a1
	move.l bitplane1,a2

	muls.w #40,d1
	add.w d1,a0
	add.w d1,a4 
	add.w d1,a1
	add.w d1,a2 

	; copy from fast bitplanes to slow bitplanes
	IFD VAMPIRE
    ;move.l #1279,d3
	load #0,e0
    ENDIF
    IFND VAMPIRE
	moveq #0,d0
    ;move.l #256-1,d3
    ENDIF
	
	
	
.preparescreenclearline:
	IFD VAMPIRE
	load (a0),e20
	load (a4),e21
	store e20,(a1)+
	store e21,(a2)+
	store e0,(a0)+
	store e0,(a4)+

	load (a0),e20
	load (a4),e21
	store e20,(a1)+
	store e21,(a2)+
	store e0,(a0)+
	store e0,(a4)+

	load (a0),e20
	load (a4),e21
	store e20,(a1)+
	store e21,(a2)+
	store e0,(a0)+
	store e0,(a4)+

	load (a0),e20
	load (a4),e21
	store e20,(a1)+
	store e21,(a2)+
	store e0,(a0)+
	store e0,(a4)+

	load (a0),e20
	load (a4),e21
	store e20,(a1)+
	store e21,(a2)+
	store e0,(a0)+
	store e0,(a4)+
	ELSE
	move.l (a0),(a1)+
	move.l (a4),(a2)+
	move.l d0,(a0)+
	move.l d0,(a4)+

	move.l (a0),(a1)+
	move.l (a4),(a2)+
	move.l d0,(a0)+
	move.l d0,(a4)+

	move.l (a0),(a1)+
	move.l (a4),(a2)+
	move.l d0,(a0)+
	move.l d0,(a4)+

	move.l (a0),(a1)+
	move.l (a4),(a2)+
	move.l d0,(a0)+
	move.l d0,(a4)+

	move.l (a0),(a1)+
	move.l (a4),(a2)+
	move.l d0,(a0)+
	move.l d0,(a4)+

	move.l (a0),(a1)+
	move.l (a4),(a2)+
	move.l d0,(a0)+
	move.l d0,(a4)+

	move.l (a0),(a1)+
	move.l (a4),(a2)+
	move.l d0,(a0)+
	move.l d0,(a4)+

	move.l (a0),(a1)+
	move.l (a4),(a2)+
	move.l d0,(a0)+
	move.l d0,(a4)+

	move.l (a0),(a1)+
	move.l (a4),(a2)+
	move.l d0,(a0)+
	move.l d0,(a4)+

	move.l (a0),(a1)+
	move.l (a4),(a2)+
	move.l d0,(a0)+
	move.l d0,(a4)+
	ENDIF
	dbra d3,.preparescreenclearline
	movem.l (sp)+,d0/d1/d2/d3/a0-a4
	rts