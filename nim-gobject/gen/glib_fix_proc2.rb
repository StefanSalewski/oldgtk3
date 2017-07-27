# glib for nimrod, fix this:
# proc g_byte_array_remove_index*(array: ptr GByteArray; index: guint): ptr GByteArray {.
#    importc: "g_byte_array_remove_index", libglib.}
#
# http://stackoverflow.com/questions/1509915/converting-camel-case-to-underscore-case-in-ruby
#
# should be a safe operation -- compiler should detect name conflicts for us.
#
class String
  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end
last_line = nil
arg0 = ARGV[0]
text = File.read(arg0)
text << "\n"
sublist = Array.new
new = String.new
File.open(arg0, "w") {|file|
	text.lines{|line|
		if last_line
			long = last_line.chop + line
			if m = /^\s*proc ([a-z]+_)?([a-z]+_)?([a-z]+_)?([a-z]+_)?([a-z]+_)?([a-z]+_)?([a-z]+_)?(\w*)\*\(\s*(\w+):(?: ptr)? (\w+)/.match(long)
				a, b, c, d, e, f, g, x, pp, dt = m[1..10]
				if a && pp && dt
					dt = dt.underscore
					b ||= ''
					c ||= ''
					d ||= ''
					e ||= ''
					f ||= ''
					g ||= ''
					x ||= ''
					c1 = c2 = ''
					p = pp + '_'
					if (a + b + c + d + e + f + g == p) || (a + b + c + d + e + f == p) || (a + b + c + d + e == p) || (a + b + c + d == p) || (a + b + c == p) || (a + b == p) || (a == p)
						c1 = pp
					end
					p = dt + '_'
					if (a + b + c + d + e + f + g == p) || (a + b + c + d + e + f == p) || (a + b + c + d + e == p) || (a + b + c + d == p) || (a + b + c == p) || (a + b == p) || (a == p)
						c2 = dt
					end
					p = (c1.length > c2.length ? c1 : c2)
					if p.length > 0
					sublist << [a + b + c + d + e + f + g + x, p]
						last_line.sub!(p + '_', '')
					end
				end
			end
			new << last_line
			#file.write(last_line)
		end
		last_line = line.dup
	}
}

#sublist.each{|el| print el.first, ' ', el.last, "\n"}
sublist.each{|el|
  a = el.first
  b = el.last
  c = a.sub(b + '_', '')
	puts a, c
  text.gsub!(/([^"])\b#{a}\b/, '\1' + c)
}

File.open(arg0, "w") {|file|
file.write(text)
}
