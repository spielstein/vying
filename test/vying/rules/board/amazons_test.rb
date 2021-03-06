require 'test/unit'

require 'vying'
require 'vying/rules/rules_test'

class TestAmazons < Test::Unit::TestCase
  include RulesTests

  def rules
    Amazons
  end

  def test_info
    assert_equal( "Amazons", rules.name )
  end

  def test_players
    assert_equal( [:white,:black], rules.new.players )
  end

  def test_initialize       # Need to be more thorough here
    g = Game.new( rules )
    assert_equal( :white, g.turn )
    assert_equal( nil, g.lastc )
  end

  def test_has_moves
    g = Game.new( rules )
    assert_equal( [:white], g.has_moves )
    g << g.moves.first
    assert_equal( [:white], g.has_moves )
    g << g.moves.first
    assert_equal( [:black], g.has_moves )
    g << g.moves.first
    assert_equal( [:black], g.has_moves )
    g << g.moves.first
    assert_equal( [:white], g.has_moves )
  end

  def test_moves
    g = Game.new( rules )
    moves = g.moves

    assert_equal( "a4a3", moves[0].to_s )
    assert_equal( "a4a2", moves[1].to_s )
    assert_equal( "a4a1", moves[2].to_s )
    assert_equal( "a4b4", moves[3].to_s )
    assert_equal( "j4f8", moves[-2].to_s )
    assert_equal( "j4e9", moves[-1].to_s )

    g << g.moves.first until g.final?

    assert_not_equal( g.history[0], g.history.last )
  end
end

