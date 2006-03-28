# NAME
#   Connect Four
#
# ALIASES
#   Plot Four, The Captain's Mistress
#

require 'board'
require 'game'

class ConnectFourBoard < Board
  def drop?( x )
    self[x,0].empty?
  end

  def drop( x, piece )
    (height-1).downto( 0 ) do |y|
      if self[x,y].empty?
        self[x,y] = piece; break
      end
    end
  end
end

class ConnectFour < Rules

  INFO = Info.new( __FILE__ )

  class State < Struct.new( :board, :turn )
    def to_s
      "Board:\n#{board}\nTurn: #{turn}"
    end
  end

  def ConnectFour.init
    State.new( ConnectFourBoard.new( 7, 6 ), PlayerSet.new( *players ) )
  end

  def ConnectFour.players
    [Piece.red,Piece.blue]
  end

  def ConnectFour.ops( state )
    return nil if final?( state )

    a = []

    state.board.width.times do |x|
      next unless state.board.drop?( x ) 

      p = state.turn

      op = Op.new( "Drop", "#{p.short}#{x}" ) do
        s = state.dup
        s.board.drop( x, s.turn.current )
        s.turn.next!
        s
      end
      op.freeze
      a << op
    end

    (a == []) ? nil : a
  end

  def ConnectFour.final?( state )
    empties = state.board.count( Piece.empty )

    return true  if empties == 0
    return false if empties >  7*6-4

    return state.board               =~ /(\S)\1\1\1/ ||
           state.board.rotate( 45 )  =~ /(\S)\1\1\1/ ||
           state.board.rotate( 90 )  =~ /(\S)\1\1\1/ ||
           state.board.rotate( 315 ) =~ /(\S)\1\1\1/
  end

  def ConnectFour.winner?( state, player )
    return state.board               =~ /(#{player.short})\1\1\1/ ||
           state.board.rotate( 45 )  =~ /(#{player.short})\1\1\1/ ||
           state.board.rotate( 90 )  =~ /(#{player.short})\1\1\1/ ||
           state.board.rotate( 315 ) =~ /(#{player.short})\1\1\1/
  end

  def ConnectFour.loser?( state, player )
    return !draw?( state ) &&
           state.board               !~ /(#{player.short})\1\1\1/ &&
           state.board.rotate( 45 )  !~ /(#{player.short})\1\1\1/ &&
           state.board.rotate( 90 )  !~ /(#{player.short})\1\1\1/ &&
           state.board.rotate( 315 ) !~ /(#{player.short})\1\1\1/
  end

  def ConnectFour.draw?( state )
    return state.board               !~ /(\S)\1\1\1/ &&
           state.board.rotate( 45 )  !~ /(\S)\1\1\1/ &&
           state.board.rotate( 90 )  !~ /(\S)\1\1\1/ &&
           state.board.rotate( 315 ) !~ /(\S)\1\1\1/
  end
end
