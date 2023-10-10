module xml

pub type XMLNodeContents = XMLCData | XMLComment | XMLNode | string

pub struct XMLCData {
pub:
	text string [required]
}

pub struct XMLComment {
pub:
	text string [required]
}

pub struct XMLNode {
pub:
	name       string            [required]
	attributes map[string]string
	children   []XMLNodeContents
}

pub struct XMLDocument {
	Prolog
pub:
	root XMLNode [required]
}

pub type DTDListItem = DTDElement | DTDEntity

pub struct DTDEntity {
	name  string [required]
	value string [required]
}

pub struct DTDElement {
	name       string   [required]
	definition []string [required]
}

pub struct DocumentTypeDefinition {
	name string        [required]
	list []DTDListItem
}

pub struct DocumentType {
	name string
	dtd  DTDInfo
}

type DTDInfo = DocumentTypeDefinition | string

struct Prolog {
	parsed_reverse_entities map[string]string
pub:
	version  string       = '1.0'
	encoding string       = 'UTF-8'
	doctype  DocumentType = DocumentType{
		name: ''
		dtd: ''
	}
	comments []XMLComment
}
