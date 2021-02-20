_NUMPOINTS EQU 7

	SECTION AMMX,CODE_F

	include "tables.i"

    XDEF _ammxmainloop
    XDEF _ammxmainloop2
	XDEF _ammxmainloop3
	XDEF _ammxmainloop4
	XDEF _ammxmainloop5
	XDEF _ammxmainloop6
	XDEF _ammxmainloop7

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


; d0 ==> x
; d1 ==> y
; d2 ===> x1 y1
; d3 ===> x2 y2
; d4 ===> decision
; e6 ===> I1

_ammxmainloop4:
	
	move.l 4(sp),par1 ; argument save
	movem.l d0-d6/a0-a6,-(sp) ; stack save
	move.l par1,a1
	;LOAD LINEVERTEX,E4 ; Load X1Y1X2Y2 
	;VPERM #45456767,E4,E4,E5
	move.l LINEVERTEX_START,d2
	move.l LINEVERTEX_END,d3

	;Calculate dx = x2-x1
    ;Calculate dy = y2-y1
	PSUBW d2,d3,E5 ; e5 will contain deltas

	;Calculate i1=2*dy
	PADDW E5,E5,E6 ; I1 is on the lower 2 bytes of E6
	


	STORE E5,(a1)

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
	cmp.w #0,d5
	blt.s POINT_MIN_0 ; branch if < 0 (signed comparison)
	; We are here if point greather than zero
	vperm #$45454545,d2,d2,d0 ; x = x1 (x1 is the start)
	vperm #$67676767,d2,d2,d1 ; y = y1 (y1 is the start)
	VPERM #$45454545,d3,d3,d6 ; xend = x2
	bra.s POINT_END
POINT_MIN_0
	; We are here if point less than zero
	vperm #$45454545,d3,d3,d0 ; x = x2 (x2 is the start)
	vperm #$67676767,d3,d3,d1 ; y = y2 (y2 is the start)
	VPERM #$45454545,d2,d2,d6 ; xend = x1

POINT_END:

	; variant, use cmp
	;pcmpgtw #$0000,E8,e0

	; print pixel routine
	move.w d0,(a1)+
	move.w d1,(a1)+

	;STORE d1,(a1)
	;moveq #8,d6
LINESTARTITER:

	; interate for each x until x<=xend
	cmp.w d0,d6
	blt.s ENDLINE ; if x>=xend exit

	cmp.w #0,d4 ; check if d<0
	blt.s POINT_D_LESS_0 ; branch if id<0

	; we are here if d>=0
	paddw e9,d4,d4 ; d = i2+ d
	addq #1,d1 ; y = y+1
	bra.s POINT_D_END

POINT_D_LESS_0:
	; we are here if d<0
	paddw e6,d4,d4 ; d = i1+ d 
	

POINT_D_END:
	addq #1,d0

	; print pixel routine
	move.w d0,(a1)+
	move.w d1,(a1)+

	bra.s LINESTARTITER


ENDLINE:
	movem.l (sp)+,d0-d6/a0-a6
	rts

LINEVERTEX_START:
	dc.w 1 ; X1
	dc.w 1 ; Y1
LINEVERTEX_END:
	dc.w 8 ; X2
	dc.w 5 ; Y2


; build line from 8 5 to 1 1 (down in cartesian plane but up on screen)
; d0 ==> x
; d1 ==> y
; d2 ===> x1 y1
; d3 ===> x2 y2
; d4 ===> decision
; e6 ===> I1

_ammxmainloop5:
	
	move.l 4(sp),par1 ; argument save
	movem.l d0-d6/a0-a6,-(sp) ; stack save
	move.l par1,a1
	;LOAD LINEVERTEX,E4 ; Load X1Y1X2Y2 
	;VPERM #45456767,E4,E4,E5
	move.l LINEVERTEX_START_2,d2
	move.l LINEVERTEX_END_2,d3

	; queste 2 move sotto sono solo un test, va swappata la y1 di d2 con quella di d3
	;move.l #$00010001,d2
	;move.l #$00080005,d3
	move.b d2,d4
	move.b d3,d2
	move.b d4,d3

	;Calculate dx = x2-x1
    ;Calculate dy = y2-y1
	PSUBW d2,d3,E5 ; e5 will contain deltas

	;Calculate i1=2*dy
	PADDW E5,E5,E6 ; I1 is on the lower 2 bytes of E6
	


	STORE E5,(a1)

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
	;cmp.w #0,d5
	;blt.s POINT_MIN_0_2 ; branch if < 0 (signed comparison)
	; We are here if point greather than zero
	vperm #$45454545,d2,d2,d0 ; x = x1 (x1 is the start)
	vperm #$67676767,d3,d3,d1 ; y = y1 (y1 is the start)
	VPERM #$45454545,d3,d3,d6 ; xend = x2
	;bra.s POINT_END_2
;POINT_MIN_0_2
	; We are here if point less than zero
	;vperm #$45454545,d3,d3,d0 ; x = x2 (x2 is the start)
	;vperm #$67676767,d3,d3,d1 ; y = y2 (y2 is the start)
	;VPERM #$45454545,d2,d2,d6 ; xend = x1

;POINT_END_2:

	; variant, use cmp
	;pcmpgtw #$0000,E8,e0

	; print pixel routine
	move.w d0,(a1)+
	move.w d1,(a1)+

	;STORE d1,(a1)
	;moveq #8,d6
LINESTARTITER_2:

	; interate for each x until x<=xend
	cmp.w d0,d6
	blt.s ENDLINE_2 ; if x>=xend exit

	cmp.w #0,d4 ; check if d<0
	blt.s POINT_D_LESS_0_2 ; branch if id<0

	; we are here if d>=0
	paddw e9,d4,d4 ; d = i2+ d
	subq #1,d1 ; y = y-1
	bra.s POINT_D_END_2

POINT_D_LESS_0_2:
	; we are here if d<0
	paddw e6,d4,d4 ; d = i1+ d 
	

POINT_D_END_2:
	addq #1,d0

	; print pixel routine
	move.w d0,(a1)+
	move.w d1,(a1)+

	bra.s LINESTARTITER_2


ENDLINE_2:
	movem.l (sp)+,d0-d6/a0-a6
	rts

LINEVERTEX_START_2:
	dc.w 1 ; X1
	dc.w 5 ; Y1
LINEVERTEX_END_2:
	dc.w 8 ; X2
	dc.w 1 ; Y2


_ammxmainloop6:
	
	move.l 4(sp),par1 ; argument save
	movem.l d0-d6/a0-a6,-(sp) ; stack save
	move.l par1,a1
	
	move.l LINEVERTEX_START_3,d2
	move.l LINEVERTEX_END_3,d3

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
	move.w d1,(a1)+
	move.w d0,(a1)+

	;STORE d1,(a1)
	;moveq #8,d6
LINESTARTITER_3:

	; interate for each x until x<=xend
	cmp.w d0,d6
	blt.s ENDLINE_3 ; if x>=xend exit

	cmp.w #0,d4 ; check if d<0
	blt.s POINT_D_LESS_0_3 ; branch if id<0

	; we are here if d>=0
	paddw e9,d4,d4 ; d = i2+ d
	addq #1,d1 ; y = y+1
	bra.s POINT_D_END_3

POINT_D_LESS_0_3:
	; we are here if d<0
	paddw e6,d4,d4 ; d = i1+ d 
	

POINT_D_END_3:
	addq #1,d0

	; print pixel routine
	move.w d1,(a1)+
	move.w d0,(a1)+

	bra.s LINESTARTITER_3


ENDLINE_3:
	movem.l (sp)+,d0-d6/a0-a6
	rts

LINEVERTEX_START_3:
	dc.w 1 ; X1
	dc.w 1 ; Y1
LINEVERTEX_END_3:
	dc.w 5 ; X2
	dc.w 8 ; Y2













	; build line from 8 5 to 1 1 (down in cartesian plane but up on screen)
; d0 ==> x
; d1 ==> y
; d2 ===> x1 y1
; d3 ===> x2 y2
; d4 ===> decision
; e6 ===> I1

_ammxmainloop7:
	
	move.l 4(sp),par1 ; argument save
	movem.l d0-d6/a0-a6,-(sp) ; stack save
	move.l par1,a1
	
	move.l LINEVERTEX_START_4,d2
	move.l LINEVERTEX_END_4,d3

	; queste 2 move sotto sono solo un test, va swappata la y1 di d2 con quella di d3
	;move.l #$00010001,d2
	;move.l #$00080005,d3
	move.b d2,d4
	move.b d3,d2
	move.b d4,d3

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
	;cmp.w #0,d5
	;blt.s POINT_MIN_0_2 ; branch if < 0 (signed comparison)
	; We are here if point greather than zero
	vperm #$45454545,d2,d2,d0 ; x = x1 (x1 is the start)
	vperm #$67676767,d3,d3,d1 ; y = y1 (y1 is the start)
	VPERM #$45454545,d3,d3,d6 ; xend = x2
	;bra.s POINT_END_2
;POINT_MIN_0_2
	; We are here if point less than zero
	;vperm #$45454545,d3,d3,d0 ; x = x2 (x2 is the start)
	;vperm #$67676767,d3,d3,d1 ; y = y2 (y2 is the start)
	;VPERM #$45454545,d2,d2,d6 ; xend = x1

;POINT_END_2:

	; variant, use cmp
	;pcmpgtw #$0000,E8,e0

	; print pixel routine
	move.w d1,(a1)+
	move.w d0,(a1)+

	;STORE d1,(a1)
	;moveq #8,d6
LINESTARTITER_4:

	; interate for each x until x<=xend
	cmp.w d0,d6
	blt.s ENDLINE_4 ; if x>=xend exit

	cmp.w #0,d4 ; check if d<0
	blt.s POINT_D_LESS_0_4 ; branch if id<0

	; we are here if d>=0
	paddw e9,d4,d4 ; d = i2+ d
	subq #1,d1 ; y = y-1
	bra.s POINT_D_END_4

POINT_D_LESS_0_4:
	; we are here if d<0
	paddw e6,d4,d4 ; d = i1+ d 
	

POINT_D_END_4:
	addq #1,d0

	; print pixel routine
	move.w d1,(a1)+
	move.w d0,(a1)+

	bra.s LINESTARTITER_4


ENDLINE_4:
	movem.l (sp)+,d0-d6/a0-a6
	rts

LINEVERTEX_START_4:
	dc.w 1 ; X1
	dc.w 8 ; Y1
LINEVERTEX_END_4:
	dc.w 5 ; X2
	dc.w 1 ; Y2