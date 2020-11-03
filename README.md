# viano
MIDI piano V app, including dedicated midi input and audio modules. Supports generating sound waves (sine/triangle/sawtooth/square), and automatic loading and repitching (soon) of audio samples


### Usage

`v -cc tcc -cg run src/` for compiling/running a debug binary;  
`v -prod -compress -o vmidi src/` for compiling a production binary

### Dependencies

For now, you will need `librtmidi` installed for midi input. This dependency will be removed eventually, but for now you'll need to e.g. `sudo apt install librtmidi4`
