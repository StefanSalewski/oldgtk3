# GTK3 for Nim, fix this:
# proc gtk_app_chooser_button_new*(content_type: CSTRING): Widget {.
#    cdecl, importc: "gtk_app_chooser_button_new", dynlib: lib.}
#
# http://stackoverflow.com/questions/1509915/converting-camel-case-to-underscore-case-in-ruby
class String
  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end
# http://stackoverflow.com/questions/9524457/converting-string-from-snake-case-to-camel-case-in-ruby
class String
	def camel_case
  	return self if self !~ /_/ && self =~ /[A-Z]+.*/
  	split('_').map{|e| e.capitalize}.join
	end
end

arg0 = ARGV[0]
last_line = nil
text = File.read(arg0)
text << "\n"
File.open(arg0, "w") {|file|
	text.lines{|line|
		if last_line
			# New(_ in next line is wrong -- we do not touch it for now!
			if m = /^\s*proc gtk(\w+)New(_\w+)?\*\(/.match(last_line)
				res = m[1].dup#.camel_case
				if last_line.sub!('): GtkWidget ', '): Gtk' + res + ' ')
					file.write(last_line)
					last_line = line.dup
				else
					file.write(last_line)
					last_line = line.dup
					last_line.sub!('): GtkWidget ', '): Gtk' + res + ' ')
				end
			else
				file.write(last_line)
				last_line = line.dup
			end
		else
			last_line = line.dup
		end
	}
}

