#!/usr/bin/env perl

use strict;
use warnings;

my %min; 
my %max; 

my @vals = (1, 9, 10, 99, 100, 999, 1000, 9999, 10000, 99999);

for my $xx (0..$#vals) { 
    my $x = $vals[$xx];
    my $xl = length($x);
    for my $yy (0..$xx) { 
        my $y = $vals[$yy];
        my $yl = length($y);
        my $z = $x * $y; 
        my $zz = length($z);
        my $xyll = $xl . "+" . $yl;
        if (not exists($min{$xyll})
         or ($zz < $min{$xyll})) {
            print "min x=$x, y=$y, xyll=$xyll, z=$z, zz=$zz\n";
            $min{$xyll} = $zz;
        }
        if (not exists($max{$xyll})
         or ($zz > $max{$xyll})) {
            print "max x=$x, y=$y, xyll=$xyll, z=$z, zz=$zz\n";
            $max{$xyll} = $zz;
        }
    }
}

for my $xyll (sort keys %min) {
    print "min{$xyll} = $min{$xyll}\n";
}

for my $xyll (sort keys %max) {
    print "max{$xyll} = $max{$xyll}\n";
}

exit;