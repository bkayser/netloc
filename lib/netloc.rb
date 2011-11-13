require 'set'

class Netloc

  def initialize(options) 
    @io = options[:out] || STDOUT
    @to = options[:until] || 'HEAD'
    @from = options[:since] || 'HEAD^'
    @verbose = options[:verbose]
    @author = options[:author]
    @include = Regexp.new options[:include] if options.include? :include
    @app_regex = (options.include? :app_regex) ? Regexp.new(options[:app_regex]) : %r{(^app/)|(\.rb$)}
    @test_regex = (options.include? :test_regex) ? Regexp.new(options[:test_regex]) : %r{^test/}
  end
  
  def run
    command = "git log #{@from}..#{@to}"
    command << " --numstat"
    command << " --oneline"
    command << " --ignore-all-space"
    command << " '--pretty=format:<%h> <%an> %s'"
    command << " '--author=#{@author}'" if @author
    @output = `#{command}`.split("\n").map(&:chomp)
    raise "command failed: '#{command}'" if $? != 0
    parse
    report
  end
  
  def parse
    @apps = []
    @tests = []
    @others = []
    @files = Set.new
    @output.each do | line |
      if line =~ /^(\d+)\s+(\d+)\s+(.*)$/
        process_line $1, $2, $3
      elsif line =~ /^<(.*?)> <(.*?)> (.*)$/
        @io.puts "#$1   #$3 (#$2)" if @verbose
      end
    end
    @io.puts "no activity found." if @files.empty?
  end
  
  def report
    for label, value in [["app code", @apps],['test code', @tests],['other', @others]] do
      next if value.empty?
      net = net(value)
      @io.puts "#{label}:"
      @io.puts "    #{'%7i' % value.size} files modified"
      @io.puts "    #{'%7i' % size_of_changes(value)} lines changed"
      @io.puts "    #{'%+7i' % net} net lines #{ net >= 0 ? 'added' : 'removed'}"
    end
  end
  
  def net(values)
    values.flatten.reduce{|a,b| a + b }
  end
  
  def size_of_changes(values)
    values.flatten.reduce{|a,b| (a > 0 ? a : 0) + (b > 0 ? b : 0) }
  end
  
  def process_line added, removed, file
    @io.puts "processing #{'%+6i'%added.to_i}/#{'%-+6i'%(-removed.to_i)}#{file}" if @verbose
    return if @include && @include !~ file
    @files << file
    case file
      when @test_regex
        @tests <<  [added.to_i, -removed.to_i]
      when @app_regex
        @apps <<   [added.to_i, -removed.to_i]
      else
        @others << [added.to_i, removed.to_i]
    end
  end
  
end
