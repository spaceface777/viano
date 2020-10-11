
import audio
import os
import midi

struct App {
mut:
	input_ctx midi.Input
	audio_ctx &audio.Context
}

fn main() {
	input_ctx := midi.new_in()
    port_count := input_ctx.get_port_count()?
    println('There are $port_count ports')
    if port_count == 0 { exit(1) }

	for i in 0 .. port_count {
		name := input_ctx.get_port_name(i)?
		println(' $i: $name')
	}

	num := os.input('Enter port number: ').int()
	input_ctx.open_port(num, 'TEST IN')?
	println('Opened port $num successfully\n')

	audio_ctx := audio.new_context()

	mut app := &App{
		input_ctx: input_ctx
		audio_ctx: audio_ctx
	}

    for {
        buf, _ := input_ctx.get_message() or { continue }
		app.parse_midi_event(buf)
    }
}
