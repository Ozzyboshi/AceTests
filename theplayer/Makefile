all:
	vasmm68k_mot -devpac -Fhunkexe -quiet -esc  -m68000  -DUSE_DBLBUF -DUSE_VIDEOCHIP  -DUSE_3D ./P6112-Example.S  -o ./P6112-Example -I/usr/local/amiga/os-include && chmod 777 ./P6112-Example
	cp ./P6112-Example ./t && chmod 777 ./t


		vasmm68k_mot -devpac -Fhunkexe -quiet -esc  -m68000  -DUSE_DBLBUF -DUSE_VIDEOCHIP  -DUSE_3D ./r.s  -o ./r -I/usr/local/amiga/os-include && chmod 777 ./r
