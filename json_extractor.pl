#!/usr/bin/env perl
# Pull JSON strings out of a log file, and output as a list of JSON elements.

print "[\n";
my $ever_printed = 0;

while (<>) {
    if (my ($json) = m/content:\s*(\{.*\})\s*$/) {
        if ($ever_printed) {
            print ",\n";
        }
        print "\t$json";
        $ever_printed = 1;
    }
}
print "\n]\n";

exit;
