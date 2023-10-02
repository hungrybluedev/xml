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

struct XMLDocument {
	Prolog
pub:
	root XMLNode [required]
}

struct Prolog {
pub:
	version  string = '1.0'
	encoding string = 'UTF-8'
	comments []XMLComment
}
