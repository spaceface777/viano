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
	sustained       bool
	win_width       int
	win_height      int
	key_width       f32
	key_height      f32
	white_key_count int
	keys            [128]Key
	start_note      byte = 36
	dragging        bool
}

enum KeyColor {
	black
	white
}

struct Keypress {
mut:
	start    i64
	end      i64
	velocity byte
}

struct Key {
mut:
	sustained   bool
	pressed     bool
	presses     []Keypress
}

fn (mut app App) play_note(note byte, vol_ byte) {
	if app.keys[note].pressed { return }

	// if a note is being sustained, but it is pressed and released, pause and play it again
	if app.sustained && app.keys[note].sustained && app.keys[note].presses.len > 0 {
		t := time.ticks()
		app.keys[note].presses[app.keys[note].presses.len - 1].end = t
		app.keys[note].presses << { start: t, velocity: vol_ }
	} else {
		app.keys[note].pressed = true
		app.keys[note].sustained = app.sustained
		app.keys[note].presses << { start: time.ticks(), velocity: vol_ }
	}

	vol := f32(vol_) / 127
	app.audio.play(note, vol)
}

fn (mut app App) pause_note(note byte) {
	mut key := unsafe { &app.keys[note] }

	if app.sustained {
		key.pressed = false
		key.sustained = true
	} else {
		if key.sustained && key.pressed {
			key.sustained = false
		} else {
			key.sustained = false
			key.pressed = false
			if key.presses.len > 0 && key.presses[key.presses.len - 1].end == 0 {
				key.presses[key.presses.len - 1].end = time.ticks()
			}
			app.audio.pause(note)
		}
	}
}

[console]
fn main() {
	mut app := &App{}
	// initialize arrays
	for mut key in app.keys {
		key.presses = []
	}

	app.audio = audio.new_context(wave_kind: .torgan)

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
		font_path: gg.system_font_path()
		// sample_count: 4
	)

	if os.args.len > 1 {
		app.play_midi_file(os.args[1])  or {
			eprintln('failed to parse midi file `${os.args[1]}`: $err')
			return
		}
	} else {
		app.open_midi_port() ?
	}

	app.gg.run()
}
