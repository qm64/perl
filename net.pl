#!/usr/bin/env perl
# @brief
# Execute arbitrary commands on remote hosts through ssh in parallel,
# and report the results by host.
#
# @details
#
# @b Description
# http://ukbugdb/B-147893
#
# Execute arbitrary commands on remote hosts, using ssh,
# in parallel, and report the results grouped by remote host.
# For each host, a child process is forked, the command executed, and
# results returned to the parent. Results are reported as each host
# completes. To sort output by host, all results must first be collected.
# For sorted output, a ticker option is provided to show that the parent
# is still actively waiting.
# See the built-in help for additional features.
#
# @code
# Process command line arguments.
# Create a Parallel::ForkManager object.
# Register callbacks for child finish and child wait.
# For each host
#     Fork a child process
#     In the child process,
#         Execute the remote command
#         Capture the result
#         Prefix each result line with the hostname
#         Print the result if not sorting
#         Terminate the child, returning a reference to the result.
# @endcode
#
# @b Usage:
# net.pl -h
# See help for complete list of parameters.

use strict;
use warnings;

# Parallel::ForkManager has been inlined at the end of the script, as a fallback.
# To install P::FM on unix: sudo apt-get install libparallel-forkmanager-perl
# (The "use" line below is included to document its use when looking for included
# modules.)
# use Parallel::ForkManager;

# strftime for timestamp output
use POSIX qw(strftime);

### hash keys ###
my $HOST = q/host/;
my $START = q/start/;

### cmd line options
my $CMD_OPT  = q/-c/;
my $USER_OPT = q/-u/;
my $SSH_OPT  = q/-s/;
my $EVAL_OPT = q/-e/;
my $HELP_OPT = q/-h/;
my $TIMEOUT_OPT = q/-timeout/;
my $REDIRECT_OPT = q/-redirect/;
my $SORT_OPT = q/-sort/;
my $UNIQUE_OPT = q/-uniq/;
my $TICK_OPT = q/-tick/;
my $REPEAT_OPT = q/-repeat/;
my $FOREVER = q/forever/;
my $SLEEP_OPT = q/-sleep/;
my $HOST_OPT = q/-host/;
my $MAX_CHILD_OPT = q/-maxchild/;
my $CONNECT_TIMEOUT_OPT = q/-connect_timeout/;

### defaults
my $ssh  = my $ssh_default  = q/ssh/;
my $cmd  = my $cmd_default  = q/hostname/;
my $user = my $user_default = q/murphy/;
my $redirect = my $redirect_default = q/2>&1/;
my $sort_by_host = my $sort_by_host_default = 0;
my $unique_by_host = my $unique_by_host_default = 0;
my $timeout = my $timeout_default = 90;
my $tick = my $tick_default = 1;
my $empty_string = '';
my $repeat_limit = my $repeat_default = 1;
my $sleep = my $sleep_default = 10;
my $host_opt = my $host_default = 1;
my $max_child = my $max_child_default = 100;
my $connect_timeout = my $connect_timeout_default = 5;

##########
usage() unless @ARGV;

### process cmd line
my @temp_args;

while (@ARGV)
{
    if ($ARGV[0] =~ /^$CMD_OPT$/)
    {
        shift;
        if (exists $ARGV[0])
        {
            $cmd = shift;
            next;
        }
        else
        {
            warn "Error: option $CMD_OPT requires an argument\n";
            usage();
        }
    }

    if ($ARGV[0] =~ /^$USER_OPT$/)
    {
        shift;
        if (exists $ARGV[0])
        {
            $user = shift;
            next;
        }
        else
        {
            warn "Error: option $USER_OPT requires an argument\n";
            usage();
        }
    }

    if ($ARGV[0] =~ /^$SSH_OPT$/)
    {
        shift;
        if (exists $ARGV[0])
        {
            $ssh = shift;
            next;
        }
        else
        {
            warn "Error: option $SSH_OPT requires an argument\n";
            usage();
        }
    }

    if ($ARGV[0] =~ /^$TIMEOUT_OPT$/)
    {
        shift;
        if (exists $ARGV[0])
        {
            $timeout = shift;
            next;
        }
        else
        {
            warn "Error: option $TIMEOUT_OPT requires an argument\n";
            usage();
        }
    }

    if ($ARGV[0] =~ /^$REDIRECT_OPT$/)
    {
        shift;
        if (exists $ARGV[0])
        {
            $redirect = shift;
            next;
        }
        else
        {
            warn "Error: option $REDIRECT_OPT requires an argument\n";
            usage();
        }
    }

    if ($ARGV[0] =~ /^$REPEAT_OPT$/)
    {
        shift;
        if (exists $ARGV[0])
        {
            $repeat_limit = shift;
            next;
        }
        else
        {
            warn "Error: option $REPEAT_OPT requires an argument\n";
            usage();
        }
    }

    if ($ARGV[0] =~ /^$SLEEP_OPT$/)
    {
        shift;
        if (exists $ARGV[0])
        {
            $sleep = shift;
            next;
        }
        else
        {
            warn "Error: option $SLEEP_OPT requires an argument\n";
            usage();
        }
    }

    if ($ARGV[0] =~ /^$TICK_OPT$/)
    {
        shift;
        if (exists $ARGV[0])
        {
            $tick = shift;
            next;
        }
        else
        {
            warn "Error: option $TICK_OPT requires an argument\n";
            usage();
        }
    }

    if ($ARGV[0] =~ /^$MAX_CHILD_OPT$/)
    {
        shift;
        if (exists $ARGV[0])
        {
            $max_child = shift;
            next;
        }
        else
        {
            warn "Error: option $MAX_CHILD_OPT requires an argument\n";
            usage();
        }
    }

    if ($ARGV[0] =~ /^$CONNECT_TIMEOUT_OPT$/)
    {
        shift;
        if (exists $ARGV[0])
        {
            $connect_timeout = shift;
            next;
        }
        else
        {
            warn "Error: option $CONNECT_TIMEOUT_OPT requires an argument\n";
            usage();
        }
    }

    if ($ARGV[0] =~ /^$SORT_OPT$/)
    {
        shift;
        $sort_by_host = 1 - $sort_by_host;
        next;
    }

    if ($ARGV[0] =~ /^$HOST_OPT$/)
    {
        shift;
        $host_opt = 1 - $host_opt;
        next;
    }

    if ($ARGV[0] =~ /^$UNIQUE_OPT$/)
    {
        shift;
        $unique_by_host = 1 - $unique_by_host;
        next;
    }

    if ($ARGV[0] =~ /^$EVAL_OPT$/)
    {
        shift;
        if (exists $ARGV[0])
        {
            my $eval_string = shift;
            my @result;
            # eval the string, and remove the empty string (e.g., glob fail)
            @result = grep {length $_} eval "$eval_string";
            die ($@) if $@;
            unless (@result) {
                warn "eval <$eval_string> generated no result, skipping...\n";
            } else {
                print "<", join(', ', @result), ">\n";
                push @ARGV, @result if @result;
            }
            next;
        }
        else
        {
            warn "Error: option $EVAL_OPT requires an argument\n";
            usage();
        }
    }

    if ($ARGV[0] =~ /^$HELP_OPT/)
    {
        usage();
    }

    push @temp_args, shift;
}

@ARGV = @temp_args;

# Determine list of hostnames
my @hosts;
if (@ARGV)
{
    # Anything left in @ARGV is treated as a hostname
    @hosts = @ARGV;
} else {
    warn "No host names given, nothing to do.\n\n";
    usage();
}

# Create new manager, limit number of parallel processes
my $pm = new Parallel::ForkManager($max_child);

if (length($redirect)) {
    $cmd .= ' ' . $redirect;
}

# Show a sample ssh command line, using the first hostname
warn "Command: $ssh $user\@$hosts[0] '$cmd'\n";

# loop is exited in continue block
my $repeat_count = 1;
while (1) {
    my %child; # child pids -> hostname, start time
    my %results; # results returned by hostname

    # Register the callback to get data from the child processes
    # run_on_finish() must be called before the first start().
    $pm->run_on_finish(
        sub {
            my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $message_ref) = @_;
            # Retrieve data structure from child
            # (child is not required to send anything)
            if (defined($message_ref)) {
                $results{$ident} = ${$message_ref};  # string deref
            } else {
                warn "No message received from host $child{$pid}{$HOST}!\n";
            }
        }
    );

    # Register a callback for long waits, when sorting by host
    if ($tick) {
        $pm->run_on_wait(
            sub {
                use feature 'state';
                state $count;
                state $last_time = 0;
                if ((time-$last_time) > (0.9*$tick)) { # don't run it for every child, every time
                    if ($sort_by_host) {
                        print STDERR "Waiting to sort (<${timeout}s)..." unless $count;
                    }
                    printf STDERR "%d ", ++$count;
                    $last_time = time;
                }
            },
            $tick, # time between calls
        );
    }
    my $timestr = strftime "%T", localtime;
    warn "Results ($repeat_count, $timestr):\n";

    for my $host (sort @hosts)
    {
        # $host is used as the child $ident for convenience in run_on_finish()
        if (my $pid = $pm->start($host)) { # forks
            # parent code here
            $child{$pid}{$HOST} = $host;
            $child{$pid}{$START} = time();
            next;
        }
        ### child code here ###
        my @result;
        eval {
            alarm($timeout) if $timeout; # die after elapsed time in child

            # Future enhancement: allow scp, which needs from/to descriptors
            # instead of single remote host. And some way to specify lists
            # of from and to host groups instead of singletons.

            # The result will be updated with intermediate results.
            #   A timeout will preserve whatever we already have.
            @result = qx/$ssh ${user}\@$host '$cmd'/;
            alarm(0);
        };
        # Propagate unexpected errors
        if ($@) {
            die unless $@ eq "alarm\n";
            warn "$host timed out\n";
        }
        # Continue anyway, with whatever we got...
        my $message;
        my $prefix = '';
        if ($host_opt) {
            # Prefix the hostname to each line of the message.
            $prefix = sprintf " %20s)  ", $host;
        }
        for my $r (@result) {
            $message .= "$prefix$r";
        }
        $message .= "\n" if (@result > 1);

        # Only emit unique lines, preserving order
        if ($unique_by_host and defined($message) and length($message)) {
            # split lines, preserving order
            my @message = split "\n", $message;
            # remove duplicates, preserving lowest indexed entries
            my %message;
            for my $index (reverse 0..$#message) {
                $message{$message[$index]} = $index;
            }
            # join into one string, in original index order
            $message = join("\n", sort {$message{$a} <=> $message{$b}} keys %message);
            $message .= "\n";
            if (scalar keys %message > 1) {
                $message = prefix_starline($message);
            }
        }

        if (not $unique_by_host and (@result > 1)) {
            $message = prefix_starline($message);
        }

        if ($sort_by_host) {
            # Exit the child, returning a ref to the data structure
            $pm->finish(0,\$message);
        } else {
            print $message if defined($message);
            # Exit returning empty string (so parent doesn't complain)
            $pm->finish(0,\$empty_string);
        }
    } # for my $host

    $pm->wait_all_children;

    if ($sort_by_host) {
        print STDERR "\n" if $tick; # one newline to clear ticks
        for my $host (sort keys %results) {
            if (exists($results{$host})
            and defined($results{$host})
            and length($results{$host})) {
                print $results{$host};
            }
        }
    }
} continue {
    last unless (($repeat_limit =~ $FOREVER) or ($repeat_count < $repeat_limit));
    warn "Sleeping $sleep...\n";
    sleep $sleep;
    ++$repeat_count;
}

exit;

sub prefix_starline {
    my $string = shift;
    my $new_string = sprintf("%s\n", '*' x 20) . $string;
    return $new_string;
}

## @fn usage()
# Emit the usage statement
sub usage
{
    use File::Basename;
    my $filename = fileparse($0);

    warn "Description: $filename dispatches a single command string to multiple remote hosts through ssh, in parallel, and reports on the results.\n\n";
    warn "Usage: $filename [-s ssh_cmd] [-u user] [-c cmd] [hosts...] [other options...]\n\n";
    warn "Options:\n";
    warn "    $SSH_OPT ssh_cmd                 ssh-type cmd to use (default: $ssh_default)\n";
    warn "    $USER_OPT user                    username for the ssh_cmd (default: $user_default)\n";
    warn "    $CMD_OPT cmd                     remote command string, beware shell quoting (default: $cmd_default)\n";
    warn "    $EVAL_OPT string                  add options to $filename with Perl eval, such as multiple values (ex: $EVAL_OPT 'glob q/camhydmur00{1,3}b{0,1,2,3,4,5,6,7}/'\n";
    warn "    $TIMEOUT_OPT timeout           timeout in seconds before parent reaps children, zero for no timeout (default: $timeout_default)\n";
    warn "    $REDIRECT_OPT redirect         output redirection ($REDIRECT_OPT '' for none, default '$redirect_default')\n";
    warn "    $SORT_OPT                      sort the results by remote hostname, preserving order by host; toggle (default: $sort_by_host_default)\n";
    warn "    $UNIQUE_OPT                      remove duplicate lines within a host's results; toggle (default: $unique_by_host_default)\n";
    warn "    $REPEAT_OPT (count|$FOREVER)    repeat the command every $SLEEP_OPT seconds for count iterations, or $FOREVER (default: $repeat_default)\n";
    warn "    $SLEEP_OPT sleep               when repeating, sleep seconds after command (default: $sleep_default)\n";
    warn "    $TICK_OPT tick                 show activity every tick seconds (default: $tick_default, 0 to cancel)\n";
    warn "    $HOST_OPT                      show the remote hostnames in the output; toggle (default: $host_default)\n";
    warn "    $MAX_CHILD_OPT max_child        limit child processes to max_child (default: $max_child_default, 0 to skip)\n";
    warn "    $CONNECT_TIMEOUT_OPT timeout   ssh connect timeout (default: $connect_timeout_default, 0 to use TCP default)\n";
    warn "    hosts...                   hostnames for the remote shell command\n";
    warn "    $HELP_OPT                         usage (this output)\n";
    warn "\n";
    warn "It is assumed that ssh key exchange has already been setup.\n";
    die "\n";
}

# Emulate "use Parallel::ForkManager;" without aborting, and fallback to inline code.
BEGIN {
    unless( "eval use Parallel::ForkManager" ) {
#    unless ( 0 ) { # test fallback when P::FM is installed
        warn "Couldn't load Parallel::ForkManager, falling back to inline code...\n\n";

        # Taken from P::FM, version 1.05
        package Parallel::ForkManager;
        use POSIX ":sys_wait_h";
        use Storable qw(store retrieve);
        use File::Spec;
        use File::Temp ();
        use File::Path ();
        use strict;
        use vars qw($VERSION);
        $VERSION="1.05";
        $VERSION = eval $VERSION;

        sub new {
          my ($c,$processes,$tempdir)=@_;

          my $h={
            max_proc   => $processes,
            processes  => {},
            in_child   => 0,
            parent_pid => $$,
            auto_cleanup => ($tempdir ? 1 : 0),
          };


          # determine temporary directory for storing data structures
          # add it to Parallel::ForkManager object so children can use it
          # We don't let it clean up so it won't do it in the child process
          # but we have our own DESTROY to do that.
          if (not defined($tempdir) or not length($tempdir)) {
            $tempdir = File::Temp::tempdir(CLEANUP => 0);
          }
          die qq|Temporary directory "$tempdir" doesn\'t exist or is not a directory.| unless (-e $tempdir && -d _);  # ensure temp dir exists and is indeed a directory
          $h->{tempdir} = $tempdir;

          return bless($h,ref($c)||$c);
        };

        sub start {
          my ($s,$identification)=@_;

          die "Cannot start another process while you are in the child process"
            if $s->{in_child};
          while ($s->{max_proc} && ( keys %{ $s->{processes} } ) >= $s->{max_proc}) {
            $s->on_wait;
            $s->wait_one_child(defined $s->{on_wait_period} ? &WNOHANG : undef);
          };
          $s->wait_children;
          if ($s->{max_proc}) {
            my $pid=fork();
            die "Cannot fork: $!" if !defined $pid;
            if ($pid) {
              $s->{processes}->{$pid}=$identification;
              $s->on_start($pid,$identification);
            } else {
              $s->{in_child}=1 if !$pid;
            }
            return $pid;
          } else {
            $s->{processes}->{$$}=$identification;
            $s->on_start($$,$identification);
            return 0; # Simulating the child which returns 0
          }
        }

        sub finish {
          my ($s, $x, $r)=@_;

          if ( $s->{in_child} ) {
            if (defined($r)) {  # store the child's data structure
              my $storable_tempfile = File::Spec->catfile($s->{tempdir}, 'Parallel-ForkManager-' . $s->{parent_pid} . '-' . $$ . '.txt');
              my $stored = eval { return &store($r, $storable_tempfile); };

              # handle Storables errors, IE logcarp or carp returning undef, or die (via logcroak or croak)
              if (not $stored or $@) {
                warn(qq|The storable module was unable to store the child\'s data structure to the temp file "$storable_tempfile":  | . join(', ', $@));
              }
            }
            CORE::exit($x || 0);
          }
          if ($s->{max_proc} == 0) { # max_proc == 0
            $s->on_finish($$, $x ,$s->{processes}->{$$}, 0, 0, $r);
            delete $s->{processes}->{$$};
          }
          return 0;
        }

        sub wait_children {
          my ($s)=@_;

          return if !keys %{$s->{processes}};
          my $kid;
          do {
            $kid = $s->wait_one_child(&WNOHANG);
          } while $kid > 0 || $kid < -1; # AS 5.6/Win32 returns negative PIDs
        };

        {
            # avoid warnings for 'used only once'
            no warnings 'once';
            *wait_childs=*wait_children; # compatibility
        }

        sub wait_one_child {
          my ($s,$par)=@_;

          my $kid;
          while (1) {
            $kid = $s->_waitpid(-1,$par||=0);
            last if $kid == 0 || $kid == -1; # AS 5.6/Win32 returns negative PIDs
            redo if !exists $s->{processes}->{$kid};
            my $id = delete $s->{processes}->{$kid};

            # retrieve child data structure, if any
            my $retrieved = undef;
            my $storable_tempfile = File::Spec->catfile($s->{tempdir}, 'Parallel-ForkManager-' . $$ . '-' . $kid . '.txt');
            if (-e $storable_tempfile) {  # child has option of not storing anything, so we need to see if it did or not
              $retrieved = eval { return &retrieve($storable_tempfile); };

              # handle Storables errors
              if (not $retrieved or $@) {
                warn(qq|The storable module was unable to retrieve the child\'s data structure from the temporary file "$storable_tempfile":  | . join(', ', $@));
              }

              # clean up after ourselves
              unlink $storable_tempfile;
            }

            $s->on_finish( $kid, $? >> 8 , $id, $? & 0x7f, $? & 0x80 ? 1 : 0, $retrieved);
            last;
          }
          $kid;
        };

        sub wait_all_children {
          my ($s)=@_;

          while (keys %{ $s->{processes} }) {
            $s->on_wait;
            $s->wait_one_child(defined $s->{on_wait_period} ? &WNOHANG : undef);
          };
        }

        {
            # avoid warnings for 'used only once'
            no warnings 'once';
            *wait_all_childs=*wait_all_children; # compatibility;
        }

        sub run_on_finish {
          my ($s,$code,$pid)=@_;

          $s->{on_finish}->{$pid || 0}=$code;
        }

        sub on_finish {
          my ($s,$pid,@par)=@_;

          my $code=$s->{on_finish}->{$pid} || $s->{on_finish}->{0} or return 0;
          $code->($pid,@par);
        };

        sub run_on_wait {
          my ($s,$code, $period)=@_;

          $s->{on_wait}=$code;
          $s->{on_wait_period} = $period;
        }

        sub on_wait {
          my ($s)=@_;

          if(ref($s->{on_wait}) eq 'CODE') {
            $s->{on_wait}->();
            if (defined $s->{on_wait_period}) {
                local $SIG{CHLD} = sub { } if ! defined $SIG{CHLD};
                select undef, undef, undef, $s->{on_wait_period}
            };
          };
        };

        sub run_on_start {
          my ($s,$code)=@_;

          $s->{on_start}=$code;
        }

        sub on_start {
          my ($s,@par)=@_;

          $s->{on_start}->(@par) if ref($s->{on_start}) eq 'CODE';
        };

        sub set_max_procs {
          my ($s, $mp)=@_;

          $s->{max_proc} = $mp;
        }

        # OS dependant code follows...

        sub _waitpid { # Call waitpid() in the standard Unix fashion.
          return waitpid($_[1],$_[2]);
        }

        # On ActiveState Perl 5.6/Win32 build 625, waitpid(-1, &WNOHANG) always
        # blocks unless an actual PID other than -1 is given.
        sub _NT_waitpid {
          my ($s, $pid, $par) = @_;

          if ($par == &WNOHANG) { # Need to nonblock on each of our PIDs in the pool.
            my @pids = keys %{ $s->{processes} };
            # Simulate -1 (no processes awaiting cleanup.)
            return -1 unless scalar(@pids);
            # Check each PID in the pool.
            my $kid;
            foreach $pid (@pids) {
              $kid = waitpid($pid, $par);
              return $kid if $kid != 0; # AS 5.6/Win32 returns negative PIDs.
            }
            return $kid;
          } else { # Normal waitpid() call.
            return waitpid($pid, $par);
          }
        }

        {
          local $^W = 0;
          if ($^O eq 'NT' or $^O eq 'MSWin32') {
            *_waitpid = \&_NT_waitpid;
          }
        }

        sub DESTROY {
          my ($self) = @_;

          if ($self->{auto_cleanup} && $self->{parent_pid} == $$ && -d $self->{tempdir}) {
            File::Path::remove_tree($self->{tempdir});
          }
        }
    } # unless
} # BEGIN

