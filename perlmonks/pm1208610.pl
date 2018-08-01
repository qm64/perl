#!/usr/bin/env perl

use strict;
use warnings;

# dummy values for @p, to get the last
my @p = 0..12;

# a single value
my $glob_token = '{0.0,0.2,0.4,0.6,0.8,1.0}';

# join into multiple value string
# (must use non-whitespace, as the builtin glob treats whitespace special)
my $glob_parm = join(",", ($glob_token) x 11);

# Loop fork
for my $parm_list (glob($glob_parm)) {
    # now fix the commas
    $parm_list =~ s/,/\t/g;
    my $temp_out = "$parm_list\t$p[11]\t$p[12]\n";
    print $temp_out;
}

