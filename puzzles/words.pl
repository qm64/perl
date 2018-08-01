#!/usr/bin/env perl

# Generic word puzzle tool

# Read one or more word list files in.
# Run some code or regex on the list.
# Output the results.

use strict;
use warnings;

use File::Basename;

# Autoflush stdout
BEGIN { $| = 1 }

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

############################

sub usage {
    my($filename, $dirs, $suffix) = fileparse($0);
    my $script_name = $filename . $suffix;

    print STDERR "$script_name\n";
    print STDERR "\n";
    print STDERR "Description:\n";
    print STDERR "\tRead in one or more wordlist files, and find matches based on a regex or code block.\n";
    print STDERR "\n";
    print STDERR "\tEither a regex or codeblock must be supplied.\n";
    print STDERR "\t(To use both, put the regex in the codeblock.)\n";
    print STDERR "\n";
    print STDERR "Usage:\n";
    print STDERR "\t$script_name [[$REGEX_OPT|$REGEX_NEGATE_OPT] regex | $CODE_OPT codeblock] [[$FILTER_OPT|$FILTER_NEGATE_OPT] filter] [files...]\n";
    print STDERR "Where:\n";
    print STDERR "\t[$REGEX_OPT|$REGEX_NEGATE_OPT] regex : regex to match/reject against words (default: skip regex evaluation)\n";
    print STDERR "\t[$FILTER_OPT|$FILTER_NEGATE_OPT] regex : regex to match/reject words to store (default $FILTER_DEFAULT_STRING)\n";
    print STDERR "\t\t(Filtering the input may speed up matching later, or make the final regex or codeblock easier to specify.)\n";
    print STDERR "\t$CODE_OPT codeblock : a string to be 'eval'ed as the body of a sub, returning a string to be printed.\n";
    print STDERR "\tfiles...     : one or more wordlist files, with a single word on each line.\n";
    print STDERR "\t               May also use pipe.\n";
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
    print STDERR "\tThe anagram hash is \%anagram, with normalized anagrams as keys, lower case, and a list of input words as values, case sensitive.\n";
    print STDERR "\tExample: 'length(shift) == 8' matches all 8 character words.\n";
    print STDERR "\tExample: '\$_[0] eq reverse \$_[0]' finds palindromes.\n";
    print STDERR "\tExample: 'length(\$anagram{\$word{\$_[0]}}) > 1' finds words that are anagrams of each other.\n";
    print STDERR "\tExample: '\@anagram{\$word{\$_[0]}}' gives a list of all anagrams of \$_[0].\n";
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
# read in word list
our %word;
our %anagram;

if (@ARGV) {
    print STDERR "Reading input files...\n";
    print STDERR "\t$ARGV[0]\n";
}

while (<>) {
    chomp;
    s/_/ /g; # some lists use underlines for spaces in compound words.
    if ($FILTER) {
        if ($FILTER_CMD eq $FILTER_OPT) {
            next if ($_ !~ $filter);
        } else {
            next if ($_ =~ $filter);
        }
    }

    # Create a dictionary, with the value as the normalized anagram, lowercased
    $word{$_} = join('', (sort split '', lc $_));

    # Create a reverse lookup by anagram, with values in original case.
    push @{$anagram{$word{$_}}}, $_;
} continue {
    if (eof) { # not eof()!
        close ARGV;
        if (@ARGV) {
            print STDERR "\t$ARGV[0]\n";
        }
    }
}


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

exit;

# Front and rear halves of a word use the same letters, but is not a reduplicative.
# A reduplicative is like "bongobongo" or "pingping".
# ("riffraff" and "pingpong" are also considered reduplicatives, but would not match anyway.)
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