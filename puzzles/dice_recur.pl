#!/usr/bin/env perl
use strict;
use warnings;

# Problem: brainden.com/forum/index.php/topic/16576-dice-problem/
#
# Number 3 8-sided dice all the same, 120 distinct totals,
# find the numbering with the lowest total.
#
# Notes:
# 1) 1 and $highest_face are always face values.
# 2) $highest_face is incremented (or decremented), and because of (1), will not
#    generate duplicates.
#
# Sample results:
# s=1, d=3
# faces=(1), distinct sums=1,
# sums=[3]

# s=2, d=3
# faces=(1,2), distinct sums=4,
# sums=[3, 4, 5, 6]

# s=3, d=3
# faces=(1,2,5), distinct sums=10,
# sums=[3, 4, 5, 6, 7, 8, 9, 11, 12, 15]

# s=4, d=3
# faces=(1,2,8,12), distinct sums=20,
# sums=[3, 4, 5, 6, 10, 11, 12, 14, 15, 16, 17, 18, 21, 22, 24, 25, 26, 28, 32, 36]

# s=5, d=3
# faces=(1,2,16,19,24), distinct sums=35,
# sums=[3, 4, 5, 6, 18, 19, 20, 21, 22, 23, 26, 27, 28, 33, 34, 36, 37, 39, 40, 41,
#  42, 44, 45, 48, 49, 50, 51, 54, 56, 57, 59, 62, 64, 67, 72]

# s=6, d=3
# faces=(1,3,12,27,43,46), distinct sums=56,
# sums=[3, 5, 7, 9, 14, 16, 18, 25, 27, 29, 31, 33, 36, 40, 42, 45, 47, 48,
#  49, 50, 51, 52, 55, 56, 57, 58, 59, 61, 66, 67, 70, 71, 73, 74, 76, 81,
#  82, 85, 87, 89, 90, 92, 93, 95, 97, 98, 100, 101, 104, 113, 116, 119, 129,
#  132, 135, 138]
#
# s=7, d=3
# faces=(1,2,8,51,60,79,83), distinct sums=84,
# sums=[3, 4, 5, 6, 10, 11, 12, 17, 18, 24, 53, 54, 55, 60, 61, 62, 63, 64, 67,
#  69, 70, 76, 81, 82, 83, 85, 86, 87, 88, 89, 92, 93, 95, 99, 103, 104, 110,
#  112, 113, 119, 121, 122, 128, 131, 132, 135, 136, 138, 140, 141, 142, 144,
#  145, 147, 151, 153, 159, 160, 162, 163, 164, 166, 167, 168, 170, 171, 174,
#  180, 181, 185, 190, 194, 199, 203, 209, 213, 217, 218, 222, 226, 237, 241,
#  245, 249]

my $sides_default = 6;
my $dice_default = 3;
my $goal_default = goal_default($sides_default,$dice_default);
my $highest_face_default = $sides_default;
my $dir_default = 1;
my $quiet_default = 0;

my $sides_opt        = '-s';
my $dice_opt         = '-d';
my $goal_opt         = '-g';
my $highest_face_opt = '-hf';
my $dir_opt          = '-dir';
my $quiet_opt        = '-q';
my $help_opt         = '-h';

my $sides = $sides_default;
my $dice = $dice_default;
my $goal = $goal_default;
my $highest_face = $highest_face_default;
my $dir = $dir_default;
my $quiet = $quiet_default;
my $last_result = '';

sub usage {
    die <<USAGE;
Description:
    $0 computes the dice face values needed to maximize the number of distinct sums.

    All dice have the same set of (unique) face values.

    Combinations are searched in numerical order by minimum highest face value, so this combination will be found first. In the case of negative search direction, the last result is the minimum highest face value.

Usage: $0 [$sides_opt sides] [$dice_opt dice] [$goal_opt goal] [$highest_face_opt highest_face] [$quiet_opt] [$help_opt]

Where:
    $sides_opt      Number of sides (default $sides_default)
    $dice_opt      Number of dice (default $dice_default)
    $goal_opt      Goal for number of distinct sums (default s*(s+1)*(s+2)/6)
    $highest_face_opt     Starting highest face value (default $sides_default) [used to resume an interrupted search, skioping lower highest face values; or when searching downward, limiting the search.]
    $dir_opt    Search down from $highest_face_opt, (default $dir_default, 1=up, -1=down)
    $quiet_opt      Suppress progress output, only emit result (default $quiet_default)
    $help_opt      Get this help

USAGE
}

# Process command line
my $args = join(',', ",",@ARGV,",");
while (@ARGV) {
    if ($ARGV[0] =~ /^$help_opt$/) {
        usage;
    }
    if ($ARGV[0] =~ /^$sides_opt$/) {
        shift @ARGV;
        $sides = shift @ARGV;
        $highest_face_default = $sides;
        $goal_default = goal_default($sides,$dice);
        next;
    }
    if ($ARGV[0] =~ /^$dice_opt$/) {
        shift @ARGV;
        $dice = shift @ARGV;
        $goal_default = goal_default($sides,$dice);
        next;
    }
    if ($ARGV[0] =~ /^$goal_opt$/) {
        shift @ARGV;
        $goal = shift @ARGV;
        next;
    }
    if ($ARGV[0] =~ /^$dir_opt$/) {
        shift @ARGV;
        $dir = -1;
        next;
    }
    if ($ARGV[0] =~ /^$quiet_opt$/) {
        shift @ARGV;
        $quiet = 1 - $quiet;
        next;
    }
    if ($ARGV[0] =~ /^$highest_face_opt$/) {
        shift @ARGV;
        $highest_face = shift @ARGV;
        next;
    }
    print STDERR "Unknown option $ARGV[0]...\n";
    usage;
}

# Check for dependent options in command line
unless ($args =~ /,$goal_opt,/) {
    $goal = $goal_default;
}
unless ($args =~ /,$highest_face_opt,/) {
    $highest_face = $highest_face_default;
}

unless ($quiet) {
    print "Searching:\n";
    report_options();
}

my $highest_count_seen = 0;
my $highest_face_seen = 0;

# Autoflush STDOUT
$|++;

# All solutions include a face of 1
my $face_list;
for my $d (1..$dice) {
	$face_list->{$d} = {$d=>1};
}

if ($sides == 1) { # trivial case
    value($face_list);
} else {
    # increasing $max_face only
    while (1) {
        my ($result) = find_next_face($face_list);
        if ($result) {
           value($result);
           last;
        }
    } continue {
        $highest_face += $dir;
        printf "%s) %s=%d\n", time_stamp(), $highest_face_opt,$highest_face unless $quiet;
    } # while (1)
}

# input:
#   $face_list{1} : hash of faces
#   $face_list{2} : hash of pairwise sums
#   $face_list{3} : hash of threeway sums
#   ...
# return
#   first solution found, 0 if no solution possible
sub find_next_face {
    # Catch inputs (copies of hashes)
    my $face_list = shift;

    # Find the face to start the search
    my @faces_so_far = sort keys %{$face_list->{1}};
    my $start_face;
    if (scalar @faces_so_far == $sides-1) {
    	$start_face = $highest_face;
    } else {
	    $start_face = $faces_so_far[-1]+1; # largest face value, plus 1
	}

	return(0) if ($start_face > $highest_face);

	my ($result) = try_faces($start_face,$face_list);
	return($result);
} # find_next_face

sub try_faces {
	my $start_face = shift;
    my $face_list = shift;

    for my $try_face ($start_face..$highest_face) {
        my ($result) = sieve_sums($try_face,$face_list);
        next unless $result;

        # So far, this is a good list of faces.
        # If we have enough face values, return
        my $faces_so_far = scalar keys %{$result->{1}};
        if ($faces_so_far == $sides) {
        	return($result);
      	}

      	# If there are more sides to add, recurse
        my ($next_result) = find_next_face($result);
        if ($next_result) {
            return($next_result);
        }
        # No good solutions, try the next face...
    }
    return(0);
} # try_faces

# "Sieve" sums
# input:
#   $try_face     : next face to try
#   $face_list{1} : hash of faces
#   $face_list{2} : hash of pairwise sums
#   $face_list{3} : hash of threeway sums
#   ...
# return
#   hash with "good so far" result, or 0 if duplicate sum found
sub sieve_sums {
    # Catch inputs (copy of hashes)
    my $try_face = shift;
    my %face_list = %{deep_copy(shift)}; # deep copy for recursion

    # Add $try_face and its sums to each list
    $face_list{1}{$try_face} = 1;
    for my $d (2..$dice) {
        for my $s (keys %{$face_list{$d-1}}) {
            my $sum = $s + $try_face;
            if (exists($face_list{$d}{$sum})) {
            	my $counts = scalar keys %{$face_list{$dice}};
            	if ($counts > $highest_count_seen) {
            		$highest_count_seen = $counts;
            		value(\%face_list) unless $quiet;
            	}
            	return(0);
           	}
            $face_list{$d}{$sum} = 1;
        }
    }
    return(\%face_list);
} # sieve_sums

# Deep copy of hashes
# input:
#    $orig : hash ref
# return
#    $copy : ref to deep copy of orig
sub deep_copy {
	my $orig = shift;
	my $copy = {};

	while(my ($k,$v) = each %$orig) {
		if (ref $v) {
			$copy->{$k} = deep_copy($v);
		} else {
			$copy->{$k} = $v;
		}
	}
	return $copy;
} # deep_copy

sub value {
	my %result = %{+shift};
	my @faces = sort {$a<=>$b} keys %{$result{1}};
	my @sums = sort {$a<=>$b} keys %{$result{$dice}};

	my $side_string = "(" . join(',', @faces) . ")";
	printf "%s) Distinct sums of %s = %d, [%s]\n",
	       time_stamp(),
	       $side_string,
	       scalar @sums,
           join(", ", @sums);
} # value

sub goal_default {
# nCk, with repetition, sometimes denoted as:
#
#  (( n ))
#  (( k ))
#
# The formula is (s+d-1)! / ((s-1)!d!)
#
# The below method reduces the chance that floats and
# binary precision errors get mixed in.
    my $sides = shift;
    my $dice = shift;
    my $goal = 1;
    for my $d (1..$dice) {
    	$goal *= ($sides+$d-1);
    	$goal /= $d;
	}
    return $goal;
}

sub report_options {
	printf "\n%s\n", time_stamp();
    print "\t$sides_opt=$sides\n";
    print "\t$dice_opt=$dice\n";
    print "\t$goal_opt=$goal\n";
    print "\t$highest_face_opt=$highest_face\n";
}

sub time_stamp {
	my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $time_stamp = sprintf "%d %0d%s %0d, %0d:%0d:%0d",
		$year+1900, $mon+1, $months[$mon], $mday, $hour, $min, $sec;
	return $time_stamp;
}
