bin_PROGRAMS = ammxmatrix
ammxmatrix_LDADD = ammxasm.o
ammxmatrix_SOURCES = main.c ammxmatrix.c

ammxasm.o: ammxasm.s
	vasmm68k_mot -devpac -Fhunk -quiet -esc  -m68080 -DINTERLACE=0 ./ammxasm.s  -o ./ammxasm.o -I/usr/local/amiga/os-include
