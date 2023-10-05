import os
import xml

fn test_valid_parsing() ! {
	path := os.join_path(os.dir(@FILE), 'root.xml')

	expected := xml.XMLDocument{
		root: xml.XMLNode{
			name: 'sample'
			children: [
				'Single root element.',
			]
		}
	}
	actual := xml.XMLDocument.parse_file(path)!

	assert expected == actual, 'Parsed XML document should be equal to expected XML document'
}
