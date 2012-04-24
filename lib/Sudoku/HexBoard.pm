package Sudoku::HexBoard;

use Moose;
use Sudoku::HexSquare;

extends 'Sudoku::Board';

sub _square_class {
  return 'Sudoku::HexSquare';
}

sub _dimensions {
  my $self = shift;
  return [16,16,4,4];
}
1;
