module xml

import io
import math

struct StringReader {
	contents string
mut:
	position int
}

fn (mut sr StringReader) read(mut buf []u8) !int {
	if sr.position >= sr.contents.len {
		return 0
	}
	n := math.min(buf.len, sr.contents.len - sr.position)
	for i := 0; i < n; i++ {
		buf[i] = sr.contents[sr.position + i]
	}
	sr.position += n
	return n
}

fn next_char(mut reader io.Reader) !u8 {
	mut buf := [u8(0)]
	if reader.read(mut buf)! == 0 {
		return error('Unexpected End Of File.')
	}
	return buf[0]
}
