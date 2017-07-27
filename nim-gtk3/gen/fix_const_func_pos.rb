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


text.each_line{|l|

  puts l

}

exit


enum = text.lines.to_enum

l = enum.next
while l

	puts l

	e = enum.next
end

exit


text.lines.each_cons(3){|l1, l2, l3|
	skip -= 1
	next if skip > 0
	if /^\s*const$/.match(l1)
		if m1 = /^(\s*)(\w+)\* = \((\w+)\(\)\)/.match(l2)
			list << [m1[2].downcase, m1[3]]
			skip = 2
			if /^(\s*)/.match(l3)[1].length < m1[1].length
			  next
			end
		end
	end
	new << l1
}


list.each{|n|

  new.sub!(n[0], n[0]+ '()')
}


list.each{|n|
  fn = n[1].sub('gtk_', '')
  new.sub!(/(proc #{n[1]}\*\(\): \w+ \{.*?\})/m, '\1' + "\nconst #{n[0]}\* = #{fn}")
}
File.open(arg0, "w") {|file|
	file.write(new)
}

