module xml

import strings

pub fn (node XMLNode) pretty_str(original_indent string, depth int) string {
	mut builder := strings.new_builder(1024)
	indent := original_indent.repeat(depth)
	builder.write_string('${indent}<${node.name}')
	for key, value in node.attributes {
		builder.write_string(' ${key}="${value}"')
	}
	builder.write_string('>\n')
	for child in node.children {
		match child {
			string {
				builder.write_string(indent)
				builder.write_string(original_indent)
				builder.write_string(child)
				builder.write_u8(`\n`)
			}
			XMLNode {
				builder.write_string(child.pretty_str(original_indent, depth + 1))
				builder.write_u8(`\n`)
			}
		}
	}
	builder.write_string('${indent}</${node.name}>')
	return builder.str()
}

pub fn (doc XMLDocument) pretty_str(indent string) string {
	return '<?xml version="${doc.version}" encoding="${doc.encoding}"?>\n${doc.root.pretty_str(indent,
		0)}'
}

pub fn (doc XMLDocument) str() string {
	return doc.pretty_str('  ')
}
