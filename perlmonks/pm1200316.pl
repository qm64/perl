#!/usr/bin/perl
use strict;
use warnings;

our $quotes = '"' . ('\"' x 10000000) . '"';

print "Length of string is ", length($quotes), "\n";

our @qr;
push @qr, qr/^ " (?: [^"\\]++ |     \\. )*+     " /x ;
push @qr, qr/^ " (?: [^"\\]++ | (?: \\. )++ )*+ " /x ;
push @qr, qr/^ " (?: [^"\\]+  | (?: \\. )+  )*+ " /x ;

for my $i (0..$#qr) {
    print "$i) $qr[$i] ==> ";
    print "NOT " unless $quotes =~ $qr[$i];
    print "MATCHED!\n";
}
__END__
Length of string is 20000002
Complex regular subexpression recursion limit (32766) exceeded at ./pm1200316.pl line 16.
0) (?^x:^ " (?: [^"\\]++ |     \\. )*+     " ) ==> NOT MATCHED!
1) (?^x:^ " (?: [^"\\]++ | (?: \\. )++ )*+ " ) ==> MATCHED!
2) (?^x:^ " (?: [^"\\]+  | (?: \\. )+  )*+ " ) ==> MATCHED!


# why does this use recursion (rather than iteration)?

#Output under perl v5.24.1:
# Complex regular subexpression recursion limit (32766) exceeded at line 6.
# NOT MATCHED!