require 'netloc/score.rb'
module Netloc::Evaluator

  # :description, :files, :hash, :author, :lines_added, :lines_deleted
  def evaluate_commit hash
    if hash[:description].length == 0
      scores << Netloc::Score.new(20, -3, :commitlog, "empty commit message")
    elsif hash[:description].length < 32
      scores << Netloc::Score.new(10, -1, :commitlog, "short commit message")
    elsif hash[:description].length > 60
      scores << Netloc::Score.new(10, +2, :commitlog, "detailed commit message")
    end
    if hash[:description] =~ /(^|\W)([A-Z]{4,12}-\d)+/
      scores << Netloc::Score.new(10, +1, :commit_ticket, "mentioned jira ticket #$2 in commit message")
    else
      scores << Netloc::Score.new(10, -1, :commit_ticket, "missing jira story in commit message")
    end
  end
  
  # :file, :added, :removed
  def evaluate_file hash
    
  end

  Netloc.send :include, self  
  
end
