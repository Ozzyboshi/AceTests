bin_PROGRAMS = deletepartimage
deletepartimage_LDADD = drawline_ptr_linkable.o
deletepartimage_SOURCES = main.c deletepartimage.c

drawline_ptr_linkable.o: drawline_ptr_linkable.s
	vasmm68k_mot -Fhunk -quiet -esc  -DINTERLACE=0 ./drawline_ptr_linkable.s  -o ./drawline_ptr_linkable.o -I/usr/local/amiga/os-include
