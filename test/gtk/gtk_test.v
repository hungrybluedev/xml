module main

import xml
import os

fn test_large_gtk_file() ! {
	path := os.join_path(os.dir(@FILE), 'Gtk-4.0.gir')
	actual := xml.XMLDocument.from_file(path) or { assert false, 'Failed to parse large XML file' }

	assert true
}
