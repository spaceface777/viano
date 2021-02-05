fn parse_midi_event(buf []byte, timestamp f64, mut app App) {
	if buf.len < 1 { return }
	// println('\nRead $buf.len MIDI bytes: $buf.hex()')

	status, channel := buf[0] & 0xF0, buf[0] & 0x0F
	_ = channel
	match status {
		0x80, /* note down */ 0x90 /* note up */ {
			assert buf.len > 2
			note, velocity := buf[1] & 0x7F, buf[2] & 0x7F
			// println('\n$app.is_sustain | ${app.sustained_notes.map(int(it))}')
			if velocity == 0 {
				// if !app.is_sustain {
					// app.sustained_notes = app.sustained_notes.filter(it != note)
					app.pause_note(note)
				// }
			} else {
				// app.sustained_notes << note
				app.play_note(note, velocity)
			}
			// println('$velocity | $app.is_sustain | ${app.sustained_notes.map(int(it))}')
		} 0xB0 /* control change */ {
			assert buf.len > 2
			control, value := buf[1] & 0x7F, buf[2] & 0x7F
			match control {
				0x40 {
					if value < 0x40 {
						for note in app.sustained_notes {
							app.pause_note(note)
						}
						app.sustained_notes = []
						app.is_sustain = false
					} else {
						app.is_sustain = true
						// app.sustained_notes = []
					}
					// println('\nSUST = $app.is_sustain')
				}
				else {
					println('Control change ($buf.hex())')
				}
			}
		} else {
			println('Unknown MIDI event `$status`')
		}
	}
}
