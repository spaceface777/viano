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
	win_width       int = 1280
	win_height      int = 800
	key_width       f32 = 60
	key_height      f32 = 200
	white_key_count int
	keys            [128]Key
	start_note      byte = 36
	dragging        bool

	// info about the current song:
	// the notes that make it up
	notes []Note
	// the current timestamp (in ns)
	t     u64
	// the index of the first note currently being played in the song
	i     u32
	// the current song's length in ns
	song_len u64
}

struct Note {
mut:
	start u64
	len   u32
	midi  byte
	vel   byte
}

fn (n Note) str() string {
	a := int(n.midi)
	b := f64(n.start)  / time.second
	c := f64(n.start+n.len) / time.second
	return '\n  [$a] $b - $c'
}

enum KeyColor {
	black
	white
}

struct Key {
mut:
	sidx      u32
	sustained bool
	pressed   bool
}

// byte.is_playable returns true if a note is playable using a Boomwhackers set
[inline]
fn is_playable(n byte) bool {
	return n >= 48 && n <= 76
}

fn (mut app App) play_note(note byte, vol_ byte) {
	if app.keys[note].pressed { return }

	app.keys[note].pressed = true
	vol := f32(vol_) / 127
	app.audio.play(note, vol)
}

fn (mut app App) pause_note(note byte) {
	app.keys[note].pressed = false
	app.audio.pause(note)
}

[console]
fn main() {
	mut app := &App{}

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
		sample_count: 4
	)

	if os.args.len > 1 {
		app.parse_midi_file(os.args[1])  or {
			eprintln('failed to parse midi file `${os.args[1]}`: $err')
			return
		}

		mut song_len := u64(0)
		mut notes_needed := map[byte]u16{}
		for note in app.notes {
			if note.start + note.len > song_len {
				song_len = note.start + note.len
			}
			notes_needed[note.midi]++
		}
		app.song_len = song_len
		println('song length: ${f64(song_len) / 6e+10:.1f} minutes')

		notes_per_second := f64(app.notes.len) / f64(app.song_len) * f64(time.second)
		difficulties := ['easy', 'medium', 'hard', 'extreme']!
		println('total notes: $app.notes.len (${notes_per_second:.1f} notes/sec, difficulty: ${difficulties[clamp<byte>(byte(notes_per_second / 3.3), 0, 3)]})')

		mut keys := notes_needed.keys()
		keys.sort()

		println('required notes:')
		for k in keys {
			v := notes_needed[k]
			println(' ${midi2name(k):-20}$v')
		}

		go app.play()
	} else {
		eprintln('usage: viano <file.mid>')
		exit(1)
	}

	app.gg.run()
}
