class Netloc::Score
  
  GOOD = "+"
  BAD = "O"
  
  attr_accessor :points, :count, :weight, :description, :type, :id
  def initialize weight, points, type, description
    @count = 1
    @type = type
    @weight = weight
    @points = points
    @description = description
  end
  
  def <=> other
    v = self.type.to_s <=> other.type.to_s
    v = self.points <=> other.points if v == 0
    v = self.description <=> other.description if v == 0
    v
  end
  
  # return an array of scores where scores of the same type are combined. 
  def self.squish tail, head=[]
    return head if tail.empty? 
    next_to_combine = tail.delete(tail.min)
    if head.empty?
      head << next_to_combine
    else
      head += head.pop.combine_if_you_can next_to_combine
    end
    squish tail, head
  end
  
  def combine_if_you_can other
    return [self, other] unless self.type == other.type && self.description == other.description
    self.count += other.count
    self.points = ((self.weight * self.points) + (other.weight * other.points)) / (self.weight + other.weight)
    self.weight += other.weight
    [self]
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
    s = "#{pattern.gsub ' ', '.'}  #{@description}"
    s << " (#{@count} occurrences)" if @count > 1
    s
  end
  
end
  