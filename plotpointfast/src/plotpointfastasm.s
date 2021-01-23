	XDEF _plotpx1bpl
	XDEF _mainasm
	XDEF _initasm


_initasm:
	move.l #25,par2
	move.l #25,par3
	move.l #250,par4 ; (invertito di segno)
	rts

_mainasm:
	move.l 4(sp),par1 ; bitplane poiner
	movem.l d1-d6/a0-a6,-(sp)
	
	move.l par1,a1
	move.l STAR,a2


	; start stars iteration
	moveq #100-1,d3
STARTSTARITER:	

	; load star data
	;lea STARS,a2
	move.l (a2)+,d0
	move.l (a2)+,d1
	;move.w (a2)+,par4

	;subi.l #1,par4
	;cmp.l #-250,par4
	;bne.s dontreset
	;move.l #250,par4

	subi.l #1,(a2)
	cmp.l #-250,(a2)
	bne.s dontreset
	move.l #250,(a2)
	
dontreset:
	move.l (a2)+,d2

	bsr.w perspectiveCalc

	;move.l X,d0 ; X
	;move.l Y,d1 ; Y

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

	; end STARSTARS ITERATION
	dbra d3,STARTSTARITER

exit:
	movem.l (sp)+,d1-d6/a0-a6
	rts

	dc.b "alessio"
	even

perspectiveCalc:
	;move.l par2,d0 ; Xe
	;move.l par3,d1 ; Ye
	;move.l par4,d2 ; Ze
	move.l #256,d6 ; Zu

	move.w #160,d4
	move.w #128,d5

	; start calc
	asl.l #8,d0 ; xe*zu
	asl.l #8,d1 ; ye*zu

	add.w #256,d2

	divs.w d2,d0
	divs.w d2,d1

	add.w d4,d0
	add.w d5,d1

	; output results in ram
	;move.l d0,X
	;move.l d1,Y
	rts

;X:
;	dc.l 0
;Y:
;	dc.l 0


movePoint
	cmpi.w #319,par2
	beq.s dontupdatex
	addi.w #1,par2
dontupdatex
	cmpi.w #255,par3
	beq.s dontupdatey
	addi.w #1,par3
dontupdatey
	rts

_plotpx1bpl:
	move.l 4(sp),par1 ; bitplane poiner
	move.l 8(sp),par2
	move.l 12(sp),par3
	lea PLOTREFS,a0
	movem.l d1-d6/a0-a6,-(sp)
	move.l par1,a1
	move.l par2,d0
	move.l par3,d1
	add.w d1,d1
	move.w 0(a0,d1.w),d1
	move.w d0,d2
	lsr.w #3,d2
	add.w d2,d1
	not.b d0
	bset d0,0(a1,d1.w)
	movem.l (sp)+,d1-d6/a0-a6
	rts
	
	
par1:
	dc.l 0

par2:
	dc.l 0

par3:
	dc.l 0

par4:
	dc.l 0

STAR:
	dc.l STARS


STARS:
	dc.l 106,-75,191
	dc.l 129,-34,184
	dc.l 76,-36,76
	dc.l 68,-106,51
	dc.l 59,-60,159
	dc.l 5,32,139
	dc.l 80,-33,128
	dc.l 127,-104,21
	dc.l 35,-110,136
	dc.l -138,20,92
	dc.l 48,11,120
	dc.l -93,14,148
	dc.l -28,3,153
	dc.l 138,-48,208
	dc.l -63,97,164
	dc.l 52,73,117
	dc.l -91,-27,137
	dc.l -41,-68,187
	dc.l -115,-102,59
	dc.l 124,-69,121
	dc.l -32,-53,139
	dc.l -28,76,7
	dc.l 75,46,111
	dc.l 2,87,71
	dc.l -29,-100,84
	dc.l -67,-28,48
	dc.l 37,105,208
	dc.l 86,85,74
	dc.l 134,102,31
	dc.l -140,26,214
	dc.l -21,33,113
	dc.l 98,87,86
	dc.l -43,-88,25
	dc.l 54,64,237
	dc.l 87,-65,67
	dc.l 106,-63,204
	dc.l -7,35,207
	dc.l -120,68,190
	dc.l -25,-83,255
	dc.l -70,-57,2
	dc.l -92,75,196
	dc.l -116,29,127
	dc.l 62,0,13
	dc.l -18,-31,13
	dc.l -130,25,183
	dc.l -47,43,246
	dc.l -34,-110,105
	dc.l -116,68,251
	dc.l 127,-77,90
	dc.l -29,-8,154
	dc.l -85,29,233
	dc.l -138,75,27
	dc.l -139,-76,7
	dc.l 60,-15,144
	dc.l -134,-68,28
	dc.l 68,56,50
	dc.l 110,102,64
	dc.l 50,54,15
	dc.l 75,57,139
	dc.l -31,-81,34
	dc.l -113,-46,89
	dc.l 61,-8,240
	dc.l -49,-9,45
	dc.l 35,25,54
	dc.l -130,108,133
	dc.l 116,60,12
	dc.l 102,0,181
	dc.l -23,-87,62
	dc.l -22,107,90
	dc.l -37,-101,43
	dc.l 5,-14,36
	dc.l -24,-7,122
	dc.l 73,29,79
	dc.l 8,-99,95
	dc.l -119,-117,19
	dc.l 79,71,242
	dc.l 134,-105,76
	dc.l -5,-105,93
	dc.l 20,-96,206
	dc.l 95,-31,106
	dc.l 56,-99,112
	dc.l 108,-41,60
	dc.l -44,-65,119
	dc.l 76,-75,40
	dc.l -122,-28,34
	dc.l -140,-50,118
	dc.l -113,69,76
	dc.l 4,8,104
	dc.l -140,30,106
	dc.l -28,59,242
	dc.l -18,46,100
	dc.l 91,-109,213
	dc.l -114,-52,60
	dc.l 104,-42,148
	dc.l -119,-16,76
	dc.l 14,-98,38
	dc.l -104,-112,24
	dc.l -50,88,29
	dc.l -97,50,110
	dc.l 31,-27,41



STARS2:
	dc.l 25,25,250 ; star1
	dc.l -30,-30,50 ; star2
	dc.l 30,-30,25 ; star3
	dc.l -30,60,150 ; star4
	dc.l -90,90,450 ; star4
	dc.l 120,120,450 ; star4
	dc.l -120,90,450 ; star4
ENDSTARS:

PLOTREFS:	
	dc.w $0,$28,$50,$78,$a0
	dc.w $c8,$f0,$118,$140
	dc.w $168,$190,$1b8,$1e0
	dc.w $208,$230,$258,$280
	dc.w $2a8,$2d0,$2f8,$320
	dc.w $348,$370,$398,$3c0
	dc.w $3e8,$410,$438,$460
	dc.w $488,$4b0,$4d8,$500
	dc.w $528,$550,$578,$5a0
	dc.w $5c8,$5f0,$618,$640
	dc.w $668,$690,$6b8,$6e0
	dc.w $708,$730,$758,$780
	dc.w $7a8,$7d0,$7f8,$820
	dc.w $848,$870,$898,$8c0
	dc.w $8e8,$910,$938,$960
	dc.w $988,$9b0,$9d8,$a00
	dc.w $a28,$a50,$a78,$aa0
	dc.w $ac8,$af0,$b18,$b40
	dc.w $b68,$b90,$bb8,$be0
	dc.w $c08,$c30,$c58,$c80
	dc.w $ca8,$cd0,$cf8,$d20
	dc.w $d48,$d70,$d98,$dc0
	dc.w $de8,$e10,$e38,$e60
	dc.w $e88,$eb0,$ed8,$f00
	dc.w $f28,$f50,$f78,$fa0
	dc.w $fc8,$ff0,$1018,$1040
	dc.w $1068,$1090,$10b8,$10e0
	dc.w $1108,$1130,$1158,$1180
	dc.w $11a8,$11d0,$11f8,$1220
	dc.w $1248,$1270,$1298,$12c0
	dc.w $12e8,$1310,$1338,$1360
	dc.w $1388,$13b0,$13d8,$1400
	dc.w $1428,$1450,$1478,$14a0
	dc.w $14c8,$14f0,$1518,$1540
	dc.w $1568,$1590,$15b8,$15e0
	dc.w $1608,$1630,$1658,$1680
	dc.w $16a8,$16d0,$16f8,$1720
	dc.w $1748,$1770,$1798,$17c0
	dc.w $17e8,$1810,$1838,$1860
	dc.w $1888,$18b0,$18d8,$1900
	dc.w $1928,$1950,$1978,$19a0
	dc.w $19c8,$19f0,$1a18,$1a40
	dc.w $1a68,$1a90,$1ab8,$1ae0
	dc.w $1b08,$1b30,$1b58,$1b80
	dc.w $1ba8,$1bd0,$1bf8,$1c20
	dc.w $1c48,$1c70,$1c98,$1cc0
	dc.w $1ce8,$1d10,$1d38,$1d60
	dc.w $1d88,$1db0,$1dd8,$1e00
	dc.w $1e28,$1e50,$1e78,$1ea0
	dc.w $1ec8,$1ef0,$1f18,$1f40
	dc.w $1f68,$1f90,$1fb8,$1fe0
	dc.w $2008,$2030,$2058,$2080
	dc.w $20a8,$20d0,$20f8,$2120
	dc.w $2148,$2170,$2198,$21c0
	dc.w $21e8,$2210,$2238,$2260
	dc.w $2288,$22b0,$22d8,$2300
	dc.w $2328,$2350,$2378,$23a0
	dc.w $23c8,$23f0,$2418,$2440
	dc.w $2468,$2490,$24b8,$24e0
	dc.w $2508,$2530,$2558,$2580
	dc.w $25a8,$25d0,$25f8,$2620
	dc.w $2648,$2670,$2698,$26c0
	dc.w $26e8,$2710,$2738,$2760
	dc.w $2788,$27b0,$27d8                             
	