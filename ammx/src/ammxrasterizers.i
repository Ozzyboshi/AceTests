COORDSBUFFER:
    dc.l 0
    dc.l 0

LINE	MACRO

    lea COORDSBUFFER,a0
    move.w #0000,(a0)+
	move.w \1,(a0)+
    move.w \2,(a0)+
	move.w #0001,(a0)+
    load COORDSBUFFER,e1 ; FIRST MATRIX LOADED


    IFD MATRIX_DEBUG
    move.l par1,a1 
    store e1,(a1)+
    ENDIF

    ; SECOND MATRIX IS ACTUALLY THE CURRENT TRANSFORMATION MATRIX
    LOAD_TRASFORMATION_MATRIX e4,e5,e6

    ; TRANSFORM !!!!!!
    bsr.w ammxmatrixmul1X3

    ; apply transformation on first point (result of transformation is inside e13)
	lea LINEVERTEX_START_FINAL,a1
	vperm #$23452345,e13,e13,d0
    move.l d0,(a1)+

    ; FIRST POINT DONE!!!! START OF SECOND POINT
    lea COORDSBUFFER,a0
    move.w #0000,(a0)+
	move.w \3,(a0)+
    move.w \4,(a0)+
	move.w #0001,(a0)+
    load COORDSBUFFER,e1 ; FIRST MATRIX LOADED

    ; SECOND MATRIX IS ACTUALLY THE CURRENT TRANSFORMATION MATRIX
    LOAD_TRASFORMATION_MATRIX e4,e5,e6

    ; TRANSFORM !!!!!!
    bsr.w ammxmatrixmul1X3

    ; apply transformation on first point (result of transformation is inside e13)
	lea LINEVERTEX_END_FINAL,a1
	vperm #$23452345,e13,e13,d0
    move.l d0,(a1)+

	
    ; start line drawing routine
	load #0000000000000000,e21 ;optimisation
    ;lea LINEVERTEX_START_FINAL,a1
    ;move.l #$0A0A0B0B,(a1)
	bsr.w bresenham_line_draw
	ENDM

; Final round
; - pick lowest x first
; - check if both coords are between screen limits
; - select one of the 4 drawing routines
bresenham_line_draw:
	
	movem.l d0-d6/a0-a6,-(sp) ; stack save
	move.l par1,a1
	lea LINEVERTEX_START_PUSHED,a2
	
	; - pick lowest first x
	move.l LINEVERTEX_START_FINAL,d2
	cmp.l LINEVERTEX_END_FINAL,d2
	blt.s bammxmainloop8_lowestless ;  check if first x is lower if this is the case jump to endammxmainloop8
	move.l LINEVERTEX_START_FINAL,d3
	move.l LINEVERTEX_END_FINAL,d2
	bra.s bendammxmainloop8phase1
bammxmainloop8_lowestless:
	move.l LINEVERTEX_END_FINAL,d3
bendammxmainloop8phase1 : ; end of first check


	; - pick lowest first x end
	move.l d2,(a2)+
	move.l d3,(a2)+

	;move.l d2,(a1)+
	;move.l d3,(a1)+
    ;movem.l (sp)+,d0-d6/a0-a6
	;rts

	; - check if both coords are between screen limits start
	; - check if both coords are between screen limits end

	; select one of the 4 drawing routines start
	PSUBW d2,d3,d4 ; d4 will contain deltas
	PSUBW d3,d2,d5
	pmaxsw  d5,d4,d4
	IFD ASM_DEBUG
	move.l d4,(a1)+
	ENDIF
	vperm #$45454545,d4,d4,d5 ; move xdelta in the less sig word
	; select one of the 4 drawing routines end
	IFD ASM_DEBUG
	move.w d4,(a1)+
	move.w d5,(a1)+
	ENDIF
	cmp.w d5,d4
	blt.s bdylessthan
	IFD ASM_DEBUG
	move.w #2,(a1)+
	ENDIF
	cmp.w d2,d3
	bls.s bgotolessminus1
	;bsr.w linemgreater1		; vertical line
	bra.s bendammxmainloop8phase2
bgotolessminus1:
	;bsr.w linemlessminus1
	bra.s bendammxmainloop8phase2
bdylessthan:
	IFD ASM_DEBUG
	move.w #1,(a1)+
	ENDIF
	cmp.w d2,d3
	bls.s bgoto0tominus1
	bsr.w linem0to1
	bra.s bendammxmainloop8phase2
bgoto0tominus1:
	bsr.w linem0tominus1
bendammxmainloop8phase2:
	movem.l (sp)+,d0-d6/a0-a6
	rts
