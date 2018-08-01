#!/usr/bin/env perl

use strict;
use warnings;

# Report all non-empty, unique quoted strings

my %seen;

while (<>) {
    while (/(["'])([^'"]+)\1/g) {
        next unless defined($2);
        $seen{$2}++;
    }
}

for my $string (sort keys %seen) {
    if ($seen{$string} >= 2) {
        print "$string ($seen{$string})\n";
    }
}

exit;