bin_PROGRAMS = metaballschunky8
metaballschunky8_LDADD = music_ptr_linkable.o
metaballschunky8_SOURCES = main.c metaballschunky8.c

music_ptr_linkable.o: music_ptr_linkable.s
	vasmm68k_mot -Fhunk -quiet -esc  -DINTERLACE=0 ./music_ptr_linkable.s  -o ./music_ptr_linkable.o -I/usr/local/amiga/os-include