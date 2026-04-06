#!/usr/bin/env perl
use strict;
use warnings;
use MCE::Flow;
use POSIX qw(ceil);

# Problem: brainden.com/forum/index.php/topic/16576-dice-problem/
#
# Number $dice $sides-sided dice all the same, find face values giving
# the maximum number of distinct sums, with the lowest highest face value.
# Among all optimal solutions, find the lexicographically smallest face set.
#
# Search strategy:
#   Phase 1 - Initial pass: find any solution at the lowest highest_face.
#             Workers race; we keep the lex-min of whatever comes back.
#   Phase 2 - Refinement: repeatedly search for a strictly lex-smaller
#             solution than the current best. Each pass only examines
#             face[2] values <= best[1], and constrains deeper faces
#             to be lex-smaller. Passes are fast because the bound prunes
#             heavily. Repeat until no improvement found.
#
# The lex bound works as follows: given current best B = [b0,b1,...,bn],
# a new solution S is accepted only if S <_lex B. Passed as $bound through
# the search; when defined, at depth d:
#   v < bound[d] => already lex-smaller, clear constraint ($bound = undef)
#   v == bound[d] => still constrained, keep $bound
#   v > bound[d] => prune (max_val caps this)
# At the final forced face (hf): if $bound still active, hf == bound[-1]
# so we cannot be strictly smaller — return () immediately.
#
# Key design notes:
#   - $highest_face and $bound passed explicitly through chunk data and
#     function parameters; never read as package globals in workers.
#     MCE::Flow reuses worker processes across mce_flow calls, so package
#     globals mutated in the parent are invisible to workers.
#   - new_triples() specialised for $dice==3.

# ----------------------------------------------------------------
# Defaults and options
# ----------------------------------------------------------------
my $sides_default   = 8;
my $dice_default    = 3;
my $workers_default = 8;
my $quiet_default   = 0;

my $sides    = $sides_default;
my $dice     = $dice_default;
my $workers  = $workers_default;
my $quiet    = $quiet_default;
my $goal;
my $highest_face;

my $goal_opt_seen         = 0;
my $highest_face_opt_seen = 0;

sub usage {
    die <<USAGE;
Description:
    $0 finds dice face values maximising distinct sums,
    with the lowest possible highest face value and lexicographically
    smallest face set among all optimal solutions.

    All dice are identical; face values on each die are unique.
    Parallelises the search across face[2] values using MCE.

Usage: $0 [-s sides] [-d dice] [-g goal] [-hf highest_face] [-w workers] [-q] [-h]

Where:
    -s   Number of sides  (default $sides_default)
    -d   Number of dice   (default $dice_default)
    -g   Goal distinct sums (default: C(s+d-1,d), all multisets)
    -hf  Starting highest face; use to resume an interrupted search
         (default: theoretical minimum ceil((goal-1)/dice) + 1)
    -w   Parallel workers  (default $workers_default)
    -q   Quiet: suppress progress output
    -h   This help
USAGE
}

while (@ARGV) {
    my $opt = shift @ARGV;
    if    ($opt eq '-s')  { $sides        = shift @ARGV }
    elsif ($opt eq '-d')  { $dice         = shift @ARGV }
    elsif ($opt eq '-g')  { $goal         = shift @ARGV; $goal_opt_seen = 1 }
    elsif ($opt eq '-hf') { $highest_face = shift @ARGV; $highest_face_opt_seen = 1 }
    elsif ($opt eq '-w')  { $workers      = shift @ARGV }
    elsif ($opt eq '-q')  { $quiet        = 1 }
    elsif ($opt eq '-h')  { usage() }
    else  { warn "Unknown option: $opt\n"; usage() }
}

$goal         = goal_calc($sides, $dice) unless $goal_opt_seen;
$highest_face = ceil(($goal - 1) / $dice) + 1 unless $highest_face_opt_seen;

$| = 1;

unless ($quiet) {
    printf "%s Searching: sides=%d, dice=%d, goal=%d, start highest_face=%d, workers=%d\n",
           time_stamp(), $sides, $dice, $goal, $highest_face, $workers;
}

# ----------------------------------------------------------------
# Trivial case
# ----------------------------------------------------------------
if ($sides == 1) {
    printf "%s faces=(1), distinct sums=1, sums=[%d]\n",
           time_stamp(), $dice;
    exit 0;
}

# ----------------------------------------------------------------
# Phase 1: find initial solution at lowest possible highest_face
# ----------------------------------------------------------------
my $best;

while (!$best) {
    printf "%s Trying highest_face=%d\n", time_stamp(), $highest_face
        unless $quiet;

    my $f2_max = $highest_face - ($sides - 2);
    my @chunks = map { [$_, $highest_face, undef] } (2 .. $f2_max);

    if (@chunks) {
        my @results = run_search(\@chunks);
        if (@results) {
            $best = lex_min(\@results);
            printf "%s Initial solution: faces=(%s)\n",
                   time_stamp(), join(',', @$best)
                unless $quiet;
        }
    }

    $highest_face++ unless $best;
}

# ----------------------------------------------------------------
# Phase 2: refinement — repeatedly search for a strictly lex-smaller
# solution. Each pass is fast due to the lex bound pruning.
# ----------------------------------------------------------------
my $pass = 1;
while (1) {
    # Only examine f2 values <= best[1]:
    #   f2 < best[1]: already lex-smaller, no further constraint ($bound=undef)
    #   f2 == best[1]: still constrained, pass $bound
    #   f2 > best[1]: cannot be lex-smaller, skip entirely
    my @chunks;
    for my $f2 (2 .. $best->[1]) {
        my $bound = ($f2 == $best->[1]) ? $best : undef;
        push @chunks, [$f2, $highest_face, $bound];
    }

    printf "%s Refinement pass %d: best so far=(%s)\n",
           time_stamp(), $pass, join(',', @$best)
        unless $quiet;

    my @results = run_search(\@chunks);

    if (@results) {
        $best = lex_min(\@results);
        printf "%s  -> improved: faces=(%s)\n",
               time_stamp(), join(',', @$best)
            unless $quiet;
        $pass++;
    } else {
        printf "%s  -> no improvement, done\n", time_stamp()
            unless $quiet;
        last;
    }
}

report_solution($best);

# ----------------------------------------------------------------
# run_search(\@chunks)
#
# Dispatch chunks to MCE workers. Each chunk is [$f2, $hf, $bound].
# Workers gather arrayrefs; returns list of all gathered arrayrefs.
# ----------------------------------------------------------------
sub run_search {
    my $chunks = shift;
    return () unless @$chunks;

    return mce_flow {
        max_workers => $workers,
        chunk_size  => 1,
    },
    sub {
        my ($mce, $chunk_ref, $chunk_id) = @_;
        my ($f2, $hf, $bound) = @{ $chunk_ref->[0] };

        my @result = search_from_f2($f2, $hf, $bound);
        if (@result) {
            $mce->gather(\@result);
            $mce->abort();
        }
    }, $chunks;
}

# ----------------------------------------------------------------
# lex_min(\@arrayrefs)
#
# Return the lexicographically smallest arrayref. Faces within each
# arrayref are already in ascending order (built that way by search).
# ----------------------------------------------------------------
sub lex_min {
    my $list = shift;
    my ($best) = sort {
        for my $i (0 .. $#$a) {
            my $cmp = $a->[$i] <=> $b->[$i];
            return $cmp if $cmp;
        }
        return 0;
    } @$list;
    return $best;
}

# ----------------------------------------------------------------
# search_from_f2($f2, $hf, $bound)
#
# Worker entry point. Fresh per-worker state; face 1 pre-seeded.
# $bound: undef = unconstrained; arrayref = must find strictly lex-smaller.
# ----------------------------------------------------------------
sub search_from_f2 {
    my ($f2, $hf, $bound) = @_;

    my @faces     = (1);
    my %sum_count = (3 => 1);   # 1+1+1
    my $distinct  = 1;
    my $collision = 0;

    # Apply lex constraint at face[1] = f2.
    # face[0]=1 always matches bound[0]=1, so constraint enters here.
    if ($bound) {
        return () if $f2 > $bound->[1];          # prune: can't be lex-smaller
        $bound = undef if $f2 < $bound->[1];     # already lex-smaller, relax
        # f2 == $bound->[1]: still constrained, keep $bound
    }

    my @ns = new_triples($f2, \@faces);
    push @faces, $f2;
    apply(\@ns, +1, \%sum_count, \$distinct, \$collision);
    return () if $collision;

    # sides==2 completion: f2 is the last face
    if (scalar @faces == $sides) {
        return () if $bound;   # still constrained = equal to best, not strictly smaller
        return ($distinct == $goal) ? @faces : ();
    }

    return search($f2 + 1, $hf, \@faces, \%sum_count, \$distinct, \$collision, $bound);
}

# ----------------------------------------------------------------
# search($min_val, $hf, \@faces, \%sum_count, \$distinct, \$collision, $bound)
#
# Recursive backtracking with optional lex bound.
# $bound undef: unconstrained.
# $bound defined: at each depth d, only values v <= bound[d] are tried;
#   v < bound[d] clears the constraint for the subtree.
#   At the forced final face (hf): if $bound still active, fail immediately
#   since hf == bound[-1] so we cannot be strictly smaller.
# ----------------------------------------------------------------
sub search {
    my ($min_val, $hf, $faces, $sum_count, $distinct, $collision, $bound) = @_;

    my $depth     = scalar @$faces;
    my $remaining = $sides - $depth - 1;   # slots before the forced final face

    if ($remaining == 0) {
        # Only $hf remains. If still constrained, hf == bound[-1], can't win.
        return () if $bound;
        return try_face($hf, $hf, $faces, $sum_count, $distinct, $collision,
            sub { $$distinct == $goal ? @$faces : () });
    }

    # Cap max_val at bound[$depth] when constrained
    my $max_val = $hf - $remaining - 1;
    $max_val = $bound->[$depth] if $bound && $bound->[$depth] < $max_val;

    for my $v ($min_val .. $max_val) {
        # Determine bound for subtree:
        #   v < bound[$depth]: already lex-smaller, relax constraint
        #   v == bound[$depth]: still constrained
        my $sub_bound = $bound && ($v == $bound->[$depth]) ? $bound : undef;

        my @result = try_face($v, $hf, $faces, $sum_count, $distinct, $collision, sub {
            return () if $$collision;
            return search($v + 1, $hf, $faces, $sum_count, $distinct, $collision, $sub_bound);
        });
        return @result if @result;
    }

    return ();
}

# ----------------------------------------------------------------
# try_face($v, $hf, ..., $body_sub)
#
# Add $v, call $body, remove $v. Guarantees undo on all exit paths.
# ----------------------------------------------------------------
sub try_face {
    my ($v, $hf, $faces, $sum_count, $distinct, $collision, $body) = @_;

    my @ns = new_triples($v, $faces);
    push @$faces, $v;
    apply(\@ns, +1, $sum_count, $distinct, $collision);

    my @result = $body->();

    apply(\@ns, -1, $sum_count, $distinct, $collision);
    pop @$faces;

    return @result;
}

# ----------------------------------------------------------------
# new_triples($v, \@faces)
#
# Triple sums newly introduced by adding $v (before push).
# Specialised for dice==3.
# ----------------------------------------------------------------
sub new_triples {
    my ($v, $faces) = @_;
    my @sums = (3 * $v);

    for my $s (@$faces) {
        push @sums, 2 * $v + $s;
    }

    for my $i (0 .. $#$faces) {
        for my $j ($i .. $#$faces) {
            push @sums, $v + $faces->[$i] + $faces->[$j];
        }
    }

    return @sums;
}

# ----------------------------------------------------------------
# apply(\@sums, $delta, \%sum_count, \$distinct, \$collision)
# ----------------------------------------------------------------
sub apply {
    my ($sums, $delta, $sum_count, $distinct, $collision) = @_;

    for my $s (@$sums) {
        my $old = $sum_count->{$s} // 0;
        my $new = $old + $delta;

        if ($delta == +1) {
            $$distinct++  if $old == 0;
            $$collision++ if $old >= 1;
        } else {
            $$distinct--  if $old == 1;
            $$collision-- if $old >= 2;
        }

        if ($new == 0) { delete $sum_count->{$s} }
        else           { $sum_count->{$s} = $new  }
    }
}

# ----------------------------------------------------------------
# Reporting and utilities
# ----------------------------------------------------------------
sub report_solution {
    my $faces = shift;
    my @sf = sort { $a <=> $b } @$faces;

    my %all;
    for my $i (0 .. $#sf) {
        for my $j ($i .. $#sf) {
            for my $k ($j .. $#sf) {
                $all{ $sf[$i] + $sf[$j] + $sf[$k] } = 1;
            }
        }
    }
    my @sums = sort { $a <=> $b } keys %all;

    printf "%s Solution: faces=(%s), distinct sums=%d\n  sums=[%s]\n",
           time_stamp(),
           join(',', @sf),
           scalar @sums,
           join(', ', @sums);
}

sub goal_calc {
    my ($s, $d) = @_;
    my $g = 1;
    $g = $g * ($s + $_ - 1) / $_ for 1 .. $d;
    return int($g + 0.5);
}

sub time_stamp {
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
    return sprintf "%d %02d%s %02d, %02d:%02d:%02d",
        $year + 1900, $mon + 1, $months[$mon], $mday, $hour, $min, $sec;
}
