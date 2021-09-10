bin_PROGRAMS = ammx2drotations
ammx2drotations_LDADD = ammxasm.o music_ptr_linkable2.o
ammx2drotations_SOURCES = main.c ammx2drotations.c

ammxasm.o: ammxasm.s
	
	vasmm68k_mot -devpac -Fhunk -quiet -esc  -DUSE_DBLBUF -DUSE_VIDEOCHIP -DUSE_CLIPPING -DUSE_3D ./ammxasm.s  -o ./ammxasm.o -I/usr/local/amiga/os-include
	 echo "m68k"
	echo "	vasmm68k_mot -devpac -Fhunk -quiet -esc  -m68080 -DUSE_VIDEOCHIP -DUSE_CLIPPING -DUSE_3D ./ammxasm.s  -o ./ammxasm.o -I/usr/local/amiga/os-include"

music_ptr_linkable2.o: music_ptr_linkable2.s
	vasmm68k_mot -devpac -unnamed-sections -chklabels -Fhunk -quiet -esc  -DINTERLACE=0 ./music_ptr_linkable2.s  -o ./music_ptr_linkable2.o -I/opt/amiga/m68k-amigaos/ndk-include/
