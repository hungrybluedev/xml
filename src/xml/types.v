module xml

import os
import strings

pub struct XMLNode {
pub:
	name       string            [required]
	attributes map[string]string
	inner_text string
	children   []XMLNode
}

struct XMLDocument {
pub:
	version  string = '1.0'
	encoding string = 'UTF-8'
	root     XMLNode [required]
}

struct Prolog {
	version  string = '1.0'
	encoding string = 'UTF-8'
}

fn parse_attributes(all_attributes string) map[string]string {
	parts := all_attributes.split_any(' \t\n')
	mut attributes := map[string]string{}
	for part in parts {
		pair_contents := part.split('=')
		key := pair_contents[0].trim_space()
		value := pair_contents[1].trim_space().trim('"')
		attributes[key] = value
	}

	return attributes
}

fn parse_prolog(contents string) !(Prolog, int) {
	if contents[0..5] != '<?xml' {
		// No prolog detected, return default
		return Prolog{}, 0
	}

	prolog_ending := contents[5..].index('?>') or { return error('XML declaration not closed.') }

	prolog_attributes := contents[5..prolog_ending + 5].trim_space()
	// '?>'.len == 2 and '<?xml'.len == 5
	offset_prolog_location := prolog_ending + 7

	if prolog_attributes.len == 0 {
		// No attributes so return default prolog
		return Prolog{}, offset_prolog_location
	}

	attributes := parse_attributes(prolog_attributes)
	version := attributes['version'] or { return error('XML declaration missing version.') }
	encoding := attributes['encoding'] or { return error('XML declaration missing encoding.') }
	return Prolog{version, encoding}, offset_prolog_location
}

fn parse_single_node(contents string) !(XMLNode, string) {
	if contents[0] != `<` {
		return error('XML node must start with "<".: ${contents}')
	}
	// We're expecting an opening tag
	if contents[1] == `/` {
		return error('XML node cannot start with "</".')
	}
	tag_end := contents.index('>') or { return error('XML node tag not closed.') }
	tag_contents := contents[1..tag_end].trim_space()

	parts := tag_contents.split_any(' \t\n')
	name := parts[0]

	// Check if it is a self-closing tag
	if tag_contents[tag_contents.len - 1] == `/` {
		// We're not looking for children and inner text
		return XMLNode{
			name: name
			attributes: parse_attributes(tag_contents[name.len..tag_contents.len - 1].trim_space())
		}, contents[tag_end + 1..]
	}

	attribute_string := tag_contents[name.len..].trim_space()
	attributes := parse_attributes(attribute_string)

	// We're now looking for children OR inner text
	remaining_contents := contents[tag_end + 1..]
	looking_for_text := remaining_contents.trim_space()[0] != `<`

	if looking_for_text {
		mut inner_contents := strings.new_builder(remaining_contents.len)
		mut found_left_angle := false
		for index, ch in remaining_contents {
			match ch {
				`<` {
					found_left_angle = true
				}
				`/` {
					if !found_left_angle {
						// false alarm
						inner_contents.write_u8(ch)
						found_left_angle = false
						continue
					}
					// We've reached the end of the node
					return XMLNode{
						name: name
						attributes: attributes
						inner_text: inner_contents.str().trim_space()
					}, remaining_contents[index + name.len + 2..]
				}
				else {
					inner_contents.write_u8(ch)
					found_left_angle = false
				}
			}
		}
		return error('XML node <${name}> not closed.')
	}

	// We're looking for children
	mut children := []XMLNode{}
	mut remaining := remaining_contents

	for remaining.len > 0 {
		if remaining.len >= 2 && remaining[0..2] == '</' {
			// We've reached the end of the node
			return XMLNode{
				name: name
				attributes: attributes
				children: children
			}, remaining.all_after('${name}>')
		}
		child, new_remaining := parse_single_node(remaining.trim_space())!
		children << child
		remaining = new_remaining.trim_space()
	}

	return error('XML node <${name}> not closed.')
}

pub fn XMLDocument.parse_file(path string) !XMLDocument {
	contents := os.read_file(path) or { return error('Could not read file: ${path}') }
	return XMLDocument.parse(contents)!
}

pub fn XMLDocument.parse(raw_contents string) !XMLDocument {
	contents := raw_contents.trim_space()
	if contents.len == 0 {
		return error('XML document is empty.')
	}

	prolog, prolog_location := parse_prolog(contents)!

	root_contents := contents[prolog_location..]
	root, remaining := parse_single_node(root_contents.trim_space())!

	if remaining.len > 0 {
		return error('XML document has more than one root node or is improperly formed.')
	}

	return XMLDocument{
		version: prolog.version
		encoding: prolog.encoding
		root: root
	}
}

pub fn (node XMLNode) pretty_str(original_indent string, depth int) string {
	mut builder := strings.new_builder(1024)
	indent := original_indent.repeat(depth)
	builder.write_string('${indent}<${node.name}')
	for key, value in node.attributes {
		builder.write_string(' ${key}="${value}"')
	}
	if node.inner_text.len > 0 {
		builder.write_string('>\n${indent}${original_indent}${node.inner_text}\n${indent}</${node.name}>')
		return builder.str()
	}
	if node.children.len == 0 {
		builder.write_string('/>')
		return builder.str()
	}
	builder.write_string('>\n')
	for child in node.children {
		builder.write_string(child.pretty_str(original_indent, depth + 1))
		builder.write_u8(`\n`)
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
