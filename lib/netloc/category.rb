require 'set'
# Represents the files in a given category matched by a regular expression
class Netloc::Category
  
  attr_reader :files, :name, :regex, :lines_added, :lines_removed

  def initialize name, regex
    @name, @regex = name, regex
    @files = Set.new
    @lines_added = @lines_removed = 0
  end
  
  def match? filename
    filename =~ regex
  end
  
  def add(filename, added_lines, removed_lines)
    @files << filename
    @lines_added += added_lines
    @lines_removed -= removed_lines
  end
  
  def report(io)
    io.puts "#{name}:"
    io.puts "    #{'%7i' % files.size} files modified"
    io.puts "    #{'%7i' % size_of_changes} lines changed"
    io.puts "    #{'%+7i' % net} net lines #{ net >= 0 ? 'added' : 'removed'}"
  end
  
  def net
    lines_added + lines_removed
  end

  def size_of_changes
    lines_added
  end
  
end
