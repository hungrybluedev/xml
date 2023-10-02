module xml

import os
import strings

const (
	default_prolog_attributes = {
		'version':  '1.0'
		'encoding': 'UTF-8'
	}
)

fn parse_attributes(all_attributes string) !map[string]string {
	if all_attributes.contains_u8(`<`) {
		return error('Malformed XML. Found "<" in attribute string: "${all_attributes}"')
	}
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

fn parse_comment(contents string) !(XMLComment, string) {
	// We find the nearest '-->' to the start of the comment
	comment_end := contents.index('-->') or { return error('XML comment not closed.') }
	comment_contents := contents[4..comment_end]
	return XMLComment{comment_contents}, contents[comment_end + 3..]
}

fn parse_cdata(contents string) !(XMLCData, string) {
	// We find the nearest ']]>' to the start of the CDATA
	cdata_end := contents.index(']]>') or { return error('CDATA section not closed.') }
	cdata_contents := contents[9..cdata_end]
	return XMLCData{cdata_contents}, contents[cdata_end + 2..]
}

fn parse_prolog(contents string) !(Prolog, string) {
	if contents[0..5] != '<?xml' {
		// No prolog detected, return default
		return Prolog{}, contents
	}

	prolog_ending := contents[5..].index('?>') or { return error('XML declaration not closed.') }

	prolog_attributes := contents[5..prolog_ending + 5].trim_space()
	// '?>'.len == 2 and '<?xml'.len == 5
	mut offset_prolog_location := prolog_ending + 7

	attributes := if prolog_attributes.len == 0 {
		xml.default_prolog_attributes
	} else {
		parse_attributes(prolog_attributes)!
	}

	version := attributes['version'] or { return error('XML declaration missing version.') }
	encoding := attributes['encoding'] or { return error('XML declaration missing encoding.') }

	mut comments := []XMLComment{}

	mut remaining_contents := contents[offset_prolog_location..]

	for {
		// Skip any whitespace after the prolog
		for remaining_contents[0] in [` `, `\t`, `\n`] {
			remaining_contents = remaining_contents[1..]
		}
		if remaining_contents[0..4] == '<!--' {
			comment, remaining := parse_comment(remaining_contents)!
			comments << comment
			remaining_contents = remaining
		} else if remaining_contents[0] == `<` {
			// Found the start of the root node
			break
		}
	}

	return Prolog{version, encoding, comments}, remaining_contents
}

fn parse_children(name string, attributes map[string]string, contents string) !(XMLNode, string) {
	mut remaining_contents := contents
	mut inner_contents := strings.new_builder(remaining_contents.len)

	mut children := []XMLNodeContents{}

	for remaining_contents.len > 0 {
		ch := remaining_contents[0]
		match ch {
			`<` {
				if remaining_contents.starts_with('<!--') {
					// We are at the start of a comment
					comment, remaining := parse_comment(remaining_contents)!
					children << comment
					remaining_contents = remaining
				} else if remaining_contents.starts_with('<![CDATA') {
					// We are at the start of a CDATA section
					cdata, remaining := parse_cdata(remaining_contents)!
					children << cdata
					remaining_contents = remaining
				} else if remaining_contents.starts_with('</${name}>') {
					// We are at the end of the current node
					children << inner_contents.str().trim_space()
					return XMLNode{
						name: name
						attributes: attributes
						children: children
					}, remaining_contents.all_after('</${name}>')
				} else {
					// We are at the start of a child node
					child, new_remaining := parse_single_node(remaining_contents) or {
						if err.msg() == 'XML node cannot start with "</".' {
							return error('XML node <${name}> not closed.')
						} else {
							return err
						}
					}

					text := inner_contents.str().trim_space()
					if text.len > 0 {
						children << text
					}

					children << child
					remaining_contents = new_remaining
				}
			}
			else {
				inner_contents.write_u8(ch)
			}
		}
		remaining_contents = remaining_contents[1..]
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
			attributes: parse_attributes(tag_contents[name.len..tag_contents.len - 1].trim_space())!
		}, contents[tag_end + 1..]
	}

	attribute_string := tag_contents[name.len..].trim_space()
	attributes := parse_attributes(attribute_string)!

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

	prolog, root_contents := parse_prolog(contents)!
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
