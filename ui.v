import gg
import gx
import time

const (
	win_width  = 1260
	win_height = 800
)

const (
	default_key_width = 60
	min_key_height    = 128
	max_key_height    = 2./3
)

const (
	bg_color        = gx.rgb(24, 24, 24)
	red_strip_color = gx.rgb(80, 0, 0)
	white_key_color = gx.rgb(255, 255, 245)
	black_key_color = gx.rgb(25, 25, 25)

	pressed_white_key_color = gx.rgb(210, 210, 175)
	pressed_black_key_color = gx.rgb(80, 80, 80)
)

fn init(mut app App) {
	app.resize()
}

fn frame(app &App) {
	app.gg.begin()
	app.draw()
	app.gg.end()
}

// how long a note will fall for before being played
const lookahead = u64(3 * time.second)

fn (app &App) draw() {
	ww, wh := app.win_width, app.win_height
	kw, kh := app.key_width, app.key_height
	// 5px margin at the bottom, for pressed notes to take up
	starty := wh - kh - 5
	bar_area_height := wh - kh - 10

	// draw red strip above keyboard
	app.gg.draw_rect(0, starty - 5, ww, 5, red_strip_color)


	// whites := app.notes[app.i..].filter(octave[it.midi % octave.len] == .white)
	// blacks := app.notes[app.i..].filter(octave[it.midi % octave.len] == .black)

	// println('$app.i $whites.len + $blacks.len = ${app.notes[app.i..].len}')

	// draw the note bars
	mut i := u32(0)
	mut lol := 0
	for i = app.i; i < app.notes.len ; i++ {
		lol++
		note := app.notes[i]
		if note.start > app.t { break }
		h := f32((note.len) * u64(bar_area_height) / lookahead)
		y := f32((app.t - note.start) * u64(bar_area_height) / lookahead)
		x, w := app.note_pos(note.midi)
		app.gg.draw_rect(x, y - h, w, h, note_color(note.midi, 100))


		c := text_cfg(note.midi)
		app.gg.draw_text(int(x + w / 2), int(y - 20), note_names[note.midi % octave.len], { ...c, color: gx.white })


		// if y > wh { break }
		// println('$i: $y: ${wh - int(y)}')

		// println(f64(note.start+note.len-app.t) / f64(lookahead))

		// height := max(int(f64(note.len) / f64(lookahead) * wh), bar_area_height - f32(y))
		// color := note_color(note.midi, 100)
		// app.gg.draw_rect(note.midi * 10, f32(y), 10, height, color)
		// println('(${note.midi * 10}, $y), (10, $height)')
	}
	// println('$app.i -> $i')
	i = 0

	// draw white keys
	for midi := byte(app.start_note); i < app.white_key_count; midi++ {
		if octave[midi % octave.len] == .black { midi++ }
		startx := i * kw
		if midi > 127 { break }
		key := app.keys[midi]
		pressed := key.pressed || key.sustained
		color := if pressed { pressed_white_key_color } else { white_key_color }
		height := if pressed { kh + 5 } else { kh }
		app.gg.draw_rounded_rect(startx, starty, kw, height, f32(kw) / 6, color)
		app.gg.draw_empty_rounded_rect(startx, starty, kw, height, f32(kw) / 6, gx.black)
		app.gg.draw_text(int(startx + kw / 2), wh - 30, note_names[midi % octave.len], text_cfg(midi))
		i++
	}
	i = 0

	// calculate the black key width / black key height: 2/3 that of a white key
	bkw, bkh := app.key_width * 2 / 3, app.key_height * 2 / 3

	// draw black keys on top
	for midi := byte(app.start_note); i < app.white_key_count - 1; midi++ {
		x := octave[(midi + 1) % octave.len]
		if x == .white { i++ continue } else { midi++ }
		if midi > 127 { break }
		key := app.keys[midi]
		startx := i * kw + bkw
		pressed := key.pressed || key.sustained
		color := if pressed { pressed_black_key_color } else { black_key_color }
		height := if pressed { bkh + 3 } else { bkh }
		app.gg.draw_rect(startx, starty, bkw, height, color)
		app.gg.draw_text(int(startx + kw / 3), int(wh - app.key_height / 3 - 20), note_names[midi % octave.len], text_cfg(midi))
		i++
	}
}

// note_pos returns the x coordinate of a note bar and its width
// TODO
fn (app &App) note_pos(note byte) (f32, f32) {
	if octave[note % octave.len] == .white {
		return f32(note - app.start_note) * app.win_width / app.white_key_count / 1.75, app.key_width
	} else {
		return f32(note - app.start_note) * app.win_width / app.white_key_count / 1.75 + 1/2, app.key_width * 2 / 3
	}
}

[inline]
fn text_cfg(note byte) gx.TextCfg {
	size := if octave[note % octave.len] == .black { 18 } else { 32 }
	return {
		color: note_colors[note % octave.len]
		size: size
		align: .center
		vertical_align: .middle
		bold: true
	}
}

[inline]
fn note_color(note byte, vol byte) gx.Color {
	mut c := note_colors[note % octave.len]
	if !is_playable(note) {
		// these are outside the playable Boomwhackers range - make them dark
		c = gx.Color{
			r: c.r / 3
			g: c.g / 3
			b: c.b / 3
		}
	}
	return c
}

fn event(e &gg.Event, mut app App) {
	match e.typ {
		// .key_down {
		// 	app.on_key_down(e.key_code)
		// }
		.resized, .restored, .resumed {
			app.resize()
		}
		.mouse_scroll {
			if e.scroll_x < 0 {
				app.shift_kb(.left)
			} else if e.scroll_x > 0 {
				app.shift_kb(.right)
			}
			if e.scroll_y < 0 {
				if app.key_height < f64(app.win_height) * max_key_height {
					app.key_height += 3
				}
			} else {
				if app.key_height > 128 {
					app.key_height -= 3
				}
			}
		}
		.mouse_down {
			if e.mouse_y < app.win_height - app.key_height { return }
			if e.mouse_button == .left {
				app.dragging = true
				mut note, mut i := app.start_note, 0
				for {
					i++
					note++
					if i * app.key_width > e.mouse_x { break }
					if octave[note % octave.len] == .black { note++ } // else { note++ }
				}
				note--
				app.play_note(note, 100)
			}
		}
		.mouse_up {
			if e.mouse_y < app.win_height - app.key_height { return }
			if e.mouse_button == .left {
				app.dragging = false
				mut note, mut i := app.start_note, 0
				for {
					i++
					note++
					if i * app.key_width > e.mouse_x { break }
					if octave[note % octave.len] == .black { note++ } // else { note++ }
				}
				note--
				app.pause_note(note)
			}
		}
		.mouse_move {
			if app.dragging {
				s := sign(e.mouse_dx)
				if s == -1 { return } // TODO: fix

				mut note, mut i := i8(app.start_note), 0
				for {
					i++
					note++
					if i * app.key_width > e.mouse_x { break }
					if octave[note % octave.len] == .black { note++ }
				}
				note--
				// if octave[note % octave.len] == .black { note -- }

				mut prev_note := note - 2 * s
				i -= 2 * s
				for {
					i += s
					prev_note++
					if i * app.key_width > (e.mouse_x - e.mouse_dx) { break }
					if octave[prev_note % octave.len] == .black { prev_note ++ }
				}
				prev_note -= s
				if octave[note % octave.len] == .black { prev_note -= s }

				if note != prev_note {
					app.pause_note(byte(prev_note))
					app.play_note(byte(note), 100)
				}
			}
		}
		.key_down {
			match e.key_code {
				.escape {
					exit(0)
				}
				.left {
					app.shift_kb(.left)
				}
				.right {
					app.shift_kb(.right)
				}
				// .space {
				// 	if app.sustained { app.unsustain() } else { app.sustain() }
				// }
				else {}
			}
		}
		else {}
	}
}

enum Direction {
	left = -1
	right = 1
}

fn (mut app App) shift_kb(d Direction) {
	for {
		app.start_note -= byte(d)
		if octave[app.start_note % octave.len] == .white { break }
	}
	app.check_bounds()
}

fn (mut app App) resize() {
	// save previous values to keep proportional scaling
	_, ph := app.win_width, app.win_height

	s := gg.window_size()
	ww, wh := s.width, s.height
	app.win_width, app.win_height = ww, wh

	app.key_height = clamp(app.key_height / ph * wh, min_key_height, f32(wh) * max_key_height)

	// calculate ideal key count/width based on the current window width
	app.white_key_count = int(f32(ww) / default_key_width + 0.5) // round
	app.key_width = f32(ww) / app.white_key_count // will be 45 ± some decimal

	if app.start_note + app.white_key_count >= 127 {
		app.start_note = byte(128 - app.white_key_count)
	}
	app.check_bounds()
}

fn (mut app App) check_bounds() {
	if app.start_note > 128 {
		// overflow
		app.start_note = 0
	}

	mut midi := byte(app.start_note)
	for _ in 0 .. app.white_key_count {
		if octave[midi % octave.len] == .black { midi += 2 } else { midi++ }
	}
	if midi <= 128 { return }

	for midi > 127 {
		if octave[midi % octave.len] == .black { midi -= 2 } else { midi-- }
		app.start_note--
	}

	// ensure the window layout is now valid
	app.check_bounds()
}
