#!/bin/bash

FILES=( "Space" "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z" "0" "1" "2")


# FILES=( "A" "B" )
FILEOUT="goatfonts48"

rm -f *.raw
touch "$FILEOUT.raw"

for FILE in "${FILES[@]}"
{
	ilbm2raw "$FILE.iff"  "$FILE.raw"
	dd if="$FILE.raw" of="$FILE.bpl1" bs=252 count=1 status=none
	dd if="$FILE.raw" of="$FILE.bpl2" bs=252 count=1 skip=1 status=none
}

echo "inizio spacchettamento"
for FILE in "${FILES[@]}"
{
	
	echo "processo file $FILE"
	for (( c=0; c<=41; c++ ))
	do  
		CMD="dd if=$FILE.bpl1 of=$FILE.spr1.bpl1.raw bs=2 count=1 skip=$((c*3)) oflag=append conv=notrunc status=none"
		RES=`$CMD`
		#echo "$CMD"
		CMD="dd if=$FILE.bpl2 of=$FILE.spr1.bpl2.raw bs=2 count=1 skip=$((c*3)) oflag=append conv=notrunc status=none"
		RES=`$CMD`
		#echo "$CMD"

		# first sprite combined
		CMD="dd if=$FILE.bpl1 of=$FILE.spr1.combined.raw bs=2 count=1 skip=$((c*3)) oflag=append conv=notrunc status=none"
		RES=`$CMD`
		CMD="dd if=$FILE.bpl2 of=$FILE.spr1.combined.raw bs=2 count=1 skip=$((c*3)) oflag=append conv=notrunc status=none"
		RES=`$CMD`
		#echo "$CMD"
		

		CMD="dd if=$FILE.bpl1 of=$FILE.spr2.bpl1.raw bs=2 count=1 skip=$((c*3+1)) oflag=append conv=notrunc status=none"
		RES=`$CMD`
		#echo "$CMD"
		CMD="dd if=$FILE.bpl2 of=$FILE.spr2.bpl2.raw bs=2 count=1 skip=$((c*3+1)) oflag=append conv=notrunc status=none"
		RES=`$CMD`
		#echo "$CMD"

		# second sprite combined
		CMD="dd if=$FILE.bpl1 of=$FILE.spr2.combined.raw bs=2 count=1 skip=$((c*3+1)) oflag=append conv=notrunc status=none"
		RES=`$CMD`
		CMD="dd if=$FILE.bpl2 of=$FILE.spr2.combined.raw bs=2 count=1 skip=$((c*3+1)) oflag=append conv=notrunc status=none"
		RES=`$CMD`
		#echo "$CMD"

		CMD="dd if=$FILE.bpl1 of=$FILE.spr3.bpl1.raw bs=2 count=1 skip=$((c*3+2)) oflag=append conv=notrunc status=none"
		RES=`$CMD`
		#echo "$CMD"
		CMD="dd if=$FILE.bpl2 of=$FILE.spr3.bpl2.raw bs=2 count=1 skip=$((c*3+2)) oflag=append conv=notrunc status=none"
		RES=`$CMD`
		#echo "$CMD"

		# third sprite combined
		CMD="dd if=$FILE.bpl1 of=$FILE.spr3.combined.raw bs=2 count=1 skip=$((c*3+2)) oflag=append conv=notrunc status=none"
		RES=`$CMD`
		CMD="dd if=$FILE.bpl2 of=$FILE.spr3.combined.raw bs=2 count=1 skip=$((c*3+2)) oflag=append conv=notrunc status=none"
		RES=`$CMD`
		#echo "$CMD"
	done

	echo incbin.sh "${FILE}.spr1.combined.raw"  "${FILE}_1_combined.h"  "${FILE}_1_combined"
	incbin.sh "${FILE}.spr1.combined.raw"  "${FILE}_1_combined.h"  "${FILE}_1_combined"

	echo incbin.sh "${FILE}.spr2.combined.raw"  "${FILE}_2_combined.h"  "${FILE}_2_combined"
	incbin.sh "${FILE}.spr2.combined.raw"  "${FILE}_2_combined.h"  "${FILE}_2_combined"

	echo incbin.sh "${FILE}.spr3.combined.raw"  "${FILE}_3_combined.h"  "${FILE}_3_combined"
	incbin.sh "${FILE}.spr3.combined.raw"  "${FILE}_3_combined.h"  "${FILE}_3_combined"


	cat $FILE.spr1.bpl1.raw >> $FILEOUT.raw
	cat $FILE.spr1.bpl2.raw >> $FILEOUT.raw

	cat $FILE.spr2.bpl1.raw >> ${FILEOUT}_2.raw
	cat $FILE.spr2.bpl2.raw >> ${FILEOUT}_2.raw

	cat $FILE.spr3.bpl1.raw >> ${FILEOUT}_3.raw
	cat $FILE.spr3.bpl2.raw >> ${FILEOUT}_3.raw
}

#for FILE in "${FILES[@]}"
#{
#	cat $FILE.spr1.bpl2.raw >> $FILEOUT.raw
#
#	cat $FILE.spr2.bpl2.raw >> ${FILEOUT}_2.raw

#	cat $FILE.spr3.bpl2.raw >> ${FILEOUT}_3.raw
#}

echo incbin.sh "${FILEOUT}.raw"  "${FILEOUT}_1.h"  "${FILEOUT}_1"
incbin.sh "${FILEOUT}.raw"  "${FILEOUT}_1.h"  "${FILEOUT}_1"

echo incbin.sh "${FILEOUT}_2.raw"  "${FILEOUT}_2.h"  "${FILEOUT}_2"
incbin.sh "${FILEOUT}_2.raw"  "${FILEOUT}_2.h"  "${FILEOUT}_2"

echo incbin.sh "${FILEOUT}_3.raw"  "${FILEOUT}_3.h"  "${FILEOUT}_3"
incbin.sh "${FILEOUT}_3.raw"  "${FILEOUT}_3.h"  "${FILEOUT}_3"

# ilbm2raw SPACE  space.raw
# ilbm2raw A A.raw
# ilbm2raw B B.raw