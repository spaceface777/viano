import math
import time

import vidi


[inline]
fn midi2freq(midi byte) f32 {
	return int(math.powf(2, f32(midi - 69) / 12) * 440)
}

fn parse_midi_event(buf []byte, timestamp f64, mut app App) {
	if buf.len < 1 { return }
	// println('Read $buf.len MIDI bytes: $buf.hex()')

	status, channel := buf[0] & 0xF0, buf[0] & 0x0F
	_ = channel
	match status {
		0x80 /* note down */, 0x90 /* note up */ {
			app.note_down(buf[1] & 0x7F, buf[2] & 0x7F)
		} 0xB0 /* control change */ {
			app.control_change(buf[1] & 0x7F, buf[2] & 0x7F)
		} else {
			println('Unknown MIDI event `$status`')
		}
	}
}

fn (mut app App) note_down(note byte, velocity byte) {
	if velocity == 0 {
		app.pause_note(note)
	} else {
		app.play_note(note, velocity)
	}
}

fn (mut app App) control_change(control byte, value byte) {
	match control {
		0x40, 0x17 {
			if value > 0x40 { app.sustain() } else { app.unsustain() }
		}
		else {
			println('Control change (control=$control, value=$value)')
		}
	}
}

fn (mut app App) sustain() {
	if !app.sustained {
		app.sustained = true
		for mut note in app.keys {
			if note.pressed {
				note.sustained = true
			}
		}
	}
}

fn (mut app App) unsustain() {
	if app.sustained {
		app.sustained = false
		for midi, _ in app.keys {
			app.pause_note(byte(midi))
		}
	}
}

fn (mut app App) play_midi_file(name string) ? {
	midi := vidi.parse_file(name) ?
	// for track in midi.tracks {
		// go app.play_midi_track(track, i64(midi.micros_per_tick))
	// }
	go app.play_midi_track(midi, 0)
}

fn (mut app App) play_midi_track(midi vidi.Midi, i int) {
	mut mpqn := i64(midi.micros_per_tick)
	for event in midi.tracks[i].data {
		match event {
			vidi.NoteOn, vidi.NoteOff {
				sleep := i64(event.delta_time) * mpqn * time.microsecond
				time.sleep(sleep)
				app.note_down(event.note, event.velocity)
			}
			vidi.Controller {
				app.control_change(event.controller_type, event.value)
			}
			vidi.SetTempo {
				mpqn = midi.mpqn(event.microseconds)
			}
			else {}
		}
	}
}

fn (mut app App) open_midi_port() ? {
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
		for i in 0 .. port_count {
			if _ := app.vidi.open(i) { break } // or {}
			else {}
		}
		// num := os.input('\nEnter port number: ').int()
		// app.vidi.open(num) ?
		// println('Opened port $num successfully\n')
	}
}
