use strict;
use warnings;

package DBIx::Class::Tree::NestedSet;

use parent 'DBIx::Class';

__PACKAGE__->mk_classdata( _tree_columns => 'foo' );

sub tree_columns {
    my ($class, $args) = @_;

    if (defined $args) {
        my ($root, $left, $right) = map {
            $args->{"${_}_column"}
        } qw/root left right/;

        my $table     = $class->table;
        my %join_cond = ( "foreign.$root" => "self.$root" );

        $class->belongs_to(
            root => $class,
            \%join_cond,
            { where => \"me.$left = 1", },
        );

        $class->has_many(
            nodes => $class,
            \%join_cond,
        );

        $class->has_many(
            children => $class,
            \%join_cond,
            { where    => \"me.$left > parent.$left AND me.$right < parent.$right",
              order_by =>  "me.$left",
              from     =>  "$table me, $table parent" },
        );

        $class->has_many(
            parents => $class,
            { %join_cond, },
            { where    => \"child.$left > me.$left AND child.$right < me.$right",
              order_by =>  "me.$right",
              from     =>  "$table me, $table child" },
        );

        $class->_tree_columns($args);
    }

    return $class->_tree_columns;
}

sub parent {
    my ($self) = @_;

    return $self->parents->first;
}

sub insert {
    my $self = shift;

    my ($root, $left, $right) = map {
        $self->tree_columns->{"${_}_column"}
    } qw/root left right/;

    if (!$self->$right) {
        $self->set_columns({
            $left  => 1,
            $right => 2,
        });
    }

    my $row  = $self->next::method(@_);

    if (!defined $row->$root) {
        $row->update({
            $root => $row->get_column( ($row->result_source->primary_columns)[0] ),
        });

        $row->discard_changes;
    }

    return $row;
}

sub create_related {
    my ($self, $rel, $col_data) = @_;

    if ($rel eq 'children') {
        my ($root, $left, $right) = map {
            $self->tree_columns->{"${_}_column"}
        } qw/root left right/;

        my $p_rgt = $self->$right;

        $self->nodes_rs->update({
            $left  => \"CASE WHEN $left  >  $p_rgt THEN $left  + 2 ELSE $left  END",
            $right => \"CASE WHEN $right >= $p_rgt THEN $right + 2 ELSE $right END",
        });

        @$col_data{$root, $left, $right} = ($self->$root, $p_rgt, $p_rgt + 1);
    }

    return $self->next::method($rel => $col_data);
}

1;
