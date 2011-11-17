class Netloc::Score
  
  GOOD = "+"
  BAD = "O"
  
  def initialize weight, points, description
    @weight = weight
    @points = points
    @description = description
  end
  
  def to_s
    space = ' ' * (3 - @points.abs)
    pattern = case @points
      when (-3..-1)
        '%3s   ' % (BAD * -@points)
      when (1..3)
        '   %-3s' % (GOOD * @points)
      else
        '      '
    end
    "#{pattern}  #{@description}"
  end
  
end
  