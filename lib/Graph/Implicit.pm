use strict;
use warnings;
package Graph::Implicit;
use Heap::Simple;
use List::MoreUtils qw/apply/;

=head1 NAME

Graph::Implicit - graph algorithms for implicitly specified graphs

=head1 SYNOPSIS


=head1 DESCRIPTION


=cut

=head1 CONSTRUCTOR

=cut

sub new {
    my $class = shift;
    my $edge_calculator = shift;
    return bless $edge_calculator, $class;
}

=head1 METHODS

=cut

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

# traversal

sub _traversal {
    my $self = shift;
    my ($start, $code, $create, $notempty, $insert, $remove) = @_;
    my $bag = $create->();
    my %marked;
    my %pred;
    $pred{$start} = undef;
    $insert->($bag, [undef, $start], 0);
    while ($notempty->($bag)) {
        my ($pred, $vertex) = @{ $remove->($bag) };
        if (not exists $marked{$vertex}) {
            $code->($pred, $vertex);
            $pred{$vertex} = $pred if defined wantarray;
            $marked{$vertex} = 1;
            $insert->($bag, [$vertex, $$_[0]], $$_[1]) for $self->($vertex);
        }
    }
    return \%pred;
}

sub bfs {
    my $self = shift;
    my ($start, $code) = @_;
    return $self->_traversal($start, $code,
                             sub { [] },
                             sub { @{ $_[0] } },
                             sub { push @{ $_[0] }, $_[1] },
                             sub { shift @{ $_[0] } });
}

sub dfs {
    my $self = shift;
    my ($start, $code) = @_;
    return $self->_traversal($start, $code,
                             sub { [] },
                             sub { @{ $_[0] } },
                             sub { push @{ $_[0] }, $_[1] },
                             sub { pop @{ $_[0] } });
}

#sub iddfs {
#}

# minimum spanning tree

#sub boruvka {
#}

# XXX: this algo only works in its current form for undirected graphs with
# unique edge weights
#sub prim {
    #my $self = shift;
    #my ($start, $code) = @_;
    #return $self->_traversal($start, $code,
                             #sub { Heap::Simple->new(elements => 'Any') },
                             #sub { $_[0]->count },
                             #sub { $_[0]->key_insert($_[2], $_[1]) },
                             #sub { $_[0]->extract_top });
#}

#sub kruskal {
#}

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

#sub bellman_ford {
#}

# all pairs shortest path

#sub johnson {
#}

#sub floyd_warshall {
#}

# non-trivial graph properties

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

# sorting

#sub topological_sort {
#}

# misc utility functions

sub make_path {
    my $self = shift;
    my ($pred, $end) = @_;
    my @path;
    while (defined $end) {
        push @path, $end;
        $end = $pred->{$end};
    }
    return reverse @path;
}

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-graph-implicit at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Graph-Implicit>.

=head1 SEE ALSO

L<Moose>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Graph::Implicit

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Graph-Implicit>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Graph-Implicit>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Graph-Implicit>

=item * Search CPAN

L<http://search.cpan.org/dist/Graph-Implicit>

=back

=head1 AUTHOR

  Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;

__END__

=for example

sub {
    map { [$_, $_->intrinsic_cost] }
        shift->grep_adjacent(sub { shift->is_walkable })
}

=cut

