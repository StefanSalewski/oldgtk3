# GTK3 for Nim -- reorder struct position to reduce forward references
#
arg0 = ARGV[0]
text = File.read(arg0)
$lines = text.lines.to_a
ident_pos = Array.new
$del = Array.new
$sub = Array.new

# $lines[n] is the start of struct
# we mark these $lines for deletion.
# m is the first ident occurence, we try to
# locate a struct or 'typedef enum' before this position
def fix_it(n, m)
	puts 'fix_it', n, m
	fail unless $lines[n].index('struct') == 0
	buf = Array.new
	done = false
	c = 0
	# copy struct to buf and mark those $lines for deletion
	while true
		l = $lines[n]
		if l != nil
			h = l.count('{')
			done = true if h > 0
			c = c + h - l.count('}')
			buf << l.dup
			$del << n
			break if done && c == 0
		end
		n += 1
	end
	done = false
	while true
		break if m == 0
		done = true if $lines[m].index('}')
		break if done && ($lines[m].index('struct') == 0 || $lines[m].index('typedef enum') == 0)
		m -= 1
	end
	done = false
	c = 0
	# go to end of that struct
	while m > 0 # put it at line 0 if no struct found -- if that really occurs, manually fix!
		l = $lines[m]
		h = l.count('{')
		done = true if h > 0
		c = c + h - l.count('}')
		break if done && c == 0
		m += 1
	end
	$sub << [m, buf]
end

def fix_it2(n, m)
	puts 'fix_it2', n, m
	fail unless $lines[n].index('typedef struct') == 0
	$del << n
	done = false
	while true
		if /^typedef struct\s+\w+{}\s+\w+\s*;\s*$/.match($lines[m])
			$sub << [m, $lines[n].dup]
			return
		end
		break if m == 0
		done = true if $lines[m].index('}')
		break if done && ($lines[m].index('struct') == 0 || $lines[m].index('typedef enum') == 0)
		m -= 1
	end
	done = false
	c = 0
	# go to end of that struct
	while m > 0 # put it at line 0 if no struct found -- if that really occurs, manually fix!
		l = $lines[m]
		h = l.count('{')
		done = true if h > 0
		c = c + h - l.count('}')
		break if done && c == 0
		m += 1
	end
	$sub << [m, $lines[n].dup]
end

# move struct declaration in front of first reference to it
# repeat a few times -- may take forever when stucts refer to each other
4.times do
puts '+++++++++++++++++++++++++++++++++++++++++'
ident_pos.clear
$del.clear
$sub.clear
# record each line starting with keyword struct
$lines.each_with_index{|l, i|
	if m = /^struct\s+(\w+)\s*$/.match(l)
		ident = m[1]
		ident_pos << [ident, i]
	end
}
#is there a reference earlier?
ident_pos.each{|ident, line_num|
	com = 0
	$lines.each_with_index{|line, i|
		break if i == line_num
		com += 1 if line.index('/*')
		com -= 1 if line.index('*/')
		fail if com < 0
		next if com != 0
		if /\b#{ident}\b/.match(line)
			puts ident
			fix_it(line_num, i) # move struct from line_num up to position i
			break
		end
	}
}

$sub.sort_by!{|x| x[0]}
$lines.map!.with_index{|l, i| i == $del.first ? ($del.shift; nil) : l}
new_lines = Array.new
$lines.each_with_index{|l, i|
	new_lines << l if l
	while !$sub.empty? && $sub.first[0] == i
		new_lines.concat($sub.shift[1])
	end
}
$lines = new_lines.compact
end

# move 'typedef struct' in front of first reference to it
# only one repetition necesary
1.times do
puts '============='
ident_pos.clear
$del.clear
$sub.clear

$lines.each_with_index{|l, i|
	if m = /^typedef struct\s+\w+\{\}\s+(\w+)\s*;\s*(?:\/\*|$)/.match(l)
	#if m = /typedef struct\s+\w+\{\}\s+(\w+);\s*$/.match(l)
		ident = m[1]
		ident_pos << [ident, i]
	end
}
ident_pos.each{|ident, line_num|
	com = 0
	$lines.each_with_index{|line, i|
		break if i == line_num
		com += 1 if line.index('/*')
		com -= 1 if line.index('*/')
		fail if com < 0
		next if com != 0
		if /\b#{ident}\b/.match(line)
			puts ident
			fix_it2(line_num, i)
			break
		end
	}
}

$sub.sort_by!{|x| x[0]}
$lines.map!.with_index{|l, i| i == $del.first ? ($del.shift; nil) : l}
new_lines = Array.new
$lines.each_with_index{|l, i|
	new_lines << l if l
	while !$sub.empty? && $sub.first[0] == i
		new_lines << $sub.shift[1]
	end
}
$lines = new_lines.compact
end

File.open(arg0, "w") {|file|
	$lines.each{|l| file.write(l)}
}

