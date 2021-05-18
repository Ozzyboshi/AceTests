COORDSBUFFER:
    dc.l 0
    dc.l 0

LINEBROKEN	MACRO

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
	bsr.w _ammxmainloop8
	ENDM

POINTDEBUG MACRO
	move.w \1,d0
	move.l #$0001FFFF,d1
	move.w \2,d1

	vperm #$8967EFCD,d0,d1,e1
	REG_ZERO e2
	REG_ZERO e3

	LOAD_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6

	DEBUG_FIRST_INPUT_TRANSFORMATION_MATRIX #0*0
	DEBUG_SECOND_INPUT_TRANSFORMATION_MATRIX #4*8

	bsr.w ammxmatrixmul1X3
	;UPDATE_CURRENT_TRANSFORMATION_MATRIX e13,e14,e15

	;NORMALIZE_128


	;DEBUG_CURRENT_TRANSFORMATION_MATRIX #8*8
	DEBUG_OUTPUT_TRANSFORMATION_MATRIX #8*8

	; normalize (divide by 128) ONLY IF WE ROTATE!!!!
	pmul88 #$0004000400040004,e13,e13
	pmul88 #$0004000400040004,e14,e14
	pmul88 #$0004000400040004,e15,e15

	vperm #$FFFFFF23,e13,e2,d0
	vperm #$FFFFFF45,e13,e2,d1
	
	DEBUG_COORDS #12*8

	ENDM

POINTDEBUG_Q_10_6 MACRO
	move.w \1,d0
	move.l #$0040FFFF,d1
	move.w \2,d1

	vperm #$8967EFCD,d0,d1,e1
	REG_ZERO e2
	REG_ZERO e3

	LOAD_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6

	DEBUG_FIRST_INPUT_TRANSFORMATION_MATRIX #0*0
	DEBUG_SECOND_INPUT_TRANSFORMATION_MATRIX #4*8

	bsr.w ammxmatrixmul1X3_q10_6

	DEBUG_OUTPUT_TRANSFORMATION_MATRIX #8*8

	vperm #$FFFFFF23,e13,e2,d0
	vperm #$FFFFFF45,e13,e2,d1

	lsr.l #6,d0
	lsr.l #6,d1
	
	DEBUG_COORDS #12*8

	ENDM


POINT_Q_10_6 MACRO
	move.w \1,d0
	move.l #$0040FFFF,d1
	move.w \2,d1

	vperm #$8967EFCD,d0,d1,e1
	REG_ZERO e2
	REG_ZERO e3

	LOAD_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6

	bsr.w ammxmatrixmul1X3_q10_6

	vperm #$FFFFFF23,e13,e2,d0
	vperm #$FFFFFF45,e13,e2,d1

	lsr.l #6,d0
	lsr.l #6,d1

	; start plot routine
	lea PLOTREFS,a1
	add.w d1,d1
	move.w 0(a1,d1.w),d1
	move.w d0,d2
	lsr.w #3,d2
	add.w d2,d1
	not.b d0
	lea SCREEN_0,a0
	bset d0,(a0,d1.w)
	
	ENDM

LINE_Q_10_6_TEST MACRO
	move.w \1,d0
	move.l #$0040FFFF,d1
	move.w \2,d1

	vperm #$8967EFCD,d0,d1,e1
	REG_ZERO e2
	REG_ZERO e3

	LOAD_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6

	bsr.w ammxmatrixmul1X3_q10_6

	vperm #$FFFFFF23,e13,e2,d0
	vperm #$FFFFFF45,e13,e2,d1

	

	lsr.l #6,d0
	lsr.l #6,d1

	lea LINEVERTEX_START_FINAL,a2
	move.w d0,(a2)+
	move.w d1,(a2)+

	move.w \3,d0
	move.l #$0040FFFF,d1
	move.w \4,d1

	vperm #$8967EFCD,d0,d1,e1

	REG_ZERO e2
	REG_ZERO e3

	LOAD_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6

	bsr.w ammxmatrixmul1X3_q10_6
	vperm #$FFFFFF23,e13,e2,d0
	vperm #$FFFFFF45,e13,e2,d1
	lsr.l #6,d0
	lsr.l #6,d1

	move.w d0,(a2)+
	move.w d1,(a2)+


	; start bresen routine
	load #0000000000000000,e21 ;optimisation

	lea LINEVERTEX_START_FINAL,a1
	move.w #96,(a1)+
	move.w #6,(a1)+
	move.w #96,(a1)+
	move.w #25,(a1)+
	;bsr.w ammxlinefill
	bsr.w _ammxmainloop8
	
	ENDM

LINE_Q_10_6 MACRO
	move.w \1,d0
	move.l #$0040FFFF,d1
	move.w \2,d1

	vperm #$CC67EFCD,d0,d1,e1
	REG_ZERO e2
	REG_ZERO e3

	LOAD_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6

	bsr.w ammxmatrixmul1X3_q10_6

	vperm #$FFFFFF23,e13,e2,d0
	vperm #$FFFFFF45,e13,e2,d1

	

	lsr.l #6,d0
	lsr.l #6,d1

	lea LINEVERTEX_START_FINAL,a2
	move.w d0,(a2)+
	move.w d1,(a2)+

	move.w \3,d0
	move.l #$0040FFFF,d1
	move.w \4,d1

	vperm #$CC67EFCD,d0,d1,e1

	bsr.w ammxmatrixmul1X3_q10_6
	vperm #$FFFFFF23,e13,e2,d0
	vperm #$FFFFFF45,e13,e2,d1
	lsr.l #6,d0
	lsr.l #6,d1

	move.w d0,(a2)+
	move.w d1,(a2)+


	; start bresen routine
	load #0000000000000000,e21 ;optimisation
	bsr.w _ammxmainloop8
	
	ENDM

LINEDEBUG_Q_10_6 MACRO
	move.w \1,d0
	move.l #$0040FFFF,d1
	move.w \2,d1

	vperm #$CC67EFCD,d0,d1,e1
	REG_ZERO e2
	REG_ZERO e3

	LOAD_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6

	DEBUG_FIRST_INPUT_TRANSFORMATION_MATRIX #0*0
	DEBUG_SECOND_INPUT_TRANSFORMATION_MATRIX #4*8

	bsr.w ammxmatrixmul1X3_q10_6

	vperm #$FFFFFF23,e13,e2,d0
	vperm #$FFFFFF45,e13,e2,d1

	DEBUG_OUTPUT_TRANSFORMATION_MATRIX #8*8

	

	lsr.l #6,d0
	lsr.l #6,d1

	lea LINEVERTEX_START_FINAL,a2
	move.w d0,(a2)+
	move.w d1,(a2)+

	move.w \3,d0
	move.l #$0040FFFF,d1
	move.w \4,d1

	vperm #$8967EFCD,d0,d1,e1

	bsr.w ammxmatrixmul1X3_q10_6
	vperm #$FFFFFF23,e13,e2,d0
	vperm #$FFFFFF45,e13,e2,d1
	DEBUG_OUTPUT_TRANSFORMATION_MATRIX #12*8
	lsr.l #6,d0
	lsr.l #6,d1

	move.w d0,(a2)+
	move.w d1,(a2)+


	; start bresen routine
	load #0000000000000000,e21 ;optimisation
	bsr.w _ammxmainloop8
	
	ENDM

CIRCLE_Q_10_6_CENTER_X:
	dc.w 0
CIRCLE_Q_10_6_CENTER_Y:
	dc.w 0
CIRCLE_Q_10_6_LAST_X:
	dc.w 0
CIRCLE_Q_10_6_LAST_Y:
	dc.w 0
CIRCLE_Q_10_6_PRECISION:
	dc.w 0
CIRCLE_Q_10_6_LINE_1:
	dc.w 0
CIRCLE_Q_10_6_LINE_2:
	dc.w 0
CIRCLE_Q_10_6_LINE_3:
	dc.w 0
CIRCLE_Q_10_6_LINE_4:
	dc.w 0

CIRCLEDEBUG_Q_10_6: ; pass xcenter ycenter radius and precision
	movem.l d0-d7/a0-a6,-(sp) ; stack save
	asr.w #6,d0 ; normalize center x
    asr.w #6,d1 ; normalize center y
	asr.w #6,d2 ; normalize radius
				; precision is inside d7, no need to be normalized

	move.l par1,a1 ; for debgging

	; save the center into variables
	move.w d0,CIRCLE_Q_10_6_CENTER_X
	move.w d1,CIRCLE_Q_10_6_CENTER_Y

	; save the precision
	move.w d7,CIRCLE_Q_10_6_PRECISION

	;move.w d0,CIRCLE_Q_10_6_LAST_X
	move.w d2,CIRCLE_Q_10_6_LAST_X
	move.w #0,CIRCLE_Q_10_6_LAST_Y

CIRCLEDEBUG_Q_10_6_STARTLOOP:
	;move.w CIRCLE_Q_10_6_CENTER_X,d3 ; x of first point is equal to 0+radius
	move.w d2,d3 ; x of first point is equal to 0+radius
	moveq #0,d4 ; y of first point is equal to 0 


	lea COS_SIN_SIN_COSINV_TABLE,b1   ; Cos and SIN in b1 (precalculated * 256)
	LOAD (b1,D7.w*8),E5 ; Load precalculated sin/cos values to register E5

	;LOAD COORDS,E4 ; Load XY input data in register for pmula
	vperm #$67EF67EF,d3,d4,e4
	PMUl88 E4,E5,E7 ; Calculate rotation with formula x*cos(a) ## y*sin(a) ## x*sin(a) ## -y*cos(a)
	;ammx mode - copy the result in E8 but 16bit shifted
    dc.w $fe7c,$f038,$0000,$0000,$0000,$0010  ; LSL.Q  #16,E7,E8
	PADDW    E7,E8,E9 ; add x*cos(a) + y*sin(a) and x*sin(a) -y*cos(a) in one shot

	VPERM #$01010101,E9,E9,D5 ; result of first addition to d0
    VPERM #$45454545,E9,E9,D6 ; result of first addition to d1

	; divide by 4
	;asr.w #2,d4
    ;asr.w #2,d5

	;add.w CIRCLE_Q_10_6_CENTER_X,d3
	;add.w CIRCLE_Q_10_6_CENTER_Y,d4
	;add.w CIRCLE_Q_10_6_CENTER_X,d5
	;add.w CIRCLE_Q_10_6_CENTER_Y,d6

	move.w CIRCLE_Q_10_6_LAST_X,d0
	add.w CIRCLE_Q_10_6_CENTER_X,d0
	move.w d0,CIRCLE_Q_10_6_LINE_1

	move.w CIRCLE_Q_10_6_LAST_Y,d0
	add.w CIRCLE_Q_10_6_CENTER_Y,d0
	move.w d0,CIRCLE_Q_10_6_LINE_2

	move.w d5,d0
	add.w CIRCLE_Q_10_6_CENTER_X,d0
	move.w d0,CIRCLE_Q_10_6_LINE_3

	move.w d6,d0
	add.w CIRCLE_Q_10_6_CENTER_Y,d0
	move.w d0,CIRCLE_Q_10_6_LINE_4

	;asl.w #6,d0
	;asl.w #6,d3

	;LINE_Q_10_6 CIRCLE_Q_10_6_LAST_X,CIRCLE_Q_10_6_LAST_Y,d5,d6
	move.w CIRCLE_Q_10_6_LINE_1,(a1)+
	move.w CIRCLE_Q_10_6_LINE_2,(a1)+
	move.w CIRCLE_Q_10_6_LINE_3,(a1)+
	move.w CIRCLE_Q_10_6_LINE_4,(a1)+


	; save last point
	move.w d5,CIRCLE_Q_10_6_LAST_X
	move.w d6,CIRCLE_Q_10_6_LAST_Y

    ;store d0,(a1)+
    ;store d1,(a1)+
    ;store d2,(a1)+
	;store d3,(a1)+
	;store d4,(a1)+
	;store d5,(a1)+
	;store d6,(a1)+
	;store d7,(a1)+

	; increment d7 with its own precision
	add.w CIRCLE_Q_10_6_PRECISION,d7

	; if d7 < 360 repeat
	cmp #359,d7
	bls.w CIRCLEDEBUG_Q_10_6_STARTLOOP

	; handle last rect

	move.w d2,d3 ; x of first point is equal to 0+radius
	moveq #0,d4 ; y of first point is equal to 0 


	lea COS_SIN_SIN_COSINV_TABLE,b1   ; Cos and SIN in b1 (precalculated * 256)
	LOAD (b1),E5 ; Load precalculated sin/cos values to register E5

	;LOAD COORDS,E4 ; Load XY input data in register for pmula
	vperm #$67EF67EF,d3,d4,e4
	PMUl88 E4,E5,E7 ; Calculate rotation with formula x*cos(a) ## y*sin(a) ## x*sin(a) ## -y*cos(a)
	;ammx mode - copy the result in E8 but 16bit shifted
    dc.w $fe7c,$f038,$0000,$0000,$0000,$0010  ; LSL.Q  #16,E7,E8
	PADDW    E7,E8,E9 ; add x*cos(a) + y*sin(a) and x*sin(a) -y*cos(a) in one shot

	VPERM #$01010101,E9,E9,D5 ; result of first addition to d0
    VPERM #$45454545,E9,E9,D6 ; result of first addition to d1

	move.w CIRCLE_Q_10_6_LAST_X,d0
	add.w CIRCLE_Q_10_6_CENTER_X,d0
	move.w d0,CIRCLE_Q_10_6_LINE_1

	move.w CIRCLE_Q_10_6_LAST_Y,d0
	add.w CIRCLE_Q_10_6_CENTER_Y,d0
	move.w d0,CIRCLE_Q_10_6_LINE_2

	move.w d5,d0
	add.w CIRCLE_Q_10_6_CENTER_X,d0
	move.w d0,CIRCLE_Q_10_6_LINE_3

	move.w d6,d0
	add.w CIRCLE_Q_10_6_CENTER_Y,d0
	move.w d0,CIRCLE_Q_10_6_LINE_4

	;asl.w #6,d0
	;asl.w #6,d3

	;LINE_Q_10_6 CIRCLE_Q_10_6_LAST_X,CIRCLE_Q_10_6_LAST_Y,d5,d6
	move.w CIRCLE_Q_10_6_LINE_1,(a1)+
	move.w CIRCLE_Q_10_6_LINE_2,(a1)+
	move.w CIRCLE_Q_10_6_LINE_3,(a1)+
	move.w CIRCLE_Q_10_6_LINE_4,(a1)+


	movem.l (sp)+,d0-d7/a0-a6

	rts

CIRCLE_Q_10_6: ; pass xcenter ycenter radius and precision
	movem.l d0-d7/a0-a6,-(sp) ; stack save
	asr.w #6,d0 ; normalize center x
    asr.w #6,d1 ; normalize center y
	asr.w #6,d2 ; normalize radius
				; precision is inside d7, no need to be normalized

	; save the center into variables
	move.w d0,CIRCLE_Q_10_6_CENTER_X
	move.w d1,CIRCLE_Q_10_6_CENTER_Y

	; save the precision
	move.w d7,CIRCLE_Q_10_6_PRECISION

	;move.w d0,CIRCLE_Q_10_6_LAST_X
	move.w d2,CIRCLE_Q_10_6_LAST_X
	move.w #0,CIRCLE_Q_10_6_LAST_Y

CIRCLE_Q_10_6_STARTLOOP:
	move.w d2,d3 ; x of first point is equal to 0+radius
	moveq #0,d4 ; y of first point is equal to 0 


	lea COS_SIN_SIN_COSINV_TABLE,b1   ; Cos and SIN in b1 (precalculated * 256)
	LOAD (b1,D7.w*8),E5 ; Load precalculated sin/cos values to register E5

	;LOAD COORDS,E4 ; Load XY input data in register for pmula
	vperm #$67EF67EF,d3,d4,e4
	PMUl88 E4,E5,E7 ; Calculate rotation with formula x*cos(a) ## y*sin(a) ## x*sin(a) ## -y*cos(a)
	;ammx mode - copy the result in E8 but 16bit shifted
    dc.w $fe7c,$f038,$0000,$0000,$0000,$0010  ; LSL.Q  #16,E7,E8
	PADDW    E7,E8,E9 ; add x*cos(a) + y*sin(a) and x*sin(a) -y*cos(a) in one shot

	VPERM #$01010101,E9,E9,D5 ; result of first addition to d0
    VPERM #$45454545,E9,E9,D6 ; result of first addition to d1

	

	move.w CIRCLE_Q_10_6_LAST_X,d0
	add.w CIRCLE_Q_10_6_CENTER_X,d0
	asl.w #6,d0
	move.w d0,CIRCLE_Q_10_6_LINE_1

	move.w CIRCLE_Q_10_6_LAST_Y,d0
	add.w CIRCLE_Q_10_6_CENTER_Y,d0
	asl.w #6,d0
	move.w d0,CIRCLE_Q_10_6_LINE_2

	move.w d5,d0
	add.w CIRCLE_Q_10_6_CENTER_X,d0
	asl.w #6,d0
	move.w d0,CIRCLE_Q_10_6_LINE_3

	move.w d6,d0
	add.w CIRCLE_Q_10_6_CENTER_Y,d0
	asl.w #6,d0
	move.w d0,CIRCLE_Q_10_6_LINE_4

	LINE_Q_10_6 CIRCLE_Q_10_6_LINE_1,CIRCLE_Q_10_6_LINE_2,CIRCLE_Q_10_6_LINE_3,CIRCLE_Q_10_6_LINE_4


	; save last point
	move.w d5,CIRCLE_Q_10_6_LAST_X
	move.w d6,CIRCLE_Q_10_6_LAST_Y

	; increment d7 with its own precision
	add.w CIRCLE_Q_10_6_PRECISION,d7

	; if d7 < 360 repeat
	cmp #359,d7
	bls.w CIRCLE_Q_10_6_STARTLOOP

	move.w d2,d3 ; x of first point is equal to 0+radius
	moveq #0,d4 ; y of first point is equal to 0 


	lea COS_SIN_SIN_COSINV_TABLE,b1   ; Cos and SIN in b1 (precalculated * 256)
	LOAD (b1),E5 ; Load precalculated sin/cos values to register E5

	;LOAD COORDS,E4 ; Load XY input data in register for pmula
	vperm #$67EF67EF,d3,d4,e4
	PMUl88 E4,E5,E7 ; Calculate rotation with formula x*cos(a) ## y*sin(a) ## x*sin(a) ## -y*cos(a)
	;ammx mode - copy the result in E8 but 16bit shifted
    dc.w $fe7c,$f038,$0000,$0000,$0000,$0010  ; LSL.Q  #16,E7,E8
	PADDW    E7,E8,E9 ; add x*cos(a) + y*sin(a) and x*sin(a) -y*cos(a) in one shot

	VPERM #$01010101,E9,E9,D5 ; result of first addition to d0
    VPERM #$45454545,E9,E9,D6 ; result of first addition to d1

	

	move.w CIRCLE_Q_10_6_LAST_X,d0
	add.w CIRCLE_Q_10_6_CENTER_X,d0
	asl.w #6,d0
	move.w d0,CIRCLE_Q_10_6_LINE_1

	move.w CIRCLE_Q_10_6_LAST_Y,d0
	add.w CIRCLE_Q_10_6_CENTER_Y,d0
	asl.w #6,d0
	move.w d0,CIRCLE_Q_10_6_LINE_2

	move.w d5,d0
	add.w CIRCLE_Q_10_6_CENTER_X,d0
	asl.w #6,d0
	move.w d0,CIRCLE_Q_10_6_LINE_3

	move.w d6,d0
	add.w CIRCLE_Q_10_6_CENTER_Y,d0
	asl.w #6,d0
	move.w d0,CIRCLE_Q_10_6_LINE_4

	LINE_Q_10_6 CIRCLE_Q_10_6_LINE_1,CIRCLE_Q_10_6_LINE_2,CIRCLE_Q_10_6_LINE_3,CIRCLE_Q_10_6_LINE_4

	movem.l (sp)+,d0-d7/a0-a6

	rts

TRIANGLE_Q_10_6 MACRO
	move.w \1,d1
	move.w \2,d2

	move.w \3,d3
	move.w \4,d4

	LINE_Q_10_6 d1,d2,d3,d4

	move.w \1,d1
	move.w \2,d2

	move.w \5,d3
	move.w \6,d4

	LINE_Q_10_6 d1,d2,d3,d4

	move.w \3,d1
	move.w \4,d2

	move.w \5,d3
	move.w \6,d4

	LINE_Q_10_6 d1,d2,d3,d4


	ENDM

RECT_Q_10_6 MACRO
	move.w \1,d3
	add.w \3,d3
	move.w \2,d4
	LINE_Q_10_6 \1,\2,d3,d4

	move.w \1,d3
	move.w \2,d4
	add.w \4,d4
	LINE_Q_10_6 \1,\2,d3,d4

	move.w \1,d3
	add.w \3,d3
	move.w \2,d4

	move.w \2,d5
	add.w \4,d5

	LINE_Q_10_6 d3,d4,d3,d5

	move.w \1,d3
	move.w \2,d4
	add.w \4,d4

	move.w \1,d5
	add.w \3,d5

	move.w \2,d6
	add.w \4,d6

	LINE_Q_10_6 d3,d4,d5,d6


ENDM

RECT_Q_10_6_BROKEN MACRO
	move.w \1,d0
	move.l #$0040FFFF,d1
	move.w \2,d1

	vperm #$8967EFCD,d0,d1,e1
	REG_ZERO e2
	REG_ZERO e3

	LOAD_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6

	bsr.w ammxmatrixmul1X3_q10_6

	vperm #$FFFFFF23,e13,e2,d0
	vperm #$FFFFFF45,e13,e2,d1

	lsr.l #6,d0
	lsr.l #6,d1

	lea LINEVERTEX_START_FINAL,a2
	move.w d0,(a2)+
	move.w d1,(a2)+
	lea LINEVERTEX_TMP2,a3
	move.w d0,(a3)+
	move.w d1,(a3)+

	move.w \1,d1
	add.w \3,d0
	move.l #$0040FFFF,d1
	move.w \2,d1

	vperm #$8967EFCD,d0,d1,e1

	bsr.w ammxmatrixmul1X3_q10_6
	vperm #$FFFFFF23,e13,e2,d0
	vperm #$FFFFFF45,e13,e2,d1
	lsr.l #6,d0
	lsr.l #6,d1

	move.w d0,(a2)+
	move.w d1,(a2)+

	lea LINEVERTEX_TMP,a3
	move.w d0,(a3)+
	move.w d1,(a3)+

	; start bresen routine
	REG_ZERO e21
	bsr.w _ammxmainloop8

	; second line bottom one
	move.w \1,d0
	move.l #$0040FFFF,d1
	move.w \2,d1
	add.w \4,d1

	vperm #$8967EFCD,d0,d1,e1

	LOAD_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6

	bsr.w ammxmatrixmul1X3_q10_6

	vperm #$FFFFFF23,e13,e2,d0
	vperm #$FFFFFF45,e13,e2,d1

	lsr.l #6,d0
	lsr.l #6,d1

	lea LINEVERTEX_START_FINAL,a2
	move.w d0,(a2)+
	move.w d1,(a2)+
	lea LINEVERTEX_TMP3,a3
	move.w d0,(a3)+
	move.w d1,(a3)+
	

	move.w \1,d0
	move.l #$0040FFFF,d1
	move.w \2,d1
	add.w \3,d0
	add.w \4,d1

	vperm #$8967EFCD,d0,d1,e1

	LOAD_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6

	bsr.w ammxmatrixmul1X3_q10_6

	vperm #$FFFFFF23,e13,e2,d0
	vperm #$FFFFFF45,e13,e2,d1

	lsr.l #6,d0
	lsr.l #6,d1

	move.w d0,(a2)+
	move.w d1,(a2)+

	; start bresen routine
	bsr.w _ammxmainloop8

	lea LINEVERTEX_START_FINAL,a2
	lea LINEVERTEX_TMP,a3
	move.w (a3)+,(a2)+
	move.w (a3)+,(a2)+

	
	; start bresen routine
	bsr.w _ammxmainloop8

	lea LINEVERTEX_START_FINAL,a2
	lea LINEVERTEX_TMP2,a3
	move.w (a3)+,(a2)+
	move.w (a3)+,(a2)+
	lea LINEVERTEX_TMP3,a3
	move.w (a3)+,(a2)+
	move.w (a3)+,(a2)+

	bsr.w _ammxmainloop8
	
	ENDM

POINT MACRO
	move.w \1,d0
	move.l #$0001FFFF,d1
	move.w \2,d1

	vperm #$8967EFCD,d0,d1,e1
	REG_ZERO e2
	REG_ZERO e3

	LOAD_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6

	bsr.w ammxmatrixmul1X3

	; normalize (divide by 128) ONLY IF WE ROTATE!!!!
	pmul88 #$0004000400040004,e13,e13
	pmul88 #$0004000400040004,e14,e14
	pmul88 #$0004000400040004,e15,e15

	vperm #$FFFFFF23,e13,e2,d0
	vperm #$FFFFFF45,e13,e2,d1

	; start plot routine
	lea PLOTREFS,a1
	add.w d1,d1
	move.w 0(a1,d1.w),d1
	move.w d0,d2
	lsr.w #3,d2
	add.w d2,d1
	not.b d0
	lea SCREEN_0,a0
	bset d0,(a0,d1.w)

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
	;bsr.w linem0to1
	bra.s bendammxmainloop8phase2
bgoto0tominus1:
	bsr.w blinem0tominus1
bendammxmainloop8phase2:
	movem.l (sp)+,d0-d6/a0-a6
	rts


; build line from 8 5 to 1 1 (down in cartesian plane but up on screen)
; d0 ==> x
; d1 ==> y
; d2 ===> x1 y1
; d3 ===> x2 y2
; d4 ===> decision
; e6 ===> I1
blinem0tominus1:
	movem.l d0-d7/a2,-(sp) ; stack save

	move.l LINEVERTEX_START_PUSHED,d2
	move.l LINEVERTEX_END_PUSHED,d3

	move.w d2,d4
	move.w d3,d2
	move.w d4,d3

	;Calculate dx = x2-x1
    ;Calculate dy = y2-y1
	PSUBW d2,d3,E5 ; e5 will contain deltas

	;Calculate i1=2*dy
	PADDW E5,E5,E6 ; I1 is on the lower 2 bytes of E6

	VPERM #$45454545,E5,E5,E8 ; Put DeltaX in all e8
	VPERM #$6767EFEF,E6,E5,E7 ; E7 = I1 I1 Dy Dy

	PSUBW E8,E7,E9; E9 : first word  i1-dx and third word dy-dx
	
	;Calculate i2=2*(dy-dx)
    ;Calculate d=i1-dx

	; decision variable to D4
	VPERM #$01010101,E9,E9,D4 ; d calculated  in D4
	PADDW E9,E9,E9            ; i2 calculated in E9

	vperm #$45454545,d2,d2,d0 ; x = x1 (x1 is the start)
	vperm #$67676767,d3,d3,d1 ; y = y1 (y1 is the start)
	VPERM #$45454545,d3,d3,d6 ; xend = x2

	
	bsr.w bplotpoint ; PLOT POINT!!

BENDLINE_F2:
	movem.l (sp)+,d0-d7/a2
	rts

; plotpoint routine
; before calling this routine set
; x ==> d1 (word)
; y ==> d0 (word)
; plotrefs bust be build precalculated
; e22 filled with bitplane flags
; bitplaneX must be loaded with real bitplane addresses
bplotpoint:
	movem.l d0-d3/a0-a1,-(sp) ; stack save
	lea PLOTREFS,a1
	
	;load e23,d6
	vperm #$000000000000000F,e21,e22,d3 ; optimisation, e21 must be all zeroes from the caller

	

	; start plot routine
	add.w d1,d1
	move.w 0(a1,d1.w),d1

	

	move.w d0,d2
	lsr.w #3,d2
	add.w d2,d1
	not.b d0

	;moveq #0,d0
	;move.l par1,a2 
	;store d0,(a2)+
    ;store d1,(a2)+
	;movem.l (sp)+,d0-d3/a0-a1
	;rts
	;moveq #0,d1

	

	; First bitplane
	IFD CLEAR_NONSET_PIXELS
	lea SCREEN_0,a0
	bclr d0,(a0,d1.w)
	ENDIF
	btst #0,d3
	beq.s bplotpoint_nofirstbitplane
	IFND CLEAR_NONSET_PIXELS
	lea SCREEN_0,a0
	ENDIF
	lea SCREEN_0,a0
	bset d0,(a0,d1.w)
bplotpoint_nofirstbitplane:

	; Second bitplane
	IFD CLEAR_NONSET_PIXELS
	lea SCREEN_1,a0
	;bclr d0,(a0,d1.w)
	ENDIF
	btst #1,d3
	beq.s bplotpoint_nosecondbitplane
	IFND CLEAR_NONSET_PIXELS
	lea SCREEN_1,a0
	ENDIF
	bset d0,(a0,d1.w)
bplotpoint_nosecondbitplane:

	; WARNING!!!!!! line optimization, save d0 in d5 so that the caller can calculate the next X without reentering here
	move.b d0,d5
	lea SCREEN_0,a2
	adda.w d1,a2

	;exit plotpoint
	movem.l (sp)+,d0-d3/a0-a1
	rts

ammxlinefill:
	movem.l d0-d6/a0-a6,-(sp) ; stack save
	move.l par1,a1
	lea LINEVERTEX_START_PUSHED,a2
	
	; - pick lowest first x
	move.l LINEVERTEX_START_FINAL,d2
	cmp.l LINEVERTEX_END_FINAL,d2
	blt.s ammxlinefill_lowestless ;  check if first x is lower if this is the case jump to endammxlinefill
	move.l LINEVERTEX_START_FINAL,d3
	move.l LINEVERTEX_END_FINAL,d2
	bra.s endammxlinefillphase1
ammxlinefill_lowestless:
	move.l LINEVERTEX_END_FINAL,d3
endammxlinefillphase1 : ; end of first check


; apply translation (ma questa per me non serve piu)
	;move.l TRANSLATE_MEM_2D_X,d4
	;paddw d2,d4,d2
	;paddw d3,d4,d3

	; - pick lowest first x end
	move.l d2,(a2)+
	move.l d3,(a2)+

	; - check if both coords are between screen limits start
	; - check if both coords are between screen limits end

	; select one of the 4 drawing routines start
	PSUBW d2,d3,d4 ; d4 will contain deltas
	PSUBW d3,d2,d5
	pmaxsw  d5,d4,d4
	
	vperm #$45454545,d4,d4,d5 ; move xdelta in the less sig word
	; select one of the 4 drawing routines end
	
	cmp.w d5,d4
	blt.s ammxlinefill_dylessthan
	
	cmp.w d2,d3
	bls.s ammxlinefill_gotolessminus1
	nop
	bsr.w ammxlinefill_linemgreater1		; vertical line
	bra.s ammxlinefill_endammxlinefillphase2

ammxlinefill_gotolessminus1:
	;bsr.w ammxlinefill_linemlessminus1
	bra.s ammxlinefill_endammxlinefillphase2


ammxlinefill_dylessthan:
	
	cmp.w d2,d3
	bls.s ammxlinefill_goto0tominus1
	bsr.w ammxlinefill_linem0to1
	nop
	bra.s ammxlinefill_endammxlinefillphase2
ammxlinefill_goto0tominus1:
	;bsr.w ammxlinefill_linem0tominus1
	nop
ammxlinefill_endammxlinefillphase2:
	movem.l (sp)+,d0-d6/a0-a6

	rts


; d0 ==> x
; d1 ==> y
; d2 ===> x1 y1
; d3 ===> x2 y2
; d4 ===> decision
; e6 ===> I1

ammxlinefill_linem0to1:
	
	IFD ASM_DEBUG
	movem.l d0-d6/a0-a6,-(sp) ; stack save
	move.l par2,a1
	ELSE
	movem.l d0-d7/a2,-(sp) ; stack save
	ENDIF

	move.l LINEVERTEX_START_PUSHED,d2
	move.l LINEVERTEX_END_PUSHED,d3

	;Calculate dx = x2-x1
    ;Calculate dy = y2-y1
	PSUBW d2,d3,E5 ; e5 will contain deltas

	;Calculate i1=2*dy
	PADDW E5,E5,E6 ; I1 is on the lower 2 bytes of E6
	
	VPERM #$45454545,E5,E5,E8 ; Put DeltaX in all e8
	VPERM #$6767EFEF,E6,E5,E7 ; E7 = I1 I1 Dy Dy

	PSUBW E8,E7,E9; E9 : first word  i1-dx and third word dy-dx

	VPERM #$01010101,E9,E9,D4 ; d calculated  in D4
	PADDW E9,E9,E9            ; i2 calculated in E9

	vperm #$45454545,d2,d2,d0 ; x = x1 (x1 is the start)
	vperm #$67676767,d2,d2,d1 ; y = y1 (y1 is the start)
	VPERM #$45454545,d3,d3,d6 ; xend = x2

	bsr.w plotpoint ; PLOT POINT!!

ammxlinefill_LINESTARTITER_F:

	; interate for each x until x<=xend
	cmp.w d0,d6
	blt.s ammxlinefill_ENDLINE_F ; if x>=xend exit

	cmp.w #0,d4 ; check if d<0
	blt.s ammxlinefill_POINT_D_LESS_0_F ; branch if id<0

	; we are here if d>=0
	paddw e9,d4,d4 ; d = i2+ d
	addq #1,d1 ; y = y+1
	adda.w #$0028,a2 ; optimization , go to next line in bitplane
	bra.s ammxlinefill_POINT_D_END_F

ammxlinefill_POINT_D_LESS_0_F:
	; we are here if d<0
	paddw e6,d4,d4 ; d = i1+ d 
	
ammxlinefill_POINT_D_END_F:
	addq #1,d0

	; here d5 is available and pushed
	; d7 available but not pushed
	; aX all availables except a1 but not pushed
	; bsr.w plotpoint ; PLOT POINT!!
	; here we have in d5 = position of first bit plotted
	; a2 = address where the first bit was plotted
	subq.b #1,d5
	move.b d5,d7
	andi.l #$00000007,d7
	addq.b #1,d7
	lsr.b #3,d7
	adda.l d7,a2
	vperm #$000000000000000F,e21,e22,d7
	IFD CLEAR_NONSET_PIXELS
	bclr d5,(a2)
	ENDIF
	btst #0,d7
	beq.s ammxlinefill_ENDLINEBPL0_F
	bset d5,(a2) ; plot optimized!!!

	; opt bitplane 1
ammxlinefill_ENDLINEBPL0_F:
	IFD CLEAR_NONSET_PIXELS
	move.l a2,a3
	adda.w #10240,a3
	bclr d5,(a3)
	ENDIF
	btst #1,d7
	beq.s ammxlinefill_ENDLINEBPL1_F
	IFND CLEAR_NONSET_PIXELS
	move.l a2,a3
	adda.w #10240,a3
	ENDIF
	bset d5,(a3) ; plot optimized!!!
ammxlinefill_ENDLINEBPL1_F

	bra.s ammxlinefill_LINESTARTITER_F

ammxlinefill_ENDLINE_F:
	IFD ASM_DEBUG
	movem.l (sp)+,d0-d6/a0-a6
	ELSE
	movem.l (sp)+,d0-d7/a2
	ENDIF
	rts

; start of vertical routines
ammxlinefill_linemgreater1:
	
	movem.l d0-d7/a2,-(sp) ; stack save
	
	move.l LINEVERTEX_START_PUSHED,d2
	move.l LINEVERTEX_END_PUSHED,d3

	swap d2
	swap d3

	;Calculate dx = x2-x1
    ;Calculate dy = y2-y1
	PSUBW d2,d3,E5 ; e5 will contain deltas

	;Calculate i1=2*dy
	PADDW E5,E5,E6 ; I1 is on the lower 2 bytes of E6

	VPERM #$45454545,E5,E5,E8 ; Put DeltaX in all e8
	VPERM #$6767EFEF,E6,E5,E7 ; E7 = I1 I1 Dy Dy

	PSUBW E8,E7,E9; E9 : first word  i1-dx and third word dy-dx
	
	;Calculate i2=2*(dy-dx)
    ;Calculate d=i1-dx

	; decision variable to D4
	VPERM #$01010101,E9,E9,D4 ; d calculated  in D4
	PADDW E9,E9,E9            ; i2 calculated in E9

	; check if dx < or > 0
	VPERM #$45454545,e5,e5,d5
	
	; We are here if point greather than zero
	vperm #$45454545,d2,d2,d0 ; x = x1 (x1 is the start)
	vperm #$67676767,d2,d2,d1 ; y = y1 (y1 is the start)
	VPERM #$45454545,d3,d3,d6 ; xend = x2

	; print pixel routine
	bsr.w plotpointv ; PLOT POINT!!
ammxlinefill_LINESTARTITER_F3:

	; interate for each x until x<=xend
	cmp.w d0,d6
	blt.s ammxlinefill_ENDLINE_F3 ; if x>=xend exit

	cmp.w #0,d4 ; check if d<0
	blt.s ammxlinefill_POINT_D_LESS_0_F3 ; branch if id<0

	; we are here if d>=0
	paddw e9,d4,d4 ; d = i2+ d
	addq #1,d1 ; x = x+1
	; start optimization
	subq.w #1,d5
	move.b d5,d7
	andi.l #$00000007,d7
	addq.b #1,d7
	lsr.b #3,d7
	adda.l d7,a2
	;end optimization
	bra.s ammxlinefill_POINT_D_END_F3

ammxlinefill_POINT_D_LESS_0_F3:
	; we are here if d<0
	paddw e6,d4,d4 ; d = i1+ d 

ammxlinefill_POINT_D_END_F3:
	addq #1,d0

	; print pixel routine
	;bsr.w plotpointv ; PLOT POINT!!
	; start optimization
	;subq.b #1,d5
	;move.b d5,d7
	;andi.l #$00000007,d7
	;addq.b #1,d7
	;lsr.b #3,d7
	;adda.l d7,a2
	adda.w #$0028,a2
	vperm #$000000000000000F,e21,e22,d7

	IFD CLEAR_NONSET_PIXELS
	bclr d5,(a2) ; plot optimized!!!
	ENDIF
	btst #0,d7
	beq.s ammxlinefill_ENDLINEBPL0_F3
	bset d5,(a2) ; plot optimized!!!
ammxlinefill_ENDLINEBPL0_F3:
	IFD CLEAR_NONSET_PIXELS
	move.l a2,a3
	adda.w #10240,a3
	bclr d5,(a3)
	ENDIF
	btst #1,d7
	beq.s ammxlinefill_ENDLINEBPL1_F3
	IFND CLEAR_NONSET_PIXELS
	move.l a2,a3
	adda.w #10240,a3
	ENDIF
	bset d5,(a3) ; plot optimized!!!
ammxlinefill_ENDLINEBPL1_F3

	bra.s ammxlinefill_LINESTARTITER_F3

ammxlinefill_ENDLINE_F3:
	movem.l (sp)+,d0-d7/a2
	rts


FILL_TABLE:
	dcb.b 4*256,$FF

