import gx
import math

const log_color_offset = 4

fn note_color(note byte, vol byte) gx.Color {
	h := note * 16 % 360
	s := 0.7
	v := math.log_n(vol + log_color_offset, 128 + log_color_offset)
	return HSV{ h, s, v }.rgb()
}

struct HSV {
	h f64
	s f64
	v f64
}

fn (c HSV) rgb() gx.Color {
	v := byte(c.v * 255)
	if c.s <= 0.0 {
		return gx.rgb(v, v, v)
	}
	hh := c.h / 60
	i := int(hh) % 6
	ff := hh - i
	p := byte(c.v * (1.0 - c.s) * 255)
	q := byte(c.v * (1.0 - (c.s * ff)) * 255)
	t := byte(c.v * (1.0 - (c.s * (1.0 - ff))) * 255)

	return match i {
		0 { gx.rgb(v, t, p) }
		1 { gx.rgb(q, v, p) }
		2 { gx.rgb(p, v, t) }
		3 { gx.rgb(p, q, v) }
		4 { gx.rgb(t, p, v) }
		else { gx.rgb(v, p, q) }
	}
}
