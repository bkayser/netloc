require 'set'
require 'net/http'
require 'json'
$LOAD_PATH.unshift File.dirname(__FILE__)
class Netloc

  require 'netloc/score.rb'
  require 'netloc/evaluator.rb'
  require 'netloc/category.rb'
  
  attr_reader :scores, :categories
  
  def initialize(options)
    @scores = []
    @io = options[:out] || STDOUT
    @license_key = options[:license_key]
    if @license_key
      @platform_host = options[:platform_host] || "collector.newrelic.com"
      # In New Relic commit hook mode, only send data on last commit 
      # and look up author in config
      @from, @to = 'HEAD^', 'HEAD'
      @author_name = %x[git config --get user.name].chomp
      @author_name = %x[git config --get user.email].chomp if @author_name.strip.empty?
      @test = options[:test]
      @repo_name = %x[git remote show origin -n].to_s[%r{/([^/.]+).git}, 1] || File.basename(File.realpath('.'))
    else
      @from = options[:since] || 'HEAD^'
      @to = options[:until] || 'HEAD'
      @author = options[:author]
    end
    @verbose = options[:verbose]
    @include = Regexp.new options[:include] if options.include? :include
    @categories = []
    @categories << Category.new(:app, 'Application Code', ((options.include? :app_regex) ? Regexp.new(options[:app_regex]) : %r{(^app/)|(\.rb$)}))
    @categories << Category.new(:test, 'Test Code', ((options.include? :test_regex) ? Regexp.newRegexp.new(options[:test_regex]) : %r{^test/}))
    @categories << Category.new(:other, 'Other', /.*/) 
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
    if @license_key
      report_metrics_to_rpm
    else
      report
    end
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
    process_commit
    categories_by_id = {}
    categories.each { |c| categories_by_id[c.id] = c }
    evaluate_categories categories_by_id
    @io.puts "no activity found." if @files.empty? 
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
    0
  end

  def report_metrics_to_rpm
    metrics = {}
    files = Set.new
    for category in categories
      next if category.files.empty?
      files += category.files
      metrics["Component/Catagory/Changes/#@author_name/#{category.name}[files]"] = category.files.size
      metrics["Component/Category/Lines added/#@author_name/#{category.name}[lines]"] = category.lines_added
      metrics["Component/Category/Lines removed/#@author_name/#{category.name}[lines]"] = -category.lines_removed

      metrics["Component/Category/All changes/#{category.name}[files]"] = category.files.size
      metrics["Component/Category/All Lines added/#{category.name}[lines]"] = category.lines_added
      metrics["Component/Category/All Lines removed/#{category.name}[lines]"] = -category.lines_removed
    end
    metrics["Component/Commits/Total changes[files]"] = files.size
    metrics["Component/Commits/Total commits[commits]"] = 1
    metrics["Component/Commits/Author commits/#@author_name[commits]"] = 1

    if @verbose
      @io.puts "Sending metrics to New Relic:"
      metrics.to_a.sort.each do | metric, val |
        @io.puts "  #{'%8i'%val} #{metric} "
      end
    end
    
=begin    @scores = Score.squish @scores
    total_weight = total_score = 0
    @scores.each do |s| 
      total_weight += s.weight
      total_score += s.points * s.weight
    end
    bottom_line = 50.0 + (10.0 * total_score / total_weight)
=end
    body = {}
    body['agent'] = {
      host: %x[hostname].chomp,
      name: "Git Activity Plugin",
      version: "1.0.0"
    }
    body["components"] = [{
      duration: 60, 
      guid: "5df209bd50c36b2674601f5692a3a57951b760d7",
      metrics: metrics,
      name: @repo_name
      }]
    if @test
      @io.puts body.inspect
      return
    end
    uri = URI.parse("http://#{@platform_host}/platform/v1/metrics")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request['X-License-Key'] = @license_key
    request['Content-Type'] = 'application/json'
    request.body = body.to_json
    response = http.request(request)
    if response.code == '200'
      @io.puts "Data accepted by New Relic" if @verbose
    else
      $stderr.puts "Unable to send stats to New Relic"
      $stderr.puts "Response from server (status: #{response.code}):\n   #{response.body.inspect}"
    end
  end  

  def process_line added, removed, file
    @commit_filecount += 1
    @commit_linesadded += added
    @commit_linesdeleted += removed
    @io.puts "processing #{'%+6i' % added.to_i}/#{'%-+6i'%(-removed.to_i)}#{file}" if @verbose
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

  def process_commit description=nil, author=nil
    if @commit
      evaluate_commit @commit.merge(:files => @commit_filecount,
                                    :lines_added => @commit_linesadded,
                                    :lines_deleted => @commit_linesdeleted)
    end
    return unless description && author
    @commit_filecount = @commit_linesadded = @commit_linesdeleted = 0                                         
    @commit = {:description => description,
                :author => author}
  end
  
end
