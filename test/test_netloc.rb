require 'helper'

class TestNetloc < Test::Unit::TestCase

  def setup
    @io = StringIO.new
  end
  should "compile stats in latest commit" do
    n = Netloc.new :out => @io, :verbose => true
    n.run
  end

  should "compile stats over historical commit" do
    n = Netloc.new :out => @io, :verbose => false, :since => '11f3f', :until => '5e3d2'
    n.run
    assert_equal <<EOF.strip, @io.string.strip
app code:
          2 files modified
         37 lines changed
        +12 net lines added
test code:
          1 files modified
         14 lines changed
        +12 net lines added
other:
          5 files modified
         74 lines changed
        +74 net lines added
EOF
  end
  
  should "omit commits by other user" do
    n = Netloc.new :out => @io, :verbose => false, :since => '11f3f', :until => '5e3d2', :author => 'Joe'
    n.run
    assert @io.string =~ /no activity found/
  end
  
  should "include commits by me" do
    n = Netloc.new :out => @io, :verbose => false, :since => '11f3f', :until => '5e3d2', :author => 'Bill Kayser'
    n.run
    assert @io.string !~ /no activity found/
  end
  
end
