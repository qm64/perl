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
sub tri {
    return $_[0]*($_[0]+1)/2;
}

############################
# Main

# Hashes for triangular lookups
our %tri = (0=>0);
our %untri = (0=>0);

my $n = 0;
my $newline = 0;
while (++$n) {
    # compute next triangular number
    $tri{$n} = tri($n);
    $untri{$tri{$n}} = $n;

    # Check if it's also twice a previous triangular number
    # (Must be even -- bigint truncates, resulting in false positives)
    my $tri_n_half = $tri{$n} / 2;
    if ($tri{$n} % 2 == 0) {
        if (exists($untri{$tri_n_half})) {
            print "\n" if $newline;
            $newline = 0;
            printf "\t%d, %d\n", $untri{$tri_n_half}+1, $n+1;
        }
    }

    if ($n % $INTERVAL == 0) {
        # Remove any entries no longer needed.
        compact_hash($tri_n_half);

#        $newline = 1;
#        print STDERR "$n ";
#        printf STDERR "%d (%d keys)\n", $n, scalar keys %tri;
    }
}

############################
# Compute a product of sequential integers
sub compact_hash {
    my $tri_n_half = shift;

    for my $untri (sort {$a <=> $b} keys %untri) {
        if ($untri <= $tri_n_half) {
            delete($tri{$untri{$untri}});
            delete($untri{$untri});
        } else {
            last;
        }
    }
}

exit;

