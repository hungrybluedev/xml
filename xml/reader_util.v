module xml

import io
import math

fn next_char(mut reader io.Reader) !u8 {
	mut buf := [u8(0)]
	if reader.read(mut buf)! == 0 {
		return error('Unexpected End Of File.')
	}
	return buf[0]
}

struct FullBufferReader {
	contents []u8
mut:
	position int
}

[direct_array_access]
fn (mut fbr FullBufferReader) read(mut buf []u8) !int {
	if fbr.position >= fbr.contents.len {
		return 0
	}
	n := math.min(buf.len, fbr.contents.len - fbr.position)
	for i := 0; i < n; i++ {
		buf[i] = fbr.contents[fbr.position + i]
	}
	fbr.position += n
	return n
}
