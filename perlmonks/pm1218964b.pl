#!/usr/bin/perl

use strict;
use warnings;
use feature qw/say/;
#use Algorithm::Combinatorics qw/variations/;
use Algorithm::Permute;

$| = 1;

sub p {
	my $s = '';
	for (@_) {
		$s .= ['0'..'9', 'a'..'z']->[$_]; 
	}
	return $s;
}

sub check {
	use integer;
	my $base = shift;

	say "**** $base ****";
	my $b1 = $base - 1;
	my $b2 = $base / 2;
	my $v = Algorithm::Permute->new([1 .. $b1], $b2);
	my $max = $base ** ($b2 - 1);
	my @range = reverse 0 .. ($b2 - 2);

	my @bailout;
	$bailout[1] = $bailout[$b1] = $bailout[$b2] = 1;

	L:
	while (my @denom = $v->next) {
		my $quot = shift @denom;
		next if $denom[0]*$quot >= $base or $bailout[$quot];

		my @numer;
		my $carry = 0;
		for (@range) {
			$numer[$_] += $carry + $denom[$_] * $quot;
			$carry = $numer[$_] / $base;
			$numer[$_] = $numer[$_] % $base;
		}
		next if $carry;

		my @check;
		++$check[$_] > 1 and next L for 0, @numer, @denom, $quot;
		  $check[$_] < 1 and next L for @numer;
		say p(@numer)." / ".p(@denom)." = ".p($quot); 
	}
	say "";
}

my $maxbase = shift || 14;
check(2*$_) for 3..$maxbase/2;

exit;