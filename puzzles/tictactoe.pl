#!/usr/bin/env perl
# $Id: tictactoe.pl,v 1.1.1.1 2008/10/12 04:05:34 alamos Exp $
# The state is in an array
use strict;
use warnings;

# Variable used in formatting
my $pos;

# Mapping to the opponent
my($opponent) = { x =>'o', o => 'x'};


################################################
#
# Format game position, using an array reference
#
################################################
format POS =
+-----+-----+-----+
|     |     |     |
|  @  |  @  |  @  |
$pos->[0], $pos->[1], $pos->[2]
|     |     |     |
+-----+-----+-----+
|     |     |     |
|  @  |  @  |  @  |
$pos->[3], $pos->[4], $pos->[5]
|     |     |     |
+-----+-----+-----+
|     |     |     |
|  @  |  @  |  @  |
$pos->[6], $pos->[7], $pos->[8]
|     |     |     |
+-----+-----+-----+
.
################################################


sub display_position {
    $pos = $_[0];
    $~ = 'POS';
    write
}

sub test_slice {
    my($player,$pos,$offset,$step)=@_;
    for(my($i) = 0; $i < 3; $i ++) {
	return 0 unless $pos->[$offset] eq $player;
	$offset+=$step;
    }
    return 1;
}

sub game_won {
    my($player,$pos)=@_;
    return
	# Diagonals
	&test_slice($player, $pos, 0, 4) ||
	&test_slice($player, $pos, 2, 2) ||
	# Rows
	&test_slice($player, $pos, 0, 1) ||
	&test_slice($player, $pos, 3, 1) ||
	&test_slice($player, $pos, 6, 1) ||
	# Columns
	&test_slice($player, $pos, 0, 3) ||
	&test_slice($player, $pos, 1, 3) ||
	&test_slice($player, $pos, 2, 3);
}

sub unoccupied_squares {
    my($position)=@_;
    my @squares;
    # Squares in the order of importance
    foreach (4,0,2,6,8,1,3,5,7) {
	if($position->[$_] eq ' ') {
	    push @squares, $_;
	}
    }
    return @squares;
}

sub child_position {
    my($position, $square, $player)=@_;
    my($newpos)=[@$position];
    $newpos->[$square]=$player;
    return $newpos;
}

sub min_max {
    my($game)=@_;
    my($best_move) = undef;
    my(@moves) = &generate_moves($game);
    foreach (@moves) {
	my($new_game) = &apply_move($game,$_);
	unless(defined($new_game->{result})) {
	    my($move) = &min_max($new_game);
	    $_->{value} = -$move->{value};
	}
	if(!defined($best_move) || $_->{value} > $best_move->{value}) {
	    $best_move = $_;
	}
    }
    return $best_move;
}

# Remember:
# Alpha is the guaranteed score for max.
# Beta  is the maximum score max can hope for.
sub alpha_beta {
    my($game,$alpha,$beta)=@_;
    my($best_move) = undef;
    my(@moves) = &generate_moves($game);
    foreach (@moves) {
	my($new_game) = &apply_move($game,$_);
	unless(defined($new_game->{result})) {
	    my($move) = &alpha_beta($new_game, -$beta, -$alpha);
	    $_->{value} = -$move->{value};
	}
	if(!defined($best_move) || $_->{value} > $best_move->{value}) {
	    $best_move = $_;
	    $alpha = $best_move->{value};
	    if($alpha > $beta) {
		last;
	    }
	}
    }
    return $best_move;
}

sub apply_move {
    my($game,$move)=@_;
    my($value);
    my($result) = undef;
    my($new_game)= {
	position => &child_position($game->{position}, $move->{square}, $game->{player}),
	player   => $opponent->{$game->{player}},
	ply      => $game->{ply} + 1
	};
    if(game_won($game->{player}, $new_game->{position})) {
	$move->{value} = 100 - $new_game->{ply} ;
	$new_game->{result} = 'won';
    } else {
	# Number of occupied squares is the value
	my(@blanks) = grep /^ $/, @{$new_game->{position}};
	if($new_game->{ply} == 9) {
	    $new_game->{result}='stalemate';
	}
	$move->{value} = 9 - $new_game->{ply};
    }
    return $new_game;
}

sub generate_moves {
    my($game)=@_;
    my(@squares) = &unoccupied_squares($game->{position});
    $game->{result}='stalemate'   unless(@squares);
    map { &make_move($_) } @squares;
}

sub make_move {
    my($square)=@_;
    return {
	square => $square,
	value => undef
	};
}

sub play {
    my $game= {
	position   =>  [(' ') x 9],
	player     => 'o',
	ply        =>  0
	};
    &display_game($game);
    my @squares = &unoccupied_squares($game->{position});
    &prompt(@squares);
    while(1) {
	last unless defined(my $square=<>);
	chomp($square);
	if(!grep /^$square$/, @squares) {
	    &syntax($square);
	    next;
	}
	print "You chose $square.\n";
	my($move) = &make_move($square);
	$game = &apply_move($game, $move);
	&display_game($game);
	if(defined($game->{result})) {
	    if($game->{result} eq 'won') {
		print "You won! Congratulations.\n";
	    } elsif($game->{result} eq 'stalemate') {
		print "It's a stalemate, mate!\n";
	    }
	    last;
	}
	$move = &alpha_beta($game, -1000, 1000);
	#$move = &min_max($game);
	$game = &apply_move($game, $move);
	&display_game($game);
	if(defined($game->{result})) {
	    if($game->{result} eq 'won') {
		print "I won. Perhaps the next time you will have more luck.\n";
	    } elsif($game->{result} eq 'stalemate') {
		print "It's a stalemate, mate!";
	    }
	    last;
	}
	@squares = &unoccupied_squares($game->{position});
	&prompt(@squares);
    }
}

sub display_game {
    my($game)=@_;
    &display_position($game->{position});
    print "Ply: $game->{ply}\n";
    print "$game->{player} to move\n";
}

sub prompt {
    print "Enter square (legal are ", join(',', @_), "):\n";
}

sub syntax {
    print "Illegal move: $_[0]\n";
}

&play;

exit;
