#!/usr/bin/env perl

# From: https://centerofmathematics.blogspot.co.uk/2017/08/advanced-knowledge-problem-of-week_17.html
#
# Sequence: a[0] = 1/2, a[n] = 1 + (a[n-1] - 1)^2
# What is PROD(i=0 to inf, a[i])?

use strict;
use warnings;

sub seq {
    my $a1 = shift;
    my $a2 = 1 + ($a1-1)**2;
    return $a2;
}

our @a;
our @prod;
$prod[0] = $a[0] = 0.5;
my $i = 0;

while (1) {
    print "$i) \$a[$i]=$a[$i], \$prod[$i]=$prod[$i]\n";
    ++$i;
    $a[$i] = seq($a[$i-1]);
    $prod[$i] = $prod[$i-1] * $a[$i];
    last if ($prod[$i] == $prod[$i-1]);
}
print "Converged at \$i=$i\n";
print "$i) \$a[$i]=$a[$i], \$prod[$i]=$prod[$i]\n";

exit;
