#!/usr/bin/env perl

use strict;
use warnings;

my @trip =   ("Chicago", "Saint Looey", "Joplin", "OKC", "Amarillo", "Gallup",
                         "Flagstaff", "Winona", "Kingman", "Barstow", "San Bernandino", "LA" );
map { printf  "%15s to %-15s\n", @trip[$_..$_+1]  } 0..$#trip-1;

exit;