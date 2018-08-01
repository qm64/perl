#!/usr/bin/env perl
#
# Move the source file/dir to a similar path for offline backup/archiving (e.g., Dropbox),
# and create a softlink from the source's parent to the new location.
# Source defaults to the current dir.
# (Determine if the source is a dir or file.)
# Create a bash source file in the new location to recreate the softlink.
# (useful after a restore)

use strict;
use warnings;

use File::Basename;
use Cwd(abs_path);
use File::Spec(qw(catfile));
# Get the local path separator
our $PATH_SEP = catfile('', '');

######################
# common strings and regexes
our $SOURCE_DEF = '.';
our $SOURCE_OPT = '-s';
our $SOURCE = $SOURCE_DEF;
our $TARGET_DEF = '~/Dropbox';
our $TARGET_OPT = '-t';
our $TARGET = $TARGET_DEF;


##############################

sub usage {
    my $script_name = leaf_name($0)

    print STDERR "\n",
                 "$script_name\n",
                 "\n",
                 "Description:\n",
                 "    Move the source file/dir to target root dir (e.g., ~/Dropbox). ",
                 "Create a softlink from the source to the target. ",
                 "Create a bash script in the target to help recreate the links ",
                 "after a restore. (Existing scripts will be appended to, in case of single files.)\n",
                 "\n",
                 "\n",
                 "Usage:\n",
                 "        $script_name [$SOURCE_OPT source] [$TARGET_OPT target_root]\n",
                 "\n",
                 "Where:\n",
                 "    $SOURCE_OPT source         is the source file/dir to move/link from (default, \'${SOURCE_DEF}\').\n",
                 "    $TARGET_OPT target_root    is the target (parent) dir to move/link to (default, \'${TARGET_DEF}\').\n",
                 "\n",
                 "Examples:\n",
                 "    # move the current dir to the default target\n",
                 "    $script_name\n",
                 "\n",
                 "    # move the file foo.txt to the default target\n",
                 "    $script_name $SOURCE_OPT foo.txt\n",
                 "\n",
                 "    # move the dir 'pickles' to the target root ~/Jar\n",
                 "    $script_name $SOURCE_OPT pickles $TARGET_OPT ~/Jar\n";
    exit;
}

######################
# Process command line

while (@ARGV)
{
    if ($ARGV[0] eq $SOURCE_OPT)
    {
        shift @ARGV;
        if (@ARGV)
        {
            $SOURCE = shift(@ARGV);
            next;
        }
        else
        {
            usage;
        }
    }

    if ($ARGV[0] eq $TARGET_OPT)
    {
        shift @ARGV;
        if (@ARGV)
        {
            $TARGET = shift(@ARGV);
            next;
        }
        else
        {
            usage;
        }
    }

    # If there are any unknown arguments, go to usage.
    # As the script can run without arguments, usage is only triggered with unknowns.
    usage();
}

# Get absolute pathnames, as the current directory will probably be moved.
# This makes use of magic aliasing in for loops.
for my $path ($SOURCE, $TARGET) {
    $path = abs($path);
}

#####################################
# Check source and target
our $source_is_dir;
our $source_is_file;

if (-e $SOURCE) {
    if (-d $SOURCE or -f $SOURCE) {
        $source_is_dir = -d $SOURCE;
        $source_is_file = -f $SOURCE;
    } else {
        die "Source ($SOURCE) is not a plain file or directory\n";
    }
} else {
    die "Source ($SOURCE) does not exist\n";
}

if (-e $TARGET) {
    if (not -d $TARGET) {
        die "Target ($TARGET) is not a directory\n";
    }
} else {
    die "Target ($TARGET) does not exist\n";
}

####################################

move_path($SOURCE, $TARGET);
make_softlink($SOURCE, $TARGET);
recover_link($SOURCE, $TARGET);

# good place to stop during debug
exit;

# name after the last dir name
sub leaf_name {
    my($filename, $dirs, $suffix) = fileparse($_[0]);
    my $leaf_name = $filename . $suffix;
    return $leaf_name;
}

# Move the dir/file to the target
sub move_path {
    my $source = shift;
    my $target = shift;

    # get the leaf of source, which is either the last dir,
    # or the filename without path

    my ($source_base) = $source =~ m/${PATH_SEP}([^${PATH_SEP}]+)/;

    # get target spec