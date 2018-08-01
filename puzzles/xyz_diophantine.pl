#!/usr/bin/env perl

# Puzzle solver for Diophantine ratio
# https://www.quora.com/How-do-you-find-the-integer-solutions-to-frac-x-y+z-+-frac-y-z+x-+-frac-z-x+y-4

#   x       y       z
# ----- + ----- + ----- = 4
# y + z   x + z   x + y

# The original problem asked for positive values of x, y, z.
# This solution will allow integer values (with a command line switch),
# and also allow for a different constant.

# Note that the original problem, with positive values, is not solvable
# with a computer search.

use strict;
use warnings;

use File::Basename;

# Autoflush stdout
BEGIN { $| = 1 }

#######################
# options and defaults

our $CONSTANT_OPT = '-c';
our $CONSTANT_DEFAULT = 4;
our $CONSTANT = $CONSTANT_DEFAULT;

our $POSITIVE_OPT = '-p';
our $POSITIVE_DEFAULT = 0;
our $POSITIVE = $POSITIVE_DEFAULT;

############################

sub usage {
    my($filename, $dirs, $suffix) = fileparse($0);
    my $script_name = $filename . $suffix;

    print STDERR "Search for solutions to a Diophantine equation which takes the form:\n\n";

    print STDERR <<"FORMULA";
      x       y       z
    ----- + ----- + ----- = $CONSTANT_DEFAULT
    y + z   x + z   x + y

FORMULA
    print STDERR "The constant may be changed, and positive-only values may be searched for.\n\n";
    print STDERR "Note: positive-only values for the default constant are very large, and\n";
    print STDERR "      cannot be found with a computer search.\n\n";

    print STDERR "Usage:\n";
    print STDERR "\t$script_name [$CONSTANT_OPT const] [$POSITIVE_OPT]\n";
    print STDERR "Where:\n";
    print STDERR "\t$CONSTANT_OPT const : use this constant (default $CONSTANT_DEFAULT)\n";
    print STDERR "\t$POSITIVE_OPT       : toggle positive-only search (default $POSITIVE_DEFAULT)\n";
    exit;
}

######################
# process command line

while (@ARGV) {
    if ($ARGV[0] eq $CONSTANT_OPT and defined($ARGV[1]))  {
        $CONSTANT = $ARGV[1];
        shift;shift;
        next;
    }

    if ($ARGV[0] eq $POSITIVE_OPT)  {
        $POSITIVE = 1 - $POSITIVE;
        shift;
        next;
    }

    warn "Unknown argument $ARGV[0], aborting\n";
    usage;
}

###############################

{
    my %h;
    sub compute {
        my $n = shift; # numerator
        my $d = shift; # denominator
        if (not exists($h{"$n,$d"})) {
            $h{"$n,$d"} = $n / $d;
        }

        return $h{"$n,$d"};
    }
}

#############################

my $radius = 0;

while (1) {
    ++$radius;
    if ($radius % 10 == 0) {
        print STDERR "radius:$radius\n";
    }

    my @range;
    if (not $POSITIVE) {
        push @range, -$radius .. -1;
    }
    push @range, 1..$radius;

    my @x;
    if (not $POSITIVE) {
        push @x, -$radius;
    }
    push @x, $radius;

    for my $x (@x) {
        for my $y (@range) {
            my $xy = $x + $y;
            next if (not $POSITIVE and ($xy == 0));
            for my $z (@range) {
                next if (abs($z) > abs($y));

                my $xz = $x + $z;
                my $yz = $y + $z;
                if (not $POSITIVE) {
                    next if ($xz == 0);
                    next if ($yz == 0);
                }
                my $t1 = compute($x, $yz);
                my $t2 = compute($y, $xz);
                my $t3 = compute($z, $xy);
                my $sum = $t1 + $t2 + $t3;
                if ($sum == $CONSTANT) {
                    print "\tx=$x, y=$y, z=$z\n";
                }
            }
        }
    }
}

exit;
