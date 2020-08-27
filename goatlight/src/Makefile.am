bin_PROGRAMS = goatlight
goatlight_LDADD = music_ptr_linkable.o
goatlight_SOURCES = main.c goatlight.c simplebuffertest.c sprites.c physics.c

music_ptr_linkable.o: music_ptr_linkable.s
	vasmm68k_mot -Fhunk -quiet -esc  -DINTERLACE=0 ./music_ptr_linkable.s  -o ./music_ptr_linkable.o -I/usr/local/amiga/os-include
