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
    else
      scores << Netloc::Score.new(5, +1, :commitlog, "standard commit message")
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
  
  def evaluate_categories categories
    # No tests modified at all...
    if categories[:test].size_of_changes == 0
      # ...but a lot of new code added
      if categories[:app].net >= 100
        scores << Netloc::Score.new(60, -3, :tests, "no updated tests for more than 100 lines of new code")
      # ...but a little new code added
      elsif categories[:app].net >= 10
        scores << Netloc::Score.new(50, -2, :tests, "no updated tests for new code")
      # ...no new code but some code changed
      elsif categories[:app].size_of_changes > 0
        scores << Netloc::Score.new(40, -1, :tests, "no tests updated")
      end
    # tests updated but not added
    elsif categories[:test].net <= 5
      # ...and a lot of new code added
      if categories[:app].net >= 100
        scores << Netloc::Score.new(40, -2, :tests, "no new tests for more than 100 lines of new code")
      # ...and some new code changed
      elsif categories[:app].size_of_changes > 10
        scores << Netloc::Score.new(30, -1, :tests, "no new tests")
      end
    end
    
    if categories[:test].net > 200
      scores << Netloc::Score.new(80, 3, :tests, "more than 200 lines of new test code")
    elsif categories[:test].net > 50
      scores << Netloc::Score.new(60, 2, :tests, "more than 50 lines of new test code")
    end
    
    if categories[:app].net < 200
      scores << Netloc::Score.new(100, 3, :tests, "more than 200 lines of code purged")
    elsif categories[:app].net < 50
      scores << Netloc::Score.new(80, 3, :tests, "more than 50 lines of code purged")
    elsif categories[:app].net < 0
      scores << Netloc::Score.new(60, 3, :tests, "more code purged than added")
    end
  end
  Netloc.send :include, self  
  
end
