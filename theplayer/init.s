SAVE_FILL_TABLE2 MACRO
                        lea                    FILL_TABLE,a0
                        move.l                 FILLTABLES_ADDR_START,a1
                        move.l                 #4*257,d0
                        mulu.w                 \1,d0
                        adda.l                 d0,a1
                        move.w                 AMMXFILLTABLE_CURRENT_ROW,(a1)+
                        move.w                 AMMXFILLTABLE_END_ROW,(a1)+
                        move.w                 #255,d3
.1\@:
                        move.l                 (a0)+,(a1)+
                        dbra                   d3,.1\@
                        ENDM

FILLTABLES_ADDR_START:  dc.l                   0
FILLTABLES_ADDR_END:    dc.l                   0
FILLTABLES_PTR:         dc.l                   0

_ammxmainloop3_init:
                        movem.l                d0-d7/a0-a6,-(sp)
                        move.l                 #4*257*360,d0
                        jsr                    allocdef
                        move.l                 d0,FILLTABLES_ADDR_START
                        add.l                  #4*257*360,d0
                        move.l                 d0,FILLTABLES_ADDR_END

                ;move.l #4*257*360,d0
                ;move.l FILLTABLES_ADDR_START,a0
                ;jsr freemem

                        move.l                 #ammx_fill_table_noreset,AMMX_FILL_FUNCT_ADDR
                        LOADIDENTITY
                        VERTEX_INIT            1,#0,#-50,#0
                        VERTEX_INIT            2,#50,#50,#0
                        VERTEX_INIT            3,#-50,#50,#0
                        bsr.w                  BULD_FILLTABLE                  
                  
                        move.l                 FILLTABLES_ADDR_START,FILLTABLES_PTR
                        movem.l                (sp)+,d0-d7/a0-a6

                        rts

allocdef:                                                ; subroutine for allocating memory - first fast then chip. ML: d0 = allocdef(d0).
                        movem.l                d1-d7/a0-a6,-(a7)                                ; push registers on the stack
                        moveq                  #1,d1                                            ; trick to quickly get $#10000
                        swap                   d1                                               ; set d1 to MEMF_CLEAR initialize memory to all zeros
                        move.l                 $4,a6                                            ; fetch base pointer for exec.library
                        jsr                    -198(a6)                                         ; call AllocMem. d0 = AllocMem(d0,d1)
                        movem.l                (a7)+,d1-d7/a0-a6                                ; pop registers from the stack
                        rts

freemem:                    ; subroutine for deallocating. ML: freemem(a1,d0).
                        movem.l                d0-d7/a0-a6,-(a7)                                ; push registers on the stack
                        move.l                 a0,a1                                            ; set a1 to the memory block to free
                        move.l                 $4,a6                                            ; fetch base pointer for exec.library
                        jsr                    -210(a6)                                         ; call FreeMem. FreeMem(a1,d0)
                        movem.l                (sp)+,d0-d7/a0-a6                                ; pop registers from the stack
                        rts

BULD_FILLTABLE:
                        movem.l                d0-d7/a0-a6,-(sp)
                        move.w                 #360-1,d5
                        moveq                  #0,d6
BULD_FILLTABLE_START:
                        RESETFILLTABLE
                        bsr.w                  BULD_ROTATION
        ;SAVE_FILL_TABLE d6
                        SAVE_FILL_TABLE2       d6
                        addq                   #1,d6
                        dbra                   d5,BULD_FILLTABLE_START
                        movem.l                (sp)+,d0-d7/a0-a6
                        rts

BULD_ROTATION:
                        movem.l                d0-d7/a0-a6,-(sp)
                        LOADIDENTITY
                        ROTATE_X_INV_Q_5_11    d6
                        jsr                    TRIANGLE3D_NODRAW
                        movem.l                (sp)+,d0-d7/a0-a6
                        rts
