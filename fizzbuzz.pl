#!/usr/bin/env perl

#Write a script to implement the game "Fizz Buzz".
#Counting from 1 to 100, print each number in turn, on a new line.
#BUT...
# * If the number is divisible by 3, or contains a digit 3,
#    print "Fizz" instead of the number.
# * Similarly, for 5s, print "Buzz".
# * If both the "3" and "5" conditions, "Fizz Buzz".

use strict;
use warnings;

for my $i (1..100) {
    my $line = '';
    if ($i % 3 == 0) {
        $line .= "Fizz ";
    }
    if ($i % 5 == 0) {
        $line .= "Buzz";
    }
    if (not $line) {
        $line .= $i;
    }
    print "$line\n";
}

exit;
