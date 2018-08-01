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

use Algorithm::Combinatorics qw(permutations);

my $num_base = 10;
my $zero_allowed = 0;

my @digits = ($zero_allowed ? 0 : 1) .. ($num_base - 1);

my $combo_iterator = permutations(\@digits);
my $num_min_index = int($#digits/2)-1;

my %factors;

COMBO:
while (my $combo_ref = $combo_iterator->next()) {
#    my $combo = join('', @$combo_ref);
#    printf STDERR "\t%s\n", join('', $combo);
    
    # The first digit can't be 0
    next COMBO unless $combo_ref->[0];

    # The result can't be 0 or 1;
    # Must leave 1 digit for result, 1 digit for denominator, hence "-2"
    #
    NUMERATOR:
    for my $num_last_index ($num_min_index..(($#$combo_ref)-2)) {
        # Quotient can't start with 0
        next NUMERATOR if $combo_ref->[$num_last_index+1] == 0;
        my (@num) = @$combo_ref[0..$num_last_index];
        my $num = 0 + join('', @num);
        my $fnum = $factors{$num} = {} unless exists($factors{$num}); # duplicate factor cache
        
        # Must leave 1 digit for denominator, hence "-1"
        QUOTIENT:
        for my $quotient_last_index ($num_last_index+1..($#$combo_ref-1)) {
            # Denominator can't start with 0
            next QUOTIENT if $combo_ref->[$quotient_last_index+1] == 0;
            my @quot = @$combo_ref[$num_last_index+1..$quotient_last_index];
            my $quot = 0 + join('', @quot);
            
            # Quotient must be at least 2.
            # If $quot > $num, then this combo is exhausted.
            next QUOTIENT unless $quot > 1;            
            next NUMERATOR unless $quot < $num; 
            next QUOTIENT if exists($fnum->{$quot});
            my @den = @$combo_ref[$quotient_last_index+1..$#$combo_ref];
            my $den = 0 + join('', @den);
            # if denominator is 1, quotient generation is used up
            next NUMERATOR if $den == 1;
            next QUOTIENT unless ($quot < $den);
            next QUOTIENT unless ($den * $quot == $num);
            
            $fnum->{$quot} = $fnum->{$den} = 1;
            printf "%d / %d = %d\n", $num, $den, $quot;
        }
    }
}

exit;
