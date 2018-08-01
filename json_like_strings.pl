#!/usr/bin/env perl
# Pull JSON and other strings out of a log file, count occurences, emit frequency table

use JSON qw( decode_json );

my $JSON_MATCH = qr/(?>\{["\[](?:[^{}]*|(?R))*\})/; # "
my $quoted_string_match = qr/(["'])(?:\\?+.)*?\1/; # '"
my $p_or_h = qr/Platform|Hub/;
my $p_or_h_match = qr/${p_or_h} => ${p_or_h}:/; # Platform => Hub:

my $EMPTY_STRING = q//;
my $HASH = q/HASH/;
my $ARRAY = q/ARRAY/;
my $DIR = q/DIR/;
my $ROUTING = q/ROUTING/;

my $freq = {};
my @message;

print STDERR "Reading files:\n";
print STDERR "\t$ARGV[0]\n";
while (<>) {
    if (my ($dir, $json, $routing) = m/($p_or_h_match)?\s*($JSON_MATCH)\s*(\[.*\])?/) {
        my $json = eval{decode_json($json)}
                   or do {
                       my $e = $@;
                       print STDERR "Json decode error on file $ARGV, line $.\n";
                       print STDERR "$e\n";
                       print STDERR "\n";
                   };

        count_elements($json, $freq);

#        $json->{$DIR} = $dir if defined($dir);
#        $json->{$ROUTING} = $dir if defined($routing);
#
#        push @message, $json;
    }

} continue {
    if (eof) { # Not eof()!
        close ARGV;
        print STDERR "\t$ARGV[0]\n";
    }
}


print STDERR "Sorting results\n";

#print "key: count\n";
#for my $k (sort {hash_by_values_numeric_or_string($a, $b, $freq)} keys %{$freq}) {
#    printf "(%s) => %d\n", $k, $freq->{$k};
#}


for my $msg (sort {hashes_by_key_string($a, $b, 'timeStamp')} @message) {
    print "$msg\n";
}


exit;

sub count_elements {
    my $thing = shift;
    my $freq = shift;

    my $reftype = ref($thing);
    if ($reftype eq $HASH) {
        count_elements_hash($thing, $freq);
    } elsif ($reftype eq $ARRAY) {
        count_elements_array($thing, $freq);
    } elsif ($reftype eq $EMPTY_STRING) {
        $freq->{$thing}++;
    } else {
        ++$freq->{"type: $reftype"};
    }
}

sub count_elements_hash {
    my $hash = shift;
    my $freq = shift;

    while (my ($key, $val) = each %{$hash}) {
        count_elements($val, $freq);
        ++$freq->{$key};
    }
}

sub count_elements_array {
    my $array = shift;
    my $freq = shift;

    for my $val (@{$array}) {
        count_elements($val, $freq);
    }
}

sub hash_by_values_numeric_or_string {
    my ($a, $b, $hash) = @_;

    $hash->{$a} <=> $hash->{$b}
        or
    $hash->{$a} cmp $hash->{$b}
}

sub hashes_by_key_string {
    my ($a, $b, $key) = @_;

    $a->{$key} cmp $b->{$key}
}
