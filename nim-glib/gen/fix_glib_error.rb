arg0 = ARGV[0]
text = File.read(arg0)
new = String.new
sedlist = Array.new
#t = ARGV[1] # GTK_
t = 'G_'
text.lines{|line|
	if m = (/^\s*#\s*define\s*(#{t}\w+_ERROR)\s+\((\w+\s*\(\))\)\s*$/.match(line) or /^\s*#\s*define\s*(#{t}\w+_ERROR)\s+(\w+\s*\(\))\s*$/.match(line))
		sedlist << "s/\b#{m[1]}\b/#{m[2].sub(t.downcase, '').sub(' ', '')}/g\n"
	else
		new << line
	end
}

File.open(arg0, "w") {|file|
	file.write(new)
}
sedlist.sort_by!{|el| -el.length}
File.open('glib_error_sedlist', "w") {|file|
	sedlist.each{|l|
		file.write(l + "\n")
	}
}

