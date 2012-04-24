package SudokuBoard;

use SudokuSquare;
use Data::Dumper;
use Storable qw(dclone);
use Moose;
use Scalar::Util qw(weaken);

=head1 NAME

SudokuBoard

=head1 SYNOPSIS

  use SudokuBoard;
  $board = SudokuBoard->new();

  $board->set_puzzle($txt);
  $board->display();
  $board->solve();
  $ans = $board->is_solved();

  $num = $board->get_num_unset();

=head1 CONSTRUCTOR

=over

=item new()

Creates new SudokuBoard.  Generally no arguments are given.

=back

=head1 METHODS

=head2 width()
=head2 height()
=head2 block_width()
=head2 block_height()

These return fixed values for the width & height of a puzzle, and the width & height of the sub-blocks within it.

=cut 

my @dims = qw(width height block_width block_height);
for my $i (0..3) {
  #this breaks Moose's 'fourth wall' a bit, but I didn't want to type this stuff 4 times
  has $dims[$i] => 
    ( is => 'ro',
      isa => 'Int',
      default => sub { my $self = shift; 
		       return $self->_dimensions()->[$i]; 
		     }
    );
}

=head2 square(X,Y)

Returns the SudokuSquare object at the given coordinates in the puzzle.

=cut

sub square {
  my $self = shift;
  my $idx = join(':',@_);
  return $self->squares()->{$idx};
}

=head2 all_squares()

Returns list of all SudokuSquare objects in the puzzle.  Useful for iterating over all squares.

=cut

sub all_squares {
  my $self = shift;
  return values( %{$self->squares()} );
}

=head2 set_puzzle( PUZZLE_STRING )

Sets the values in the puzzle based on the string given, which should have one line per row of the puzzle, with each character on each line representing one square.  A space is used for each open square.

=cut

sub set_puzzle {
  my $self = shift;
  my $puz_str = shift;
  my @lines = split( /\n/m, $puz_str );
  if( @lines != $self->height() ) {
    die "wrong number of lines!";
  }
  for my $i (0..$#lines) {
    chomp($lines[$i]);
    my @v = split( //, $lines[$i] );
     for my $j (0..$#v) {
      #print "$i,$j = $v[$j]\n";
       if( $v[$j] !~ /\s/ ) {
	 $self->square($i,$j)->from_str($v[$j]);
       }
    }
  }
}

=head2 display()

Prints an ascii-art representation of the puzzle to STDOUT.

=cut

sub display {
  my $self = shift;
  my $disp_type = 'VAL';
  if( @_ > 0 ) {
    $disp_type = shift;
  }
  my $h_bar = "-" x ($self->width()*2 + 1);
  print "$h_bar\n";
  for my $i (0..$self->height()-1) {
    print "|";
    for my $j (0..$self->width()-1) {
      if( $disp_type eq 'VAL' ) {
	print $self->square($i,$j)->to_str();
      } elsif( $disp_type eq 'OPT' ) {
	if( defined( $self->square($i,$j)->value() ) ) {
	  print ' ';
	} else {
	  print $self->square($i,$j)->get_num_possible();
	}
      } else {
	print ' ';
      }
      if( ($j+1) % $self->block_width() == 0 ) {
	print '|';
      } else {
	print ' ';
      }
    }
    if( ($i+1) % $self->block_height() == 0 ) {
      print "\n$h_bar\n";
    } else {
      print "\n";
    }
  }
}

=head2 get_num_unset()

Returns the number of squares without a definite value().

=cut

sub get_num_unset {
  my $self = shift;
  my $num_unset = 0;
  map { $num_unset++ } grep {not defined} map { $_->value() } $self->all_squares();
  return $num_unset;
}

=head2 is_solved()

Returns a true value if all squares have a definite value.

=cut

sub is_solved {
  my $self = shift;
  return (0 == $self->get_num_unset());
}

=head2 solve(DISPLAY)

Attempts to solve the puzzle.  Returns true if successful.  First attempts deterministic methods, then tries guessing a single value, followed by re-application of deterministic methods, backtracking when the puzzle is found to be unsolvable.

=cut

sub solve {
  my ($self,$display,$depth) = @_;
  $depth ||= 1;
  if( $self->solve_det($display) ) {
    return 1;
  } else {
    #guess values, then try to continue solving
    my @uncertain_squares = 
      map { $_->[1] }
	sort { $a->[0] <=> $b->[0] }
	  map { [$_->get_num_possible(), $_] }
	    grep { not defined $_->value() } $self->all_squares();
    my $orig_squares = $self->squares();
    for my $unc (@uncertain_squares) {
      for my $v ($unc->possibilities()) {
	#clone the board, so we can revert later if needed
	my $squares_dupe = dclone($orig_squares);
	$self->squares( dclone($orig_squares) );
	#get the clone of the current square in question
	my $sq = $self->square( @{$unc->index()} );
	print " " . ("." x $depth) . "Trying $v at (" . join(",",@{$sq->index()}) . ")\n";
	$sq->value($v);
	my $sol = 
	  eval {
	    $self->solve($display,$depth+1);
	  };
	if( $@ and $@ !~ /UNSOLVABLE/ ) {
	  die $@;
	} elsif( $sol ) {
	  return 1;
	}
      }
    }
    #nothing yielded a solution:
    return 0;
  }
}

=head1 SUBCLASSING

To create a subclass, you should override at least _square_class() and _dimensions().  See HexdokuBoard.pm for an example.

=head1 INTERNALS

The following functions are used internally by SudokuBoard.

=head2 square_class()

=head2 _square_class()

Return the name of the class to use for creating squares in the puzzle.  When subclassing, override _square_class() -- it is a Moose builder sub for square_class().

=cut

has 'square_class' =>
( is => 'ro',
  isa => 'ClassName',
  builder => '_square_class'
);

sub _square_class {
  return 'SudokuSquare';
}

=head2 squares()

Returns the hash ref of all squares in the puzzle.

=cut

has 'squares' =>
( is => 'rw',
  isa => 'HashRef[SudokuSquare]',
  builder => '_build_squares',
);

=head2 _dimensions()

Returns an array ref containing the width, height, width of sub-blocks, height of sub-blocks.  Used by the width() method, etc.

=cut

sub _dimensions {
  my $self = shift;
  return [9,9,3,3];
}

=head2 _square_indexes()

Returns a list of the indexes of all squares in the puzzle, based on the values in _dimensions().  Override for 3D or otherwise non-rectangular puzzles.

=cut

sub _square_indexes {
  my $self = shift;
  my @idx;
  for my $i (0..$self->width()-1) {
    for my $j (0..$self->height()-1) {
      push @idx, [$i,$j]
    }
  }
  return @idx;
}

=head2 _coset_indexes()

Return a list of array refs, one for each co-set (group of cells which must contain all possible values).  In normal Sudoku, this is the rows, columns, and three-by-three blocks.  Cosets are build based on _dimensions().

=cut

sub _coset_indexes {
  my $self = shift;
  my @cosets;
  #row sets
  for my $i (0..$self->height()-1) {
    push @cosets, [map { [$i,$_] } (0..$self->width()-1) ];
  }
  #column sets
  for my $i (0..$self->width()-1) {
    push @cosets, [map { [$_,$i] } (0..$self->height()-1) ];
  }

  for( my $w = 0; $w < $self->width(); $w += $self->block_width() ) {
    for( my $h = 0; $h < $self->height(); $h += $self->block_height() ) {
      my @block;
      for my $i (0..$self->block_width()-1) {
	for my $j (0..$self->block_height()-1) {
	  push @block, [$w+$i,$h+$j];
	}
      }
      push @cosets, \@block;
    }
  }
  return @cosets;
}

=head2 _build_squares()

Builder method for squares(); creates SudokuSquare objects to populate the board.  Behavior is controlled by _square_indexes() and _coset_indexes().

=cut

sub _build_squares {
  my $self = shift;
  my %squares;

  for my $index ($self->_square_indexes()) {
    my $idx = join(":",@$index);
    my $sq = $self->square_class()->new( index => $index );
    $squares{$idx} = $sq;

    if( $squares{$idx} ne $sq ) {
      die "Mismatch!";
    }
  }

  #do all the cosets:
  for my $cos ($self->_coset_indexes()) {
    my @coset = map { my $ref = $squares{$_}; weaken($ref); $ref } map { join(':',@$_); } @$cos;
    for my $sq (@coset) {
      $sq->add_coset( @coset );
    }
  }
  return \%squares;
}

=head2 solve_det( DISPLAY ) 

Tries deterministic solution methods.  If DISPLAY is true, calls display() after each pass.  Returns true value if puzzle is solved.  Dies with "UNSOLVABLE" if puzzle is not solvable.

=cut

sub solve_det {
  my $self = shift;
  my $display = 0;
  if( @_ ) {
    $display = shift;
  }
  my $num_iter = 0;
  while( 1 ) {
    my $num_improved = 0;
    for my $sq ($self->all_squares()) {
      if( $sq->compare_to_cosets() ) {
	$num_improved++;
      }
    }
    if( $display ) {
      $self->display();
    }
    $num_iter++;
    if( $num_improved == 0 ) {
      if( $self->is_solved() ) {
	print "Solved!\n";
	return 1;
      } else {
	return 0;
      }
    }
  }
}



1;

#end
