import time

import vidi

[inline]
fn midi2name(midi byte) string {
	x := ['bass', 'mid', 'high']!
	oct := if is_playable(midi) { x[clamp(midi/12 - 4, 0, x.len-1)] } else { '(unplayable)' }
	note := note_names[midi%12]
	return '$oct $note'
}

// byte.is_playable returns true if a note is playable using a Boomwhackers set
[inline]
fn is_playable(n byte) bool {
	return n >= 48 && n <= 76
}

[inline]
fn (mut app App) play_note(note byte, vol_ byte) {
	if app.keys[note].pressed { return }

	app.keys[note].pressed = true
	vol := f32(vol_) / 127
	app.audio.play(note, vol)
}

[inline]
fn (mut app App) pause_note(note byte) {
	app.keys[note].pressed = false
	app.audio.pause(note)
}

[inline]
fn (mut app App) pause_all() {
	for note, mut key in app.keys {
		if key.pressed {
			key.pressed = false
			app.audio.pause(byte(note))
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
		for midi in 0 .. byte(app.keys.len) {
			app.pause_note(midi)
		}
	}
}

fn (mut app App) parse_midi_file(name string) ? {
	midi := vidi.parse_file(name) ?
	mut mpqn := u32(midi.micros_per_tick)
	mut cache := [128]Note{}
	mut sustained_notes := []Note{}
	mut is_sustain := false
	_ = is_sustain
	mut t := u64(0)
	for track in midi.tracks {
		mpqn = u32(midi.micros_per_tick)
		for event in track.data {
			t += event.delta_time * mpqn * u64(time.microsecond)
			match event {
				vidi.NoteOn, vidi.NoteOff {
					if event.velocity == 0 {
						// pause
						if cache[event.note].midi != event.note {
							eprintln('malformed midi file - releasing paused note')
							continue
						}
						cache[event.note].len = u32(t - cache[event.note].start)
						app.notes << cache[event.note]
						cache[event.note] = Note{}
					} else {
						// play
						cache[event.note] = {
							start: t
							midi: event.note
							vel: event.velocity
						}
					}
				}
				vidi.Controller {
						match event.controller_type {
							0x40, 0x17 {
								if event.value > 0x40 {
									is_sustain = true
								} else {
									is_sustain = false
									for mut note in sustained_notes {
										note.len = u32(t - note.start)
									}
									app.notes << sustained_notes
									sustained_notes.clear()
								}
							}
							else {
								// println('Control change (control=$control, value=$value)')
							}
						}

				}
				vidi.SetTempo {
					mpqn = u32(midi.mpqn(event.microseconds))
				}
				else {
					// println(event)
				}
			}
		}
		t = 0
	}
	app.notes.sort(a.start < b.start)
}

fn (mut app App) play() {
	mut sw := time.new_stopwatch({})
	for app.t < app.song_len + lookahead + u64(time.second) {
		time.sleep(50*time.microsecond)
		if app.paused {
			sw.restart()
			continue
		}
		app.t += u64(f64(sw.elapsed()) * app.tempo)
		sw.restart()
		mut is_at_start := true
		for i := app.i; i < app.notes.len ; i++ {
			note := app.notes[i]
			key := app.keys[note.midi]
			end := note.start + note.len

			lt := app.t - lookahead

			if is_at_start {
				if lt < app.t && note.start + note.len < lt {
					app.i++
				} else {
					is_at_start = false
				}
			}
			
			$if !unplayable ? {
				if !is_playable(note.midi) { continue }
			}

			if note.start <= lt && end > lt && !key.pressed {
				app.play_note(note.midi, note.vel)
				app.keys[note.midi].sidx = i
			}
			if key.sidx == i && end <= lt && key.pressed {
				app.pause_note(note.midi)
			}

			if note.start > lt { break }
		}
	}
	// exit(0)
}
