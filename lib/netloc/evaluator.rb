require 'netloc/score.rb'
module Netloc::Evaluator

  # :description, :files, :hash, :author, :lines_added, :lines_deleted
  def evaluate_commit hash
    if hash[:description].length == 0
      scores << Netloc::Score.new(20, -3, "empty commit message")
    elsif hash[:description].length < 32
      scores << Netloc::Score.new(10, -1, "short commit message (#{hash[:description]})")
    elsif hash[:description].length > 60
      scores << Netloc::Score.new(10, +2, "detailed commit message")
    end
    if hash[:description] =~ /(^|\W)([A-Z]{4,12}-\d)+/
      scores << Netloc::Score.new(10, +1, "mentioned jira ticket #$2 in commit message")
    else
      scores << Netloc::Score.new(10, -1, "missing jira story in commit message")
    end
  end
  
  # :file, :added, :removed
  def evaluate_file hash
    
  end

  Netloc.send :include, self  
  
end
