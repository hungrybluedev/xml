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
	// doc := xml.XMLDocument.from_file('src/spec/local/12_doctype_entity/entity.xml')!
	doc := xml.XMLDocument.from_string('<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE note [
  <!ELEMENT note (to,from,heading,body)>
  <!ELEMENT to (#PCDATA)>
  <!ELEMENT from (#PCDATA)>
  <!ELEMENT heading (#PCDATA)>
  <!ELEMENT body (#PCDATA)>
]>
<note>
  <to>Tove</to>
  <from>Jani</from>
  <heading>Reminder</heading>
  <body>Don\'t forget me this weekend!</body>
</note>
')!
	println(doc)
}
