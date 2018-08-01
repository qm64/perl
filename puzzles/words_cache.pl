#!/usr/bin/env perl

# Generic word puzzle tool

# Read one or more word list files in.
# Run some code or regex on the list.
# Output the results.

use strict;
use warnings;

use File::Basename;
use File::Spec qw(catfile);
use DBM::Deep;

our ($FILENAME, $DIRS, $SUFFIX) = fileparse($0);
# $DIRS may be ./, which doesn't play well with absolute pathnames.
my $dir_sep = File::Spec->catfile('','');
if ($DIRS =~ m/^\.$dir_sep$/) {
    $DIRS = '';
}
our $SCRIPT_NAME = $FILENAME . $SUFFIX;

# Autoflush stdout
BEGIN { $| = 1 }

#######################
# constants
our $WORD = q/word/;
our $ANAGRAM = q/anagram/;

#######################
# options and defaults

our $REGEX_OPT = '-r';
our $REGEX_NEGATE_OPT = '-R';
our $REGEX_CMD = '';
our $REGEX_DEFAULT = '';
our $REGEX = $REGEX_DEFAULT;

our $CODE_OPT = '-c';
our $CODE_DEFAULT = ''; # Matches all inputs
our $CODE = $CODE_DEFAULT;

# Filter words going into hashes
our $FILTER_OPT = '-f';
our $FILTER_NEGATE_OPT = '-F';
our $FILTER_CMD = '-f';
our $FILTER_DEFAULT_STRING = 'm/^[a-z]+$/';
our $FILTER_DEFAULT = '^[a-z]+$';
our $FILTER = $FILTER_DEFAULT;

# Cache file
our $CACHE_REWRITE_OPT = '-cr';
our $CACHE_REWRITE_DEFAULT = 0;
our $CACHE_REWRITE = $CACHE_REWRITE_DEFAULT;

our $CACHE_FILENAME_OPT = '-cf';
our $CACHE_SUFFIX = '.cache';
our $CACHE_FILENAME_DEFAULT = File::Spec->catfile($ENV{HOME}, "junk", "${SCRIPT_NAME}${CACHE_SUFFIX}");
our $CACHE_FILENAME = $CACHE_FILENAME_DEFAULT;

############################

sub usage {
    print STDERR "$SCRIPT_NAME\n";
    print STDERR "\n";
    print STDERR "Description:\n";
    print STDERR "\tRead in one or more wordlist files, and find matches based on a regex or code block.\n";
    print STDERR "\n";
    print STDERR "\tEither a regex or codeblock must be supplied.\n";
    print STDERR "\t(To use both, put the regex in the codeblock.)\n";
    print STDERR "\n";
    print STDERR "Usage:\n";
    print STDERR "\t$SCRIPT_NAME [[$REGEX_OPT|$REGEX_NEGATE_OPT] regex | $CODE_OPT codeblock] [[$FILTER_OPT|$FILTER_NEGATE_OPT] filter] [files...]\n";
    print STDERR "Where:\n";
    print STDERR "\t[$REGEX_OPT|$REGEX_NEGATE_OPT] regex : regex to match/reject against words (default: skip regex evaluation)\n";
    print STDERR "\t[$FILTER_OPT|$FILTER_NEGATE_OPT] regex : regex to match/reject words to store (default $FILTER_DEFAULT_STRING)\n";
    print STDERR "\t\t(Filtering the input may speed up matching later, or make the final regex or codeblock easier to specify.)\n";
    print STDERR "\t$CODE_OPT codeblock : a string to be 'eval'ed as the body of a sub, returning a string to be printed.\n";
    print STDERR "\t[files...]   : one or more wordlist files, with a single word on each line.\n";
    print STDERR "\t               May also read from a pipe.\n";
    print STDERR "\t               Files are ignored if they are older than the cache file.\n";
    print STDERR "\t$CACHE_REWRITE_OPT : Force the cache to be rewritten from the input files/pipe.\n";
    print STDERR "\t    Rewrite/update to the cache file is very slow. Subsequent access is much quicker.\n";
    print STDERR "\t    (If there is no input, the cache file will be preserved, and a warning generated.)\n";
    print STDERR "\t$CACHE_FILENAME_OPT : Filename of the cache to use between runs (default: $CACHE_FILENAME_DEFAULT)\n";
    print STDERR "\n";
    print STDERR "Regexes:\n";
    print STDERR "\tMost simple regexes can be specified with literal strings.\n";
    print STDERR "\tSome complex regexes will need to be defined as code.\n";
    print STDERR "\n";
    print STDERR "Code blocks:\n";
    print STDERR "\tIf the code block returns a true value, the word will be emitted. Otherwise, not.\n";
    print STDERR "\tA sub will be created with codeblock as the body.\n";
    print STDERR "\tCode blocks should pull the candidate word from \@_ in the usual Perl way.\n";
    print STDERR "\tThe word hash is \%word, with input words as keys, case-sensitive, and normalized anagrams as values, lowercase.\n";
    print STDERR "\tThe anagram hash is \%anagram, with normalized anagrams as keys, lower case, and hash of input words as keys in a subhash.\n";
    print STDERR "\tExample: 'length(shift) == 8' matches all 8 character words.\n";
    print STDERR "\tExample: '\$_[0] eq reverse \$_[0]' finds palindromes.\n";
    print STDERR "\tExample: 'keys \%{\$anagram{\$word{\$_[0]}}}' gives a list of all anagrams of \$_[0].\n";
    print STDERR "\tMore complex statements are allowed.\n";
    print STDERR "\n";

    exit;
}

######################
# process command line

usage unless @ARGV;
my @TEMP_ARGV;

while (@ARGV) {
    if ($ARGV[0] =~ m/^$REGEX_OPT$/i and defined($ARGV[1])) {
        $REGEX_CMD = shift;
        $REGEX = shift;
        next;
    }

    if ($ARGV[0] =~ m/^$FILTER_OPT$/i and defined($ARGV[1])) {
        $FILTER_CMD = shift;
        $FILTER = shift;
        next;
    }

    if ($ARGV[0] eq $CODE_OPT and defined($ARGV[1])) {
        $CODE = $ARGV[1];
        shift;shift;
        next;
    }

    if ($ARGV[0] eq $CACHE_REWRITE_OPT) {
        $CACHE_REWRITE = 1 - $CACHE_REWRITE;
        shift;
        next;
    }

    if ($ARGV[0] eq $CACHE_FILENAME_OPT and defined($ARGV[1])) {
        $CACHE_FILENAME = $ARGV[1];
        shift;shift;
        next;
    }

    push @TEMP_ARGV, shift;
}

usage if $REGEX and $CODE;

@ARGV = @TEMP_ARGV;

###########################
# create regex and anonymous sub (code block)
our $regex;
if ($REGEX) {
    $regex = qr/$REGEX/;
}

our $filter;
if ($FILTER) {
    $filter = qr/$FILTER/;
}

our $code;
if ($CODE) {
    $code = eval ('sub {' . $CODE . '}');
    die $@ if $@;
}

###########################
# cache file
my $cache;
my $cache_later;

###########################
# read in word list
if (@ARGV) {
    print STDERR "Reading input files...\n";
    print STDERR "\t$ARGV[0]\n";
}

my $check_cache = 1;
my $key_count = 0;
while (<>) {
    if ($check_cache) {
        $check_cache = 0;
        if ((not -t)
         or ($CACHE_REWRITE and @ARGV)
         or (file_older_than($CACHE_FILENAME, @ARGV))) {
            if (-t) {
                $cache_later = cache_file_reset($CACHE_FILENAME);
                print STDERR "Cache file will not be written until the end of processing\n";
            } else {
                print STDERR "Reading from STDIN -- cache will not be saved\n";
            }
        } else {
            print STDERR "Skipping input, using word list from cache file $CACHE_FILENAME\n";
            $cache = cache_file_get($CACHE_FILENAME);
            last;
        }
    }

    chomp;
    tr/_/ /; # some lists use underlines for spaces in compound words.
    if ($FILTER) {
        if ($FILTER_CMD eq $FILTER_OPT) {
            next if ($_ !~ $filter);
        } else {
            next if ($_ =~ $filter);
        }
    }

    # Create a dictionary entry, with the value as the normalized anagram, lowercased (only alpha)
    $cache->{$WORD}{$_} = sorted_anagram($_);

    # Create a reverse lookup by anagram, with values in original case.
    $cache->{$ANAGRAM}{$cache->{$WORD}{$_}}{$_} = 1;

    ++$key_count;
    if (not ($key_count % 1e5)) {
        printf STDERR "\t\t(%d) %s\n", $key_count, $_;
    }
} continue {
    if (eof) { # not eof()!
        close ARGV;
        if (@ARGV) {
            print STDERR "\t$ARGV[0]\n";
        }
    }
}

our %word = %{$cache->{$WORD}};
our %anagram = %{$cache->{$ANAGRAM}};

###########################
# search word list
for my $w (sort keys %word) {
    if ($REGEX) {
        if (($REGEX_CMD eq $REGEX_OPT) and ($w =~ $regex)
         or ($REGEX_CMD eq $REGEX_NEGATE_OPT) and ($w !~ $regex)) {
            print "$w\n";
        }
    } elsif ($CODE) {
        # This could be reworked to print the return value instead.
        # E.g., printing anagram families together
        my $code_result = $code->($w);
        if ($code_result) {
            print "$w\n";
        }
    }
}

# If the cache file needs rewriting, do it here.
if ($cache_later) {
    print STDERR "Saving cache file $CACHE_FILENAME...";
    %{$cache_later} = %{$cache};
    print STDERR "Done!\n";
}
exit;

############################
# Sorted anagram, lowercased, alpha only
sub sorted_anagram {
    return join('', sort map lc, $_[0] =~ m/([a-z])/gi);
}

############################
# All letters in non-decreasing order (lexicographic)
sub increasing_order {
    my $candidate = shift; # word to test

    # make a copy for munging
    my $cand = $candidate;

    # only keep alpha
    $cand = join('', map lc, ($cand =~ m/([A-Za-z])/g));
    # make anagram in sorted order
    my $anagram = join('', sort split '', $cand);
    if ($cand eq $anagram) {
        return $candidate;
    }
}

############################
# All letters in non-increasing order (lexicographic)
sub decreasing_order {
    my $candidate = shift; # word to test

    # make a copy for munging
    my $cand = $candidate;
    # only keep alpha
    $cand = join('', map lc, ($cand =~ m/([A-Za-z])/g));
    # make anagram in sorted order
    my $anagram = join('', reverse sort split '', $cand);
    if ($cand eq $anagram) {
        return $candidate;
    }
}

############################
# Front and rear halves of a word use the same letters, but is not a reduplicative.
# A reduplicative is like "bongobongo" or "pingping".
# ("riffraff" and "pingpong" are also considered reduplicatives, but would not match anyway.)
# Note that palindromes will also be found, though not as interesting as, say, "horseshoer".
sub front_rear {
    my $candidate = shift; # word to test
    my $min = (shift // 10); # minimum word length, including punctuation, if present

    return '' unless length($candidate) >= $min;
    my $q = int(length($candidate)/2);
    return '' if $candidate =~ m/^(.{$q})\1.?$/;
    my ($l, $r) = $candidate =~ m/^(.{$q}).?(.{$q})$/;
    return '' if $l eq $r;
    my $result = join("", (sort split "", lc $l)) eq join("", (sort split "", lc $r));
    return $result;
}

###############################
# Cache file utilties
###############################
sub cache_file_reset {
    my $cache_path = shift;
    # The file doesn't get smaller when clearing, so delete it explicitly first
    unlink $cache_path or die "Could not delete cache file $cache_path, aborting...\n";
    # create the cache file
    my $cache = cache_file_get($cache_path);
    # create the sub-hashes
    $cache->{$WORD} = {};
    $cache->{$ANAGRAM} = {};
    return $cache;
}

###############################
# Connect a Perl data structure to a disk file.
# If the file does not exist, it is created.
# If it already exists, it is unchanged.
sub cache_file_get {
    my $cache_path = shift;
    my $cache = DBM::Deep->new(
        file             => $cache_path,
        max_buckets      => 256,
        data_sector_size => 32,
    );
    return $cache;
}

###############################
# Compare cache file last modified time to @ARGV files
# Return true if any input files are newer than the reference file
sub file_older_than {
    my $ref_file = shift;
    my @files = @_;

    my $ref_age = -M $ref_file;
    for my $in (@files) {
        if (-M $in < $ref_age) {
            return 1;
        }
    }
    return 0;
}
