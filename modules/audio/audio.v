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

[inline]
fn square(note &Note, time, amp f32) f32 {
	t := time * note.freq
    f := t - int(t)
    return if f < 0.5 { amp } else { -amp }
}

[inline]
fn triangle(note &Note, time, amp f32) f32 {
	t := time * note.freq
    f := t - int(t)
    return f32(2 * math.abs(2 * (f - 0.5)) - 1) * amp
}

[inline]
fn sawtooth(note &Note, time, amp f32) f32 {
	t := time * note.freq
    f := t - int(t)
    return f32(2 * (f - 0.5)) * (amp / 2)
}

[inline]
fn sine(note &Note, time, amp f32) f32 {
	return math.sinf(tau * time * note.freq) * amp
}

fn (c &Context) next(mut note Note, time f32) f32 {
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
    return c.next_fn(note, time, vol)
}

pub struct Context {
mut:
	next_fn fn(n &Note, t, amp f32) f32
	notes   []Note
	t       f32
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
	                    buffer[idx] += ctx.next(mut ctx.notes[i], ctx.t)
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

pub enum WaveKind {
	sine
	square
	triangle
	sawtooth
}

pub struct Config {
	wave_kind WaveKind
}

pub fn new_context(cfg Config) &Context {
	next_fn := match cfg.wave_kind {
		.sine { sine }
		.square { square }
		.triangle { triangle }
		.sawtooth { sawtooth }
	}
	mut ctx := &Context{
		notes: []
		t: 0
		next_fn: next_fn
	}
	saudio.setup({
		user_data: ctx
		stream_userdata_cb: audio_cb
	})
	return ctx
}
