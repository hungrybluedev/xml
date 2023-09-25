module main

import os
import xml

fn main() {
	paths := os.walk_ext('spec/local', 'xml')

	for path in paths {
		doc := xml.XMLDocument.parse_file(path) or {
			println('Failed to parse: ' + path)
			continue
		}
		println(doc)
	}
	// doc := xml.XMLDocument.parse_file('spec/local/01_mdn_example/hello_world.xml')!
	// // doc := xml.XMLDocument.parse_file('spec/local/08_comments/comment.xml')!
	// println(doc)
}
