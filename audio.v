import math

const damp_ratio = 8

[inline]
fn midi2freq(midi byte) f32 {
	return int(math.powf(2, f32(midi - 69) / 12) * 440)
}
