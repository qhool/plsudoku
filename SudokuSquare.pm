package SudokuSquare;

sub new {
  my $pkg = shift;
  my $self = { VALUE => undef,
               POSSIBLE => { map { $_ => 1 } (1..9) },
	       COSETS => []
	     };
  bless $self, $pkg;
  return $self;
}

sub add_coset {
  my $self = shift;
  push @{$self->{COSETS}}, [@_];
}

sub value {
  my $self = shift;
  if( @_ > 0 ) {
    $self->{VALUE} = $_[0];
    for my $k (keys(%{$self->{POSSIBLE}})) {
      if( $k != $self->{VALUE} ) {
	$self->{POSSIBLE}->{$k} = 0;
      }
    }
  }
  return $self->{VALUE};
}

sub get_num_possible {
  my $self = shift;
  my $n = 0;
  for my $k (keys(%{$self->{POSSIBLE}})) {
    if( $self->{POSSIBLE}->{$k} ) {
      $n++;
    }
  }
  return $n;
}

#return value if one is selected, undef otherwise
sub compare_to_cosets {
  my $self = shift;
  my $dbg = shift;
  if( defined($self->value()) ) {
    return $self->value();
  }
  for my $coset (@{$self->{COSETS}}) {
    if( $dbg ) {
      print "Coset:\n";
    }
    for my $square (@{$coset}) {
      my $sqval = $square->value();
      if( defined($sqval) ) {
	if( $dbg ) {
	  print "$sqval ";
	}
	$self->{POSSIBLE}->{$sqval} = 0;
      }
    }
    if( $dbg ) {
      print "\n";
    }
  }
  my $num_possible = 0;
  my $v = undef;
  for my $k (keys(%{$self->{POSSIBLE}})) {
    if( $self->{POSSIBLE}->{$k} ) {
      $v = $k;
      $num_possible++;
      if( $num_possible > 1 ) {
	last;
      }
    }
  }
  if( $dbg ) {
    print "Num_possible: $num_possible Val: $v\n";
  }
  if( $num_possible == 1 ) {
    return $self->value($v);
  }
  return undef;
}

1;
#end

