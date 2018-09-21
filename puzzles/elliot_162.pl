#!/usr/bin/env perl

# Find a run of a specific size of Pythagorean hypotenuses in sequential order.

# From http://www.elliottline.com/puzzles-1/2018/8/10/hypotenuse-connect-four

# Some numbers can be the hypotenuse of an integer triangle, and some cannot. 
# For instance, 24 cannot, neither can 27, but 25 and 26 both can (for example 
# 7,24,25 and 10,24,26). In fact 25 and 26 is the first case where two 
# consecutive numbers can each be hypotenuses. The first case of three numbers 
# in a row which can be hypotenuses is 39, 40 and 41 
# (eg 15,36,39; 24,32,40; 9,40,41).
#
# Which numbers are the first example of four in a row that could each be hypotenuse?

# Given a run size:
# Generate a list of all squares of all integers up to some highest integer.
# Sum pairs of squares, record the sum of squares.
# Identify sums of squares that are themselves entries in the squares list.
# Look for a run of sums of squares that is at least the given length.
# Increase the highest integer, repeat until done.

use strict;
use warnings;
use integer;

use File::Basename;
use File::Spec qw(catfile);
use JSON;

our ($FILENAME, $DIRS, $SUFFIX) = fileparse($0);
our $SCRIPT_NAME = $FILENAME . $SUFFIX;

# Autoflush stdout
BEGIN { $| = 1 }

#######################
# options and defaults

# Run size
our $RUN_SIZE_DEFAULT = 4;
our $RUN_SIZE = $RUN_SIZE_DEFAULT;

# help
our $HELP_OPT = '-h|-help';

############################

sub usage {
    print STDERR "$SCRIPT_NAME\n";
    print STDERR "\n";
    print STDERR "Description:\n";
    print STDERR "\tSearch for a run of a given length, of Pythagorean hypotenuses in sequetial order.\n";
    print STDERR "\t\te.g., [50, 51, 52, 53] are all hypotenuses of Pythagorean triples, making a run of 4.\n";

    print STDERR "\n";
    print STDERR "Usage:\n";
    print STDERR "\t$SCRIPT_NAME [run_size]\n";
    print STDERR "Where:\n";
    print STDERR "\trun_size : minimum run length to report (default $RUN_SIZE_DEFAULT)\n";
    print STDERR "\t[HELP_OPT] : this help\n";
    print STDERR "\n";

    exit;
}


######################
# process command line

while (@ARGV) {
    if ($ARGV[0] =~ m/^\d+$/i) {
        $RUN_SIZE = shift;
        next;
    }

    if ($ARGV[0] =~ m/^$HELP_OPT$/) {
        usage;
    }

}

######################
# Main

our %square = (1 => 1); # lookup the square 
our %square_root = (1 => 1); # lookup the square root
our %sum_of_2squares = (2 => 0); # known sums of 2 squares, value is sqrt (0 => not an integer sqrt)

my $last_side = 1;
while (1) {
    print STDERR "$last_side ";
    # check for a run of the minimum size
    if (my @run = find_run($RUN_SIZE)) {
        printf "\n%d: [%d..%d]\n", scalar(@run), $run[0], $run[-1];
        last;
    }
    ++$last_side;
    $square{$last_side} = $last_side**2;
    $square_root{$square{$last_side}} = $last_side;
    
    # compute square sums with square{$last_side}
    my $last_side_squared = $square{$last_side};
    for my $s (1..$last_side) {
        my $square_sum = $square{$s} + $last_side_squared;
        $sum_of_2squares{$square_sum} = int_sqrt($square_sum);
    }
}

exit;

#####################################
# Find a consecutive sequence of sqrts
#
# Filter the list of sum_of_2squares for those that have a sqrt, make a list of these sqrts.
# Compute the delta between consecutive sqrts.
# Return the first run of the minimum length.
sub find_run {
    my $run_size = shift;
    # find the distinct non-zero sqrts, sorted
    my @sqrt = grep { $_ } 
               sort {$a <=> $b} 
               uniq(values %sum_of_2squares);
    # compute the delta between each pair of sqrts
    my @deltas = map { $sqrt[$_+1] - $sqrt[$_] } 0..$#sqrt-1;
    # check each run of $run_size sqrts
    for my $i (0..$#deltas-$run_size+1) {
        my $run = 1;
        # -2: -1 for $run_size elements, 
        # -1 for one less delta than elements
        map { $run *= $_ } @deltas[$i..$i+$run_size-2]; 
        return @sqrt[$i..$i+$run_size-1] if $run == 1;
    }
    return;
} # find_run
    
######################################
# Compute the integer sqrt, or return 0
sub int_sqrt {
    my $square = shift;
    return int(sqrt($square))**2 == $square 
           ? int(sqrt($square))
           : 0;
}

#####################################
# Return distinct (unique) values of a list
sub uniq {
    my %seen;
    return grep { !$seen{$_}++ } @_;   
} 