module xml

import os
import strings

const (
	default_prolog_attributes = {
		'version':  '1.0'
		'encoding': 'UTF-8'
	}
)

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

fn parse_comment(contents string) !(XMLComment, int) {
	// We find the nearest '-->' to the start of the comment
	comment_end := contents.index('-->') or { return error('XML comment not closed.') }
	comment_contents := contents[4..comment_end]
	return XMLComment{comment_contents}, comment_end + 3
}

fn parse_prolog(contents string) !(Prolog, int) {
	if contents[0..5] != '<?xml' {
		// No prolog detected, return default
		return Prolog{}, 0
	}

	prolog_ending := contents[5..].index('?>') or { return error('XML declaration not closed.') }

	prolog_attributes := contents[5..prolog_ending + 5].trim_space()
	// '?>'.len == 2 and '<?xml'.len == 5
	mut offset_prolog_location := prolog_ending + 7

	attributes := if prolog_attributes.len == 0 {
		xml.default_prolog_attributes
	} else {
		parse_attributes(prolog_attributes)
	}

	version := attributes['version'] or { return error('XML declaration missing version.') }
	encoding := attributes['encoding'] or { return error('XML declaration missing encoding.') }

	mut comments := []XMLComment{}

	for {
		// Skip any whitespace after the prolog
		for contents[offset_prolog_location] in [` `, `\t`, `\n`] {
			offset_prolog_location++
		}
		if contents[offset_prolog_location..offset_prolog_location + 4] == '<!--' {
			comment, new_location := parse_comment(contents[offset_prolog_location..])!
			comments << comment
			offset_prolog_location += new_location
		} else if contents[offset_prolog_location] == `<` {
			// Found the start of the root node
			break
		}
	}

	return Prolog{version, encoding, comments}, offset_prolog_location
}

fn parse_children(name string, attributes map[string]string, contents string) !(XMLNode, string) {
	mut remaining_contents := contents
	mut inner_contents := strings.new_builder(remaining_contents.len)

	mut children := []XMLNodeContents{}

	mut index := 0
	for index < remaining_contents.len {
		ch := remaining_contents[index]
		match ch {
			`<` {
				// We are either at the start of a child node or the end of the current node
				if remaining_contents[index..index + name.len + 3] == '</${name}>' {
					// We are at the end of the current node
					children << inner_contents.str().trim_space()
					return XMLNode{
						name: name
						attributes: attributes
						children: children
					}, remaining_contents.all_after('</${name}>')
				} else {
					// We are at the start of a child node
					child, new_remaining := parse_single_node(remaining_contents[index..])!
					children << inner_contents.str().trim_space()
					children << child
					remaining_contents = new_remaining
					index = -1
				}
			}
			else {
				inner_contents.write_u8(ch)
			}
		}
		index++
	}
	return error('XML node <${name}> not closed.')
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

	return parse_children(name, attributes, contents[tag_end + 1..])
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
		comments: prolog.comments
		root: root
	}
}
