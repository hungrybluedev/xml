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
			}
			XMLNode {
				builder.write_string(child.pretty_str(original_indent, depth + 1))
			}
			XMLComment {
				builder.write_string(indent)
				builder.write_string(original_indent)
				builder.write_string('<!--')
				builder.write_string(child.text)
				builder.write_string('-->')
			}
			XMLCData {
				builder.write_string(indent)
				builder.write_string(original_indent)
				builder.write_string('<![CDATA[')
				builder.write_string(child.text)
				builder.write_string(']]>')
			}
			DTDEntity {
				builder.write_string(indent)
				builder.write_string(original_indent)
				builder.write_string('<!ENTITY ')
				builder.write_string(child.name)
				builder.write_string(' ')
				builder.write_string(child.value)
				builder.write_string('>')
			}
			// DTDElement{
			// 	builder.write_string(indent)
			// 	builder.write_string(original_indent)
			// 	builder.write_string('<!ELEMENT ')
			// 	builder.write_string(child.name)
			// 	builder.write_string(' ')
			// 	builder.write_string(child.definition)
			// 	builder.write_string('>')
			// }
		}
		builder.write_u8(`\n`)
	}
	builder.write_string('${indent}</${node.name}>')
	return builder.str()
}

fn (entities []DTDEntity) pretty_str(indent string) string {
	if entities.len == 0 {
		return ''
	}

	mut builder := strings.new_builder(1024)
	builder.write_u8(`[`)
	builder.write_u8(`\n`)

	for entity in entities {
		builder.write_string('${indent}<!ENTITY ${entity.name} "${entity.value}">')
		builder.write_u8(`\n`)
	}
	builder.write_u8(`]`)
	return builder.str()
}

fn (doctype DocumentType) pretty_str(indent string) string {
	match doctype.dtd {
		string {
			return '<!DOCTYPE ${doctype.name} SYSTEM "${doctype.dtd}">'
		}
		DocumentTypeDefinition {
			if doctype.dtd.entities.len == 0 {
				return ''
			}

			mut builder := strings.new_builder(1024)
			builder.write_string('<!DOCTYPE ')
			builder.write_string(doctype.name)
			builder.write_string(' ')
			builder.write_string(doctype.dtd.entities.pretty_str(indent))
			builder.write_string('>')
			builder.write_u8(`\n`)
			return builder.str()
		}
	}
}

pub fn (doc XMLDocument) pretty_str(indent string) string {
	prolog := '<?xml version="${doc.version}" encoding="${doc.encoding}"?>'
	comments := if doc.comments.len > 0 {
		mut buffer := strings.new_builder(512)
		for comment in doc.comments {
			buffer.write_string('<!--')
			buffer.write_string(comment.text)
			buffer.write_string('-->')
			buffer.write_u8(`\n`)
		}
		buffer.str()
	} else {
		''
	}
	return '${prolog}\n${doc.doctype.pretty_str(indent)}${comments}${doc.root.pretty_str(indent,
		0)}'
}

pub fn (doc XMLDocument) str() string {
	return doc.pretty_str('  ')
}
