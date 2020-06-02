bin_PROGRAMS = 3dstarfield
3dstarfield_LDADD = drawline_ptr_linkable.o music_ptr_linkable.o
3dstarfield_SOURCES = main.c 3dstarfield.c

drawline_ptr_linkable.o: drawline_ptr_linkable.s
	vasmm68k_mot -Fhunk -quiet -esc  -DINTERLACE=0 ./drawline_ptr_linkable.s  -o ./drawline_ptr_linkable.o -I/usr/local/amiga/os-include

music_ptr_linkable.o: music_ptr_linkable.s
	vasmm68k_mot -Fhunk -quiet -esc  -DINTERLACE=0 ./music_ptr_linkable.s  -o ./music_ptr_linkable.o -I/usr/local/amiga/os-include
