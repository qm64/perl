#!/usr/bin/env perl
#
# From http://brainden.com/forum/topic/18147-dumb-robot/
#

# Each square of an NxN grid of squares is either filled with cement blocks or
# left empty, such that there is at least one path from the top left corner to the
# bottom right corner of the grid. Outside the grid everything is filled with
# cement.
#
# A robot is currently located at the top left corner and wants to get to
# the bottom right corner, but it only knows the value of N and doesn't know the
# layout of the grid. It also has no method of observing its surroundings. It
# is your job to give it instructions to ensure it ends up at its destination.
#
# Your instructions should be a finite list of directions (Up, Down, Left, Right).
# The robot will try to move in the indicated directions in order, and, if there
# is a cement wall in the way at some step, it will simply fail to move in the
# corresponding direction and continue on with the next instruction in the list.
#
# Since the robot has no way of sensing whether it has reached its destination, it
# might reach the destination somewhere in the middle of your list of instructions
# and then later leave. The goal is to give a list of instructions, depending only
# on N, such that after following your instructions the robot is guaranteed to end
# its journey in the bottom right corner of the grid.

use strict;
use warnings;

my $EMPTY = ' ';
my $BLOCK = '*';

my $N = (shift or 3);

# get a seed, but save it in case we want to use the same seed again
my $seed = time;
srand($seed);
print "Random seed: $seed\n";

my @grid = @{create_random_grid($N)};
print_grid(@grid);


exit;

###########################
sub create_random_grid {
    my $n = shift;

    my @x;
    for my $r (0..$n-1) {
        for my $c (0..$n-1) {
            $x[$r][$c] = (rand > 0.5 ? $BLOCK : $EMPTY);
        }
    }
    # start and end cells must be clear
    $x[ 0][ 0] = $EMPTY;
    $x[-1][-1] = $BLOCK;
    return \@x;
}

##########################
sub print_grid {
    my @grid = @_;

    my $grid_lines = join('-', ('+') x (@grid+1));
    print "$grid_lines\n";
    for my $r (@grid) {
        print "|", join('|',@$r), "|\n";
        print "$grid_lines\n";
    }
}

##########################
# Is the exit reachable from the start?
sub reachable {
    my $start = shift;
    my $exit = shift;
    my @grid = @{shift};

    # Get a list of all cells that can be reached from the starting cell
    # Start with a list of reachable coordinates
    my %cumulative;
    $cumulative{$start} = 1;
    my %edges = %cumulative; # search for neighbours of these (copy of %cumulative)
    for my $cell (keys %edges) {
        my %next_ones = %{find_next(\%cumulative, \%edges, \@grid)};
        %cumulative = (%cumulative, %next_ones); # update cumulative
        return 1 if $cumulative{$exit}; # exit is reachable
        %edges = %next_ones;
    }
    return 0;
}

###########################
# Given a list of reachable cells, a list of edge cells to check for neighbours,
# and a grid to navigate, return a list of newly reachable cells as a hash.
sub find_next {
    my %cumulative = %{shift};
    my %edges = %{shift};
    my @grid = @{shift};
