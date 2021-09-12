
; Lezione4c.s	FUSIONE DI 3 EFFETTI COPPER + FIGURA AD 8 COLORI

	SECTION	CiriCop,CODE_C

P61mode	=2	;Try other modes ONLY IF there are no Fxx commands >= 20.
		;(f.ex., P61.new_ditty only works with P61mode=1)


;;    ---  options common to all P61modes  ---

usecode	=$945A	;CHANGE! to the USE hexcode from P61con for a big 
		;CPU-time gain! (See module usecodes at end of source)
		;Multiple songs, single playroutine? Just "OR" the 
		;usecodes together!

		;...STOP! Have you changed it yet!? ;)
		;You will LOSE RASTERTIME AND FEATURES if you don't.

P61pl=usecode&$400000

split4	=0	;Great time gain, but INCOMPATIBLE with F03, F02, and F01
		;speeds in the song! That's the ONLY reason it's default 0.
		;So ==> PLEASE try split4=1 in ANY mode!
		;Overrides splitchans to decrunch 1 chan/frame.
		;See ;@@ note for P61_SetPosition.


splitchans=1	;#channels to be split off to be decrunched at "playtime frame"
		;0=use normal "decrunch all channels in the same frame"
		;Experiment to find minimum rastertime, but it should be 1 or 2
		;for 3-4 channels songs and 0 or 1 with less channels.

visuctrs=0	;enables visualizers in this example: P61_visuctr0..3.w 
		;containing #frames (#lev6ints if cia=1) elapsed since last
		;instrument triggered. (0=triggered this frame.)
		;Easy alternative to E8x or 1Fx sync commands.

asmonereport	=0	;ONLY for printing a settings report on assembly. Use
			;if you get problems (only works in AsmOne/AsmPro, tho)

p61system=0	;1=system-friendly. Use for DOS/Workbench programs.

p61exec	=0	;0 if execbase is destroyed, such as in a trackmo.

p61fade	=0	;enable channel volume fading from your demo

channels=4	;<4 for game sound effects in the higher channels. Incompatible
		; with splitchans/split4.

playflag=0	;1=enable music on/off capability (at run-time). .If 0, you can
		;still do this by just, you know, not calling P61_Music...
		;It's a convenience function to "pause" music in CIA mode.

p61bigjtab=0	;1 to waste 480b and save max 56 cycles on 68000.

opt020	=0	;1=enable optimizations for 020+. Please be 68000 compatible!
		;splitchans will already give MUCH bigger gains, and you can
		;try the MAXOPTI mode.

p61jump	=0	;0 to leave out P61_SetPosition (size gain)
		;1 if you need to force-start at a given position fex in a game

C	=0	;If you happen to have some $dffxxx value in a6, you can 
		;change this to $xxx to not have to load it before P61_Music.

clraudxdat=0	;enable smoother start of quiet sounds. probably not needed.

optjmp	=1	;0=safety check for jump beyond end of song. Clear it if you 
		;play unknown P61 songs with erroneous Bxx/Dxx commands in them

oscillo	=0	;1 to get a sample window (ptr, size) to read and display for 
		;oscilloscope type effects (beta, noshorts=1, pad instruments)
		;IMPORTANT: see ;@@ note about chipmem dc.w buffer.

quietstart=0	;attempt to avoid the very first click in some modules
		;IMPORTANT: see ;@@ note about chipmem dc.w buffer.

use1Fx=0	;Optional extra effect-sync trigger (*). If your module is free
		;from E commands, and you add E8x to sync stuff, this will 
		;change the usecode to include a whole code block for all E 
		;commands. You can avoid this by only using 1Fx. (You can 
		;also use this as an extra sync command if E8x is not enough, 
		;of course.)

;(*) Slideup values>116 causes bugs in Protracker, and E8 causes extra-code 
;for all E-commands, so I used this. It's only faster if your song contains 0
;E-commands, so it's only useful to a few, I guess. Bit of cyclemania. :)

;Just like E8x, you will get the trigger after the P61_Music call, 1 frame 
;BEFORE it's heard. This is good, because it allows double-buffered graphics 
;or effects running at < 50 fps to show the trigger synced properly.



;;    ---  CIA mode options (default) ---

	ifeq P61mode-1

p61cia	=1	;call P61_Music on the CIA interrupt instead of every frame.

lev6	=1	;1=keep the timer B int at least for setting DMA.
		;0="FBI mode" - ie. "Free the B-timer Interrupt".

		;0 requires noshorts=1, p61system=0, and that YOU make sure DMA
		;is set at 11 scanlines (700 usecs) after P61_Music is called.
		;AsmOne will warn you if requirements are wrong.

		;DMA bits will be poked in the address you pass in A4 to 
		;P61_init. (Update P61_DMApokeAddr during playing if necessary,
		;for example if switching Coppers.)

		;P61_Init will still save old timer B settings, and initialize
		;it. P61_End will still restore timer B settings from P61_Init.
		;So don't count on it 'across calls' to these routines.
		;Using it after P61_Init and before P61_End is fine.

noshorts=0	;1 saves ~1 scanline, requires Lev6=0. Use if no instrument is
		;shorter than ~300 bytes (or extend them to > 300 bytes).
		;It does this by setting repeatpos/length the next frame 
		;instead of after a few scanlines,so incompatible with MAXOPTI

dupedec	=0	;0=save 500 bytes and lose 26 cycles - I don't blame you. :)
		;1=splitchans or split4 must be on.

suppF01	=1	;0 is incompatible with CIA mode. It moves ~100 cycles of
		;next-pattern code to the less busy 2nd frame of a notestep.
		;If you really need it, you have to experiment as the support 
		;is quite complex. Basically set it to 1 and try the various 
		;P61modes, if none work, change some settings.

	endc

;;    ---  VBLANK mode options ---

	ifeq P61mode-2

p61cia	=0
lev6	=1	;still set sound DMA with a simple interrupt.
noshorts=0	;try 1 (and pad short instruments if nec) for 1 scanline gain
dupedec	=0
suppF01	=P61pl	;if 1, split4=1 may cause sound errors. but try it anyway. :)
	
	endc

;;    ---  COPPER mode options ---

	ifeq P61mode-3

p61cia	=0
lev6	=0	;don't set sound DMA with an interrupt.
		;(use the copper to set sound DMA 11 scanlines after P61_Music)
noshorts=1	;You must pad instruments < 300 bytes for this mode to work.
dupedec	=0
suppF01	=P61pl	;if 1, split4=1 may cause sound errors. but try it anyway. :)

	endc

;;    ---  MAXOPTI mode options ---

	ifeq P61mode-4

p61cia	=0
lev6	=0
noshorts=1	;You must pad instruments < 300 bytes for this mode to work.
dupedec	=1
suppF01	=P61pl	;if 1, split4=1 may cause sound errors. but try it anyway. :)

	endc

Inizio:
	move.l	4.w,a6		; Execbase in a6
	jsr	-$78(a6)	; Disable - ferma il multitasking
	lea	gfxname(PC),a1	; Indirizzo del nome della lib da aprire in a1
	jsr	-$198(a6)	; OpenLibrary
	move.l	d0,gfxbase	; salvo l'indirizzo base GFX in GfxBase
	move.l	d0,a6
	move.l	$26(a6),oldcop	; salviamo l'indirizzo della copperlist vecchia

;*****************************************************************************
;	FACCIAMO PUNTARE I BPLPOINTERS NELLA COPPELIST AI NOSTRI BITPLANES
;*****************************************************************************


	MOVE.L	#SCREEN_0,d0		; in d0 mettiamo l'indirizzo della PIC,
				; ossia dove inizia il primo bitplane

	LEA	BPLPOINTERS,A1	; in a1 mettiamo l'indirizzo dei
				; puntatori ai planes della COPPERLIST
	MOVEQ	#0,D1		; numero di bitplanes -1 (qua sono 3)
				; per eseguire il ciclo col DBRA
POINTBP:
	;move.w	d0,6(a1)	; copia la word BASSA dell'indirizzo del plane
				; nella word giusta nella copperlist
	swap	d0		; scambia le 2 word di d0 (es: 1234 > 3412)
				; mettendo la word ALTA al posto di quella
				; BASSA, permettendone la copia col move.w!!
	;move.w	d0,2(a1)	; copia la word ALTA dell'indirizzo del plane
				; nella word giusta nella copperlist
	swap	d0		; scambia le 2 word di d0 (es: 3412 > 1234)
				; rimettendo a posto l'indirizzo.
	ADD.L	#40*256,d0	; Aggiungiamo 10240 ad D0, facendolo puntare
				; al secondo bitplane (si trova dopo il primo)
				; (cioe' aggiungiamo la lunghezza di un plane)
				; Nei cicli seguenti al primo faremo puntare
				; al terzo, al quarto bitplane eccetera.

	addq.w	#8,a1		; a1 ora contiene l'indirizzo dei prossimi
				; bplpointers nella copperlist da scrivere.
	dbra	d1,POINTBP	; Rifai D1 volte POINTBP (D1=num of bitplanes)

	jsr	-$10e(a6)		;WaitTOF
	jsr	-$10e(a6)		;WaitTOF

    lea	$dff000,a6
	move	$dff002,olddma		;Old DMA
	move	#$7ff,$96(a6)		;Disable DMAs
	move	#%1000011111000000,$96(a6) ;Master,Copper,Blitter,Bitplanes
	move	$1c(a6),-(sp)		;Old IRQ
	move	#$7fff,$9a(a6)		;Disable IRQs
	move	#$e000,$9a(a6)		;Master and lev6
					;NO COPPER-IRQ!
	moveq	#0,d0
	move	d0,$106(a6)		;Disable AGA/ECS-stuff
	move	d0,$1fc(a6)

	move.l	#COPPERLIST,$dff080	; Puntiamo la nostra COP
	move.w	d0,$dff088		; Facciamo partire la COP

	move.w	#0,$dff1fc		; FMODE - Disattiva l'AGA
	move.w	#$c00,$dff106		; BPLCON3 - Disattiva l'AGA

    lea Module1,a0
	sub.l a1,a1
	sub.l a2,a2
	moveq #0,d0

	;lea p61coppoke+3,a4		;only used in P61mode >=3
	jsr P61_Init

    jsr _ammxmainloop3_init

mouse:
	cmpi.b	#$ff,$dff006	; Siamo alla linea 255?
	bne.s	mouse		; Se non ancora, non andare avanti

    ;move	#$00F0,$180(a6)
	jsr P61_Music			;and call the playroutine manually.
	;move	#$003,$180(a6)

    move.w #$0F00,$dff180
	;STROKE #3
	;or.w    #3,STROKE_DATA
	jsr ammxmainloop3
	;move.l #SCREEN_0,d0
	lea BPLPOINTERS,a0
	move.w d0,6(a0)
	swap d0
	move.w d0,2(a0)
	swap d0

	lea BPLPOINTERS1,a0
	add.l #256*40,d0
	move.w d0,6(a0)
	swap d0
	move.w d0,2(a0)
	swap d0


	move	#$003,$180(a6)
	;move.l SCREEN_PTR_OTHER_0,a0
	;move.l #$FFFFFFFF,(a0)
	;move.l SCREEN_PTR_0,a0
	;move.l #$FFFFFFFF,(a0)
	IFD EFFECTS
	bsr.w	muovicopper	; barra rossa sotto linea $ff
	bsr.w	CopperDestSin	; Routine di scorrimento destra/sinistra
	BSR.w	scrollcolors	; scorrimento ciclico dei colori
	ENDC
Aspetta:
	cmpi.b	#$ff,$dff006	; Siamo alla linea 255?
	beq.s	Aspetta		; Se si, non andare avanti, aspetta la linea
				; seguente, altrimenti MuoviCopper viene
				; rieseguito

	btst	#6,$bfe001	; tasto sinistro del mouse premuto?
	bne.s	mouse		; se no, torna a mouse:


	move.l	oldcop(PC),$dff080	; Puntiamo la cop di sistema
	move.w	d0,$dff088		; facciamo partire la vecchia cop

	move.l	4.w,a6
	jsr	-$7e(a6)	; Enable - riabilita il Multitasking
	move.l	gfxbase(PC),a1	; Base della libreria da chiudere
	jsr	-$19e(a6)	; Closelibrary - chiudo la graphics lib
	move	olddma,$dff096
	moveq	#0,d0
	rts			; USCITA DAL PROGRAMMA


;	Dati

gfxname:
	dc.b	"graphics.library",0,0	

gfxbase:		; Qua ci va l'indirizzo di base per gli Offset
	dc.l	0	; della graphics.library

oldcop:			; Qua ci va l'indirizzo della vecchia COP di sistema
	dc.l	0

olddma:
	dc.l 0

Playrtn:
	include "P6112-Play.i"



; **************************************************************************
; *		BARRA A SCORRIMENTO ORIZZONTALE (Lezione3h.s)		   *
; **************************************************************************
	IFD EFFECTS
CopperDestSin:
	CMPI.W	#85,DestraFlag		; VAIDESTRA eseguita 85 volte?
	BNE.S	VAIDESTRA		; se non ancora, rieseguila
	CMPI.W	#85,SinistraFlag	; VAISINISTRA eseguita 85 volte?
	BNE.S	VAISINISTRA		; se non ancora, rieseguila
	CLR.W	DestraFlag	; la routine VAISINISTRA e' stata eseguita
	CLR.W	SinistraFlag	; 85 volte, riparti
	RTS			; TORNIAMO AL LOOP mouse


VAIDESTRA:			; questa routine sposta la barra verso DESTRA
	lea	CopBar+1,A0	; Mettiamo in A0 l'indirizzo del primo XX
	move.w	#29-1,D2	; dobbiamo cambiare 29 wait (usiamo un DBRA)
DestraLoop:
	addq.b	#2,(a0)		; aggiungiamo 2 alla coordinata X del wait
	ADD.W	#16,a0		; andiamo al prossimo wait da cambiare
	dbra	D2,DestraLoop	; ciclo eseguito d2 volte
	addq.w	#1,DestraFlag	; segnamo che abbiamo eseguito VAIDESTRA
	RTS			; TORNIAMO AL LOOP mouse


VAISINISTRA:			; questa routine sposta la barra verso SINISTRA
	lea	CopBar+1,A0
	move.w	#29-1,D2	; dobbiamo cambiare 29 wait
SinistraLoop:
	subq.b	#2,(a0)		; sottraiamo 2 alla coordinata X del wait
	ADD.W	#16,a0		; andiamo al prossimo wait da cambiare
	dbra	D2,SinistraLoop	; ciclo eseguito d2 volte
	addq.w	#1,SinistraFlag ; Annotiamo lo spostamento
	RTS			; TORNIAMO AL LOOP mouse


DestraFlag:		; In questa word viene tenuto il conto delle volte
	dc.w	0	; che e' stata eseguita VAIDESTRA

SinistraFlag:		; In questa word viene tenuto il conto delle volte
	dc.w    0	; che e' stata eseguita VAISINISTRA

; **************************************************************************
; *		BARRA ROSSA SOTTO LA LINEA $FF (Lezione3f.s)		   *
; **************************************************************************

muovicopper:
	LEA	BARRA,a0
	TST.B	SuGiu		; Dobbiamo salire o scendere?
	beq.w	VAIGIU
	cmpi.b	#$0a,(a0)	; siamo arrivati alla linea $0a+$ff? (265)
	beq.s	MettiGiu	; se si, siamo in cima e dobbiamo scendere
	subq.b	#1,(a0)
	subq.b	#1,8(a0)	; ora cambiamo gli altri wait: la distanza
	subq.b	#1,8*2(a0)	; tra un wait e l'altro e' di 8 bytes
	subq.b	#1,8*3(a0)
	subq.b	#1,8*4(a0)
	subq.b	#1,8*5(a0)
	subq.b	#1,8*6(a0)
	subq.b	#1,8*7(a0)	; qua dobbiamo modificare tutti i 9 wait della
	subq.b	#1,8*8(a0)	; barra rossa ogni volta per farla salire!
	subq.b	#1,8*9(a0)
	rts

MettiGiu:
	clr.b	SuGiu		; Azzerando SuGiu, al TST.B SuGiu il BEQ
	rts			; fara' saltare alla routine VAIGIU, e
				; la barra scedera'

VAIGIU:
	cmpi.b	#$2c,8*9(a0)	; siamo arrivati alla linea $2c?
	beq.s	MettiSu		; se si, siamo in fondo e dobbiamo risalire
	addq.b	#1,(a0)
	addq.b	#1,8(a0)	; ora cambiamo gli altri wait: la distanza
	addq.b	#1,8*2(a0)	; tra un wait e l'altro e' di 8 bytes
	addq.b	#1,8*3(a0)
	addq.b	#1,8*4(a0)
	addq.b	#1,8*5(a0)
	addq.b	#1,8*6(a0)
	addq.b	#1,8*7(a0)	; qua dobbiamo modificare tutti i 9 wait della
	addq.b	#1,8*8(a0)	; barra rossa ogni volta per farla scendere!
	addq.b	#1,8*9(a0)
	rts

MettiSu:
	move.b	#$ff,SuGiu	; Quando la label SuGiu non e' a zero,
	rts			; significa che dobbiamo risalire.


SuGiu:
	dc.b	0,0

; **************************************************************************
; *		SCORRIMENTO CICLICO DEI COLORI (Lezione3E.s)		   *
; **************************************************************************

scrollcolors:	
	move.w	col2,col1	; col2 copiato in col1
	move.w	col3,col2	; col3 copiato in col2
	move.w	col4,col3	; col4 copiato in col3
	move.w	col5,col4	; col5 copiato in col4
	move.w	col6,col5	; col6 copiato in col5
	move.w	col7,col6	; col7 copiato in col6
	move.w	col8,col7	; col8 copiato in col7
	move.w	col9,col8	; col9 copiato in col8
	move.w	col10,col9	; col10 copiato in col9
	move.w	col11,col10	; col11 copiato in col10
	move.w	col12,col11	; col12 copiato in col11
	move.w	col13,col12	; col13 copiato in col12
	move.w	col14,col13	; col14 copiato in col13
	move.w	col1,col14	; col1 copiato in col14
	rts
	ENDC


	include	"AProcessing/libs/rasterizers/globaloptions.s"
    include "AProcessing/libs/ammxmacros.i"
    include "AProcessing/libs/matrix/matrix.s"
	include "AProcessing/libs/rasterizers/3dglobals.i"
	include "AProcessing/libs/rasterizers/processingfill.s"
	include "AProcessing/libs/rasterizers/processing_table_plotrefs.s"
	include "AProcessing/libs/rasterizers/processingclearfunctions.s"
    include "AProcessing/libs/trigtables.i"
	include "AProcessing/libs/rasterizers/point.s"
    include "AProcessing/libs/rasterizers/triangle3d.s"
	include "AProcessing/libs/rasterizers/processing_bitplanes_fast.s"

	include "init.s"
	include "ammxmainloop3.s"

; **************************************************************************
; *				SUPER COPPERLIST			   *
; **************************************************************************

	SECTION	GRAPHIC,DATA_C

COPPERLIST:

	; Facciamo puntare gli sprite a ZERO, per eliminarli, o ce li troviamo
	; in giro impazziti a disturbare!!!

	dc.w	$120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000
	dc.w	$12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
	dc.w	$134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
	dc.w	$13e,$0000

	dc.w	$8e,$2c81	; DiwStrt	(registri con valori normali)
	dc.w	$90,$2cc1	; DiwStop
	dc.w	$92,$0038	; DdfStart
	dc.w	$94,$00d0	; DdfStop
	dc.w	$102,0		; BplCon1
	dc.w	$104,0		; BplCon2
	dc.w	$108,0		; Bpl1Mod
	dc.w	$10a,0		; Bpl2Mod

; Il BPLCON0 per uno schermo a 3 bitplanes: (8 colori)

		    ; 5432109876543210
	dc.w	$100,%0010001000000000	; bits 13 e 12 accesi!! (3 = %011)

;	Facciamo puntare i bitplanes direttamente mettendo nella copperlist
;	i registri $dff0e0 e seguenti qua di seguito con gli indirizzi
;	dei bitplanes che saranno messi dalla routine POINTBP

BPLPOINTERS:
	dc.w $e0,$0000,$e2,$0000	;primo	 bitplane - BPL0PT
BPLPOINTERS1:
	dc.w $e4,$0000,$e6,$0000	;secondo bitplane - BPL1PT
	;dc.w $e8,$0000,$ea,$0000	;terzo	 bitplane - BPL2PT


	IFD EFFECTS
;	L'effetto di Lezione3e.s spostato piu' in ALTO

	dc.w	$3a07,$fffe	; aspettiamo la linea 154 ($9a in esadecimale)
	dc.w	$180		; REGISTRO COLOR0
col1:
	dc.w	$0f0		; VALORE DEL COLOR 0 (che sara' modificato)
	dc.w	$3b07,$fffe ; aspettiamo la linea 155 (non sara' modificata)
	dc.w	$180		; REGISTRO COLOR0 (non sara' modificato)
col2:
	dc.w	$0d0		; VALORE DEL COLOR 0 (sara' modificato)
	dc.w	$3c07,$fffe	; aspettiamo la linea 156 (non modificato,ecc.)
	dc.w	$180		; REGISTRO COLOR0
col3:
	dc.w	$0b0		; VALORE DEL COLOR 0
	dc.w 	$3d07,$fffe	; aspettiamo la linea 157
	dc.w	$180		; REGISTRO COLOR0
col4:
	dc.w	$090		; VALORE DEL COLOR 0
	dc.w	$3e07,$fffe	; aspettiamo la linea 158
	dc.w	$180		; REGISTRO COLOR0
col5:
	dc.w	$070		; VALORE DEL COLOR 0
	dc.w	$3f07,$fffe	; aspettiamo la linea 159
	dc.w	$180		; REGISTRO COLOR0
col6:
	dc.w	$050		; VALORE DEL COLOR 0
	dc.w	$4007,$fffe	; aspettiamo la linea 160
	dc.w	$180		; REGISTRO COLOR0
col7:
	dc.w	$030		; VALORE DEL COLOR 0
	dc.w	$4107,$fffe	; aspettiamo la linea 161
	dc.w	$180		; color0... (ora avete capito i commenti,
col8:				; posso anche smettere di metterli da qua!)
	dc.w	$030
	dc.w	$4207,$fffe	; linea 162
	dc.w	$180
col9:
	dc.w	$050
	dc.w	$4307,$fffe	;  linea 163
	dc.w	$180
col10:
	dc.w	$070
	dc.w	$4407,$fffe	;  linea 164
	dc.w	$180
col11:
	dc.w	$090
	dc.w	$4507,$fffe	;  linea 165
	dc.w	$180
col12:
	dc.w	$0b0
	dc.w	$4607,$fffe	;  linea 166
	dc.w	$180
col13:
	dc.w	$0d0
	dc.w	$4707,$fffe	;  linea 167
	dc.w	$180
col14:
	dc.w	$0f0
	dc.w 	$4807,$fffe	;  linea 168

	dc.w 	$180,$0000	; Decidiamo il colore NERO per la parte
				; di schermo sotto l'effetto


	dc.w	$0180,$000	; color0
	ENDC
	dc.w	$0182,$550	; color1	; ridefiniamo il colore della
	dc.w	$0184,$ff0	; color2	; scritta COMMODORE! GIALLA!
	dc.w	$0186,$00F0	; color3
	dc.w	$0188,$990	; color4
	dc.w	$018a,$220	; color5
	dc.w	$018c,$770	; color6
	dc.w	$018e,$440	; color7

	IFD EFFECTS
	dc.w	$7007,$fffe	; Aspettiamo la fine della scritta COMMODORE

;	Gli 8 colori della figura sono definiti qui:

	dc.w	$0180,$000	; color0
	dc.w	$0182,$475	; color1
	dc.w	$0184,$fff	; color2
	dc.w	$0186,$ccc	; color3
	dc.w	$0188,$999	; color4
	dc.w	$018a,$232	; color5
	dc.w	$018c,$777	; color6
	dc.w	$018e,$444	; color7

;	EFFETTO DELLA LEZIONE3h.s

	dc.w	$9007,$fffe	; aspettiamo l'inizio della linea
	dc.w	$180,$000	; grigio al minimo, ossia NERO!!!
CopBar:
	dc.w	$9031,$fffe	; wait che cambiamo ($9033,$9035,$9037...)
	dc.w	$180,$100	; colore rosso
	dc.w	$9107,$fffe	; wait che non cambiamo (Inizio linea)
	dc.w	$180,$111	; colore GRIGIO (parte dall'inizio linea fino
	dc.w	$9131,$fffe	; a questo WAIT, che noi cambiaremo...
	dc.w	$180,$200	; dopo il quale comincia il ROSSO

;	    WAIT FISSI (poi grigio) - WAIT DA CAMBIARE (seguiti dal rosso)

	dc.w	$9207,$fffe,$180,$222,$9231,$fffe,$180,$300 ; linea 3
	dc.w	$9307,$fffe,$180,$333,$9331,$fffe,$180,$400 ; linea 4
	dc.w	$9407,$fffe,$180,$444,$9431,$fffe,$180,$500 ; linea 5
	dc.w	$9507,$fffe,$180,$555,$9531,$fffe,$180,$600 ; ....
	dc.w	$9607,$fffe,$180,$666,$9631,$fffe,$180,$700
	dc.w	$9707,$fffe,$180,$777,$9731,$fffe,$180,$800
	dc.w	$9807,$fffe,$180,$888,$9831,$fffe,$180,$900
	dc.w	$9907,$fffe,$180,$999,$9931,$fffe,$180,$a00
	dc.w	$9a07,$fffe,$180,$aaa,$9a31,$fffe,$180,$b00
	dc.w	$9b07,$fffe,$180,$bbb,$9b31,$fffe,$180,$c00
	dc.w	$9c07,$fffe,$180,$ccc,$9c31,$fffe,$180,$d00
	dc.w	$9d07,$fffe,$180,$ddd,$9d31,$fffe,$180,$e00
	dc.w	$9e07,$fffe,$180,$eee,$9e31,$fffe,$180,$f00
	dc.w	$9f07,$fffe,$180,$fff,$9f31,$fffe,$180,$e00
	dc.w	$a007,$fffe,$180,$eee,$a031,$fffe,$180,$d00
	dc.w	$a107,$fffe,$180,$ddd,$a131,$fffe,$180,$c00
	dc.w	$a207,$fffe,$180,$ccc,$a231,$fffe,$180,$b00
	dc.w	$a307,$fffe,$180,$bbb,$a331,$fffe,$180,$a00
	dc.w	$a407,$fffe,$180,$aaa,$a431,$fffe,$180,$900
	dc.w	$a507,$fffe,$180,$999,$a531,$fffe,$180,$800
	dc.w	$a607,$fffe,$180,$888,$a631,$fffe,$180,$700
	dc.w	$a707,$fffe,$180,$777,$a731,$fffe,$180,$600
	dc.w	$a807,$fffe,$180,$666,$a831,$fffe,$180,$500
	dc.w	$a907,$fffe,$180,$555,$a931,$fffe,$180,$400
	dc.w	$aa07,$fffe,$180,$444,$aa31,$fffe,$180,$301
	dc.w	$ab07,$fffe,$180,$333,$ab31,$fffe,$180,$202
	dc.w	$ac07,$fffe,$180,$222,$ac31,$fffe,$180,$103
	dc.w	$ad07,$fffe,$180,$113,$ad31,$fffe,$180,$004

	dc.w	$ae07,$FFFE	; prossima linea
	dc.w	$180,$006	; blu a 6
	dc.w	$b007,$FFFE	; salto 2 linee
	dc.w	$180,$007	; blu a 7
	dc.w	$b207,$FFFE	; sato 2 linee
	dc.w	$180,$008	; blu a 8
	dc.w	$b507,$FFFE	; salto 3 linee
	dc.w	$180,$009	; blu a 9
	dc.w	$b807,$FFFE	; salto 3 linee
	dc.w	$180,$00a	; blu a 10
	dc.w	$bb07,$FFFE	; salto 3 linee
	dc.w	$180,$00b	; blu a 11
	dc.w	$be07,$FFFE	; salto 3 linee
	dc.w	$180,$00c	; blu a 12
	dc.w	$c207,$FFFE	; salto 4 linee
	dc.w	$180,$00d	; blu a 13
	dc.w	$c707,$FFFE	; salto 7 linee
	dc.w	$180,$00e	; blu a 14
	dc.w	$ce07,$FFFE	; salto 6 linee
	dc.w	$180,$00f	; blu a 15
	dc.w	$d807,$FFFE	; salto 10 linee
	dc.w	$180,$11F	; schiarisco...
	dc.w	$e807,$FFFE	; salto 16 linee
	dc.w	$180,$22F	; schiarisco...

;	Effetto della lezione3f.s

	dc.w	$ffdf,$fffe	; ATTENZIONE! WAIT ALLA FINE LINEA $FF!
				; i wait dopo questo sono sotto la linea
				; $FF e ripartono da $00!!

	dc.w	$0107,$FFFE	; una barretta fissa verde SOTTO la linea $FF!
	dc.w	$180,$010
	dc.w	$0207,$FFFE
	dc.w	$180,$020
	dc.w	$0307,$FFFE
	dc.w	$180,$030
	dc.w	$0407,$FFFE
	dc.w	$180,$040
	dc.w	$0507,$FFFE
	dc.w	$180,$030
	dc.w	$0607,$FFFE
	dc.w	$180,$020
	dc.w	$0707,$FFFE
	dc.w	$180,$010
	dc.w	$0807,$FFFE
	dc.w	$180,$000

BARRA:
	dc.w	$0907,$FFFE	; aspetto la linea $79
	dc.w	$180,$300	; inizio la barra rossa: rosso a 3
	dc.w	$0a07,$FFFE	; linea seguente
	dc.w	$180,$600	; rosso a 6
	dc.w	$0b07,$FFFE
	dc.w	$180,$900	; rosso a 9
	dc.w	$0c07,$FFFE
	dc.w	$180,$c00	; rosso a 12
	dc.w	$0d07,$FFFE
	dc.w	$180,$f00	; rosso a 15 (al massimo)
	dc.w	$0e07,$FFFE
	dc.w	$180,$c00	; rosso a 12
	dc.w	$0f07,$FFFE
	dc.w	$180,$900	; rosso a 9
	dc.w	$1007,$FFFE
	dc.w	$180,$600	; rosso a 6
	dc.w	$1107,$FFFE
	dc.w	$180,$300	; rosso a 3
	dc.w	$1207,$FFFE
	dc.w	$180,$000	; colore NERO
	ENDC


	dc.w	$FFFF,$FFFE	; FINE DELLA COPPERLIST


; **************************************************************************
; *			FIGURA AD 8 COLORI 320x256			   *
; **************************************************************************

;	Ricordatevi di selezionare la directory dove si trova la figura
;	in questo caso basta scrivere: "V df0:SORGENTI2"

					; 3 bitplanes consecutivi
PIC:
        dcb.b 40*256*3,$01

Module1:
	;incbin "P61.sowhat-intro"			;usecode $9410
	incbin "P61.chippy_nr.399" ; usecode $945A
	even

	end


