#!/usr/bin/env perl
use strict;
use warnings;

# How many different ways are there of arranging the letters of ENIGMATIST,
# such that no two vowels are adjacent, and no two identical letters are adjacent?
#
# See http://www.elliottline.com/puzzles-1/2017/10/20/puzzle-of-the-week-122-enigmatist

# For the default, the answer is 129600 (out of 907200 combinations)

use File::Basename;

# Autoflush stdout
BEGIN { $| = 1 }

###########################################
# Options and defaults

our $STRING_DEFAULT = q/ENIGMATIST/;
our $STRING = $STRING_DEFAULT;
our $STRING_OPT = q/-s/;
our $VOWELS_DEFAULT = q/aeiou/;
our $VOWELS = $VOWELS_DEFAULT;
our $VOWELS_OPT = q/-v/;

###########################################

sub usage {
    my($filename, $dirs, $suffix) = fileparse($0);
    my $script_name = $filename . $suffix;

    print STDERR "Solve Elliot's Puzzle of the Week #122\n\n";
    print STDERR "How many different ways are there of arranging the letters of ENIGMATIST,\n";
    print STDERR "such that no two vowels are adjacent, and no two identical letters are adjacent?\n\n";
    print STDERR "Usage:\n";
    print STDERR "\t$script_name [$VOWELS_OPT vowels] [$STRING_OPT string]\n\n";
    print STDERR "Where:\n";
    print STDERR "\t$STRING_OPT string is the string to use (default: $STRING_DEFAULT)\n";
    print STDERR "\t$VOWELS_OPT vowels is the list of vowels to use (default: $VOWELS_DEFAULT)\n";
    exit;
}

###########################################

while (@ARGV) {
    if ($ARGV[0] eq $STRING_OPT and defined($ARGV[1]))  {
        $STRING = $ARGV[1];
        shift; shift;
        next;
    }

    if ($ARGV[0] eq $VOWELS_OPT and defined($ARGV[1]))  {
        $VOWELS = $ARGV[1];
        shift; shift;
        next;
    }

    usage();

}

###########################################
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

###########################################
# Main body

# Regexes for testing
my $regex = qr/([$VOWELS]){2,}|(\w)\2/i;

# split string into array
my @string = split '', $STRING;
my $string_fac = factorial(scalar @string);
printf STDERR "Checking %d permutations\n", factorial(scalar @string);

my %combos;
my %seen;

# Now the work loop
for my $n (0..$string_fac-1)
{
    # Generate the next permutation of the input
	my $string_perm = join('', permutation_n($n, @string));
	next if exists($seen{$string_perm});
	$seen{$string_perm} = 1;

	# Check against regex
    if ($string_perm !~ $regex) {
        $combos{$string_perm} = 1;
    }
} continue {
    $n++;
    # Keep the user interested
    if ($n % 100000 == 0) {
        print STDERR "$n ";
    }
}

printf "Total valid combinations: %d (out of %d unique combinations)\n\n", scalar keys %combos, scalar keys %seen;
my $dump = 10;
printf "First %d combinations (sorted):\n", $dump;
for my $i ((sort keys %combos)[0..$dump-1]) {
    print "$i\n";
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