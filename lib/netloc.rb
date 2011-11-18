require 'set'
$LOAD_PATH.unshift File.dirname(__FILE__)
class Netloc

  require 'netloc/score.rb'
  require 'netloc/evaluator.rb'
  require 'netloc/category.rb'
  
  attr_reader :scores, :categories
  
  def initialize(options)
    @scores = []
    @io = options[:out] || STDOUT
    @to = options[:until] || 'HEAD'
    @from = options[:since] || 'HEAD^'
    @verbose = options[:verbose]
    @author = options[:author]
    @include = Regexp.new options[:include] if options.include? :include
    @categories = []
    @categories << Category.new('Application Code', ((options.include? :app_regex) ? Regexp.new(options[:app_regex]) : %r{(^app/)|(\.rb$)}))
    @categories << Category.new('Test Code', ((options.include? :test_regex) ? Regexp.newRegexp.new(options[:test_regex]) : %r{^test/}))
    @categories << Category.new('Other', /.*/) 
  end
  
  def run
    command = "git log '#{@from}..#{@to}'"
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
        process_line $1.to_i, $2.to_i, $3
      elsif line =~ /^<(.*?)> <(.*?)> (.*)$/
        process_commit $3, $2
        @io.puts "#$1   #$3 (#$2)" if @verbose
      end
    end
    if @files.empty?
      @io.puts "no activity found." if @files.empty?
    else
      evaluate_commit @commit.merge(:files => @commit_filecount,
                                    :lines_added => @commit_linesadded,
                                    :lines_deleted => @commit_linesdeleted)
    end
    
  end
    
  def report
    for category in categories
      next if category.files.empty?
      category.report @io
    end
    @io.puts
    @scores = Score.squish @scores
    total_weight = total_score = 0
    @scores.each do |s| 
      puts s.to_s 
      total_weight += s.weight
      total_score += s.points * s.weight
    end
    bottom_line = 50.0 + (10.0 * total_score / total_weight)
    puts "\nTotal score:  #{bottom_line.to_i}\n"
  end
  
  def process_line added, removed, file
    @commit_filecount += 1
    @commit_linesadded += added
    @commit_linesdeleted += removed
    @io.puts "processing #{'%+6i'%added.to_i}/#{'%-+6i'%(-removed.to_i)}#{file}" if @verbose
    return if @include && @include !~ file
    @files << file
    evaluate_file :file => file, :added => added, :removed => removed
    for category in categories
      if category.match? file
        category.add file, added.to_i, removed.to_i
        break
      end
    end
  end

  def process_commit description, author
    if @commit
      evaluate_commit @commit.merge(:files => @commit_filecount,
                                    :lines_added => @commit_linesadded,
                                    :lines_deleted => @commit_linesdeleted)
    end
    @commit_filecount = @commit_linesadded = @commit_linesdeleted = 0                                         
    @commit = {:description => description,
                :author => author}
  end
  
end
