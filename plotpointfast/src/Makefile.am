bin_PROGRAMS = plotpointfast
plotpointfast_LDADD = plotpointfastasm.o
plotpointfast_SOURCES = main.c plotpointfast.c 

plotpointfastasm.o: plotpointfastasm.s
	vasmm68k_mot -Fhunk -quiet -esc  -DINTERLACE=0 ./plotpointfastasm.s  -o ./plotpointfastasm.o -I/usr/local/amiga/os-include