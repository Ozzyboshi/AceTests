bin_PROGRAMS = ammx2drotations
ammx2drotations_LDADD = ammxasm.o
ammx2drotations_SOURCES = main.c ammx2drotations.c

ammxasm.o: ammxasm.s
	vasmm68k_mot -devpac -Fhunk -quiet -esc  -m68080  -DUSE_CLIPPING -DUSE_3D ./ammxasm.s  -o ./ammxasm.o -I/usr/local/amiga/os-include

