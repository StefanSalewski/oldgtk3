# glib for Nim, fix this:
# const 
#   GDK_TYPE_DEVICE* = (gdk_device_get_type())
# proc device_get_type*(): GType {.importc: "gdk_device_get_type", 
#                                      libgdk.}

arg0 = ARGV[0]
text = File.read(arg0)
text << "\n\n"
new = String.new
list = Array.new
skip = 0
text.lines.each_cons(3){|l1, l2, l3|
	skip -= 1
	next if skip > 0
	if /^\s*const $/.match(l1)
		if m1 = /^(\s*)(\w+)\* = \((\w+)\(\)\)/.match(l2)
			list << [m1[2], m1[3]]
			skip = 2
			if /^(\s*)/.match(l3)[1].length < m1[1].length
			  next
			end
		end
	end
	new << l1
}

list.each{|n|
  fn = n[1].sub('gdk_', '')
  new.sub!(/(proc #{fn}\*\(\): \w+ \{.*?\})/m, '\1' + "\nconst #{n[0]}\* = #{fn}")
}
File.open(arg0, "w") {|file|
	file.write(new)
}

