DEBUG_COLORS=1;
                  include                                       "aprocessing/rasterizers/processing_bitplanes_fast.s"

                  XDEF                                          _ammxmainloop
                  XDEF                                          _ammxmainloop2
                  XDEF                                          _ammxmainloop3
                    XDEF                                          _ammxmainloop3_init

                 ; SECTION                                       PROCESSING,CODE_F
                 SECTION ".data_chip",data

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



allocdef:                   ; subroutine for allocating memory - first fast then chip. ML: d0 = allocdef(d0).
        movem.l	d1-d7/a0-a6,-(a7)   ; push registers on the stack
        moveq	#1,d1               ; trick to quickly get $#10000
        swap	d1                  ; set d1 to MEMF_CLEAR initialize memory to all zeros
        move.l	$4,a6               ; fetch base pointer for exec.library
        jsr	-198(a6)            ; call AllocMem. d0 = AllocMem(d0,d1)
        movem.l	(a7)+,d1-d7/a0-a6   ; pop registers from the stack
        rts

freemem:                    ; subroutine for deallocating. ML: freemem(a1,d0).
        movem.l	d0-d7/a0-a6,-(a7)   ; push registers on the stack
        move.l	a0,a1               ; set a1 to the memory block to free
        move.l	$4,a6               ; fetch base pointer for exec.library
        jsr	-210(a6)            ; call FreeMem. FreeMem(a1,d0)
        movem.l	(a7)+,d0-d7/a0-a6   ; pop registers from the stack
        rts   

;FILLTABLES: dcb.b 4*257*360,$00
;FILLTABLES_END:


BULD_FILLTABLE:
        movem.l                                       d0-d7/a0-a6,-(sp)
        move.w #360-1,d5
        moveq #0,d6
BULD_FILLTABLE_START:
        RESETFILLTABLE
        bsr.w BULD_ROTATION
        ;SAVE_FILL_TABLE d6
        SAVE_FILL_TABLE2 d6
        addq #1,d6
        dbra d5,BULD_FILLTABLE_START
        movem.l                                       (sp)+,d0-d7/a0-a6
        rts

BULD_ROTATION:
        movem.l                                       d0-d7/a0-a6,-(sp)
        LOADIDENTITY
        ROTATE_X_INV_Q_5_11 d6
        jsr                                         TRIANGLE3D
        movem.l                                       (sp)+,d0-d7/a0-a6
        rts

FILLTABLES_ADDR_START:  dc.l 0
FILLTABLES_ADDR_END:    dc.l 0
_ammxmainloop3_init:
                ;movem.l                                       d0-d7/a0-a6,-(sp)
                move.l #4*257*360,d0
                jsr allocdef
                move.l d0,FILLTABLES_ADDR_START
                add.l #4*257*360,d0
                move.l d0,FILLTABLES_ADDR_END

                ;move.l #4*257*360,d0
                ;move.l FILLTABLES_ADDR_START,a0
                ;jsr freemem

                move.l  #ammx_fill_table_noreset,AMMX_FILL_FUNCT_ADDR
                LOADIDENTITY
                VERTEX_INIT                                   1,#0,#-50,#0
                VERTEX_INIT                                   2,#50,#50,#0
                VERTEX_INIT                                   3,#-50,#50,#0
                bsr.w BULD_FILLTABLE

                  IFD ALESSIO
                        RESETFILLTABLE
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 0


                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 1

                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 2




                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 3

                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 4

                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 5




                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 6

                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 7

                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 8

                  


                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 9

                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 10

                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 11




                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 12

                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 13

                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 14


                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 15

                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 16

                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 17


                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 18

                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 19

                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 20


                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 21

                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 22

                  RESETFILLTABLE
                  ROTATE_X_INV_Q_5_11 #15
                  jsr                                         TRIANGLE3D
                  SAVEFILLTABLE 23
                ENDIF
                  





                  

                  
              ;  move.l #FILLTABLES,FILLTABLES_PTR
              move.l FILLTABLES_ADDR_START,FILLTABLES_PTR


              ; Init LSP and start replay using easy CIA toolbox
		;	lea		LSPMusic,a0
		;	lea		LSPBank,a1
		;	suba.l	a2,a2			; suppose VBR=0 ( A500 )
		;	moveq	#0,d0			; suppose PAL machine
		;	bsr		LSP_MusicDriver_CIA_Start

              ;  lea		LSPMusic,a0
		;	lea		LSPBank,a1
		;	lea		copperDMAConPatch+3,a2
		;	bsr		LSP_MusicDriver



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
                  movem.l                                       d0-d7/a0-a6,-(sp)	
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
                SWAP_BPL
                bsr.w CLEAR
				;  	bsr.w _mt_music

                  btst    #6,$dff002
waitblit_copy5:
        btst    #6,$dff002
        bne.s   waitblit_copy5
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
                   ;move.w #255,AMMXFILLTABLE_END_ROW
                   ;move.w #10,AMMXFILLTABLE_CURRENT_ROW
                    STROKE #3

                    
                    move.l FILLTABLES_PTR,a0
                    jsr ammx_fill_table_precalc

                    ; point the NEXT FILLTABLES record
                    adda.l #4*257*1,a0
                    ;cmp.l #FILLTABLES_END,a0
                    cmp.l FILLTABLES_ADDR_END,a0
                    bne.s filltablesdonotreset
                    ;move.l #FILLTABLES,a0
                    move.l FILLTABLES_ADDR_START,a0
filltablesdonotreset
                    move.l a0,FILLTABLES_PTR
                    ;jsr ammx_fill_table_noreset
                     IFD DEBUG_COLORS
                  move.w                                        #$0000F,$dff180
                  ENDIF

        IFD BLITTA
; start of screen dump
        btst    #6,$dff002
waitblit_copy:
        btst    #6,$dff002
        bne.s   waitblit_copy
        move.w  #$09F0,$dff040
        move.w  #$0000,$dff042
        move.l SCREEN_PTR_0,a0
        move.l bitplane0,a1
        move.w FILLTABLE_FRAME_MIN_Y,d0
        move.w FILLTABLE_FRAME_MAX_Y,d1
        sub.w d0,d1
        ;move.w #100,d1
        lsl.w #6,d1
        or.w #$0014,d1
        mulu.w #40,d0
        add.w d0,a0
        add.w d0,a1
        move.l  a0,$dff050 ; copy from a channel
        move.l  a1,$dff054 ; copy to d channel
        move.w  #$0000,$dff064 ;A mod
        move.w  #$0000,$dff066 ;D mod
        move.w d1,$dff058
        btst    #6,$dff002
waitblit_copy2:
        btst    #6,$dff002
        bne.s   waitblit_copy2
        ;add.w #256*40,a0
        ;add.w #256*40,a1
        move.l SCREEN_PTR_1,a0
        move.l bitplane1,a1
        add.w d0,a0
        add.w d0,a1
        move.l  a0,$dff050 ; copy from a channel
        move.l  a1,$dff054 ; copy to d channel
        move.w #$1914,$dff058
        btst    #6,$dff002
waitblit_copy3:
        btst    #6,$dff002
        bne.s   waitblit_copy3
        ENDIF
;end of screen dump
         IFD DEBUG_COLORS
                  move.w                                        #$0000,$dff180
        ENDIF
        movem.l                                       (sp)+,d0-d7/a0-a6
                  move.l                                        SCREEN_PTR_OTHER_0,d0

                  rts

par1:
                  dc.l                                          0
bitplane0:
                  dc.l                                          0
bitplane1:
                  dc.l                                          0
FILLTABLES_PTR: dc.l 0
CLEAR: 
   btst    #6,$dff002
waitblit_copy4:
        btst    #6,$dff002
        bne.s   waitblit_copy4
        move.w  #$0100,$dff040
        move.w  #$0000,$dff042        
        move.l  SCREEN_PTR_0,$dff054 ; copy to d channel
        move.w  #$0000,$dff066 ;D mod
        move.w #$8014,$dff058
;  	movem.l d0/d1/d2/d3/a0-a4,-(sp) ; stack save
;    movem.l (sp)+,d0/d1/d2/d3/a0-a4
	  rts

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
	IFD LSP
;*****************************************************************
;
;	Light Speed Player v1.03
;	Fastest Amiga MOD player ever :)
;	Written By Arnaud Carré (aka Leonard / OXYGENE)
;	https://github.com/arnaud-carre/LSPlayer
;	twitter: @leonard_coder
;
;	"small & fast" player version ( min/avg/peak = 0.25/1/2 scanline)
;	Less than 512 bytes of code!
;	You can also use generated "insane" player code for even more perf
;
;	--------How to use--------- 
;
;	bsr LSP_MusicDriver+0 : Init LSP player code
;		In:	a0: LSP music data(any memory)
;			a1: LSP sound bank(chip memory)
;			a2: DMACON 8bits byte address
;		Out:a0: music BPM pointer (16bits)
;
;	bsr LSP_MusicDriver+4 : LSP player tick (call once per frame)
;		In:	a6: should be $dff0a0
;			Used regs: d0/d1/a0/a1/a2/a3/a4
;		Out:None
;
;*****************************************************************
        IFD LOLLAMELO

	opt o-		; switch off ALL optimizations (we don't want vasm to change some code size, and all optimizations are done!)

LSP_MusicDriver:
			bra.w	.LSP_PlayerInit

;.LSP_MusicDriver+4:						; player tick handle ( call this at music player rate )
			lea		.LSPVars(pc),a1
			move.l	(a1),a0					; byte stream
.process:	moveq	#0,d0
			move.b	(a0)+,d0
			bne.s	.swCode
			move.w	#$0100,d0
			move.b	(a0)+,d0
			bne.s	.swCode
			move.w	#$0200,d0
			move.b	(a0)+,d0
.swCode:	add.w	d0,d0
			move.l	m_codeTableAddr(a1),a2	; code table
			move.w	0(a2,d0.w),d0			; code
			beq		.noInst
			bpl.s	.optim
			cmpi.w	#$ffff,d0
			beq		.r_rewind
			cmpi.w	#$f00f,d0
			beq		.r_chgbpm
.optim:
			moveq	#15,d1
			and.w	d0,d1

			add.w	d0,d0
			bcc.s	.noRd
			move.l	.resetv(pc),a3
			move.l	(a3)+,$d0-$a0(a6)
			move.w	(a3)+,$d4-$a0(a6)
.noRd:		add.w	d0,d0
			bcc.s	.noRc
			move.l	.resetv+4(pc),a3
			move.l	(a3)+,$c0-$a0(a6)
			move.w	(a3)+,$c4-$a0(a6)
.noRc:		add.w	d0,d0
			bcc.s	.noRb
			move.l	.resetv+8(pc),a3
			move.l	(a3)+,$b0-$a0(a6)
			move.w	(a3)+,$b4-$a0(a6)
.noRb:		add.w	d0,d0
			bcc.s	.noRa
			move.l	.resetv+12(pc),a3
			move.l	(a3)+,(a6)
			move.w	(a3)+,$a4-$a0(a6)
.noRa:		

			add.w	d0,d0
			bcc.s	.noVd
			move.b	(a0)+,$d9-$a0(a6)
.noVd:		add.w	d0,d0
			bcc.s	.noVc
			move.b	(a0)+,$c9-$a0(a6)
.noVc:		add.w	d0,d0
			bcc.s	.noVb
			move.b	(a0)+,$b9-$a0(a6)
.noVb:		add.w	d0,d0
			bcc.s	.noVa
			move.b	(a0)+,$a9-$a0(a6)
.noVa:		
			move.l	a0,(a1)+	; store byte stream ptr
			move.l	(a1),a0		; word stream

			add.w	d0,d0
			bcc.s	.noPd
			move.w	(a0)+,$d6-$a0(a6)
.noPd:		add.w	d0,d0
			bcc.s	.noPc
			move.w	(a0)+,$c6-$a0(a6)
.noPc:		add.w	d0,d0
			bcc.s	.noPb
			move.w	(a0)+,$b6-$a0(a6)
.noPb:		add.w	d0,d0
			bcc.s	.noPa
			move.w	(a0)+,$a6-$a0(a6)
.noPa:		
			tst.w	d1
			beq.s	.noInst

			move.l	m_dmaconPatch-4(a1),a3		; dmacon patch
			move.w	d1,$96-$a0(a6)				; switch off DMA
			move.b	d1,(a3)						; dmacon			
			move.l	m_lspInstruments-4(a1),a2	; instrument table

			lea		.resetv(pc),a3
			add.w	d0,d0
			bcc.s	.noId
			add.w	(a0)+,a2
			move.l	(a2)+,$d0-$a0(a6)
			move.w	(a2)+,$d4-$a0(a6)
			move.l	a2,(a3)
.noId:		add.w	d0,d0
			bcc.s	.noIc
			add.w	(a0)+,a2
			move.l	(a2)+,$c0-$a0(a6)
			move.w	(a2)+,$c4-$a0(a6)
			move.l	a2,4(a3)
.noIc:		add.w	d0,d0
			bcc.s	.noIb
			add.w	(a0)+,a2
			move.l	(a2)+,$b0-$a0(a6)
			move.w	(a2)+,$b4-$a0(a6)
			move.l	a2,8(a3)
.noIb:		add.w	d0,d0
			bcc.s	.noIa
			add.w	(a0)+,a2
			move.l	(a2)+,(a6)
			move.w	(a2)+,$a4-$a0(a6)
			move.l	a2,12(a3)
.noIa:		

.noInst:	move.l	a0,(a1)			; store word stream (or byte stream if coming from early out)
			rts

.r_rewind:	move.l	m_byteStreamLoop(a1),a0
			move.l	m_wordStreamLoop(a1),m_wordStream(a1)
			bra		.process

.r_chgbpm:	move.b	(a0)+,(m_currentBpm+1)(a1)	; BPM
			bra		.process


	rsreset
	
m_byteStream:		rs.l	1	;  0 byte stream
m_wordStream:		rs.l	1	;  4 word stream
m_dmaconPatch:		rs.l	1	;  8 m_lfmDmaConPatch
m_codeTableAddr:	rs.l	1	; 12 code table addr
m_lspInstruments:	rs.l	1	; 16 LSP instruments table addr
m_relocDone:		rs.w	1	; 20 reloc done flag
m_currentBpm:		rs.w	1	; 22 current BPM
m_byteStreamLoop:	rs.l	1	; 24 byte stream loop point
m_wordStreamLoop:	rs.l	1	; 28 word stream loop point
sizeof_LSPVars:		rs.w	0

.LSPVars:	ds.b	sizeof_LSPVars
			
.resetv:	dc.l	0,0,0,0

; a0: music data (any mem)
; a1: sound bank data (chip mem)
; a2: 16bit DMACON word address

.LSP_PlayerInit:
			cmpi.l	#'LSP1',(a0)+
			bne.s	.dataError
			move.l	(a0)+,d0		; unique id
			cmp.l	(a1),d0			; check that sample bank is this one
			bne.s	.dataError

			lea		.LSPVars(pc),a3
			move.w	(a0)+,d0				; skip major & minor version of LSP
			move.w	(a0)+,m_currentBpm(a3)	; default BPM
			move.l	a2,m_dmaconPatch(a3)
			move.w	(a0)+,d0				; instrument count
			lea		-12(a0),a2				; LSP data has -12 offset on instrument tab ( to win 2 cycles in fast player :) )
			move.l	a2,m_lspInstruments(a3)	; instrument tab addr ( minus 4 )
			tst.b	m_relocDone(a3)
			bne.s	.skip
			st		m_relocDone(a3)
			subq.w	#1,d0
			move.l	a1,d1
.relocLoop:	add.l	d1,(a0)
			add.l	d1,6(a0)
			lea		12(a0),a0
			dbf		d0,.relocLoop
			bra.s	.relocDone
.skip:		mulu.w	#12,d0
			add.l	d0,a0
.relocDone:	move.w	(a0)+,d0				; codes count (+2)
			move.l	a0,m_codeTableAddr(a3)	; code table
			add.w	d0,d0
			add.w	d0,a0
			move.l	(a0)+,d0				; word stream size
			move.l	(a0)+,d1				; byte stream loop point
			move.l	(a0)+,d2				; word stream loop point

			move.l	a0,m_wordStream(a3)
			lea		0(a0,d0.l),a1			; byte stream
			move.l	a1,m_byteStream(a3)
			add.l	d2,a0
			add.l	d1,a1
			move.l	a0,m_wordStreamLoop(a3)
			move.l	a1,m_byteStreamLoop(a3)
			bset.b	#1,$bfe001				; disabling this fucking Low pass filter!!
			lea		m_currentBpm(a3),a0
			rts

.dataError:	illegal

;*****************************************************************
;
;	Light Speed Player v1.03
;	Fastest Amiga MOD player ever :)
;	Written By Arnaud Carré (aka Leonard / OXYGENE)
;	https://github.com/arnaud-carre/LSPlayer
;	twitter: @leonard_coder
;
;	"cia" player version ( or "less effort" )
;
;	Warnings:
;	a)	this file is provided for "easy of use". But if you're working
;		on a cycle-optimizated demo effect, please call LightSpeedPlayer from your
;		own existing interrupt and use copper to set DMACON 11 raster lines later
;
;	b)	this code doesn't restore any amiga OS stuff.
;		( are you a cycle-optimizer or what? :) )
;
;	--------How to use--------- 
;
;	bsr LSP_MusicDriver_CIA_Start : Init LSP player code and install CIA interrupt
;		a0: LSP music data(any memory)
;		a1: LSP sound bank(chip memory)
;		a2: VBR (CPU Vector Base Register) ( use 0 if 68000 )
;		d0: 0=PAL, 1=NTSC
;
;	bsr LSP_MusicDriver_CIA_Stop : Stop LSP music replay
;
;*****************************************************************
LSP_MusicDriver_CIA_Start:
			move.w	d0,-(a7)
			lea		.irqVector(pc),a3
			lea		$78(a2),a2
			move.l	a2,(a3)
			lea		.LSPDmaCon+1(pc),a2		; DMACON byte patch address
			bsr		LSP_MusicDriver+0		; init the LSP player ( whatever fast or insane version )

			lea		.pMusicBPM(pc),a2
			move.l	a0,(a2)					; store music BPM pointer
			move.w	(a0),d0					; start BPM
			lea		.curBpm(pc),a2
			move.w	d0,(a2)
			moveq	#1,d1
			and.w	(a7)+,d1
			bsr.s	.LSP_IrqInstall

			rts

.LSPDmaCon:	dc.w	$8000
.irqVector:	dc.l	0
.ciaClock:	dc.l	0
.curBpm:	dc.w	0
.pMusicBPM:	dc.l	0

; d0: music BPM
; d1: PAL(0) or NTSC(1)
.LSP_IrqInstall:
			move.w 	#(1<<13),$dff09a		; disable CIA interrupt
			lea		.LSP_MainIrq(pc),a0
			move.l	.irqVector(pc),a5
			move.l	a0,(a5)

			lea		$bfd000,a0
			move.b 	#$7f,$d00(a0)
			move.b 	#$10,$e00(a0)
			move.b 	#$10,$f00(a0)
			lsl.w	#2,d1
			move.l	.palClocks(pc,d1.w),d1				; PAL or NTSC clock
			lea		.ciaClock(pc),a5
			move.l	d1,(a5)
			divu.w	d0,d1
			move.b	d1,$400(a0)
			lsr.w 	#8,d1
			move.b	d1,$500(a0)
			move.b	#$83,$d00(a0)
			move.b	#$11,$e00(a0)
			
			move.b	#496&255,$600(a0)		; set timer b to 496 ( to set DMACON )
			move.b	#496>>8,$700(a0)

			move.w 	#(1<<13),$dff09c		; clear any req CIA
			move.w 	#$a000,$dff09a			; CIA interrupt enabled
			rts
		
.palClocks:	dc.l	1773447,1789773

.LSP_MainIrq:
			move.w	#$2000,$dff09c
			btst.b	#0,$bfdd00
			beq.s	.skipa
			
			movem.l	d0-d1/a0-a3/a6,-(a7)

		; call player tick
			lea		$dff0a0,a6
			bsr		LSP_MusicDriver+4		; LSP main music driver tick

		; check if BMP changed in the middle of the music
			move.l	.pMusicBPM(pc),a0
			move.w	(a0),d0					; current music BPM
			cmp.w	.curBpm(pc),d0
			beq.s	.noChg
			lea		.curBpm(pc),a2			
			move.w	d0,(a2)					; current BPM
			move.l	.ciaClock(pc),d1
			divu.w	d0,d1
			move.b	d1,$bfd400
			lsr.w 	#8,d1
			move.b	d1,$bfd500			

.noChg:		lea		.LSP_DmaconIrq(pc),a0
			move.l	.irqVector(pc),a1
			move.l	a0,(a1)
			move.b	#$19,$bfdf00			; start timerB, one shot

			movem.l	(a7)+,d0-d1/a0-a3/a6
.skipa:		nop
			rte

.LSP_DmaconIrq:
			move.w	#$2000,$dff09c
			btst.b	#1,$bfdd00
			beq.s	.skipb
			move.w	.LSPDmaCon(pc),$dff096
			pea		(a0)
			move.l	.irqVector(pc),a0
			pea		.LSP_MainIrq(pc)
			move.l	(a7)+,(a0)
			move.l	(a7)+,a0
.skipb:		nop
			rte

LSP_MusicDriver_CIA_Stop:
			move.b	#$7f,$bfdd00
			move.w	#$2000,$dff09a
			move.w	#$2000,$dff09c
			move.w	#$000f,$dff096
			rts
        ENDIF
        
		;SECTION ".data2_chip",data

LSPBank:	incbin	"rink-a-dink.lsbank"
                ;incbin "Dirty_Tricks.lsbank"
			even

		data

LSPMusic:	incbin	"rink-a-dink.lsmusic"
                ;incbin "Dirty_Tricks.lsmusic"
			even
	ENDIF
