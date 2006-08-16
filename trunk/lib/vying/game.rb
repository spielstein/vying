require "yaml"

class GameResults
  attr_reader :rules, :seed, :sequence, :user_map
  
  def initialize( game )
    @rules = game.rules.to_s
    @seed = game.respond_to?( :seed ) ? game.seed : nil
    @sequence = game.sequence
    @user_map = {}
    game.user_map.each { |k,v| @user_map[k] = [v.user_id, v.username] }
  end
end

class Game
  attr_reader :rules, :history, :sequence, :user_map

  def initialize( rules, seed=nil )
    @rules, @history, @sequence, @user_map = rules, [rules.new( seed )], [], {}
    yield self if block_given?
  end

  def method_missing( method_id, *args )
    if history.last.respond_to?( method_id )
      return history.last.send( method_id, *args )
    end
    super.method_missing( method_id, *args )
  end

  def respond_to?( method_id )
    history.last.respond_to?( method_id ) ||
    rules.respond_to?( method_id ) ||
    super.respond_to?( method_id )
  end

  def append( op )
    if op?( op )
      @history << apply( op )
      @sequence << op
      return self
    end
    raise "'#{op}' not a valid operation"
  end

  def append_list( ops )
    i = 0
    begin
      ops.each { |op| append( op ); i += 1 }
    rescue
      i.times { undo }
    end
    self
  end

  def append_string( ops, regex=/,/ )
    append_list( ops.split( regex ) )
  end

  def <<( ops )
    if ops.kind_of? String
      return append_string( ops )
    elsif ops.kind_of? Enumerable
      return append_list( ops )
    else
      return append( ops )
    end
  end

  def undo
    [@history.pop,@sequence.pop]
  end

  def register_users( h )
    user_map.merge!( h )
  end

  def step
    has_ops.each do |p|
      if players.include?( p )
        op = user_map[p].select( history.last.dup, p )
        if op?( op, p )
          self << user_map[p].select( history.last.dup, p )
        else
          raise "#{user_map[p].username} attempted invalid op: #{op}"
        end
      elsif p == :random
        ops = history.last.ops
        self << ops[history.last.rng.rand(ops.size)]
      end
    end
    self
  end

  def play
    step until final?
    results
  end

  def results
    GameResults.new( self )
  end

  def Game.replay( results )
    g = Game.new( Kernel.const_get( results.rules ), results.seed )
    g << results.sequence
    g
  end

  def to_s
    history.last.to_s
  end
end

# Requires all files that appear to be Rules/Bot on the standard library path
Rules.find
Bot.find

