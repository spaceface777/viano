module midi

#flag -I@VROOT/modules/midi
#include "rtmidi_c.h"
#flag -lrtmidi

// type RtMidiInPtr = voidptr

struct C.RtMidiWrapper {
    ptr  voidptr
    data voidptr
	ok   bool
	msg  charptr
}

fn C.rtmidi_in_create_default() &C.RtMidiWrapper
fn C.rtmidi_get_port_count(&C.RtMidiWrapper) u32
fn C.rtmidi_get_port_name(&C.RtMidiWrapper, u32) charptr
fn C.rtmidi_open_port(&C.RtMidiWrapper, u32, charptr)
fn C.rtmidi_in_get_message(&C.RtMidiWrapper, &byte, u32) f64

const ( read_size = 16 )

pub struct Input {
	ptr  &C.RtMidiWrapper
	buf  byteptr
}

pub fn new_in() Input {
	return {
		ptr: C.rtmidi_in_create_default()
		buf: malloc(read_size)
	}
}

pub fn (i &Input) get_port_count() ?int {
	count := C.rtmidi_get_port_count(i.ptr)
	if !i.ptr.ok { return none }
	return int(count)
}

pub fn (i &Input) get_port_name(port int) ?string {
	name := C.rtmidi_get_port_name(i.ptr, u32(port))
	if !i.ptr.ok { return none }
	return tos2(name)
}

pub fn (i &Input) open_port(port int, name string) ? {
	C.rtmidi_open_port(i.ptr, u32(port), name.str)
	if !i.ptr.ok { return none }
}

pub fn (i &Input) get_message() ?([]byte, f64) {
	mut len := u32(read_size)
	offset := C.rtmidi_in_get_message(i.ptr, &i.buf, &len)
	if !i.ptr.ok { return none }

	mut arr := []byte{ len: int(len) }
	unsafe { C.memcpy(arr.data, i.buf, len) }
	return arr, offset
}
