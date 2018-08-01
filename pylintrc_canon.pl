#!/usr/bin/env perl

# Read in a pylintrc config file.
# Output the file in a standard order:
#   Sorted lexicographically by section name
#   Sorted within sections by attribute name
#
# Assumptions:
#    1) Section names are in [brackets]
#    2) Attribute names and values are on single lines.
#    3) Comments for sections or attributes are not separated from their target by blank lines.
#    4) Blank lines separate all elements (sections or attributes)
#    5) Commented attributes will be captured as if it were uncommented (and sorted accordingly),
#           but will still be commented in the output. (So lines that look like commented
#           attributes, but aren't, may cause unexpected results.)
#    6) A group of commented lines (aka, orphan comments), not associated directly with
#           a section or attribute, will be retained as a separate element. For sorting
#           purposes, they are stored according to a sequence number, and will be sorted
#           before any other elements in that section. Order between orphan comment groups
#           will be retained.

use strict;
use warnings;

use File::Basename;

##############################

sub usage {
    my($filename, $dirs, $suffix) = fileparse($0);
    my $script_name = $filename . $suffix;

    print STDERR "\n";
    print STDERR "Pylintrc canonicalizer: Given a pylintrc file, output the sorted sections and attributes.\n";
    print STDERR "If multiple input files are given, merge the attribute values, keeping last.\n";

    print STDERR "Usage:\n";
    print STDERR "\t$script_name file[...]\n";
    print STDERR "Where:\n";
    print STDERR "\tfile : input file(s) to canonicalise\n";
    exit;
}

######################
# No need to process command line.
# Just check if there are filename arguments, or a pipe
usage unless (@ARGV or not -t STDIN);

#####################################
# common strings and regexes
our $BLANK_LINE_MATCH = qr/^\s*$/;
our $SECTION_MATCH = qr/^(\[[^\]]+\])\s*$/;
our $ATTRIB_MATCH = qr/^(\w[\w\-]*)\s*=\s*(.*)$/;
our $ATTRIB_COMMENT_MATCH = qr/^#+(\w[\w\-]*)\s*=\s*(.*)$/;
our $ATTRIB_LIST_MATCH = qr/(\w[\w\-]*(?:\s*,\s*[\w\-]+)+)$/;
our $COMMENT_MATCH = qr/^(#.*)$/;

# In case any attributes or comments occur before the first section name
our $NULL_SECTION = "";

our $BLANK_LINE = "\n";

#####################################
# print groups of lines
sub print_element {
    my $elref = shift;
    for my $line (@{$elref}) {
        print $line, "\n";
    }
    print $BLANK_LINE;
}

#####################################
# replacement sort sub: give it a code block or sort sub, and sort by values, returning keys
# Usage:
#   my @sorted_keys = sort_by_value {$a <=> $b} %hash;
#   my @sorted_keys = sort_by_value {numerically} %hash;
sub sort_by_value (&\%) {
    my ($sub, $hash) = @_;
    sort {
        local($a, $b) = @$hash{$a, $b};
        $sub->()
    } keys %$hash
}

#####################################
# output sections in order canonically
#
# Attributes are overwritten -- a duplicate attribute in a later file overrides an earlier value.
# Attributes are allowed to have null values (e.g., "attribute=")
# Comments that look like attributes, will be sorted as attributes.

my %sections;
my %attrib;
my %section_order;
my $section_number = 0;
my $section = $NULL_SECTION;
my @comments_queued = ();
my $orphan_comment_number = 0;

while (<>) {
    chomp;
    if (m/$SECTION_MATCH/) {
        $section = $1;
        # Keep original section number, if found
        $section_order{$section} //= ++$section_number;
        $sections{$section} = [@comments_queued, $section];
        @comments_queued = ();
        next;
    }

    if (m/$ATTRIB_MATCH/) {
        my $attrib_name = $1;
        my $attrib_string = $_;
        if (m/$ATTRIB_LIST_MATCH/) {
            my $attrib_list = $1;
            my @attribs = sort split '\s*,\s*', $attrib_list;
            $attrib_string = sprintf "%s=%s", $attrib_name, join(',', @attribs);
        }
        $attrib{$section}{$attrib_name} = [@comments_queued, $attrib_string];
        @comments_queued = ();
        next;
    }

    if (m/$ATTRIB_COMMENT_MATCH/) {
        my $attrib_name = $1;
        my $attrib_string = $_;
        if (m/$ATTRIB_LIST_MATCH/) {
            my $attrib_list = $1;
            my @attribs = sort split '\s*,\s*', $attrib_list;
            $attrib_string = sprintf "#%s=%s", $attrib_name, join(',', @attribs);
        }
        $attrib{$section}{$attrib_name} = [@comments_queued, $attrib_string];
        @comments_queued = ();
        next;
    }

    if (m/$COMMENT_MATCH/) {
        push @comments_queued, $1;
        next;
    }

    if (m/$BLANK_LINE_MATCH/) {
        # Check for orphan comments
        # These probably shouldn't occur, but are kept in order relative to other orphan comments
        #    in the same section.
        if (@comments_queued) {
            my $attrib = ++$orphan_comment_number;
            $attrib{$section}{$attrib} = [@comments_queued];
            @comments_queued = ();
        }
        next;
    }

    die "ERROR: unknown line type at file $ARGV, line $.\n";
}

for my $s (sort keys %sections) {
    print_element($sections{$s});
    for my $at (sort keys %{$attrib{$s}}) {
        print_element($attrib{$s}{$at});
    }
}


exit;
