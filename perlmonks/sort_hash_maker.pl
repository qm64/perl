#!/usr/bin/env perl

# Example sort sub maker
# https://perlmonks.pairsite.com/?node_id=1198333

use strict;
use warnings;
use feature qw{ say };
use Scalar::Util qw{ looks_like_number };

sub make_sort_sub {
    my $code = shift;
    my $hashref = shift;
    my $sort_sub = eval "sub { $code }";
    die $@ if $@;
    return $sort_sub;
}

# simple code snippet
my %hash = ( a => 5, b => 4, c => 3, d => 5, e => 4 );
my $keys_by_value = make_sort_sub(
    '$hashref->{$a} <=> $hashref->{$b}',
    \%hash);
my @keys_sorted_by_value = sort $keys_by_value keys %hash;
say @keys_sorted_by_value;

# Try with curlies now
$keys_by_value = make_sort_sub(
    '{$hashref->{$a} <=> $hashref->{$b}}',
    \%hash);
@keys_sorted_by_value = sort $keys_by_value keys %hash;
say @keys_sorted_by_value;

# Naive compare by values as numbers, keys as strings
my $keys_by_value_or_keys = make_sort_sub(
    '$hashref->{$a} <=> $hashref->{$b} or $a cmp $b',
    \%hash);
my @keys_by_value_or_keys = sort $keys_by_value_or_keys keys %hash;
say @keys_by_value_or_keys;

# Compare as numbers then strings, values then keys
# my %hash2 = (a => 'a', b => 'b', c => 3, d => 4);
my %hash2 = (a => 'a', b => 'b', c => 34, d => 444);
my $keys_by_value_or_keys_mixed = make_sort_sub(
    'return $hashref->{$a} <=> $hashref->{$b}
         if ((looks_like_number($hashref->{$a}) and looks_like_number($hashref->{$b}))
         and ($hashref->{$a} <=> $hashref->{$b}));
     return $hashref->{$a} cmp $hashref->{$b}
         if ($hashref->{$a} cmp $hashref->{$b});
     return $a <=> $b
        if ((looks_like_number($a) and looks_like_number($b)) and ($a <=> $b));
     return $a cmp $b;',
    \%hash2);
my @keys_by_value_or_keys_mixed = sort $keys_by_value_or_keys_mixed keys %hash2;
say @keys_by_value_or_keys_mixed;

exit;
