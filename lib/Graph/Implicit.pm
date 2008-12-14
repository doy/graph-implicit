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

sub dijkstra {
    my $self = shift;
    my $from = shift;

    my $pq = Heap::Simple->new(elements => "Any");
    my %neighbors;
    my %dist = ($from => 0);
    my %pred = ($from => undef);
    $pq->key_insert(0, $from);
    while ($pq->count) {
        my $cost = $pq->top_key;
        my ($vertex, $path) = @{ $pq->extract_top };
        $neighbors{$vertex} = [$self->($vertex)]
            unless exists $neighbors{$vertex};
        for my $neighbor (@{ $neighbors{$vertex} })) {
            my ($vert_n, $weight_n) = @{ $neighbor };
            my $dist = $cost + $weight_n;
            if (!defined $dist{$vert_n} || $dist < $dist{$vert_n}) {
                $dist{$vert_n} = $dist;
                $pred{$vert_n} = $vertex;
                $pq->key_insert($dist, $vert_n);
            }
        }
    }
    return \%pred;
}

1;
