# GTK3 for Nim

h = Hash.new
new = String.new
text = File.read(ARGV[0])
text.each_line{|l|
	if m = /struct/.match(l)
		#m = /^\s*typedef\s+struct\s+(_\w+)\s+\w+\s*;\s*$/.match(l)
		m = /^\s*typedef\s+struct\s+(_\w+)\s+\w+\s*;/.match(l)
		if m
			h[m[1]] = m[0]
		else
			new << l
		end
	end
}

new.each_line{|l|
	#m = /^\s*struct\s+(_\w+)\s*$/.match(l)
	m = /^\s*struct\s+(_\w+)/.match(l)
	if m
		h.delete(m[1])
	end
#	if m && h.include?(m[1])
#		s = h[m[1]].chop
#		print "sed -i 's/", s, "/", s.sub(/(_\w+)(\s+)/, '\1{} '), "/' final.h\n"
#	end
}

h.each_value{|s|
	#s.chop!
	print "sed -i 's/", s, "/", s.sub(/(_\w+)(\s+)/, '\1{} '), "/' final.h\n"
}









