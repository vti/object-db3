package ObjectDB::Related::OneToMany;

use strict;
use warnings;

use base 'ObjectDB::Related';

our $VERSION = '3.17';

use Scalar::Util ();
use ObjectDB::Util qw(merge);

sub create_related {
    my $self = shift;
    my ($row, $related) = @_;

    my $meta = $self->meta;
    my ($from, $to) = %{$meta->map};

    my @params = ($to => $row->column($from));

    my @objects;
    foreach my $related (@$related) {
        if (Scalar::Util::blessed($related)) {
            push @objects, $related->set_columns(@params)->save;
        }
        else {
            push @objects, $meta->class->new(%$related, @params)->create;
        }
    }

    return @objects;
}

sub find_related {
    my $self = shift;
    my ($row) = shift;

    my $meta = $self->meta;
    my ($from, $to) = %{$meta->map};

    return unless defined $row->column($from);

    return $self->_related_table->find($self->_build_params($row, @_));
}

sub count_related {
    my $self = shift;
    my ($row) = shift;

    return $self->_related_table->count($self->_build_params($row, @_));
}

sub update_related {
    my $self = shift;
    my ($row) = shift;

    return $self->_related_table->update($self->_build_params($row, @_));
}

sub delete_related {
    my $self = shift;
    my ($row) = shift;

    return $self->_related_table->delete($self->_build_params($row, @_));
}

sub _related_table { shift->meta->class->table }

sub _build_params {
    my $self = shift;
    my ($row) = shift;

    my $meta = $self->meta;
    my ($from, $to) = %{$meta->map};

    my $params = merge { @_ }, {where => [$to => $row->column($from)]};
    return %$params;
}

1;
