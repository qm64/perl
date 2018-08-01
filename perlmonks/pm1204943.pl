#!/usr/bin/env perl

use strict;
use warnings;

my @files = <c:/perl64/myfiles/*>;

# record matching regexes
our %matched;

my @nums = ('1203', '1204', '1207');
my $regex = '\b(?:' + join('|', @nums) + ')\b';

for my $file ( @files ) {

    open my $file_h, '<', $file or die "Can't open $file: $!";

    while ( <$file_h> ) {
        if (my ($match) = m/$regex/) {
            $matched{$match} = 1;
            print "$file $_";
        }
    }
}

# Check all nums have been seen
for my $num (@nums) {
    if (not exists($matched{$num})) {
        print "$num not found\n";
    }
}
