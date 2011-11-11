require 'set'

class Netloc

  def initialize(options) 
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
    command << " '--pretty=format:<%h> <%an> %s'"
    command << " '--author=#{@author}'" if @author
    @output = `#{command}`.split("\n").map(&:chomp)
    exit if $? != 0
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
        puts "#$1   #$3 (#$2)" if @verbose
      end
    end
  end
  
  def report
    for label, value in [["app code", @apps],['test code', @tests],['other', @others]] do
      puts "#{'%14s'%label}:  #{net(value)} lines in #{value.size} files" unless value.empty?
    end
  end
  
  def net(values)
    '%+7i' % values.flatten.reduce{|a,b| a + b }
  end
  
  def process_line added, removed, file
    puts "processing #{'%+6i'%added.to_i}/#{'%-+6i'%(-removed.to_i)}#{file}" if @verbose
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
