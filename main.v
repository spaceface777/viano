import os
import time
import audio
import midi

struct App {
mut:
	input_ctx       &midi.Input
	audio_ctx       &audio.Context
	sustained_notes []byte
	is_sustain      bool
}

const (
	port_name = 'V midi input'
)

fn main() {
	input_ctx := midi.new_in()
    port_count := input_ctx.get_port_count()?
    println('There are $port_count ports')
    if port_count == 0 { exit(1) }

	for i in 0 .. port_count {
		name := input_ctx.get_port_name(i)?
		println(' $i: $name')
	}

	if port_count == 1 {
		input_ctx.open_port(0, port_name)?
		println('\nOpened port 0, since it was the only available port\n')
	} else {
		num := os.input('\nEnter port number: ').int()
		input_ctx.open_port(num, port_name)?
		println('Opened port $num successfully\n')
	}

	audio_ctx := audio.new_context(wave_kind: .triangle)

	mut app := &App{
		input_ctx: input_ctx
		audio_ctx: audio_ctx
	}

    for {
        buf, _ := input_ctx.get_message() or { continue }
		app.parse_midi_event(buf)
		time.sleep_ms(3)
    }
}
