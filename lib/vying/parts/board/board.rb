# Copyright 2007, Eric Idema except where otherwise noted.
# You may redistribute / modify this file under the same terms as Ruby.


class Board

  attr_reader :shape, :cell_shape, :directions, :coords, :cells, 
              :width, :height, :length, :occupied
  protected :cells

  # Initialize a board.

  def initialize( h )
    @width  = h[:width]
    @height = h[:height]
    @length = h[:length]

    @shape = h[:shape]
    @cell_shape = h[:cell_shape]
    @directions = h[:directions]

    if @shape.nil?
      raise "board requires the :shape param"
    end

    omit = (h[:omit] || []).map { |c| Coord[c] }

    case h[:shape]
      when :square
        @length ||= @width
        @width  ||= @length
        @height ||= @length

        if @length.nil?
          raise "square board requires the :length or :width params"
        end

        @cell_shape ||= :square
        @directions ||= [:n, :s, :e, :w, :ne, :sw, :nw, :se]

      when :rect
        
        if @width.nil? || @height.nil?
          raise "rect board requires both the :width and :height params"
        end

        @cell_shape ||= :square
        @directions ||= [:n, :s, :e, :w, :ne, :sw, :nw, :se]

      when :triangle

        if @length.nil?
          raise "triangle board requires the :length param"
        end

        @width  = @length
        @height = @length

        @width.times do |x|
          @height.times do |y|
            omit << Coord[x,y] if x + y >= length
          end
        end

        @cell_shape ||= :hexagon
        @directions ||= [:n, :s, :e, :w, :ne, :sw]

      when :rhombus

        if @width.nil? || @height.nil?
          raise "rhombus board requires both the :width and :height params"
        end

        @cell_shape ||= :hexagon
        @directions ||= [:n, :s, :e, :w, :ne, :sw]

      when :hexagon

        if @length.nil?
          raise "hexagon board requires the :length param"
        end

        @width  = @length * 2 - 1
        @height = @length * 2 - 1

        @width.times do |x|
          @height.times do |y|
            omit << Coord[x,y] if (x - y).abs >= @length
          end
        end

        @cell_shape ||= :hexagon
        @directions ||= [:n, :s, :e, :w, :nw, :se]
    end

    if @width && @height 
      @cells = Array.new( @width * @height, nil )
      @coords = CoordsProxy.new( self, Coords.new( width, height, omit ) )
    end

    @occupied = Hash.new( [] )
    @occupied[nil] = @coords.to_a.dup

    fill( h[:fill] ) if h[:fill]
  end

  # Perform a deep copy on this board.

  def initialize_copy( original )
    @cells = original.cells.dup
    @occupied = Hash.new( [] )
    original.occupied.each { |k,v| @occupied[k] = v.dup }
  end

  # Compare boards for equality.

  def ==( o )
    o.respond_to?( :cells ) && o.respond_to?( :width ) &&
    o.width == width && cells == o.cells
  end

  # Return a hash code for this board.

  def hash
    [cells,width].hash
  end

  # Return a count of pieces on the board.  If a piece is given, only that
  # pieces is counted.  If no piece is given, all pieces are counted.  Empty
  # cells are never counted (see #empty_count).

  def count( p=nil )
    return occupied[p].length if p
    occupied.inject(0) { |m,v| m + (v[0] ? v[1].length : 0) }
  end

  # Count of empty (unoccupied) cells.  This is equivalent to calling
  # unoccupied.length.

  def empty_count
    width * height - count
  end

  # Get all the pieces in the selected row.

  def row( y )
    (0...width).map { |x| cells[ci(x,y)] }
  end

  # Move whatever piece is at the start coord (sc) to the end coord (ec).
  # If there was a piece at the end coord it is overwritten.

  def move( sc, ec )
    self[sc], self[ec] = nil, self[sc]
    self
  end

  # Get a list of the coords of unoccupied cells (that is the value at
  # the coord is nil).

  def unoccupied
    occupied[nil]
  end

  # Iterate over each piece on the board.

  def each
    coords.each { |c| yield self[c] }
  end

  # Iterate over pieces from the start coord in the given directions.  The
  # start coord is not included.

  def each_from( s, directions )
    i = 0
    directions.each do |d|
      c = s
      while (c = coords.next( c, d )) && yield( self[c] )
        i += 1
      end
    end
    i
  end

  # Clear all the pieces from the board.

  def clear
    fill( nil )
  end

  # Fill the entire board with the given piece.

  def fill( p )
    if coords.omitted.empty?
      cells.each_index { |i| cells[i] = p }

      @occupied = Hash.new( [] )
      @occupied[p] = @coords.to_a.dup
    else
      coords.each { |c| self[c] = p }
    end

    self
  end

  # This can be overridden perform some action before a cell on the board is
  # overwritten (as with #[]=).  The given piece (p) is the value at the given
  # (x,y) coordinate before it's changed.

  def before_set( x, y, p )
  end

  # This can be overridden perform some action after a cell on the board has
  # been overwritten (as with #[]=).  The given piece (p) is the value at the 
  # given (x,y) coordinate after it's been changed.

  def after_set( x, y, p )
  end

  # Returns a string representation of this Board.  This is simple 
  # fixed-width ascii with one character per cell.  The character is the
  # first letter of the string representation of the piece in that cell.
  # The rows and columns are all labeled.

  def to_s
    off = height >= 10 ? 2 : 1                                
    w = width

    letters = ' '*off + 'abcdefghijklmnopqrstuvwxyz'[0..(w-1)] + ' '*off + "\n"

    s = letters
    height.times do |y|
      s += sprintf( "%*d", off, y+1 )
      s += row(y).inject( '' ) do |rs,p|
        rs + (p.nil? ? ' ' : p.to_s[0..0])
      end
      s += sprintf( "%*d\n", -off, y+1 )
    end
    s + letters
  end

  class CoordsProxy
    def initialize( board, coords )
      @board, @coords = board, coords
    end

    def ring( coord, d )
      @coords.ring( coord, d, @board.cell_shape, @board.directions )
    end

    def neighbors( coord )
      @coords.neighbors( coord, @board.directions )
    end

    def neighbors_nil( coord )
      @coords.neighbors_nil( coord, @board.directions )
    end

    def to_a
      @coords.to_a
    end

    def respond_to?( m )
      m != :_dump && (super || @coords.respond_to?( m ))
    end

    def method_missing( m, *args, &block )
      if m != :_dump && @coords.respond_to?( m ) 
        @coords.send( m, *args, &block )
      else
        super
      end
    end
  end


end

