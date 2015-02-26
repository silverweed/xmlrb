# xmlrb
Tiny XML parser for Ruby

## ...why?
I needed to parse XML in Ruby so I wrote my thing. It's nothing fancy: just a single file
exposing a "XML" module containing 2 classes: one for representing XML Nodes (named, cleverly
enough, `XML::Node`) and one for doing the parsing (guess how it's named? That's right: 
`XML::Parser`).

Usage:

```ruby
require '/path/to/xmlrb.rb'

parser = XML::Parser.new
# assuming `xml` contains an XML string:
root = parser.parse(xml)[:node]
```

I wrote this quite in a hurry, so it's not very nice and it probably needs some
reorganization, but it's working. Kinda.
I'll eventually document the `Node` class better.

## Requires
At least Ruby 1.9. I tested it with Ruby 2.x, but it *should* work with 1.9 too. It certainly doesn't work with 1.8.x.
