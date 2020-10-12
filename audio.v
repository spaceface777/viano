import math

[inline]
fn midi2freq(midi byte) f32 {
	return int(math.powf(2, f32(midi - 69) / 12) * 440)
}

[inline]
fn (mut app App) play(note, vol byte) {
	freq := midi2freq(note)
	app.audio_ctx.play(freq, f32(vol) / 127 / 4)
}

[inline]
fn (mut app App) pause(note byte) {
	freq := midi2freq(note)
	app.audio_ctx.pause(freq)
}
