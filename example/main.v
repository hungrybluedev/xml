module main

// import os
import xml

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
	doc := xml.XMLDocument.from_file('test/gtk/Gtk-4.0.gir')!
	println(doc)
}
