
import math
import miniaudio as ma
import os
import time
import midi

struct App {
mut:
	input   midi.Input
	device  &ma.Device
	samples map[string]&ma.Sound
}

fn main() {
	input := midi.new_in()
    count := input.get_port_count()?
    println('There are $count ports')
    if count == 0 { exit(1) }

	for i in 0 .. count {
		name := input.get_port_name(i)?
		println(' $i: $name')
	}

	num := os.input('Enter port number: ').int()
	input.open_port(num, 'TEST IN')?
	println('Opened port $num successfully\n')

	mut app := &App{
		input: input
		device: ma.device()
	}
	app.device.volume(0.5)

	for i := -12; i < 12; i++ {
		mut s := ma.sound_rate('./samples/60.wav', u32(44100 * math.powf(2, f32(i) / 12)))
		app.samples[(60 - i).str()] = s
		app.device.add((60 - i).str(), s)
	}

    for {
        buf, _ := input.get_message() or { continue }
		app.parse_midi_event(buf)
    }
}
