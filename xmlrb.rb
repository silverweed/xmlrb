# An XML parser
# Author: silverweed

module XML

class Node
	attr_reader :name, :attribs, :text, :children, :selfclosing

	def initialize(name, attribs = {}, text = "", children = [], selfclosing = false)
		@name = name
		@attribs = if attribs.is_a? String then pack_attribs(attribs) else attribs end
		@text = text
		@children = children
		@selfclosing = selfclosing
	end

	# converts a string of attributes into a hash
	def pack_attribs(attr)
		return {} unless attr.respond_to? 'scan'
		attr.scan(/[\w:]+\s*="\s*[^"]+"/).map{ |pair| pair.split '=' }.inject({}) do |r, s|
			r.merge!({ s[0].to_sym => s[1][1..-2] })
		end
	end

	def unpack_attribs(attr)
		attr.map{ |k, v| "#{k}=\"#{v}\"" }.join " "
	end

	def tree(depth = 0)
		node = self
		txt = "Node {\n" +
		     "  name:        #{node.name}\n" +
		     "  attrs:       #{node.attribs}\n" +
		     "  selfclosing: #{node.selfclosing}\n" +
		     "  text:        \"#{node.text}\"\n"
		txt += "  children:    "
		if node.children.nil?
			txt += "-"
		else
			txt += "\n"
			node.children.each do |n|
				if n.is_a? XML::Node
					txt += n.tree depth + 1
				else
					txt += n.to_s
				end
			end
		end
		txt += "\n}"
		txt = txt.split("\n").map{ |line| line = "  " * depth + line }.join "\n"
		return txt
	end

	def dump
		dump_header + (@selfclosing? "" : @text + "</#{@name}>")
	end

	def dump_header
		if @selfclosing
			"<#{@name}" + (!@attribs || @attribs.empty?? "" : " " + unpack_attribs(@attribs)) + "/>"
		else
			"<#{@name}" + (!@attribs || @attribs.empty?? "" : " " + unpack_attribs(@attribs)) + ">"
		end
	end

	def print_tree(depth = 0)
		txt = "<#{@name}" + (!@attribs || @attribs.empty?? "" : " " + unpack_attribs(@attribs)) + 
			(@selfclosing ? "/" : "") + ">"
		if @children.length > 0
			txt += "\n"
			@children.each do |c|
				txt += c.print_tree(depth + 1) + "\n"
			end
			#txt += "\n"
		else
			txt += @text
		end
		txt += "</#{@name}>" unless @selfclosing
		if depth == 0
			puts txt
		else
			return txt.split("\n").map{ |l| l = "   " + l }.join "\n"
		end
	end
end

class Parser 
	# Builds the XML tree from a string by finding the first tag and recursively calling itself
	# on the tag's content. Returns a Node, the text that was skipped before finding one, all
	# the text that was parsed this time (used for recursion mostly) and whether we terminated
	# before expected (isEOF)
	def parse(xml)
		# data
		skipped = ""
		all = ""
		content = ""
		tag = ""
		attribs = ""
		# tags with our same name we've opened in this tag content
		stack = 0
		# index
		i = 0
		# helpers
		@getchar = Proc.new {
			if xml.class != String || i > xml.length
				raise EOFError
			end
			c = xml[i]
			i += 1
			c
		}
		# assuming we're at the start of a tag, return it (plus any attributes).
		def get_this_tag(xml)
			buffer = ""
			c = @getchar.call
			while c != '>'
				buffer << c
				c = @getchar.call
			end
			return buffer.strip
		end
		return_data = Proc.new { |eof|
			children = []
			unless content.empty?
				toprocess = content
				while toprocess != nil and toprocess.length > 0
					child = parse toprocess
					toprocess = toprocess[child[:all].length..-1]
					children << child
				end
			end
			return {
				:skipped => skipped,
				:node    => Node.new(tag,
						     attribs,
						     content,
						     children.map{ |c| c[:node] }.find_all{ |n| !n.name.empty? },
						     (content.length == 0 and children.length == 0)
						    ),
				:all     => skipped + "<#{tag}" + (!attribs || attribs.empty? ? ">" : " #{attribs}>") + 
						"#{content}</#{tag}>",
				:isEOF   => eof
			}
		}
		# main loop
		loop do
			begin
				buffer = ""
				# read until a tag opening is found
				ch = @getchar.call i
				if ch == nil # we arrived at the end and found no tag
					return_data.call true
				end
				if ch != '<'
					unless tag.empty?
						content << ch
					else
						skipped << ch
					end
					next
				end
				# here we found a tag opening. If in_tag == false, it must be an
				# opening tag (throw error if not). Else, it can either be this
				# tag's closing tag or a sub-tag opening. Just continue processing
				# till we find the current tag's opening, and throw error if we
				# don't.
				buffer << ch
				unless tag.empty?  # we're in the tag
					this_tag = get_this_tag xml
					if this_tag == "/#{tag}" # it's the closing tag
						if stack == 0
							# we've closed all tags with our name, return.
							return_data.call false
						else
							stack -= 1
							content << "<#{this_tag}>"
						end
					else
						content << "<#{this_tag}>"
						stack += 1 if this_tag.split(" ")[0] == tag
					end
				else    # we found the opening tag
					tag_and_attribs = get_this_tag xml
					tag, attribs = tag_and_attribs.split " ", 2
					# check if self-closing tag or XML special tag
					if tag[-1] == "/" 
						return_data.call false
					elsif tag[0] == "?"
						# for now we ignore the XML header
						get_this_tag xml
					end
				end
			rescue EOFError
				$stderr.write "get_next_tag: EOF\n"
				return_data.call true
			end
		end
	end
end

end # module
