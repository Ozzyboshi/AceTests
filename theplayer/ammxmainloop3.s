ammxmainloop3:
                   movem.l                d0-d7/a0-a6,-(sp)    
  
                   SWAP_BPL
                   bsr.w                  CLEAR

                   move.w                 MUSICCOUNTER,d1
                   cmpi.w                 #64,d1
                   bne.s                  musiccounternoreset
                   IFD DEBUGCOLORS
                   move.w                 #$0AAA,$dff180
                   ENDC
                   moveq                  #0,d1
musiccounternoreset:
                   addq                   #1,d1
                   move.w                 d1,MUSICCOUNTER

                   move.w                 FRAMECOUNTER,d1
                   cmp                    #0,d1
                   beq.w                  nonewanim
                   subq                   #1,d1


  ; start of precalculation of next effect
  ;RESETFILLTABLE
  ;LOADIDENTITY
  ;VERTEX_INIT            1,#0,#-10,#0
  ;VERTEX_INIT            2,#10,#10,#0
  ;VERTEX_INIT            3,#-10,#10,#0
  ;ROTATE_X_INV_Q_5_11    d1
  ;jsr                    TRIANGLE3D_NODRAW

                   lea                    DRAWFUNCTARRAY_START,a0
                   add.l                  DRAWFUNCTCOUNTER,a0

  ; restart cyce of animations
                   cmp.l                  #DRAWFUNCTARRAY_END,a0
                   bne.s                  drawfunctcounternoreset
                   IFD DEBUGCOLORS
                   move.w                 #$0FF0,$dff180
                   ENDC
                   move.l                 #0,DRAWFUNCTCOUNTER
                   lea                    DRAWFUNCTARRAY_START,a0
drawfunctcounternoreset:

                   move.l                 (a0),a0
                   jsr                    (a0)
 
                   SAVE_FILL_TABLE2       d1
                   cmp.w                  #359,d1
                   bne.s                  nonewanim
                   move.w                 #0,FRAMECOUNTER
                   add.l                  #4,DRAWFUNCTCOUNTER
nonewanim:
                   add.w                  #1,FRAMECOUNTER


  ; end of precalculation of next effect

                   btst                   #6,$dff002
waitblit_copy5:
                   btst                   #6,$dff002
                   bne.s                  waitblit_copy5
                
                   STROKE                 #3

                   move.l                 FILLTABLES_PTR,a0
                   jsr                    ammx_fill_table_precalc
                   ;jsr                    ammx_fill_table_precalc


  

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

                   jsr                    ammx_fill_table_single_line_bpl1
                   add.w                  #40,d1
	
                   dbra                   d5,ammx_fill_table_nextline_precalc
ammx_fill_table_end_precalc:
                   movem.l                (sp)+,d0/d2-d7/a0/a3/a4/a5
                   rts

FRAMECOUNTER:      dc.w                   0 
MUSICCOUNTER:      dc.w                   0

DRAWFUNCTCOUNTER:  dc.l                   0

DRAWFUNCTARRAY_START: 
                   dc.l                   BIGTRIANGLE_Z
                   dc.l                   SMALLTRIANGLE
                   dc.l                   MEDIUMTRIANGLE
                   dc.l                   BIGTRIANGLE
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

BIGTRIANGLE_Z:
                   movem.l                d0-d6/a1,-(sp)
                   move.l                 d1,d6
                   andi.l                 #$0000FFFF,d6
                   RESETFILLTABLE
                   LOADIDENTITY

                   move.w                 #160,d0
                   move.w                 #128,d1
                   jsr                    TRANSLATE
                   ROTATE                 d6


                   move.w                 #0,d0
                   move.w                 #-15,d1

                   move.w                 #-15,d6
                   move.w                 #15,d3

                   move.w                 #15,d4
                   move.w                 #15,d5


	
                   jsr                    TRIANGLE_NODRAW
                   movem.l                (sp)+,d0-d6/a1


                   rts

; ammx_fill_table_single_line - Fills a single line according to the fill table into screens
; Input:
;	- d6.w : left X (0-319)
;	- d7.w : right X (0-319)
;	- d1.w : line number multiplied by 40 (line)
;	- a4 : addr of plotrefs
;   - a5 : addr of screen
;
; Defines:
; - USE_CLIPPING
; - USE_DBLBUF
;
; Trashes:
;   - d0
;   - d2
;	- d3
;	- d4
;	- d6
;	- d7
; 	- a3
ammx_fill_table_single_line_bpl1:
	move.l d5,-(sp) ; stack save

	move.w d7,d5 ; alternative to psubw
	sub.w d6,d5
	IFD USE_CLIPPING
	bmi.w ammx_fill_table_no_end_0_bpl1 ; if Xright<0 we are sure that no pixel must be drawn so jump to whatever exit
	ENDC
	addq #1,d5

	move.w d6,d2
	lsr.w #3,d2
	add.w d1,d2
	
	; d2.w now has the address of the first byte let's calculate the fill for this byte
	;move.w d6,d4 ; d6 can be trashed at this point
	andi.w #$0007,d6
	scc d3 ; I need to set d3 to FF, since andy ALWAYS clears C and V i use SCC who is faster than move.b
	lsr.b d6,d3

	move.l a5,a3
	add.w d2,a3

	; bitprocessed = 8-d6
	subq #8,d6 ; d6 must always be negative here!!!!
	add.w d6,d5 ; totalcount must be decremented by written bits (using add because d4 is always negative)
	
	; special case -  if d5 is negative we plotted too much
	bpl.s ammx_fill_table_no_special_case_bpl1
	neg.w d5
	lsr.b d5,d3
	lsl.b d5,d3

	or.b d3,(a3)+ ; Plot points!!
ammx_fill_table_no_special_0_bpl1:
	move.l (sp)+,d5
	rts


ammx_fill_table_no_special_case_bpl1:
    ; end special case

	; reset bitplane data
	IFND VAMPIRE
	moveq #0,d6
	moveq #0,d7
	ENDC
	IFD VAMPIRE
	REG_ZERO e0
	REG_ZERO e1
	ENDC
    
	
ammx_fill_table_no_firstbyte_1_bpl1:
    or.b d3,(a3)+ ; Plot points!!
	IFND VAMPIRE
	not.l d7
	ENDC
	IFD VAMPIRE
	load #$FFFFFFFFFFFFFFFF,e0
	ENDC

	; start addr odd or even? store result on d4
	IFND VAMPIRE
	move.l a3,d4
	btst #0,d4
	beq.s ammx_fill_table_startiter_bpl1
	cmpi.w #8,d5
	bcs.w ammx_fill_table_no8_bpl1 ; branch if lower (it will continue if we have at least 8 bits to fill)
	or.b  d7,(a3)+
	subq #8,d5
	ENDC

; start iteration until we are at the end
ammx_fill_table_startiter_bpl1:

	; now we are byte aligned, evaluate how many bits we still have to fill
	cmpi.w #64,d5
	bcs.w ammx_fill_table_no64_bpl1 ; branch if lower (it will continue if we have at least 64 bits to fill)

	; here starts the code to fill 64 bits
	IFD VAMPIRE
	POR 256*40(a3),e1,e6
	STORE e6,256*40(a3)
	POR (a3),e0,e6
	STORE e6,(a3)+
	subi.w #64,d5
	bne.s ammx_fill_table_startiter_bpl1
	move.l (sp)+,d5
	rts
	ENDC
	IFND VAMPIRE
	

	or.l  d7,(a3)+
	or.l  d7,(a3)+

	subi.w #64,d5
	bne.s ammx_fill_table_startiter_bpl1
	move.l (sp)+,d5
	rts
	ENDC
	
ammx_fill_table_no64_bpl1:
	cmpi.w #32,d5
	bcs.w ammx_fill_table_no32_bpl1 ; branch if lower (it will continue if we have at least 32 bits to fill)

	IFD VAMPIRE
	vperm #$00000000,e1,e1,d0
	vperm #$00000000,e0,e0,d0
	or.l d0,(a3)+ ; first bitplane
	subi.w #32,d5
	bne.w ammx_fill_table_startiter_bpl1
	move.l (sp)+,d5
	rts
	ENDC
	
	IFND VAMPIRE
	
	or.l  d7,(a3)+

	subi.w #32,d5
	beq.s ammx_fill_table_no_end_0_bpl1

	ENDC
	
ammx_fill_table_no32_bpl1:
	cmpi.w #16,d5
	bcs.w ammx_fill_table_no16_bpl1 ; branch if lower (it will continue if we have at least 16 bits to fill)
	
	IFD VAMPIRE
	vperm #$00000000,e1,e1,d0
	vperm #$00000000,e0,e0,d0
	or.w d0,(a3)+ ; first bitplane
	subi.w #16,d5
	bne.w ammx_fill_table_no16_bpl1
	move.l (sp)+,d5
	rts
	ENDC
	
	IFND VAMPIRE
	or.w  d7,(a3)+

	subi.w #16,d5
	beq.s ammx_fill_table_no_end_0_bpl1
	ENDC
	
ammx_fill_table_no16_bpl1:

	cmpi.w #8,d5
	bcs.w ammx_fill_table_no8_bpl1 ; branch if lower (it will continue if we have at least 8 bits to fill)
	IFD VAMPIRE
	vperm #$00000000,e1,e1,d0
	vperm #$00000000,e0,e0,d0
	or.b d0,(a3)+ ; first bitplane
	ENDC

	IFND VAMPIRE
	or.b  d7,(a3)+
	ENDC

	subq #8,d5
	beq.s ammx_fill_table_no_end_0_bpl1

ammx_fill_table_no8_bpl1:

	; we get here only and only if there is less then a byte to fill, in other words, d5<8
	; in this case we must fill the MSG bytes of the byte wit a 1
	moveq #8,d4
	sub.w d5,d4
	IFD VAMPIRE
	vperm #$00000000,e1,e1,d6
	vperm #$00000000,e0,e0,d7
	ENDC
	lsl.b d4,d6
	lsl.b d4,d7

	or.b d7,(a3)
ammx_fill_table_no_end_0_bpl1
	move.l (sp)+,d5
	rts

