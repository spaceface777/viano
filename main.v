import gg
import os
import time

import audio
import vidi

struct App {
mut:
	gg              &gg.Context = voidptr(0)
	vidi            &vidi.Context = voidptr(0)
	audio           &audio.Context = voidptr(0)
	sustained_notes []byte
	is_sustain      bool
	win_width       int
	win_height      int
	key_width       f32
	key_height      f32
	white_key_count int
	keys            map[byte]Keypress
	start_note      byte = 36
	dragging        bool
}

[inline]
fn (mut app App) play_note(note byte, vol_ byte) {
	app.keys[note].pressed = true
	app.keys[note].press_times << { start: time.ticks() }
	freq := midi2freq(note)

	// // make the bass notes louder
	// vol := f32(vol_ + 20 * (128 - note)) / 127 / 8 // + (128 - note) 
	vol := f32(vol_) / 127 / 32
	app.audio.play(freq, vol)
}

[inline]
fn (mut app App) pause_note(note byte) {
	app.keys[note].pressed = false
	if app.keys[note].press_times.len > 0 {
		app.keys[note].press_times[app.keys[note].press_times.len - 1].end = time.ticks()
	}
	freq := midi2freq(note)
	app.audio.pause(freq)
}

[console]
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
		for i in 0 .. port_count {
			if _ := app.vidi.open(i) { break } // or {}
			else {}
		}
		// num := os.input('\nEnter port number: ').int()
		// app.vidi.open(num) ?
		// println('Opened port $num successfully\n')
	}

	app.audio = audio.new_context(wave_kind: .triangle)

	app.gg = gg.new_context(
		bg_color: bg_color
		width: win_width
		height: win_height
		create_window: true
		window_title: 'Viano'
		init_fn: init
		frame_fn: frame
		event_fn: event
		user_data: app
		sample_count: 2
	)
	app.gg.run()
}
