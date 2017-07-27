# GTK3 for Nim, fix this:
#
# Entry* = object 
#   parent_instance*: Widget
# GParamSpecCharObj* = object 
#   parent_instance*: GParamSpecObj

arg0 = ARGV[0]
text = File.read(arg0)
text << "\n"
lines = text.lines
skip = 0
File.open(arg0, "w") {|file|
	lines.each_cons(2){|l1, l2|
		if skip > 0
			skip -= 1
			next
		end
		fix = nil
		if m1 = /(^\s*Broadway\w+\*)( = object)$/.match(l1)
			m2 = /^  \s*base\*: (\w+BaseMsgObj)$/.match(l2) || /^  \s*base\*: (\w+BaseObj)$/.match(l2)
			if m2
				fix = m1[1] + '{.final.}' + m1[2] + ' of ' + m2[1] + "\n"
			end
		elsif m1 = /(^\s*\w+ClassObj\*)( = object)$/.match(l1)
			m2 = /^  \s*(?:parent|base)(?:Class)?\*: (\w+\.?\w+Class(?:Obj)?)$/.match(l2)
			if m2
				fix = m1[1] + '{.final.}' + m1[2] + ' of ' + m2[1] + "\n"
			end
		elsif m1 = /(^\s*\w+\*)( = object)$/.match(l1)
			if m2 = /^  \s*parent(?:(?:Instance)|(?:Object))?\*: (\w+\.?\w+)$/.match(l2)
			#if m2
				fix = m1[1] + '{.final.}' + m1[2] + ' of ' + m2[1] + "\n"
			elsif m2 = /gIface\*: (gobject.GTypeInterfaceObj)/.match(l2)
				fix = m1[1] + '{.final.}' + m1[2] + ' of ' + m2[1] + "\n"
			elsif m2 = /`object`\*: (gobject.GObjectObj)/.match(l2)
				fix = m1[1] + '{.final.}' + m1[2] + ' of ' + m2[1] + "\n"
			#elsif m2 = /baseClass\*: (gobject.GObjectClassObj)/.match(l2)
			#	fix = m1[1] + '{.final.}' + m1[2] + ' of ' + m2[1] + "\n"
			end
		end
		if fix
			skip = 1
			file.write(fix)
		else
			file.write(l1)
		end
	}
}

