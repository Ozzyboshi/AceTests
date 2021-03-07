bin_PROGRAMS = mmxline
mmxline_LDADD = ammxasm.o
mmxline_SOURCES = main.c mmxline.c

ammxasm.o: ammxasm.s
	vasmm68k_mot -devpac -Fhunk -quiet -esc  -m68080 -DINTERLACE=0 ./ammxasm.s  -o ./ammxasm.o -I/usr/local/amiga/os-include
