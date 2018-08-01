#!/usr/bin/env perl

# eliottline.com, puzzle 112
# http://www.elliottline.com/puzzles-1/2017/8/11/puzzle-of-the-week-112-number-fill-in

# Given 12 6-digit numbers, fill in the 6x6 grid.
# Report the 6 digit number from the major diagonal.

use strict;
use warnings;

use File::Basename;

# Autoflush stdout
BEGIN { $| = 1 }

#######################
# options and defaults

our $GRID_DEFAULT = 6;
our $GRID_OPT = '-g';
our $GRID = $GRID_DEFAULT;
our $HELP = '^\D$'; # Not a known option, and not a number


############################

sub usage {
    my($filename, $dirs, $suffix) = fileparse($0);
    my $script_name = $filename . $suffix;

    print STDERR "Solve Elliot's Puzzle of the Week #112\n\n";
    print STDERR "Usage:\n";
    print STDERR "\t$script_name [$GRID_OPT grid_size] [list_of_numbers]\n\n";
    print STDERR "Default grid size is $GRID_DEFAULT\n\n";
    print STDERR "Grid is square, there must be 2x numbers for a grid of size x.\n\n";
    exit;
}

our @NUMS_DEFAULT = qw(113443 143132 241131 321422 323132 331222
                       341114 412433 414422 431331 443112 444313);

our @nums;

######################
# Process the command line

while (@ARGV) {
    if ($ARGV[0] eq $GRID_OPT and defined($ARGV[1]))  {
        $GRID = $ARGV[1];
        shift;shift;
        next;
    }

    if ($ARGV[0] =~ m/$HELP/)  {
        usage();
    }

    push @nums, shift;
}

if (not @nums) {
    @nums = @NUMS_DEFAULT;
}

###########################
# We might do this a lot, so cache the results
# Closure, so put this before the function is called.
{
    my @factorial;
    $factorial[0] = 1;

    sub factorial {
    	my $n = shift;

    	# If we already know it, return it
    	return $factorial[$n] if defined $factorial[$n];

    	# Else compute it from the largest known result
    	my $result = $factorial[$#factorial];
    	for my $k ( $#factorial+1..$n ) {
    		$result *= $k;
    	}
    	return $result;
    }
}

#########################

if (scalar(@nums) != (2 * $GRID)) {
    die sprintf "Wrong number count, expected %d, have %d\n",
                2 * $GRID, scalar(@nums);
}

# Create a hash of arrays, to store the digits of each number
our %nums;
for my $num (@nums) {
    push @{$nums{$num}}, split '', $num;
}

printf STDERR "%d total permutations\n", factorial(scalar @nums);
# Now the work loop
for my $n (0..factorial(scalar @nums)-1)
{
    if ($n % 100000 == 0) {
        print STDERR "$n ";
    }
	my @perm = permutation_n($n,@nums);
    if (tryit(@perm)) {
        print "\n*** permutation: $n ***\n";
        print "grid:\n";
        for my $p (@perm[0..(@perm/2-1)]) {
            print "\t$p\n";
        }
        print "Diagonal: ";
        for my $i (0..int(@perm/2)) {
            print substr($perm[$i], $i, 1);
        }
        print "\n";
        exit;
    }
} continue {
    $n++;
}

exit;

###########################################
# Try the given permutation
sub tryit {
    my @perm = @_;

    # Fill a grid with the first half of the numbers (horizontally)
    my @grid1;
    for my $x (0..$GRID-1) {
        for my $y (0..$GRID-1) {
            $grid1[$y][$x] = $nums{$perm[$x]}[$y];
        }
    }

    # Fill a grid with the remaining numbers (vertically)
    my @grid2;
    for my $p (@perm[$GRID..$#perm]) {
        $grid2[@grid2] = $nums{$p};
    }

    return grid_compare(\@grid1, \@grid2);
}

###########################################
# Compare 2 arrays
sub grid_compare {
    my $g1 = shift;
    my $g2 = shift;
    my @g1 = @$g1;
    my @g2 = @$g2;

    for my $x (0..$#g1) {
        for my $y (0..$#{$g1[$x]}) {
            return 0 if $g1[$x][$y] != $g2[$x][$y];
        }
    }
    return 1;
}

###########################################
# Find and return the $n'th permutation
# of the remaining arguments in some canonical order
# (modified from QOTW solution)
sub permutation_n {
  my $n = shift;
  my @result;
  while (@_) {
    ($n, my $r) = (int($n/@_), $n % @_);
    push @result, splice @_, $r, 1;
  }
  return @result;
}
