package Sudoku::HexSquare;

use Moose;

extends 'Sudoku::Square';

sub all_possibilities {
  return (0..15);
}

my $disp_squares = "0123456789ABCDEF";
sub from_str {
  my $self = shift;
  my $str = shift;
  if( $str !~ /^\s*$/ ) {
    return $self->value( index($disp_squares, $str) );
  }
}

sub to_str {
  my $self = shift;
  if( defined $self->value() ) {
    return substr( $disp_squares, $self->value(), 1 );
  } else {
    return ' ';
  }
}

1;
