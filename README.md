# UPDATE: This project is now archived

The work done here has been incorporated into the V Standard Library: https://github.com/vlang/v/pull/19708

## Description

`xml` is a module to parse XML documents into a tree structure. It also supports
validation of XML documents against a DTD.

Note that this is not a streaming XML parser. It reads the entire document into
memory and then parses it. This is not a problem for small documents, but it
might be a problem for extremely large documents (several hundred megabytes or more).

## Usage

### Parsing XML Files

There are three different ways to parse an XML Document:

1. Pass the entire XML document as a string to `XMLDocument.from_string`.
2. Specify a file path to `XMLDocument.from_file`.
3. Use a source that implements `io.Reader` and pass it to `XMLDocument.from_reader`.

```v
import xml

...
doc := xml.XMLDocument.from_file('test/sample.xml')!
```

### Validating XML Documents

Simply call `validate` on the parsed XML document.

### Querying

Check the `get_element...` methods defined on the XMLDocument struct.

### Escaping and Un-escaping XML Entities

When the `validate` method is called, the XML document is parsed and all text
nodes are un-escaped. This means that the text nodes will contain the actual
text and not the escaped version of the text.

When the XML document is serialized (using `str` or `pretty_str`), all text nodes are escaped.

The escaping and un-escaping can also be done manually using the `escape_text` and `unescape_text` methods.
