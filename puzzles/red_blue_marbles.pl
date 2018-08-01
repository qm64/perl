#!/usr/bin/env perl

# 50 red marbles and 50 blue marbles are distributed between 2 jars.
# What is the best distribution to minimize the chance of picking
# a red marble?

use strict;
use warnings;

our $RED = 50;
our $BLUE = 50;

##################

sub red_fraction {
    my $red = shift;
    my $blue = shift;
    
    # Handle edge cases first (avoid divide by zero)
    return 0 if not $red;
    return 1 if not $blue;
    
    my $fraction = $red / ($red + $blue);
    return $fraction;
}

######################

our %table;
our @min_red;

for my $r1 (0..$RED) {
    my $r2 = $RED - $r1;
    for my $b1 (0..$BLUE) {
        my $b2 = $BLUE - $b1;
        
        my $red_chance = (red_fraction($r1,$b1) + red_fraction($r2,$b2)) / 2;
        
        if ((not @min_red) or
            ($min_red[0] > $red_chance)) {
            @min_red = ($red_chance, $r1, $b1, $r2, $b2);
        }
        printf "%5.3f, %d, %d, %d, %d\n", $red_chance, $r1, $b1, $r2, $b2;
        
        push @{$table{$red_chance}}, [$r1, $b1, $r2, $b2];
    }
}

printf "Min red chance: %5.3f, %d, %d, %d, %d\n", @min_red;

exit;
        

