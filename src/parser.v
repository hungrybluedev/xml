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

		if key.len == 0 {
			return error('Malformed XML. Found empty attribute key.')
		}

		if key in attributes {
			return error('Malformed XML. Found duplicate attribute key: ${key}')
		}
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

fn parse_entity(contents string) !(DTDEntity, string) {
	// We find the nearest '>' to the start of the ENTITY
	entity_end := contents.index('>') or { return error('Entity declaration not closed.') }
	entity_contents := contents[9..entity_end]

	name := entity_contents.trim_left(' \t\n').all_before(' ')
	value := entity_contents.all_after_first(name).trim_space().trim('"\'')

	// TODO: Add support for SYSTEM and PUBLIC entities

	return DTDEntity{name, value}, contents[entity_end + 1..]
}

fn parse_element(contents string) !(DTDElement, string) {
	// We find the nearest '>' to the start of the ELEMENT
	element_end := contents.index('>') or { return error('Element declaration not closed.') }
	element_contents := contents[9..element_end]

	name := element_contents.trim_left(' \t\n').all_before(' ')
	definition_string := element_contents.all_after_first(name).trim_space().trim('"\'')

	definition := if definition_string.starts_with('(') {
		// We have a list of possible children

		// Ensure that both ( and ) are present
		if !definition_string.ends_with(')') {
			return error('Element declaration not closed.')
		}

		definition_string.trim('()').split(',')
	} else {
		// Invalid definition
		return error('Invalid element definition: ${definition_string}')
	}

	// TODO: Add support for SYSTEM and PUBLIC entities

	return DTDElement{name, definition}, contents[element_end + 1..]
}

fn parse_doctype(contents string) !(DocumentType, string) {
	// We may have more < in the doctype so keep count
	mut depth := 0
	mut ending_location := 0
	for i, ch in contents {
		match ch {
			`<` {
				depth++
			}
			`>` {
				depth--
				if depth == 0 {
					ending_location = i
					break
				}
			}
			else {}
		}
	}

	if ending_location == 0 {
		return error('DOCTYPE declaration not closed.')
	}

	doctype_end := ending_location
	doctype_contents := contents[10..doctype_end]

	name := doctype_contents.all_before(' ').trim_space()

	mut list_contents := doctype_contents.all_after(' [').all_before(']').trim_space()
	mut items := []DTDListItem{}

	for list_contents.len > 0 {
		if list_contents.starts_with('<!ENTITY') {
			entity, remaining := parse_entity(list_contents)!
			items << entity
			list_contents = remaining.trim_space()
		} else if list_contents.starts_with('<!ELEMENT') {
			element, remaining := parse_element(list_contents)!
			items << element
			list_contents = remaining.trim_space()
		} else {
			return error('Unknown DOCTYPE list item: ${list_contents}')
		}
	}

	return DocumentType{
		name: name
		dtd: DocumentTypeDefinition{
			name: ''
			list: items
		}
	}, contents[doctype_end + 1..]
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
	mut doctype := DocumentType{
		name: ''
		dtd: ''
	}
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
		} else if remaining_contents.starts_with('<!DOCTYPE') {
			// We are at the start of a DOCTYPE declaration
			doctype, remaining_contents = parse_doctype(remaining_contents)!
		} else if remaining_contents[0] == `<` {
			// Found the start of the root node
			break
		}
	}

	return Prolog{
		version: version
		encoding: encoding
		doctype: doctype
		comments: comments
	}, remaining_contents
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
					continue
				} else if remaining_contents.starts_with('<![CDATA') {
					// We are at the start of a CDATA section
					cdata, remaining := parse_cdata(remaining_contents)!
					children << cdata
					remaining_contents = remaining
					continue
				} else if remaining_contents.starts_with('</${name}>') {
					// We are at the end of the current node
					collected_contents := inner_contents.str().trim_space()
					if collected_contents.len > 0 {
						// We have some inner text
						children << collected_contents
					}
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
					continue
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

pub fn XMLDocument.from_file(path string) !XMLDocument {
	contents := os.read_file(path) or { return error('Could not read file: ${path}') }
	return XMLDocument.from_string(contents)!
}

pub fn XMLDocument.from_string(raw_contents string) !XMLDocument {
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
		doctype: prolog.doctype
		root: root
	}.validate()
}
