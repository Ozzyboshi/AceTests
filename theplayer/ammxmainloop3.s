ammxmainloop3:
  movem.l                d0-d7/a0-a6,-(sp)    
  
  SWAP_BPL
  bsr.w                  CLEAR

  move.w MUSICCOUNTER,d1
  cmpi.w #64,d1
  bne.s musiccounternoreset
  move.w #$0AAA,$dff180
  moveq #0,d1
musiccounternoreset:
  addq #1,d1
  move.w d1,MUSICCOUNTER

  move.w FRAMECOUNTER,d1
  cmp #0,d1
  beq.w nonewanim
  subq #1,d1


  ; start of precalculation of next effect
  ;RESETFILLTABLE
  ;LOADIDENTITY
  ;VERTEX_INIT            1,#0,#-10,#0
  ;VERTEX_INIT            2,#10,#10,#0
  ;VERTEX_INIT            3,#-10,#10,#0
  ;ROTATE_X_INV_Q_5_11    d1
  ;jsr                    TRIANGLE3D_NODRAW

  lea DRAWFUNCTARRAY_START,a0
  add.l DRAWFUNCTCOUNTER,a0

  ; restart cyce of animations
  cmp.l #DRAWFUNCTARRAY_END,a0
  bne.s drawfunctcounternoreset
  move.w #$0FF0,$dff180
  move.l #0,DRAWFUNCTCOUNTER
  lea DRAWFUNCTARRAY_START,a0
drawfunctcounternoreset:

  move.l (a0),a0
  jsr (a0)
 
  SAVE_FILL_TABLE2 d1
  cmp.w #359,d1
  bne.s nonewanim
  move.w #0,FRAMECOUNTER
  add.l #4,DRAWFUNCTCOUNTER
nonewanim:
  add.w #1,FRAMECOUNTER


  ; end of precalculation of next effect

  btst                   #6,$dff002
waitblit_copy5:
  btst                   #6,$dff002
  bne.s                  waitblit_copy5
                
  STROKE                 #3

  move.l                 FILLTABLES_PTR,a0
  jsr                    ammx_fill_table_precalc

; start of overwriting with next animation
  IFD LOL
  clr.w $100
  move.w #$1234,d3
  move.w                 #255,d0
  move.l                 a0,a1
  lea FILL_TABLE,a2
  move.w                 #0,(a1)+
  move.w                 #0,(a1)+
copynewfilltable;
  move.l                 (a2),(a1)+
  dbra                   d0,copynewfilltable
  ENDC
  
; end of overwriting with next animation

  adda.l                 #4*257*1,a0
  cmp.l                  FILLTABLES_ADDR_END,a0
  bne.s                  filltablesdonotreset
  move.l                 FILLTABLES_ADDR_START,a0
filltablesdonotreset
  move.l                 a0,FILLTABLES_PTR
                   

      
  movem.l                (sp)+,d0-d7/a0-a6
  move.l                 SCREEN_PTR_OTHER_0,d0

  rts


CLEAR: 
  btst                   #6,$dff002
waitblit_copy4:
  btst                   #6,$dff002
  bne.s                  waitblit_copy4
  move.w                 #$0100,$dff040
  move.w                 #$0000,$dff042        
  move.l                 SCREEN_PTR_0,$dff054                   ; copy to d channel
  move.w                 #$0000,$dff066                         ;D mod
  move.w                 #$8014,$dff058
  rts


ammx_fill_table_precalc:
	
  movem.l                d0/d2-d7/a0/a3/a4/a5,-(sp)             ; stack save

	
  move.w                 (a0)+,AMMXFILLTABLE_CURRENT_ROW
  move.w                 (a0)+,AMMXFILLTABLE_END_ROW

  move.w                 #1,AMMX_FILL_TABLE_FIRST_DRAW
  move.w                 AMMXFILLTABLE_END_ROW,d5


	; Reposition inside the fill table according to the starting row
  move.w                 AMMXFILLTABLE_CURRENT_ROW,d6
  move.w                 d6,d1
  lsl.w                  #2,d6
  add.w                  d6,a0
	; end of repositioning

  MINUWORD               d1,FILLTABLE_FRAME_MIN_Y
  MAXUWORD               d5,FILLTABLE_FRAME_MAX_Y

  cmp.w                  d5,d1
  bhi.s                  ammx_fill_table_end_precalc
  sub.w                  d1,d5

  lea                    PLOTREFS,a4
  add.w                  d1,d1
  move.w                 0(a4,d1.w),d1

  IFD                    USE_DBLBUF
  move.l                 SCREEN_PTR_0,a5
  ELSE
  lea                    SCREEN_0,a5
  ENDC

ammx_fill_table_nextline_precalc:

  move.w                 (a0)+,d6                               ; start of fill line
  move.w                 (a0)+,d7                               ; end of fill line

  jsr                    ammx_fill_table_single_line
  add.w                  #40,d1
	
  dbra                   d5,ammx_fill_table_nextline_precalc
ammx_fill_table_end_precalc:
  movem.l                (sp)+,d0/d2-d7/a0/a3/a4/a5
  rts

FRAMECOUNTER: dc.w 0 
MUSICCOUNTER: dc.w 0

DRAWFUNCTCOUNTER: dc.l 0

DRAWFUNCTARRAY_START: 
  dc.l SMALLTRIANGLE
  dc.l MEDIUMTRIANGLE
  dc.l BIGTRIANGLE
DRAWFUNCTARRAY_END:

SMALLTRIANGLE:
  RESETFILLTABLE
  LOADIDENTITY
  VERTEX_INIT            1,#0,#-10,#0
  VERTEX_INIT            2,#10,#10,#0
  VERTEX_INIT            3,#-10,#10,#0
  ROTATE_X_INV_Q_5_11    d1
  jsr                    TRIANGLE3D_NODRAW
  rts

MEDIUMTRIANGLE:
  RESETFILLTABLE
  LOADIDENTITY
  VERTEX_INIT            1,#0,#-25,#0
  VERTEX_INIT            2,#25,#25,#0
  VERTEX_INIT            3,#-25,#25,#0
  ROTATE_X_INV_Q_5_11    d1
  jsr                    TRIANGLE3D_NODRAW
  rts

BIGTRIANGLE:
  RESETFILLTABLE
  LOADIDENTITY
  VERTEX_INIT            1,#0,#-50,#0
  VERTEX_INIT            2,#50,#50,#0
  VERTEX_INIT            3,#-50,#50,#0
  ROTATE_X_INV_Q_5_11    d1
  jsr                    TRIANGLE3D_NODRAW
  rts


