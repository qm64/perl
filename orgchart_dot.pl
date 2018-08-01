#!/usr/bin/env perl

# Convert a CSV of employee/manager records into a "dot" file.

# Fields:
# 0) Resource/Role (aka, name; surname first, doublequoted field
# 1) "Resource Allocation"
# 2) Resource/Role ID (aka, employee number)
# 3) Primary Role (Role, mostly "Fixed Price Resource")
# 4) Resource Manager (manager name, surname first, doublequoted field)
# 5) Employment Type (employee, contractor, 3rd party)
# 6) Resource Type (Labor == person)

use strict;
use warnings;

# Parse command line
my $HELP_OPT = q/-h/;
my $MATCH_OPT = q/-m/;
my $MATCH_DEFAULT = qr/.*/i;
my $MATCH = $MATCH_DEFAULT;

### process cmd line
my @temp_args;

while (@ARGV)
{
    if ($ARGV[0] =~ /^$HELP_OPT/)
    {
        usage();
    }
    if ($ARGV[0] =~ /^$MATCH_OPT$/)
    {
        shift;
        if (exists $ARGV[0])
        {
            $MATCH = shift;
            next;
        }
        else
        {
            warn "Error: option $MATCH_OPT requires an argument\n";
            usage();
        }
    }
    push @temp_args, shift;
}

@ARGV = @temp_args;

#########################
sub usage
{
    use File::Basename;
    my $filename = fileparse($0);

    warn "Description: $filename creates an org chart in 'dot' format from a CSV file.\n\n";
    warn "Usage: $filename [$MATCH_OPT regex] input_files...\n\n";
    warn "Options:\n";
    warn "    $MATCH_OPT name    A regex or string used to limit output to matching nodes, any immediate subordinates, but all superiors (default: /$MATCH_DEFAULT/)\n";
    warn "    $HELP_OPT          usage (this output)\n";
    die "\n";
}
######################

use Text::CSV::Encoded;
my $CSV = Text::CSV::Encoded->new ({ encoding  => "utf8",
                                     eol => $/, # EOL for current OS
                                     auto_diag => 1, # error message prints to STDERR
                                     diag_verbose => 1, # adds input record number and column number to error message
                                  });

my $EMP_NUM    = q/EMP_NUM/;
my $EMP_ROLE   = q/EMP_ROLE/;
my $MGR        = q/MGR/;
my $EMP_TYPE   = q/EMP_TYPE/;
my $RES_TYPE   = q/RES_TYPE/;
my $EMP_STRING = q/EMP_STRING/;
my $MGR_STRING = q/MGR_STRING/;

# modify chart label for match
my $CHART_LABEL = q/Clarity Org Chart/;
if ($MATCH ne $MATCH_DEFAULT) {
    $CHART_LABEL = '"' . $CHART_LABEL . '\n' . "(based on matching '$MATCH')" . '"';
}

# All graphs start like this
my $PREAMBLE = <<"PREAMBLE";
digraph  {
	graph [compound=True,
		label=$CHART_LABEL,
		rankdir=BT,
		ratio=0.3
	];
	node [color=black,
		fillcolor=white,
		height=1.2,
		shape=circle,
		style=filled
	];
	edge [color=black];
PREAMBLE

my $INDENT = " " x 4;
my $SEP = " -> ";
my $REC_TERM = ";";
my $GRAPH_TERM = "}";
my $EDGE_FORMAT = qq/%s"%s"%s"%s"%s\n/;

my $preamble_printed = 0;
my %emps;
my %mgrs;

while (<>) {
    chomp;

    if ($CSV->parse( $_ )) {
        # Fields:
        # 0) Resource/Role (aka, name; surname first, doublequoted field
        # 1) "Resource Allocation"
        # 2) Resource/Role ID (aka, employee number)
        # 3) Primary Role (Role, mostly "Fixed Price Resource")
        # 4) Resource Manager (manager name, surname first, doublequoted field)
        # 5) Employment Type (employee, contractor, 3rd party)
        # 6) Resource Type (Labor == person)
        my ($emp, undef, $emp_num, $emp_role, $mgr, $emp_type, $res_type) = $CSV->fields();
        if ($res_type =~ m/labor/i) {
            if (not $preamble_printed) {
                $preamble_printed = 1;
                print $PREAMBLE;
            }
            # remove leading/trailing whitespace
            for my $i ($emp, $emp_num, $mgr) {
                $i =~ s/^\s+|\s+$//g;
            }
            # check for an employee number
            if ($emp_num !~ m/^\d+$/) {
                #print STDERR "No employee  number, line $.: $_\n";
                next;
            }
            # check for empty employee string
            unless (length($emp))  {
                print STDERR "Employee string empty, line $.: $_\n";
                next;
            }
            # Create employee entree, with newlines and employee number
            my $emp_string  = join('\\n', split(/\s*,\s/, $emp), $emp_num);
            # Check for empty manager string
            unless (length($mgr))  {
                #print STDERR "Manager string empty, line $.: $_\n";
                next;
            }
            # store by manager by employee name
            $emps{$emp}{$EMP_NUM} = $emp_num;
            $emps{$emp}{$EMP_ROLE} = $emp_role;
            $emps{$emp}{$MGR} = $mgr;
            $emps{$emp}{$EMP_TYPE} = $emp_type;
            $emps{$emp}{$RES_TYPE} = $res_type;
            $emps{$emp}{$EMP_STRING} = $emp_string;
            push @{$mgrs{$mgr}}, $emp;
        }
    } else {
        print STDERR "Line $. could not be parsed\n";
    }
}

# Find the $emp_string of each manager, to construct the edge output
for my $emp (keys %emps) {
    # if the manager is not an employee (with number), create a separate entry
    if (not exists($emps{$emps{$emp}{$MGR}})) {
        $emps{$emps{$emp}{$MGR}}{$EMP_STRING} = join('\\n', split(/\s*,\s/, $emps{$emp}{$MGR}));
    }
    $emps{$emp}{$MGR_STRING} = $emps{$emps{$emp}{$MGR}}{$EMP_STRING};
}

# Reduce data if needed
my %match;
if ($MATCH ne $MATCH_DEFAULT) {
    # find all matching nodes
    my %emp_matches;
    for my $emp (keys %emps) {
        next if exists($emp_matches{$emp});
        my $match = 0;
        # note the (almost magical) hash slice from a hash ref, @{ $hash{$key} }{$k1, $k2, ...}
        for my $val ($emp, @{$emps{$emp}}{$EMP_NUM, $EMP_ROLE, $MGR, $EMP_TYPE}) {
            if (defined($val) and $val =~ m/$MATCH/) {
                print STDERR "Matched $val for $emp\n";
                $emp_matches{$emp} = 1;
                last;
            }
        }
    }

    # Find all managers to the top, and "reports to" down one level
    for my $emp (keys %emp_matches) {
        my $sup = $emp;
        $match{$sup} = $emps{$sup};
        while (exists($emps{$sup}{$MGR})
           and defined($emps{$sup}{$MGR})) {
            $sup = $emps{$sup}{$MGR};
            $match{$sup} = $emps{$sup};
        }
    }

    # "reports to" of any matches and their managers, 1 level down
    my @matches = keys %match;
    for my $mgr (@matches) {
        if (exists($mgrs{$mgr})) {
            for my $rep (@{$mgrs{$mgr}}) {
                $match{$rep} = $emps{$rep};
            }
        }
    }
} else {
    %match = %emps;
}

 # output
my $count = 0;
for my $emp (sort emp_by_mgr keys %match) {
    # Some employees don't have managers, and no edge is output
    if (exists($match{$emp}{$MGR_STRING})
    and defined($match{$emp}{$MGR_STRING})) {
        printf $EDGE_FORMAT, $INDENT, $match{$emp}{$EMP_STRING}, $SEP, $match{$emp}{$MGR_STRING}, $REC_TERM;
        $count++;
    }
}

print "$GRAPH_TERM\n";
print STDERR "Total edges in graph: $count\n";

exit;

sub emp_by_mgr {
    if (exists($match{$a}{$MGR}) and defined($match{$a}{$MGR})
            and
        exists($match{$b}{$MGR}) and defined($match{$b}{$MGR})) {
        return(
            ($match{$a}{$MGR} cmp $match{$b}{$MGR})
                or
            ($a cmp $b));
    } elsif (exists($match{$a}{$MGR})) {
        return 1;
    } elsif (exists($match{$b}{$MGR})) {
        return -1;
    } else {
        return 0;
    }
}
