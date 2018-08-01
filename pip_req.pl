#!/usr/bin/env perl
#
# Sort through a list of pip "requirements.txt" files, such as the output from:
#
#   find . -name requirements.txt -exec cat {} \;
#
# and remove duplicates. Only duplicates with the highest version number will be
# emitted.

use strict;
use warnings;

use File::Basename;

######################
# common strings and regexes
our $SEP_DEF = '==';
our $SEP_OPT = '-s';
our $SEP = $SEP_DEF;

##############################

sub usage {
    my($filename, $dirs, $suffix) = fileparse($0);
    my $script_name = $filename . $suffix;

    print STDERR "\n";
    print STDERR "$script_name: Deduplicate pip requirements.txt key/value pairs, such that the highest version ";
    print STDERR "number of each package is emitted.\n";
    print STDERR "\n";
    print STDERR "The input to this script might be from another command, such as:\n";
    print STDERR "\n";
    print STDERR "        find . -name requirements.txt -exec cat {} \\; | $script_name\n";
    print STDERR "    or\n";
    print STDERR "        find . -name requirements.txt | xargs $script_name\n";
    print STDERR "\n";
    print STDERR "The output of this script might be piped to pip as:\n";
    print STDERR "\n";
    print STDERR "        | xargs pip\n";
    print STDERR "\n";
    print STDERR "Usage:\n";
    print STDERR "        $script_name [$SEP_OPT separator] kv_pair kv_pair...\n";
    print STDERR "    or\n";
    print STDERR "        some_command | $script_name [$SEP_OPT separator]\n";
    print STDERR "\n";
    print STDERR "Where:\n";
    print STDERR "    $SEP_OPT separator    is the separator between keys and values.\n";
    print STDERR "                    (beware of special shell characters)\n";
    exit;
}

######################
# No need to process command line.
# Just check if there are filename arguments, or a pipe
usage unless (@ARGV or not -t STDIN);

#####################
# Process command line
my @temp_args;

while (@ARGV)
{
    if ($ARGV[0] eq $SEP_OPT)
    {
        shift @ARGV;
        if (@ARGV)
        {
            $SEP= shift(@ARGV);
            next;
        }
        else
        {
            usage;
        }
    }

    push @temp_args, shift @ARGV;
}

@ARGV = @temp_args;

######################
# Main body
our %target;

while (<>) {
    chomp;
    next unless length($_);
    my ($key, $val) = split /$SEP/;
    if (defined($val)) {
        # Not a bare target...
        if (exists($target{$key})) {
            # There is a previous matching target,
            # so save the highest value.
            $target{$key} = (sort alpha_num ($target{$key}, $val))[1];
        } else {
            # There was no previous matching target, save this value
            $target{$key} = $val;
        }
    } elsif (not exists($target{$key})) {
        # No previous matching target, no explicit value, save the empty string.
        $target{$key} = "";
    }
}

# Emit the key/value pairs, in sorted order for convenience.
# (This could be done in discovered order, but given that multiple pip requirements.txt
#  files might be involved, discovered order doesn't mean much.)
for my $key (sort { "\U$a" cmp "\U$b"} keys %target) {
    if (length($target{$key})) {
        print "${key}${SEP}$target{$key}";
    } else {
        print $key;
    }
    print "\n";
}

# Stopping place when debugging
exit;

#############################
# Sort strings, such as version numbers, where numeric and non-numeric fields alternate.
# This is a magic sort routine, making use of $a and $b.
# (See http://perldoc.perl.org/functions/sort.html)
sub alpha_num {
    # Split into numbers and not-numbers, keeping separators.
    # If the first field is a number, the zeroth element will be the empty string.
    # (So long as the strings are comparable, this won't be a problem
    my @x = split /(\d+)/, $a;
    my @y = split /(\d+)/, $b;

    while (@x and @y) {
        my $r;
        if ($x[0] =~ /^\d+$/ and $y[0] =~ /^\d+$/) {
            if ($r = $x[0] <=> $y[0]) { return $r }
        } else {
            if ($r = $x[0] cmp $y[0]) { return $r }
        }
        shift @x;
        shift @y;
        next;
    }

    # Up to the end of the shortest string (by field count), they are equal.
    # Report the longest string (by field count).
    return @x <=> @y;
}

