module main

import xml

fn main() {
	paths := [
		'01_mdn_example/hello_world.xml',
		'02_note_message/note.xml',
		'03_cd_catalogue/cd_catalog.xml',
	]
	for path in paths {
		doc := xml.XMLDocument.parse_file('spec/' + path)!
		println(doc)
	}
}
