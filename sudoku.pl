#!/usr/bin/perl
use warnings;
use strict;

use SudokuSquare;
use SudokuBoard;

my $board = new SudokuBoard;

if( 0 == 1 ) {
$board->set_puzzle( 
" 4   1  3
    5  79
56   28 4
1  27  8 
 82   96 
 3  18  7
3 61   98
47  8    
8  5   4 ");
}

$board->set_puzzle("9 6 13  8
 58    9 
 3     1 
 6 8  92 
  34 91  
 49  6 3 
 9     8 
 1    67 
4  96 3 1");

$board->display();
my $prev_num_un = $board->get_num_unset();
print "$prev_num_un Unset.\n";
my $num_un = 100;
my $num_iter = 0;
while( $num_un > 0 ) {
  $num_un = $board->iterate();
  $board->display();
  print "$num_un Unset.\n";
  $num_iter++;
  if( $num_un == $prev_num_un ) {
    print "I'm stuck after $num_iter iterations\n";
    $board->display('OPT');
    exit(-1);
  }
  $prev_num_un = $num_un;
  #print Data::Dumper::Dumper($board->[2][3]->{POSSIBLE});
  #sleep(1);
};
print "Solved in $num_iter iterations\n";
