#!/usr/bin/env perl

# http://perlmonks.org/?node_id=1197354

use strict;
use warnings;

@ARGV or @ARGV = qw( 113443 143132 241131 321422 323132 331222
  341114 412433 414422 431331 443112 444313 );

my $half = @ARGV / 2;
my $steps = 0;

my @stack = [ "\n" x $half, join '', map "$_\n", @ARGV ];

NEXT:
while( @stack )
  {
  my ($have, $rest) = @{ pop @stack };
  $steps++;

  my %lefts;                            # validate legal so far
  $lefts{$_}++ for $have =~ /^(.+)\n/gm;
  for my $head (keys %lefts)
    {
    $lefts{$head} <= ( () = $rest =~ /^$head/gm ) or goto NEXT;
    }

  if( $rest =~ tr/\n// == $half )    # half left means completed
    {
    print "answer in $steps steps\n\n$have";
    print "diagonal  ", $have =~ /(\d)(?:..{$half})?/gs;
    exit;
    }

  while( $rest =~ /^(.+)\n/gm )      # try each number remaining
    {
    my ($before, $after, @digits) = ($`, $', #' # IDE doesn't recognize $'
                                     split //, $1);
    push @stack,
      [ $have =~ s/(?=\n)/ shift @digits /ger, $before . $after ];
    }
  }

print "failed to find solution in $steps steps\n";

exit;