bin_PROGRAMS = ammx
ammx_LDADD =  ammxasm.o
ammx_SOURCES = main.c ammx.c

ammxasm.o: ammxasm.s
	vasmm68k_mot -devpac -Fhunk -quiet -esc  -m68080 -DINTERLACE=0 ./ammxasm.s  -o ./ammxasm.o -I/usr/local/amiga/os-include