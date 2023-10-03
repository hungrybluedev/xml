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

struct XMLDocument {
	Prolog
pub:
	root XMLNode [required]
}

// TODO: Add support for external entities
struct DTDEntity {
	name  string [required]
	value string [required]
}

struct DTDElement {
	name       string [required]
	definition string [required]
}

struct DocumentTypeDefinition {
	name string [required]
	// elements []DTDElement
	entities []DTDEntity
}

struct DocumentType {
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
