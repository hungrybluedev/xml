module xml

pub type XMLNodeContents = DTDEntity | XMLCData | XMLComment | XMLNode | string

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

// TODO: Add support for external entities
pub struct DTDEntity {
	name  string [required]
	value string [required]
}

pub struct DTDElement {
	name       string [required]
	definition string [required]
}

pub struct DocumentTypeDefinition {
	name string [required]
	// elements []DTDElement
	entities []DTDEntity
}

pub struct DocumentType {
	name     string
	dtd_type string
	dtd      DTDInfo
}

type DTDInfo = DocumentTypeDefinition | string

struct Prolog {
pub:
	version  string = '1.0'
	encoding string = 'UTF-8'
	doctype  DocumentType
	comments []XMLComment
}
