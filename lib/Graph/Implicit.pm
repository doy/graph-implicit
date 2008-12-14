#!/usr/bin/perl
use strict;
use warnings;
package Graph::Implicit;
use Heap::Simple;

=for example

sub {
    map { [$_, $_->intrinsic_cost] }
        shift->grep_adjacent(sub { shift->is_walkable })
}

=cut

sub new {
    my $class = shift;
    my $edge_calculator = shift;
    return bless $edge_calculator, $class;
}

# generic information

sub vertices {
}

sub edges {
}

sub neighbors {
}

# traversal

sub bfs {
}

sub dfs {
}

sub iddfs {
}

# minimum spanning tree

sub boruvka {
}

sub prim {
}

sub kruskal {
}

# single source shortest path

sub dijkstra {
    my $self = shift;
    my $from = shift;
    my $scorer = shift;

    my $pq = Heap::Simple->new(elements => "Any");
    my %neighbors;
    my ($max_vert, $max_score) = (undef, 0);
    my %dist = ($from => 0);
    my %pred = ($from => undef);
    $pq->key_insert(0, $from);
    while ($pq->count) {
        my $cost = $pq->top_key;
        my ($vertex, $path) = @{ $pq->extract_top };
        if ($scorer) {
            my $score = $scorer->($vertex);
            return (\%pred, $vertex) if $score eq 'q';
            ($max_vert, $max_score) = ($vertex, $score)
                if ($score > $max_score);
        }
        $neighbors{$vertex} = [$self->($vertex)]
            unless exists $neighbors{$vertex};
        for my $neighbor (@{ $neighbors{$vertex} }) {
            my ($vert_n, $weight_n) = @{ $neighbor };
            my $dist = $cost + $weight_n;
            if (!defined $dist{$vert_n} || $dist < $dist{$vert_n}) {
                $dist{$vert_n} = $dist;
                $pred{$vert_n} = $vertex;
                $pq->key_insert($dist, $vert_n);
            }
        }
    }
    return \%pred, $max_vert;
}

sub astar {
}

sub bellman_ford {
}

# all pairs shortest path

sub johnson {
}

sub floyd_warshall {
}

1;
