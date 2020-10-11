[inline]
fn (mut app App) play(note byte) {
	if '$note' in app.samples {
		mut sample := app.samples['$note']
		sample.play()
	}
}

[inline]
fn (mut app App) stop(note byte) {
	if '$note' in app.samples {
		mut sample := app.samples['$note']
		sample.stop()
	}
}
