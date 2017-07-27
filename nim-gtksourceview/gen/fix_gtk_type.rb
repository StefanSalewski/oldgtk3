arg0 = ARGV[0]
text = File.read(arg0)
new = String.new
sedlist = Array.new
t = ARGV[1] # GTK_


#puts t.downcase

text.lines{|line|
	if m = (/^\s*#\s*define\s*(#{t}TYPE_\w+)\s+\((\w+\s*\(\))\)\s*$/.match(line) or /^\s*#\s*define\s*(#{t}TYPE_\w+)\s+(\w+\s*\(\))\s*$/.match(line))
		#x = m[2].sub(t.downcase, '').sub(' ', '')
		#puts x
		sedlist << "s/#{m[1]}/#{m[2].sub(t.downcase, '').sub(' ', '')}/g\n"
	else
		new << line
	end
}


File.open(arg0, "w") {|file|
	file.write(new)
}
sedlist.sort_by!{|el| -el.length}
File.open('gtk_type_sedlist', "w") {|file|
	sedlist.each{|l|
		file.write(l + "\n")
	}
}

