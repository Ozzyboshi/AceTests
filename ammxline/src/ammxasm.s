DEBUG EQU 1
	IIF DEBUG moveq #0,d0
	IFEQ DEBUG
	moveq #0,d0
	ENDIF
LOL=1
	IFD LOL
	ENDIF

BITPLANE_MEM_OPT:
	dc.w 0

BITPLANE_OPT MACRO
	lea BITPLANE_MEM_OPT,a1
	move.w \1,(a1)+
ENDM

TRANSLATE_MEM_2D:
TRANSLATE_MEM_2D_X:
	dc.w 0
TRANSLATE_MEM_2D_Y:
	dc.w 0

TRANSLATE2D MACRO
	lea TRANSLATE_MEM_2D,a1
	move.w \1,(a1)+
	move.w \2,(a1)+
	ENDM

DRAWLINE2D	MACRO
	lea LINEVERTEX_START_FINAL,a1
	move.w \1,(a1)+
	move.w \2,(a1)+
	move.w \3,(a1)+
	move.w \4,(a1)+
	load \5,e22
	load #0000000000000000,e21 ;optimisation
	bsr.w _ammxmainloop8
	ENDM

PREPARESCREEN MACRO
	; copy from fast bitplanes to slow bitplanes
	move.l #5*255,d3
	lea SCREEN_0,a0
	lea SCREEN_1,a4
	
	load #0,e0

	move.l bitplane0,a1
	move.l bitplane1,a2
preparescreenclearline:
	load (a0),e20
	load (a4),e21
	store e20,(a1)+
	store e21,(a2)+
	store e0,(a0)+
	store e0,(a4)+
	dbra d3,preparescreenclearline
	ENDM


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
	XDEF _ammxmainloop8
	XDEF _ammxmainloop9
	XDEF _ammxmainloop10
	XDEF _ammxmainloopQ
	XDEF _ammxmainloopclear
	XDEF _wait1
	XDEF _wait2

DATAIN:
    dc.l $AAAAAAAA
    dc.l $BBBBBBBB
par1:
    dc.l 0
par2:
	dc.l 0
bitplanelist:
	dc.l 99999999
bitplane0:
	dc.l 0
bitplane1:
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

; Final round
; - pick lowest x first
; - check if both coords are between screen limits
; - select one of the 4 drawing routines
_ammxmainloop8:
	IFD ASM_DEBUG
	move.l 4(sp),par1 ; argument save
	move.l 8(sp),par2
	move.l 12(sp),bitplane0
	ENDIF
	
	movem.l d0-d6/a0-a6,-(sp) ; stack save
	move.l par1,a1
	lea LINEVERTEX_START_PUSHED,a2
	
	; - pick lowest first x
	move.l LINEVERTEX_START_FINAL,d2
	cmp.l LINEVERTEX_END_FINAL,d2
	blt.s ammxmainloop8_lowestless ;  check if first x is lower if this is the case jump to endammxmainloop8
	move.l LINEVERTEX_START_FINAL,d3
	move.l LINEVERTEX_END_FINAL,d2
	bra.s endammxmainloop8phase1
ammxmainloop8_lowestless:
	move.l LINEVERTEX_END_FINAL,d3

; apply translation
	move.l TRANSLATE_MEM_2D_X,d4
	paddw d2,d4,d2
	paddw d3,d4,d3

endammxmainloop8phase1 ; end of first check
	; - pick lowest first x end
	move.l d2,(a2)+
	move.l d3,(a2)+
	IFD ASM_DEBUG
	move.l d2,(a1)+
	move.l d3,(a1)+
	ENDIF

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
	blt.s dylessthan
	IFD ASM_DEBUG
	move.w #2,(a1)+
	ENDIF
	cmp.w d2,d3
	bls.s gotolessminus1
	bsr.w linemgreater1		; vertical line
	bra.s endammxmainloop8phase2
gotolessminus1:
	bsr.w linemlessminus1
	bra.s endammxmainloop8phase2


dylessthan:
	IFD ASM_DEBUG
	move.w #1,(a1)+
	ENDIF
	cmp.w d2,d3
	bls.s goto0tominus1
	;bsr.w linem0to1
	bra.s endammxmainloop8phase2
goto0tominus1:
	;bsr.w linem0tominus1
	nop
endammxmainloop8phase2:
endammxmainloop8:
	movem.l (sp)+,d0-d6/a0-a6
	rts

LINEVERTEX_START_FINAL:
	dc.w 2 ; X1
	dc.w 1 ; Y1
LINEVERTEX_END_FINAL:
	dc.w 1 ; X2
	dc.w 8 ; Y2

; d0 ==> x
; d1 ==> y
; d2 ===> x1 y1
; d3 ===> x2 y2
; d4 ===> decision
; e6 ===> I1

linem0to1:
	
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
	
	;Calculate i2=2*(dy-dx)
    ;Calculate d=i1-dx

	; decision variable to D4
	VPERM #$01010101,E9,E9,D4 ; d calculated  in D4
	PADDW E9,E9,E9            ; i2 calculated in E9

	vperm #$45454545,d2,d2,d0 ; x = x1 (x1 is the start)
	vperm #$67676767,d2,d2,d1 ; y = y1 (y1 is the start)
	VPERM #$45454545,d3,d3,d6 ; xend = x2

	; print pixel routine
	IFD ASM_DEBUG
	move.w d0,(a1)+
	move.w d1,(a1)+
	ENDIF
	bsr.w plotpoint ; PLOT POINT!!

LINESTARTITER_F:

	; interate for each x until x<=xend
	cmp.w d0,d6
	blt.s ENDLINE_F ; if x>=xend exit

	cmp.w #0,d4 ; check if d<0
	blt.s POINT_D_LESS_0_F ; branch if id<0

	; we are here if d>=0
	paddw e9,d4,d4 ; d = i2+ d
	addq #1,d1 ; y = y+1
	adda.w #$0028,a2 ; optimization , go to next line in bitplane
	bra.s POINT_D_END_F

POINT_D_LESS_0_F:
	; we are here if d<0
	paddw e6,d4,d4 ; d = i1+ d 
	
POINT_D_END_F:
	addq #1,d0

	; print pixel routine
	IFD ASM_DEBUG
	move.w d0,(a1)+
	move.w d1,(a1)+
	ENDIF

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
	btst #0,d7
	beq.s ENDLINEBPL0_F
	bset d5,(a2) ; plot optimized!!!

	; opt bitplane 1
ENDLINEBPL0_F:
	btst #1,d7
	beq.s ENDLINEBPL1_F
	move.l a2,a3
	adda.w #10240,a3
	bset d5,(a3) ; plot optimized!!!
ENDLINEBPL1_F

	bra.s LINESTARTITER_F

ENDLINE_F:
	IFD ASM_DEBUG
	movem.l (sp)+,d0-d6/a0-a6
	ELSE
	movem.l (sp)+,d0-d7/a2
	ENDIF
	rts

LINEVERTEX_START_PUSHED:
	dc.w 0 ; X1
	dc.w 0 ; Y1
LINEVERTEX_END_PUSHED:
	dc.w 0 ; X2
	dc.w 0 ; Y2

; build line from 8 5 to 1 1 (down in cartesian plane but up on screen)
; d0 ==> x
; d1 ==> y
; d2 ===> x1 y1
; d3 ===> x2 y2
; d4 ===> decision
; e6 ===> I1

linem0tominus1:

	IFD ASM_DEBUG
	movem.l d0-d6/a0-a6,-(sp) ; stack save
	move.l par2,a1
	ELSE
	movem.l d0-d7/a2,-(sp) ; stack save
	ENDIF

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

	; print pixel routine
	IFD ASM_DEBUG
	move.w d0,(a1)+
	move.w d1,(a1)+
	ENDIF

	bsr.w plotpoint ; PLOT POINT!!

LINESTARTITER_F2:

	; interate for each x until x<=xend
	cmp.w d0,d6
	blt.s ENDLINE_F2 ; if x>=xend exit

	cmp.w #0,d4 ; check if d<0
	blt.s POINT_D_LESS_0_F2 ; branch if id<0

	; we are here if d>=0
	paddw e9,d4,d4 ; d = i2+ d
	subq #1,d1 ; y = y-1
	suba.w #$0028,a2 ; optimization , go to next line in bitplane
	bra.s POINT_D_END_F2

POINT_D_LESS_0_F2:
	; we are here if d<0
	paddw e6,d4,d4 ; d = i1+ d 
	
POINT_D_END_F2:
	addq #1,d0

	; print pixel routine
	IFD ASM_DEBUG
	move.w d0,(a1)+
	move.w d1,(a1)+
	ENDIF
	;bsr.w plotpoint ; PLOT POINT!!

	; start optimization
	subq.b #1,d5
	move.b d5,d7
	andi.l #$00000007,d7
	addq.b #1,d7
	lsr.b #3,d7
	adda.l d7,a2
	vperm #$000000000000000F,e21,e22,d7
	btst #0,d7
	beq.s ENDLINEBPL0_F2
	bset d5,(a2) ; plot optimized!!!

	; opt bitplane 1
ENDLINEBPL0_F2:
	btst #1,d7
	beq.s ENDLINEBPL1_F2
	move.l a2,a3
	adda.w #10240,a3
	bset d5,(a3) ; plot optimized!!!
ENDLINEBPL1_F2

	bra.s LINESTARTITER_F2


ENDLINE_F2:
	IFD ASM_DEBUG
	movem.l (sp)+,d0-d6/a0-a6
	ELSE
	movem.l (sp)+,d0-d7/a2
	ENDIF
	rts

; start of vertical routines
linemgreater1:
	
	IFD ASM_DEBUG
	movem.l d0-d6/a0-a6,-(sp) ; stack save
	move.l par2,a1
	ELSE
	movem.l d0-d7/a2,-(sp) ; stack save
	ENDIF
	
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
	IFD ASM_DEBUG
	move.w d1,(a1)+
	move.w d0,(a1)+
	ENDIF
	moveq #8,d0
	moveq #8,d1
	bsr.w plotpointv ; PLOT POINT!!
	;movem.l (sp)+,d0-d7/a2
	;rts

LINESTARTITER_F3:

	; interate for each x until x<=xend
	cmp.w d0,d6
	blt.s ENDLINE_F3 ; if x>=xend exit

	cmp.w #0,d4 ; check if d<0
	blt.s POINT_D_LESS_0_F3 ; branch if id<0

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
	bra.s POINT_D_END_F3

POINT_D_LESS_0_F3:
	; we are here if d<0
	paddw e6,d4,d4 ; d = i1+ d 

POINT_D_END_F3:
	addq #1,d0

	; print pixel routine
	IFD ASM_DEBUG
	move.w d1,(a1)+
	move.w d0,(a1)+
	ENDIF
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
	btst #0,d7
	beq.s ENDLINEBPL0_F3
	bset d5,(a2) ; plot optimized!!!
ENDLINEBPL0_F3:
	btst #1,d7
	beq.s ENDLINEBPL1_F3
	move.l a2,a3
	adda.w #10240,a3
	bset d5,(a3) ; plot optimized!!!
ENDLINEBPL1_F3

	bra.s LINESTARTITER_F3

ENDLINE_F3:
	IFD ASM_DEBUG
	movem.l (sp)+,d0-d6/a0-a6
	ELSE
	movem.l (sp)+,d0-d7/a2
	ENDIF
	rts

linemlessminus1:
	IFD ASM_DEBUG
	movem.l d0-d6/a0-a6,-(sp) ; stack save
	move.l par2,a1
	ELSE
	movem.l d0-d7/a2,-(sp) ; stack save
	ENDIF
	
	move.l LINEVERTEX_START_PUSHED,d2
	move.l LINEVERTEX_END_PUSHED,d3

	move.w d2,d4
	move.w d3,d2
	move.w d4,d3

	swap d2
	swap d3

	load #-0000000000000040,e10

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
	
	; print pixel routine
	IFD ASM_DEBUG
	move.w d1,(a1)+
	move.w d0,(a1)+
	ENDIF

	bsr.w plotpointv ; PLOT POINT!!

	;movem.l (sp)+,d0-d7/a2
	;rts

LINESTARTITER_F4:

	; interate for each x until x<=xend
	cmp.w d0,d6
	blt.s ENDLINE_F4 ; if x>=xend exit

	cmp.w #0,d4 ; check if d<0
	blt.s POINT_D_LESS_0_F4 ; branch if id<0

	; we are here if d>=0
	paddw e9,d4,d4 ; d = i2+ d
	subq #1,d1 ; y = y-1
	; start optimization
	subq.w #1,d5
	move.b d5,d7
	andi.l #$00000007,d7
	addq.b #1,d7
	lsr.b #3,d7
	adda.l d7,a2
	;end optimization
	bra.s POINT_D_END_F4

POINT_D_LESS_0_F4:
	; we are here if d<0
	paddw e6,d4,d4 ; d = i1+ d 
	

POINT_D_END_F4:
	addq #1,d0

	; print pixel routine
	IFD ASM_DEBUG
	move.w d1,(a1)+
	move.w d0,(a1)+
	ENDIF
	;bsr.w plotpointv ; PLOT POINT!!

	vperm #$45674567,e10,e10,d7
	suba.w d7,a2
	vperm #$000000000000000F,e21,e22,d7
	btst #0,d7
	beq.s ENDLINEBPL0_F4
	bset d5,(a2) ; plot optimized!!!
ENDLINEBPL0_F4:
	btst #1,d7
	beq.s ENDLINEBPL1_F4
	move.l a2,a3
	adda.w #10240,a3
	bset d5,(a3) ; plot optimized!!!
ENDLINEBPL1_F4

	bra.s LINESTARTITER_F4

ENDLINE_F4:
	IFD ASM_DEBUG
	movem.l (sp)+,d0-d6/a0-a6
	ELSE
	movem.l (sp)+,d0-d7/a2
	ENDIF
	rts

; plotpoint routine
; before calling this routine set
; x ==> d1 (word)
; y ==> d0 (word)
; plotrefs bust be build precalculated
; e22 filled with bitplane flags
; bitplaneX must be loaded with real bitplane addresses
plotpoint:
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

	; First bitplane
	btst #0,d3
	beq.s plotpoint_nofirstbitplane
	lea SCREEN_0,a0
	bset d0,(a0,d1.w)
plotpoint_nofirstbitplane:

	; Second bitplane
	btst #1,d3
	beq.s plotpoint_nosecondbitplane
	lea SCREEN_1,a0
	bset d0,(a0,d1.w)
plotpoint_nosecondbitplane:

	; WARNING!!!!!! line optimization, save d0 in d5 so that the caller can calculate the next X without reentering here
	move.b d0,d5
	lea SCREEN_0,a2
	adda.w d1,a2

	;exit plotpoint
	movem.l (sp)+,d0-d3/a0-a1
	rts

; plotpoint routine
; before calling this routine set
; x ==> d1 (word)
; y ==> d0 (word)
; plotrefs bust be build precalculated
; e23 filled with bitplane flags
; bitplaneX must be loaded with real bitplane addresses
plotpointv:
	movem.l d0-d3/a0-a1,-(sp) ; stack save
	lea PLOTREFS,a1
	vperm #$000000000000000F,e21,e22,d3 ; optimisation, e21 must be all zeroes from the caller

	; start plot routine
	add.w d0,d0
	move.w 0(a1,d0.w),d0
	move.w d1,d2
	lsr.w #3,d2
	add.w d2,d0
	not.b d1

	; First bitplane
	btst #0,d3
	beq.s plotpointv_nofirstbitplane
	lea SCREEN_0,a0
	bset d1,0(a0,d0.w)
plotpointv_nofirstbitplane:

	; Second bitplane
	btst #1,d3
	beq.s plotpointv_nosecondbitplane
	lea SCREEN_1,a0
	bset d1,0(a0,d0.w)
plotpointv_nosecondbitplane:

	; WARNING!!!!!! line optimization, save d0 in d5 so that the caller can calculate the next X without reentering here
	move.b d1,d5
	lea SCREEN_0,a2
	adda.w d0,a2

	movem.l (sp)+,d0-d3/a0-a1
	rts

	_ammxmainloop9:
	;move.l 4(sp),bitplane0
	move.l 4(sp),par1
	;move.l 8(sp),bitplanelist
	movem.l d0-d6/a0-a6,-(sp) ; stack save
	move.l par1,A0
	;move.l (a0),a2
	move.l (a0)+,bitplane0
	move.l (a0),bitplane1

	; copy from fast bitplanes to slow bitplanes
	move.l #5*255,d3
	lea SCREEN_0,a0
	lea SCREEN_1,a4

	move.l bitplane0,a1
	move.l bitplane1,a2
ammxloopclearline:
	load (a0)+,e20
	load (a4)+,e21
	store e20,(a1)+
	store e21,(a2)+
	dbra d3,ammxloopclearline

	;lea LINEVERTEX_START_FINAL,a1
	;move.w #10,(a1)+
	;move.w #10,(a1)+
	;move.w #30,(a1)+
	;move.w #30,(a1)+
	;bsr.w _ammxmainloop8

	;move.l (bitplanelist),bitplane0

	; clear fast bitplanes
	move.l #5*256,d3
	lea SCREEN_0,a0
	lea SCREEN_1,a1
	load #0,e0
drawlineammxloopclear:
	store e0,(a0)+
	store e0,(a1)+
	dbra d3,drawlineammxloopclear
	; end clear fast bitplanes

	BITPLANE_OPT #$23

	moveq #100-1,d3
	addi.w #1,DYNTRANSLATEY
	cmpi.w #200,DYNTRANSLATEY
	bls.s avanti
	move.w #0,DYNTRANSLATEY
avanti:
	;lea DYNTRANSLATEY,A0
	;addi.b #1,(a0)
LINECYCLE:


	move.w DYNTRANSLATEX,d0
	move.w DYNTRANSLATEY,d1
	
	TRANSLATE2D #0,#143
	
	DRAWLINE2D #10,#10,#11,#90,#3
	TRANSLATE2D #0,#0
	DRAWLINE2D #10,#10,#200,#5,#2
	dbra d3,LINECYCLE
	TRANSLATE2D #160,#0
	DRAWLINE2D #10,#100,#20,#20,#3
	movem.l (sp)+,d0-d6/a0-a6
	rts

DYNTRANSLATE:
DYNTRANSLATEX: dc.w 0
DYNTRANSLATEY: dc.w 0

_wait1:
	move.l	#$1ff00,D1	; bit per la selezione tramite AND
	MOVE.L	#$13000,d2	; linea da aspettare = $130, ossia 304
Waity1:
	MOVE.L	$dff004,D0	; VPOSR e VHPOSR - $dff004/$dff006
	AND.L	D1,D0		; Seleziona solo i bit della pos. verticale
	CMP.L	D2,D0		; aspetta la linea $130 (304)
	BNE.S	Waity1
	rts

_wait2:
	MOVE.L	#$1ff00,d1	; bit per la selezione tramite AND
	MOVE.L	#$13000,d2	; linea da aspettare = $130, ossia 304
Aspetta:
	MOVE.L	$dff004,D0	; VPOSR e VHPOSR - $dff004/$dff006
	AND.L	D1,D0		; Seleziona solo i bit della pos. verticale
	CMP.L	D2,D0		; aspetta la linea $130 (304)
	BEQ.S	Aspetta
	rts

_ammxmainloop10:
	;move.l 4(sp),bitplane0
	move.l 4(sp),par1
	move.l 8(sp),bitplanelist
	movem.l d0-d6/a0-a6,-(sp) ; stack save
	move.l par1,A0
	move.l (bitplanelist),(a0)+
	move.l (bitplanelist),a2
	;move.l a2,a3
	move.l (a2),(a0)+
	move.l 4(a2),(a0)+
	;move.l (a3),(a0)
	;move.l (a1),(a0)
	movem.l (sp)+,d0-d6/a0-a6
	rts

_ammxmainloopclear:
	move.l 4(sp),par1
	movem.l d0-d6/a0-a6,-(sp) ; stack save
	move.l par1,A0
	move.l (a0),bitplane0
	move.l 4(a0),bitplane1
	LOAD #0000000000000000,d0

	move.l #5*256,d3
	move.l bitplane0,a0
ammxloopclear:
	store d0,(a0)+
	dbra d3,ammxloopclear

	movem.l (sp)+,d0-d6/a0-a6
	rts

_ammxmainloopQ:
    move.l 4(sp),par1 ; argument save
	movem.l d0-d7/a0-a6,-(sp) ; stack save
    move.l par1,a0 ; argument address in a1 (bitplane 0 addr)
	move.l (a0)+,bitplane0
	move.l (a0),bitplane1

	PREPARESCREEN
	; start of increase angle routine - each frame the angle will be increased by 1 deg 
	addi.w #1,ANGLE
	move.w ANGLE,D0 ; set angle
	cmp.w #10,d0
	bls.s noresetangleq
	moveq #0,d0
	move.w #0,ANGLE
noresetangleq:
	
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

	TRANSLATE2D #160,#0
	DRAWLINE2D #10,#20,#20,#100,#3

	movem.l (sp)+,d0-d7/a0-a6
    rts

SCREEN_0
    dcb.b 40*256,$00

SCREEN_1
    dcb.b 40*256,$00