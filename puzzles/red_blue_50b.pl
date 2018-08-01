#!/usr/bin/env perl

use strict;
use warnings;

# http://brainden.com/forum/topic/18002-probability-of-selecting-two-blue-discs-back-to-back/
#
# A box contains a number of balls of 2 colors.
# For some number of balls, find the partition of colors such that drawing 2 without replacement
# gives exactly 50% chance of both balls being the same color.
#
# Example: N = 21, Blue = 15, Red = 6, Balls drawn = 2
#
# 15/21 * 14/20 = 210/420 = 1/2
#
# What is the partition for the first total N over 1 trillion?

use File::Basename;

# All operators except range (..) are overloaded.
# All constants are created as proper BigInts
use bigint;

# Autoflush stdout
BEGIN { $| = 1 }

our $BALLS_DEFAULT = 21;
our $DRAWS_DEFAULT = 2;
our $INTERVAL_DEFAULT = 10000;

our $BALLS_OPT = '-b';
our $DRAWS_OPT = '-d';
our $INTERVAL_OPT = '-i';

our $BALLS = $BALLS_DEFAULT;
our $DRAWS = $DRAWS_DEFAULT;
our $INTERVAL = $INTERVAL_DEFAULT;


############################

sub usage {
    my($filename, $dirs, $suffix) = fileparse($0);
    my $script_name = $filename . $suffix;

    print STDERR "Given N or more balls in 2 colors, find N and the partition such that drawing B balls of the same color has probability 50%:\n\n";

    print STDERR "Usage:\n";
    print STDERR "\t$script_name [$BALLS_OPT balls] [$DRAWS_OPT draws] [$INTERVAL_OPT interval]\n";
    print STDERR "Where:\n";
    print STDERR "\t$BALLS_OPT balls : total number of balls (default $BALLS_DEFAULT)\n";
    print STDERR "\t$DRAWS_OPT draws : draw this number of same-colored balls in a row (default $DRAWS_DEFAULT)\n";
    print STDERR "\t$INTERVAL_OPT interval : interval for reporting total ball steps (default $INTERVAL_DEFAULT)\n";
    exit;
}

######################
# process command line

while (@ARGV) {
    if ($ARGV[0] eq $BALLS_OPT and defined($ARGV[1]))  {
        $BALLS = $ARGV[1];
        shift;shift;
        next;
    }

    if ($ARGV[0] eq $DRAWS_OPT and defined($ARGV[1]))  {
        $DRAWS = $ARGV[1];
        shift;shift;
        next;
    }

    if ($ARGV[0] eq $INTERVAL_OPT and defined($ARGV[1]))  {
        $INTERVAL = $ARGV[1];
        shift;shift;
        next;
    }

    warn "Unknown argument $ARGV[0], or not enough arguments, aborting\n";
    usage;
}

############################
# Compute a product of sequential integers
sub prod_seq {
    my $max = shift;
    my $num = shift;
    my $result = 1;
    for my $i (0..$num-1) {
        $result *= ($max-$i);
    }
    return $result;
}

############################
# Compute the triangular root
# Due to bigint issues (?), sometimes returns invalid results
# Always check.
sub tri_root {
    my $target = shift;
    my $target_x8 = $target*8;
    my $target_x8_sqrt = sqrt($target_x8+1);
    if ($target_x8_sqrt**2 == $target_x8+1) {
        if ($target_x8_sqrt % 2 == 1) {
            my $root = ($target_x8_sqrt-1)/2;
            if ($root*($root+1)/2 == $target) {
                return $root;
            }
        }
    }
    return undef;
}

############################
# Compute the RMS value of 2 terms
sub rms {
    return int(sqrt(($_[0]**2 + $_[1]**2)/2));
}

############################
# Binary search for a product equal to $target.
# The product is $nums sequential numbers.
# The highest number in the sequence is between $min and $max.
sub bsearch {
    my $min = shift;
    my $balls = shift; # max
    my $nums = shift; # geometric sequence length
    my $target = shift;

    my $max = $balls;
    my $guess = int(($min+$max)/2);

    while (1) {
        my $prod = prod_seq($guess, $nums);
        if ($prod == $target) {
            return $guess;
        } elsif ($max == $min) {
#            print STDERR " Failed on $guess/$balls\n";
            return undef;
        } elsif ($prod > $target) {
            if ($max == $guess) {
#                print STDERR " Failed on $guess/$balls\n";
                return undef;
            }
#            print STDERR " Update max to $guess\n";
            $max = $guess;
            $guess = rms($guess,$min);
        } else {
            if ($min == $guess) {
#                print STDERR " Failed on $guess/$balls\n";
                return undef;
            }
#            print STDERR " Update min to $guess\n";
            $min = $guess;
            $guess = rms($guess,$max);
        }
    }
}


############################
# Main
print STDERR "Starting from $BALLS: ";
my $n = $BALLS - 1;

while (++$n) {
    print STDERR "$n " if $n % $INTERVAL == 0;

    my $prod_seq = prod_seq($n, $DRAWS);
    # While $prod_seq will be even, it may not be divisible by 4
    # (Assuming $DRAWS is > 1)
    if ($prod_seq % 4 == 0) {
        my $target = $prod_seq / 4;
        if (my $result = tri_root($target)) {
            printf "\n\t%d, %d\n", $result+1, $n;
            last;
        }
    }
}

exit;

