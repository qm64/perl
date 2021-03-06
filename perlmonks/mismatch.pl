#!/usr/bin/env perl

use strict;
use warnings;

# Find a subset of one string in another string, with at least N character run,
# where no more than M characters in the run don't match.

# From https://perlmonks.pairsite.com/?node_id=1199101

# In that example, N=10, M=1

our $N_DEFAULT = 10;
our $M_DEFAULT = 1;

our $N = $N_DEFAULT;
our $M = $M_DEFAULT;

our $A_DEFAULT = <<'SHORTER';
AAATTGGTGTATATGAAAGACCTCGACGCTATTTAGAAAGAGAGAGCAATATTTCAAGAATGCATGCGTCAATTTTACGCAGACTATCTTTCTAGGGTTAAATATACTGACAGTGTGCAGTGACTCACAAAAGATGATTA
SHORTER

our $B_DEFAULT = <<'LONGER';
ACAATGAGATCACATGGACACAGGAAGGGGAATATCACACTCTGGGGACTGTGGTGGGGTCGGGGGAGGGGGGAGGGATAGCATTGGGAGATATACCTAATGCTAGATGACGTCCATACTGAGAATCATGTTAACATTAGTGGGTGCAGCGCACAAGCATGGCACATGTATACATATGTAACTAACCTGCACAATGTGCACATGTACCCTAAAACTTAGAGTATAATAAAAAAAAAAAAAAAAAAAAAAAAAAACACATTAAAAAAAAAAAAAACAACAAAACAAAGCAAACATGGAAATGTTTGTTATTTTAATTGTTATGATGGTTTCATGGCTGTTTGCATGTGTCAAAACTCATCAAATTTGTGTACGTTAAATATGTGAAACTTATTGTATGCTGGTTACACCTCAATAAAGCTGTTAAATTTAAAAAAAAAAAAAAAAAAAAAAATCACCAATAGTTGCTGCTAGAAATCCAGTGTCACAAAAGGCCAAAGTTTATTGACAAATTGGTGTATATGAAAGACCTCGACGCTATTTAGAAAGAGAGAGCAATATTTCAAGAATGCATGCGTCAATTTTACGCAGACTATCTTTCTAGGGTTAATCTAGCTGCATCAGGATCATATCGTCGGGTCTTTTTTCCGGCTCAGTCATCGCCCAAGCTGGCGCTATCTGGGCATCGGGGAGGAAGAAGCCCGTGCCTTTTCCCGCGAGGTTGAAGCGGCATGGAAAGAGTTTGCCGAGGATGACTGCTGCTGCATTGACGTTGAGCGAAAACGCACGTTTACCATGATGATTCGGGAAGGTGTGGCCATGCACGCCTTTAACGGTGAACTGTTCGTTCAGGCCACCTGGGATACCAGTTCGTCGCGGCTTTTCCGGACACAGTTCCGGATGGTCAGCCCGAAGCGCATCAGCAACCCGAACAATACCGGCGACAGCCGGAACTGCCGTGCCGGTGTGCAGATTAATGACAGCGGTGCGGCGCTGGGATATTACGTCAGCGAGGACGGGTATCCTGGCTGGATGCCGCAGAAATGGACATGGATACCCCGTGAGTTACCCGGCGGGCGCGCTTGGCGTAATCATGGTCATAGCTGTTTCCTGTGTGAAATTGTTATCCGCTCACAATTCCACACAACATACGAGCCGGAAGCATAAAGTGTAAAGCCTGGGGTGCCTAATGAGTGAGCTAACTCACATTAATTGCGTTGCGCTCACTGCCCGCTTTCCAGTCGGGAAACCTGTCGTGCCAGCTGCATTAATGAATCGGCCAACGCGCGGGGAGAGGCGGTTTGCGTATTGGGCGCTCTTCCGCTTCCTCGCTCACTGACTCGCTGCGCTCGGTCGTTCGGCTGCGGCGAGCGGTATCAGCTCACTCAAAGGCGGTAATACGGTTATCCACAGAATCAGGGGATAACGCAGGAAAGAACATGTGAGCAAAAGGCCAGCAAAAGGCCAGGAACCGTAAAAAGGCCGCGTTGCTGGCGTTTTTCCATAGGCTCCGCCCCCCTGACGAGCATCACAAAAATCGACGCTCAAGTCAGAGGTGGCGAAACCCGACAGGACTATAAAGATACCAGGCGTTTCCCCCTGGAAGCTCCCTCGTGCGCTCTCCTGTTCCGACCCTGCCGCTTACCGGATACCTGTCCGCCTTTCTCCCTTCGGGAAGCGTGGCGCTTTCTCATAGCTCACGCTGTAGGTATCTCAGTTCGGTGTAGGTCGTTCGCTCCAAGCTGGGCTGTGTGCACGAACCCCCCGTTCAGCCCGACCGCTGCGCCTTATCCGGTAACTATCGTCTTGAGTCCAACCCGGTAAGACACGACTTATCGCCACTGGCAGCAGCCACTGGTAACAGGATTAGCAGAGCGAGGTATGTAGGCGGTGCTACAGAGTTCTTGAAGTGGTGGCCTAACTACGGCTACACTAGAAGGACAGTATTTGGTATCTGCGCTCTGCTGAAGCCAGTTACCTTCGGAAAAAGAGTTGGTAGCTCTTGATCCGGCAAACAAACCACCGCTGGTAGCGGTGGTTTTTTTGTTTGCAAGCAGCAGATTACGCGCAGAAAAAAAGGATCTCAAGAAGATCCTTTGATCTTTTCTACGGGGTCTGACGCTCAGTGGAACGAAAACTCACGTTAAGGGATTTTGGTCATGAGATTATCAAAAAGGATCTTCACCTAGATCCTTTTAAATTAAAAATGAAGTTTTAAATCAATCTAAAGTATATATGAGTAAACTTGGTCTGACAGTTACCAATGCTTAATCAGTGAGGCACCTATCTCAGCGATCTGTCTATTTCGTTCATCCATAGTTGCCTGACTCCCCGTCGTGTAGATAACTACGATACGGGAGGGCTTACCATCTGGCCCCAGTGCTGCAATGATACCGCGAGACCCACGCTCACCGGCTCCAGATTTATCAGCAATAAACCAGCCAGCCGGAAGGGCCGAGCGCAGAAGTGGTCCTGCAACTTTATCCGCCTCCATCCAGTCTATTAATTGTTGCCGGGAAGCTAGAGTAAGTAGTTCGCCAGTTAATAGTTTGCGCAACGTTGTTGCCATTGCTACAGGCATCGTGGTGTCACGCTCGTCGTTTGGTATGGCTTCATTCAGCTCCGGTTCCCAACGATCAAGGCGAGTTACATGATCCCCCATGTTGTGCAAAAAAGCGGTTAGCTCCTTCGGTCCTCCGATCGTTGTCAGAAGTAAGTTGGCCGCAGTGTTATCACTCATGGTTATGGCAGCACTGCATAATTCTCTTACTGTCATGCCATCCGTAAGATGCTTTTCTGTGACTGGTGAGTACTCAACCAAGTCATTCTGAGAATAGTGTATGCGGCGACCGAGTTGCTCTTGCCCGGCGTCAATACGGGATAATACCGCGCCACATAGCAGAACTTTAAAAGTGCTCATCATTGGAAAACGTTCTTCGGGGCGAAAACTCTCAAGGATCTTACCGCTGTTGAGATCCAGTTCGATGTAACCCACTCGTGCACCCAACTGATCTTCAGCATCTTTTACTTTCACCAGCGTTTCTGGGTGAGCAAAAACAGGAAGGCAAAATGCCGCAAAAAAGGGAAAAGGGCGACACGGAAATGTTGAATACTCAT
LONGER

our $A = $A_DEFAULT;
our $B = $B_DEFAULT;

our $N_OPT = '-n';
our $M_OPT = '-m';
our $A_OPT = '-a';
our $B_OPT = '-b';

############################

sub usage {
    use File::Basename;
    my($filename, $dirs, $suffix) = fileparse($0);
    my $script_name = $filename . $suffix;

    print STDERR "Given 2 strings, find the overlaps at least N chars long, where no more than M chars mismatch.\n\n";

    print STDERR "Usage:\n";
    print STDERR "\t$script_name [$N_OPT n] [$M_OPT -m] [$A_OPT string_a] [$B_OPT string_b]\n";
    print STDERR "Where:\n";
    print STDERR "\t$N_OPT n : minimum length of overlap (default $N_DEFAULT)\n";
    print STDERR "\t$M_OPT n : maximum mismatch positions (default $M_DEFAULT)\n";
    print STDERR "\t$A_OPT string_a : first string to use (default not shown)\n";
    print STDERR "\t$B_OPT string_b : second string to use (default not shown)\n";
    exit;
}

######################
# process command line

while (@ARGV) {
    if ($ARGV[0] eq $N_OPT and defined($ARGV[1]))  {
        $N = $ARGV[1];
        shift;shift;
        next;
    }

    if ($ARGV[0] eq $M_OPT and defined($ARGV[1]))  {
        $M = $ARGV[1];
        shift;shift;
        next;
    }

    if ($ARGV[0] eq $A_OPT and defined($ARGV[1]))  {
        $A = $ARGV[1];
        shift;shift;
        next;
    }

    if ($ARGV[0] eq $B_OPT and defined($ARGV[1]))  {
        $B = $ARGV[1];
        shift;shift;
        next;
    }

    warn "Unknown argument $ARGV[0], or not enough arguments, aborting\n";
    usage;
}

###################
# recursive sub to generate all combinations of wildcards in M positions,
# starting from given start.
sub replace {
    my $regex = shift;
    my $start = shift;
    my $count = shift;

    if ($count == 0) {
        return $regex;
    }

    my @regex;
    for my $i ($start..length($regex)-$count) {
        my $new_regex = $regex;
        substr($new_regex, $start, 1, '.'); # change this one
        for my $j ($start+1..length($regex)-$count+1) {
            push @regex, replace($new_regex, $j, $count-1); # create derivatives
        }
    }
    return @regex;
}

###################
# main

# If necessary, swap strings so A is the shortest
if (length($A) > length($B)) {
    ($A, $B) = ($B, $A);
}

# Generate the list of all substrings of length N
# Use a hash to avoid duplicates
my %chunks = map {substr($A,$_,$N)=>1} 0..length($A)-$N;

# Generate the list of all regexes, replacing M characters with wildcards
# Use a hash to avoid duplicates
my %regex;
for my $chunk (keys %chunks) { # for each chunk
    for my $i (0..length($chunk)-$M) { # for each starting position index
        my $regex = $chunk;
        my $j = $i;
        my @regex = replace($regex, 0, $M);

        # Add them, uniquely
        for my $r (@regex) {
            $regex{$r} = 1;
        }
    }
}

# Join the regexes
# (does sorting keys help?)
my $big_regex_string = join('|', sort keys %regex);
my $big_regex = qr/$big_regex_string/;

# Get all matches
my %matches;
while ( $B =~ m/($big_regex)/g ) {
    $matches{$1}++;
    pos($B) -= length($1)-1;
}

# This also works
#1 while $B =~ m/($big_regex)(?{$matches{$&}++;})(?!)/;

for my $k (sort keys %matches) {
    print "$k : $matches{$k}\n";
}

exit;
