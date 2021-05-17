# viano
MIDI piano V app. Visualizes and plays a MIDI file (similarly to Synthesia).

https://user-images.githubusercontent.com/12110214/118543500-9d5a2a80-b754-11eb-8cc3-e45e60d6f3aa.mp4

### Usage

`v -cg run .` for compiling/running a debug binary;  
`v -prod -skip-unused -compress -o vmidi .` for compiling a production binary

### External Dependencies

None - all libraries used are written in V, and only have the standard dependencies required by the V standard library modules :)
Previous versions depended on rtmidi, but viano now uses [vidi](https://github.com/vmulti/vidi), a pure-V realtime midi library.
