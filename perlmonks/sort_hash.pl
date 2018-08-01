#!/usr/bin/env perl
# Example of a meta sort routine for hash values

use warnings;
use strict;
use feature qw{ say };

# $sub is a codeblock, which can really on reference $a, $b.
sub sort_hash (&\%) {
    my ($sub, $hash) = @_;
    sort {
        local($a, $b) = @$hash{$a, $b};
        $sub->()
    } keys %$hash
}

my $count;
my %hash = ( second => 2, fourth => 4, third => 3, first => 1 );
say ++$count;
say for sort_hash { $a <=> $b } %hash;

sub numerically {
    $a <=> $b
}

say ++$count;
say for sort_hash {numerically} %hash;

exit;
