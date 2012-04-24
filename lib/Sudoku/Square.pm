package Sudoku::Square;

use 5.008000;
use strict;
use warnings;

use Moose;

our $VERSION = '0.1';

=head1 NAME

Sudoku::Square

=head1 SYNOPSIS

  use Sudoku::Square;
  $sq = Sudoku::Square->new(\@index);

  @possible = $sq->possibilities();
  $val = $sq->value();
  $sq->value(7); #set the value

  $sq->compare_to_cosets();

=head1 DESCRIPTION

The Sudoku::Square class is meant to be used by Sudoku::Board.  It keeps track of the value or possible values of the square, as well as the cosets (my name for the regions in a sudoku puzzle where each value must appear exactly once, and can perform inferences about its value based on the 

=head1 SUBCLASSING

To make a sub-class of Sudoku::Square, you need to override all_possibilities(), and possibly from_str() and to_str() if the display form of values are anything besides numbers (e.g. for hexadecimal sudoku).  See Sudoku::HexSquare.pm in this package for an example.

=head1 CONSTRUCTOR

=over 4

=item new( index => $idx );

Create a new Sudoku::Square.  $idx should be an arrayref of coordinates for this square within the puzzle (it's an array to allow for more than 2 dimensions).

=back

=head1 METHODS

=head2 value( [ VALUE ] )

Get or set the value of the square.  Return undef for an un-set square.

=cut
has 'value' =>
(
 is => 'rw',
 isa => 'Int',
 trigger => \&_set_value
);

=head2 possible()

Returns a hash-ref of possible values.  Keys are the possibilities, and values are 1 for allowable possibilities, 0 for ruled-out possibilities.

=cut

has 'possible' =>
( is => 'ro',
  isa => 'HashRef[Bool]',
  builder => '_build_possible'
);

=head2 cosets()

Returns array ref of cosets.  Use add_coset() to modify cosets of the Square.

=cut

has 'cosets' =>
( is => 'ro',
  isa => 'ArrayRef[ArrayRef[Sudoku::Square]]',
  default => sub { [] }
);

=head2 index( INDEX1, INDEX2, ... )

Get or set the index of the square.

=cut

has 'index' =>
( is => 'rw',
  isa => 'ArrayRef',
);

=head2 all_possibilities()

Return list of all possible values for Sudoku squares.  Should be integers only.

=cut

sub all_possibilities {
  return (1..9);
}

=head2 from_str( STRING )

Set the value for the square from $str.  Does nothing if $str consists of whitespace.  Used by Sudoku::Board::set_puzzle() to construct a puzzle from a string.

=cut

sub from_str {
  my $self = shift;
  my $str = shift;
  if( $str !~ /^\s*$/ ) {
    return $self->value($str);
  }
}

=head2 to_str()

Returns a textual representation of the Square.  Used by Sudoku::Square::display().

=cut

sub to_str {
  my $self = shift;
  return $self->value() || ' ';
}


sub _build_possible {
  my $self = shift;
  return { map { $_ => 1 } $self->all_possibilities() };
}

sub add_coset {
  my $self = shift;
  push @{$self->cosets()}, [@_];
}

sub _unset_possibilities {
  my $self = shift;
  for my $k (keys(%{$self->possible()})) {
    $self->possible()->{$k} = 0;
  }
}

sub _set_value {
  my $self = shift;
  $self->_unset_possibilities();
  $self->possible()->{$self->value()};
}

sub set_possibilities {
  my $self = shift;
  my @vals = @_;
  $self->_unset_possibilities();
  for my $v (@vals) {
    $self->possible()->{$v} = 1;
  }
}

sub get_num_possible {
  my $self = shift;
  return 0 + $self->possibilities();
}

sub possibilities {
  my $self = shift;
  return grep { $self->possible()->{$_} } $self->all_possibilities();
}

=head2 deduce()

Tries to solve for the value of this square by eliminating as possibilities any known values from the squares in the cosets of this square.  If the value of this square is set, returns it; otherwise undef.

=cut

sub deduce {
  my $self = shift;
  if( defined($self->value()) ) {
    return $self->value();
  }
  for my $coset (@{$self->cosets()}) {
    map { $self->possible()->{$_} = 0 }
      grep { defined } 
	map { $_->value() } @{$coset};
  }
  my @possible = $self->possibilities();
  if( @possible == 1 ) {
    return $self->value($possible[0]);
  } elsif( @possible == 0 ) {
    die "UNSOLVABLE";
  }
  return undef;
}

sub sort_unique {
  my @t = sort(@_);
  my @r;
  for my $t (@t) {
    if( @r == 0 or $t != $r[$#r] ) {
      push @r, $t;
    }
  }
  return @r;
}

sub minus {
  my @a = sort_unique @{shift(@_)};
  my @b = sort_unique @{shift(@_)};
  my @c;
  while( @a and @b ) {
    if( $a[0] < $b[0] ) {
      unshift @c, shift(@a);
    } elsif( $a[0] == $b[0] ) {
      shift @a; shift @b;
    } else {
      shift @b;
    }
  }
  return (@c,@a);
}

sub intersect {
  my @a = sort_unique @{shift(@_)};
  my @b = sort_unique @{shift(@_)};
  my @c;
  while( @a and @b ) {
    if( $a[0] == $b[0] ) {
      push @c, shift(@a); shift @b;
    } elsif( $a[0] < $b[0] ) {
      shift @a;
    } else {
      shift @b;
    }
  }
  return @c;
}

=head2 induce()

Tries to solve for the value of this square by looking for any values which are not possible for another square in one of the cosets of this square.  Returns the value of the square if it is set, undef otherwise.

=cut

sub induce {
  my $self = shift;
  if( defined($self->value()) ) {
    return $self->value();
  }
  my @vals = $self->possibilities();
  for my $coset (@{$self->cosets()}) {
    my @vals = 
      intersect( \@vals,
		 [ minus( [$self->all_possibilities()],
			  [ map { $_->possibilities() } @{$coset} ] ) ] );
  }
  if( @vals == 1 ) {
    print "Induced: ", join(",",@vals), "\n";
    $self->value( $vals[0] );
  } elsif( @vals == 0 ) {
    die "UNSOLVABLE";
  } else {
    $self->set_possibilities( @vals );
  }
  return $self->value();
}

=head2 compare_to_cosets()

Calls deduce() and induce().  If the value of the square is set during the call, or if the number of possible values is reduced, returns 1; otherwise returns 0.  Sudoku::Board uses this return value to tell when the deterministic solver has 'settled' -- if the calls to compare_to_cosets for all squares return 0, that means nothing has changed, and the solution is stuck.

=cut

sub compare_to_cosets {
  my $self = shift;
  if( defined $self->value() ) {
    return 0;
  }
  my $possible_before = $self->get_num_possible();
  $self->deduce;
  $self->induce;
  if( defined $self->value() or $possible_before > $self->get_num_possible() ) {
    return 1;
  } else {
    return 0;
  }
}

=head1 TODO

Improve deterministic solution with X-Wings, etc.

=cut

1;
__END__

