ammxmainloop3:
  movem.l     d0-d7/a0-a6,-(sp)    
  
  SWAP_BPL
  bsr.w       CLEAR

  

  ; start of precalculation of next effect
  RESETFILLTABLE
  LOADIDENTITY
  VERTEX_INIT            1,#0,#-50,#0
  VERTEX_INIT            2,#50,#50,#0
  VERTEX_INIT            3,#-50,#50,#0
  ROTATE_X_INV_Q_5_11 #45
  jsr                    TRIANGLE3D_2
  ; end of precalculation of next effect

  btst        #6,$dff002
waitblit_copy5:
  btst        #6,$dff002
  bne.s       waitblit_copy5
                
  STROKE      #3

  move.l      FILLTABLES_PTR,a0
  jsr         ammx_fill_table_precalc

  adda.l      #4*257*1,a0
  cmp.l       FILLTABLES_ADDR_END,a0
  bne.s       filltablesdonotreset
  move.l      FILLTABLES_ADDR_START,a0
filltablesdonotreset
  move.l      a0,FILLTABLES_PTR
                   

      
  movem.l     (sp)+,d0-d7/a0-a6
  move.l      SCREEN_PTR_OTHER_0,d0

  rts


CLEAR: 
  btst        #6,$dff002
waitblit_copy4:
  btst        #6,$dff002
  bne.s       waitblit_copy4
  move.w      #$0100,$dff040
  move.w      #$0000,$dff042        
  move.l      SCREEN_PTR_0,$dff054                   ; copy to d channel
  move.w      #$0000,$dff066                         ;D mod
  move.w      #$8014,$dff058
  rts


ammx_fill_table_precalc:
	
  movem.l     d0/d2-d7/a0/a3/a4/a5,-(sp)             ; stack save

	
  move.w      (a0)+,AMMXFILLTABLE_CURRENT_ROW
  move.w      (a0)+,AMMXFILLTABLE_END_ROW

  move.w      #1,AMMX_FILL_TABLE_FIRST_DRAW
  move.w      AMMXFILLTABLE_END_ROW,d5


	; Reposition inside the fill table according to the starting row
  move.w      AMMXFILLTABLE_CURRENT_ROW,d6
  move.w      d6,d1
  lsl.w       #2,d6
  add.w       d6,a0
	; end of repositioning

  MINUWORD    d1,FILLTABLE_FRAME_MIN_Y
  MAXUWORD    d5,FILLTABLE_FRAME_MAX_Y

  cmp.w       d5,d1
  bhi.s       ammx_fill_table_end_precalc
  sub.w       d1,d5

  lea         PLOTREFS,a4
  add.w       d1,d1
  move.w      0(a4,d1.w),d1

  IFD         USE_DBLBUF
  move.l      SCREEN_PTR_0,a5
  ELSE
  lea         SCREEN_0,a5
  ENDC

ammx_fill_table_nextline_precalc:

  move.w      (a0)+,d6                               ; start of fill line
  move.w      (a0)+,d7                               ; end of fill line

  jsr         ammx_fill_table_single_line
  add.w       #40,d1
	
  dbra        d5,ammx_fill_table_nextline_precalc
ammx_fill_table_end_precalc:
  movem.l     (sp)+,d0/d2-d7/a0/a3/a4/a5
  rts


