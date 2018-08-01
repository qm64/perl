#!/usr/bin/env perl
use strict;
use warnings;

# Find optimal Golomb-like ruler, given a list of lengths to measure.
# See http://www.elliottline.com/puzzles-1/2017/10/6/puzzle-of-the-week-120-quality-control

use File::Basename;

# Autoflush stdout
BEGIN { $| = 1 }

#######################
# options and defaults

our @LEN_DEFAULT = qw(7 17 18 19 25 37 44 46 63 65 82 83 90 100);
our $LEN_OPT = q/-l/;
our @LENS = qw(7 17 18 19 25 37 44 46 63 65 82 83 90 100);
our $TRIES_OPT = q/-t/;
our $TRIES_DEFAULT = 1000;
our $TRIES = $TRIES_DEFAULT;

######################
# constants

our $COVER = q/cover/;
our $MARKS = q/marks/;
our $NUMBER_MATCH = qr/^\d+$/;

######################

sub usage {
    my($filename, $dirs, $suffix) = fileparse($0);
    my $script_name = $filename . $suffix;

    print STDERR "Solve Elliot's Puzzle of the Week #120\n\n";
    print STDERR "Compute the ruler with the fewest marks to measure each length, and the shortest ruler.\n\n";
    print STDERR "Usage:\n";
    print STDERR "\t$script_name [$LEN_OPT len...] [$TRIES_OPT tries]\n\n";
    print STDERR "Where:\n";
    print STDERR "\t$LEN_OPT len...   list of lengths to cover (default: @LENS)\n";
    print STDERR "\t$TRIES_OPT tries  number of iterations (default: $TRIES_DEFAULT)\n";
    exit;
}

######################
# Process the command line

my $len_seen = 0;
while (@ARGV) {
    if ($ARGV[0] eq $LEN_OPT) {
        $len_seen = 1;
        @LENS = ();
        shift;
        next;
    }

    if (($ARGV[0] =~ $NUMBER_MATCH)
    and ($len_seen)) {
        push @LENS, shift;
        next;
    }

    $len_seen = 0;

    if (($ARGV[0] eq $TRIES_OPT)
    and (defined($ARGV[1]))
    and ($ARGV[1] =~ $NUMBER_MATCH)) {
        $TRIES = $ARGV[1];
        shift;shift;
        next;
    }

    usage();
}

# Sort them, just in case
@LENS = sort {$a<=>$b} @LENS;
print "Lengths to measure: (@LENS)\n\n";

######################
# Given a list of marks, generate all of the possible lengths that can be measured between any two.
# The ends of the rod are also considered marks, so 0 and length_of_rod should also be given.
# Assume all marks are unique.

sub get_measures {
    my @marks = @_;

    my %lens;

    for my $m2 (1..$#marks) {
        for my $m1 (0..$m2-1) {
            my $len = $marks[$m2] - $marks[$m1];
            $lens{$len} = "$marks[$m2] - $marks[$m1]";
        }
    }
    return \%lens;
}

######################
# Given a target list of measures, and a proposed list of measures,
# report the number of measures covered in the target.

sub measures_covered {
    my $lens_ref = shift;
    my $meas_ref = shift;

    my %result = map {$_ => 1} grep {exists($meas_ref->{$_})} keys %$lens_ref;

    return \%result;
}

######################
# Print math

sub print_math {
    my $lens_ref = shift;
    my $meas_ref = shift;

    for my $len (sort {$a<=>$b} keys %$lens_ref) {
        if (exists($meas_ref->{$len})) {
            printf "\t$len = $meas_ref->{$len}\n";
        } else {
            print "\t$len = (not found)\n";
        }
    }
}

######################
# Generate a naive ruler, with every mark a length from 0
# Always include 0
my @marks = (0);
push @marks, sort {$a<=>$b} @LENS;
my %LENS = map {$_ => 1} @LENS;

######################
# Check the current marks, and record number of measures covered.
# Randomly add or remove marks

my %checked;
my $best_marks_key = ''; # key of %checked with full coverage, fewest marks
my $best_cover = 0; # highest coverage number
my $best_marks = 2 * scalar @LENS; # lowest number of marks
my $best_math = ''; # ref to how the lengths are covered
my $last_cover = 0;

for my $try (1..$TRIES) {
    my $rand = rand($try);
#    print STDERR "\n$try rand: $rand, ";
    # If all lengths are covered, there are at least 2 marks,
    # and randomly (later passes are more likely to remove a mark)
    if ((@marks > 2) and ($rand > 1)) {
        # randomly remove a mark, but not zero
#        print STDERR "remove";
        my $r1 = int(rand(@marks-1)) + 1;
        @marks = @marks[0..$r1-1,$r1+1..$#marks];
    } else {
        # randomly add a mark
#        print STDERR "add";
        my %marks = map {$_ => 1} @marks;
        for my $trial (1..100) {
            # Pick a random number up to 10x the highest length.
            my $new_mark = int(rand($LENS[-1]))+1;
            next if exists($marks{$new_mark});
            @marks = sort {$a <=> $b} @marks, $new_mark;
            last;
        }
    }

    my $marks = join(',', sort {$a<=>$b} @marks);
    if (exists($checked{$marks})) {
        # already tried this one, let's restart from the best @marks
        @marks = split ',', $best_marks_key;
#        print STDERR "Seen it, resetting...\n";
        next;
    }

    my $measures_ref = get_measures(@marks);
    my $measures_covered_ref = measures_covered(\%LENS, $measures_ref);
    $last_cover = $checked{$marks}{$COVER} = scalar keys %$measures_covered_ref;
    $checked{$marks}{$MARKS} = scalar @marks;

    if (($checked{$marks}{$COVER} >= $best_cover)
     and ($checked{$marks}{$MARKS} <= $best_marks)) {
        $best_cover = $checked{$marks}{$COVER};
        $best_marks = $checked{$marks}{$MARKS};
        $best_math = $measures_ref;
        $best_marks_key = $marks;
        printf "%d) marks=(%s), #cover=%s, #marks=%s\n", $try, $marks, $best_cover, $best_marks;
        print_math(\%LENS, $measures_ref);

#    } else {
#        printf "marks=(%s), #cover=%s, #marks=%s\n", $marks, $checked{$marks}{$COVER}, $checked{$marks}{$MARKS};
    }

#    print STDERR ".";
}

print "\nFinally...\n";
print "Lengths to measure: (@LENS)\n";
printf "marks=(%s), #cover=%s, #marks=%s\n", $best_marks_key, $best_cover, $best_marks;
print_math(\%LENS, $best_math);

exit;
