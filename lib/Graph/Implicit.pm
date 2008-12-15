#!/usr/bin/perl
use strict;
use warnings;
package Graph::Implicit;
use Heap::Simple;
use List::MoreUtils qw/apply/;

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
    my $self = shift;
    my ($start) = @_;
    my @vertices;
    $self->dfs($start, sub { push @vertices, $_[1] });
    return @vertices;
}

# XXX: probably pretty inefficient... can we do better?
sub edges {
    my $self = shift;
    my ($start) = @_;
    map { my $v = $_; map { [$v, $_] } $self->neighbors($v) }
        $self->vertices($start);
}

sub neighbors {
    my $self = shift;
    my ($from) = @_;
    return map { $$_[0] } $self->($from);
}

# more complicated graph properties

sub is_bipartite {
    my $self = shift;
    my ($from) = @_;
    my $ret = 1;
    BIPARTITE: {
        my %colors = ($from => 0);
        no warnings 'exiting';
        $self->bfs($from, sub {
            my $vertex = $_[1];
            apply {
                last BIPARTITE if $colors{$vertex} == $colors{$_};
                $colors{$_} = not $colors{$vertex};
            } $self->neighbors($vertex)
        });
        return 1;
    }
    return 0;
}

# traversal

# XXX: if we can generalize @bag to allow for a heap, then we can implement
# prim with this too
sub _traversal {
    my $self = shift;
    my ($start, $code, $insert, $remove) = @_;
    my @bag;
    my %marked;
    my %pred;
    $insert->(\@bag, [undef, $start]);
    while (@bag) {
        my ($pred, $vertex) = @{ $remove->(\@bag) };
        if (not exists $marked{$vertex}) {
            $code->($pred, $vertex);
            $pred{$vertex} = $pred if defined wantarray;
            $marked{$vertex} = 1;
            $insert->(\@bag, $_) for $self->neighbors($vertex);
        }
    }
    return \%pred;
}

sub bfs {
    my $self = shift;
    my ($start, $code) = @_;
    return $self->_traversal($start, $code,
                             sub { push @{ $_[0] }, $_[1] },
                             sub { shift @{ $_[0] } });
}

sub dfs {
    my $self = shift;
    my ($start, $code) = @_;
    return $self->_traversal($start, $code,
                             sub { push @{ $_[0] }, $_[1] },
                             sub { pop @{ $_[0] } });
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
    my ($from, $scorer) = @_;
    return $self->astar($from, sub { 0 }, $scorer);
}

sub astar {
    my $self = shift;
    my ($from, $heuristic, $scorer) = @_;

    my $pq = Heap::Simple->new(elements => "Any");
    my %neighbors;
    my ($max_vert, $max_score) = (undef, 0);
    my %dist = ($from => 0);
    my %pred = ($from => undef);
    $pq->key_insert(0, $from);
    while ($pq->count) {
        my $cost = $pq->top_key;
        my $vertex = $pq->extract_top;
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
            my $dist = $cost + $weight_n + $heuristic->($vertex, $vert_n);
            if (!defined $dist{$vert_n} || $dist < $dist{$vert_n}) {
                $dist{$vert_n} = $dist;
                $pred{$vert_n} = $vertex;
                $pq->key_insert($dist, $vert_n);
            }
        }
    }
    return \%pred, $max_vert;
}

sub bellman_ford {
}

# all pairs shortest path

sub johnson {
}

sub floyd_warshall {
}

# other (?)

sub topological_sort {
}

# misc utility functions

sub make_path {
    my ($pred, $end) = @_;
    my @path;
    while (defined $end) {
        push @path, $end;
        $end = $pred->{$end};
    }
    return reverse @path;
}

1;
