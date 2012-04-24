package HexdokuBoard;

use Moose;
use HexdokuSquare;

extends 'SudokuBoard';

sub _square_class {
  return 'HexdokuSquare';
}

sub _dimensions {
  my $self = shift;
  return [16,16,4,4];
}
1;
