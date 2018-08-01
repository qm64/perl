#!/usr/bin/env perl

# Generate random acronyms, with a given mean and sigma.
# Approximate a normal distribution around mu +/- sigma.

use strict;
use warnings;

use File::Basename;

our $N = '-n';
our $M = '-m';
our $S = '-s';
our $D = '-d';

our $n = 5;
our $m = 5;
our $s = 3;
our $debug = 0;

our $PI = 3.14159265358979323846264338327950288419716939937510582;

sub phi {
    my $x = shift; # random input
    my $mu = shift // 0;
    my $sigma = shift // 1;

    my $result = 2*$x*$sigma + $mu;

    printf STDERR "x:%5.3f, m:%d, s:%d, result:%5.3f\n", $x, $mu, $sigma, $result if $debug;

    return $result;
}

sub rand_acro {
    my $n = shift;
    my $x = '';
    for my $i (1..$n) {
        my $ch = ('A'..'Z')[int(rand(26))];
        $x .= $ch;
#    $x .= ('A'..'Z')[int(rand(26))] for my $i (1..$n);
    }
    print STDERR "n:$n, x:$x\n" if $debug;
    return $x;
}

sub usage {
    my($filename, $dirs, $suffix) = fileparse($0);
    my $script_name = $filename . $suffix;

    print STDERR "Output random acronyms based on a normal distribution with lengths conforming to a given mean and sigma\n\n";
    print STDERR "Usage:\n";
    print STDERR "\t$script_name [$N count] [$M mean_length] [$S sigma_length]\n";
    exit;
}


while (@ARGV) {
    if ($ARGV[0] eq $N and defined($ARGV[1]))  {
        $n = $ARGV[1];
        shift;shift;
        next;
    }

    if ($ARGV[0] eq $M and defined($ARGV[1]))  {
        $m = $ARGV[1];
        shift;shift;
        next;
    }

    if ($ARGV[0] eq $S and defined($ARGV[1]))  {
        $s = $ARGV[1];
        shift;shift;
        next;
    }

    if ($ARGV[0] eq $D)  {
        $debug = 1;
        shift;
        next;
    }

    warn "Unknown argument $ARGV[0], aborting\n";
    usage;
}

for my $nn (1..$n) {
    my $phi = phi(rand(), $m, $s);
    $phi = 2 if ($phi < 2);
    my $acro = rand_acro(int($phi));
    print STDERR "$nn:" if $debug;
    print "$acro\n";
}

exit;
