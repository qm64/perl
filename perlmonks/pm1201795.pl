#!/usr/bin/env perl
#
# Match a char only occuring once in a string.
# See https://perlmonks.pairsite.com/?node_id=1201795

use strict;
use warnings;

my @alpha = ('a'..'b');
my $alpha = join(',', @alpha);
my @input = glob "{$alpha}" x 12;

my @regex;
for my $c (@alpha) {
    my $d = quotemeta($c);
    push @regex, "(?:[^$d]*)([$d])(?:[^$d]*)";
}

my $once = join('|', @regex);
my $matches;
my $attempts;

for my $i (@input) {
    my(@catch) = $i =~ /^(?:$once)$/;
    if (@catch) {
        my $catch = join('', grep {defined($_)} @catch);
#        printf "(%s) => (%s)\n", $catch, $i;
        $matches++;
    }
    $attempts++;
}

printf "matches: %s/%s\n", $matches, $attempts;
exit;
