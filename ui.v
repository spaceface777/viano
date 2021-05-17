import gg
import gx
import time

const (
	win_width  = 1320
	win_height = 800
)

const (
	default_key_width = 56
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
const lookahead = u64(2 * time.second)

fn (app &App) draw() {
	ww, wh := app.win_width, app.win_height
	kw, kh := app.key_width, app.key_height
	// allow for a 5px margin at the bottom
	starty := wh - kh - 5
	bar_area_height := wh - kh - 10

	// draw red "felt" strip above keyboard
	app.gg.draw_rect(0, starty - 5, ww, 5, red_strip_color)

	// draw the note bars
	mut i := u32(0)
	for i = app.i; i < app.notes.len ; i++ {
		note := app.notes[i]
		if note.start > app.t { break }
		h := f32((note.len) * u64(bar_area_height) / lookahead)
		y := f32((app.t - note.start) * u64(bar_area_height) / lookahead)
		x, w := app.note_pos(note.midi)
		color := note_color(note.midi, 100)
		app.gg.draw_rounded_rect(x, y - h, w, h, f32(w) / 6, color)
		// draw a thin strip below each note in order to be able to make apart quick presses
		app.gg.draw_rect(x, y-7, w, 7, lighten(color, 0.67))

		c := text_cfg(note.midi)
		app.gg.draw_text(int(x + w / 2), int(y - 12), note_names[note.midi % octave.len], { ...c, color: gx.black, size: 20 })
	}
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
	c := note_colors[note % octave.len]
	$if !unplayable ? {
		if !is_playable(note) {
			// these are outside the playable Boomwhackers range - darken them
			return lighten(c, 0.33)
		}
	}
	return c
}

// lighten lightens `color` by a rate of `amount`. An `amount` < 0 means that `color` is darkened instead.
[inline]
fn lighten(color gx.Color, amount f32) gx.Color {
	return {
		r: byte(color.r * amount)
		g: byte(color.g * amount)
		b: byte(color.b * amount)
	}
}

// event is the callback that is called after a window event occurs
fn event(e &gg.Event, mut app App) {
	match e.typ {
		.resized, .restored, .resumed {
			app.resize()
		}
		.mouse_scroll {
			if e.scroll_y < 0 {
				if app.key_height < f64(app.win_height) * max_key_height {
					app.key_height += 3
				}
			} else if e.scroll_y > 0 {
				if app.key_height > 128 {
					app.key_height -= 3
				}
			}
		}
		.key_down {
			match e.key_code {
				.escape {
					exit(0)
				}
				// .left {
				// 	app.shift_kb(.left)
				// }
				// .right {
				// 	app.shift_kb(.right)
				// }
				.left {
					if app.t < time.second {
						app.t = 0
					} else {
						if app.t > u64(time.second) {
							app.t -= u64(time.second)
						} else {
							app.t = 0
						}
					}
					// TODO
					if app.i > 10 {
						app.i -= 10
					} else {
						app.i = 0
					}
					app.pause_all()
				}
				.right {
					app.t += u64(time.second)
				}
				.up {
					app.tempo += 0.03
				}
				.down {
					app.tempo -= 0.03
				}
				.space {
					app.paused = !app.paused
				}
				else {
					println(e.key_code)
				}
			}
		}
		else {}
	}
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
		// an overflow ocurred somewhere
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
