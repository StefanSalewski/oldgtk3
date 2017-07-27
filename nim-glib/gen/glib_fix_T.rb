# glib for Nim, fix this:
#  GString* = object 

arg0 = ARGV[0]
modname = ARGV[1]
remfix = ARGV[2] # remove that in sedlist
text = File.read(arg0)
new = String.new
sedlist = String.new
list = Array.new
privlist = Array.new
dep = Array.new

text.lines{|line|
	if m = /^(\s*)(\w+)\* = object( {.union.})?$/.match(line)
		if /INNER_C_UNION_/.match(m[2])
		  new << line
		elsif /rivate/.match(m[2]) && m[2] != 'GPrivate'
			privlist << m[2]
			new << m[1] + m[2] + "Obj = object#{m[3]}\n"
		else
			list << m[2]
			n = m[2]
			dep.push("{.deprecated: [P#{n}: #{n}, T#{n}: #{n}Obj].}\n")
			new << m[1] + n + 'salewski1911* =  ptr ' + n + "Obj\n"  
			new << m[1] + n + 'Ptr* = ptr ' + n + "Obj\n"  
			new << m[1] + n + "Obj* = object#{m[3]}\n"
		end
	else
		new << line
	end
}

privlist.sort_by!{|el| -el.length}
privlist.each{|pat|
	new.gsub!(/\b#{pat}\b/, pat + 'Obj')
}

list.sort_by!{|el| -el.length}
list.each{|pat|
	p1 = '\bptr ptr ' + pat + '\b'
	p2 = 'vaaaaar' + pat
	sedlist << "s/#{p1}/#{modname}#{p2.sub(remfix, '')}/g\n"
	new.gsub!(/#{p1}/, p2)
	p1 = '\bptr ' + pat + '\b'
	p2 = 'ptttttr' + pat
	sedlist << "s/#{p1}/#{modname}#{p2.sub(remfix, '')}/g\n"
	new.gsub!(/#{p1}/, p2)
	p1 = '\b' + pat + '\b'
	p2 = pat + 'Obj'
	sedlist << "s/#{p1}/#{modname}\.#{p2.sub(remfix, '')}/g\n"
	new.gsub!(/#{p1}/,  pat + 'O@bj') # with special marker!
}

# we have to care for aliases like
#type 
#  GInitiallyUnowned* = GObjectObj
#  GInitiallyUnownedClass* = GObjectClassObj

list = Array.new
text = new
new = String.new
text.lines{|line|
	if m = /^(\s*)(\w+)\* = (\w+O@bj ?)$/.match(line)
		list << m[2]
		n = m[2]
		dep.push("{.deprecated: [P#{n}: #{n}, T#{n}: #{n}Obj].}\n")
		new << m[1] + n + 'salewski1911* =  ptr ' + n + "Obj\n"  
		new << m[1] + n + 'Ptr* = ptr ' + n + "Obj\n"  
		new << m[1] + n + "Obj* = #{m[3]}\n"  
	else
		new << line
	end
}

list.sort_by!{|el| -el.length}
list.each{|pat|
	p1 = '\bptr ptr ' + pat + '\b'
	p2 = 'vaaaaar' + pat
	sedlist << "s/#{p1}/#{modname}#{p2.sub(remfix, '')}/g\n"
	new.gsub!(/#{p1}/, p2)
	p1 = '\bptr ' + pat + '\b'
	p2 = 'ptttttr' + pat
	sedlist << "s/#{p1}/#{modname}#{p2.sub(remfix, '')}/g\n"
	new.gsub!(/#{p1}/, p2)
	p1 = '\b' + pat + '\b'
	p2 = pat + 'Obj'
	sedlist << "s/#{p1}/#{modname}\.#{p2.sub(remfix, '')}/g\n"
	new.gsub!(/#{p1}/, p2)
}

new.gsub!('O@bj','Obj')

sedlist << "s/#{modname}vaaaaar/var #{modname}\./g\n"
sedlist << "s/#{modname}ptttttr/#{modname}\./g\n"
new.gsub!(/vaaaaar/, 'var ')
new.gsub!(/ptttttr/, '')
new.gsub!(/salewski1911/, '')

File.open(arg0, "w") {|file|
	file.write(new)
	#dep.uniq.each{|s|
	#	file.write(s)
	#}
}

File.open(ARGV[1] + '_sedlist', "w") {|file|
	file.write(sedlist)
}

