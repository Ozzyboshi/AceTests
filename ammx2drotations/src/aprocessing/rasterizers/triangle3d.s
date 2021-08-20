; first point d0,d1
; second point d6,d3
; third point d4,d5
  IFD                                          USE_3D
TRIANGLE3D:
  movem.l                                      d0-d6/a1,-(sp)
    
  POINT_TRANSFORM_AND_STORE_IN_FILLTABLE_3D    VERTEX_LIST_3D_1,VERTEX_LIST_3D_1+2,VERTEX_LIST_3D_1+4,0
  POINT_TRANSFORM_AND_STORE_IN_FILLTABLE_3D    VERTEX_LIST_3D_2,VERTEX_LIST_3D_2+2,VERTEX_LIST_3D_2+4,4
  bsr.w                                        ammxlinefill
    
  POINT_TRANSFORM_AND_STORE_IN_FILLTABLE_3D    VERTEX_LIST_3D_3,VERTEX_LIST_3D_3+2,VERTEX_LIST_3D_3+4,4
  bsr.w                                        ammxlinefill
    
  POINT_TRANSFORM_AND_STORE_IN_FILLTABLE_3D    VERTEX_LIST_3D_2,VERTEX_LIST_3D_2+2,VERTEX_LIST_3D_2+4,0
  bsr.w                                        ammxlinefill
    
  move.l                                       AMMX_FILL_FUNCT_ADDR,a1
  jsr                                          (a1)

  movem.l                                      (sp)+,d0-d6/a1
  rts
TRIANGLE3D_BPL0:
  movem.l                                      d0-d6/a1,-(sp)
    
  POINT_TRANSFORM_AND_STORE_IN_FILLTABLE_3D    VERTEX_LIST_3D_1,VERTEX_LIST_3D_1+2,VERTEX_LIST_3D_1+4,0
  POINT_TRANSFORM_AND_STORE_IN_FILLTABLE_3D    VERTEX_LIST_3D_2,VERTEX_LIST_3D_2+2,VERTEX_LIST_3D_2+4,4
  bsr.w                                        ammxlinefill
    
  POINT_TRANSFORM_AND_STORE_IN_FILLTABLE_3D    VERTEX_LIST_3D_3,VERTEX_LIST_3D_3+2,VERTEX_LIST_3D_3+4,4
  bsr.w                                        ammxlinefill
    
  POINT_TRANSFORM_AND_STORE_IN_FILLTABLE_3D    VERTEX_LIST_3D_2,VERTEX_LIST_3D_2+2,VERTEX_LIST_3D_2+4,0
  bsr.w                                        ammxlinefill
    
  ;move.l                                       AMMX_FILL_FUNCT_ADDR,a1
  ;jsr                                          (a1)
  bsr.w ammx_fill_table_bpl0 

  movem.l                                      (sp)+,d0-d6/a1
  rts

ammx_fill_table_bpl0:
	IFD DEBUG_COLORS
	move.w                                        #$0FF0,$dff180
	ENDIF
	movem.l d1/d5-d7/a0,-(sp) ; stack save
	move.w #1,AMMX_FILL_TABLE_FIRST_DRAW
	move.w AMMXFILLTABLE_END_ROW,d5

	lea FILL_TABLE,a0

	; Reposition inside the fill table according to the starting row
	move.w AMMXFILLTABLE_CURRENT_ROW,d6
	move.w d6,d1
	lsl.w #2,d6
	add.w d6,a0
	; end of repositioning

ammx_fill_table_nextline_bpl0:
	cmp.w d5,d1
	bhi.s ammx_fill_table_end_bpl0

	move.w (a0),d6 ; start of fill line
	move.w 2(a0),d7 ; end of fill line
	move.l #$7FFF8000,(a0)+
	
	bsr.w ammx_fill_table_single_line_bpl0
	addq #1,d1
	
	bra.s ammx_fill_table_nextline_bpl0
ammx_fill_table_end_bpl0:

	move.w AMMXFILLTABLE_CURRENT_ROW,d6
	MINUWORD d6,FILLTABLE_FRAME_MIN_Y
	MAXUWORD d1,FILLTABLE_FRAME_MAX_Y
	move.w #-1,AMMXFILLTABLE_END_ROW
	movem.l (sp)+,d1/d5-d7/a0
	IFD DEBUG_COLORS
	move.w                                        #$00F0,$dff180
	ENDIF
	rts



; ammx_fill_table_single_line - Fills a single line according to the fill table into screens
; Input:
;	- d6.w : left X (0-319)
;	- d7.w : right X (0-319)
;	- d1.w : line number (0-255)
;
; Defines:
; - USE_CLIPPING
;
; Trashes: nothing
ammx_fill_table_single_line_bpl0:
	movem.l d0-d7/a0,-(sp) ; stack save

	; d5 => totalcount
	; d3 / d4 => tmp

	; d6 => left X
	; d7 => right X

	move.w d7,d5 ; alternative to psubw
	sub.w d6,d5
	IFD USE_CLIPPING
	bmi.w ammx_fill_table_no_end_0_bpl0 ; if Xright<0 we are sure that no pixel must be drawn so jump to whatever exit
	ENDIF
	addq #1,d5

	; align to nearest byte
	; address of the first point
	lea PLOTREFS,a0

	add.w d1,d1
	move.w 0(a0,d1.w),d1
	move.w d6,d2
	lsr.w #3,d2
	add.w d2,d1
	
	; d1.w now has the address of the first byte let's calculate the fill for this byte
	move.w d6,d4
	andi.w #$0007,d4
	move.b #$FF,d3
	lsr.b d4,d3

	move.l SCREEN_PTR_0,a0
	add.w d1,a0

	; bitprocessed = 8-d4
	subi.b #8,d4 ; d4 must always be negative here!!!!
	ext.w d4
	add.w d4,d5 ; totalcount must be decremented by written bits (susing add because d4 is always negative)
	
	; special case -  if d5 is negative we plotted too much
	bpl.s ammx_fill_table_no_special_case_bpl0
    subq #1,d5
	not d5
	lsr.b d5,d3
	lsl.b d5,d3

	or.b d3,(a0)+ ; Plot points!!
ammx_fill_table_no_special_0_bpl0:
	movem.l (sp)+,d0-d7/a0
	rts

ammx_fill_table_no_special_case_bpl0:
    ; end special case
    
    or.b d3,(a0) ; Plot points!!
ammx_fill_table_no_firstbyte_0_bpl0:
	addq #1,a0

; start iteration until we are at the end
ammx_fill_table_startiter_bpl0:

	; now we are byte aligned, evaluate how many bits we still have to fill
	cmpi.w #64,d5
	bcs.w ammx_fill_table_no64_bpl0 ; branch if lower (it will continue if we have at least 64 bits to fill)

	; here starts the code to fill 64 bits
	IFD VAMPIRE
	POR 256*40(a0),e1,e6
	STORE e6,256*40(a0)
	POR (a0),e0,e6
	STORE e6,(a0)+
	ENDIF
	IFND VAMPIRE
	
	move.l a0,d0
	btst #0,d0
	beq.s ammx_fill_table_64_even_bpl0


	or.b d7,(a0)+
	or.l d7,(a0)+
    or.w d7,(a0)+
    or.b d7,(a0)+

    subi.w #64,d5
	bne.s ammx_fill_table_startiter_bpl0
	movem.l (sp)+,d0-d7/a0
	rts
 ammx_fill_table_64_even_bpl0:



	or.l  d7,(a0)+
	or.l  d7,(a0)+

	subi.w #64,d5
	bne.s ammx_fill_table_startiter_bpl0
	movem.l (sp)+,d0-d7/a0
	rts
	ENDIF
	
	subi.w #64,d5
	bne.s ammx_fill_table_startiter_bpl0
	movem.l (sp)+,d0-d7/a0
	rts
ammx_fill_table_no64_bpl0:
	cmpi.w #32,d5
	bcs.w ammx_fill_table_no32_bpl0 ; branch if lower (it will continue if we have at least 32 bits to fill)

	IFD VAMPIRE

	vperm #$00000000,e0,e0,d0
	or.l d0,(a0)+ ; first bitplane
	subi.w #32,d5
	bne.w ammx_fill_table_startiter_bpl0
	movem.l (sp)+,d0-d7/a0
	rts
	ENDIF
	
	IFND VAMPIRE
	
	move.l a0,d0
	btst #0,d0
	beq.s ammx_fill_table_32_even_bpl0
	


	or.b d7,(a0)+
    or.w d7,(a0)+
    or.b d7,(a0)+

    subi.w #32,d5
	bne.w ammx_fill_table_startiter_bpl0
	movem.l (sp)+,d0-d7/a0
	rts
 ammx_fill_table_32_even_bpl0:
	or.l  d7,(a0)+

	subi.w #32,d5
	bne.w ammx_fill_table_startiter_bpl0
	movem.l (sp)+,d0-d7/a0
	rts

	ENDIF
	
ammx_fill_table_no32_bpl0:
	cmpi.w #16,d5
	bcs.w ammx_fill_table_no16_bpl0 ; branch if lower (it will continue if we have at least 16 bits to fill)
	
	IFD VAMPIRE

	vperm #$00000000,e0,e0,d0
	or.w d0,(a0)+ ; first bitplane
	subi.w #16,d5
	bne.w ammx_fill_table_startiter_bpl0
	movem.l (sp)+,d0-d7/a0
	rts
	ENDIF
	
	IFND VAMPIRE
	move.l a0,d0
	btst #0,d0
	beq.s ammx_fill_table_16_even_bpl0

	or.b d7,(a0)+
    or.b d7,(a0)+

    subi.w #16,d5
	bne.w ammx_fill_table_startiter_bpl0
	movem.l (sp)+,d0-d7/a0
	rts
 ammx_fill_table_16_even_bpl0:
	or.w  d7,(a0)+

	subi.w #16,d5
	bne.w ammx_fill_table_startiter_bpl0
	movem.l (sp)+,d0-d7/a0
	rts
	ENDIF
	
ammx_fill_table_no16_bpl0:

	cmpi.w #8,d5
	bcs.w ammx_fill_table_no8_bpl0 ; branch if lower (it will continue if we have at least 8 bits to fill)
	IFD VAMPIRE
	vperm #$00000000,e0,e0,d0
	or.b d0,(a0)+ ; first bitplane
	ENDIF

	IFND VAMPIRE
	or.b  d7,(a0)+
	ENDIF

	subi.w #8,d5
	bne.w ammx_fill_table_startiter_bpl0
	movem.l (sp)+,d0-d7/a0
	rts
ammx_fill_table_no8_bpl0:

	; we get here only and only if there is less then a byte to fill, in other words, d5<8
	; in this case we must fill the MSG bytes of the byte wit a 1
	;move.b #$FF,d3
	moveq #8,d4
	sub.w d5,d4
	IFD VAMPIRE
	vperm #$00000000,e1,e1,d6
	vperm #$00000000,e0,e0,d7
	ENDC
	lsl.b d4,d6
	lsl.b d4,d7

	or.b d7,(a0)
ammx_fill_table_no_end_0_bpl0
	movem.l (sp)+,d0-d7/a0
	rts

	; if we still have bit to fill repeat the process
ammx_fill_table_check_if_other_bpl0: ;
	cmpi.w #0,d5
	bhi.w ammx_fill_table_startiter_bpl0

	movem.l (sp)+,d0-d7/a0
	rts

  ENDIF