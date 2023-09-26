module xml

import strings

pub const default_entities = {
	'lt':   `<`
	'gt':   `>`
	'amp':  `&`
	'apos': `'`
	'quot': `"`
}

pub const default_entities_reverse = {
	`<`: 'lt'
	`>`: 'gt'
	`&`: 'amp'
	`'`: 'apos'
	`"`: 'quot'
}

[params]
pub struct EscapeConfig {
	content          string          [required]
	reverse_entities map[rune]string = xml.default_entities_reverse
}

pub fn escape_text(config EscapeConfig) string {
	mut buffer := strings.new_builder(config.content.len)
	for ch in config.content.runes() {
		if ch in config.reverse_entities {
			buffer.write_u8(`&`)
			buffer.write_string(config.reverse_entities[ch])
			buffer.write_u8(`;`)
		} else {
			buffer.write_rune(ch)
		}
	}
	return buffer.str()
}

[params]
pub struct UnescapeConfig {
	content  string          [required]
	entities map[string]rune = xml.default_entities
}

pub fn unescape_text(config UnescapeConfig) !string {
	mut buffer := strings.new_builder(config.content.len)
	mut index := 0
	runes := config.content.runes()
	for index < runes.len {
		match runes[index] {
			`&` {
				mut offset := 1
				mut entity_buf := strings.new_builder(8)
				for index + offset < runes.len && runes[index + offset] != `;` {
					entity_buf.write_rune(runes[index + offset])
					offset++
				}
				// Did we reach the end of the string?
				if index + offset == runes.len {
					return error('Unexpected end of string while parsing entity.')
				}
				// Did we find a valid entity?
				entity := entity_buf.str()
				if entity in config.entities {
					buffer.write_rune(config.entities[entity])
					index += offset
				} else {
					return error('Unknown entity: ' + entity)
				}
			}
			else {
				buffer.write_rune(runes[index])
			}
		}
		index++
	}
	return buffer.str()
}
