import gg
import gx
import time

const (
	win_width  = 1260
	win_height = 800
)

const (
	default_key_width = 60
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

// how quickly the note bars will leave the screen
const leave_factor = 100

// NOTE: there is a "bug" here, which is that once a note has been released,
// it moves up quicker than the leave_factor. This was not the intended behavior 
// originally, but it looked nice to me, and I haven't bothered fixing it :))
fn (app &App) draw() {
	ww, wh := app.win_width, app.win_height
	kw, kh := app.key_width, app.key_height
	// 5px margin at the bottom, for pressed notes to take up
	starty := wh - kh - 5
	bar_area_height := wh - kh - 10

	t := time.ticks()

	// draw red strip above keyboard
	app.gg.draw_rect(0, starty - 5, ww, 5, red_strip_color)

	// draw white keys
	mut i := 0
	for midi := byte(app.start_note); i < app.white_key_count; midi++ {
		if octave[midi % octave.len] == .black { midi++ }
		startx := i * kw
		if midi > 127 { break }
		key := app.keys[midi]
		pressed := key.pressed || key.sustained
		color := if pressed { pressed_white_key_color } else { white_key_color }
		height := if pressed { kh + 5 } else { kh }
		app.gg.draw_rounded_rect(startx, starty, kw / 2, height / 2, f32(kw) / 6, color)
		app.gg.draw_empty_rounded_rect(startx, starty, kw / 2, height / 2, f32(kw) / 6, gx.black)
		app.gg.draw_text(int(startx + kw / 2), wh - 30, note_names[midi % octave.len], text_cfg(midi))

		// draw note bars
		for press in key.presses {
			end := if press.end == 0 { t } else { press.end }
			offset := f32(t - end)
			len := f32(end - press.start)
			len_px := (leave_factor * len) / bar_area_height
			bcolor := note_color(midi, press.velocity)
			app.gg.draw_rect(startx, bar_area_height - len_px - offset, f32(kw), len_px, bcolor)
		}
		i++
	}

	// black key width / black key height
	bkw, bkh := app.key_width * 2 / 3, app.key_height * 2 / 3

	// draw black keys on top
	i = 0
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

		// draw note bars
		for press in key.presses {
			end := if press.end == 0 { t } else { press.end }
			offset := f32(t - end)
			len := f32(end - press.start)
			len_px := (leave_factor * len) / bar_area_height
			bcolor := note_color(midi, press.velocity)
			app.gg.draw_rect(startx, bar_area_height - len_px - offset, f32(bkw), len_px, bcolor)
		}
		i++
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
	return note_colors[note % octave.len]
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
				println(s)

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
					println('$prev_note -> $note')
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
					for {
						app.start_note++
						if octave[app.start_note % octave.len] == .white { break }
					}
					app.check_bounds()
				}
				.right {
					for {
						app.start_note--
						if octave[app.start_note % octave.len] == .white { break }
					}
					app.check_bounds()
				}
				.space {
					if app.sustained { app.unsustain() } else { app.sustain() }
				}
				else {}
			}
		}
		else {}
	}
}

fn (mut app App) resize() {
	s := gg.window_size()
	app.win_width, app.win_height = s.width, s.height

	app.key_height = clamp(app.win_height / 4, 150, 400)

	// calculate ideal key count/width based on the current window width
	app.white_key_count = int(f32(app.win_width) / default_key_width + 0.5) // round
	app.key_width = f32(app.win_width) / app.white_key_count // will be 45 ± some decimal

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

	dump('YES')

	for midi > 127 {
		if octave[midi % octave.len] == .black { midi -= 2 } else { midi-- }
		app.start_note--
	}
	dump(app.start_note)

	// ensure the window layout is now valid
	app.check_bounds()
}
