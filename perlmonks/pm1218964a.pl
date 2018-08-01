#!/usr/bin/env perl

# Find "pan-digital" fractions, where the result is an integer completing the pan-digital part.
# Leading zero is not allowed.
#
# Options:
#    change of base
#    omit zero

# TODO: 
# * Rework to sample factors, compute product, and check for pandigital status
# * Try digital sums to filter out faster.

use strict;
use warnings;

use Algorithm::Combinatorics qw(variations);

my $num_base = 10;
my $zero_allowed = 1;

my @digits = ($zero_allowed ? 0 : 1) .. ($num_base - 1);

# compute the digital sum of products of digital sums
my %digital_product_sums;
for my $i (0..$#digits) {
    for my $j ($i..$#digits) {
        my $k = digital_sum($i*$j);
        $digital_product_sums{$i}{$j} = $k;
    }
}
    
my $vary = variations(\@digits, 

exit;

sub digital_sum {
    my @nums = @_;
    my @sums;
    for my $num (@nums) {
        do {
            my $sum = 0;
            map {$sum += $_} split '', $num;
            $num = $sum;
        } until length($num) == 1;
        push @sums, $num;
    }
    return @sums;
}
        

