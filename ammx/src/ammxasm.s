_NUMPOINTS EQU 7

	SECTION AMMX,CODE_F

	include "tables.i"

    XDEF _ammxmainloop:
    XDEF _ammxmainloop2:
	XDEF _ammxmainloop3:

DATAIN:
    dc.l $AAAAAAAA
    dc.l $BBBBBBBB
par1:
    dc.l 0

_ammxmainloop:
    move.l 4(sp),par1 ; bitplane poiner
	movem.l d0-d6/a0-a6,-(sp)
    move.l par1,a1

    lea DATAIN,A0
    LOAD    (A0),D1
    STORE   D1,(a1)
    
    movem.l (sp)+,d0-d6/a0-a6
    rts

; ------------------ test 2 - draw some concentric circles
_ammxmainloop2:
    move.l 4(sp),par1 ; argument save
	movem.l d0-d6/a0-a6,-(sp) ; stack save
    move.l par1,a1 ; argument address in a1 (bitplane 0 addr)

	; start of increase angle routine - each frame the angle will be increased by 1 deg 
	addi.w #1,ANGLE
	move.w ANGLE,D0 ; set angle
	cmp.w #359,d0
	bls.s noresetangle
	; things to do after 360 is reached
	moveq #0,d0
	move.w #0,ANGLE
	; increase radius by one after a full rotation
	addi.w #1,COORDX
	addi.w #1,COORDY
	addi.w #1,COORDX_2
	addi.w #1,COORDY_2

	
noresetangle:
	LOAD COORDS,E4 ; Load XY input data in register for pmula
	lea COS_SIN_SIN_COSINV_TABLE,b1   ; Cos and SIN in b1 (precalculated * 256)
	LOAD (b1,D0.w*8),E5 ; Load precalculated sin/cos values to register E5

    PMULL E4,E5,E7 ; Calculate rotation with formula x*cos(a) ## y*sin(a) ## x*sin(a) ## -y*cos(a)

    ;ammx mode - copy the result in E8 but 16bit shifted
    dc.w $fe7c,$f038,$0000,$0000,$0000,$0010  ; LSL.Q  #16,E7,E8
    PADDW    E7,E8,E9 ; add x*cos(a) + y*sin(a) and x*sin(a) -y*cos(a) in one shot

    ;STORE   E7,(a1) debug commented

    VPERM #$01010101,E9,E9,D0 ; result of first addition to d0
    VPERM #$45454545,E9,E9,D1 ; result of first addition to d1
    
    ; divide by eight
	asr.w #8,d0
    asr.w #8,d1

	; translate
	add.w #160,d0
	add.w #128,d1

    ;move.w d0,(a1)+ debug commented
    ;move.w d1,(a1)  debug commented
    ;STORE   E8,(a1) debug commented

	; clip routine - dont plot if outside the screen
	cmpi.w #0,d0 ; X min 0
	blt.s endplot
	cmp.w #319,d0
	bgt.s endplot
	cmp.w #0,d1
	blt.s endplot
	cmp.w #255,d1
	bgt.s endplot

	lea PLOTREFS,a0

	; start plot routine
	add.w d1,d1
	move.w 0(a0,d1.w),d1
	move.w d0,d2
	lsr.w #3,d2
	add.w d2,d1
	not.b d0
	bset d0,0(a1,d1.w)
endplot:

    movem.l (sp)+,d0-d6/a0-a6
    rts

ANGLE:
	dc.w 0
COORDS:
COORDX:
    dc.w 30
COORDY:
    dc.w 30
COORDX_2:
    dc.w 30
COORDY_2:
    dc.w 30

OLDX:
	dc.w 0
OLDY
	dc.w 0

;TRIG:
;COSA:
;    dc.w 256
;SINA:
;    dc.w 0
;COSA_2:
;    dc.w 256
;SINA_2:
;    dc.w 0

; ------------------ test 3 - rotate points
_ammxmainloop3:
    move.l 4(sp),par1 ; argument save
	movem.l d0-d6/a0-a6,-(sp) ; stack save
    move.l par1,a1 ; argument address in a1 (bitplane 0 addr)

	; start delete old point routine
	lea PLOTREFS,a0
	lea OLDCOORDS,A2

	cmp.w #0,CLEARPOINTS
	bne.s ENDCLEAR
	
	moveq #_NUMPOINTS-1,d3
STARTCLEAR:
	move.w (a2)+,d0
	move.w (a2)+,d1
	add.w d1,d1
	move.w 0(a0,d1.w),d1
	move.w d0,d2
	lsr.w #3,d2
	add.w d2,d1
	not.b d0
	bclr d0,0(a1,d1.w)
	; end POINTS CLEAR ITERATION
	dbra d3,STARTCLEAR
ENDCLEAR:
    
	; start of increase angle routine - each frame the angle will be increased by 1 deg 
	addi.w #1,ANGLE
	move.w ANGLE,D0 ; set angle
	cmp.w #359,d0
	bls.s noresetangle3
	; things to do after 360 is reached
	moveq #0,d0
	move.w #0,ANGLE
	not.w CLEARPOINTS

	

noresetangle3:

	lea LISTCOORDS,a3 ; Coords addr in b0
    lea COS_SIN_SIN_COSINV_TABLE,b1   ; Cos and SIN in b1 (precalculated * 256)

	lea OLDCOORDS,A2
	moveq #_NUMPOINTS-1,d3
STARTPOINTS:
    LOAD (a3),E4 ; Load XY input data in register for pmula

	move.w ANGLE,D0 ; set angle
	LOAD (b1,D0.w*8),E5 ; Load precalculated sin/cos values to register E5

    PMULL E4,E5,E7 ; Calculate rotation with formula x*cos(a) ## y*sin(a) ## x*sin(a) ## -y*cos(a)

    ;ammx mode - copy the result in E8 but 16bit shifted
    dc.w $fe7c,$f038,$0000,$0000,$0000,$0010  ; LSL.Q  #16,E7,E8
    PADDW    E7,E8,E9 ; add x*cos(a) + y*sin(a) and x*sin(a) -y*cos(a) in one shot

    ;STORE   E7,(a1) debug commented

    VPERM #$01010101,E9,E9,D0 ; result of first addition to d0
    VPERM #$45454545,E9,E9,D1 ; result of first addition to d1
    
    ; divide by eight
	asr.w #8,d0
    asr.w #8,d1

	; translate
	add.w #160,d0
	add.w #128,d1

    ;move.w d0,(a1)+ debug commented
    ;move.w d1,(a1)  debug commented
    ;STORE   E8,(a1) debug commented

	; clip routine - dont plot if outside the screen
	cmpi.w #0,d0 ; X min 0
	blt.s endplot3
	cmp.w #319,d0
	bgt.s endplot3
	cmp.w #0,d1
	blt.s endplot3
	cmp.w #255,d1
	bgt.s endplot3

	;save old values
	
	move.w d0,(a2)+
	move.w d1,(a2)+

	lea PLOTREFS,a0

	; start plot routine
	add.w d1,d1
	move.w 0(a0,d1.w),d1
	move.w d0,d2
	lsr.w #3,d2
	add.w d2,d1
	not.b d0
	bset d0,0(a1,d1.w)
endplot3:

	; end POINTS ITERATION
	adda.l #8,a3
	dbra d3,STARTPOINTS

    movem.l (sp)+,d0-d6/a0-a6
    rts

LISTCOORDS:

    dc.w 0
    dc.w 0
    dc.w 0
    dc.w 0

    dc.w 6
    dc.w -11
    dc.w 6
    dc.w -11

	dc.w 16
    dc.w -21
    dc.w 16
    dc.w -21

	dc.w 31
    dc.w -25
    dc.w 31
    dc.w -25

	dc.w 31
    dc.w -34
    dc.w 31
    dc.w -34

	dc.w 46
    dc.w -23
    dc.w 46
    dc.w -23

	dc.w 46
    dc.w -33
    dc.w 46
    dc.w -33

OLDCOORDS:
	dc.w 0
	dc.w 0

	dc.w 0
	dc.w 0

	dc.w 0
	dc.w 0

	dc.w 0
	dc.w 0

	dc.w 0
	dc.w 0

	dc.w 0
	dc.w 0

	dc.w 0
	dc.w 0

CLEARPOINTS:
	dc.w 0

	


