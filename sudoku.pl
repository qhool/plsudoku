#!/usr/bin/perl
use warnings;
use strict;

use lib './lib';

use Sudoku::Board;
use Sudoku::HexBoard;

my $board;

if( @ARGV == 1 ) {
  my $f = $ARGV[0];
  open PUZZLE, "<$f" or die "Can't open $f: $!";
  local $/ = undef;
  my $p = <PUZZLE>;
  close PUZZLE;
  if( 10 < split( "\n", $p ) ) {
    $board = Sudoku::HexBoard->new();
  } else {
    $board = Sudoku::Board->new();
  }
  $board->set_puzzle($p);
} else {
  print "Please give the name of the file which contains the puzzle you want to solve.\n";
  exit(0);
}

$board->display();
my $prev_num_un = $board->get_num_unset();
$board->solve(1);
my $num_un = $board->get_num_unset();
$board->display();
