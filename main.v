import os

import audio
import vidi

struct App {
mut:
	vidi            &vidi.Context = voidptr(0)
	audio           &audio.Context = voidptr(0)
	sustained_notes []byte
	is_sustain      bool
}

fn main() {
	mut app := &App{}

	app.vidi = vidi.new_ctx(callback: parse_midi_event, user_data: app) ?
    port_count := vidi.port_count()
    println('There are $port_count ports')
    if port_count == 0 { exit(1) }

	for i in 0 .. port_count {
		info := vidi.port_info(i)
		println(' $i: $info.manufacturer $info.name $info.model')
	}

	if port_count == 1 {
		app.vidi.open(0) ?
		println('\nOpened port 0, since it was the only available port\n')
	} else {
		num := os.input('\nEnter port number: ').int()
		app.vidi.open(num) ?
		println('Opened port $num successfully\n')
	}

	app.audio = audio.new_context(wave_kind: .triangle)
	
	os.input('Press enter to exit...')
}
