module xml

fn (node XMLNode) get_element_by_id(id string) ?XMLNode {
	// Is this the node we're looking for?
	if 'id' in node.attributes && node.attributes['id'] == id {
		return node
	}

	if node.children.len == 0 {
		return none
	}

	// Recurse into children
	for child in node.children {
		match child {
			XMLNode {
				result := child.get_element_by_id(id)
				if result != none {
					return result
				}
			}
			else {
				// Ignore
			}
		}
	}

	return none
}

fn (node XMLNode) get_elements_by_tag(tag string) []XMLNode {
	mut result := []XMLNode{}

	if node.name == tag {
		result << node
	}

	if node.children.len == 0 {
		return result
	}

	// Recurse into children
	for child in node.children {
		match child {
			XMLNode {
				result << child.get_elements_by_tag(tag)
			}
			else {
				// Ignore
			}
		}
	}

	return result
}

pub fn (doc XMLDocument) get_element_by_id(id string) ?XMLNode {
	return doc.root.get_element_by_id(id)
}

pub fn (doc XMLDocument) get_elements_by_tag(tag string) []XMLNode {
	return doc.root.get_elements_by_tag(tag)
}
