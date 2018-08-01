#!/usr/bin/env perl
#
# From http://www.elliottline.com/puzzles-1/2018/2/23/puzzle-of-the-week-139-strange-sequence
#
# I have a curious sequence: it begins: 2, 2, 2, 7, and then every subsequent number
# is the magnitude of the difference between the sum of the two previous numbers
# and the sum of the two numbers before that. Or in more mathematical language:
#
# A(n) = abs(A(n-1)+A(n-2)-A(n-3)-A(n-4))
#
# So, for instance the 5th number is 5, since (7+2)-(2+2) is 5.
# Remember since we are always looking for the magnitude of the difference,
# it cannot be negative.
#
# What is the 123456789th number in the sequence?

use strict;
use warnings;

my @ARRAY = (2, 2, 2, 7);
my $aa = 5;
my $next;

while ($aa <= 123456789) {
    $next = compute(@ARRAY);
    if ($aa =~ /3456789$/){
        print "$aa: $next\n";
    }
    last if ($aa >= 123456789);
    shift @ARRAY;
    push @ARRAY, $next;
    $aa++;
}
print "$aa: $next\n";

exit;

sub compute {
    my (@array) = @_;
    my $next = abs(-$array[0]-$array[1]+$array[2]+$array[3]);
    return $next;
}
