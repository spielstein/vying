# Copyright 2008, Eric Idema, Dieter Stein except where otherwise noted.
# You may redistribute / modify this file under the same terms as Ruby.

require 'vying'

# Attangle
#
# For detailed rules see:  http://vying.org/games/attangle
# or the official Attangle site: http://attangle.com

Rules.create( 'Attangle' ) do
  name    'Attangle'
  version '1.0.0'

  players :white, :black
  option :board_size, :default => 4, :values => Array( 3..6 )

  score_determines_outcome

  cache :moves

  position do
    attr_reader :board, :pool, :triples

    def init
      @board = Board.hexagon( :length => @options[:board_size], :plugins => [:stacking] )
      p = ((board.length * 2 - 1) ** 2 - board.length * (board.length - 1) - 1) / 2
      @pool = { :white => p, :black => p }
      @triples = ((board.length - 3) * 2 + 1).freeze
      @center = Coord.new( board.length - 1, board.length - 1 ).freeze
    end

    def has_moves
      score( opponent( turn ) ) < triples && ( pool[turn] > 0 || capture_moves.any? ) ? [turn] : []
    end

    def moves
      all = []
      all += board.unoccupied - [@center] if pool[turn] > 0
      all += capture_moves
    end

    def apply!( move )
      coords = move.to_coords
      if coords.length == 1
        board[coords.first] = [turn]
        pool[turn] -= 1
      else
        if board[coords.first].length == 1
          board[coords.last] = board[coords[1]] + board[coords.last]
        else
          board[coords.last] = board[coords.first] + board[coords.last]
        end
        board[coords.last].flatten!
        board[coords.first] = board[coords[1]] = nil
        pool[turn] += 1
      end
      rotate_turn
      self
    end

    def final?
      has_moves.empty?
    end

    def score( player )
      count = 0
      board.occupied.each_pair do |c, p|
        next if c.nil?
        count += p.length if c.first == player && c.length == 3
      end
      count
    end

    def hash
      [board, pool, triples, turn].hash
    end

    private

    def capture_moves
      all = []
      board.occupied.each do |allc|
        if !allc.first.nil? && allc.first.first == opponent( turn )

          allc.last.each do |c|
            # Collect all possible attacking pieces
            attackers = []
            board.directions.each do |d|
              scanc = c
              while scanc = board.coords.next( scanc, d )
                if !board[scanc].nil? && board[scanc].first == turn
                  attackers << [ scanc, board[scanc].length ]
                  break
                end
              end
            end

            # Construct all possible moves
            attackers.each do |a1|
              attackers.each do |a2|
                if a1 != a2 && a1.last + a2.last + board[c].length <= 4
                  all << "#{a1.first}#{a2.first}#{c}"
                end
              end
            end

          end
        end
      end
      all
    end

  end
end
