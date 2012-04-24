# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sudoku-Board.t'

#########################

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Sudoku::Board') };

#########################

sub solve_puz {
  my $fname = shift;
  my $board = Sudoku::Board->new();
  open PUZZLE, "<$fname" or die "Can't open $f: $!";
  local $/ = undef;
  my $p = <PUZZLE>;
  close PUZZLE;

  ok $board->set_puzzle($p);

  ok $board->solve(0);
}

solve_puz( 'puzzles/test1.puz' );
