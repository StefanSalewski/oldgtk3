# GTK3 for nimrod, fix this:
#
# ugtk_reserved3*: proc () {.cdecl.}
# priv*: PComboBoxPrivate
#
arg0 = ARGV[0]
text = File.read(arg0)

pric = 0
resc = 0
res_inc = 1
File.open(arg0, "w") {|file|
	text.lines{|line|
		if /^\s*\w+Reserved\d\*?: proc \(\)/.match(line)
			resc += res_inc
			line.sub!('Reserved', "Reserved#{resc}")
			res_inc = 0
		else
			res_inc = 1
			if /^\s*priv\*?: (?:ptr )?\w+$/.match(line)
				pric += 1
				line.sub!('priv', "priv#{pric}")
				#puts line
			end
		end
		file.write(line)
	}
}

