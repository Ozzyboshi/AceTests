
	XDEF _matrix_test1
	XDEF _matrix_test2
	XDEF _matrix_test3
	XDEF _matrix_test4
	
	SECTION PROCESSING,CODE_F

	include "../../../libs/ammxmacros.i"
	include "../../../libs/matrix/matrix.s"

_matrix_test1:
	RESET_CURRENT_TRANSFORMATION_MATRIX_Q_10_6
	IFD VAMPIRE
	LOAD_CURRENT_TRANSFORMATION_MATRIX e1,e2,e3
	AMMX_DUMP_TRANSFORMATION_MATRIX_TO_RAM_OP1 e1,e2,e3
	ENDIF
	IFND VAMPIRE
	LOAD_CURRENT_TRANSFORMATION_MATRIX OPERATOR1_TR_MATRIX_ROW1
	ENDIF

	bsr.w processing_first_matrix_addr

	rts

_matrix_test2:
	RESET_CURRENT_TRANSFORMATION_MATRIX_Q_10_6
	IFD VAMPIRE
	LOAD_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6
	AMMX_DUMP_TRANSFORMATION_MATRIX_TO_RAM_OP2 e4,e5,e6
	ENDIF
	IFND VAMPIRE
	LOAD_CURRENT_TRANSFORMATION_MATRIX OPERATOR2_TR_MATRIX_ROW1
	ENDIF

	bsr.w processing_second_matrix_addr

	rts
	
_matrix_test3:
	IFD VAMPIRE
	REG_LOADI 0000,0040,0040,0040,e4
	REG_LOADI 0000,0040,0040,0040,e5
	REG_LOADI 0000,0040,0040,0040,e6
	UPDATE_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6
	AMMX_DUMP_TRANSFORMATION_MATRIX_TO_RAM_OP1 e4,e5,e6
	ENDIF
	IFND VAMPIRE
	move.l #$00000040,OPERATOR1_TR_MATRIX_ROW1
	move.l #$00400040,OPERATOR1_TR_MATRIX_ROW1+4
	move.l #$00000040,OPERATOR1_TR_MATRIX_ROW2
	move.l #$00400040,OPERATOR1_TR_MATRIX_ROW2+4
	move.l #$00000040,OPERATOR1_TR_MATRIX_ROW3
	move.l #$00400040,OPERATOR1_TR_MATRIX_ROW3+4

	UPDATE_CURRENT_TRANSFORMATION_MATRIX OPERATOR1_TR_MATRIX_ROW1,OPERATOR1_TR_MATRIX_ROW2,OPERATOR1_TR_MATRIX_ROW3
	ENDIF

	bsr.w processing_first_matrix_addr

	rts

_matrix_test4:
	IFD VAMPIRE
	REG_LOADI 0000,0040,0040,0040,e4
	REG_LOADI 0000,0040,0040,0040,e5
	REG_LOADI 0000,0040,0040,0040,e6
	UPDATE_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6
	AMMX_DUMP_TRANSFORMATION_MATRIX_TO_RAM_OP1 e4,e5,e6
	ENDIF
	IFND VAMPIRE
	move.l #$00000040,OPERATOR1_TR_MATRIX_ROW1
	move.l #$00400040,OPERATOR1_TR_MATRIX_ROW1+4
	move.l #$00000040,OPERATOR1_TR_MATRIX_ROW2
	move.l #$00400040,OPERATOR1_TR_MATRIX_ROW2+4
	move.l #$00000040,OPERATOR1_TR_MATRIX_ROW3
	move.l #$00400040,OPERATOR1_TR_MATRIX_ROW3+4

	UPDATE_CURRENT_TRANSFORMATION_MATRIX OPERATOR1_TR_MATRIX_ROW1,OPERATOR1_TR_MATRIX_ROW2,OPERATOR1_TR_MATRIX_ROW3
	ENDIF

	PUSHMATRIX

	IFD VAMPIRE
	REG_LOADI 0000,0080,0080,0080,e4
	REG_LOADI 0000,0080,0080,0080,e5
	REG_LOADI 0000,0080,0080,0080,e6
	UPDATE_CURRENT_TRANSFORMATION_MATRIX e4,e5,e6
	AMMX_DUMP_TRANSFORMATION_MATRIX_TO_RAM_OP1 e4,e5,e6
	ENDIF
	IFND VAMPIRE
	move.l #$00000080,OPERATOR1_TR_MATRIX_ROW1
	move.l #$00800080,OPERATOR1_TR_MATRIX_ROW1+4
	move.l #$00000080,OPERATOR1_TR_MATRIX_ROW2
	move.l #$00800080,OPERATOR1_TR_MATRIX_ROW2+4
	move.l #$00000080,OPERATOR1_TR_MATRIX_ROW3
	move.l #$00800080,OPERATOR1_TR_MATRIX_ROW3+4

	UPDATE_CURRENT_TRANSFORMATION_MATRIX OPERATOR1_TR_MATRIX_ROW1,OPERATOR1_TR_MATRIX_ROW2,OPERATOR1_TR_MATRIX_ROW3
	ENDIF

	POPMATRIX

	IFD VAMPIRE
	AMMX_DUMP_TRANSFORMATION_MATRIX_TO_RAM_OP1 e4,e5,e6
	ENDIF

	bsr.w processing_current_transformation_matrix_addr
	rts

