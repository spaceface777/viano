import gg
import gx
import sokol.sapp
import time

const (
	win_width  = 1260
	win_height = 800
)

const (
	default_key_width = 45
)

const (
	bg_color        = gx.rgb(24, 24, 24)
	red_strip_color = gx.rgb(80, 0, 0)
	white_key_color = gx.rgb(255, 255, 245)
	black_key_color = gx.rgb(25, 25, 25)

	pressed_white_key_color = gx.rgb(210, 210, 175)
	pressed_black_key_color = gx.rgb(80, 80, 80)
)

enum KeyColor { black white }

const octave = [KeyColor.white, .black, .white, .black, .white, .white, .black, .white, .black, .white, .black, .white]!

struct Keypress {
mut:
	start    i64
	end      i64
	velocity byte
}

struct Key {
mut:
	pressed     bool
	presses     []Keypress
}

fn init(mut app App) {
	app.resize()
}

fn frame(app &App) {
	app.gg.begin()
	app.draw()
	app.gg.end()
}

fn (app &App) draw() {
	ww, wh := app.win_width, app.win_height
	kw, kh := app.key_width, app.key_height
	// 5px margin at the bottom
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
		key := app.keys[midi]
		color := if key.pressed { pressed_white_key_color } else { white_key_color }
		height := if key.pressed { kh + 5 } else { kh }
		app.gg.draw_rounded_rect(startx, starty, kw / 2, height / 2, f32(kw) / 6, color)
		app.gg.draw_empty_rounded_rect(startx, starty, kw / 2, height / 2, f32(kw) / 6, gx.black)

		// draw note bars
		for press in key.presses {
			end := if press.end == 0 { t } else { press.end }
			offset := f32(t - end)
			len := f32(end - press.start)
			len_px := (100 * len) / bar_area_height
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
		key := app.keys[midi]
		startx := i * kw + bkw
		color := if key.pressed { pressed_black_key_color } else { black_key_color }
		app.gg.draw_rect(startx, starty, bkw, bkh, color)
		i++
	}
}

fn event(e &sapp.Event, mut app App) {
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
			// if app.dragging {
			// 	mut note, mut i := app.start_note, 0
			// 	for {
			// 		i++
			// 		note++
			// 		if i * app.key_width > e.mouse_x { break }
			// 		if octave[note % octave.len] == .black { note++ }
			// 	}
			// 	note--
			// 	if octave[note % octave.len] == .black { note-- }

			// 	s := sign(e.mouse_dx)
			// 	mut prev_note := note - 2 * s
			// 	i -= 2 * s
			// 	for {
			// 		i += 1 * s
			// 		prev_note += 1 * s
			// 		if i * app.key_width > (e.mouse_x - e.mouse_dx) { break }
			// 		if octave[prev_note % octave.len] == .black { prev_note += 1 * s }
			// 	}
			// 	prev_note -= 1 * s
			// 	if octave[note % octave.len] == .black { prev_note -= 1 * s }

			// 	if note != prev_note {
			// 		println('$prev_note -> $note')
			// 		app.pause_note(prev_note)
			// 		app.play_note(note)
			// 	}
			// }
		}
		.key_down {
			match e.key_code {
				.escape {
					exit(0)
				}
				.left {
					if app.start_note + app.white_key_count < 127 {
						for {
							app.start_note++
							if octave[app.start_note % octave.len] == .white { break }
						}
					}
				}
				.right {
					if app.start_note > 0 {
						for {
							app.start_note--
							if octave[app.start_note % octave.len] == .white { break }
						}
					}
				}
				else {}
			}
		}
		else {}
	}
}

fn (mut app App) resize() {
	mut s := sapp.dpi_scale()
	if s == 0.0 { s = 1.0 }
	app.win_width = int(sapp.width() / s)
	app.win_height = int(sapp.height() / s)

	app.key_height = clamp(app.win_height / 4, 150, 400)

	// calculate ideal key count/width based on the current window width
	app.white_key_count = int(f32(app.win_width) / default_key_width + 0.5) // round
	app.key_width = f32(app.win_width) / app.white_key_count // will be 45 ± some decimal
}
