X_SCREEN_RES:         dc.w      320
X_SCREEN_RES_LAST_X:  dc.w      319

GLOBAL_OPTIONS:
                      dc.l      $00000000
                      dc.w      $0000
DRAWING_OPTIONS:      dc.b      $00                           ; bit 0 = clipping enabled
STROKE_DATA:          dc.b      $01                           ; colors here

AMMX_FILL_FUNCT_ADDR    dc.l ammx_fill_table
STROKE MACRO
                      IFD       VAMPIRE 
                      PAND      #$FFFFFFFFFFFFFF00,e22,e22    ; last byte zeroed
                      POR       \1,e22,e22                    ; last byte reserved for bitplanes
                      ENDIF
                      move.b    \1,STROKE_DATA
                      ENDM

                      IFD       USE_CLIPPING
ENABLE_CLIPPING MACRO
                      IFD       VAMPIRE
                      POR       #$0000000000000100,e22,e22
                      ENDIF
                      IFND      VAMPIRE
                      ori.b     #$01,DRAWING_OPTIONS
                      ENDIF
                      move.l  #ammx_fill_table_clip,AMMX_FILL_FUNCT_ADDR
                      ENDM
DISABLE_CLIPPING MACRO
                      move.w #0,LINEVERTEX_CLIP_X_OFFSET
                      IFD       VAMPIRE
                      PAND      #$FFFFFFFFFFFFFEFF,e22,e22
                      ENDIF
                      IFND      VAMPIRE
                      andi.b    #$FE,DRAWING_OPTIONS
                      ENDIF
                      move.l  #ammx_fill_table,AMMX_FILL_FUNCT_ADDR
                      ENDM
                      ENDIF

MINUWORD MACRO
                      cmp.w     \2,\1
                      bhi.s     .1\@
                      move.w    \1,\2
.1\@
                      ENDM

MAXUWORD MACRO
                      cmp.w     \2,\1
                      bcs.s     .1\@
                      move.w    \1,\2
.1\@
                      ENDM
FILLTABLE_FRAME_MIN_Y: dc.w -1
FILLTABLE_FRAME_MAX_Y: dc.w 0

SAVEFILLTABLE MACRO
    lea FILL_TABLE,a0
    lea FILLTABLES,a1
    adda.l #4*257*\1,a1
    move.w AMMXFILLTABLE_CURRENT_ROW,(a1)+
    move.w AMMXFILLTABLE_END_ROW,(a1)+
    move.w #255,d3
.1\@:
    move.l (a0)+,(a1)+
    dbra d3,.1\@
    ENDM

SAVE_FILL_TABLE MACRO
    lea FILL_TABLE,a0
    lea FILLTABLES,a1
    move.l #4*257,d0
    mulu.w \1,d0
    adda.l d0,a1
    move.w AMMXFILLTABLE_CURRENT_ROW,(a1)+
    move.w AMMXFILLTABLE_END_ROW,(a1)+
    move.w #255,d3
.1\@:
    move.l (a0)+,(a1)+
    dbra d3,.1\@
    ENDM

SAVE_FILL_TABLE2 MACRO
    lea FILL_TABLE,a0
    move.l FILLTABLES_ADDR_START,a1
    move.l #4*257,d0
    mulu.w \1,d0
    adda.l d0,a1
    move.w AMMXFILLTABLE_CURRENT_ROW,(a1)+
    move.w AMMXFILLTABLE_END_ROW,(a1)+
    move.w #255,d3
.1\@:
    move.l (a0)+,(a1)+
    dbra d3,.1\@
    ENDM