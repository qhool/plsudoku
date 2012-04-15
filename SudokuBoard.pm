package SudokuBoard;

use SudokuSquare;
use Data::Dumper;

sub new {
  my $pkg = shift;
  my $self = [];
  bless $self, $pkg;
  for my $i (0..8) {
    for my $j (0..8) {
      my $sq = SudokuSquare->new();
      $self->[$i][$j] = $sq;
    }
  }
  #do all the cosets:
  my @cosets;
  for my $i (0..8) {
    my @row_set = map { $self->[$i][$_] } (0..8);
    my @col_set = map { $self->[$_][$i] } (0..8);
    push @cosets, \@row_set;
    push @cosets, \@col_set;
  }
  my @threeby;
  for my $i (0..2) {
    for my $j (0..2) {
      push @threeby, [$i,$j];
    }
  }
  for my $i (0..2) {
    for my $j (0..2) {
      my @sq_set = map { $self->[$i*3+$_->[0]][$j*3+$_->[1]] } @threeby;
      push @cosets, \@sq_set;
    }
  }
  for my $cos (@cosets) {
    for my $sq (@$cos) {
      #print Data::Dumper::Dumper( $sq );
      $sq->add_coset( @$cos );
    }
  }
  return $self;
}

sub set_puzzle {
  my $self = shift;
  my $puz_str = shift;
  my @lines = split( /\n/m, $puz_str );
  if( @lines != 9 ) {
    die "wrong number of lines!";
  }
  for my $i (0..$#lines) {
    chomp($lines[$i]);
    my @v = split( //, $lines[$i] );
     for my $j (0..$#v) {
      #print "$i,$j = $v[$j]\n";
       if( $v[$j] =~ /[0-9]/ ) {
	 $self->[$i][$j]->value($v[$j]);
       }
    }
  }
}

sub display {
  my $self = shift;
  $disp_type = 'VAL';
  if( @_ > 0 ) {
    $disp_type = shift;
  }
  print "-------------------\n";
  for my $i (0..8) {
    print "|";
    for my $j (0..8) {
      if( $disp_type eq 'VAL' ) {
	print $self->[$i][$j]->value() || ' ';
      } elsif( $disp_type eq 'OPT' ) {
	if( defined( $self->[$i][$j]->value() ) ) {
	  print ' ';
	} else {
	  print $self->[$i][$j]->get_num_possible();
	}
      } else {
	print ' ';
      }
      if( $j % 3 == 2 ) {
	print '|';
      } else {
	print ' ';
      }
    }
    if( $i % 3 == 2 ) {
      print "\n-------------------\n";
    } else {
      print "\n";
    }
  }
}

sub get_num_unset {
  my $self = shift;
  my $num_unset = 0;
  for my $i (0..8) {
    for my $j (0..8) {
      if( not defined( $self->[$i][$j]->value() ) ) {
	$num_unset++;
      }
    }
  }
  return $num_unset;
}

sub iterate {
  my $self = shift;
  my $num_unset = 0;
  for my $i (0..8) {
    for my $j (0..8) {
      my $prev_val = $self->[$i][$j]->value();
      my $dbg = 0;
      #if( $i == 2 and $j == 3 ) {
      # $dbg = 1;
      #}
      my $val = $self->[$i][$j]->compare_to_cosets($dbg);
      if( not defined($val) ) {
	$num_unset++;
      } elsif( not defined($prev_val) and defined($val) ) {
	print "Set ($i,$j) to $val\n";
      }
    }
  }
  return $num_unset;
}

1;

#end
