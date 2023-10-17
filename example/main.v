module main

// import os
import xml
import time

fn main() {
	// paths := os.walk_ext('src/spec/local', 'xml')

	// for path in paths {
	// 	doc := xml.XMLDocument.from_file(path) or {
	// 		println('Failed to parse: ' + path + '\n')
	// 		continue
	// 	}
	// 	println(doc)
	// 	println('\n\n')
	// }
	// doc := xml.XMLDocument.from_file('test/local/01_mdn_example/hello_world.xml')!
	mut sw := time.new_stopwatch()
	doc := xml.XMLDocument.from_file('test/gtk/Gtk-4.0.gir')!
	println('Parsing took ${sw.elapsed().milliseconds()} ms')

	sw.restart()
	validated := doc.validate()!
	println('Validation took ${sw.elapsed().milliseconds()} ms')

	sw.restart()
	println(validated.get_elements_by_tag('include'))
	println('Getting elements took ${sw.elapsed().milliseconds()} ms')
}
