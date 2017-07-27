# glib for nim, fix this:
#type 
#  GOnceStatus* {.size: sizeof(cint).} = enum 
#    G_ONCE_STATUS_NOTCALLED, G_ONCE_STATUS_PROGRESS, G_ONCE_STATUS_READY
#
arg0 = ARGV[0]
text = File.read(arg0)
lines = text.each_line
new = String.new
dep = String.new
l = lines.next.dup

# caution, GIOStatus and such
loop do
	#if m = /^( +)([A-Z][a-z]*)?([A-Z]{1,2}[a-z]*)?([A-Z][a-z]+)?([A-Z][a-z]+)?.* = enum$/.match(l)
	if m = /^( +)(GI)?([A-Z]{1,2}[a-z]*)?([A-Z][a-z]+)?([A-Z][a-z]+)?.* = enum$/.match(l)
		indent = m[1] + '  '
		a = m[2..5]
		a.compact!
		l.gsub!('.} = enum', ', pure.} = enum')
		n = /^\s*(\w+)\* /.match(l)[1]
		dep << "{.deprecated: [T#{n}: #{n}].}\n"
		new << l
		l = lines.next.dup
		while !a.empty?
			s = a.join('_').upcase + '_'
			#break if s.length < 3 # do not remove only single letters
			if /#{indent}#{s}/.match(l)
				l.gsub!(' ' + s, ' ')
				l.gsub!(' END,', ' `END`,')
				l.gsub!(/ END$/, ' `END`')
				l.gsub!(' IMPORT,', ' `IMPORT`,')
				l.gsub!(' EXPORT,', ' `EXPORT`,')
				l.gsub!(' BIND,', ' `BIND`,')
				l.gsub!(' INCLUDE,', ' `INCLUDE`,')
				l.gsub!(' IN,', ' `IN`,')
				l.gsub!(' OUT,', ' `OUT`,')
				l.gsub!(' STATIC,', ' `STATIC`')
				l.gsub!(' CONTINUE,', ' `CONTINUE`,')
				new << l
				l = lines.next.dup
				while true do
					if /#{indent}#{s}/.match(l)
						l.gsub!(' ' + s, ' ')
						l.gsub!(' END,', ' `END`,')
						l.gsub!(/ END$/, ' `END`')
						l.gsub!(' IMPORT,', ' `IMPORT`,')
						l.gsub!(' EXPORT,', ' `EXPORT`,')
						l.gsub!(/ EXPORT$/, ' `EXPORT`')
						l.gsub!(' BIND,', ' `BIND`,')
						l.gsub!(' INCLUDE,', ' `INCLUDE`,')
						l.gsub!(' IN,', ' `IN`,')
						l.gsub!(' OUT,', ' `OUT`,')
						l.gsub!(' STATIC,', ' `STATIC`')
						l.gsub!(' CONTINUE,', ' `CONTINUE`,')
						new << l
						l = lines.next.dup
					else
						break
					end
				end
				break # better be carefully and break here
			else
				a.pop
			end
		end
	else
		new << l
		l = lines.next.dup
	end
end

File.open(arg0, "w") {|file|
	file.write(new)
	#file.write(dep)
}

