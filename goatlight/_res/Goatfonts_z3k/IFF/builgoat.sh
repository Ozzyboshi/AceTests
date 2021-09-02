#!/bin/bash

FILES=( "SPACE" "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z" "0" "1" "2")

rm -f *.raw
touch goatfonts.raw

for FILE in "${FILES[@]}"
{
	ilbm2raw "$FILE.iff"  "$FILE.raw"
	dd if="$FILE.raw" of="$FILE.bpl1" bs=128 count=1
	dd if="$FILE.raw" of="$FILE.bpl2" bs=128 count=1 skip=1
}

for FILE in "${FILES[@]}"
{
	cat "$FILE.bpl1" >> goatfonts.raw
}

for FILE in "${FILES[@]}"
{
	cat "$FILE.bpl2" >> goatfonts.raw
}

incbin.sh goatfonts.raw goatfonts.h goatfonts

# ilbm2raw SPACE  space.raw
# ilbm2raw A A.raw
# ilbm2raw B B.raw