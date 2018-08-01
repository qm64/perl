#!/usr/bin/env perl

use strict;
use warnings;

# Remove duplicates from a path (or other string), preserving order.
# That is, early elements will always be retained, later duplicates will be dropped.
#
# Example: '/usr/bin:/home/blah:/usr/bin' => '/usr/bin:/home/blah'
#
# Reads from command line and stdin (pipe only)

my $SEPARATOR_DEFAULT = ':';
my $separator = $SEPARATOR_DEFAULT;
my $SEPARATOR_OPT = q/-s/;
my $HELP_OPT = q/-h(?:elp)?/;

sub usage
{
    my @message = @_;

    warn for @message;

    warn "Usage:\n\n";
    warn "\t$0 [$SEPARATOR_OPT sep] string...\n\n";
    warn "Description: remove duplicate elements from a path or other string, preserving order.\n\n";
    warn "Options:\n\n";
    printf STDERR "\t%-10s    use separator sep (default '$separator'). sep can be multiple characters\n", "$SEPARATOR_OPT sep";
    printf STDERR "\t%-10s    path or other string to remove duplicates from\n\n", "string...";
    warn "Notes:\n\n";
    warn "\tReads from command line, and pipe (STDIN)\n";
    warn "\tZero length elements will be removed\n";
    die "\n";
}

my @temp_args;

while (@ARGV)
{
    if ($ARGV[0] eq $SEPARATOR_OPT)
    {
        shift @ARGV;
        if (@ARGV)
        {
            $separator = shift(@ARGV);
            next;
        }
        else
        {
            usage "Error: Separator option ($SEPARATOR_OPT) requires argument\n";
        }
    }

    if ($ARGV[0] =~ /^$HELP_OPT$/)
    {
        usage();
    }

    push @temp_args, shift @ARGV;
}

@ARGV = @temp_args;

while (@ARGV)
{
    my $s = shift(@ARGV);
    uniquify($s);
}

if (not -t STDIN)
{
    while (my $s = <>)
    {
        uniquify($s);
    }
}

sub uniquify
{
    my $s = shift;
    chomp($s);
    my $i=0;
    my %elements;
    for my $elem (split(/$separator/,$s))
    {
        next unless length($elem);
        unless (exists($elements{$elem}))
        {
            $elements{$elem} = $i++;
        }
    }

    my $numeric_value = make_hash_value_numeric_sort( \%elements );
    printf "%s\n", join($separator, sort $numeric_value keys %elements);
} # uniquify

sub make_hash_value_numeric_sort
{
    my $hash_ref = shift;

    return sub
    {
        $hash_ref->{$a} <=> $hash_ref->{$b};
    };
}
exit;



