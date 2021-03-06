# Copyright 2007, Eric Idema except where otherwise noted.
# You may redistribute / modify this file under the same terms as Ruby.

require 'vying/ai/bot'
require 'vying/rules'

class RandomBot < Bot
  def initialize( username=nil, id=nil )
    id ||= 387

    super( username, id )
  end

  def select( sequence, position, player )
    moves = position.moves( player )
    moves[rand(moves.size)]
  end

  def self.plays?( rules )
    true
  end
end

