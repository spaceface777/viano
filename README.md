# viano
MIDI piano V app. Visualizes and plays a MIDI file (similarly to Synthesia).

https://user-images.githubusercontent.com/12110214/118543500-9d5a2a80-b754-11eb-8cc3-e45e60d6f3aa.mp4

### Usage

`v -cg run .` for compiling/running a debug binary;  
`v -prod -skip-unused -compress -o vmidi .` for compiling a production binary

### External Dependencies

This module does not depend on any C libraries outside of those needed by the V standard library.
This means that on some linux distros, you may need to install the `alsa` development package

Debian/Ubuntu: `sudo apt install libasound2-dev libxi-dev libxcursor-dev`

If you've ever used V's graphical modules (for example, ran one of the graphical examples such as tetris or 2048) or V UI, you most likely already have these dependencies installed.
