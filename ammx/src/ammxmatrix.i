;MATRIX_DEBUG=1

CURRENT_TRANSFORMATION_MATRIX:
    dc.w 0,1,0,0
    dc.w 0,0,1,0
    dc.w 0,0,0,1

TRANSFORMATIONS_PTR:
    dc.l TRANSFORMATIONS_MATRIX

TRANSFORMATIONS_MATRIX:
    dc.w 0,0,0,0
    dc.w 0,0,0,0
    dc.w 0,0,0,0

    dc.w 0,0,0,0
    dc.w 0,0,0,0
    dc.w 0,0,0,0

LOAD_TRASFORMATION_MATRIX MACRO
    lea CURRENT_TRANSFORMATION_MATRIX,b0
    LOAD (b0)+,\1
    LOAD (b0)+,\2
    LOAD (b0),\3
    ENDM

RESET_CURRENT_TRANFORMATION_MATRIX MACRO
	lea CURRENT_TRANSFORMATION_MATRIX,b0
	REG_LOADI 0000,0001,0000,0000,e0
    store e0,(b0)+
	REG_LOADI 0000,0000,0001,0000,e0
    store e0,(b0)+
	REG_LOADI 0000,0000,0000,0001,e0
    store e0,(b0)+
	ENDM

LOAD_CURRENT_TRANSFORMATION_MATRIX MACRO
	lea CURRENT_TRANSFORMATION_MATRIX,b0
    LOAD (b0)+,\1
    LOAD (b0)+,\2
    LOAD (b0),\3
	ENDM

UPDATE_CURRENT_TRANSFORMATION_MATRIX MACRO
	lea CURRENT_TRANSFORMATION_MATRIX,b0
    store \1,(b0)+
	store \2,(b0)+
	store \3,(b0)+
	ENDM

DEBUG_CURRENT_TRANSFORMATION_MATRIX MACRO
	move.l par1,a1
	adda.l \1,a1
    lea CURRENT_TRANSFORMATION_MATRIX,b0
    load (b0)+,e0
    store e0,(a1)+
    load (b0)+,e0
    store e0,(a1)+
    load (b0)+,e0
    store e0,(a1)+
	ENDM

DEBUG_FIRST_INPUT_TRANSFORMATION_MATRIX MACRO
	move.l par1,a1
	adda.l \1,a1
    store e1,(a1)+
    store e2,(a1)+
    store e3,(a1)+
	ENDM

DEBUG_SECOND_INPUT_TRANSFORMATION_MATRIX MACRO
	move.l par1,a1
	adda.l \1,a1
    store e4,(a1)+
    store e5,(a1)+
    store e6,(a1)+
	ENDM

ROTATE MACRO
	LOAD_CURRENT_TRANSFORMATION_MATRIX e1,e2,e3

	move.w \1,d0
	lea ROT_Z_MATRIX_128,b1   ; Cos and SIN in b1 (precalculated * 2^15)
	LOAD (b1,D0.w*8),E10 ; Load precalculated sin/cos values to register E10

	; rotation matrix
	REG_ZERO e21
    vperm  #$FF0123FF,e10,e21,e4     ; first  row of the matrix  0 cos -sin 0
    vperm  #$FF4567FF,e10,e21,e5     ; second row of the matrix  0 sin  cos 0
	REG_LOADI 0000,0000,0000,0080,e6 ; NOTE, last word must be 1* table multiplier!!!!
	
	bsr.w ammxmatrixmul3X3

	; normalize (divide by 128)
	pmul88 #$0002000200020002,e13,e13
	pmul88 #$0002000200020002,e14,e14
	pmul88 #$0002000200020002,e15,e15

	UPDATE_CURRENT_TRANSFORMATION_MATRIX e13,e14,e15

	ENDM

ROTATEDEBUG MACRO
	LOAD_CURRENT_TRANSFORMATION_MATRIX e1,e2,e3

	move.w \1,d0
	lea ROT_Z_MATRIX_128,b1   ; Cos and SIN in b1 (precalculated * 2^15)
	LOAD (b1,D0.w*8),E10 ; Load precalculated sin/cos values to register E10

	; rotation matrix
	REG_ZERO e21
    vperm  #$FF0123FF,e10,e21,e4     ; first  row of the matrix  0 cos -sin 0
    vperm  #$FF4567FF,e10,e21,e5     ; second row of the matrix  0 sin  cos 0
	REG_LOADI 0000,0000,0000,0080,e6 ; NOTE, last word must be 1* table multiplier!!!!
	; end loading matrix

	;pmull #$0002000200020002,e4,e4
	;pmull #$0002000200020002,e5,e5
	;pmull #$0002000200020002,e6,e6

	DEBUG_CURRENT_TRANSFORMATION_MATRIX #0*8

	DEBUG_SECOND_INPUT_TRANSFORMATION_MATRIX #4*8

	
	bsr.w ammxmatrixmul3X3

	; normalize (divide by 128)
	pmul88 #$0002000200020002,e13,e13
	pmul88 #$0002000200020002,e14,e14
	pmul88 #$0002000200020002,e15,e15

	UPDATE_CURRENT_TRANSFORMATION_MATRIX e13,e14,e15

	DEBUG_CURRENT_TRANSFORMATION_MATRIX #8*8
	ENDM

; use d0 and d1 as input for x and y
TRANSLATE MACRO

	LOAD_CURRENT_TRANSFORMATION_MATRIX e1,e2,e3
    

    REG_LOADI 0000,0001,0000,0000,e4  ; 0 1 0 0
    REG_LOADI 0000,0000,0001,0000,e5  ; 0 0 1 0
	
    move.w \1,d0
    move.l #$0001FFFF,d1
    move.w \2,d1	
	
    vperm #$4567EFCD,d0,d1,e6
	REG_LOADI 0000,0001,0001,0001,e0  ; 0 1 0 0
	pmull e6,e0,e6 ; Y sign inverted and first word zeroed

    bsr.w ammxmatrixmul3X3

	UPDATE_CURRENT_TRANSFORMATION_MATRIX e13,e14,e15

    ENDM

; use d0 and d1 as input for x and y
TRANSLATEDEBUG MACRO

	LOAD_CURRENT_TRANSFORMATION_MATRIX e1,e2,e3
    

    REG_LOADI 0000,0001,0000,0000,e4  ; 0 1 0 0
    REG_LOADI 0000,0000,0001,0000,e5  ; 0 0 1 0
	
    move.w \1,d0
    move.l #$0001FFFF,d1
    move.w \2,d1	
	
    vperm #$4567EFCD,d0,d1,e6
	REG_LOADI 0000,0001,0001,0001,e0  ; 0 1 0 0
	pmull e6,e0,e6 ; Y sign inverted and first word zeroed

    ;DEBUG_SECOND_INPUT_TRANSFORMATION_MATRIX #0*0

    bsr.w ammxmatrixmul3X3

	UPDATE_CURRENT_TRANSFORMATION_MATRIX e13,e14,e15

	DEBUG_CURRENT_TRANSFORMATION_MATRIX #12*8

    ENDM

; INPUT (LOAD BEFORE USING IT)
; MATRIX 1 data must be put on e1,e2,e3 (todo)
; MATRIX 2 data must be put on e4,e5,d6
ammxmatrixmul3X3:
    ;move.l 4(sp),par1 ; argument save
	movem.l d0-d7/a0-a6,-(sp) ; stack save
    ;move.l par1,a1 ; argument address in a1 

    ;move.w #0,d0; ANGLE
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
	pmull e1,e9,e13
	REG_ADD_LESS_SIG_3_WORDS e13
	vperm #$00EF0000,e21,d1,e13

	; multiply second row of the first matrix with last row of the second matrix output in e14 left middle word
	pmull e2,e9,e14
	REG_ADD_LESS_SIG_3_WORDS e14
	vperm #$00EF0000,e21,d1,e14

	; multiply first row of the first matrix with middle row of the second matrix output in e13 right middle word
	pmull e1,e8,e0
	REG_ADD_LESS_SIG_3_WORDS e0
	vperm #$0123EF67,e13,d1,e13

	; multiply third row of the first matrix with last row of the second matrix output in e15 left middle word
	pmull e3,e9,e15
	REG_ADD_LESS_SIG_3_WORDS e15
	vperm #$00EF0000,e21,d1,e15

	; multiply middle row of the first matrix with middle row of the second matrix output in e14 right middle word
	pmull e2,e8,e0
	REG_ADD_LESS_SIG_3_WORDS e0
	vperm #$0123EF67,e14,d1,e14

	; multiply first row of the first matrix with first row if the second matrix output in e13 right word
	pmull e1,e7,e0
	REG_ADD_LESS_SIG_3_WORDS e0
	vperm #$012345EF,e13,d1,e13

	; multiply second row of the first matrix with first row of the second matrix output in e14 right word
	pmull e2,e7,e0
	REG_ADD_LESS_SIG_3_WORDS e0
	vperm #$012345EF,e14,d1,e14

	; multiply third row of the first matrix with middle row of the second matrix output in e15  right middle word
	pmull e3,e8,e0
	REG_ADD_LESS_SIG_3_WORDS e0
	vperm #$0123EF67,e15,d1,e15

	; multiply third row of the first matrix with first row of the second matrix output in e15 right word
	pmull e3,e7,e0
	REG_ADD_LESS_SIG_3_WORDS e0
	vperm #$012345EF,e15,d1,e15

    ;lea CURRENT_TRANSFORMATION_MATRIX,b0
    ;store e13,(b0)+
	;store e14,(b0)+
	;store e15,(b0)+

    movem.l (sp)+,d0-d7/a0-a6
    rts

; INPUT (LOAD BEFORE USING IT)
; MATRIX 1 data must be put on e1
; MATRIX 2 data must be put on e4,e5,d6
; OUTPUT inside E13
ammxmatrixmul1X3:
	movem.l d0-d7/a0-a6,-(sp) ; stack save
    

    REG_ZERO e21 ; zero register

    ; this is the first matrix
	;REG_LOADI 0000,001E,0000,0001,e1 ; X = 30, Y = 0, Z = 1  into e1
	REG_ZERO e2
	REG_ZERO e3

	; this is the second matrix into e4 e5 e6
	;REG_LOADI 0000,0001,0000,0000,e4
	;REG_LOADI 0000,0000,0001,0000,e5
	;REG_LOADI 0000,00A0,0080,0001,e6

	IFD MATRIX_DEBUG
	move.l par1,a1 ; argument address in a1 
	store e1,(a1)+
    store e2,(a1)+
    store e3,(a1)+

    load #$FFFFFFFFFFFFFFFF,e0
    store e0,(a1)+

    store e4,(a1)+
    store e5,(a1)+
    store e6,(a1)+

	ENDIF

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

	IFD MATRIX_DEBUG
	load #$FFFFFFFFFFFFFFFF,e0
	store e0,(a1)+

    store e7,(a1)+
	store e8,(a1)+
	store e9,(a1)+
	; end of matrix rotation
	ENDIF

	; start of matrix multiplication

	; multiply first row of the first matrix with last row of the second matrix output in e13 left middle word
	pmull e1,e9,e13
	REG_ADD_LESS_SIG_3_WORDS e13
	vperm #$00EF0000,e21,d1,e13

	; multiply first row of the first matrix with middle row of the second matrix output in e13 right middle word
	pmull e1,e8,e0
	REG_ADD_LESS_SIG_3_WORDS e0
	vperm #$0123EF67,e13,d1,e13

	; multiply first row of the first matrix with first row if the second matrix output in e13 right word
	pmull e1,e7,e0
	REG_ADD_LESS_SIG_3_WORDS e0
	vperm #$012345EF,e13,d1,e13

	REG_ZERO e14
	REG_ZERO e15
	
	IFD MATRIX_DEBUG
	load #$FFFFFFFFFFFFFFFE,e0
	store e0,(a1)+
	
    store e13,(a1)+
	store e14,(a1)+
	store e15,(a1)+
	; end of matrix rotation
	ENDIF
	
	movem.l (sp)+,d0-d7/a0-a6
    rts

; use this if the second matrix contains trigonometric functions
_ammxmatrixmul3X3Trig:
    ;move.l 4(sp),par1 ; argument save
	movem.l d0-d7/a0-a6,-(sp) ; stack save
    ;move.l par1,a1 ; argument address in a1 

    ;move.w #0,d0; ANGLE
    load #0000000000000000,e21 ; zero register

    ;lea SIN_TABLE_3,b1   ; Cos and SIN in b1 (precalculated * 2^15)
	;LOAD (b1,D0.w*8),E10 ; Load precalculated sin/cos values to register E10

    ; this is the current transformation matrix from e1 to e3, initialize it with neutral values
    ;REG_LOADI 0000,0001,0000,0000,e1
	;REG_LOADI 0000,0000,0001,0000,e2
	;REG_LOADI 0000,00A0,0080,0001,e3

	;REG_LOADI 0004,0004,0004,0004,e0
	;pmull e1,e0,e1
	;pmull e2,e0,e2
	;pmull e3,e0,e3

    ; rotation matrix
    ;vperm  #$FF0123FF,e10,e21,e4     ; first  row of the matrix  0 cos -sin 0
    ;vperm  #$FF4567FF,e10,e21,e5     ; second row of the matrix  0 sin  cos 0
	;REG_LOADI 0000,0000,0000,4000,e6 ; NOTE, last word must be 1* table multiplier!!!!
	; end loading matrix


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

	;move.l par1,a1 ; argument address in a1 
	
	;store e1,(a1)+
    ;store e2,(a1)+
    ;store e3,(a1)+
	
    ;load #$FFFFFFFFFFFFFFFF,e0
    ;store e0,(a1)+

    ;store e4,(a1)+
    ;store e5,(a1)+
    ;store e6,(a1)+
	
	;load #$FFFFFFFFFFFFFFFF,e0
	;store e0,(a1)+

    ;store e7,(a1)+
	;store e8,(a1)+
	;store e9,(a1)+

	; start of matrix multiplication

	; multiply first row of the first matrix with last row of the second matrix output in e13 left middle word
	pmul88 e1,e9,e13
	REG_ADD_LESS_SIG_3_WORDS e13
	vperm #$00EF0000,e21,d1,e13

	; multiply second row of the first matrix with last row of the second matrix output in e14 left middle word
	pmul88 e2,e9,e14
	REG_ADD_LESS_SIG_3_WORDS e14
	vperm #$00EF0000,e21,d1,e14

	; multiply first row of the first matrix with middle row of the second matrix output in e13 right middle word
	pmul88 e1,e8,e0
	REG_ADD_LESS_SIG_3_WORDS e0
	vperm #$0123EF67,e13,d1,e13

	; multiply third row of the first matrix with last row of the second matrix output in e15 left middle word
	pmul88 e3,e9,e15
	REG_ADD_LESS_SIG_3_WORDS e15
	vperm #$00EF0000,e21,d1,e15

	; multiply middle row of the first matrix with middle row of the second matrix output in e14 right middle word
	pmul88 e2,e8,e0
	REG_ADD_LESS_SIG_3_WORDS e0
	vperm #$0123EF67,e14,d1,e14

	

	; multiply first row of the first matrix with first row if the second matrix output in e13 right word
	pmul88 e1,e7,e0
	REG_ADD_LESS_SIG_3_WORDS e0
	vperm #$012345EF,e13,d1,e13

	

	; multiply second row of the first matrix with first row of the second matrix output in e14 right word
	pmul88 e2,e7,e0
	REG_ADD_LESS_SIG_3_WORDS e0
	vperm #$012345EF,e14,d1,e14

	

	; multiply third row of the first matrix with middle row of the second matrix output in e15  right middle word
	pmul88 e3,e8,e0
	REG_ADD_LESS_SIG_3_WORDS e0
	vperm #$0123EF67,e15,d1,e15

	

	; multiply third row of the first matrix with first row of the second matrix output in e15 right word
	pmul88 e3,e7,e0
	REG_ADD_LESS_SIG_3_WORDS e0
	vperm #$012345EF,e15,d1,e15

	load #$FFFFFFFFFFFFFFFE,e0
	store e0,(a1)+

	
	
    store e13,(a1)+
	store e14,(a1)+
	store e15,(a1)+



    movem.l (sp)+,d0-d7/a0-a6
    rts