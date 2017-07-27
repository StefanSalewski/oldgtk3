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
File.open(arg0, "w") {|file|
	text.lines{|line|
		if last_line
			long = last_line.chop + line
			if m = /^\s*proc \w*\*\(\s*(`?\w+`?):(?: ptr){0,2} (\w+)/.match(long)
				pp, dt = m[1..2]
				if pp && dt
					if dt == 'Gunichar'
						dt = 'GUnichar'
					elsif dt == 'cstring'
						if last_line[0..11] == 'proc gString'
						  dt = 'gString'
						elsif last_line[0..8] == 'proc gStr'
						  dt = 'gStr'
						end

					elsif dt == 'GSList'
						dt = 'GSlist'
					elsif dt == 'GData'
						dt = 'GDatalist'
					elsif dt == 'GIOChannel'
						dt = 'GIoChannel'
					#elsif dt == 'GHookList' && b == 'hook_' && c != 'list_'
					#	dt = 'GHook'
					#elsif dt == 'GSequenceIter' && b == 'sequence_' && c != 'iter_'
					#	dt = 'GSequence'
					end
					#dt = dt.underscore
					#b ||= ''
					#c ||= ''
					#d ||= ''
					#e ||= ''
					#f ||= ''
					#g ||= ''
					#c1 = c2 = ''
					#p = pp + '_'
					#if (a + b + c + d + e + f + g == p) || (a + b + c + d + e + f == p) || (a + b + c + d + e == p) || (a + b + c + d == p) || (a + b + c == p) || (a + b == p) || (a == p)
					#	c1 = pp
					#end
					#p = dt + '_'
					#if (a + b + c + d + e + f + g == p) || (a + b + c + d + e + f == p) || (a + b + c + d + e == p) || (a + b + c + d == p) || (a + b + c == p) || (a + b == p) || (a == p)
					#	c2 = dt
					#end
					#p = (c1.length > c2.length ? c1 : c2)
					if dt.length > 0
						dt[0] = dt[0].downcase
						last_line.sub!('proc ' + dt, 'proc ')
            last_line.sub!(/proc [A-Z]/, &:downcase)
					end
				end
			end
					if /proc g[A-Z]/.match(last_line)
            last_line.sub!(/(proc )g([A-Z])/, '\1\2')
            last_line.sub!(/proc [A-Z]/, &:downcase)

					end
				#end
			#end
			file.write(last_line)
		end
		last_line = line.dup
	}
}

