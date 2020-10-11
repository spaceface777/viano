// © spaceface, spytheman, henrixounez

module audio

import math
import sokol.audio as saudio

const (
	tau    = 2 * math.pi
	transi = 5000
)

pub struct Note {
mut:
	freq f32
	vol  f32
	step int
	paused bool
}

fn (mut note Note) next(time f32, vol2 f32) f32 {
	mut vol := f32(0.0)
	if !note.paused {
		if note.step < transi {
			vol = note.vol * smoothstep(0, transi, note.step)
			note.step++
		} else {
			vol = note.vol
		}
	} else if note.paused && note.step >= 0 {
		vol = note.vol * smoothstep(0, transi, note.step)
		note.step--
	}
    return math.sinf(tau * time * note.freq) * vol
}

pub struct Context {
mut:
	notes []Note
	t     f32
}

pub fn (mut ctx Context) play(freq, volume f32) {
	ctx.notes << Note{ freq, volume, 0, false }
}

pub fn (mut ctx Context) pause(freq f32) {
	// Modifying the array here crashes the program
	// ctx.notes = ctx.notes.filter(it.step != -1)
	for i in 0..ctx.notes.len {
		if ctx.notes[i].freq == freq {
			ctx.notes[i].paused = true
		}
	}
}

fn smoothstep(edge0 f64, edge1 f64, val f64) f32 {
	x := clamp((val - edge0) / (edge1 - edge0), 0.0, 1.0)
	return f32(x * x * x * (x * (x * 6 - 15) + 10))
}

fn clamp(x f64, lowerlimit f64, upperlimit f64) f64 {
	if x < lowerlimit {
		return lowerlimit
	}
	if x > upperlimit {
		return upperlimit
	}
	return x
}

fn audio_cb(mut buffer &f32, num_frames, num_channels int, mut ctx Context) {
    mut mc := f32(0.0)
    frame_ms := 1.0 / f32(saudio.sample_rate())
    unsafe {
        for frame in 0 .. num_frames {
            for ch in 0 .. num_channels {
                idx := frame * num_channels + ch
                buffer[idx] = 0
                for i, note in ctx.notes {
					if note.step != -1 {
	                    buffer[idx] += ctx.notes[i].next(ctx.t, 0.0)
					}
                }
                c := buffer[idx]
                ac := if c < 0 { -c } else { c }
                if mc < ac {
                    mc = ac
                }
            }
            ctx.t += frame_ms
        }
        if mc < 1.0 {
            return
        }
        mut normalizing_coef := 1.0 / mc
        for idx in 0 .. (num_frames * num_channels) {
            buffer[idx] *= normalizing_coef
        }
    }
}

pub fn new_context() &Context {
	mut ctx := &Context{
		notes: []
		t: 0
	}
	saudio.setup({
		user_data: ctx
		stream_userdata_cb: audio_cb
	})
	return ctx
}
