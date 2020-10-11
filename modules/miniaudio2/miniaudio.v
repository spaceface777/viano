module miniaudio2

$if linux && tinyc {
	// most Linux distributions have /usr/lib/libatomic.so, but Ubuntu uses gcc version specific dir
	#flag -L/usr/lib/gcc/x86_64-linux-gnu/8 -L/usr/lib/gcc/x86_64-linux-gnu/9 -latomic
}

// #flag -I ./miniaudio/c // for the wrapper code
#flag -I @VROOT/modules/miniaudio2

#flag -D MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"

struct C.ma_waveform {}

