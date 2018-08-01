#!/usr/bin/env perl

# From OEIS A180632, https://oeis.org/A180632:
#
# Minimum length of a string of letters that contains every permutation of N letters
# as sub-strings, also known as length of the minimal super-permutation.
#
# That is, the permutations should overlap in the final string.

# Given N, compute the shortest substring.

# Method:
# 0) Define an alphabet of length N
# 1) Generate all permutations of length N, of the N-alphabet
# 2) Starting from a random permutation,
# 3) Try adding an unused permutation with the same prefix
#    as a suffix of the last permutation.
# 4) Keep track of the shortest result.
# 5) Backtrack when any result must be longer than the best result
#    (e.g., when there are more unused permutations than
#    the difference between the length of the current result
#    and the length of the best result)

# The result up to 5 is known. For 6, the best result known is 872
# (see https://mathoverflow.net/questions/289976/examples-of-integer-sequences-coincidences/290002#290002).

use strict;
use warnings;

our $N = (shift // 6);

# Alpabet up to 62
our @SYMBOLS = ('1'..'9', '0', 'A'..'Z', 'a'..'z')[0..$N-1];

our %PERMUTATIONS;
our %PREFIXES;
our %SUFFIXES;

for my $n (0..(fac(scalar(@SYMBOLS))-1)) {
    my $perm = permutation_n($n, @SYMBOLS);
    $PERMUTATIONS{$perm} = 1;
    ($PREFIXES{$perm}, $SUFFIXES{$perm}) = allfixes($perm);
}

#############################
# Now the fun begins




exit;

#############################################

# Find and return the $n'th permutation
# of the remaining arguments in some canonical order
# (modified from QOTW solution)
sub permutation_n
{
  my $n = shift;
  # The remaining elements, as a list, are the characters to be permuted.
  # (They could be multichar strings, but that would be weird?)
  my $result = '';
  while (@_)
  {
    ($n, my $r) = (int($n/@_), $n % @_);
    $result .= splice @_, $r, 1;
  }
  return $result; # a string
}

# Simple factorial, not expecting heavy use or large results
sub fac {
    my $n = shift;
    my $f = 1;
    for my $i (2..$n) {
        $f *= $i;
    }
    return $f;
}

# Compute all prefixes and suffixes of a given string.
# Return as 2 array refs, where $pre->[3] is the prefix of length 3, etc.
# Zero-length results are surpressed.
sub allfixes {
    my $perm = shift;
    my(@prefix, @suffix);
    $prefix[length($perm)] = $suffix[length($perm)] = $perm;

    for my $i (1..length($perm)-1) {
        my $pre = substr($perm,0,$i);
        my $suf = substr($perm,$i);
        $prefix[length($pre)] = $pre;
        $suffix[length($suf)] = $suf;
    }

    return (\@prefix, \@suffix);
}
