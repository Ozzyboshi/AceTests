
;		#-----+-----------------------------------------#
;		|Name:|    	P6112 Example Source		|
;		+-----+-----------------------------------------+
;		|V1.06|	P6112,E1x/E2x fix			|
;		|V1.05|	P6111,Edx fix,init/exit patch,Dxx note. |
;		|V1.04|	P6110 final, E6x command fix+new option	|
;		|V1.03|	Final, compatibility changes only.	|
;		|V1.02|	Made more user friendly			|
;		|V1.01|	Plays the example P61 song until you 	|
;		|     |	press the left mouse button.		|
;		+-----+-----------------------------------------+
;		|	    	 Photon/Scoopex 		|
;		#-----------------------------------------------#

;Tutorial here: http://youtu.be/xBtHO-IuN9E
;Put it in your demo: http://youtu.be/JYLcIR6tyO4
;Relevant Protracker, P61, music, and code articles on http://coppershade.org

;I'm leaving the P61 project. Read sources and docs.
;I now strictly follow a "Don't ask, don't tell" policy :D

;(I know I said the same in P6111, but I made an exception because it would be 
;unnecessarily hard to spot the erroneous line for a coder coming in.)

;If the song works here but not in your demo, the playroutine is okay. Check 
;that you have selected the right mode. P61_Music is called automatically in 
;p61mode 1 (CIA interrupt, remember?),so don't call it anywhere in your source.

;older notes:

;NOTE: it is now extra important that you SET THE USECODE. See the Special Note
;in P6112-Play.i for why. TIP: using 80x for syncing (timing) instead of E8x
;won't make the song sound worse in non-legacy trackers. It's plug and play, 
;just swap them out.

;This example demonstrates simple syncing Set visuctrs=1 to see them :)
;There also 3 commands you can use for module-controller syncing (80x recommen-
;ded), and an oscilloscope ptrs option as well.

;This source demonstrates non-system, non-exec mode. (That means that it can 
;also be used in trackmos where you're using ALL low chipmem ;) )

;It uses an AGA compatible startup that shows a simple copper with a copper 
;interrupt request trigger that you poll in the frame loop to wait for a raster
;position. (I.e. you can turn it into a proper copper interrupt).

;Compatibility: You can assemble with or without Label: option.
;Any case-sensitivity and "special operators" issues should be gone.

;Esau/Traktor sent me a nice module to include (thanks!), if it's too big for 
;your chipmem left, try one of the smaller ones.


;IT CAN BE USED IN 4 MODES:
;-------------------------
; 1	CIA mode. Plays any song. Uses the CIA interrupt.
;	 - (default, P61_Music should not be called, easiest to use)

; 2	VBLANK mode. No F20 or higher commands must be used in the song.
;	 - (use when you want to decide when P61_Music should be called.)

; 3	COPPER mode. No F20 or higher commands must be used in the song.
;	 - (requires a timed call to P61_Music and a timed copper command 
;	    11 scanlines later to set sound DMA.)

; 4	MAXOPTI mode. No F20 or higher commands must be used in the song.
;	 - (requires a timed call to P61_Music and a timed copper command 
;	    11 scanlines later to set sound DMA. Maximum optimized.)


P61mode	=1	;Try other modes ONLY IF there are no Fxx commands >= 20.
		;(f.ex., P61.new_ditty only works with P61mode=1)


;;    ---  options common to all P61modes  ---

usecode	=-1	;CHANGE! to the USE hexcode from P61con for a big 
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

visuctrs=1	;enables visualizers in this example: P61_visuctr0..3.w 
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

********** CODE START **********
;(slightly) modified from CIA_Example.G in P6106, credits to original author.

	section	"P6112-Example",code

	movem.l	d0-a6,-(sp)
	move	$dff002,-(sp)		;Old DMA
	lea	gfxname(pc),a1		;Open graphics.library
	moveq	#0,d0
	move.l	4.w,a6
	jsr	-$228(a6)
	move.l	d0,a6
	move.l	34(a6),-(sp)		;Old view
	move.l	a6,-(sp)
	sub.l	a1,a1
	jsr	-$de(a6)		;LoadView
	jsr	-$10e(a6)		;WaitTOF
	jsr	-$10e(a6)		;WaitTOF

	lea	$dff000,a6
	move	#$7ff,$96(a6)		;Disable DMAs
	move	#%1000001111000000,$96(a6) ;Master,Copper,Blitter,Bitplanes
	move	$1c(a6),-(sp)		;Old IRQ
	move	#$7fff,$9a(a6)		;Disable IRQs
	move	#$e000,$9a(a6)		;Master and lev6
					;NO COPPER-IRQ!
	moveq	#0,d0
	move	d0,$106(a6)		;Disable AGA/ECS-stuff
	move	d0,$1fc(a6)

;;    ---  Call P61_Init  ---
	lea Module1,a0
	sub.l a1,a1
	sub.l a2,a2
	moveq #0,d0
	lea p61coppoke+3,a4		;only used in P61mode >=3
	jsr P61_Init

	move.l	#p61copper,$80(a6)

;;    ---  frame loop start  ---
wait:	move	$1e(a6),d0		;Wait for Copper-bit in INTREQR
	and.l	#$10,d0
	beq.b	wait
	move	#$10,$9c(a6)		;Clear the bit (poll)

	ifeq p61cia
	move	#$7f3,$180(a6)
	jsr P61_Music			;and call the playroutine manually.
	move	#$003,$180(a6)
	endc

;;    ---  your demo code start  ---

; ===>  Put some cool stuff here :)  <===

	ifne visuctrs
	lea P61_visuctr0(PC),a0
	lea p61visupoke+6,a1
	moveq #channels-1,d7
lol:	move.l #15,d0			;maxvalue
	sub.w (a0)+,d0			;-#frames/irqs since instrument trigger
	bpl.s .ok			;below minvalue?
	moveq #0,d0			;then set to minvalue
.ok:	move.w d0,(a1)			;poke blue color
	lea 16(a1),a1			;next colorline in copper.
	dbf d7,lol
	endc

;;    ---  your demo code end  ---

	btst	#6,$bfe001		;repeat until left mouse button pressed
	bne	wait

;;    ---  frame loop end  ---
	
exit:	btst	#6,2(a6)		;Wait for blitter to finish, if used.
	bne.b	exit

;;    ---  Call P61_End  ---
	jsr P61_End

;;    ---  exit  ---

	move	#$7fff,$9a(a6)		;Restore system status
	move	#$7ff,$96(a6)

	move	(sp)+,d7		;Old IRQs

	move.l	(sp)+,a6
	move.l	(sp)+,a1
	jsr	-$de(a6)		;Old view
	move.l	38(a6),d3		;3fd Copper1
	move.l	a6,a1
	move.l	4.w,a6
	jsr	-$19e(a6)		;CLOSE graphics.library

	lea	$dff000,a6
	move.l	d3,$80(a6)		;Set old Copper
	move	d3,$88(a6)		;Trigger

	or	#$8000,d7
	move	d7,$9a(a6)		;Old IRQs

	move	(sp)+,d7
	or	#$8000,d7
	move	d7,$96(a6)		;Old DMAs
	movem.l	(sp)+,d0-a6
	moveq	#0,d0			;No error code to CLI
	rts

********** DATA  **********

gfxname:
	dc.b	"graphics.library",0
	even

********** PLAYROUTINE CODE **********
;Note: if this is put in its own section (or compiled as separate binary), then
;jsr <addr>+P61_InitOffset,P61_MusicOffset,P61_EndOffset,P61_SetPositionOffset
;to call the routines.

Playrtn:
	include "P6112-Play.i"

********** CHIP DATA **********

	section	"CHIPDATA",data_c

p61copper:
	dc	$100,$0200
	dc	$180,$003
	dc	$800f,$fffe		;The line to wait to
	dc	$09c,$8010		;Set Copper-bit in INTREQ
;;    ---  set dma  ---			;(for instruments triggered this frame)
	dc	$8b0f,$fffe
p61coppoke:
	dc	$096,$8000		;sound DMA poke address (in P61mode>=3)

;;    ---  visualizers  ---
p61visupoke:
	dc.w	$f007,$fffe
	dc.w	$180,$003
	dc.w	$f107,$fffe
	dc.w	$180,$003

	dc.w	$f407,$fffe
	dc.w	$180,$003
	dc.w	$f507,$fffe
	dc.w	$180,$003

	dc.w	$f807,$fffe
	dc.w	$180,$003
	dc.w	$f907,$fffe
	dc.w	$180,$003

	dc.w	$fc07,$fffe
	dc.w	$180,$003
	dc.w	$fd07,$fffe
	dc.w	$180,$003

	dc.w	$ffff,$fffe

Module1:
;	incbin "P61.sowhat-intro"			;usecode $9410
;	incbin "P61.new_ditty"				;CIA, usecode $c00b43b
	incbin "P61.Dolphins-Dreamquest-by-Esau"	;CIA, usecode $1006bf5f
