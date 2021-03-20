

MATRIX_DEBUG=1;

; my own macro to load a immediate
REG_LOADI MACRO
	load #$\1\2\3\4,\5  ; 0 1 0 0
	ENDM

; add 3 rightmost signed 3 of a En register and store the result in the right word of d1
REG_ADD_LESS_SIG_3_WORDS MACRO
	vperm #$000000AB,e21,\1,d0 ; e21 zero register
	paddw \1,d0,d0
	move.l d0,d1
	swap d1
	add.w d0,d1
	ENDM

REG_ZERO MACRO
	load #0000000000000000,\1 ; zero register
	ENDM

    XDEF _ammxmatrixmul3X3
	XDEF _ammxmatrixmul3X3Trig
	XDEF _ammxmatrixmul1X3

par1:
    dc.l 0

_ammxmatrixmul1X3:
    move.l 4(sp),par1 ; argument save
	movem.l d0-d7/a0-a6,-(sp) ; stack save
    move.l par1,a1 ; argument address in a1 

    REG_ZERO e21 ; zero register

    ; this is the first matrix
	REG_LOADI 0000,001E,0000,0001,e1 ; X = 30, Y = 0, Z = 1  into e1
	REG_ZERO e2
	REG_ZERO e3

	; this is the second matrix into e4 e5 e6
	REG_LOADI 0000,0001,0000,0000,e4
	REG_LOADI 0000,0000,0001,0000,e5
	REG_LOADI 0000,00A0,0080,0001,e6

	IFD MATRIX_DEBUG
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

_ammxmatrixmul3X3:
    move.l 4(sp),par1 ; argument save
	movem.l d0-d7/a0-a6,-(sp) ; stack save
    move.l par1,a1 ; argument address in a1 

    move.w #0,d0; ANGLE
    load #0000000000000000,e21 ; zero register

    lea TRIG_TABLE,b1   ; Cos and SIN in b1 (precalculated * 256)
	LOAD (b1,D0.w*8),E10 ; Load precalculated sin/cos values to register E5

    ; this is the current transformation matrix from e1 to e3, initialize it with neutral values
    load #$0000000100000000,e1  ; 0 1 0 0
    load #$0000000000010000,e2  ; 0 0 1 0
    load #$0000000000000001,e3  ; 0 0 0 1

    ; rotation matrix
    vperm  #$FF0123FF,e10,e21,e4     ; first  row of the matrix  0 cos -sin 0
    vperm  #$FF4567FF,e10,e21,e5     ; second row of the matrix  0 sin  cos 0
    load   #$0000000000000001,E6     ; third  row of the matrix  0  0    0  1

	; end loading matrix

	IFD MATRIX_DEBUG

	; in debug mode i use some custom debug matrix
	load #$0000000100090008,e1  ; 0 1 0 0
    load #$0000000200030009,e2  ; 0 0 1 0
    load #$0000000500070001,e3  ; 0 0 0 1

	load #$0000000400020005,e4  ; 0 1 0 0
    load #$0000000500010006,e5  ; 0 0 1 0
    load #$0000000600090007,e6  ; 0 0 0 1

	; with the above number resulting matrix must be:
	; 97 83 115
	; 77 88  91
	; 61 26  74

	; hex values;
	; 61 53 73
	; 4d 58 5b
	; 3d 1a 4a

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
    move.l 4(sp),par1 ; argument save
	movem.l d0-d7/a0-a6,-(sp) ; stack save
    move.l par1,a1 ; argument address in a1 

    move.w #45,d0; ANGLE
    load #0000000000000000,e21 ; zero register

    lea TRIG_TABLE_128,b1   ; Cos and SIN in b1 (precalculated * 2^15)
	LOAD (b1,D0.w*8),E10 ; Load precalculated sin/cos values to register E10

    ; this is the current transformation matrix from e1 to e3, initialize it with neutral values
    REG_LOADI 0000,0001,0000,0000,e1
	REG_LOADI 0000,0000,0001,0000,e2
	REG_LOADI 0000,00A0,0080,0001,e3

	;REG_LOADI 0100,0100,0100,0100,e0
	;pmull e1,e0,e1
	;pmull e2,e0,e2
	;pmull e3,e0,e3

    ; rotation matrix
    vperm  #$FF0123FF,e10,e21,e4     ; first  row of the matrix  0 cos -sin 0
    vperm  #$FF4567FF,e10,e21,e5     ; second row of the matrix  0 sin  cos 0
	REG_LOADI 0000,0000,0000,4000,e6 ; NOTE, last word must be 1* table multiplier!!!!
	; end loading matrix

	

	IFD MATRIX_DEBUG

	

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



TRIG_TABLE: ; cos -sin sin cos multiplied by 256
	dc.w 256,0,0,256   ; 0 deg - True value: 0
	dc.w 255,-4,4,255   ; 1 deg - True value: 0.01745240643728351
	dc.w 255,-8,8,255   ; 2 deg - True value: 0.03489949670250097
	dc.w 255,-13,13,255   ; 3 deg - True value: 0.05233595624294383
	dc.w 255,-17,17,255   ; 4 deg - True value: 0.0697564737441253
	dc.w 255,-22,22,255   ; 5 deg - True value: 0.08715574274765817
	dc.w 254,-26,26,254   ; 6 deg - True value: 0.10452846326765346
	dc.w 254,-31,31,254   ; 7 deg - True value: 0.12186934340514748
	dc.w 253,-35,35,253   ; 8 deg - True value: 0.13917310096006544
	dc.w 252,-40,40,252   ; 9 deg - True value: 0.15643446504023087
	dc.w 252,-44,44,252   ; 10 deg - True value: 0.17364817766693033
	dc.w 251,-48,48,251   ; 11 deg - True value: 0.1908089953765448
	dc.w 250,-53,53,250   ; 12 deg - True value: 0.20791169081775931
	dc.w 249,-57,57,249   ; 13 deg - True value: 0.224951054343865
	dc.w 248,-61,61,248   ; 14 deg - True value: 0.24192189559966773
	dc.w 247,-66,66,247   ; 15 deg - True value: 0.25881904510252074
	dc.w 246,-70,70,246   ; 16 deg - True value: 0.27563735581699916
	dc.w 244,-74,74,244   ; 17 deg - True value: 0.29237170472273677
	dc.w 243,-79,79,243   ; 18 deg - True value: 0.3090169943749474
	dc.w 242,-83,83,242   ; 19 deg - True value: 0.32556815445715664
	dc.w 240,-87,87,240   ; 20 deg - True value: 0.3420201433256687
	dc.w 238,-91,91,238   ; 21 deg - True value: 0.35836794954530027
	dc.w 237,-95,95,237   ; 22 deg - True value: 0.374606593415912
	dc.w 235,-100,100,235   ; 23 deg - True value: 0.3907311284892737
	dc.w 233,-104,104,233   ; 24 deg - True value: 0.40673664307580015
	dc.w 232,-108,108,232   ; 25 deg - True value: 0.42261826174069944
	dc.w 230,-112,112,230   ; 26 deg - True value: 0.4383711467890774
	dc.w 228,-116,116,228   ; 27 deg - True value: 0.45399049973954675
	dc.w 226,-120,120,226   ; 28 deg - True value: 0.4694715627858908
	dc.w 223,-124,124,223   ; 29 deg - True value: 0.48480962024633706
	dc.w 221,-127,127,221   ; 30 deg - True value: 0.49999999999999994
	dc.w 219,-131,131,219   ; 31 deg - True value: 0.5150380749100542
	dc.w 217,-135,135,217   ; 32 deg - True value: 0.5299192642332049
	dc.w 214,-139,139,214   ; 33 deg - True value: 0.5446390350150271
	dc.w 212,-143,143,212   ; 34 deg - True value: 0.5591929034707469
	dc.w 209,-146,146,209   ; 35 deg - True value: 0.573576436351046
	dc.w 207,-150,150,207   ; 36 deg - True value: 0.5877852522924731
	dc.w 204,-154,154,204   ; 37 deg - True value: 0.6018150231520483
	dc.w 201,-157,157,201   ; 38 deg - True value: 0.6156614753256582
	dc.w 198,-161,161,198   ; 39 deg - True value: 0.6293203910498374
	dc.w 196,-164,164,196   ; 40 deg - True value: 0.6427876096865393
	dc.w 193,-167,167,193   ; 41 deg - True value: 0.6560590289905072
	dc.w 190,-171,171,190   ; 42 deg - True value: 0.6691306063588582
	dc.w 187,-174,174,187   ; 43 deg - True value: 0.6819983600624985
	dc.w 184,-177,177,184   ; 44 deg - True value: 0.6946583704589973
	dc.w 181,-181,181,181   ; 45 deg - True value: 0.7071067811865475
	dc.w 177,-184,184,177   ; 46 deg - True value: 0.7193398003386511
	dc.w 174,-187,187,174   ; 47 deg - True value: 0.7313537016191705
	dc.w 171,-190,190,171   ; 48 deg - True value: 0.7431448254773942
	dc.w 167,-193,193,167   ; 49 deg - True value: 0.754709580222772
	dc.w 164,-196,196,164   ; 50 deg - True value: 0.766044443118978
	dc.w 161,-198,198,161   ; 51 deg - True value: 0.7771459614569708
	dc.w 157,-201,201,157   ; 52 deg - True value: 0.788010753606722
	dc.w 154,-204,204,154   ; 53 deg - True value: 0.7986355100472928
	dc.w 150,-207,207,150   ; 54 deg - True value: 0.8090169943749475
	dc.w 146,-209,209,146   ; 55 deg - True value: 0.8191520442889918
	dc.w 143,-212,212,143   ; 56 deg - True value: 0.8290375725550417
	dc.w 139,-214,214,139   ; 57 deg - True value: 0.8386705679454239
	dc.w 135,-217,217,135   ; 58 deg - True value: 0.8480480961564261
	dc.w 131,-219,219,131   ; 59 deg - True value: 0.8571673007021122
	dc.w 128,-221,221,128   ; 60 deg - True value: 0.8660254037844386
	dc.w 124,-223,223,124   ; 61 deg - True value: 0.8746197071393957
	dc.w 120,-226,226,120   ; 62 deg - True value: 0.8829475928589269
	dc.w 116,-228,228,116   ; 63 deg - True value: 0.8910065241883678
	dc.w 112,-230,230,112   ; 64 deg - True value: 0.898794046299167
	dc.w 108,-232,232,108   ; 65 deg - True value: 0.9063077870366499
	dc.w 104,-233,233,104   ; 66 deg - True value: 0.9135454576426009
	dc.w 100,-235,235,100   ; 67 deg - True value: 0.9205048534524403
	dc.w 95,-237,237,95   ; 68 deg - True value: 0.9271838545667874
	dc.w 91,-238,238,91   ; 69 deg - True value: 0.9335804264972017
	dc.w 87,-240,240,87   ; 70 deg - True value: 0.9396926207859083
	dc.w 83,-242,242,83   ; 71 deg - True value: 0.9455185755993167
	dc.w 79,-243,243,79   ; 72 deg - True value: 0.9510565162951535
	dc.w 74,-244,244,74   ; 73 deg - True value: 0.9563047559630354
	dc.w 70,-246,246,70   ; 74 deg - True value: 0.9612616959383189
	dc.w 66,-247,247,66   ; 75 deg - True value: 0.9659258262890683
	dc.w 61,-248,248,61   ; 76 deg - True value: 0.9702957262759965
	dc.w 57,-249,249,57   ; 77 deg - True value: 0.9743700647852352
	dc.w 53,-250,250,53   ; 78 deg - True value: 0.9781476007338056
	dc.w 48,-251,251,48   ; 79 deg - True value: 0.981627183447664
	dc.w 44,-252,252,44   ; 80 deg - True value: 0.984807753012208
	dc.w 40,-252,252,40   ; 81 deg - True value: 0.9876883405951378
	dc.w 35,-253,253,35   ; 82 deg - True value: 0.9902680687415703
	dc.w 31,-254,254,31   ; 83 deg - True value: 0.992546151641322
	dc.w 26,-254,254,26   ; 84 deg - True value: 0.9945218953682733
	dc.w 22,-255,255,22   ; 85 deg - True value: 0.9961946980917455
	dc.w 17,-255,255,17   ; 86 deg - True value: 0.9975640502598242
	dc.w 13,-255,255,13   ; 87 deg - True value: 0.9986295347545738
	dc.w 8,-255,255,8   ; 88 deg - True value: 0.9993908270190958
	dc.w 4,-255,255,4   ; 89 deg - True value: 0.9998476951563913
	dc.w 1,-256,256,1   ; 90 deg - True value: 1
	dc.w -4,-255,255,-4   ; 91 deg - True value: 0.9998476951563913
	dc.w -8,-255,255,-8   ; 92 deg - True value: 0.9993908270190958
	dc.w -13,-255,255,-13   ; 93 deg - True value: 0.9986295347545738
	dc.w -17,-255,255,-17   ; 94 deg - True value: 0.9975640502598242
	dc.w -22,-255,255,-22   ; 95 deg - True value: 0.9961946980917455
	dc.w -26,-254,254,-26   ; 96 deg - True value: 0.9945218953682734
	dc.w -31,-254,254,-31   ; 97 deg - True value: 0.9925461516413221
	dc.w -35,-253,253,-35   ; 98 deg - True value: 0.9902680687415704
	dc.w -40,-252,252,-40   ; 99 deg - True value: 0.9876883405951377
	dc.w -44,-252,252,-44   ; 100 deg - True value: 0.984807753012208
	dc.w -48,-251,251,-48   ; 101 deg - True value: 0.981627183447664
	dc.w -53,-250,250,-53   ; 102 deg - True value: 0.9781476007338057
	dc.w -57,-249,249,-57   ; 103 deg - True value: 0.9743700647852352
	dc.w -61,-248,248,-61   ; 104 deg - True value: 0.9702957262759965
	dc.w -66,-247,247,-66   ; 105 deg - True value: 0.9659258262890683
	dc.w -70,-246,246,-70   ; 106 deg - True value: 0.9612616959383189
	dc.w -74,-244,244,-74   ; 107 deg - True value: 0.9563047559630355
	dc.w -79,-243,243,-79   ; 108 deg - True value: 0.9510565162951536
	dc.w -83,-242,242,-83   ; 109 deg - True value: 0.9455185755993168
	dc.w -87,-240,240,-87   ; 110 deg - True value: 0.9396926207859084
	dc.w -91,-238,238,-91   ; 111 deg - True value: 0.9335804264972017
	dc.w -95,-237,237,-95   ; 112 deg - True value: 0.9271838545667874
	dc.w -100,-235,235,-100   ; 113 deg - True value: 0.9205048534524404
	dc.w -104,-233,233,-104   ; 114 deg - True value: 0.913545457642601
	dc.w -108,-232,232,-108   ; 115 deg - True value: 0.90630778703665
	dc.w -112,-230,230,-112   ; 116 deg - True value: 0.8987940462991669
	dc.w -116,-228,228,-116   ; 117 deg - True value: 0.8910065241883679
	dc.w -120,-226,226,-120   ; 118 deg - True value: 0.8829475928589271
	dc.w -124,-223,223,-124   ; 119 deg - True value: 0.8746197071393959
	dc.w -127,-221,221,-127   ; 120 deg - True value: 0.8660254037844387
	dc.w -131,-219,219,-131   ; 121 deg - True value: 0.8571673007021123
	dc.w -135,-217,217,-135   ; 122 deg - True value: 0.8480480961564261
	dc.w -139,-214,214,-139   ; 123 deg - True value: 0.838670567945424
	dc.w -143,-212,212,-143   ; 124 deg - True value: 0.8290375725550417
	dc.w -146,-209,209,-146   ; 125 deg - True value: 0.819152044288992
	dc.w -150,-207,207,-150   ; 126 deg - True value: 0.8090169943749475
	dc.w -154,-204,204,-154   ; 127 deg - True value: 0.7986355100472927
	dc.w -157,-201,201,-157   ; 128 deg - True value: 0.788010753606722
	dc.w -161,-198,198,-161   ; 129 deg - True value: 0.777145961456971
	dc.w -164,-196,196,-164   ; 130 deg - True value: 0.766044443118978
	dc.w -167,-193,193,-167   ; 131 deg - True value: 0.7547095802227718
	dc.w -171,-190,190,-171   ; 132 deg - True value: 0.7431448254773942
	dc.w -174,-187,187,-174   ; 133 deg - True value: 0.7313537016191706
	dc.w -177,-184,184,-177   ; 134 deg - True value: 0.7193398003386514
	dc.w -181,-181,181,-181   ; 135 deg - True value: 0.7071067811865476
	dc.w -184,-177,177,-184   ; 136 deg - True value: 0.6946583704589971
	dc.w -187,-174,174,-187   ; 137 deg - True value: 0.6819983600624986
	dc.w -190,-171,171,-190   ; 138 deg - True value: 0.6691306063588583
	dc.w -193,-167,167,-193   ; 139 deg - True value: 0.6560590289905073
	dc.w -196,-164,164,-196   ; 140 deg - True value: 0.6427876096865395
	dc.w -198,-161,161,-198   ; 141 deg - True value: 0.6293203910498377
	dc.w -201,-157,157,-201   ; 142 deg - True value: 0.6156614753256584
	dc.w -204,-154,154,-204   ; 143 deg - True value: 0.6018150231520482
	dc.w -207,-150,150,-207   ; 144 deg - True value: 0.5877852522924732
	dc.w -209,-146,146,-209   ; 145 deg - True value: 0.5735764363510464
	dc.w -212,-143,143,-212   ; 146 deg - True value: 0.5591929034707469
	dc.w -214,-139,139,-214   ; 147 deg - True value: 0.5446390350150269
	dc.w -217,-135,135,-217   ; 148 deg - True value: 0.5299192642332049
	dc.w -219,-131,131,-219   ; 149 deg - True value: 0.5150380749100544
	dc.w -221,-127,127,-221   ; 150 deg - True value: 0.49999999999999994
	dc.w -223,-124,124,-223   ; 151 deg - True value: 0.48480962024633717
	dc.w -226,-120,120,-226   ; 152 deg - True value: 0.4694715627858911
	dc.w -228,-116,116,-228   ; 153 deg - True value: 0.45399049973954686
	dc.w -230,-112,112,-230   ; 154 deg - True value: 0.4383711467890773
	dc.w -232,-108,108,-232   ; 155 deg - True value: 0.4226182617406995
	dc.w -233,-104,104,-233   ; 156 deg - True value: 0.40673664307580043
	dc.w -235,-100,100,-235   ; 157 deg - True value: 0.39073112848927416
	dc.w -237,-95,95,-237   ; 158 deg - True value: 0.37460659341591224
	dc.w -238,-91,91,-238   ; 159 deg - True value: 0.3583679495453002
	dc.w -240,-87,87,-240   ; 160 deg - True value: 0.3420201433256689
	dc.w -242,-83,83,-242   ; 161 deg - True value: 0.325568154457157
	dc.w -243,-79,79,-243   ; 162 deg - True value: 0.3090169943749475
	dc.w -244,-74,74,-244   ; 163 deg - True value: 0.29237170472273705
	dc.w -246,-70,70,-246   ; 164 deg - True value: 0.27563735581699966
	dc.w -247,-66,66,-247   ; 165 deg - True value: 0.258819045102521
	dc.w -248,-61,61,-248   ; 166 deg - True value: 0.24192189559966773
	dc.w -249,-57,57,-249   ; 167 deg - True value: 0.22495105434386478
	dc.w -250,-53,53,-250   ; 168 deg - True value: 0.20791169081775931
	dc.w -251,-48,48,-251   ; 169 deg - True value: 0.19080899537654497
	dc.w -252,-44,44,-252   ; 170 deg - True value: 0.17364817766693028
	dc.w -252,-40,40,-252   ; 171 deg - True value: 0.15643446504023098
	dc.w -253,-35,35,-253   ; 172 deg - True value: 0.13917310096006574
	dc.w -254,-31,31,-254   ; 173 deg - True value: 0.12186934340514755
	dc.w -254,-26,26,-254   ; 174 deg - True value: 0.10452846326765373
	dc.w -255,-22,22,-255   ; 175 deg - True value: 0.08715574274765864
	dc.w -255,-17,17,-255   ; 176 deg - True value: 0.06975647374412552
	dc.w -255,-13,13,-255   ; 177 deg - True value: 0.05233595624294381
	dc.w -255,-8,8,-255   ; 178 deg - True value: 0.0348994967025007
	dc.w -255,-4,4,-255   ; 179 deg - True value: 0.01745240643728344
	dc.w -256,-3,3,-256   ; 180 deg - True value: 1.2246467991473532e-16
	dc.w -255,4,-4,-255   ; 181 deg - True value: -0.017452406437283192
	dc.w -255,8,-8,-255   ; 182 deg - True value: -0.0348994967025009
	dc.w -255,13,-13,-255   ; 183 deg - True value: -0.052335956242943564
	dc.w -255,17,-17,-255   ; 184 deg - True value: -0.06975647374412483
	dc.w -255,22,-22,-255   ; 185 deg - True value: -0.08715574274765794
	dc.w -254,26,-26,-254   ; 186 deg - True value: -0.10452846326765305
	dc.w -254,31,-31,-254   ; 187 deg - True value: -0.12186934340514775
	dc.w -253,35,-35,-253   ; 188 deg - True value: -0.13917310096006552
	dc.w -252,40,-40,-252   ; 189 deg - True value: -0.15643446504023073
	dc.w -252,44,-44,-252   ; 190 deg - True value: -0.17364817766693047
	dc.w -251,48,-48,-251   ; 191 deg - True value: -0.19080899537654472
	dc.w -250,53,-53,-250   ; 192 deg - True value: -0.20791169081775907
	dc.w -249,57,-57,-249   ; 193 deg - True value: -0.22495105434386498
	dc.w -248,61,-61,-248   ; 194 deg - True value: -0.2419218955996675
	dc.w -247,66,-66,-247   ; 195 deg - True value: -0.25881904510252035
	dc.w -246,70,-70,-246   ; 196 deg - True value: -0.275637355816999
	dc.w -244,74,-74,-244   ; 197 deg - True value: -0.2923717047227364
	dc.w -243,79,-79,-243   ; 198 deg - True value: -0.30901699437494773
	dc.w -242,83,-83,-242   ; 199 deg - True value: -0.32556815445715676
	dc.w -240,87,-87,-240   ; 200 deg - True value: -0.34202014332566866
	dc.w -238,91,-91,-238   ; 201 deg - True value: -0.35836794954530043
	dc.w -237,95,-95,-237   ; 202 deg - True value: -0.374606593415912
	dc.w -235,100,-100,-235   ; 203 deg - True value: -0.39073112848927355
	dc.w -233,104,-104,-233   ; 204 deg - True value: -0.4067366430757998
	dc.w -232,108,-108,-232   ; 205 deg - True value: -0.4226182617406993
	dc.w -230,112,-112,-230   ; 206 deg - True value: -0.43837114678907707
	dc.w -228,116,-116,-228   ; 207 deg - True value: -0.45399049973954625
	dc.w -226,120,-120,-226   ; 208 deg - True value: -0.46947156278589086
	dc.w -223,124,-124,-223   ; 209 deg - True value: -0.48480962024633695
	dc.w -221,128,-128,-221   ; 210 deg - True value: -0.5000000000000001
	dc.w -219,131,-131,-219   ; 211 deg - True value: -0.5150380749100542
	dc.w -217,135,-135,-217   ; 212 deg - True value: -0.5299192642332048
	dc.w -214,139,-139,-214   ; 213 deg - True value: -0.5446390350150271
	dc.w -212,143,-143,-212   ; 214 deg - True value: -0.5591929034707467
	dc.w -209,146,-146,-209   ; 215 deg - True value: -0.5735764363510458
	dc.w -207,150,-150,-207   ; 216 deg - True value: -0.587785252292473
	dc.w -204,154,-154,-204   ; 217 deg - True value: -0.601815023152048
	dc.w -201,157,-157,-201   ; 218 deg - True value: -0.6156614753256578
	dc.w -198,161,-161,-198   ; 219 deg - True value: -0.6293203910498376
	dc.w -196,164,-164,-196   ; 220 deg - True value: -0.6427876096865393
	dc.w -193,167,-167,-193   ; 221 deg - True value: -0.6560590289905074
	dc.w -190,171,-171,-190   ; 222 deg - True value: -0.6691306063588582
	dc.w -187,174,-174,-187   ; 223 deg - True value: -0.6819983600624984
	dc.w -184,177,-177,-184   ; 224 deg - True value: -0.6946583704589974
	dc.w -181,181,-181,-181   ; 225 deg - True value: -0.7071067811865475
	dc.w -177,184,-184,-177   ; 226 deg - True value: -0.7193398003386509
	dc.w -174,187,-187,-174   ; 227 deg - True value: -0.7313537016191701
	dc.w -171,190,-190,-171   ; 228 deg - True value: -0.743144825477394
	dc.w -167,193,-193,-167   ; 229 deg - True value: -0.7547095802227717
	dc.w -164,196,-196,-164   ; 230 deg - True value: -0.7660444431189779
	dc.w -161,198,-198,-161   ; 231 deg - True value: -0.7771459614569711
	dc.w -157,201,-201,-157   ; 232 deg - True value: -0.7880107536067221
	dc.w -154,204,-204,-154   ; 233 deg - True value: -0.7986355100472928
	dc.w -150,207,-207,-150   ; 234 deg - True value: -0.8090169943749473
	dc.w -146,209,-209,-146   ; 235 deg - True value: -0.8191520442889916
	dc.w -143,212,-212,-143   ; 236 deg - True value: -0.8290375725550414
	dc.w -139,214,-214,-139   ; 237 deg - True value: -0.838670567945424
	dc.w -135,217,-217,-135   ; 238 deg - True value: -0.848048096156426
	dc.w -131,219,-219,-131   ; 239 deg - True value: -0.8571673007021121
	dc.w -128,221,-221,-128   ; 240 deg - True value: -0.8660254037844385
	dc.w -124,223,-223,-124   ; 241 deg - True value: -0.8746197071393959
	dc.w -120,226,-226,-120   ; 242 deg - True value: -0.882947592858927
	dc.w -116,228,-228,-116   ; 243 deg - True value: -0.8910065241883678
	dc.w -112,230,-230,-112   ; 244 deg - True value: -0.8987940462991668
	dc.w -108,232,-232,-108   ; 245 deg - True value: -0.9063077870366497
	dc.w -104,233,-233,-104   ; 246 deg - True value: -0.913545457642601
	dc.w -100,235,-235,-100   ; 247 deg - True value: -0.9205048534524403
	dc.w -95,237,-237,-95   ; 248 deg - True value: -0.9271838545667873
	dc.w -91,238,-238,-91   ; 249 deg - True value: -0.9335804264972016
	dc.w -87,240,-240,-87   ; 250 deg - True value: -0.9396926207859082
	dc.w -83,242,-242,-83   ; 251 deg - True value: -0.9455185755993168
	dc.w -79,243,-243,-79   ; 252 deg - True value: -0.9510565162951535
	dc.w -74,244,-244,-74   ; 253 deg - True value: -0.9563047559630353
	dc.w -70,246,-246,-70   ; 254 deg - True value: -0.9612616959383189
	dc.w -66,247,-247,-66   ; 255 deg - True value: -0.9659258262890683
	dc.w -61,248,-248,-61   ; 256 deg - True value: -0.9702957262759965
	dc.w -57,249,-249,-57   ; 257 deg - True value: -0.9743700647852351
	dc.w -53,250,-250,-53   ; 258 deg - True value: -0.9781476007338056
	dc.w -48,251,-251,-48   ; 259 deg - True value: -0.9816271834476639
	dc.w -44,252,-252,-44   ; 260 deg - True value: -0.984807753012208
	dc.w -40,252,-252,-40   ; 261 deg - True value: -0.9876883405951377
	dc.w -35,253,-253,-35   ; 262 deg - True value: -0.9902680687415704
	dc.w -31,254,-254,-31   ; 263 deg - True value: -0.9925461516413221
	dc.w -26,254,-254,-26   ; 264 deg - True value: -0.9945218953682734
	dc.w -22,255,-255,-22   ; 265 deg - True value: -0.9961946980917455
	dc.w -17,255,-255,-17   ; 266 deg - True value: -0.9975640502598242
	dc.w -13,255,-255,-13   ; 267 deg - True value: -0.9986295347545738
	dc.w -8,255,-255,-8   ; 268 deg - True value: -0.9993908270190957
	dc.w -4,255,-255,-4   ; 269 deg - True value: -0.9998476951563913
	dc.w -4,256,-256,-4   ; 270 deg - True value: -1
	dc.w 4,255,-255,4   ; 271 deg - True value: -0.9998476951563913
	dc.w 8,255,-255,8   ; 272 deg - True value: -0.9993908270190958
	dc.w 13,255,-255,13   ; 273 deg - True value: -0.9986295347545738
	dc.w 17,255,-255,17   ; 274 deg - True value: -0.9975640502598243
	dc.w 22,255,-255,22   ; 275 deg - True value: -0.9961946980917455
	dc.w 26,254,-254,26   ; 276 deg - True value: -0.9945218953682734
	dc.w 31,254,-254,31   ; 277 deg - True value: -0.992546151641322
	dc.w 35,253,-253,35   ; 278 deg - True value: -0.9902680687415704
	dc.w 40,252,-252,40   ; 279 deg - True value: -0.9876883405951378
	dc.w 44,252,-252,44   ; 280 deg - True value: -0.9848077530122081
	dc.w 48,251,-251,48   ; 281 deg - True value: -0.9816271834476641
	dc.w 53,250,-250,53   ; 282 deg - True value: -0.9781476007338058
	dc.w 57,249,-249,57   ; 283 deg - True value: -0.9743700647852352
	dc.w 61,248,-248,61   ; 284 deg - True value: -0.9702957262759966
	dc.w 66,247,-247,66   ; 285 deg - True value: -0.9659258262890682
	dc.w 70,246,-246,70   ; 286 deg - True value: -0.9612616959383188
	dc.w 74,244,-244,74   ; 287 deg - True value: -0.9563047559630354
	dc.w 79,243,-243,79   ; 288 deg - True value: -0.9510565162951536
	dc.w 83,242,-242,83   ; 289 deg - True value: -0.945518575599317
	dc.w 87,240,-240,87   ; 290 deg - True value: -0.9396926207859085
	dc.w 91,238,-238,91   ; 291 deg - True value: -0.9335804264972021
	dc.w 95,237,-237,95   ; 292 deg - True value: -0.9271838545667874
	dc.w 100,235,-235,100   ; 293 deg - True value: -0.9205048534524405
	dc.w 104,233,-233,104   ; 294 deg - True value: -0.9135454576426008
	dc.w 108,232,-232,108   ; 295 deg - True value: -0.9063077870366498
	dc.w 112,230,-230,112   ; 296 deg - True value: -0.898794046299167
	dc.w 116,228,-228,116   ; 297 deg - True value: -0.891006524188368
	dc.w 120,226,-226,120   ; 298 deg - True value: -0.8829475928589271
	dc.w 124,223,-223,124   ; 299 deg - True value: -0.8746197071393961
	dc.w 128,221,-221,128   ; 300 deg - True value: -0.8660254037844386
	dc.w 131,219,-219,131   ; 301 deg - True value: -0.8571673007021123
	dc.w 135,217,-217,135   ; 302 deg - True value: -0.8480480961564261
	dc.w 139,214,-214,139   ; 303 deg - True value: -0.8386705679454243
	dc.w 143,212,-212,143   ; 304 deg - True value: -0.8290375725550421
	dc.w 146,209,-209,146   ; 305 deg - True value: -0.8191520442889918
	dc.w 150,207,-207,150   ; 306 deg - True value: -0.8090169943749476
	dc.w 154,204,-204,154   ; 307 deg - True value: -0.798635510047293
	dc.w 157,201,-201,157   ; 308 deg - True value: -0.7880107536067218
	dc.w 161,198,-198,161   ; 309 deg - True value: -0.7771459614569708
	dc.w 164,196,-196,164   ; 310 deg - True value: -0.7660444431189781
	dc.w 167,193,-193,167   ; 311 deg - True value: -0.7547095802227721
	dc.w 171,190,-190,171   ; 312 deg - True value: -0.7431448254773946
	dc.w 174,187,-187,174   ; 313 deg - True value: -0.731353701619171
	dc.w 177,184,-184,177   ; 314 deg - True value: -0.7193398003386517
	dc.w 181,181,-181,181   ; 315 deg - True value: -0.7071067811865477
	dc.w 184,177,-177,184   ; 316 deg - True value: -0.6946583704589976
	dc.w 187,174,-174,187   ; 317 deg - True value: -0.6819983600624983
	dc.w 190,171,-171,190   ; 318 deg - True value: -0.6691306063588581
	dc.w 193,167,-167,193   ; 319 deg - True value: -0.6560590289905074
	dc.w 196,164,-164,196   ; 320 deg - True value: -0.6427876096865396
	dc.w 198,161,-161,198   ; 321 deg - True value: -0.6293203910498378
	dc.w 201,157,-157,201   ; 322 deg - True value: -0.6156614753256588
	dc.w 204,154,-154,204   ; 323 deg - True value: -0.6018150231520483
	dc.w 207,150,-150,207   ; 324 deg - True value: -0.5877852522924734
	dc.w 209,146,-146,209   ; 325 deg - True value: -0.5735764363510465
	dc.w 212,143,-143,212   ; 326 deg - True value: -0.5591929034707473
	dc.w 214,139,-139,214   ; 327 deg - True value: -0.544639035015027
	dc.w 217,135,-135,217   ; 328 deg - True value: -0.5299192642332058
	dc.w 219,131,-131,219   ; 329 deg - True value: -0.5150380749100545
	dc.w 221,128,-128,221   ; 330 deg - True value: -0.5000000000000004
	dc.w 223,124,-124,223   ; 331 deg - True value: -0.4848096202463369
	dc.w 226,120,-120,226   ; 332 deg - True value: -0.4694715627858908
	dc.w 228,116,-116,228   ; 333 deg - True value: -0.45399049973954697
	dc.w 230,112,-112,230   ; 334 deg - True value: -0.438371146789077
	dc.w 232,108,-108,232   ; 335 deg - True value: -0.4226182617407
	dc.w 233,104,-104,233   ; 336 deg - True value: -0.40673664307580015
	dc.w 235,100,-100,235   ; 337 deg - True value: -0.3907311284892747
	dc.w 237,95,-95,237   ; 338 deg - True value: -0.37460659341591235
	dc.w 238,91,-91,238   ; 339 deg - True value: -0.35836794954530077
	dc.w 240,87,-87,240   ; 340 deg - True value: -0.3420201433256686
	dc.w 242,83,-83,242   ; 341 deg - True value: -0.32556815445715753
	dc.w 243,79,-79,243   ; 342 deg - True value: -0.3090169943749476
	dc.w 244,74,-74,244   ; 343 deg - True value: -0.29237170472273627
	dc.w 246,70,-70,246   ; 344 deg - True value: -0.2756373558169998
	dc.w 247,66,-66,247   ; 345 deg - True value: -0.2588190451025207
	dc.w 248,61,-61,248   ; 346 deg - True value: -0.24192189559966787
	dc.w 249,57,-57,249   ; 347 deg - True value: -0.22495105434386534
	dc.w 250,53,-53,250   ; 348 deg - True value: -0.20791169081775987
	dc.w 251,48,-48,251   ; 349 deg - True value: -0.19080899537654467
	dc.w 252,44,-44,252   ; 350 deg - True value: -0.17364817766693127
	dc.w 252,40,-40,252   ; 351 deg - True value: -0.15643446504023112
	dc.w 253,35,-35,253   ; 352 deg - True value: -0.13917310096006588
	dc.w 254,31,-31,254   ; 353 deg - True value: -0.12186934340514811
	dc.w 254,26,-26,254   ; 354 deg - True value: -0.10452846326765342
	dc.w 255,22,-22,255   ; 355 deg - True value: -0.08715574274765832
	dc.w 255,17,-17,255   ; 356 deg - True value: -0.06975647374412476
	dc.w 255,13,-13,255   ; 357 deg - True value: -0.05233595624294437
	dc.w 255,8,-8,255   ; 358 deg - True value: -0.034899496702500823
	dc.w 255,4,-4,255   ; 359 deg - True value: -0.01745240643728445


SIN_TABLE_2:
	dc.w 32768,0,0,32768   ; 0 deg - True value: 0
	dc.w 32763,-571,571,32763   ; 1 deg - True value: 0.01745240643728351
	dc.w 32748,-1143,1143,32748   ; 2 deg - True value: 0.03489949670250097
	dc.w 32723,-1714,1714,32723   ; 3 deg - True value: 0.05233595624294383
	dc.w 32688,-2285,2285,32688   ; 4 deg - True value: 0.0697564737441253
	dc.w 32643,-2855,2855,32643   ; 5 deg - True value: 0.08715574274765817
	dc.w 32588,-3425,3425,32588   ; 6 deg - True value: 0.10452846326765346
	dc.w 32523,-3993,3993,32523   ; 7 deg - True value: 0.12186934340514748
	dc.w 32449,-4560,4560,32449   ; 8 deg - True value: 0.13917310096006544
	dc.w 32364,-5126,5126,32364   ; 9 deg - True value: 0.15643446504023087
	dc.w 32270,-5690,5690,32270   ; 10 deg - True value: 0.17364817766693033
	dc.w 32165,-6252,6252,32165   ; 11 deg - True value: 0.1908089953765448
	dc.w 32051,-6812,6812,32051   ; 12 deg - True value: 0.20791169081775931
	dc.w 31928,-7371,7371,31928   ; 13 deg - True value: 0.224951054343865
	dc.w 31794,-7927,7927,31794   ; 14 deg - True value: 0.24192189559966773
	dc.w 31651,-8480,8480,31651   ; 15 deg - True value: 0.25881904510252074
	dc.w 31498,-9032,9032,31498   ; 16 deg - True value: 0.27563735581699916
	dc.w 31336,-9580,9580,31336   ; 17 deg - True value: 0.29237170472273677
	dc.w 31164,-10125,10125,31164   ; 18 deg - True value: 0.3090169943749474
	dc.w 30982,-10668,10668,30982   ; 19 deg - True value: 0.32556815445715664
	dc.w 30791,-11207,11207,30791   ; 20 deg - True value: 0.3420201433256687
	dc.w 30591,-11743,11743,30591   ; 21 deg - True value: 0.35836794954530027
	dc.w 30381,-12275,12275,30381   ; 22 deg - True value: 0.374606593415912
	dc.w 30163,-12803,12803,30163   ; 23 deg - True value: 0.3907311284892737
	dc.w 29935,-13327,13327,29935   ; 24 deg - True value: 0.40673664307580015
	dc.w 29697,-13848,13848,29697   ; 25 deg - True value: 0.42261826174069944
	dc.w 29451,-14364,14364,29451   ; 26 deg - True value: 0.4383711467890774
	dc.w 29196,-14876,14876,29196   ; 27 deg - True value: 0.45399049973954675
	dc.w 28932,-15383,15383,28932   ; 28 deg - True value: 0.4694715627858908
	dc.w 28659,-15886,15886,28659   ; 29 deg - True value: 0.48480962024633706
	dc.w 28377,-16383,16383,28377   ; 30 deg - True value: 0.49999999999999994
	dc.w 28087,-16876,16876,28087   ; 31 deg - True value: 0.5150380749100542
	dc.w 27788,-17364,17364,27788   ; 32 deg - True value: 0.5299192642332049
	dc.w 27481,-17846,17846,27481   ; 33 deg - True value: 0.5446390350150271
	dc.w 27165,-18323,18323,27165   ; 34 deg - True value: 0.5591929034707469
	dc.w 26841,-18794,18794,26841   ; 35 deg - True value: 0.573576436351046
	dc.w 26509,-19260,19260,26509   ; 36 deg - True value: 0.5877852522924731
	dc.w 26169,-19720,19720,26169   ; 37 deg - True value: 0.6018150231520483
	dc.w 25821,-20173,20173,25821   ; 38 deg - True value: 0.6156614753256582
	dc.w 25465,-20621,20621,25465   ; 39 deg - True value: 0.6293203910498374
	dc.w 25101,-21062,21062,25101   ; 40 deg - True value: 0.6427876096865393
	dc.w 24730,-21497,21497,24730   ; 41 deg - True value: 0.6560590289905072
	dc.w 24351,-21926,21926,24351   ; 42 deg - True value: 0.6691306063588582
	dc.w 23964,-22347,22347,23964   ; 43 deg - True value: 0.6819983600624985
	dc.w 23571,-22762,22762,23571   ; 44 deg - True value: 0.6946583704589973
	dc.w 23170,-23170,23170,23170   ; 45 deg - True value: 0.7071067811865475
	dc.w 22762,-23571,23571,22762   ; 46 deg - True value: 0.7193398003386511
	dc.w 22347,-23964,23964,22347   ; 47 deg - True value: 0.7313537016191705
	dc.w 21926,-24351,24351,21926   ; 48 deg - True value: 0.7431448254773942
	dc.w 21497,-24730,24730,21497   ; 49 deg - True value: 0.754709580222772
	dc.w 21062,-25101,25101,21062   ; 50 deg - True value: 0.766044443118978
	dc.w 20621,-25465,25465,20621   ; 51 deg - True value: 0.7771459614569708
	dc.w 20173,-25821,25821,20173   ; 52 deg - True value: 0.788010753606722
	dc.w 19720,-26169,26169,19720   ; 53 deg - True value: 0.7986355100472928
	dc.w 19260,-26509,26509,19260   ; 54 deg - True value: 0.8090169943749475
	dc.w 18794,-26841,26841,18794   ; 55 deg - True value: 0.8191520442889918
	dc.w 18323,-27165,27165,18323   ; 56 deg - True value: 0.8290375725550417
	dc.w 17846,-27481,27481,17846   ; 57 deg - True value: 0.8386705679454239
	dc.w 17364,-27788,27788,17364   ; 58 deg - True value: 0.8480480961564261
	dc.w 16876,-28087,28087,16876   ; 59 deg - True value: 0.8571673007021122
	dc.w 16384,-28377,28377,16384   ; 60 deg - True value: 0.8660254037844386
	dc.w 15886,-28659,28659,15886   ; 61 deg - True value: 0.8746197071393957
	dc.w 15383,-28932,28932,15383   ; 62 deg - True value: 0.8829475928589269
	dc.w 14876,-29196,29196,14876   ; 63 deg - True value: 0.8910065241883678
	dc.w 14364,-29451,29451,14364   ; 64 deg - True value: 0.898794046299167
	dc.w 13848,-29697,29697,13848   ; 65 deg - True value: 0.9063077870366499
	dc.w 13327,-29935,29935,13327   ; 66 deg - True value: 0.9135454576426009
	dc.w 12803,-30163,30163,12803   ; 67 deg - True value: 0.9205048534524403
	dc.w 12275,-30381,30381,12275   ; 68 deg - True value: 0.9271838545667874
	dc.w 11743,-30591,30591,11743   ; 69 deg - True value: 0.9335804264972017
	dc.w 11207,-30791,30791,11207   ; 70 deg - True value: 0.9396926207859083
	dc.w 10668,-30982,30982,10668   ; 71 deg - True value: 0.9455185755993167
	dc.w 10125,-31164,31164,10125   ; 72 deg - True value: 0.9510565162951535
	dc.w 9580,-31336,31336,9580   ; 73 deg - True value: 0.9563047559630354
	dc.w 9032,-31498,31498,9032   ; 74 deg - True value: 0.9612616959383189
	dc.w 8480,-31651,31651,8480   ; 75 deg - True value: 0.9659258262890683
	dc.w 7927,-31794,31794,7927   ; 76 deg - True value: 0.9702957262759965
	dc.w 7371,-31928,31928,7371   ; 77 deg - True value: 0.9743700647852352
	dc.w 6812,-32051,32051,6812   ; 78 deg - True value: 0.9781476007338056
	dc.w 6252,-32165,32165,6252   ; 79 deg - True value: 0.981627183447664
	dc.w 5690,-32270,32270,5690   ; 80 deg - True value: 0.984807753012208
	dc.w 5126,-32364,32364,5126   ; 81 deg - True value: 0.9876883405951378
	dc.w 4560,-32449,32449,4560   ; 82 deg - True value: 0.9902680687415703
	dc.w 3993,-32523,32523,3993   ; 83 deg - True value: 0.992546151641322
	dc.w 3425,-32588,32588,3425   ; 84 deg - True value: 0.9945218953682733
	dc.w 2855,-32643,32643,2855   ; 85 deg - True value: 0.9961946980917455
	dc.w 2285,-32688,32688,2285   ; 86 deg - True value: 0.9975640502598242
	dc.w 1714,-32723,32723,1714   ; 87 deg - True value: 0.9986295347545738
	dc.w 1143,-32748,32748,1143   ; 88 deg - True value: 0.9993908270190958
	dc.w 571,-32763,32763,571   ; 89 deg - True value: 0.9998476951563913
	dc.w 2,-32768,32768,2   ; 90 deg - True value: 1
	dc.w -571,-32763,32763,-571   ; 91 deg - True value: 0.9998476951563913
	dc.w -1143,-32748,32748,-1143   ; 92 deg - True value: 0.9993908270190958
	dc.w -1714,-32723,32723,-1714   ; 93 deg - True value: 0.9986295347545738
	dc.w -2285,-32688,32688,-2285   ; 94 deg - True value: 0.9975640502598242
	dc.w -2855,-32643,32643,-2855   ; 95 deg - True value: 0.9961946980917455
	dc.w -3425,-32588,32588,-3425   ; 96 deg - True value: 0.9945218953682734
	dc.w -3993,-32523,32523,-3993   ; 97 deg - True value: 0.9925461516413221
	dc.w -4560,-32449,32449,-4560   ; 98 deg - True value: 0.9902680687415704
	dc.w -5126,-32364,32364,-5126   ; 99 deg - True value: 0.9876883405951377
	dc.w -5690,-32270,32270,-5690   ; 100 deg - True value: 0.984807753012208
	dc.w -6252,-32165,32165,-6252   ; 101 deg - True value: 0.981627183447664
	dc.w -6812,-32051,32051,-6812   ; 102 deg - True value: 0.9781476007338057
	dc.w -7371,-31928,31928,-7371   ; 103 deg - True value: 0.9743700647852352
	dc.w -7927,-31794,31794,-7927   ; 104 deg - True value: 0.9702957262759965
	dc.w -8480,-31651,31651,-8480   ; 105 deg - True value: 0.9659258262890683
	dc.w -9032,-31498,31498,-9032   ; 106 deg - True value: 0.9612616959383189
	dc.w -9580,-31336,31336,-9580   ; 107 deg - True value: 0.9563047559630355
	dc.w -10125,-31164,31164,-10125   ; 108 deg - True value: 0.9510565162951536
	dc.w -10668,-30982,30982,-10668   ; 109 deg - True value: 0.9455185755993168
	dc.w -11207,-30791,30791,-11207   ; 110 deg - True value: 0.9396926207859084
	dc.w -11743,-30591,30591,-11743   ; 111 deg - True value: 0.9335804264972017
	dc.w -12275,-30381,30381,-12275   ; 112 deg - True value: 0.9271838545667874
	dc.w -12803,-30163,30163,-12803   ; 113 deg - True value: 0.9205048534524404
	dc.w -13327,-29935,29935,-13327   ; 114 deg - True value: 0.913545457642601
	dc.w -13848,-29697,29697,-13848   ; 115 deg - True value: 0.90630778703665
	dc.w -14364,-29451,29451,-14364   ; 116 deg - True value: 0.8987940462991669
	dc.w -14876,-29196,29196,-14876   ; 117 deg - True value: 0.8910065241883679
	dc.w -15383,-28932,28932,-15383   ; 118 deg - True value: 0.8829475928589271
	dc.w -15886,-28659,28659,-15886   ; 119 deg - True value: 0.8746197071393959
	dc.w -16383,-28377,28377,-16383   ; 120 deg - True value: 0.8660254037844387
	dc.w -16876,-28087,28087,-16876   ; 121 deg - True value: 0.8571673007021123
	dc.w -17364,-27788,27788,-17364   ; 122 deg - True value: 0.8480480961564261
	dc.w -17846,-27481,27481,-17846   ; 123 deg - True value: 0.838670567945424
	dc.w -18323,-27165,27165,-18323   ; 124 deg - True value: 0.8290375725550417
	dc.w -18794,-26841,26841,-18794   ; 125 deg - True value: 0.819152044288992
	dc.w -19260,-26509,26509,-19260   ; 126 deg - True value: 0.8090169943749475
	dc.w -19720,-26169,26169,-19720   ; 127 deg - True value: 0.7986355100472927
	dc.w -20173,-25821,25821,-20173   ; 128 deg - True value: 0.788010753606722
	dc.w -20621,-25465,25465,-20621   ; 129 deg - True value: 0.777145961456971
	dc.w -21062,-25101,25101,-21062   ; 130 deg - True value: 0.766044443118978
	dc.w -21497,-24730,24730,-21497   ; 131 deg - True value: 0.7547095802227718
	dc.w -21926,-24351,24351,-21926   ; 132 deg - True value: 0.7431448254773942
	dc.w -22347,-23964,23964,-22347   ; 133 deg - True value: 0.7313537016191706
	dc.w -22762,-23571,23571,-22762   ; 134 deg - True value: 0.7193398003386514
	dc.w -23170,-23170,23170,-23170   ; 135 deg - True value: 0.7071067811865476
	dc.w -23571,-22762,22762,-23571   ; 136 deg - True value: 0.6946583704589971
	dc.w -23964,-22347,22347,-23964   ; 137 deg - True value: 0.6819983600624986
	dc.w -24351,-21926,21926,-24351   ; 138 deg - True value: 0.6691306063588583
	dc.w -24730,-21497,21497,-24730   ; 139 deg - True value: 0.6560590289905073
	dc.w -25101,-21062,21062,-25101   ; 140 deg - True value: 0.6427876096865395
	dc.w -25465,-20621,20621,-25465   ; 141 deg - True value: 0.6293203910498377
	dc.w -25821,-20173,20173,-25821   ; 142 deg - True value: 0.6156614753256584
	dc.w -26169,-19720,19720,-26169   ; 143 deg - True value: 0.6018150231520482
	dc.w -26509,-19260,19260,-26509   ; 144 deg - True value: 0.5877852522924732
	dc.w -26841,-18794,18794,-26841   ; 145 deg - True value: 0.5735764363510464
	dc.w -27165,-18323,18323,-27165   ; 146 deg - True value: 0.5591929034707469
	dc.w -27481,-17846,17846,-27481   ; 147 deg - True value: 0.5446390350150269
	dc.w -27788,-17364,17364,-27788   ; 148 deg - True value: 0.5299192642332049
	dc.w -28087,-16876,16876,-28087   ; 149 deg - True value: 0.5150380749100544
	dc.w -28377,-16383,16383,-28377   ; 150 deg - True value: 0.49999999999999994
	dc.w -28659,-15886,15886,-28659   ; 151 deg - True value: 0.48480962024633717
	dc.w -28932,-15383,15383,-28932   ; 152 deg - True value: 0.4694715627858911
	dc.w -29196,-14876,14876,-29196   ; 153 deg - True value: 0.45399049973954686
	dc.w -29451,-14364,14364,-29451   ; 154 deg - True value: 0.4383711467890773
	dc.w -29697,-13848,13848,-29697   ; 155 deg - True value: 0.4226182617406995
	dc.w -29935,-13327,13327,-29935   ; 156 deg - True value: 0.40673664307580043
	dc.w -30163,-12803,12803,-30163   ; 157 deg - True value: 0.39073112848927416
	dc.w -30381,-12275,12275,-30381   ; 158 deg - True value: 0.37460659341591224
	dc.w -30591,-11743,11743,-30591   ; 159 deg - True value: 0.3583679495453002
	dc.w -30791,-11207,11207,-30791   ; 160 deg - True value: 0.3420201433256689
	dc.w -30982,-10668,10668,-30982   ; 161 deg - True value: 0.325568154457157
	dc.w -31164,-10125,10125,-31164   ; 162 deg - True value: 0.3090169943749475
	dc.w -31336,-9580,9580,-31336   ; 163 deg - True value: 0.29237170472273705
	dc.w -31498,-9032,9032,-31498   ; 164 deg - True value: 0.27563735581699966
	dc.w -31651,-8480,8480,-31651   ; 165 deg - True value: 0.258819045102521
	dc.w -31794,-7927,7927,-31794   ; 166 deg - True value: 0.24192189559966773
	dc.w -31928,-7371,7371,-31928   ; 167 deg - True value: 0.22495105434386478
	dc.w -32051,-6812,6812,-32051   ; 168 deg - True value: 0.20791169081775931
	dc.w -32165,-6252,6252,-32165   ; 169 deg - True value: 0.19080899537654497
	dc.w -32270,-5690,5690,-32270   ; 170 deg - True value: 0.17364817766693028
	dc.w -32364,-5126,5126,-32364   ; 171 deg - True value: 0.15643446504023098
	dc.w -32449,-4560,4560,-32449   ; 172 deg - True value: 0.13917310096006574
	dc.w -32523,-3993,3993,-32523   ; 173 deg - True value: 0.12186934340514755
	dc.w -32588,-3425,3425,-32588   ; 174 deg - True value: 0.10452846326765373
	dc.w -32643,-2855,2855,-32643   ; 175 deg - True value: 0.08715574274765864
	dc.w -32688,-2285,2285,-32688   ; 176 deg - True value: 0.06975647374412552
	dc.w -32723,-1714,1714,-32723   ; 177 deg - True value: 0.05233595624294381
	dc.w -32748,-1143,1143,-32748   ; 178 deg - True value: 0.0348994967025007
	dc.w -32763,-571,571,-32763   ; 179 deg - True value: 0.01745240643728344
	dc.w -32768,-4,4,-32768   ; 180 deg - True value: 1.2246467991473532e-16
	dc.w -32763,571,-571,-32763   ; 181 deg - True value: -0.017452406437283192
	dc.w -32748,1143,-1143,-32748   ; 182 deg - True value: -0.0348994967025009
	dc.w -32723,1714,-1714,-32723   ; 183 deg - True value: -0.052335956242943564
	dc.w -32688,2285,-2285,-32688   ; 184 deg - True value: -0.06975647374412483
	dc.w -32643,2855,-2855,-32643   ; 185 deg - True value: -0.08715574274765794
	dc.w -32588,3425,-3425,-32588   ; 186 deg - True value: -0.10452846326765305
	dc.w -32523,3993,-3993,-32523   ; 187 deg - True value: -0.12186934340514775
	dc.w -32449,4560,-4560,-32449   ; 188 deg - True value: -0.13917310096006552
	dc.w -32364,5126,-5126,-32364   ; 189 deg - True value: -0.15643446504023073
	dc.w -32270,5690,-5690,-32270   ; 190 deg - True value: -0.17364817766693047
	dc.w -32165,6252,-6252,-32165   ; 191 deg - True value: -0.19080899537654472
	dc.w -32051,6812,-6812,-32051   ; 192 deg - True value: -0.20791169081775907
	dc.w -31928,7371,-7371,-31928   ; 193 deg - True value: -0.22495105434386498
	dc.w -31794,7927,-7927,-31794   ; 194 deg - True value: -0.2419218955996675
	dc.w -31651,8480,-8480,-31651   ; 195 deg - True value: -0.25881904510252035
	dc.w -31498,9032,-9032,-31498   ; 196 deg - True value: -0.275637355816999
	dc.w -31336,9580,-9580,-31336   ; 197 deg - True value: -0.2923717047227364
	dc.w -31164,10125,-10125,-31164   ; 198 deg - True value: -0.30901699437494773
	dc.w -30982,10668,-10668,-30982   ; 199 deg - True value: -0.32556815445715676
	dc.w -30791,11207,-11207,-30791   ; 200 deg - True value: -0.34202014332566866
	dc.w -30591,11743,-11743,-30591   ; 201 deg - True value: -0.35836794954530043
	dc.w -30381,12275,-12275,-30381   ; 202 deg - True value: -0.374606593415912
	dc.w -30163,12803,-12803,-30163   ; 203 deg - True value: -0.39073112848927355
	dc.w -29935,13327,-13327,-29935   ; 204 deg - True value: -0.4067366430757998
	dc.w -29697,13848,-13848,-29697   ; 205 deg - True value: -0.4226182617406993
	dc.w -29451,14364,-14364,-29451   ; 206 deg - True value: -0.43837114678907707
	dc.w -29196,14876,-14876,-29196   ; 207 deg - True value: -0.45399049973954625
	dc.w -28932,15383,-15383,-28932   ; 208 deg - True value: -0.46947156278589086
	dc.w -28659,15886,-15886,-28659   ; 209 deg - True value: -0.48480962024633695
	dc.w -28377,16384,-16384,-28377   ; 210 deg - True value: -0.5000000000000001
	dc.w -28087,16876,-16876,-28087   ; 211 deg - True value: -0.5150380749100542
	dc.w -27788,17364,-17364,-27788   ; 212 deg - True value: -0.5299192642332048
	dc.w -27481,17846,-17846,-27481   ; 213 deg - True value: -0.5446390350150271
	dc.w -27165,18323,-18323,-27165   ; 214 deg - True value: -0.5591929034707467
	dc.w -26841,18794,-18794,-26841   ; 215 deg - True value: -0.5735764363510458
	dc.w -26509,19260,-19260,-26509   ; 216 deg - True value: -0.587785252292473
	dc.w -26169,19720,-19720,-26169   ; 217 deg - True value: -0.601815023152048
	dc.w -25821,20173,-20173,-25821   ; 218 deg - True value: -0.6156614753256578
	dc.w -25465,20621,-20621,-25465   ; 219 deg - True value: -0.6293203910498376
	dc.w -25101,21062,-21062,-25101   ; 220 deg - True value: -0.6427876096865393
	dc.w -24730,21497,-21497,-24730   ; 221 deg - True value: -0.6560590289905074
	dc.w -24351,21926,-21926,-24351   ; 222 deg - True value: -0.6691306063588582
	dc.w -23964,22347,-22347,-23964   ; 223 deg - True value: -0.6819983600624984
	dc.w -23571,22762,-22762,-23571   ; 224 deg - True value: -0.6946583704589974
	dc.w -23170,23170,-23170,-23170   ; 225 deg - True value: -0.7071067811865475
	dc.w -22762,23571,-23571,-22762   ; 226 deg - True value: -0.7193398003386509
	dc.w -22347,23964,-23964,-22347   ; 227 deg - True value: -0.7313537016191701
	dc.w -21926,24351,-24351,-21926   ; 228 deg - True value: -0.743144825477394
	dc.w -21497,24730,-24730,-21497   ; 229 deg - True value: -0.7547095802227717
	dc.w -21062,25101,-25101,-21062   ; 230 deg - True value: -0.7660444431189779
	dc.w -20621,25465,-25465,-20621   ; 231 deg - True value: -0.7771459614569711
	dc.w -20173,25821,-25821,-20173   ; 232 deg - True value: -0.7880107536067221
	dc.w -19720,26169,-26169,-19720   ; 233 deg - True value: -0.7986355100472928
	dc.w -19260,26509,-26509,-19260   ; 234 deg - True value: -0.8090169943749473
	dc.w -18794,26841,-26841,-18794   ; 235 deg - True value: -0.8191520442889916
	dc.w -18323,27165,-27165,-18323   ; 236 deg - True value: -0.8290375725550414
	dc.w -17846,27481,-27481,-17846   ; 237 deg - True value: -0.838670567945424
	dc.w -17364,27788,-27788,-17364   ; 238 deg - True value: -0.848048096156426
	dc.w -16876,28087,-28087,-16876   ; 239 deg - True value: -0.8571673007021121
	dc.w -16384,28377,-28377,-16384   ; 240 deg - True value: -0.8660254037844385
	dc.w -15886,28659,-28659,-15886   ; 241 deg - True value: -0.8746197071393959
	dc.w -15383,28932,-28932,-15383   ; 242 deg - True value: -0.882947592858927
	dc.w -14876,29196,-29196,-14876   ; 243 deg - True value: -0.8910065241883678
	dc.w -14364,29451,-29451,-14364   ; 244 deg - True value: -0.8987940462991668
	dc.w -13848,29697,-29697,-13848   ; 245 deg - True value: -0.9063077870366497
	dc.w -13327,29935,-29935,-13327   ; 246 deg - True value: -0.913545457642601
	dc.w -12803,30163,-30163,-12803   ; 247 deg - True value: -0.9205048534524403
	dc.w -12275,30381,-30381,-12275   ; 248 deg - True value: -0.9271838545667873
	dc.w -11743,30591,-30591,-11743   ; 249 deg - True value: -0.9335804264972016
	dc.w -11207,30791,-30791,-11207   ; 250 deg - True value: -0.9396926207859082
	dc.w -10668,30982,-30982,-10668   ; 251 deg - True value: -0.9455185755993168
	dc.w -10125,31164,-31164,-10125   ; 252 deg - True value: -0.9510565162951535
	dc.w -9580,31336,-31336,-9580   ; 253 deg - True value: -0.9563047559630353
	dc.w -9032,31498,-31498,-9032   ; 254 deg - True value: -0.9612616959383189
	dc.w -8480,31651,-31651,-8480   ; 255 deg - True value: -0.9659258262890683
	dc.w -7927,31794,-31794,-7927   ; 256 deg - True value: -0.9702957262759965
	dc.w -7371,31928,-31928,-7371   ; 257 deg - True value: -0.9743700647852351
	dc.w -6812,32051,-32051,-6812   ; 258 deg - True value: -0.9781476007338056
	dc.w -6252,32165,-32165,-6252   ; 259 deg - True value: -0.9816271834476639
	dc.w -5690,32270,-32270,-5690   ; 260 deg - True value: -0.984807753012208
	dc.w -5126,32364,-32364,-5126   ; 261 deg - True value: -0.9876883405951377
	dc.w -4560,32449,-32449,-4560   ; 262 deg - True value: -0.9902680687415704
	dc.w -3993,32523,-32523,-3993   ; 263 deg - True value: -0.9925461516413221
	dc.w -3425,32588,-32588,-3425   ; 264 deg - True value: -0.9945218953682734
	dc.w -2855,32643,-32643,-2855   ; 265 deg - True value: -0.9961946980917455
	dc.w -2285,32688,-32688,-2285   ; 266 deg - True value: -0.9975640502598242
	dc.w -1714,32723,-32723,-1714   ; 267 deg - True value: -0.9986295347545738
	dc.w -1143,32748,-32748,-1143   ; 268 deg - True value: -0.9993908270190957
	dc.w -571,32763,-32763,-571   ; 269 deg - True value: -0.9998476951563913
	dc.w -6,32768,-32768,-6   ; 270 deg - True value: -1
	dc.w 571,32763,-32763,571   ; 271 deg - True value: -0.9998476951563913
	dc.w 1143,32748,-32748,1143   ; 272 deg - True value: -0.9993908270190958
	dc.w 1714,32723,-32723,1714   ; 273 deg - True value: -0.9986295347545738
	dc.w 2285,32688,-32688,2285   ; 274 deg - True value: -0.9975640502598243
	dc.w 2855,32643,-32643,2855   ; 275 deg - True value: -0.9961946980917455
	dc.w 3425,32588,-32588,3425   ; 276 deg - True value: -0.9945218953682734
	dc.w 3993,32523,-32523,3993   ; 277 deg - True value: -0.992546151641322
	dc.w 4560,32449,-32449,4560   ; 278 deg - True value: -0.9902680687415704
	dc.w 5126,32364,-32364,5126   ; 279 deg - True value: -0.9876883405951378
	dc.w 5690,32270,-32270,5690   ; 280 deg - True value: -0.9848077530122081
	dc.w 6252,32165,-32165,6252   ; 281 deg - True value: -0.9816271834476641
	dc.w 6812,32051,-32051,6812   ; 282 deg - True value: -0.9781476007338058
	dc.w 7371,31928,-31928,7371   ; 283 deg - True value: -0.9743700647852352
	dc.w 7927,31794,-31794,7927   ; 284 deg - True value: -0.9702957262759966
	dc.w 8480,31651,-31651,8480   ; 285 deg - True value: -0.9659258262890682
	dc.w 9032,31498,-31498,9032   ; 286 deg - True value: -0.9612616959383188
	dc.w 9580,31336,-31336,9580   ; 287 deg - True value: -0.9563047559630354
	dc.w 10125,31164,-31164,10125   ; 288 deg - True value: -0.9510565162951536
	dc.w 10668,30982,-30982,10668   ; 289 deg - True value: -0.945518575599317
	dc.w 11207,30791,-30791,11207   ; 290 deg - True value: -0.9396926207859085
	dc.w 11743,30591,-30591,11743   ; 291 deg - True value: -0.9335804264972021
	dc.w 12275,30381,-30381,12275   ; 292 deg - True value: -0.9271838545667874
	dc.w 12803,30163,-30163,12803   ; 293 deg - True value: -0.9205048534524405
	dc.w 13327,29935,-29935,13327   ; 294 deg - True value: -0.9135454576426008
	dc.w 13848,29697,-29697,13848   ; 295 deg - True value: -0.9063077870366498
	dc.w 14364,29451,-29451,14364   ; 296 deg - True value: -0.898794046299167
	dc.w 14876,29196,-29196,14876   ; 297 deg - True value: -0.891006524188368
	dc.w 15383,28932,-28932,15383   ; 298 deg - True value: -0.8829475928589271
	dc.w 15886,28659,-28659,15886   ; 299 deg - True value: -0.8746197071393961
	dc.w 16384,28377,-28377,16384   ; 300 deg - True value: -0.8660254037844386
	dc.w 16876,28087,-28087,16876   ; 301 deg - True value: -0.8571673007021123
	dc.w 17364,27788,-27788,17364   ; 302 deg - True value: -0.8480480961564261
	dc.w 17846,27481,-27481,17846   ; 303 deg - True value: -0.8386705679454243
	dc.w 18323,27165,-27165,18323   ; 304 deg - True value: -0.8290375725550421
	dc.w 18794,26841,-26841,18794   ; 305 deg - True value: -0.8191520442889918
	dc.w 19260,26509,-26509,19260   ; 306 deg - True value: -0.8090169943749476
	dc.w 19720,26169,-26169,19720   ; 307 deg - True value: -0.798635510047293
	dc.w 20173,25821,-25821,20173   ; 308 deg - True value: -0.7880107536067218
	dc.w 20621,25465,-25465,20621   ; 309 deg - True value: -0.7771459614569708
	dc.w 21062,25101,-25101,21062   ; 310 deg - True value: -0.7660444431189781
	dc.w 21497,24730,-24730,21497   ; 311 deg - True value: -0.7547095802227721
	dc.w 21926,24351,-24351,21926   ; 312 deg - True value: -0.7431448254773946
	dc.w 22347,23964,-23964,22347   ; 313 deg - True value: -0.731353701619171
	dc.w 22762,23571,-23571,22762   ; 314 deg - True value: -0.7193398003386517
	dc.w 23170,23170,-23170,23170   ; 315 deg - True value: -0.7071067811865477
	dc.w 23571,22762,-22762,23571   ; 316 deg - True value: -0.6946583704589976
	dc.w 23964,22347,-22347,23964   ; 317 deg - True value: -0.6819983600624983
	dc.w 24351,21926,-21926,24351   ; 318 deg - True value: -0.6691306063588581
	dc.w 24730,21497,-21497,24730   ; 319 deg - True value: -0.6560590289905074
	dc.w 25101,21062,-21062,25101   ; 320 deg - True value: -0.6427876096865396
	dc.w 25465,20621,-20621,25465   ; 321 deg - True value: -0.6293203910498378
	dc.w 25821,20173,-20173,25821   ; 322 deg - True value: -0.6156614753256588
	dc.w 26169,19720,-19720,26169   ; 323 deg - True value: -0.6018150231520483
	dc.w 26509,19260,-19260,26509   ; 324 deg - True value: -0.5877852522924734
	dc.w 26841,18794,-18794,26841   ; 325 deg - True value: -0.5735764363510465
	dc.w 27165,18323,-18323,27165   ; 326 deg - True value: -0.5591929034707473
	dc.w 27481,17846,-17846,27481   ; 327 deg - True value: -0.544639035015027
	dc.w 27788,17364,-17364,27788   ; 328 deg - True value: -0.5299192642332058
	dc.w 28087,16876,-16876,28087   ; 329 deg - True value: -0.5150380749100545
	dc.w 28377,16384,-16384,28377   ; 330 deg - True value: -0.5000000000000004
	dc.w 28659,15886,-15886,28659   ; 331 deg - True value: -0.4848096202463369
	dc.w 28932,15383,-15383,28932   ; 332 deg - True value: -0.4694715627858908
	dc.w 29196,14876,-14876,29196   ; 333 deg - True value: -0.45399049973954697
	dc.w 29451,14364,-14364,29451   ; 334 deg - True value: -0.438371146789077
	dc.w 29697,13848,-13848,29697   ; 335 deg - True value: -0.4226182617407
	dc.w 29935,13327,-13327,29935   ; 336 deg - True value: -0.40673664307580015
	dc.w 30163,12803,-12803,30163   ; 337 deg - True value: -0.3907311284892747
	dc.w 30381,12275,-12275,30381   ; 338 deg - True value: -0.37460659341591235
	dc.w 30591,11743,-11743,30591   ; 339 deg - True value: -0.35836794954530077
	dc.w 30791,11207,-11207,30791   ; 340 deg - True value: -0.3420201433256686
	dc.w 30982,10668,-10668,30982   ; 341 deg - True value: -0.32556815445715753
	dc.w 31164,10125,-10125,31164   ; 342 deg - True value: -0.3090169943749476
	dc.w 31336,9580,-9580,31336   ; 343 deg - True value: -0.29237170472273627
	dc.w 31498,9032,-9032,31498   ; 344 deg - True value: -0.2756373558169998
	dc.w 31651,8480,-8480,31651   ; 345 deg - True value: -0.2588190451025207
	dc.w 31794,7927,-7927,31794   ; 346 deg - True value: -0.24192189559966787
	dc.w 31928,7371,-7371,31928   ; 347 deg - True value: -0.22495105434386534
	dc.w 32051,6812,-6812,32051   ; 348 deg - True value: -0.20791169081775987
	dc.w 32165,6252,-6252,32165   ; 349 deg - True value: -0.19080899537654467
	dc.w 32270,5690,-5690,32270   ; 350 deg - True value: -0.17364817766693127
	dc.w 32364,5126,-5126,32364   ; 351 deg - True value: -0.15643446504023112
	dc.w 32449,4560,-4560,32449   ; 352 deg - True value: -0.13917310096006588
	dc.w 32523,3993,-3993,32523   ; 353 deg - True value: -0.12186934340514811
	dc.w 32588,3425,-3425,32588   ; 354 deg - True value: -0.10452846326765342
	dc.w 32643,2855,-2855,32643   ; 355 deg - True value: -0.08715574274765832
	dc.w 32688,2285,-2285,32688   ; 356 deg - True value: -0.06975647374412476
	dc.w 32723,1714,-1714,32723   ; 357 deg - True value: -0.05233595624294437
	dc.w 32748,1143,-1143,32748   ; 358 deg - True value: -0.034899496702500823
	dc.w 32763,571,-571,32763   ; 359 deg - True value: -0.01745240643728445


SIN_TABLE_3:
	dc.w 16384,0,0,16384   ; 0 deg - True value: 0
	dc.w 16381,-285,285,16381   ; 1 deg - True value: 0.01745240643728351
	dc.w 16374,-571,571,16374   ; 2 deg - True value: 0.03489949670250097
	dc.w 16361,-857,857,16361   ; 3 deg - True value: 0.05233595624294383
	dc.w 16344,-1142,1142,16344   ; 4 deg - True value: 0.0697564737441253
	dc.w 16321,-1427,1427,16321   ; 5 deg - True value: 0.08715574274765817
	dc.w 16294,-1712,1712,16294   ; 6 deg - True value: 0.10452846326765346
	dc.w 16261,-1996,1996,16261   ; 7 deg - True value: 0.12186934340514748
	dc.w 16224,-2280,2280,16224   ; 8 deg - True value: 0.13917310096006544
	dc.w 16182,-2563,2563,16182   ; 9 deg - True value: 0.15643446504023087
	dc.w 16135,-2845,2845,16135   ; 10 deg - True value: 0.17364817766693033
	dc.w 16082,-3126,3126,16082   ; 11 deg - True value: 0.1908089953765448
	dc.w 16025,-3406,3406,16025   ; 12 deg - True value: 0.20791169081775931
	dc.w 15964,-3685,3685,15964   ; 13 deg - True value: 0.224951054343865
	dc.w 15897,-3963,3963,15897   ; 14 deg - True value: 0.24192189559966773
	dc.w 15825,-4240,4240,15825   ; 15 deg - True value: 0.25881904510252074
	dc.w 15749,-4516,4516,15749   ; 16 deg - True value: 0.27563735581699916
	dc.w 15668,-4790,4790,15668   ; 17 deg - True value: 0.29237170472273677
	dc.w 15582,-5062,5062,15582   ; 18 deg - True value: 0.3090169943749474
	dc.w 15491,-5334,5334,15491   ; 19 deg - True value: 0.32556815445715664
	dc.w 15395,-5603,5603,15395   ; 20 deg - True value: 0.3420201433256687
	dc.w 15295,-5871,5871,15295   ; 21 deg - True value: 0.35836794954530027
	dc.w 15190,-6137,6137,15190   ; 22 deg - True value: 0.374606593415912
	dc.w 15081,-6401,6401,15081   ; 23 deg - True value: 0.3907311284892737
	dc.w 14967,-6663,6663,14967   ; 24 deg - True value: 0.40673664307580015
	dc.w 14848,-6924,6924,14848   ; 25 deg - True value: 0.42261826174069944
	dc.w 14725,-7182,7182,14725   ; 26 deg - True value: 0.4383711467890774
	dc.w 14598,-7438,7438,14598   ; 27 deg - True value: 0.45399049973954675
	dc.w 14466,-7691,7691,14466   ; 28 deg - True value: 0.4694715627858908
	dc.w 14329,-7943,7943,14329   ; 29 deg - True value: 0.48480962024633706
	dc.w 14188,-8191,8191,14188   ; 30 deg - True value: 0.49999999999999994
	dc.w 14043,-8438,8438,14043   ; 31 deg - True value: 0.5150380749100542
	dc.w 13894,-8682,8682,13894   ; 32 deg - True value: 0.5299192642332049
	dc.w 13740,-8923,8923,13740   ; 33 deg - True value: 0.5446390350150271
	dc.w 13582,-9161,9161,13582   ; 34 deg - True value: 0.5591929034707469
	dc.w 13420,-9397,9397,13420   ; 35 deg - True value: 0.573576436351046
	dc.w 13254,-9630,9630,13254   ; 36 deg - True value: 0.5877852522924731
	dc.w 13084,-9860,9860,13084   ; 37 deg - True value: 0.6018150231520483
	dc.w 12910,-10086,10086,12910   ; 38 deg - True value: 0.6156614753256582
	dc.w 12732,-10310,10310,12732   ; 39 deg - True value: 0.6293203910498374
	dc.w 12550,-10531,10531,12550   ; 40 deg - True value: 0.6427876096865393
	dc.w 12365,-10748,10748,12365   ; 41 deg - True value: 0.6560590289905072
	dc.w 12175,-10963,10963,12175   ; 42 deg - True value: 0.6691306063588582
	dc.w 11982,-11173,11173,11982   ; 43 deg - True value: 0.6819983600624985
	dc.w 11785,-11381,11381,11785   ; 44 deg - True value: 0.6946583704589973
	dc.w 11585,-11585,11585,11585   ; 45 deg - True value: 0.7071067811865475
	dc.w 11381,-11785,11785,11381   ; 46 deg - True value: 0.7193398003386511
	dc.w 11173,-11982,11982,11173   ; 47 deg - True value: 0.7313537016191705
	dc.w 10963,-12175,12175,10963   ; 48 deg - True value: 0.7431448254773942
	dc.w 10748,-12365,12365,10748   ; 49 deg - True value: 0.754709580222772
	dc.w 10531,-12550,12550,10531   ; 50 deg - True value: 0.766044443118978
	dc.w 10310,-12732,12732,10310   ; 51 deg - True value: 0.7771459614569708
	dc.w 10086,-12910,12910,10086   ; 52 deg - True value: 0.788010753606722
	dc.w 9860,-13084,13084,9860   ; 53 deg - True value: 0.7986355100472928
	dc.w 9630,-13254,13254,9630   ; 54 deg - True value: 0.8090169943749475
	dc.w 9397,-13420,13420,9397   ; 55 deg - True value: 0.8191520442889918
	dc.w 9161,-13582,13582,9161   ; 56 deg - True value: 0.8290375725550417
	dc.w 8923,-13740,13740,8923   ; 57 deg - True value: 0.8386705679454239
	dc.w 8682,-13894,13894,8682   ; 58 deg - True value: 0.8480480961564261
	dc.w 8438,-14043,14043,8438   ; 59 deg - True value: 0.8571673007021122
	dc.w 8192,-14188,14188,8192   ; 60 deg - True value: 0.8660254037844386
	dc.w 7943,-14329,14329,7943   ; 61 deg - True value: 0.8746197071393957
	dc.w 7691,-14466,14466,7691   ; 62 deg - True value: 0.8829475928589269
	dc.w 7438,-14598,14598,7438   ; 63 deg - True value: 0.8910065241883678
	dc.w 7182,-14725,14725,7182   ; 64 deg - True value: 0.898794046299167
	dc.w 6924,-14848,14848,6924   ; 65 deg - True value: 0.9063077870366499
	dc.w 6663,-14967,14967,6663   ; 66 deg - True value: 0.9135454576426009
	dc.w 6401,-15081,15081,6401   ; 67 deg - True value: 0.9205048534524403
	dc.w 6137,-15190,15190,6137   ; 68 deg - True value: 0.9271838545667874
	dc.w 5871,-15295,15295,5871   ; 69 deg - True value: 0.9335804264972017
	dc.w 5603,-15395,15395,5603   ; 70 deg - True value: 0.9396926207859083
	dc.w 5334,-15491,15491,5334   ; 71 deg - True value: 0.9455185755993167
	dc.w 5062,-15582,15582,5062   ; 72 deg - True value: 0.9510565162951535
	dc.w 4790,-15668,15668,4790   ; 73 deg - True value: 0.9563047559630354
	dc.w 4516,-15749,15749,4516   ; 74 deg - True value: 0.9612616959383189
	dc.w 4240,-15825,15825,4240   ; 75 deg - True value: 0.9659258262890683
	dc.w 3963,-15897,15897,3963   ; 76 deg - True value: 0.9702957262759965
	dc.w 3685,-15964,15964,3685   ; 77 deg - True value: 0.9743700647852352
	dc.w 3406,-16025,16025,3406   ; 78 deg - True value: 0.9781476007338056
	dc.w 3126,-16082,16082,3126   ; 79 deg - True value: 0.981627183447664
	dc.w 2845,-16135,16135,2845   ; 80 deg - True value: 0.984807753012208
	dc.w 2563,-16182,16182,2563   ; 81 deg - True value: 0.9876883405951378
	dc.w 2280,-16224,16224,2280   ; 82 deg - True value: 0.9902680687415703
	dc.w 1996,-16261,16261,1996   ; 83 deg - True value: 0.992546151641322
	dc.w 1712,-16294,16294,1712   ; 84 deg - True value: 0.9945218953682733
	dc.w 1427,-16321,16321,1427   ; 85 deg - True value: 0.9961946980917455
	dc.w 1142,-16344,16344,1142   ; 86 deg - True value: 0.9975640502598242
	dc.w 857,-16361,16361,857   ; 87 deg - True value: 0.9986295347545738
	dc.w 571,-16374,16374,571   ; 88 deg - True value: 0.9993908270190958
	dc.w 285,-16381,16381,285   ; 89 deg - True value: 0.9998476951563913
	dc.w 1,-16384,16384,1   ; 90 deg - True value: 1
	dc.w -285,-16381,16381,-285   ; 91 deg - True value: 0.9998476951563913
	dc.w -571,-16374,16374,-571   ; 92 deg - True value: 0.9993908270190958
	dc.w -857,-16361,16361,-857   ; 93 deg - True value: 0.9986295347545738
	dc.w -1142,-16344,16344,-1142   ; 94 deg - True value: 0.9975640502598242
	dc.w -1427,-16321,16321,-1427   ; 95 deg - True value: 0.9961946980917455
	dc.w -1712,-16294,16294,-1712   ; 96 deg - True value: 0.9945218953682734
	dc.w -1996,-16261,16261,-1996   ; 97 deg - True value: 0.9925461516413221
	dc.w -2280,-16224,16224,-2280   ; 98 deg - True value: 0.9902680687415704
	dc.w -2563,-16182,16182,-2563   ; 99 deg - True value: 0.9876883405951377
	dc.w -2845,-16135,16135,-2845   ; 100 deg - True value: 0.984807753012208
	dc.w -3126,-16082,16082,-3126   ; 101 deg - True value: 0.981627183447664
	dc.w -3406,-16025,16025,-3406   ; 102 deg - True value: 0.9781476007338057
	dc.w -3685,-15964,15964,-3685   ; 103 deg - True value: 0.9743700647852352
	dc.w -3963,-15897,15897,-3963   ; 104 deg - True value: 0.9702957262759965
	dc.w -4240,-15825,15825,-4240   ; 105 deg - True value: 0.9659258262890683
	dc.w -4516,-15749,15749,-4516   ; 106 deg - True value: 0.9612616959383189
	dc.w -4790,-15668,15668,-4790   ; 107 deg - True value: 0.9563047559630355
	dc.w -5062,-15582,15582,-5062   ; 108 deg - True value: 0.9510565162951536
	dc.w -5334,-15491,15491,-5334   ; 109 deg - True value: 0.9455185755993168
	dc.w -5603,-15395,15395,-5603   ; 110 deg - True value: 0.9396926207859084
	dc.w -5871,-15295,15295,-5871   ; 111 deg - True value: 0.9335804264972017
	dc.w -6137,-15190,15190,-6137   ; 112 deg - True value: 0.9271838545667874
	dc.w -6401,-15081,15081,-6401   ; 113 deg - True value: 0.9205048534524404
	dc.w -6663,-14967,14967,-6663   ; 114 deg - True value: 0.913545457642601
	dc.w -6924,-14848,14848,-6924   ; 115 deg - True value: 0.90630778703665
	dc.w -7182,-14725,14725,-7182   ; 116 deg - True value: 0.8987940462991669
	dc.w -7438,-14598,14598,-7438   ; 117 deg - True value: 0.8910065241883679
	dc.w -7691,-14466,14466,-7691   ; 118 deg - True value: 0.8829475928589271
	dc.w -7943,-14329,14329,-7943   ; 119 deg - True value: 0.8746197071393959
	dc.w -8191,-14188,14188,-8191   ; 120 deg - True value: 0.8660254037844387
	dc.w -8438,-14043,14043,-8438   ; 121 deg - True value: 0.8571673007021123
	dc.w -8682,-13894,13894,-8682   ; 122 deg - True value: 0.8480480961564261
	dc.w -8923,-13740,13740,-8923   ; 123 deg - True value: 0.838670567945424
	dc.w -9161,-13582,13582,-9161   ; 124 deg - True value: 0.8290375725550417
	dc.w -9397,-13420,13420,-9397   ; 125 deg - True value: 0.819152044288992
	dc.w -9630,-13254,13254,-9630   ; 126 deg - True value: 0.8090169943749475
	dc.w -9860,-13084,13084,-9860   ; 127 deg - True value: 0.7986355100472927
	dc.w -10086,-12910,12910,-10086   ; 128 deg - True value: 0.788010753606722
	dc.w -10310,-12732,12732,-10310   ; 129 deg - True value: 0.777145961456971
	dc.w -10531,-12550,12550,-10531   ; 130 deg - True value: 0.766044443118978
	dc.w -10748,-12365,12365,-10748   ; 131 deg - True value: 0.7547095802227718
	dc.w -10963,-12175,12175,-10963   ; 132 deg - True value: 0.7431448254773942
	dc.w -11173,-11982,11982,-11173   ; 133 deg - True value: 0.7313537016191706
	dc.w -11381,-11785,11785,-11381   ; 134 deg - True value: 0.7193398003386514
	dc.w -11585,-11585,11585,-11585   ; 135 deg - True value: 0.7071067811865476
	dc.w -11785,-11381,11381,-11785   ; 136 deg - True value: 0.6946583704589971
	dc.w -11982,-11173,11173,-11982   ; 137 deg - True value: 0.6819983600624986
	dc.w -12175,-10963,10963,-12175   ; 138 deg - True value: 0.6691306063588583
	dc.w -12365,-10748,10748,-12365   ; 139 deg - True value: 0.6560590289905073
	dc.w -12550,-10531,10531,-12550   ; 140 deg - True value: 0.6427876096865395
	dc.w -12732,-10310,10310,-12732   ; 141 deg - True value: 0.6293203910498377
	dc.w -12910,-10086,10086,-12910   ; 142 deg - True value: 0.6156614753256584
	dc.w -13084,-9860,9860,-13084   ; 143 deg - True value: 0.6018150231520482
	dc.w -13254,-9630,9630,-13254   ; 144 deg - True value: 0.5877852522924732
	dc.w -13420,-9397,9397,-13420   ; 145 deg - True value: 0.5735764363510464
	dc.w -13582,-9161,9161,-13582   ; 146 deg - True value: 0.5591929034707469
	dc.w -13740,-8923,8923,-13740   ; 147 deg - True value: 0.5446390350150269
	dc.w -13894,-8682,8682,-13894   ; 148 deg - True value: 0.5299192642332049
	dc.w -14043,-8438,8438,-14043   ; 149 deg - True value: 0.5150380749100544
	dc.w -14188,-8191,8191,-14188   ; 150 deg - True value: 0.49999999999999994
	dc.w -14329,-7943,7943,-14329   ; 151 deg - True value: 0.48480962024633717
	dc.w -14466,-7691,7691,-14466   ; 152 deg - True value: 0.4694715627858911
	dc.w -14598,-7438,7438,-14598   ; 153 deg - True value: 0.45399049973954686
	dc.w -14725,-7182,7182,-14725   ; 154 deg - True value: 0.4383711467890773
	dc.w -14848,-6924,6924,-14848   ; 155 deg - True value: 0.4226182617406995
	dc.w -14967,-6663,6663,-14967   ; 156 deg - True value: 0.40673664307580043
	dc.w -15081,-6401,6401,-15081   ; 157 deg - True value: 0.39073112848927416
	dc.w -15190,-6137,6137,-15190   ; 158 deg - True value: 0.37460659341591224
	dc.w -15295,-5871,5871,-15295   ; 159 deg - True value: 0.3583679495453002
	dc.w -15395,-5603,5603,-15395   ; 160 deg - True value: 0.3420201433256689
	dc.w -15491,-5334,5334,-15491   ; 161 deg - True value: 0.325568154457157
	dc.w -15582,-5062,5062,-15582   ; 162 deg - True value: 0.3090169943749475
	dc.w -15668,-4790,4790,-15668   ; 163 deg - True value: 0.29237170472273705
	dc.w -15749,-4516,4516,-15749   ; 164 deg - True value: 0.27563735581699966
	dc.w -15825,-4240,4240,-15825   ; 165 deg - True value: 0.258819045102521
	dc.w -15897,-3963,3963,-15897   ; 166 deg - True value: 0.24192189559966773
	dc.w -15964,-3685,3685,-15964   ; 167 deg - True value: 0.22495105434386478
	dc.w -16025,-3406,3406,-16025   ; 168 deg - True value: 0.20791169081775931
	dc.w -16082,-3126,3126,-16082   ; 169 deg - True value: 0.19080899537654497
	dc.w -16135,-2845,2845,-16135   ; 170 deg - True value: 0.17364817766693028
	dc.w -16182,-2563,2563,-16182   ; 171 deg - True value: 0.15643446504023098
	dc.w -16224,-2280,2280,-16224   ; 172 deg - True value: 0.13917310096006574
	dc.w -16261,-1996,1996,-16261   ; 173 deg - True value: 0.12186934340514755
	dc.w -16294,-1712,1712,-16294   ; 174 deg - True value: 0.10452846326765373
	dc.w -16321,-1427,1427,-16321   ; 175 deg - True value: 0.08715574274765864
	dc.w -16344,-1142,1142,-16344   ; 176 deg - True value: 0.06975647374412552
	dc.w -16361,-857,857,-16361   ; 177 deg - True value: 0.05233595624294381
	dc.w -16374,-571,571,-16374   ; 178 deg - True value: 0.0348994967025007
	dc.w -16381,-285,285,-16381   ; 179 deg - True value: 0.01745240643728344
	dc.w -16384,-2,2,-16384   ; 180 deg - True value: 1.2246467991473532e-16
	dc.w -16381,285,-285,-16381   ; 181 deg - True value: -0.017452406437283192
	dc.w -16374,571,-571,-16374   ; 182 deg - True value: -0.0348994967025009
	dc.w -16361,857,-857,-16361   ; 183 deg - True value: -0.052335956242943564
	dc.w -16344,1142,-1142,-16344   ; 184 deg - True value: -0.06975647374412483
	dc.w -16321,1427,-1427,-16321   ; 185 deg - True value: -0.08715574274765794
	dc.w -16294,1712,-1712,-16294   ; 186 deg - True value: -0.10452846326765305
	dc.w -16261,1996,-1996,-16261   ; 187 deg - True value: -0.12186934340514775
	dc.w -16224,2280,-2280,-16224   ; 188 deg - True value: -0.13917310096006552
	dc.w -16182,2563,-2563,-16182   ; 189 deg - True value: -0.15643446504023073
	dc.w -16135,2845,-2845,-16135   ; 190 deg - True value: -0.17364817766693047
	dc.w -16082,3126,-3126,-16082   ; 191 deg - True value: -0.19080899537654472
	dc.w -16025,3406,-3406,-16025   ; 192 deg - True value: -0.20791169081775907
	dc.w -15964,3685,-3685,-15964   ; 193 deg - True value: -0.22495105434386498
	dc.w -15897,3963,-3963,-15897   ; 194 deg - True value: -0.2419218955996675
	dc.w -15825,4240,-4240,-15825   ; 195 deg - True value: -0.25881904510252035
	dc.w -15749,4516,-4516,-15749   ; 196 deg - True value: -0.275637355816999
	dc.w -15668,4790,-4790,-15668   ; 197 deg - True value: -0.2923717047227364
	dc.w -15582,5062,-5062,-15582   ; 198 deg - True value: -0.30901699437494773
	dc.w -15491,5334,-5334,-15491   ; 199 deg - True value: -0.32556815445715676
	dc.w -15395,5603,-5603,-15395   ; 200 deg - True value: -0.34202014332566866
	dc.w -15295,5871,-5871,-15295   ; 201 deg - True value: -0.35836794954530043
	dc.w -15190,6137,-6137,-15190   ; 202 deg - True value: -0.374606593415912
	dc.w -15081,6401,-6401,-15081   ; 203 deg - True value: -0.39073112848927355
	dc.w -14967,6663,-6663,-14967   ; 204 deg - True value: -0.4067366430757998
	dc.w -14848,6924,-6924,-14848   ; 205 deg - True value: -0.4226182617406993
	dc.w -14725,7182,-7182,-14725   ; 206 deg - True value: -0.43837114678907707
	dc.w -14598,7438,-7438,-14598   ; 207 deg - True value: -0.45399049973954625
	dc.w -14466,7691,-7691,-14466   ; 208 deg - True value: -0.46947156278589086
	dc.w -14329,7943,-7943,-14329   ; 209 deg - True value: -0.48480962024633695
	dc.w -14188,8192,-8192,-14188   ; 210 deg - True value: -0.5000000000000001
	dc.w -14043,8438,-8438,-14043   ; 211 deg - True value: -0.5150380749100542
	dc.w -13894,8682,-8682,-13894   ; 212 deg - True value: -0.5299192642332048
	dc.w -13740,8923,-8923,-13740   ; 213 deg - True value: -0.5446390350150271
	dc.w -13582,9161,-9161,-13582   ; 214 deg - True value: -0.5591929034707467
	dc.w -13420,9397,-9397,-13420   ; 215 deg - True value: -0.5735764363510458
	dc.w -13254,9630,-9630,-13254   ; 216 deg - True value: -0.587785252292473
	dc.w -13084,9860,-9860,-13084   ; 217 deg - True value: -0.601815023152048
	dc.w -12910,10086,-10086,-12910   ; 218 deg - True value: -0.6156614753256578
	dc.w -12732,10310,-10310,-12732   ; 219 deg - True value: -0.6293203910498376
	dc.w -12550,10531,-10531,-12550   ; 220 deg - True value: -0.6427876096865393
	dc.w -12365,10748,-10748,-12365   ; 221 deg - True value: -0.6560590289905074
	dc.w -12175,10963,-10963,-12175   ; 222 deg - True value: -0.6691306063588582
	dc.w -11982,11173,-11173,-11982   ; 223 deg - True value: -0.6819983600624984
	dc.w -11785,11381,-11381,-11785   ; 224 deg - True value: -0.6946583704589974
	dc.w -11585,11585,-11585,-11585   ; 225 deg - True value: -0.7071067811865475
	dc.w -11381,11785,-11785,-11381   ; 226 deg - True value: -0.7193398003386509
	dc.w -11173,11982,-11982,-11173   ; 227 deg - True value: -0.7313537016191701
	dc.w -10963,12175,-12175,-10963   ; 228 deg - True value: -0.743144825477394
	dc.w -10748,12365,-12365,-10748   ; 229 deg - True value: -0.7547095802227717
	dc.w -10531,12550,-12550,-10531   ; 230 deg - True value: -0.7660444431189779
	dc.w -10310,12732,-12732,-10310   ; 231 deg - True value: -0.7771459614569711
	dc.w -10086,12910,-12910,-10086   ; 232 deg - True value: -0.7880107536067221
	dc.w -9860,13084,-13084,-9860   ; 233 deg - True value: -0.7986355100472928
	dc.w -9630,13254,-13254,-9630   ; 234 deg - True value: -0.8090169943749473
	dc.w -9397,13420,-13420,-9397   ; 235 deg - True value: -0.8191520442889916
	dc.w -9161,13582,-13582,-9161   ; 236 deg - True value: -0.8290375725550414
	dc.w -8923,13740,-13740,-8923   ; 237 deg - True value: -0.838670567945424
	dc.w -8682,13894,-13894,-8682   ; 238 deg - True value: -0.848048096156426
	dc.w -8438,14043,-14043,-8438   ; 239 deg - True value: -0.8571673007021121
	dc.w -8192,14188,-14188,-8192   ; 240 deg - True value: -0.8660254037844385
	dc.w -7943,14329,-14329,-7943   ; 241 deg - True value: -0.8746197071393959
	dc.w -7691,14466,-14466,-7691   ; 242 deg - True value: -0.882947592858927
	dc.w -7438,14598,-14598,-7438   ; 243 deg - True value: -0.8910065241883678
	dc.w -7182,14725,-14725,-7182   ; 244 deg - True value: -0.8987940462991668
	dc.w -6924,14848,-14848,-6924   ; 245 deg - True value: -0.9063077870366497
	dc.w -6663,14967,-14967,-6663   ; 246 deg - True value: -0.913545457642601
	dc.w -6401,15081,-15081,-6401   ; 247 deg - True value: -0.9205048534524403
	dc.w -6137,15190,-15190,-6137   ; 248 deg - True value: -0.9271838545667873
	dc.w -5871,15295,-15295,-5871   ; 249 deg - True value: -0.9335804264972016
	dc.w -5603,15395,-15395,-5603   ; 250 deg - True value: -0.9396926207859082
	dc.w -5334,15491,-15491,-5334   ; 251 deg - True value: -0.9455185755993168
	dc.w -5062,15582,-15582,-5062   ; 252 deg - True value: -0.9510565162951535
	dc.w -4790,15668,-15668,-4790   ; 253 deg - True value: -0.9563047559630353
	dc.w -4516,15749,-15749,-4516   ; 254 deg - True value: -0.9612616959383189
	dc.w -4240,15825,-15825,-4240   ; 255 deg - True value: -0.9659258262890683
	dc.w -3963,15897,-15897,-3963   ; 256 deg - True value: -0.9702957262759965
	dc.w -3685,15964,-15964,-3685   ; 257 deg - True value: -0.9743700647852351
	dc.w -3406,16025,-16025,-3406   ; 258 deg - True value: -0.9781476007338056
	dc.w -3126,16082,-16082,-3126   ; 259 deg - True value: -0.9816271834476639
	dc.w -2845,16135,-16135,-2845   ; 260 deg - True value: -0.984807753012208
	dc.w -2563,16182,-16182,-2563   ; 261 deg - True value: -0.9876883405951377
	dc.w -2280,16224,-16224,-2280   ; 262 deg - True value: -0.9902680687415704
	dc.w -1996,16261,-16261,-1996   ; 263 deg - True value: -0.9925461516413221
	dc.w -1712,16294,-16294,-1712   ; 264 deg - True value: -0.9945218953682734
	dc.w -1427,16321,-16321,-1427   ; 265 deg - True value: -0.9961946980917455
	dc.w -1142,16344,-16344,-1142   ; 266 deg - True value: -0.9975640502598242
	dc.w -857,16361,-16361,-857   ; 267 deg - True value: -0.9986295347545738
	dc.w -571,16374,-16374,-571   ; 268 deg - True value: -0.9993908270190957
	dc.w -285,16381,-16381,-285   ; 269 deg - True value: -0.9998476951563913
	dc.w -3,16384,-16384,-3   ; 270 deg - True value: -1
	dc.w 285,16381,-16381,285   ; 271 deg - True value: -0.9998476951563913
	dc.w 571,16374,-16374,571   ; 272 deg - True value: -0.9993908270190958
	dc.w 857,16361,-16361,857   ; 273 deg - True value: -0.9986295347545738
	dc.w 1142,16344,-16344,1142   ; 274 deg - True value: -0.9975640502598243
	dc.w 1427,16321,-16321,1427   ; 275 deg - True value: -0.9961946980917455
	dc.w 1712,16294,-16294,1712   ; 276 deg - True value: -0.9945218953682734
	dc.w 1996,16261,-16261,1996   ; 277 deg - True value: -0.992546151641322
	dc.w 2280,16224,-16224,2280   ; 278 deg - True value: -0.9902680687415704
	dc.w 2563,16182,-16182,2563   ; 279 deg - True value: -0.9876883405951378
	dc.w 2845,16135,-16135,2845   ; 280 deg - True value: -0.9848077530122081
	dc.w 3126,16082,-16082,3126   ; 281 deg - True value: -0.9816271834476641
	dc.w 3406,16025,-16025,3406   ; 282 deg - True value: -0.9781476007338058
	dc.w 3685,15964,-15964,3685   ; 283 deg - True value: -0.9743700647852352
	dc.w 3963,15897,-15897,3963   ; 284 deg - True value: -0.9702957262759966
	dc.w 4240,15825,-15825,4240   ; 285 deg - True value: -0.9659258262890682
	dc.w 4516,15749,-15749,4516   ; 286 deg - True value: -0.9612616959383188
	dc.w 4790,15668,-15668,4790   ; 287 deg - True value: -0.9563047559630354
	dc.w 5062,15582,-15582,5062   ; 288 deg - True value: -0.9510565162951536
	dc.w 5334,15491,-15491,5334   ; 289 deg - True value: -0.945518575599317
	dc.w 5603,15395,-15395,5603   ; 290 deg - True value: -0.9396926207859085
	dc.w 5871,15295,-15295,5871   ; 291 deg - True value: -0.9335804264972021
	dc.w 6137,15190,-15190,6137   ; 292 deg - True value: -0.9271838545667874
	dc.w 6401,15081,-15081,6401   ; 293 deg - True value: -0.9205048534524405
	dc.w 6663,14967,-14967,6663   ; 294 deg - True value: -0.9135454576426008
	dc.w 6924,14848,-14848,6924   ; 295 deg - True value: -0.9063077870366498
	dc.w 7182,14725,-14725,7182   ; 296 deg - True value: -0.898794046299167
	dc.w 7438,14598,-14598,7438   ; 297 deg - True value: -0.891006524188368
	dc.w 7691,14466,-14466,7691   ; 298 deg - True value: -0.8829475928589271
	dc.w 7943,14329,-14329,7943   ; 299 deg - True value: -0.8746197071393961
	dc.w 8192,14188,-14188,8192   ; 300 deg - True value: -0.8660254037844386
	dc.w 8438,14043,-14043,8438   ; 301 deg - True value: -0.8571673007021123
	dc.w 8682,13894,-13894,8682   ; 302 deg - True value: -0.8480480961564261
	dc.w 8923,13740,-13740,8923   ; 303 deg - True value: -0.8386705679454243
	dc.w 9161,13582,-13582,9161   ; 304 deg - True value: -0.8290375725550421
	dc.w 9397,13420,-13420,9397   ; 305 deg - True value: -0.8191520442889918
	dc.w 9630,13254,-13254,9630   ; 306 deg - True value: -0.8090169943749476
	dc.w 9860,13084,-13084,9860   ; 307 deg - True value: -0.798635510047293
	dc.w 10086,12910,-12910,10086   ; 308 deg - True value: -0.7880107536067218
	dc.w 10310,12732,-12732,10310   ; 309 deg - True value: -0.7771459614569708
	dc.w 10531,12550,-12550,10531   ; 310 deg - True value: -0.7660444431189781
	dc.w 10748,12365,-12365,10748   ; 311 deg - True value: -0.7547095802227721
	dc.w 10963,12175,-12175,10963   ; 312 deg - True value: -0.7431448254773946
	dc.w 11173,11982,-11982,11173   ; 313 deg - True value: -0.731353701619171
	dc.w 11381,11785,-11785,11381   ; 314 deg - True value: -0.7193398003386517
	dc.w 11585,11585,-11585,11585   ; 315 deg - True value: -0.7071067811865477
	dc.w 11785,11381,-11381,11785   ; 316 deg - True value: -0.6946583704589976
	dc.w 11982,11173,-11173,11982   ; 317 deg - True value: -0.6819983600624983
	dc.w 12175,10963,-10963,12175   ; 318 deg - True value: -0.6691306063588581
	dc.w 12365,10748,-10748,12365   ; 319 deg - True value: -0.6560590289905074
	dc.w 12550,10531,-10531,12550   ; 320 deg - True value: -0.6427876096865396
	dc.w 12732,10310,-10310,12732   ; 321 deg - True value: -0.6293203910498378
	dc.w 12910,10086,-10086,12910   ; 322 deg - True value: -0.6156614753256588
	dc.w 13084,9860,-9860,13084   ; 323 deg - True value: -0.6018150231520483
	dc.w 13254,9630,-9630,13254   ; 324 deg - True value: -0.5877852522924734
	dc.w 13420,9397,-9397,13420   ; 325 deg - True value: -0.5735764363510465
	dc.w 13582,9161,-9161,13582   ; 326 deg - True value: -0.5591929034707473
	dc.w 13740,8923,-8923,13740   ; 327 deg - True value: -0.544639035015027
	dc.w 13894,8682,-8682,13894   ; 328 deg - True value: -0.5299192642332058
	dc.w 14043,8438,-8438,14043   ; 329 deg - True value: -0.5150380749100545
	dc.w 14188,8192,-8192,14188   ; 330 deg - True value: -0.5000000000000004
	dc.w 14329,7943,-7943,14329   ; 331 deg - True value: -0.4848096202463369
	dc.w 14466,7691,-7691,14466   ; 332 deg - True value: -0.4694715627858908
	dc.w 14598,7438,-7438,14598   ; 333 deg - True value: -0.45399049973954697
	dc.w 14725,7182,-7182,14725   ; 334 deg - True value: -0.438371146789077
	dc.w 14848,6924,-6924,14848   ; 335 deg - True value: -0.4226182617407
	dc.w 14967,6663,-6663,14967   ; 336 deg - True value: -0.40673664307580015
	dc.w 15081,6401,-6401,15081   ; 337 deg - True value: -0.3907311284892747
	dc.w 15190,6137,-6137,15190   ; 338 deg - True value: -0.37460659341591235
	dc.w 15295,5871,-5871,15295   ; 339 deg - True value: -0.35836794954530077
	dc.w 15395,5603,-5603,15395   ; 340 deg - True value: -0.3420201433256686
	dc.w 15491,5334,-5334,15491   ; 341 deg - True value: -0.32556815445715753
	dc.w 15582,5062,-5062,15582   ; 342 deg - True value: -0.3090169943749476
	dc.w 15668,4790,-4790,15668   ; 343 deg - True value: -0.29237170472273627
	dc.w 15749,4516,-4516,15749   ; 344 deg - True value: -0.2756373558169998
	dc.w 15825,4240,-4240,15825   ; 345 deg - True value: -0.2588190451025207
	dc.w 15897,3963,-3963,15897   ; 346 deg - True value: -0.24192189559966787
	dc.w 15964,3685,-3685,15964   ; 347 deg - True value: -0.22495105434386534
	dc.w 16025,3406,-3406,16025   ; 348 deg - True value: -0.20791169081775987
	dc.w 16082,3126,-3126,16082   ; 349 deg - True value: -0.19080899537654467
	dc.w 16135,2845,-2845,16135   ; 350 deg - True value: -0.17364817766693127
	dc.w 16182,2563,-2563,16182   ; 351 deg - True value: -0.15643446504023112
	dc.w 16224,2280,-2280,16224   ; 352 deg - True value: -0.13917310096006588
	dc.w 16261,1996,-1996,16261   ; 353 deg - True value: -0.12186934340514811
	dc.w 16294,1712,-1712,16294   ; 354 deg - True value: -0.10452846326765342
	dc.w 16321,1427,-1427,16321   ; 355 deg - True value: -0.08715574274765832
	dc.w 16344,1142,-1142,16344   ; 356 deg - True value: -0.06975647374412476
	dc.w 16361,857,-857,16361   ; 357 deg - True value: -0.05233595624294437
	dc.w 16374,571,-571,16374   ; 358 deg - True value: -0.034899496702500823
	dc.w 16381,285,-285,16381   ; 359 deg - True value: -0.01745240643728445


TRIG_TABLE_256:
	dc.w 256,0,0,256   ; 0 deg - True value: 0
	dc.w 255,-4,4,255   ; 1 deg - True value: 0.01745240643728351
	dc.w 255,-8,8,255   ; 2 deg - True value: 0.03489949670250097
	dc.w 255,-13,13,255   ; 3 deg - True value: 0.05233595624294383
	dc.w 255,-17,17,255   ; 4 deg - True value: 0.0697564737441253
	dc.w 255,-22,22,255   ; 5 deg - True value: 0.08715574274765817
	dc.w 254,-26,26,254   ; 6 deg - True value: 0.10452846326765346
	dc.w 254,-31,31,254   ; 7 deg - True value: 0.12186934340514748
	dc.w 253,-35,35,253   ; 8 deg - True value: 0.13917310096006544
	dc.w 252,-40,40,252   ; 9 deg - True value: 0.15643446504023087
	dc.w 252,-44,44,252   ; 10 deg - True value: 0.17364817766693033
	dc.w 251,-48,48,251   ; 11 deg - True value: 0.1908089953765448
	dc.w 250,-53,53,250   ; 12 deg - True value: 0.20791169081775931
	dc.w 249,-57,57,249   ; 13 deg - True value: 0.224951054343865
	dc.w 248,-61,61,248   ; 14 deg - True value: 0.24192189559966773
	dc.w 247,-66,66,247   ; 15 deg - True value: 0.25881904510252074
	dc.w 246,-70,70,246   ; 16 deg - True value: 0.27563735581699916
	dc.w 244,-74,74,244   ; 17 deg - True value: 0.29237170472273677
	dc.w 243,-79,79,243   ; 18 deg - True value: 0.3090169943749474
	dc.w 242,-83,83,242   ; 19 deg - True value: 0.32556815445715664
	dc.w 240,-87,87,240   ; 20 deg - True value: 0.3420201433256687
	dc.w 238,-91,91,238   ; 21 deg - True value: 0.35836794954530027
	dc.w 237,-95,95,237   ; 22 deg - True value: 0.374606593415912
	dc.w 235,-100,100,235   ; 23 deg - True value: 0.3907311284892737
	dc.w 233,-104,104,233   ; 24 deg - True value: 0.40673664307580015
	dc.w 232,-108,108,232   ; 25 deg - True value: 0.42261826174069944
	dc.w 230,-112,112,230   ; 26 deg - True value: 0.4383711467890774
	dc.w 228,-116,116,228   ; 27 deg - True value: 0.45399049973954675
	dc.w 226,-120,120,226   ; 28 deg - True value: 0.4694715627858908
	dc.w 223,-124,124,223   ; 29 deg - True value: 0.48480962024633706
	dc.w 221,-127,127,221   ; 30 deg - True value: 0.49999999999999994
	dc.w 219,-131,131,219   ; 31 deg - True value: 0.5150380749100542
	dc.w 217,-135,135,217   ; 32 deg - True value: 0.5299192642332049
	dc.w 214,-139,139,214   ; 33 deg - True value: 0.5446390350150271
	dc.w 212,-143,143,212   ; 34 deg - True value: 0.5591929034707469
	dc.w 209,-146,146,209   ; 35 deg - True value: 0.573576436351046
	dc.w 207,-150,150,207   ; 36 deg - True value: 0.5877852522924731
	dc.w 204,-154,154,204   ; 37 deg - True value: 0.6018150231520483
	dc.w 201,-157,157,201   ; 38 deg - True value: 0.6156614753256582
	dc.w 198,-161,161,198   ; 39 deg - True value: 0.6293203910498374
	dc.w 196,-164,164,196   ; 40 deg - True value: 0.6427876096865393
	dc.w 193,-167,167,193   ; 41 deg - True value: 0.6560590289905072
	dc.w 190,-171,171,190   ; 42 deg - True value: 0.6691306063588582
	dc.w 187,-174,174,187   ; 43 deg - True value: 0.6819983600624985
	dc.w 184,-177,177,184   ; 44 deg - True value: 0.6946583704589973
	dc.w 181,-181,181,181   ; 45 deg - True value: 0.7071067811865475
	dc.w 177,-184,184,177   ; 46 deg - True value: 0.7193398003386511
	dc.w 174,-187,187,174   ; 47 deg - True value: 0.7313537016191705
	dc.w 171,-190,190,171   ; 48 deg - True value: 0.7431448254773942
	dc.w 167,-193,193,167   ; 49 deg - True value: 0.754709580222772
	dc.w 164,-196,196,164   ; 50 deg - True value: 0.766044443118978
	dc.w 161,-198,198,161   ; 51 deg - True value: 0.7771459614569708
	dc.w 157,-201,201,157   ; 52 deg - True value: 0.788010753606722
	dc.w 154,-204,204,154   ; 53 deg - True value: 0.7986355100472928
	dc.w 150,-207,207,150   ; 54 deg - True value: 0.8090169943749475
	dc.w 146,-209,209,146   ; 55 deg - True value: 0.8191520442889918
	dc.w 143,-212,212,143   ; 56 deg - True value: 0.8290375725550417
	dc.w 139,-214,214,139   ; 57 deg - True value: 0.8386705679454239
	dc.w 135,-217,217,135   ; 58 deg - True value: 0.8480480961564261
	dc.w 131,-219,219,131   ; 59 deg - True value: 0.8571673007021122
	dc.w 128,-221,221,128   ; 60 deg - True value: 0.8660254037844386
	dc.w 124,-223,223,124   ; 61 deg - True value: 0.8746197071393957
	dc.w 120,-226,226,120   ; 62 deg - True value: 0.8829475928589269
	dc.w 116,-228,228,116   ; 63 deg - True value: 0.8910065241883678
	dc.w 112,-230,230,112   ; 64 deg - True value: 0.898794046299167
	dc.w 108,-232,232,108   ; 65 deg - True value: 0.9063077870366499
	dc.w 104,-233,233,104   ; 66 deg - True value: 0.9135454576426009
	dc.w 100,-235,235,100   ; 67 deg - True value: 0.9205048534524403
	dc.w 95,-237,237,95   ; 68 deg - True value: 0.9271838545667874
	dc.w 91,-238,238,91   ; 69 deg - True value: 0.9335804264972017
	dc.w 87,-240,240,87   ; 70 deg - True value: 0.9396926207859083
	dc.w 83,-242,242,83   ; 71 deg - True value: 0.9455185755993167
	dc.w 79,-243,243,79   ; 72 deg - True value: 0.9510565162951535
	dc.w 74,-244,244,74   ; 73 deg - True value: 0.9563047559630354
	dc.w 70,-246,246,70   ; 74 deg - True value: 0.9612616959383189
	dc.w 66,-247,247,66   ; 75 deg - True value: 0.9659258262890683
	dc.w 61,-248,248,61   ; 76 deg - True value: 0.9702957262759965
	dc.w 57,-249,249,57   ; 77 deg - True value: 0.9743700647852352
	dc.w 53,-250,250,53   ; 78 deg - True value: 0.9781476007338056
	dc.w 48,-251,251,48   ; 79 deg - True value: 0.981627183447664
	dc.w 44,-252,252,44   ; 80 deg - True value: 0.984807753012208
	dc.w 40,-252,252,40   ; 81 deg - True value: 0.9876883405951378
	dc.w 35,-253,253,35   ; 82 deg - True value: 0.9902680687415703
	dc.w 31,-254,254,31   ; 83 deg - True value: 0.992546151641322
	dc.w 26,-254,254,26   ; 84 deg - True value: 0.9945218953682733
	dc.w 22,-255,255,22   ; 85 deg - True value: 0.9961946980917455
	dc.w 17,-255,255,17   ; 86 deg - True value: 0.9975640502598242
	dc.w 13,-255,255,13   ; 87 deg - True value: 0.9986295347545738
	dc.w 8,-255,255,8   ; 88 deg - True value: 0.9993908270190958
	dc.w 4,-255,255,4   ; 89 deg - True value: 0.9998476951563913
	dc.w 1,-256,256,1   ; 90 deg - True value: 1
	dc.w -4,-255,255,-4   ; 91 deg - True value: 0.9998476951563913
	dc.w -8,-255,255,-8   ; 92 deg - True value: 0.9993908270190958
	dc.w -13,-255,255,-13   ; 93 deg - True value: 0.9986295347545738
	dc.w -17,-255,255,-17   ; 94 deg - True value: 0.9975640502598242
	dc.w -22,-255,255,-22   ; 95 deg - True value: 0.9961946980917455
	dc.w -26,-254,254,-26   ; 96 deg - True value: 0.9945218953682734
	dc.w -31,-254,254,-31   ; 97 deg - True value: 0.9925461516413221
	dc.w -35,-253,253,-35   ; 98 deg - True value: 0.9902680687415704
	dc.w -40,-252,252,-40   ; 99 deg - True value: 0.9876883405951377
	dc.w -44,-252,252,-44   ; 100 deg - True value: 0.984807753012208
	dc.w -48,-251,251,-48   ; 101 deg - True value: 0.981627183447664
	dc.w -53,-250,250,-53   ; 102 deg - True value: 0.9781476007338057
	dc.w -57,-249,249,-57   ; 103 deg - True value: 0.9743700647852352
	dc.w -61,-248,248,-61   ; 104 deg - True value: 0.9702957262759965
	dc.w -66,-247,247,-66   ; 105 deg - True value: 0.9659258262890683
	dc.w -70,-246,246,-70   ; 106 deg - True value: 0.9612616959383189
	dc.w -74,-244,244,-74   ; 107 deg - True value: 0.9563047559630355
	dc.w -79,-243,243,-79   ; 108 deg - True value: 0.9510565162951536
	dc.w -83,-242,242,-83   ; 109 deg - True value: 0.9455185755993168
	dc.w -87,-240,240,-87   ; 110 deg - True value: 0.9396926207859084
	dc.w -91,-238,238,-91   ; 111 deg - True value: 0.9335804264972017
	dc.w -95,-237,237,-95   ; 112 deg - True value: 0.9271838545667874
	dc.w -100,-235,235,-100   ; 113 deg - True value: 0.9205048534524404
	dc.w -104,-233,233,-104   ; 114 deg - True value: 0.913545457642601
	dc.w -108,-232,232,-108   ; 115 deg - True value: 0.90630778703665
	dc.w -112,-230,230,-112   ; 116 deg - True value: 0.8987940462991669
	dc.w -116,-228,228,-116   ; 117 deg - True value: 0.8910065241883679
	dc.w -120,-226,226,-120   ; 118 deg - True value: 0.8829475928589271
	dc.w -124,-223,223,-124   ; 119 deg - True value: 0.8746197071393959
	dc.w -127,-221,221,-127   ; 120 deg - True value: 0.8660254037844387
	dc.w -131,-219,219,-131   ; 121 deg - True value: 0.8571673007021123
	dc.w -135,-217,217,-135   ; 122 deg - True value: 0.8480480961564261
	dc.w -139,-214,214,-139   ; 123 deg - True value: 0.838670567945424
	dc.w -143,-212,212,-143   ; 124 deg - True value: 0.8290375725550417
	dc.w -146,-209,209,-146   ; 125 deg - True value: 0.819152044288992
	dc.w -150,-207,207,-150   ; 126 deg - True value: 0.8090169943749475
	dc.w -154,-204,204,-154   ; 127 deg - True value: 0.7986355100472927
	dc.w -157,-201,201,-157   ; 128 deg - True value: 0.788010753606722
	dc.w -161,-198,198,-161   ; 129 deg - True value: 0.777145961456971
	dc.w -164,-196,196,-164   ; 130 deg - True value: 0.766044443118978
	dc.w -167,-193,193,-167   ; 131 deg - True value: 0.7547095802227718
	dc.w -171,-190,190,-171   ; 132 deg - True value: 0.7431448254773942
	dc.w -174,-187,187,-174   ; 133 deg - True value: 0.7313537016191706
	dc.w -177,-184,184,-177   ; 134 deg - True value: 0.7193398003386514
	dc.w -181,-181,181,-181   ; 135 deg - True value: 0.7071067811865476
	dc.w -184,-177,177,-184   ; 136 deg - True value: 0.6946583704589971
	dc.w -187,-174,174,-187   ; 137 deg - True value: 0.6819983600624986
	dc.w -190,-171,171,-190   ; 138 deg - True value: 0.6691306063588583
	dc.w -193,-167,167,-193   ; 139 deg - True value: 0.6560590289905073
	dc.w -196,-164,164,-196   ; 140 deg - True value: 0.6427876096865395
	dc.w -198,-161,161,-198   ; 141 deg - True value: 0.6293203910498377
	dc.w -201,-157,157,-201   ; 142 deg - True value: 0.6156614753256584
	dc.w -204,-154,154,-204   ; 143 deg - True value: 0.6018150231520482
	dc.w -207,-150,150,-207   ; 144 deg - True value: 0.5877852522924732
	dc.w -209,-146,146,-209   ; 145 deg - True value: 0.5735764363510464
	dc.w -212,-143,143,-212   ; 146 deg - True value: 0.5591929034707469
	dc.w -214,-139,139,-214   ; 147 deg - True value: 0.5446390350150269
	dc.w -217,-135,135,-217   ; 148 deg - True value: 0.5299192642332049
	dc.w -219,-131,131,-219   ; 149 deg - True value: 0.5150380749100544
	dc.w -221,-127,127,-221   ; 150 deg - True value: 0.49999999999999994
	dc.w -223,-124,124,-223   ; 151 deg - True value: 0.48480962024633717
	dc.w -226,-120,120,-226   ; 152 deg - True value: 0.4694715627858911
	dc.w -228,-116,116,-228   ; 153 deg - True value: 0.45399049973954686
	dc.w -230,-112,112,-230   ; 154 deg - True value: 0.4383711467890773
	dc.w -232,-108,108,-232   ; 155 deg - True value: 0.4226182617406995
	dc.w -233,-104,104,-233   ; 156 deg - True value: 0.40673664307580043
	dc.w -235,-100,100,-235   ; 157 deg - True value: 0.39073112848927416
	dc.w -237,-95,95,-237   ; 158 deg - True value: 0.37460659341591224
	dc.w -238,-91,91,-238   ; 159 deg - True value: 0.3583679495453002
	dc.w -240,-87,87,-240   ; 160 deg - True value: 0.3420201433256689
	dc.w -242,-83,83,-242   ; 161 deg - True value: 0.325568154457157
	dc.w -243,-79,79,-243   ; 162 deg - True value: 0.3090169943749475
	dc.w -244,-74,74,-244   ; 163 deg - True value: 0.29237170472273705
	dc.w -246,-70,70,-246   ; 164 deg - True value: 0.27563735581699966
	dc.w -247,-66,66,-247   ; 165 deg - True value: 0.258819045102521
	dc.w -248,-61,61,-248   ; 166 deg - True value: 0.24192189559966773
	dc.w -249,-57,57,-249   ; 167 deg - True value: 0.22495105434386478
	dc.w -250,-53,53,-250   ; 168 deg - True value: 0.20791169081775931
	dc.w -251,-48,48,-251   ; 169 deg - True value: 0.19080899537654497
	dc.w -252,-44,44,-252   ; 170 deg - True value: 0.17364817766693028
	dc.w -252,-40,40,-252   ; 171 deg - True value: 0.15643446504023098
	dc.w -253,-35,35,-253   ; 172 deg - True value: 0.13917310096006574
	dc.w -254,-31,31,-254   ; 173 deg - True value: 0.12186934340514755
	dc.w -254,-26,26,-254   ; 174 deg - True value: 0.10452846326765373
	dc.w -255,-22,22,-255   ; 175 deg - True value: 0.08715574274765864
	dc.w -255,-17,17,-255   ; 176 deg - True value: 0.06975647374412552
	dc.w -255,-13,13,-255   ; 177 deg - True value: 0.05233595624294381
	dc.w -255,-8,8,-255   ; 178 deg - True value: 0.0348994967025007
	dc.w -255,-4,4,-255   ; 179 deg - True value: 0.01745240643728344
	dc.w -256,-3,3,-256   ; 180 deg - True value: 1.2246467991473532e-16
	dc.w -255,4,-4,-255   ; 181 deg - True value: -0.017452406437283192
	dc.w -255,8,-8,-255   ; 182 deg - True value: -0.0348994967025009
	dc.w -255,13,-13,-255   ; 183 deg - True value: -0.052335956242943564
	dc.w -255,17,-17,-255   ; 184 deg - True value: -0.06975647374412483
	dc.w -255,22,-22,-255   ; 185 deg - True value: -0.08715574274765794
	dc.w -254,26,-26,-254   ; 186 deg - True value: -0.10452846326765305
	dc.w -254,31,-31,-254   ; 187 deg - True value: -0.12186934340514775
	dc.w -253,35,-35,-253   ; 188 deg - True value: -0.13917310096006552
	dc.w -252,40,-40,-252   ; 189 deg - True value: -0.15643446504023073
	dc.w -252,44,-44,-252   ; 190 deg - True value: -0.17364817766693047
	dc.w -251,48,-48,-251   ; 191 deg - True value: -0.19080899537654472
	dc.w -250,53,-53,-250   ; 192 deg - True value: -0.20791169081775907
	dc.w -249,57,-57,-249   ; 193 deg - True value: -0.22495105434386498
	dc.w -248,61,-61,-248   ; 194 deg - True value: -0.2419218955996675
	dc.w -247,66,-66,-247   ; 195 deg - True value: -0.25881904510252035
	dc.w -246,70,-70,-246   ; 196 deg - True value: -0.275637355816999
	dc.w -244,74,-74,-244   ; 197 deg - True value: -0.2923717047227364
	dc.w -243,79,-79,-243   ; 198 deg - True value: -0.30901699437494773
	dc.w -242,83,-83,-242   ; 199 deg - True value: -0.32556815445715676
	dc.w -240,87,-87,-240   ; 200 deg - True value: -0.34202014332566866
	dc.w -238,91,-91,-238   ; 201 deg - True value: -0.35836794954530043
	dc.w -237,95,-95,-237   ; 202 deg - True value: -0.374606593415912
	dc.w -235,100,-100,-235   ; 203 deg - True value: -0.39073112848927355
	dc.w -233,104,-104,-233   ; 204 deg - True value: -0.4067366430757998
	dc.w -232,108,-108,-232   ; 205 deg - True value: -0.4226182617406993
	dc.w -230,112,-112,-230   ; 206 deg - True value: -0.43837114678907707
	dc.w -228,116,-116,-228   ; 207 deg - True value: -0.45399049973954625
	dc.w -226,120,-120,-226   ; 208 deg - True value: -0.46947156278589086
	dc.w -223,124,-124,-223   ; 209 deg - True value: -0.48480962024633695
	dc.w -221,128,-128,-221   ; 210 deg - True value: -0.5000000000000001
	dc.w -219,131,-131,-219   ; 211 deg - True value: -0.5150380749100542
	dc.w -217,135,-135,-217   ; 212 deg - True value: -0.5299192642332048
	dc.w -214,139,-139,-214   ; 213 deg - True value: -0.5446390350150271
	dc.w -212,143,-143,-212   ; 214 deg - True value: -0.5591929034707467
	dc.w -209,146,-146,-209   ; 215 deg - True value: -0.5735764363510458
	dc.w -207,150,-150,-207   ; 216 deg - True value: -0.587785252292473
	dc.w -204,154,-154,-204   ; 217 deg - True value: -0.601815023152048
	dc.w -201,157,-157,-201   ; 218 deg - True value: -0.6156614753256578
	dc.w -198,161,-161,-198   ; 219 deg - True value: -0.6293203910498376
	dc.w -196,164,-164,-196   ; 220 deg - True value: -0.6427876096865393
	dc.w -193,167,-167,-193   ; 221 deg - True value: -0.6560590289905074
	dc.w -190,171,-171,-190   ; 222 deg - True value: -0.6691306063588582
	dc.w -187,174,-174,-187   ; 223 deg - True value: -0.6819983600624984
	dc.w -184,177,-177,-184   ; 224 deg - True value: -0.6946583704589974
	dc.w -181,181,-181,-181   ; 225 deg - True value: -0.7071067811865475
	dc.w -177,184,-184,-177   ; 226 deg - True value: -0.7193398003386509
	dc.w -174,187,-187,-174   ; 227 deg - True value: -0.7313537016191701
	dc.w -171,190,-190,-171   ; 228 deg - True value: -0.743144825477394
	dc.w -167,193,-193,-167   ; 229 deg - True value: -0.7547095802227717
	dc.w -164,196,-196,-164   ; 230 deg - True value: -0.7660444431189779
	dc.w -161,198,-198,-161   ; 231 deg - True value: -0.7771459614569711
	dc.w -157,201,-201,-157   ; 232 deg - True value: -0.7880107536067221
	dc.w -154,204,-204,-154   ; 233 deg - True value: -0.7986355100472928
	dc.w -150,207,-207,-150   ; 234 deg - True value: -0.8090169943749473
	dc.w -146,209,-209,-146   ; 235 deg - True value: -0.8191520442889916
	dc.w -143,212,-212,-143   ; 236 deg - True value: -0.8290375725550414
	dc.w -139,214,-214,-139   ; 237 deg - True value: -0.838670567945424
	dc.w -135,217,-217,-135   ; 238 deg - True value: -0.848048096156426
	dc.w -131,219,-219,-131   ; 239 deg - True value: -0.8571673007021121
	dc.w -128,221,-221,-128   ; 240 deg - True value: -0.8660254037844385
	dc.w -124,223,-223,-124   ; 241 deg - True value: -0.8746197071393959
	dc.w -120,226,-226,-120   ; 242 deg - True value: -0.882947592858927
	dc.w -116,228,-228,-116   ; 243 deg - True value: -0.8910065241883678
	dc.w -112,230,-230,-112   ; 244 deg - True value: -0.8987940462991668
	dc.w -108,232,-232,-108   ; 245 deg - True value: -0.9063077870366497
	dc.w -104,233,-233,-104   ; 246 deg - True value: -0.913545457642601
	dc.w -100,235,-235,-100   ; 247 deg - True value: -0.9205048534524403
	dc.w -95,237,-237,-95   ; 248 deg - True value: -0.9271838545667873
	dc.w -91,238,-238,-91   ; 249 deg - True value: -0.9335804264972016
	dc.w -87,240,-240,-87   ; 250 deg - True value: -0.9396926207859082
	dc.w -83,242,-242,-83   ; 251 deg - True value: -0.9455185755993168
	dc.w -79,243,-243,-79   ; 252 deg - True value: -0.9510565162951535
	dc.w -74,244,-244,-74   ; 253 deg - True value: -0.9563047559630353
	dc.w -70,246,-246,-70   ; 254 deg - True value: -0.9612616959383189
	dc.w -66,247,-247,-66   ; 255 deg - True value: -0.9659258262890683
	dc.w -61,248,-248,-61   ; 256 deg - True value: -0.9702957262759965
	dc.w -57,249,-249,-57   ; 257 deg - True value: -0.9743700647852351
	dc.w -53,250,-250,-53   ; 258 deg - True value: -0.9781476007338056
	dc.w -48,251,-251,-48   ; 259 deg - True value: -0.9816271834476639
	dc.w -44,252,-252,-44   ; 260 deg - True value: -0.984807753012208
	dc.w -40,252,-252,-40   ; 261 deg - True value: -0.9876883405951377
	dc.w -35,253,-253,-35   ; 262 deg - True value: -0.9902680687415704
	dc.w -31,254,-254,-31   ; 263 deg - True value: -0.9925461516413221
	dc.w -26,254,-254,-26   ; 264 deg - True value: -0.9945218953682734
	dc.w -22,255,-255,-22   ; 265 deg - True value: -0.9961946980917455
	dc.w -17,255,-255,-17   ; 266 deg - True value: -0.9975640502598242
	dc.w -13,255,-255,-13   ; 267 deg - True value: -0.9986295347545738
	dc.w -8,255,-255,-8   ; 268 deg - True value: -0.9993908270190957
	dc.w -4,255,-255,-4   ; 269 deg - True value: -0.9998476951563913
	dc.w -4,256,-256,-4   ; 270 deg - True value: -1
	dc.w 4,255,-255,4   ; 271 deg - True value: -0.9998476951563913
	dc.w 8,255,-255,8   ; 272 deg - True value: -0.9993908270190958
	dc.w 13,255,-255,13   ; 273 deg - True value: -0.9986295347545738
	dc.w 17,255,-255,17   ; 274 deg - True value: -0.9975640502598243
	dc.w 22,255,-255,22   ; 275 deg - True value: -0.9961946980917455
	dc.w 26,254,-254,26   ; 276 deg - True value: -0.9945218953682734
	dc.w 31,254,-254,31   ; 277 deg - True value: -0.992546151641322
	dc.w 35,253,-253,35   ; 278 deg - True value: -0.9902680687415704
	dc.w 40,252,-252,40   ; 279 deg - True value: -0.9876883405951378
	dc.w 44,252,-252,44   ; 280 deg - True value: -0.9848077530122081
	dc.w 48,251,-251,48   ; 281 deg - True value: -0.9816271834476641
	dc.w 53,250,-250,53   ; 282 deg - True value: -0.9781476007338058
	dc.w 57,249,-249,57   ; 283 deg - True value: -0.9743700647852352
	dc.w 61,248,-248,61   ; 284 deg - True value: -0.9702957262759966
	dc.w 66,247,-247,66   ; 285 deg - True value: -0.9659258262890682
	dc.w 70,246,-246,70   ; 286 deg - True value: -0.9612616959383188
	dc.w 74,244,-244,74   ; 287 deg - True value: -0.9563047559630354
	dc.w 79,243,-243,79   ; 288 deg - True value: -0.9510565162951536
	dc.w 83,242,-242,83   ; 289 deg - True value: -0.945518575599317
	dc.w 87,240,-240,87   ; 290 deg - True value: -0.9396926207859085
	dc.w 91,238,-238,91   ; 291 deg - True value: -0.9335804264972021
	dc.w 95,237,-237,95   ; 292 deg - True value: -0.9271838545667874
	dc.w 100,235,-235,100   ; 293 deg - True value: -0.9205048534524405
	dc.w 104,233,-233,104   ; 294 deg - True value: -0.9135454576426008
	dc.w 108,232,-232,108   ; 295 deg - True value: -0.9063077870366498
	dc.w 112,230,-230,112   ; 296 deg - True value: -0.898794046299167
	dc.w 116,228,-228,116   ; 297 deg - True value: -0.891006524188368
	dc.w 120,226,-226,120   ; 298 deg - True value: -0.8829475928589271
	dc.w 124,223,-223,124   ; 299 deg - True value: -0.8746197071393961
	dc.w 128,221,-221,128   ; 300 deg - True value: -0.8660254037844386
	dc.w 131,219,-219,131   ; 301 deg - True value: -0.8571673007021123
	dc.w 135,217,-217,135   ; 302 deg - True value: -0.8480480961564261
	dc.w 139,214,-214,139   ; 303 deg - True value: -0.8386705679454243
	dc.w 143,212,-212,143   ; 304 deg - True value: -0.8290375725550421
	dc.w 146,209,-209,146   ; 305 deg - True value: -0.8191520442889918
	dc.w 150,207,-207,150   ; 306 deg - True value: -0.8090169943749476
	dc.w 154,204,-204,154   ; 307 deg - True value: -0.798635510047293
	dc.w 157,201,-201,157   ; 308 deg - True value: -0.7880107536067218
	dc.w 161,198,-198,161   ; 309 deg - True value: -0.7771459614569708
	dc.w 164,196,-196,164   ; 310 deg - True value: -0.7660444431189781
	dc.w 167,193,-193,167   ; 311 deg - True value: -0.7547095802227721
	dc.w 171,190,-190,171   ; 312 deg - True value: -0.7431448254773946
	dc.w 174,187,-187,174   ; 313 deg - True value: -0.731353701619171
	dc.w 177,184,-184,177   ; 314 deg - True value: -0.7193398003386517
	dc.w 181,181,-181,181   ; 315 deg - True value: -0.7071067811865477
	dc.w 184,177,-177,184   ; 316 deg - True value: -0.6946583704589976
	dc.w 187,174,-174,187   ; 317 deg - True value: -0.6819983600624983
	dc.w 190,171,-171,190   ; 318 deg - True value: -0.6691306063588581
	dc.w 193,167,-167,193   ; 319 deg - True value: -0.6560590289905074
	dc.w 196,164,-164,196   ; 320 deg - True value: -0.6427876096865396
	dc.w 198,161,-161,198   ; 321 deg - True value: -0.6293203910498378
	dc.w 201,157,-157,201   ; 322 deg - True value: -0.6156614753256588
	dc.w 204,154,-154,204   ; 323 deg - True value: -0.6018150231520483
	dc.w 207,150,-150,207   ; 324 deg - True value: -0.5877852522924734
	dc.w 209,146,-146,209   ; 325 deg - True value: -0.5735764363510465
	dc.w 212,143,-143,212   ; 326 deg - True value: -0.5591929034707473
	dc.w 214,139,-139,214   ; 327 deg - True value: -0.544639035015027
	dc.w 217,135,-135,217   ; 328 deg - True value: -0.5299192642332058
	dc.w 219,131,-131,219   ; 329 deg - True value: -0.5150380749100545
	dc.w 221,128,-128,221   ; 330 deg - True value: -0.5000000000000004
	dc.w 223,124,-124,223   ; 331 deg - True value: -0.4848096202463369
	dc.w 226,120,-120,226   ; 332 deg - True value: -0.4694715627858908
	dc.w 228,116,-116,228   ; 333 deg - True value: -0.45399049973954697
	dc.w 230,112,-112,230   ; 334 deg - True value: -0.438371146789077
	dc.w 232,108,-108,232   ; 335 deg - True value: -0.4226182617407
	dc.w 233,104,-104,233   ; 336 deg - True value: -0.40673664307580015
	dc.w 235,100,-100,235   ; 337 deg - True value: -0.3907311284892747
	dc.w 237,95,-95,237   ; 338 deg - True value: -0.37460659341591235
	dc.w 238,91,-91,238   ; 339 deg - True value: -0.35836794954530077
	dc.w 240,87,-87,240   ; 340 deg - True value: -0.3420201433256686
	dc.w 242,83,-83,242   ; 341 deg - True value: -0.32556815445715753
	dc.w 243,79,-79,243   ; 342 deg - True value: -0.3090169943749476
	dc.w 244,74,-74,244   ; 343 deg - True value: -0.29237170472273627
	dc.w 246,70,-70,246   ; 344 deg - True value: -0.2756373558169998
	dc.w 247,66,-66,247   ; 345 deg - True value: -0.2588190451025207
	dc.w 248,61,-61,248   ; 346 deg - True value: -0.24192189559966787
	dc.w 249,57,-57,249   ; 347 deg - True value: -0.22495105434386534
	dc.w 250,53,-53,250   ; 348 deg - True value: -0.20791169081775987
	dc.w 251,48,-48,251   ; 349 deg - True value: -0.19080899537654467
	dc.w 252,44,-44,252   ; 350 deg - True value: -0.17364817766693127
	dc.w 252,40,-40,252   ; 351 deg - True value: -0.15643446504023112
	dc.w 253,35,-35,253   ; 352 deg - True value: -0.13917310096006588
	dc.w 254,31,-31,254   ; 353 deg - True value: -0.12186934340514811
	dc.w 254,26,-26,254   ; 354 deg - True value: -0.10452846326765342
	dc.w 255,22,-22,255   ; 355 deg - True value: -0.08715574274765832
	dc.w 255,17,-17,255   ; 356 deg - True value: -0.06975647374412476
	dc.w 255,13,-13,255   ; 357 deg - True value: -0.05233595624294437
	dc.w 255,8,-8,255   ; 358 deg - True value: -0.034899496702500823
	dc.w 255,4,-4,255   ; 359 deg - True value: -0.01745240643728445

TRIG_TABLE_128:
	dc.w 128,0,0,128   ; 0 deg - True value: 0
	dc.w 127,-2,2,127   ; 1 deg - True value: 0.01745240643728351
	dc.w 127,-4,4,127   ; 2 deg - True value: 0.03489949670250097
	dc.w 127,-6,6,127   ; 3 deg - True value: 0.05233595624294383
	dc.w 127,-8,8,127   ; 4 deg - True value: 0.0697564737441253
	dc.w 127,-11,11,127   ; 5 deg - True value: 0.08715574274765817
	dc.w 127,-13,13,127   ; 6 deg - True value: 0.10452846326765346
	dc.w 127,-15,15,127   ; 7 deg - True value: 0.12186934340514748
	dc.w 126,-17,17,126   ; 8 deg - True value: 0.13917310096006544
	dc.w 126,-20,20,126   ; 9 deg - True value: 0.15643446504023087
	dc.w 126,-22,22,126   ; 10 deg - True value: 0.17364817766693033
	dc.w 125,-24,24,125   ; 11 deg - True value: 0.1908089953765448
	dc.w 125,-26,26,125   ; 12 deg - True value: 0.20791169081775931
	dc.w 124,-28,28,124   ; 13 deg - True value: 0.224951054343865
	dc.w 124,-30,30,124   ; 14 deg - True value: 0.24192189559966773
	dc.w 123,-33,33,123   ; 15 deg - True value: 0.25881904510252074
	dc.w 123,-35,35,123   ; 16 deg - True value: 0.27563735581699916
	dc.w 122,-37,37,122   ; 17 deg - True value: 0.29237170472273677
	dc.w 121,-39,39,121   ; 18 deg - True value: 0.3090169943749474
	dc.w 121,-41,41,121   ; 19 deg - True value: 0.32556815445715664
	dc.w 120,-43,43,120   ; 20 deg - True value: 0.3420201433256687
	dc.w 119,-45,45,119   ; 21 deg - True value: 0.35836794954530027
	dc.w 118,-47,47,118   ; 22 deg - True value: 0.374606593415912
	dc.w 117,-50,50,117   ; 23 deg - True value: 0.3907311284892737
	dc.w 116,-52,52,116   ; 24 deg - True value: 0.40673664307580015
	dc.w 116,-54,54,116   ; 25 deg - True value: 0.42261826174069944
	dc.w 115,-56,56,115   ; 26 deg - True value: 0.4383711467890774
	dc.w 114,-58,58,114   ; 27 deg - True value: 0.45399049973954675
	dc.w 113,-60,60,113   ; 28 deg - True value: 0.4694715627858908
	dc.w 111,-62,62,111   ; 29 deg - True value: 0.48480962024633706
	dc.w 110,-63,63,110   ; 30 deg - True value: 0.49999999999999994
	dc.w 109,-65,65,109   ; 31 deg - True value: 0.5150380749100542
	dc.w 108,-67,67,108   ; 32 deg - True value: 0.5299192642332049
	dc.w 107,-69,69,107   ; 33 deg - True value: 0.5446390350150271
	dc.w 106,-71,71,106   ; 34 deg - True value: 0.5591929034707469
	dc.w 104,-73,73,104   ; 35 deg - True value: 0.573576436351046
	dc.w 103,-75,75,103   ; 36 deg - True value: 0.5877852522924731
	dc.w 102,-77,77,102   ; 37 deg - True value: 0.6018150231520483
	dc.w 100,-78,78,100   ; 38 deg - True value: 0.6156614753256582
	dc.w 99,-80,80,99   ; 39 deg - True value: 0.6293203910498374
	dc.w 98,-82,82,98   ; 40 deg - True value: 0.6427876096865393
	dc.w 96,-83,83,96   ; 41 deg - True value: 0.6560590289905072
	dc.w 95,-85,85,95   ; 42 deg - True value: 0.6691306063588582
	dc.w 93,-87,87,93   ; 43 deg - True value: 0.6819983600624985
	dc.w 92,-88,88,92   ; 44 deg - True value: 0.6946583704589973
	dc.w 90,-90,90,90   ; 45 deg - True value: 0.7071067811865475
	dc.w 88,-92,92,88   ; 46 deg - True value: 0.7193398003386511
	dc.w 87,-93,93,87   ; 47 deg - True value: 0.7313537016191705
	dc.w 85,-95,95,85   ; 48 deg - True value: 0.7431448254773942
	dc.w 83,-96,96,83   ; 49 deg - True value: 0.754709580222772
	dc.w 82,-98,98,82   ; 50 deg - True value: 0.766044443118978
	dc.w 80,-99,99,80   ; 51 deg - True value: 0.7771459614569708
	dc.w 78,-100,100,78   ; 52 deg - True value: 0.788010753606722
	dc.w 77,-102,102,77   ; 53 deg - True value: 0.7986355100472928
	dc.w 75,-103,103,75   ; 54 deg - True value: 0.8090169943749475
	dc.w 73,-104,104,73   ; 55 deg - True value: 0.8191520442889918
	dc.w 71,-106,106,71   ; 56 deg - True value: 0.8290375725550417
	dc.w 69,-107,107,69   ; 57 deg - True value: 0.8386705679454239
	dc.w 67,-108,108,67   ; 58 deg - True value: 0.8480480961564261
	dc.w 65,-109,109,65   ; 59 deg - True value: 0.8571673007021122
	dc.w 64,-110,110,64   ; 60 deg - True value: 0.8660254037844386
	dc.w 62,-111,111,62   ; 61 deg - True value: 0.8746197071393957
	dc.w 60,-113,113,60   ; 62 deg - True value: 0.8829475928589269
	dc.w 58,-114,114,58   ; 63 deg - True value: 0.8910065241883678
	dc.w 56,-115,115,56   ; 64 deg - True value: 0.898794046299167
	dc.w 54,-116,116,54   ; 65 deg - True value: 0.9063077870366499
	dc.w 52,-116,116,52   ; 66 deg - True value: 0.9135454576426009
	dc.w 50,-117,117,50   ; 67 deg - True value: 0.9205048534524403
	dc.w 47,-118,118,47   ; 68 deg - True value: 0.9271838545667874
	dc.w 45,-119,119,45   ; 69 deg - True value: 0.9335804264972017
	dc.w 43,-120,120,43   ; 70 deg - True value: 0.9396926207859083
	dc.w 41,-121,121,41   ; 71 deg - True value: 0.9455185755993167
	dc.w 39,-121,121,39   ; 72 deg - True value: 0.9510565162951535
	dc.w 37,-122,122,37   ; 73 deg - True value: 0.9563047559630354
	dc.w 35,-123,123,35   ; 74 deg - True value: 0.9612616959383189
	dc.w 33,-123,123,33   ; 75 deg - True value: 0.9659258262890683
	dc.w 30,-124,124,30   ; 76 deg - True value: 0.9702957262759965
	dc.w 28,-124,124,28   ; 77 deg - True value: 0.9743700647852352
	dc.w 26,-125,125,26   ; 78 deg - True value: 0.9781476007338056
	dc.w 24,-125,125,24   ; 79 deg - True value: 0.981627183447664
	dc.w 22,-126,126,22   ; 80 deg - True value: 0.984807753012208
	dc.w 20,-126,126,20   ; 81 deg - True value: 0.9876883405951378
	dc.w 17,-126,126,17   ; 82 deg - True value: 0.9902680687415703
	dc.w 15,-127,127,15   ; 83 deg - True value: 0.992546151641322
	dc.w 13,-127,127,13   ; 84 deg - True value: 0.9945218953682733
	dc.w 11,-127,127,11   ; 85 deg - True value: 0.9961946980917455
	dc.w 8,-127,127,8   ; 86 deg - True value: 0.9975640502598242
	dc.w 6,-127,127,6   ; 87 deg - True value: 0.9986295347545738
	dc.w 4,-127,127,4   ; 88 deg - True value: 0.9993908270190958
	dc.w 2,-127,127,2   ; 89 deg - True value: 0.9998476951563913
	dc.w 7,-128,128,7   ; 90 deg - True value: 1
	dc.w -2,-127,127,-2   ; 91 deg - True value: 0.9998476951563913
	dc.w -4,-127,127,-4   ; 92 deg - True value: 0.9993908270190958
	dc.w -6,-127,127,-6   ; 93 deg - True value: 0.9986295347545738
	dc.w -8,-127,127,-8   ; 94 deg - True value: 0.9975640502598242
	dc.w -11,-127,127,-11   ; 95 deg - True value: 0.9961946980917455
	dc.w -13,-127,127,-13   ; 96 deg - True value: 0.9945218953682734
	dc.w -15,-127,127,-15   ; 97 deg - True value: 0.9925461516413221
	dc.w -17,-126,126,-17   ; 98 deg - True value: 0.9902680687415704
	dc.w -20,-126,126,-20   ; 99 deg - True value: 0.9876883405951377
	dc.w -22,-126,126,-22   ; 100 deg - True value: 0.984807753012208
	dc.w -24,-125,125,-24   ; 101 deg - True value: 0.981627183447664
	dc.w -26,-125,125,-26   ; 102 deg - True value: 0.9781476007338057
	dc.w -28,-124,124,-28   ; 103 deg - True value: 0.9743700647852352
	dc.w -30,-124,124,-30   ; 104 deg - True value: 0.9702957262759965
	dc.w -33,-123,123,-33   ; 105 deg - True value: 0.9659258262890683
	dc.w -35,-123,123,-35   ; 106 deg - True value: 0.9612616959383189
	dc.w -37,-122,122,-37   ; 107 deg - True value: 0.9563047559630355
	dc.w -39,-121,121,-39   ; 108 deg - True value: 0.9510565162951536
	dc.w -41,-121,121,-41   ; 109 deg - True value: 0.9455185755993168
	dc.w -43,-120,120,-43   ; 110 deg - True value: 0.9396926207859084
	dc.w -45,-119,119,-45   ; 111 deg - True value: 0.9335804264972017
	dc.w -47,-118,118,-47   ; 112 deg - True value: 0.9271838545667874
	dc.w -50,-117,117,-50   ; 113 deg - True value: 0.9205048534524404
	dc.w -52,-116,116,-52   ; 114 deg - True value: 0.913545457642601
	dc.w -54,-116,116,-54   ; 115 deg - True value: 0.90630778703665
	dc.w -56,-115,115,-56   ; 116 deg - True value: 0.8987940462991669
	dc.w -58,-114,114,-58   ; 117 deg - True value: 0.8910065241883679
	dc.w -60,-113,113,-60   ; 118 deg - True value: 0.8829475928589271
	dc.w -62,-111,111,-62   ; 119 deg - True value: 0.8746197071393959
	dc.w -63,-110,110,-63   ; 120 deg - True value: 0.8660254037844387
	dc.w -65,-109,109,-65   ; 121 deg - True value: 0.8571673007021123
	dc.w -67,-108,108,-67   ; 122 deg - True value: 0.8480480961564261
	dc.w -69,-107,107,-69   ; 123 deg - True value: 0.838670567945424
	dc.w -71,-106,106,-71   ; 124 deg - True value: 0.8290375725550417
	dc.w -73,-104,104,-73   ; 125 deg - True value: 0.819152044288992
	dc.w -75,-103,103,-75   ; 126 deg - True value: 0.8090169943749475
	dc.w -77,-102,102,-77   ; 127 deg - True value: 0.7986355100472927
	dc.w -78,-100,100,-78   ; 128 deg - True value: 0.788010753606722
	dc.w -80,-99,99,-80   ; 129 deg - True value: 0.777145961456971
	dc.w -82,-98,98,-82   ; 130 deg - True value: 0.766044443118978
	dc.w -83,-96,96,-83   ; 131 deg - True value: 0.7547095802227718
	dc.w -85,-95,95,-85   ; 132 deg - True value: 0.7431448254773942
	dc.w -87,-93,93,-87   ; 133 deg - True value: 0.7313537016191706
	dc.w -88,-92,92,-88   ; 134 deg - True value: 0.7193398003386514
	dc.w -90,-90,90,-90   ; 135 deg - True value: 0.7071067811865476
	dc.w -92,-88,88,-92   ; 136 deg - True value: 0.6946583704589971
	dc.w -93,-87,87,-93   ; 137 deg - True value: 0.6819983600624986
	dc.w -95,-85,85,-95   ; 138 deg - True value: 0.6691306063588583
	dc.w -96,-83,83,-96   ; 139 deg - True value: 0.6560590289905073
	dc.w -98,-82,82,-98   ; 140 deg - True value: 0.6427876096865395
	dc.w -99,-80,80,-99   ; 141 deg - True value: 0.6293203910498377
	dc.w -100,-78,78,-100   ; 142 deg - True value: 0.6156614753256584
	dc.w -102,-77,77,-102   ; 143 deg - True value: 0.6018150231520482
	dc.w -103,-75,75,-103   ; 144 deg - True value: 0.5877852522924732
	dc.w -104,-73,73,-104   ; 145 deg - True value: 0.5735764363510464
	dc.w -106,-71,71,-106   ; 146 deg - True value: 0.5591929034707469
	dc.w -107,-69,69,-107   ; 147 deg - True value: 0.5446390350150269
	dc.w -108,-67,67,-108   ; 148 deg - True value: 0.5299192642332049
	dc.w -109,-65,65,-109   ; 149 deg - True value: 0.5150380749100544
	dc.w -110,-63,63,-110   ; 150 deg - True value: 0.49999999999999994
	dc.w -111,-62,62,-111   ; 151 deg - True value: 0.48480962024633717
	dc.w -113,-60,60,-113   ; 152 deg - True value: 0.4694715627858911
	dc.w -114,-58,58,-114   ; 153 deg - True value: 0.45399049973954686
	dc.w -115,-56,56,-115   ; 154 deg - True value: 0.4383711467890773
	dc.w -116,-54,54,-116   ; 155 deg - True value: 0.4226182617406995
	dc.w -116,-52,52,-116   ; 156 deg - True value: 0.40673664307580043
	dc.w -117,-50,50,-117   ; 157 deg - True value: 0.39073112848927416
	dc.w -118,-47,47,-118   ; 158 deg - True value: 0.37460659341591224
	dc.w -119,-45,45,-119   ; 159 deg - True value: 0.3583679495453002
	dc.w -120,-43,43,-120   ; 160 deg - True value: 0.3420201433256689
	dc.w -121,-41,41,-121   ; 161 deg - True value: 0.325568154457157
	dc.w -121,-39,39,-121   ; 162 deg - True value: 0.3090169943749475
	dc.w -122,-37,37,-122   ; 163 deg - True value: 0.29237170472273705
	dc.w -123,-35,35,-123   ; 164 deg - True value: 0.27563735581699966
	dc.w -123,-33,33,-123   ; 165 deg - True value: 0.258819045102521
	dc.w -124,-30,30,-124   ; 166 deg - True value: 0.24192189559966773
	dc.w -124,-28,28,-124   ; 167 deg - True value: 0.22495105434386478
	dc.w -125,-26,26,-125   ; 168 deg - True value: 0.20791169081775931
	dc.w -125,-24,24,-125   ; 169 deg - True value: 0.19080899537654497
	dc.w -126,-22,22,-126   ; 170 deg - True value: 0.17364817766693028
	dc.w -126,-20,20,-126   ; 171 deg - True value: 0.15643446504023098
	dc.w -126,-17,17,-126   ; 172 deg - True value: 0.13917310096006574
	dc.w -127,-15,15,-127   ; 173 deg - True value: 0.12186934340514755
	dc.w -127,-13,13,-127   ; 174 deg - True value: 0.10452846326765373
	dc.w -127,-11,11,-127   ; 175 deg - True value: 0.08715574274765864
	dc.w -127,-8,8,-127   ; 176 deg - True value: 0.06975647374412552
	dc.w -127,-6,6,-127   ; 177 deg - True value: 0.05233595624294381
	dc.w -127,-4,4,-127   ; 178 deg - True value: 0.0348994967025007
	dc.w -127,-2,2,-127   ; 179 deg - True value: 0.01745240643728344
	dc.w -128,-1,1,-128   ; 180 deg - True value: 1.2246467991473532e-16
	dc.w -127,2,-2,-127   ; 181 deg - True value: -0.017452406437283192
	dc.w -127,4,-4,-127   ; 182 deg - True value: -0.0348994967025009
	dc.w -127,6,-6,-127   ; 183 deg - True value: -0.052335956242943564
	dc.w -127,8,-8,-127   ; 184 deg - True value: -0.06975647374412483
	dc.w -127,11,-11,-127   ; 185 deg - True value: -0.08715574274765794
	dc.w -127,13,-13,-127   ; 186 deg - True value: -0.10452846326765305
	dc.w -127,15,-15,-127   ; 187 deg - True value: -0.12186934340514775
	dc.w -126,17,-17,-126   ; 188 deg - True value: -0.13917310096006552
	dc.w -126,20,-20,-126   ; 189 deg - True value: -0.15643446504023073
	dc.w -126,22,-22,-126   ; 190 deg - True value: -0.17364817766693047
	dc.w -125,24,-24,-125   ; 191 deg - True value: -0.19080899537654472
	dc.w -125,26,-26,-125   ; 192 deg - True value: -0.20791169081775907
	dc.w -124,28,-28,-124   ; 193 deg - True value: -0.22495105434386498
	dc.w -124,30,-30,-124   ; 194 deg - True value: -0.2419218955996675
	dc.w -123,33,-33,-123   ; 195 deg - True value: -0.25881904510252035
	dc.w -123,35,-35,-123   ; 196 deg - True value: -0.275637355816999
	dc.w -122,37,-37,-122   ; 197 deg - True value: -0.2923717047227364
	dc.w -121,39,-39,-121   ; 198 deg - True value: -0.30901699437494773
	dc.w -121,41,-41,-121   ; 199 deg - True value: -0.32556815445715676
	dc.w -120,43,-43,-120   ; 200 deg - True value: -0.34202014332566866
	dc.w -119,45,-45,-119   ; 201 deg - True value: -0.35836794954530043
	dc.w -118,47,-47,-118   ; 202 deg - True value: -0.374606593415912
	dc.w -117,50,-50,-117   ; 203 deg - True value: -0.39073112848927355
	dc.w -116,52,-52,-116   ; 204 deg - True value: -0.4067366430757998
	dc.w -116,54,-54,-116   ; 205 deg - True value: -0.4226182617406993
	dc.w -115,56,-56,-115   ; 206 deg - True value: -0.43837114678907707
	dc.w -114,58,-58,-114   ; 207 deg - True value: -0.45399049973954625
	dc.w -113,60,-60,-113   ; 208 deg - True value: -0.46947156278589086
	dc.w -111,62,-62,-111   ; 209 deg - True value: -0.48480962024633695
	dc.w -110,64,-64,-110   ; 210 deg - True value: -0.5000000000000001
	dc.w -109,65,-65,-109   ; 211 deg - True value: -0.5150380749100542
	dc.w -108,67,-67,-108   ; 212 deg - True value: -0.5299192642332048
	dc.w -107,69,-69,-107   ; 213 deg - True value: -0.5446390350150271
	dc.w -106,71,-71,-106   ; 214 deg - True value: -0.5591929034707467
	dc.w -104,73,-73,-104   ; 215 deg - True value: -0.5735764363510458
	dc.w -103,75,-75,-103   ; 216 deg - True value: -0.587785252292473
	dc.w -102,77,-77,-102   ; 217 deg - True value: -0.601815023152048
	dc.w -100,78,-78,-100   ; 218 deg - True value: -0.6156614753256578
	dc.w -99,80,-80,-99   ; 219 deg - True value: -0.6293203910498376
	dc.w -98,82,-82,-98   ; 220 deg - True value: -0.6427876096865393
	dc.w -96,83,-83,-96   ; 221 deg - True value: -0.6560590289905074
	dc.w -95,85,-85,-95   ; 222 deg - True value: -0.6691306063588582
	dc.w -93,87,-87,-93   ; 223 deg - True value: -0.6819983600624984
	dc.w -92,88,-88,-92   ; 224 deg - True value: -0.6946583704589974
	dc.w -90,90,-90,-90   ; 225 deg - True value: -0.7071067811865475
	dc.w -88,92,-92,-88   ; 226 deg - True value: -0.7193398003386509
	dc.w -87,93,-93,-87   ; 227 deg - True value: -0.7313537016191701
	dc.w -85,95,-95,-85   ; 228 deg - True value: -0.743144825477394
	dc.w -83,96,-96,-83   ; 229 deg - True value: -0.7547095802227717
	dc.w -82,98,-98,-82   ; 230 deg - True value: -0.7660444431189779
	dc.w -80,99,-99,-80   ; 231 deg - True value: -0.7771459614569711
	dc.w -78,100,-100,-78   ; 232 deg - True value: -0.7880107536067221
	dc.w -77,102,-102,-77   ; 233 deg - True value: -0.7986355100472928
	dc.w -75,103,-103,-75   ; 234 deg - True value: -0.8090169943749473
	dc.w -73,104,-104,-73   ; 235 deg - True value: -0.8191520442889916
	dc.w -71,106,-106,-71   ; 236 deg - True value: -0.8290375725550414
	dc.w -69,107,-107,-69   ; 237 deg - True value: -0.838670567945424
	dc.w -67,108,-108,-67   ; 238 deg - True value: -0.848048096156426
	dc.w -65,109,-109,-65   ; 239 deg - True value: -0.8571673007021121
	dc.w -64,110,-110,-64   ; 240 deg - True value: -0.8660254037844385
	dc.w -62,111,-111,-62   ; 241 deg - True value: -0.8746197071393959
	dc.w -60,113,-113,-60   ; 242 deg - True value: -0.882947592858927
	dc.w -58,114,-114,-58   ; 243 deg - True value: -0.8910065241883678
	dc.w -56,115,-115,-56   ; 244 deg - True value: -0.8987940462991668
	dc.w -54,116,-116,-54   ; 245 deg - True value: -0.9063077870366497
	dc.w -52,116,-116,-52   ; 246 deg - True value: -0.913545457642601
	dc.w -50,117,-117,-50   ; 247 deg - True value: -0.9205048534524403
	dc.w -47,118,-118,-47   ; 248 deg - True value: -0.9271838545667873
	dc.w -45,119,-119,-45   ; 249 deg - True value: -0.9335804264972016
	dc.w -43,120,-120,-43   ; 250 deg - True value: -0.9396926207859082
	dc.w -41,121,-121,-41   ; 251 deg - True value: -0.9455185755993168
	dc.w -39,121,-121,-39   ; 252 deg - True value: -0.9510565162951535
	dc.w -37,122,-122,-37   ; 253 deg - True value: -0.9563047559630353
	dc.w -35,123,-123,-35   ; 254 deg - True value: -0.9612616959383189
	dc.w -33,123,-123,-33   ; 255 deg - True value: -0.9659258262890683
	dc.w -30,124,-124,-30   ; 256 deg - True value: -0.9702957262759965
	dc.w -28,124,-124,-28   ; 257 deg - True value: -0.9743700647852351
	dc.w -26,125,-125,-26   ; 258 deg - True value: -0.9781476007338056
	dc.w -24,125,-125,-24   ; 259 deg - True value: -0.9816271834476639
	dc.w -22,126,-126,-22   ; 260 deg - True value: -0.984807753012208
	dc.w -20,126,-126,-20   ; 261 deg - True value: -0.9876883405951377
	dc.w -17,126,-126,-17   ; 262 deg - True value: -0.9902680687415704
	dc.w -15,127,-127,-15   ; 263 deg - True value: -0.9925461516413221
	dc.w -13,127,-127,-13   ; 264 deg - True value: -0.9945218953682734
	dc.w -11,127,-127,-11   ; 265 deg - True value: -0.9961946980917455
	dc.w -8,127,-127,-8   ; 266 deg - True value: -0.9975640502598242
	dc.w -6,127,-127,-6   ; 267 deg - True value: -0.9986295347545738
	dc.w -4,127,-127,-4   ; 268 deg - True value: -0.9993908270190957
	dc.w -2,127,-127,-2   ; 269 deg - True value: -0.9998476951563913
	dc.w -2,128,-128,-2   ; 270 deg - True value: -1
	dc.w 2,127,-127,2   ; 271 deg - True value: -0.9998476951563913
	dc.w 4,127,-127,4   ; 272 deg - True value: -0.9993908270190958
	dc.w 6,127,-127,6   ; 273 deg - True value: -0.9986295347545738
	dc.w 8,127,-127,8   ; 274 deg - True value: -0.9975640502598243
	dc.w 11,127,-127,11   ; 275 deg - True value: -0.9961946980917455
	dc.w 13,127,-127,13   ; 276 deg - True value: -0.9945218953682734
	dc.w 15,127,-127,15   ; 277 deg - True value: -0.992546151641322
	dc.w 17,126,-126,17   ; 278 deg - True value: -0.9902680687415704
	dc.w 20,126,-126,20   ; 279 deg - True value: -0.9876883405951378
	dc.w 22,126,-126,22   ; 280 deg - True value: -0.9848077530122081
	dc.w 24,125,-125,24   ; 281 deg - True value: -0.9816271834476641
	dc.w 26,125,-125,26   ; 282 deg - True value: -0.9781476007338058
	dc.w 28,124,-124,28   ; 283 deg - True value: -0.9743700647852352
	dc.w 30,124,-124,30   ; 284 deg - True value: -0.9702957262759966
	dc.w 33,123,-123,33   ; 285 deg - True value: -0.9659258262890682
	dc.w 35,123,-123,35   ; 286 deg - True value: -0.9612616959383188
	dc.w 37,122,-122,37   ; 287 deg - True value: -0.9563047559630354
	dc.w 39,121,-121,39   ; 288 deg - True value: -0.9510565162951536
	dc.w 41,121,-121,41   ; 289 deg - True value: -0.945518575599317
	dc.w 43,120,-120,43   ; 290 deg - True value: -0.9396926207859085
	dc.w 45,119,-119,45   ; 291 deg - True value: -0.9335804264972021
	dc.w 47,118,-118,47   ; 292 deg - True value: -0.9271838545667874
	dc.w 50,117,-117,50   ; 293 deg - True value: -0.9205048534524405
	dc.w 52,116,-116,52   ; 294 deg - True value: -0.9135454576426008
	dc.w 54,116,-116,54   ; 295 deg - True value: -0.9063077870366498
	dc.w 56,115,-115,56   ; 296 deg - True value: -0.898794046299167
	dc.w 58,114,-114,58   ; 297 deg - True value: -0.891006524188368
	dc.w 60,113,-113,60   ; 298 deg - True value: -0.8829475928589271
	dc.w 62,111,-111,62   ; 299 deg - True value: -0.8746197071393961
	dc.w 64,110,-110,64   ; 300 deg - True value: -0.8660254037844386
	dc.w 65,109,-109,65   ; 301 deg - True value: -0.8571673007021123
	dc.w 67,108,-108,67   ; 302 deg - True value: -0.8480480961564261
	dc.w 69,107,-107,69   ; 303 deg - True value: -0.8386705679454243
	dc.w 71,106,-106,71   ; 304 deg - True value: -0.8290375725550421
	dc.w 73,104,-104,73   ; 305 deg - True value: -0.8191520442889918
	dc.w 75,103,-103,75   ; 306 deg - True value: -0.8090169943749476
	dc.w 77,102,-102,77   ; 307 deg - True value: -0.798635510047293
	dc.w 78,100,-100,78   ; 308 deg - True value: -0.7880107536067218
	dc.w 80,99,-99,80   ; 309 deg - True value: -0.7771459614569708
	dc.w 82,98,-98,82   ; 310 deg - True value: -0.7660444431189781
	dc.w 83,96,-96,83   ; 311 deg - True value: -0.7547095802227721
	dc.w 85,95,-95,85   ; 312 deg - True value: -0.7431448254773946
	dc.w 87,93,-93,87   ; 313 deg - True value: -0.731353701619171
	dc.w 88,92,-92,88   ; 314 deg - True value: -0.7193398003386517
	dc.w 90,90,-90,90   ; 315 deg - True value: -0.7071067811865477
	dc.w 92,88,-88,92   ; 316 deg - True value: -0.6946583704589976
	dc.w 93,87,-87,93   ; 317 deg - True value: -0.6819983600624983
	dc.w 95,85,-85,95   ; 318 deg - True value: -0.6691306063588581
	dc.w 96,83,-83,96   ; 319 deg - True value: -0.6560590289905074
	dc.w 98,82,-82,98   ; 320 deg - True value: -0.6427876096865396
	dc.w 99,80,-80,99   ; 321 deg - True value: -0.6293203910498378
	dc.w 100,78,-78,100   ; 322 deg - True value: -0.6156614753256588
	dc.w 102,77,-77,102   ; 323 deg - True value: -0.6018150231520483
	dc.w 103,75,-75,103   ; 324 deg - True value: -0.5877852522924734
	dc.w 104,73,-73,104   ; 325 deg - True value: -0.5735764363510465
	dc.w 106,71,-71,106   ; 326 deg - True value: -0.5591929034707473
	dc.w 107,69,-69,107   ; 327 deg - True value: -0.544639035015027
	dc.w 108,67,-67,108   ; 328 deg - True value: -0.5299192642332058
	dc.w 109,65,-65,109   ; 329 deg - True value: -0.5150380749100545
	dc.w 110,64,-64,110   ; 330 deg - True value: -0.5000000000000004
	dc.w 111,62,-62,111   ; 331 deg - True value: -0.4848096202463369
	dc.w 113,60,-60,113   ; 332 deg - True value: -0.4694715627858908
	dc.w 114,58,-58,114   ; 333 deg - True value: -0.45399049973954697
	dc.w 115,56,-56,115   ; 334 deg - True value: -0.438371146789077
	dc.w 116,54,-54,116   ; 335 deg - True value: -0.4226182617407
	dc.w 116,52,-52,116   ; 336 deg - True value: -0.40673664307580015
	dc.w 117,50,-50,117   ; 337 deg - True value: -0.3907311284892747
	dc.w 118,47,-47,118   ; 338 deg - True value: -0.37460659341591235
	dc.w 119,45,-45,119   ; 339 deg - True value: -0.35836794954530077
	dc.w 120,43,-43,120   ; 340 deg - True value: -0.3420201433256686
	dc.w 121,41,-41,121   ; 341 deg - True value: -0.32556815445715753
	dc.w 121,39,-39,121   ; 342 deg - True value: -0.3090169943749476
	dc.w 122,37,-37,122   ; 343 deg - True value: -0.29237170472273627
	dc.w 123,35,-35,123   ; 344 deg - True value: -0.2756373558169998
	dc.w 123,33,-33,123   ; 345 deg - True value: -0.2588190451025207
	dc.w 124,30,-30,124   ; 346 deg - True value: -0.24192189559966787
	dc.w 124,28,-28,124   ; 347 deg - True value: -0.22495105434386534
	dc.w 125,26,-26,125   ; 348 deg - True value: -0.20791169081775987
	dc.w 125,24,-24,125   ; 349 deg - True value: -0.19080899537654467
	dc.w 126,22,-22,126   ; 350 deg - True value: -0.17364817766693127
	dc.w 126,20,-20,126   ; 351 deg - True value: -0.15643446504023112
	dc.w 126,17,-17,126   ; 352 deg - True value: -0.13917310096006588
	dc.w 127,15,-15,127   ; 353 deg - True value: -0.12186934340514811
	dc.w 127,13,-13,127   ; 354 deg - True value: -0.10452846326765342
	dc.w 127,11,-11,127   ; 355 deg - True value: -0.08715574274765832
	dc.w 127,8,-8,127   ; 356 deg - True value: -0.06975647374412476
	dc.w 127,6,-6,127   ; 357 deg - True value: -0.05233595624294437
	dc.w 127,4,-4,127   ; 358 deg - True value: -0.034899496702500823
	dc.w 127,2,-2,127   ; 359 deg - True value: -0.01745240643728445

