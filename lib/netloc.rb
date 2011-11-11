require 'set'

class Netloc

  def initialize(*range)  
    @to = 'HEAD'
    if range.empty?
      @from = 'HEAD~2'
    elsif range.size == 1
      @from = range[0]
    else
      @from, @to = *range
    end
  end
  
  def run
    @output = %X[git log #{@from}..#{@to} --numstat --oneline].split("\n").map(&:chomp)
    parse
    report
  end
  
  def parse
    @netapp = 0
    @nettest = 0
    @netother = 0
    @files = Set.new
    @output.each do | line |
      if line =~ /^(\d+)\s+(\d+)\s+(.*)$/
        process_line $1, $2, $3
      end
    end
  end
  
  def report
    puts "App:   #{'%7i' % @netapp}"
    puts "Test:   #{'%7i' % @netapp}"
    puts "Other:   #{'%7i' % @netapp}"
  end
  
  def process_line added, removed, file
    puts "processing #{file}..."
    @files << file
    case file
      when %r{^test/}
        @nettest += added.to_i - removed.to_i
      when %r{(^app/)|(\.rb$)}
        @netapp += added.to_i - removed.to_i
      else
        @netother += added.to_i - removed.to_i
    end
  end
  
end
