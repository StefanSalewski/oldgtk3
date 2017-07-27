# GTK3 for Nim -- reorder #define
#
arg0 = ARGV[0]
arg1 = ARGV[1]
text = File.read(arg0)
$lines = text.lines.to_a
ident_pos = Array.new
$del = Array.new

$lines.each_with_index{|l, i|
#define GTK_TYPE_ACCEL_GROUP              (gtk_accel_group_get_type ())

#define GTK_TYPE_ACCEL_GROUP              (gtk_accel_group_get_type ())
	#if m = /^#define (#{arg1}_TYPE_\w+)\s+\((\w+)\s*\(\)\)/.match(l)
	if m = /^#define (#{arg1}_TYPE_\w+)\s+\((\w+)\s*\(\)\)/.match(l)
		puts 'hhhhhhhhhhhhhhhhhh'
		$del << i
		ident_pos << [i, m[1], m[2], l.gsub('()', '')]
	end
}

$del.each{|i| $lines[i] = nil}
$lines.compact!

$del.clear

ident_pos.each{|el|
	$lines.each_with_index{|l, i|
		if /#define .*\b#{el[1]}\b/.match(l)
			$del << i
			el << l
			puts l
		end
	}
}
#define G_TYPE_APP_INFO_CREATE_FLAGS (g_app_info_create_flags_get_type ())
#GLIB_AVAILABLE_IN_ALL GType g_app_info_create_flags_get_type (void) G_GNUC_CONST;

$del.each{|i| $lines[i] = nil}
$lines.compact!
#GType          gtk_accel_group_get_type           (void) G_GNUC_CONST;

#GType          gtk_accel_group_get_type           (void) G_GNUC_CONST;
ident_pos.each{|el|
  el[0] = 0

	$lines.each_with_index{|l, i|
		if /^(?:GLIB_AVAILABLE_IN_ALL )?GType\s+\b#{el[2]}\b/.match(l)
			puts 'xxxxxxxxxxxxxxxxxxxx'
			el[0] = i
			break
		end
	}
	if el[0] == 0
		puts 'error', el[2]
		exit
	end
}

ident_pos.sort_by!{|el| el[0]}

i = 0
puts 'www', ident_pos.length
puts ident_pos[0]
puts ident_pos[1]
File.open(arg0, "w") {|file|
	$lines.each{|l|
		file.write(l)
		if !ident_pos.empty? && i == ident_pos.first[0]
			puts 'rrrrrrrrrrrrrr'
			#puts ident_pos.first
			
			#puts ident_pos.first.length
			#puts ident_pos.first[3]
			#puts ident_pos.first[4]
			#puts ident_pos.first[5]
			#exit
			file.write(ident_pos.shift[3..-1].join(''))
		end
		i += 1
	}	
}

