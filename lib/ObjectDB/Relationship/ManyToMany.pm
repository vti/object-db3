package ObjectDB::Relationship::ManyToMany;

use strict;
use warnings;

use base 'ObjectDB::Relationship';

sub create_related {
    my $self = shift;
    my ($row) = shift;

    my @related = @_ == 1 ? ref $_[0] eq 'ARRAY' ? @{$_[0]} : ($_[0]): ({@_});

    my @objects;
    foreach my $related (@related) {
        my %params = %$related;

        my $meta = $self->meta;

        my $object;

        $object = $meta->class->new(%params)->load;
        if (!$object) {
            $object = $meta->class->new(%params)->create;
        }

        my $map_from = $meta->map_from;
        my $map_to   = $meta->map_to;

        my ($from_foreign_pk, $from_pk) =
          %{$meta->map_class->meta->relationships->{$map_from}->map};

        my ($to_foreign_pk, $to_pk) =
          %{$meta->map_class->meta->relationships->{$map_to}->map};

        $meta->map_class->new(
            $from_foreign_pk => $row->get_column($from_pk),
            $to_foreign_pk   => $object->get_column($to_pk)
        )->create;

        push @objects, $object;
    }

    return @related == 1 ? $objects[0] : @objects;
}

#sub find_related {
#    my $self   = shift;
#    my ($row)  = shift;
#    my %params = @_;
#
#    my $meta = $self->meta;
#
#    my $map_from = $meta->map_from;
#    my $map_to   = $meta->map_to;
#
#    my ($from, $to) = %{$meta->map_class->meta->relationships->{$map_to}->map};
#
#    my ($map_table_to, $map_table_from) =
#      %{$meta->map_class->meta->relationships->{$map_from}->map};
#
#    push @{$params{where}}, 'books.id' => $row->column($map_table_from);
#
#    #my $table     = $meta->class->meta->table;
#    #my $map_table = $meta->map_class->meta->table;
#    #$params{joins} = [
#        #{   table      => $map_table,
#            #join       => 'left',
#            #constraint => [
#                #"$table.$to" => {-col => "$map_table.$from"},
#                ##"$map_table.$map_table_to" => $row->column($map_table_from)
#            #]
#        #}
#    #];
#
#    return $meta->class->table->find(%params);
#}
#
#sub count_related {
#    my $self = shift;
#    my ($row) = shift;
#    my %params = @_;
#
#    my $meta = $self->meta;
#
#    my $map_from = $meta->{map_from};
#    my $map_to   = $meta->{map_to};
#
#    my ($map_table_to, $map_table_from) =
#      %{$meta->map_class->meta->relationships->{$map_from}->map};
#
#    #push @{$params{where}},
#      #($meta->map_class->meta->table . '.' . $to => $row->column($from));
#
#    my ($from, $to) = %{$meta->map_class->meta->relationships->{$map_to}->map};
#
#    my $table     = $meta->class->meta->table;
#    my $map_table = $meta->map_class->meta->table;
#    $params{joins} = [
#        {   table      => $map_table,
#            join       => 'left',
#            constraint => [
#                "$table.$to" => {-col => "$map_table.$from"},
#                "$map_table.$map_table_to" => $row->column($map_table_from)
#            ]
#        }
#    ];
#
#    return $meta->class->table->count(%params);
#}

sub delete_related {
    my $self = shift;
    my ($row, %params) = @_;

    $params{where} ||= [];

    my $meta = $self->meta;

    my $map_from = $meta->map_from;
    my $map_to   = $meta->map_to;

    my ($to, $from) =
      %{$meta->map_class->meta->relationships->{$map_from}->map};

    push @{$params{where}}, ($to => $row->get_column($from));

    if ($meta->where) {
        push @{$params{where}}, %{$meta->where};
    }

    return $meta->map_class->table->delete(%params);
}

1;