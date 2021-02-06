# viano
MIDI piano V app, including dedicated midi input and audio modules. Supports generating sound waves (sine/triangle/sawtooth/square), and automatic loading and repitching (soon) of audio samples


### Usage

`v -cc tcc -cg run src/` for compiling/running a debug binary;  
`v -prod -compress -o vmidi src/` for compiling a production binary

### External Dependencies

None - all libraries used are written in V, and only have the standard dependencies required by the V standard library modules :)
Previous versions depended on rtmidi, but viano now uses [vidi](https://github.com/vmulti/vidi), a pure-V realtime midi library.
