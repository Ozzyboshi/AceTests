

MATRIX_STACK_START:
	dcb.b 24*256,$00
MATRIX_STACK_END:

MATRIX_STACK_PTR: dc.l MATRIX_STACK_START

CURRENT_TRANSFORMATION_MATRIX:
    dc.w 0000,$0040,0000,0000
    dc.w 0000,0000,$0040,0000
    dc.w 0000,0000,0000,$0040

;TRANSFORMATIONS_PTR:
;    dc.l TRANSFORMATIONS_MATRIX

AMMX_DUMP_TRANSFORMATION_MATRIX_TO_RAM_OP1 MACRO
	lea OPERATOR1_TR_MATRIX_ROW1,b0
	store \1,(b0)+
	store \2,(b0)+
	store \3,(b0)+
	ENDM

AMMX_DUMP_TRANSFORMATION_MATRIX_TO_RAM_OP2 MACRO
	lea OPERATOR2_TR_MATRIX_ROW1,b0
	store \1,(b0)+
	store \2,(b0)+
	store \3,(b0)+
	ENDM

;AMMX_DUMP_THIRD_OP_TO_RAM_OP1 MACRO
AMMX_DUMP_REGS_TO_THIRD_OP MACRO
	lea OPERATOR3_TR_MATRIX_ROW1,b0
	store \1,(b0)+
	store \2,(b0)+
	store \3,(b0)+
ENDM

AMMX_DUMP_THIRD_OP_TO_TR_MATRIX MACRO
	lea CURRENT_TRANSFORMATION_MATRIX,b0
	store \1,(b0)+
	store \2,(b0)+
	store \3,(b0)+
ENDM

RESET_MATRIX_STACK MACRO
	; reset matrix stack
	move.l #MATRIX_STACK_START,MATRIX_STACK_PTR
	ENDM

LOADIDENTITY MACRO
	IFD VAMPIRE
	lea CURRENT_TRANSFORMATION_MATRIX,b0
	REG_LOADI 0000,0040,0000,0000,e0
    store e0,(b0)+
	REG_LOADI 0000,0000,0040,0000,e0
    store e0,(b0)+
	REG_LOADI 0000,0000,0000,0040,e0
    store e0,(b0)+
	ENDIF
	IFND VAMPIRE
	lea CURRENT_TRANSFORMATION_MATRIX,a0
	move.l #$00000040,(a0)+
	move.l #$00000000,(a0)+
	move.l #$00000000,(a0)+
	move.l #$00400000,(a0)+
	move.l #$00000000,(a0)+
	move.l #$00000040,(a0)+
	ENDIF
	ENDM

	IFD USE_3D
LOADIDENTITY3D MACRO
	IFD VAMPIRE
	lea CURRENT_TRANSFORMATION_MATRIX,b0
	REG_LOADI 0000,0040,0000,0000,e0
    store e0,(b0)+
	REG_LOADI 0000,0000,0040,0000,e0
    store e0,(b0)+
	REG_LOADI 0000,D800,E000,C880,e0
    store e0,(b0)+
	ENDIF
	IFND VAMPIRE
	lea CURRENT_TRANSFORMATION_MATRIX,a0
	move.l #$00000040,(a0)+
	move.l #$00000000,(a0)+
	move.l #$00000000,(a0)+
	move.l #$00400000,(a0)+
	move.l #$0000D800,(a0)+
	move.l #$E000C880,(a0)+
	ENDIF
	ENDM
	ENDIF

RESETMATRIX MACRO
	RESET_CURRENT_TRANSFORMATION_MATRIX_Q_10_6
	ENDM

RESET_CURRENT_TRANSFORMATION_MATRIX_Q_10_6 MACRO
	RESET_MATRIX_STACK
	IFD VAMPIRE
	lea CURRENT_TRANSFORMATION_MATRIX,b0
	REG_LOADI 0000,0040,0000,0000,e0
    store e0,(b0)+
	REG_LOADI 0000,0000,0040,0000,e0
    store e0,(b0)+
	REG_LOADI 0000,0000,0000,0040,e0
    store e0,(b0)+
	ENDIF
	IFND VAMPIRE
	lea CURRENT_TRANSFORMATION_MATRIX,a0
	move.l #$00000040,(a0)+
	move.l #$00000000,(a0)+
	move.l #$00000000,(a0)+
	move.l #$00400000,(a0)+
	move.l #$00000000,(a0)+
	move.l #$00000040,(a0)+
	ENDIF
	ENDM

MULT_ROW_Q_10_6 MACRO
	pmull d0,d1,d2
	pmulh d0,d1,d3

	; recompose full 32 bit number
	vperm #$CD45EF67,d2,d3,d4
	dc.w $fe3c,$4739,$0000,$0000,$0000,$0006 ;LSR.Q  #11,d4,d7

	vperm #$8901AB23,d2,d3,d4
	dc.w $fe3c,$4639,$0000,$0000,$0000,$0006 ;LSR.Q  #11,d4,d6

	paddw d6,d7,d5
	vperm #$23232323,d5,d5,\1
	add.w d5,\1 ; final result in the lowest word of output reg
	
	ENDM

MULT_ROW_Q_5_11 MACRO
	pmull d0,d1,d2
	pmulh d0,d1,d3

	; recompose full 32 bit number
	vperm #$CD45EF67,d2,d3,d4
	dc.w $fe3c,$4739,$0000,$0000,$0000,$00B ;LSR.Q  #11,d4,d7

	vperm #$8901AB23,d2,d3,d4
	dc.w $fe3c,$4639,$0000,$0000,$0000,$00B ;LSR.Q  #11,d4,d6

	paddw d6,d7,d5
	vperm #$23232323,d5,d5,\1
	add.w d5,\1 ; final result in the lowest word of output reg
	ENDM


OPERATOR1_TRANSFORMATION_MATRIX:
OPERATOR1_TR_MATRIX_ROW1:
OPERATOR1_TR_MATRIX_ROW1_WORD0:
	dc.w 0
OPERATOR1_TR_MATRIX_ROW1_WORD1:
	dc.w 0
OPERATOR1_TR_MATRIX_ROW1_WORD2:
	dc.w 0
OPERATOR1_TR_MATRIX_ROW1_WORD3:
	dc.w 0

OPERATOR1_TR_MATRIX_ROW2:
OPERATOR1_TR_MATRIX_ROW2_WORD0:
	dc.w 0
OPERATOR1_TR_MATRIX_ROW2_WORD1:
	dc.w 0
OPERATOR1_TR_MATRIX_ROW2_WORD2:
	dc.w 0
OPERATOR1_TR_MATRIX_ROW2_WORD3:
	dc.w 0

OPERATOR1_TR_MATRIX_ROW3:
OPERATOR1_TR_MATRIX_ROW3_WORD0:
	dc.w 0
OPERATOR1_TR_MATRIX_ROW3_WORD1:
	dc.w 0
OPERATOR1_TR_MATRIX_ROW3_WORD2:
	dc.w 0
OPERATOR1_TR_MATRIX_ROW3_WORD3:
	dc.w 0

OPERATOR2_TRANSFORMATION_MATRIX:
OPERATOR2_TR_MATRIX_ROW1:
OPERATOR2_TR_MATRIX_ROW1_WORD0:
	dc.w 0
OPERATOR2_TR_MATRIX_ROW1_WORD1:
	dc.w 0
OPERATOR2_TR_MATRIX_ROW1_WORD2:
	dc.w 0
OPERATOR2_TR_MATRIX_ROW1_WORD3:
	dc.w 0

OPERATOR2_TR_MATRIX_ROW2:
OPERATOR2_TR_MATRIX_ROW2_WORD0:
	dc.w 0
OPERATOR2_TR_MATRIX_ROW2_WORD1:
	dc.w 0
OPERATOR2_TR_MATRIX_ROW2_WORD2:
	dc.w 0
OPERATOR2_TR_MATRIX_ROW2_WORD3:
	dc.w 0

OPERATOR2_TR_MATRIX_ROW3:
OPERATOR2_TR_MATRIX_ROW3_WORD0:
	dc.w 0
OPERATOR2_TR_MATRIX_ROW3_WORD1:
	dc.w 0
OPERATOR2_TR_MATRIX_ROW3_WORD2:
	dc.w 0
OPERATOR2_TR_MATRIX_ROW3_WORD3:
	dc.w 0

OPERATOR3_TRANSFORMATION_MATRIX:
OPERATOR3_TR_MATRIX_ROW1:
OPERATOR3_TR_MATRIX_ROW1_WORD0:
	dc.w 0
OPERATOR3_TR_MATRIX_ROW1_WORD1:
	dc.w 0
OPERATOR3_TR_MATRIX_ROW1_WORD2:
	dc.w 0
OPERATOR3_TR_MATRIX_ROW1_WORD3:
	dc.w 0

OPERATOR3_TR_MATRIX_ROW2:
OPERATOR3_TR_MATRIX_ROW2_WORD0:
	dc.w 0
OPERATOR3_TR_MATRIX_ROW2_WORD1:
	dc.w 0
OPERATOR3_TR_MATRIX_ROW2_WORD2:
	dc.w 0
OPERATOR3_TR_MATRIX_ROW2_WORD3:
	dc.w 0

OPERATOR3_TR_MATRIX_ROW3:
OPERATOR3_TR_MATRIX_ROW3_WORD0:
	dc.w 0
OPERATOR3_TR_MATRIX_ROW3_WORD1:
	dc.w 0
OPERATOR3_TR_MATRIX_ROW3_WORD2:
	dc.w 0
OPERATOR3_TR_MATRIX_ROW3_WORD3:
	dc.w 0


ROTATE_INV_Q_5_11 MACRO

	andi.l #$0000FFFF,d0
	andi.l #$0000FFFF,d1

	IFD VAMPIRE
	; Current transformation matrix is the Multiplier (second factor)
	LOAD_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6

	; read angle from input and load trig data
	move.w \1,d0
	lea ROT_Z_MATRIX_Q5_11,b1   ; Cos and -SIN SIN COS in b1
	LOAD (b1,D0.w*8),E10 ; Load precalculated sin/cos values to register E10

	; Rotation matrix is the Multiplicand
	REG_ZERO e21
    vperm  #$FF0123FF,e10,e21,e1     ; first  row of the matrix  0 cos -sin 0
    vperm  #$FF4567FF,e10,e21,e2     ; second row of the matrix  0 sin  cos 0
	REG_LOADI 0000,0000,0000,0800,e3 ; NOTE!!!!!!!!!!, last word must be 1* table multiplier!!!!
	; end loading matrix

	UPDATE_CURRENT_TRANSFORMATION_MATRIX e13,e14,e15
	ENDIF

	IFND VAMPIRE
	LOAD_CURRENT_TRANSFORMATION_MATRIX OPERATOR2_TR_MATRIX_ROW1

	move.w \1,d0
	lea ROT_Z_MATRIX_Q5_11,a0
	lsl.w #3,d0
	add.l d0,a0
	move.w #$0000,OPERATOR1_TR_MATRIX_ROW1
	move.l (a0)+,OPERATOR1_TR_MATRIX_ROW1+2
	move.w #$0000,OPERATOR1_TR_MATRIX_ROW1+6

	move.w #$0000,OPERATOR1_TR_MATRIX_ROW2
	move.l (a0)+,OPERATOR1_TR_MATRIX_ROW2+2
	move.w #$0000,OPERATOR1_TR_MATRIX_ROW2+6

	move.l #$00000000,OPERATOR1_TR_MATRIX_ROW3
	move.l #$00000800,OPERATOR1_TR_MATRIX_ROW3+4

	ENDIF

	jsr ammxmatrixmul3X3_q5_11

	IFD VAMPIRE
	UPDATE_CURRENT_TRANSFORMATION_MATRIX e13,e14,e15
	ENDIF
	IFND VAMPIRE
	lea CURRENT_TRANSFORMATION_MATRIX,a0
	move.l OPERATOR3_TR_MATRIX_ROW1,(a0)+
	move.l OPERATOR3_TR_MATRIX_ROW1+4,(a0)+

	move.l OPERATOR3_TR_MATRIX_ROW2,(a0)+
	move.l OPERATOR3_TR_MATRIX_ROW2+4,(a0)+

	move.l OPERATOR3_TR_MATRIX_ROW3,(a0)+
	move.l OPERATOR3_TR_MATRIX_ROW3+4,(a0)+
	ENDIF

	ENDM

ROTATE_X_INV_Q_5_11 MACRO

	andi.l #$0000FFFF,d0
	andi.l #$0000FFFF,d1

	IFD VAMPIRE
	; Current transformation matrix is the Multiplier (second factor)
	LOAD_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6

	; read angle from input and load trig data
	move.w \1,d0
	lea ROT_Z_MATRIX_Q5_11,b1   ; Cos and -SIN SIN COS in b1
	LOAD (b1,D0.w*8),E10 ; Load precalculated sin/cos values to register E10

	; Rotation matrix is the Multiplicand
	REG_ZERO e21
	REG_LOADI 0000,0800,0000,0000,e1 ; NOTE!!!!!!!!!!, first word must be 1* table multiplier!!!!
    vperm  #$FFFF0123,e10,e21,e2     ; first  row of the matrix  0 cos -sin 0
    vperm  #$FFFF4567,e10,e21,e3     ; second row of the matrix  0 sin  cos 0
	; end loading matrix

	UPDATE_CURRENT_TRANSFORMATION_MATRIX e13,e14,e15
	ENDIF

	IFND VAMPIRE
	LOAD_CURRENT_TRANSFORMATION_MATRIX OPERATOR2_TR_MATRIX_ROW1

	move.w \1,d0
	lea ROT_Z_MATRIX_Q5_11,a0
	lsl.w #3,d0
	add.l d0,a0

	move.l #$00000800,OPERATOR1_TR_MATRIX_ROW1
	move.l #$00000000,OPERATOR1_TR_MATRIX_ROW1+4

	move.l #$00000000,OPERATOR1_TR_MATRIX_ROW2
	move.w (a0)+,OPERATOR1_TR_MATRIX_ROW2+4
	move.w (a0)+,OPERATOR1_TR_MATRIX_ROW2+6

	move.l #$00000000,OPERATOR1_TR_MATRIX_ROW3
	move.w (a0)+,OPERATOR1_TR_MATRIX_ROW3+4
	move.w (a0)+,OPERATOR1_TR_MATRIX_ROW3+6

	ENDIF

	jsr ammxmatrixmul3X3_q5_11

	IFD VAMPIRE
	UPDATE_CURRENT_TRANSFORMATION_MATRIX e13,e14,e15
	ENDIF
	IFND VAMPIRE
	lea CURRENT_TRANSFORMATION_MATRIX,a0
	move.l OPERATOR3_TR_MATRIX_ROW1,(a0)+
	move.l OPERATOR3_TR_MATRIX_ROW1+4,(a0)+

	move.l OPERATOR3_TR_MATRIX_ROW2,(a0)+
	move.l OPERATOR3_TR_MATRIX_ROW2+4,(a0)+

	move.l OPERATOR3_TR_MATRIX_ROW3,(a0)+
	move.l OPERATOR3_TR_MATRIX_ROW3+4,(a0)+
	ENDIF

	ENDM

ROTATE MACRO \1
	ROTATE_INV_Q_5_11 \1
	ENDM


TRANSLATE_INV_Q_10_6 MACRO
	IFD VAMPIRE
	LOAD_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6
	REG_LOADI 0000,0040,0000,0000,e1  ; 0 1 0 0
    REG_LOADI 0000,0000,0040,0000,e2  ; 0 0 1 0
	move.w \1,d0
    move.l #$0040FFFF,d1
    move.w \2,d1
	vperm #$8867EFCD,d0,d1,e3
	ENDIF
	IFND VAMPIRE
	LOAD_CURRENT_TRANSFORMATION_MATRIX OPERATOR2_TR_MATRIX_ROW1
	move.l #$00000040,OPERATOR1_TR_MATRIX_ROW1
	move.l #$00000000,OPERATOR1_TR_MATRIX_ROW1+4
	move.l #$00000000,OPERATOR1_TR_MATRIX_ROW2
	move.l #$00400000,OPERATOR1_TR_MATRIX_ROW2+4
	move.w #$0000,OPERATOR1_TR_MATRIX_ROW3
	move.w \1,OPERATOR1_TR_MATRIX_ROW3+2
	move.w \2,OPERATOR1_TR_MATRIX_ROW3+4
	move.w #$0040,OPERATOR1_TR_MATRIX_ROW3+6
	ENDIF
	bsr.w ammxmatrixmul3X3_q10_6
	IFD VAMPIRE
	UPDATE_CURRENT_TRANSFORMATION_MATRIX e13,e14,e15
	ENDIF
	IFND VAMPIRE
	lea CURRENT_TRANSFORMATION_MATRIX,a0
	move.l OPERATOR3_TR_MATRIX_ROW1,(a0)+
	move.l OPERATOR3_TR_MATRIX_ROW1+4,(a0)+

	move.l OPERATOR3_TR_MATRIX_ROW2,(a0)+
	move.l OPERATOR3_TR_MATRIX_ROW2+4,(a0)+

	move.l OPERATOR3_TR_MATRIX_ROW3,(a0)+
	move.l OPERATOR3_TR_MATRIX_ROW3+4,(a0)+
	ENDIF
	ENDM


LOAD_CURRENT_TRANSFORMATION_MATRIX MACRO
	IFD VAMPIRE
	lea CURRENT_TRANSFORMATION_MATRIX,b0
    LOAD (b0)+,\1
    LOAD (b0)+,\2
    LOAD (b0),\3
	ENDIF
	IFND VAMPIRE
	move.l CURRENT_TRANSFORMATION_MATRIX,\1
	move.l CURRENT_TRANSFORMATION_MATRIX+4,\1+4
	move.l CURRENT_TRANSFORMATION_MATRIX+8,\1+8
	move.l CURRENT_TRANSFORMATION_MATRIX+12,\1+12
	move.l CURRENT_TRANSFORMATION_MATRIX+16,\1+16
	move.l CURRENT_TRANSFORMATION_MATRIX+20,\1+20
	ENDIF
	ENDM

UPDATE_CURRENT_TRANSFORMATION_MATRIX MACRO
	IFD VAMPIRE
	lea CURRENT_TRANSFORMATION_MATRIX,b0
    store \1,(b0)+
	store \2,(b0)+
	store \3,(b0)+
	ENDIF
	IFND VAMPIRE
	lea CURRENT_TRANSFORMATION_MATRIX,a0
	move.l \1,(a0)+
	move.l \1+4,(a0)+

	move.l \2,(a0)+
	move.l \2+4,(a0)+

	move.l \3,(a0)+
	move.l \3+4,(a0)+

	ENDIF
	ENDM

; Saves current transformation matrix into the MATRIX STACK
PUSHMATRIX MACRO
	movea.l MATRIX_STACK_PTR,a2
	IFD VAMPIRE
	lea CURRENT_TRANSFORMATION_MATRIX,b0
	load (b0)+,e0
	store e0,(a2)+
	load (b0)+,e0
	store e0,(a2)+
	load (b0)+,e0
	store e0,(a2)+
	ENDIF
	IFND VAMPIRE
	move.l CURRENT_TRANSFORMATION_MATRIX,(a2)+
	move.l CURRENT_TRANSFORMATION_MATRIX+4,(a2)+
	move.l CURRENT_TRANSFORMATION_MATRIX+8,(a2)+
	move.l CURRENT_TRANSFORMATION_MATRIX+12,(a2)+
	move.l CURRENT_TRANSFORMATION_MATRIX+16,(a2)+
	move.l CURRENT_TRANSFORMATION_MATRIX+20,(a2)+
	ENDIF
	move.l a2,MATRIX_STACK_PTR
	ENDM

; restore matrix stack transformation matrix into transformation matrix
POPMATRIX MACRO
	movea.l MATRIX_STACK_PTR,a2
	suba.l #24,a2
	move.l a2,MATRIX_STACK_PTR

	IFD VAMPIRE
	lea CURRENT_TRANSFORMATION_MATRIX,b0
	load (a2)+,e0
	store e0,(b0)+
	load (a2)+,e0
	store e0,(b0)+
	load (a2),e0
	store e0,(b0)
	ENDIF

	IFND VAMPIRE
	lea CURRENT_TRANSFORMATION_MATRIX,a0
	move.l (a2)+,(a0)+
	move.l (a2)+,(a0)+

	move.l (a2)+,(a0)+
	move.l (a2)+,(a0)+

	move.l (a2)+,(a0)+
	move.l (a2)+,(a0)+
	ENDIF
	ENDM
	

; INPUT (LOAD BEFORE USING IT)
; MATRIX 1 data must be put on e1,e2,e3
; MATRIX 2 data must be put on e4,e5,d6
ammxmatrixmul3X3_q10_6:
	movem.l d0-d7/a0-a6,-(sp) ; stack save

	IFD VAMPIRE

    REG_ZERO e21

	; start of matrix rotation - output to e7 e8 a9
	
	; START OF FIRST ROW
	vperm #$67EF67EF,e5,e6,e7; 1st row (e5 last word - e6 last word - e5 last word - e6 last word)
	vperm #$6767CDEF,e4,e7,e7 ; end of first row, e4 inserted in first 2 words
	; END OF FIRST ROW

	; START OF SECOND ROW
	vperm #$45CD45CD,e5,e6,e8; 2st row (e5 middle right word - e6 middle right word - e5 middle right word - e6 middle right word)
	vperm #$4545CDEF,e4,e8,e8 ; end of second row, e4 inserted in first 2 words
	; END OF SECOND ROW

	; START OF THIRD ROW;
	vperm #$23AB23AB,e5,e6,e9; 3dr row (e5 middle left word - e6 middle left word - e5 middle left word - e6 middle left word)
	vperm #$2323CDEF,e4,e9,e9 ; end of third row, e4 inserted in first 2 words
	; END OF THIRD ROW

	; start of matrix multiplication

	; multiply first row of the first matrix with last row of the second matrix output in e13 left middle word
	LOAD e1,d0
	LOAD e9,d1
	MULT_ROW_Q_10_6 d0
	vperm #$00EF0000,e21,d0,e13

	; multiply second row of the first matrix with last row of the second matrix output in e14 left middle word
	LOAD e2,d0
	LOAD e9,d1
	MULT_ROW_Q_10_6 d0
	vperm #$00EF0000,e21,d0,e14

	; multiply first row of the first matrix with middle row of the second matrix output in e13 right middle word
	LOAD e1,d0
	LOAD e8,d1
	MULT_ROW_Q_10_6 d0
	vperm #$0123EF67,e13,d0,e13

	; multiply third row of the first matrix with last row of the second matrix output in e15 left middle word
	LOAD e3,d0
	LOAD e9,d1
	MULT_ROW_Q_10_6 d0
	vperm #$00EF0000,e21,d0,e15

	; multiply middle row of the first matrix with middle row of the second matrix output in e14 right middle word
	LOAD e2,d0
	LOAD e8,d1
	MULT_ROW_Q_10_6 d0
	vperm #$0123EF67,e14,d0,e14

	; multiply first row of the first matrix with first row if the second matrix output in e13 right word
	LOAD e1,d0
	LOAD e7,d1
	MULT_ROW_Q_10_6 d0
	vperm #$012345EF,e13,d0,e13

	; multiply second row of the first matrix with first row of the second matrix output in e14 right word
	LOAD e2,d0
	LOAD e7,d1
	MULT_ROW_Q_10_6 d0
	vperm #$012345EF,e14,d0,e14

	; multiply third row of the first matrix with middle row of the second matrix output in e15  right middle word
	LOAD e3,d0
	LOAD e8,d1
	MULT_ROW_Q_10_6 d0
	vperm #$0123EF67,e15,d0,e15

	; multiply third row of the first matrix with first row of the second matrix output in e15 right word
	LOAD e3,d0
	LOAD e7,d1
	MULT_ROW_Q_10_6 d0
	vperm #$012345EF,e15,d0,e15

	ENDIF

	IFND VAMPIRE
	   
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD1,d0
	lsr.l #6,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD1,d1
	lsr.l #6,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD1,d2
	lsr.l #6,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW1_WORD1
	
	
	; start of second pass
	move.w OPERATOR1_TR_MATRIX_ROW2_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD1,d0
	lsr.l #6,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW2_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD1,d1
	lsr.l #6,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW2_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD1,d2
	lsr.l #6,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW2_WORD1
	
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD2,d0
	lsr.l #6,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD2,d1
	lsr.l #6,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD2,d2
	lsr.l #6,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW1_WORD2

    ; end of second pass

	
    ; start of third pass
    move.w OPERATOR1_TR_MATRIX_ROW3_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD1,d0
	lsr.l #6,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW3_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD1,d1
	lsr.l #6,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW3_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD1,d2
	lsr.l #6,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW3_WORD1
	
	
	
	
	move.w OPERATOR1_TR_MATRIX_ROW2_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD2,d0
	lsr.l #6,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW2_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD2,d1
	lsr.l #6,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW2_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD2,d2
	lsr.l #6,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW2_WORD2
	
	
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD3,d0
	lsr.l #6,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD3,d1
	lsr.l #6,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD3,d2
	lsr.l #6,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW1_WORD3
    
    ;end of third pass
    
    ; start of 4th pass
    move.w OPERATOR1_TR_MATRIX_ROW2_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD3,d0
	lsr.l #6,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW2_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD3,d1
	lsr.l #6,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW2_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD3,d2
	lsr.l #6,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW2_WORD3

    
    move.w OPERATOR1_TR_MATRIX_ROW3_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD2,d0
	lsr.l #6,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW3_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD2,d1
	lsr.l #6,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW3_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD2,d2
	lsr.l #6,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW3_WORD2

	
	; end of 4th pass
	
	; starto of 5th pass
	move.w OPERATOR1_TR_MATRIX_ROW3_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD3,d0
	lsr.l #6,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW3_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD3,d1
	lsr.l #6,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW3_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD3,d2
	lsr.l #6,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW3_WORD3

	ENDIF

    movem.l (sp)+,d0-d7/a0-a6
    rts

; INPUT (LOAD BEFORE USING IT)
; MATRIX 1 data must be put on e1
; MATRIX 2 data must be put on e4,e5,d6
; OUTPUT inside E13
ammxmatrixmul1X3_q10_6:
	movem.l d0-d7/a0-a6,-(sp) ; stack save
    
    IFD VAMPIRE
	
	REG_ZERO e21 ; zero register
	REG_ZERO e2
	REG_ZERO e3

	; START OF FIRST ROW
	vperm #$67EF67EF,e5,e6,e7; 1st row (e5 last word - e6 last word - e5 last word - e6 last word)
	vperm #$6767CDEF,e4,e7,e7 ; end of first row, e4 inserted in first 2 words
	; END OF FIRST ROW

	; START OF SECOND ROW
	vperm #$45CD45CD,e5,e6,e8; 2st row (e5 middle right word - e6 middle right word - e5 middle right word - e6 middle right word)
	vperm #$4545CDEF,e4,e8,e8 ; end of second row, e4 inserted in first 2 words
	; END OF SECOND ROW

	; START OF THIRD ROW;
	vperm #$23AB23AB,e5,e6,e9; 3dr row (e5 middle left word - e6 middle left word - e5 middle left word - e6 middle left word)
	vperm #$2323CDEF,e4,e9,e9 ; end of third row, e4 inserted in first 2 words
	; END OF THIRD ROW

	; start of matrix multiplication

	; multiply first row of the first matrix with last row of the second matrix output in e13 left middle word
	LOAD e1,d0
	LOAD e9,d1
	MULT_ROW_Q_10_6 d0
	vperm #$00EF0000,e21,d0,e13

	; multiply first row of the first matrix with middle row of the second matrix output in e13 right middle word
	LOAD e1,d0
	LOAD e8,d1
	MULT_ROW_Q_10_6 d0
	vperm #$0123EF67,e13,d0,e13

	; multiply first row of the first matrix with first row if the second matrix output in e13 right word
	LOAD e1,d0
	LOAD e7,d1
	MULT_ROW_Q_10_6 d0
	vperm #$012345EF,e13,d0,e13

	REG_ZERO e14
	REG_ZERO e15
	ENDIF

	IFND VAMPIRE
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD1,d0
	lsr.l #6,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD1,d1
	lsr.l #6,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD1,d2
	lsr.l #6,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW1_WORD1
	
	
	; start of second pass
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD2,d0
	lsr.l #6,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD2,d1
	lsr.l #6,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD2,d2
	lsr.l #6,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW1_WORD2

    ; end of second pass

	
    ; start of third pass
	
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD3,d0
	lsr.l #6,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD3,d1
	lsr.l #6,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD3,d2
	lsr.l #6,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW1_WORD3
    
    ;end of third pass

	move.l #$00000000,OPERATOR3_TR_MATRIX_ROW2_WORD0
	move.l #$00000000,OPERATOR3_TR_MATRIX_ROW2_WORD2

	move.l #$00000000,OPERATOR3_TR_MATRIX_ROW3_WORD0
	move.l #$00000000,OPERATOR3_TR_MATRIX_ROW3_WORD2
    
	ENDIF

	movem.l (sp)+,d0-d7/a0-a6
    rts

; INPUT (LOAD BEFORE USING IT)
; MATRIX 1 data must be put on e1,e2,e3 (todo)
; MATRIX 2 data must be put on e4,e5,d6
ammxmatrixmul3X3_q5_11:
	movem.l d0-d7/a0-a6,-(sp) ; stack save

	IFD VAMPIRE

    REG_ZERO e21
	; START OF FIRST ROW
	vperm #$67EF67EF,e5,e6,e7; 1st row (e5 last word - e6 last word - e5 last word - e6 last word)
	vperm #$6767CDEF,e4,e7,e7 ; end of first row, e4 inserted in first 2 words
	; END OF FIRST ROW

	; START OF SECOND ROW
	vperm #$45CD45CD,e5,e6,e8; 2st row (e5 middle right word - e6 middle right word - e5 middle right word - e6 middle right word)
	vperm #$4545CDEF,e4,e8,e8 ; end of second row, e4 inserted in first 2 words
	; END OF SECOND ROW

	; START OF THIRD ROW;
	vperm #$23AB23AB,e5,e6,e9; 3dr row (e5 middle left word - e6 middle left word - e5 middle left word - e6 middle left word)
	vperm #$2323CDEF,e4,e9,e9 ; end of third row, e4 inserted in first 2 words
	; END OF THIRD ROW

	; start of matrix multiplication

	; multiply first row of the first matrix with last row of the second matrix output in e13 left middle word
	;pmull e1,e9,e13
	;REG_ADD_LESS_SIG_3_WORDS e13
	LOAD e1,d0
	LOAD e9,d1
	MULT_ROW_Q_5_11 d0
	vperm #$00EF0000,e21,d0,e13

	; multiply second row of the first matrix with last row of the second matrix output in e14 left middle word
	;pmull e2,e9,e14
	;REG_ADD_LESS_SIG_3_WORDS e14
	LOAD e2,d0
	LOAD e9,d1
	MULT_ROW_Q_5_11 d0
	vperm #$00EF0000,e21,d0,e14

	; multiply first row of the first matrix with middle row of the second matrix output in e13 right middle word
	;pmull e1,e8,e0
	;REG_ADD_LESS_SIG_3_WORDS e0
	LOAD e1,d0
	LOAD e8,d1
	MULT_ROW_Q_5_11 d0
	vperm #$0123EF67,e13,d0,e13

	; multiply third row of the first matrix with last row of the second matrix output in e15 left middle word
	; pmull e3,e9,e15
	;REG_ADD_LESS_SIG_3_WORDS e15
	LOAD e3,d0
	LOAD e9,d1
	MULT_ROW_Q_5_11 d0
	vperm #$00EF0000,e21,d0,e15

	; multiply middle row of the first matrix with middle row of the second matrix output in e14 right middle word
	;pmull e2,e8,e0
	;REG_ADD_LESS_SIG_3_WORDS e0
	LOAD e2,d0
	LOAD e8,d1
	MULT_ROW_Q_5_11 d0
	vperm #$0123EF67,e14,d0,e14

	; multiply first row of the first matrix with first row if the second matrix output in e13 right word
	;pmull e1,e7,e0
	;REG_ADD_LESS_SIG_3_WORDS e0
	LOAD e1,d0
	LOAD e7,d1
	MULT_ROW_Q_5_11 d0
	vperm #$012345EF,e13,d0,e13

	; multiply second row of the first matrix with first row of the second matrix output in e14 right word
	;pmull e2,e7,e0
	;REG_ADD_LESS_SIG_3_WORDS e0
	LOAD e2,d0
	LOAD e7,d1
	MULT_ROW_Q_5_11 d0
	vperm #$012345EF,e14,d0,e14

	; multiply third row of the first matrix with middle row of the second matrix output in e15  right middle word
	;pmull e3,e8,e0
	;REG_ADD_LESS_SIG_3_WORDS e0
	LOAD e3,d0
	LOAD e8,d1
	MULT_ROW_Q_5_11 d0
	vperm #$0123EF67,e15,d0,e15

	; multiply third row of the first matrix with first row of the second matrix output in e15 right word
	;pmull e3,e7,e0
	;REG_ADD_LESS_SIG_3_WORDS e0
	LOAD e3,d0
	LOAD e7,d1
	MULT_ROW_Q_5_11 d0
	vperm #$012345EF,e15,d0,e15

	ENDIF

	IFND VAMPIRE

	move.w OPERATOR1_TR_MATRIX_ROW1_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD1,d0
	lsr.l #8,d0
	lsr.l #3,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD1,d1
	lsr.l #8,d1
	lsr.l #3,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD1,d2
	lsr.l #8,d2
	lsr.l #3,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW1_WORD1

	; start of second pass
	move.w OPERATOR1_TR_MATRIX_ROW2_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD1,d0
	lsr.l #8,d0
	lsr.l #3,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW2_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD1,d1
	lsr.l #8,d1
	lsr.l #3,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW2_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD1,d2
	lsr.l #8,d2
	lsr.l #3,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW2_WORD1
	
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD2,d0
	lsr.l #8,d0
	lsr.l #3,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD2,d1
	lsr.l #8,d1
	lsr.l #3,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD2,d2
	lsr.l #8,d2
	lsr.l #3,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW1_WORD2

    ; end of second pass

	; start of third pass
    move.w OPERATOR1_TR_MATRIX_ROW3_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD1,d0
	lsr.l #8,d0
	lsr.l #3,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW3_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD1,d1
	lsr.l #8,d1
	lsr.l #3,d2
	
	move.w OPERATOR1_TR_MATRIX_ROW3_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD1,d2
	lsr.l #8,d2
	lsr.l #3,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW3_WORD1
	
	move.w OPERATOR1_TR_MATRIX_ROW2_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD2,d0
	lsr.l #8,d0
	lsr.l #3,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW2_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD2,d1
	lsr.l #8,d1
	lsr.l #3,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW2_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD2,d2
	lsr.l #8,d2
	lsr.l #3,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW2_WORD2
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD3,d0
	lsr.l #8,d0
	lsr.l #3,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD3,d1
	lsr.l #8,d1
	lsr.l #3,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW1_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD3,d2
	lsr.l #8,d2
	lsr.l #3,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW1_WORD3
    
    ;end of third pass

	; start of 4th pass
    move.w OPERATOR1_TR_MATRIX_ROW2_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD3,d0
	lsr.l #8,d0
	lsr.l #3,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW2_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD3,d1
	lsr.l #8,d1
	lsr.l #3,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW2_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD3,d2
	lsr.l #8,d2
	lsr.l #3,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW2_WORD3

    
    move.w OPERATOR1_TR_MATRIX_ROW3_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD2,d0
	lsr.l #8,d0
	lsr.l #3,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW3_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD2,d1
	lsr.l #8,d1
	lsr.l #3,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW3_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD2,d2
	lsr.l #8,d2
	lsr.l #3,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW3_WORD2

	
	; end of 4th pass
	
	; starto of 5th pass
	move.w OPERATOR1_TR_MATRIX_ROW3_WORD1,d0
	muls.w OPERATOR2_TR_MATRIX_ROW1_WORD3,d0
	lsr.l #8,d0
	lsr.l #3,d0
	
	move.w OPERATOR1_TR_MATRIX_ROW3_WORD2,d1
	muls.w OPERATOR2_TR_MATRIX_ROW2_WORD3,d1
	lsr.l #8,d1
	lsr.l #3,d1
	
	move.w OPERATOR1_TR_MATRIX_ROW3_WORD3,d2
	muls.w OPERATOR2_TR_MATRIX_ROW3_WORD3,d2
	lsr.l #8,d2
	lsr.l #3,d2
	
	add.w d0,d1
	add.w d1,d2
	move.w d2,OPERATOR3_TR_MATRIX_ROW3_WORD3


	ENDIF

    movem.l (sp)+,d0-d7/a0-a6
    rts



; Q_10_6 implementation
; Usage examples : 
;	move.w #60,d0
;	move.w #28,d1
;	bsr.w TRANSLATE
TRANSLATE:
	movem.l d0-d2,-(sp) ; stack save
	IFD VAMPIRE
	LOAD_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6
	REG_LOADI 0000,0040,0000,0000,e1  ; 0 1 0 0
    REG_LOADI 0000,0000,0040,0000,e2  ; 0 0 1 0
	;move.w \1,d0
	lsl.w #6,d0
    move.l #$0040FFFF,d2
    ;move.w \2,d1
	lsl.w #6,d1
	move.w d1,d2
	;move.l d2,d1
	vperm #$CC67EFCD,d0,d2,e3
	ENDIF
	IFND VAMPIRE
	LOAD_CURRENT_TRANSFORMATION_MATRIX OPERATOR2_TR_MATRIX_ROW1
	move.l #$00000040,OPERATOR1_TR_MATRIX_ROW1
	move.l #$00000000,OPERATOR1_TR_MATRIX_ROW1+4
	move.l #$00000000,OPERATOR1_TR_MATRIX_ROW2
	move.l #$00400000,OPERATOR1_TR_MATRIX_ROW2+4
	move.w #$0000,OPERATOR1_TR_MATRIX_ROW3
	;move.w \1,d0
	lsl.w #6,d0
	move.w d0,OPERATOR1_TR_MATRIX_ROW3+2
	;move.w \2,d1
	lsl.w #6,d1
	move.w d1,OPERATOR1_TR_MATRIX_ROW3+4
	move.w #$0040,OPERATOR1_TR_MATRIX_ROW3+6
	ENDIF
	bsr.w ammxmatrixmul3X3_q10_6
	IFD VAMPIRE
	UPDATE_CURRENT_TRANSFORMATION_MATRIX e13,e14,e15
	ENDIF
	IFND VAMPIRE
	lea CURRENT_TRANSFORMATION_MATRIX,a0
	move.l OPERATOR3_TR_MATRIX_ROW1,(a0)+
	move.l OPERATOR3_TR_MATRIX_ROW1+4,(a0)+

	move.l OPERATOR3_TR_MATRIX_ROW2,(a0)+
	move.l OPERATOR3_TR_MATRIX_ROW2+4,(a0)+

	move.l OPERATOR3_TR_MATRIX_ROW3,(a0)+
	move.l OPERATOR3_TR_MATRIX_ROW3+4,(a0)+
	ENDIF
	movem.l (sp)+,d0-d2
	rts

TRANSLATE3D:
	movem.l d0-d2,-(sp) ; stack save
	IFD VAMPIRE
	LOAD_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6
	REG_LOADI 0000,0040,0000,0000,e1  ; 0 1 0 0
    REG_LOADI 0000,0000,0040,0000,e2  ; 0 0 1 0
	;move.w \1,d0
	lsl.w #6,d0
    move.l #$0040FFFF,d3
    ;move.w \2,d1
	lsl.w #6,d1
	lsl.w #6,d2
	move.w d1,d3
	swap d3
	move.w d2,d3
	swap d3
	;move.l d3,d1
	andi.l #$0000FFFF,d0
	vperm #$4567EFCD,d0,d3,e3

	ENDIF
	IFND VAMPIRE
	LOAD_CURRENT_TRANSFORMATION_MATRIX OPERATOR2_TR_MATRIX_ROW1
	move.l #$00000040,OPERATOR1_TR_MATRIX_ROW1
	move.l #$00000000,OPERATOR1_TR_MATRIX_ROW1+4
	move.l #$00000000,OPERATOR1_TR_MATRIX_ROW2
	move.l #$00400000,OPERATOR1_TR_MATRIX_ROW2+4
	move.w #$0000,OPERATOR1_TR_MATRIX_ROW3
	;move.w \1,d0
	lsl.w #6,d0
	move.w d0,OPERATOR1_TR_MATRIX_ROW3+2
	;move.w \2,d1
	lsl.w #6,d1
	move.w d1,OPERATOR1_TR_MATRIX_ROW3+4
	lsl.w #6,d2
	move.w d2,OPERATOR1_TR_MATRIX_ROW3+6
	ENDIF
	bsr.w ammxmatrixmul3X3_q10_6
	IFD VAMPIRE
	UPDATE_CURRENT_TRANSFORMATION_MATRIX e13,e14,e15
	ENDIF
	IFND VAMPIRE
	lea CURRENT_TRANSFORMATION_MATRIX,a0
	move.l OPERATOR3_TR_MATRIX_ROW1,(a0)+
	move.l OPERATOR3_TR_MATRIX_ROW1+4,(a0)+

	move.l OPERATOR3_TR_MATRIX_ROW2,(a0)+
	move.l OPERATOR3_TR_MATRIX_ROW2+4,(a0)+

	move.l OPERATOR3_TR_MATRIX_ROW3,(a0)+
	move.l OPERATOR3_TR_MATRIX_ROW3+4,(a0)+
	ENDIF
	movem.l (sp)+,d0-d2
	rts

processing_first_matrix_addr:
	move.l #OPERATOR1_TRANSFORMATION_MATRIX,d0
	rts

processing_second_matrix_addr:
	move.l #OPERATOR2_TRANSFORMATION_MATRIX,d0
	rts

processing_third_matrix_addr:
	move.l #OPERATOR3_TRANSFORMATION_MATRIX,d0
	rts

processing_current_transformation_matrix_addr:
	move.l #CURRENT_TRANSFORMATION_MATRIX,d0
	rts
    