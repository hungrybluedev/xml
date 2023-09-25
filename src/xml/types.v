module xml

pub type XMLNodeContents = XMLNode | string

pub struct XMLNode {
pub:
	name       string            [required]
	attributes map[string]string
	children   []XMLNodeContents
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
