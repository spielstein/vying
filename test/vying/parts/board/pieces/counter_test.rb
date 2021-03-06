
require 'test/unit'
require 'vying'

class TestCounter < Test::Unit::TestCase

  def test_initialize
    c = Counter[:red, 1]
    
    assert_equal( :red, c.player )
    assert_equal( 1, c.count )

    c2 = Counter[:red, 1]

    assert_equal( :red, c2.player )
    assert_equal( 1, c2.count )
    assert_equal( c.object_id, c2.object_id )
    assert_equal( c, c2 )

    c3 = Counter[:blue, 1]

    assert_equal( :blue, c3.player )
    assert_equal( 1, c3.count )
    assert_not_equal( c.object_id, c3.object_id )
    assert_not_equal( c, c3 )

    c4 = Counter[:blue, 3]

    assert_equal( :blue, c4.player )
    assert_equal( 3, c4.count )
    assert_not_equal( c3.object_id, c4.object_id )
    assert_not_equal( c3, c4 )
  end

  def test_add
    c = Counter[:red, 1]

    assert_equal( :red, c.player )
    assert_equal( 1, c.count )

    c += 1

    assert_equal( :red, c.player )
    assert_equal( 2, c.count )

    c += Counter[:blue, 3]

    assert_equal( :red, c.player )
    assert_equal( 5, c.count )
  end

  def test_sub
    c = Counter[:red, 5]

    assert_equal( :red, c.player )
    assert_equal( 5, c.count )

    c -= 1

    assert_equal( :red, c.player )
    assert_equal( 4, c.count )

    c -= Counter[:blue, 3]

    assert_equal( :red, c.player )
    assert_equal( 1, c.count )
  end
end

