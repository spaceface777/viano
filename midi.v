fn (mut app App) parse_midi_event(buf []byte) {
	// println('\nRead $buf.len MIDI bytes: $buf.hex()')
	if buf.len < 1 { return }

	status, channel := buf[0] & 0xF0, buf[0] & 0x0F
	match status {
		0x80, /* note down */ 0x90 /* note up */ {
			assert buf.len > 2
			note, velocity := buf[1] & 0x7F, buf[2] & 0x7F
			if velocity == 0 { app.pause(note) } else { app.play(note) }
		} 0xB0 /* control change */ {
			assert buf.len > 2
			control, value := buf[1] & 0x7F, buf[2] & 0x7F
			match control {
				0x40 {
					typ := if value < 0x40 { 'off' } else { 'on' }
					println('MIDI pedal $typ on channel $channel')
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
