# GTK3 for Nim, fix this:
# Gdk_something -> something
require 'set'

arg0 = ARGV[0]
arg1 = ARGV[1]
text = File.read(arg0)

#while text.gsub!(/\([^()]*\)/,""); end # maybe ignore all in brackets

#words = text.split(/\W+/) # more than we really need
#words = text.scan(/\w+/) # the same I think
words = text.scan(/\.?\w+/) # 
set = Set.new(words)
#sub = Regexp.new(arg1)
sub = arg1 # when plain string
words.each{|w|
if w.start_with?(sub)
  if set.include?(w.sub!(sub, ''))
	  raise "Substitution results in ambiguity for: #{w}"
  end
end
}

if !text.gsub!(/\b#{sub}/, '')
	fail 'nothing to substitute!'
end

File.open(arg0, "w") {|file|
	file.write(text)
}

