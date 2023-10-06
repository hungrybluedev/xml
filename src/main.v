module main

// import os
import xml

fn main() {
	// paths := os.walk_ext('src/spec/local', 'xml')

	// for path in paths {
	// 	doc := xml.XMLDocument.parse_file(path) or {
	// 		println('Failed to parse: ' + path + '\n')
	// 		continue
	// 	}
	// 	println(doc)
	// 	println('\n\n')
	// }
	// doc := xml.XMLDocument.parse_file('src/spec/local/01_mdn_example/hello_world.xml')!
	doc := xml.XMLDocument.parse_file('src/spec/local/13_doctype_element/element.xml')!
	println(doc.root)
}
