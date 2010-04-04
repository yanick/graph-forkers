#!/usr/bin/perl 

use strict;
use warnings;
use DBM::Deep;
use Graph::Easy;

tie my %project, 'DBM::Deep', 'projects';

my $graph = Graph::Easy->new;

for my $p ( values %project ) {
    for my $owner ( keys %$p ) {
        warn "$owner\n";
        for my $f ( @{ $p->{$owner} } ) {
            warn "\t$f\n";
            $graph->add_edge_once( $owner => $f );
        }
    }
}

print $graph->as_graphml;



