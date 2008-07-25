use strict;
use warnings;

package DBIx::Class::Tree::NestedSet;

use parent 'DBIx::Class';

our $VERSION = '0.01_01';
$VERSION = eval $VERSION;

__PACKAGE__->mk_classdata( _tree_columns => {} );

sub tree_columns {
    my ($class, $args) = @_;

    if (defined $args) {
        $args = {
            root_rel     => 'root',
            nodes_rel    => 'nodes',
            children_rel => 'children',
            parents_rel  => 'parents',
            parent_rel   => 'parent',
            %{ $args },
        };

        my ($root, $left, $right) = map {
            $args->{"${_}_column"}
        } qw/root left right/;

        my $table     = $class->table;
        my %join_cond = ( "foreign.$root" => "self.$root" );

        $class->belongs_to(
            $args->{root_rel} => $class,
            \%join_cond,
            { where => \"me.$left = 1", },
        );

        $class->has_many(
            $args->{nodes_rel} => $class,
            \%join_cond,
        );

        $class->has_many(
            $args->{children_rel} => $class,
            \%join_cond,
            { where    => \"me.$left > parent.$left AND me.$right < parent.$right",
              order_by =>  "me.$left",
              from     =>  "$table me, $table parent" },
        );

        $class->has_many(
            $args->{parents_rel} => $class,
            { %join_cond, },
            { where    => \"child.$left > me.$left AND child.$right < me.$right",
              order_by =>  "me.$right",
              from     =>  "$table me, $table child" },
        );

        {
            no strict 'refs';
            no warnings 'redefine';

            my $meth = $args->{parents_rel};
            *{ "${class}::${\$args->{parent_rel}}" } = sub { shift->$meth(@_)->first };
        }

        $class->_tree_columns($args);
    }

    return $class->_tree_columns;
}

sub insert {
    my ($self, @args) = @_;

    my ($root, $left, $right) = map {
        $self->tree_columns->{"${_}_column"}
    } qw/root left right/;

    if (!$self->$right) {
        $self->set_columns({
            $left  => 1,
            $right => 2,
        });
    }

    my $row;
    my $get_row = $self->next::can;
    $self->result_source->schema->txn_do(sub {
        $row = $get_row->($self, @args);

        if (!defined $row->$root) {
            $row->update({
                $root => $row->get_column( ($row->result_source->primary_columns)[0] ),
            });

            $row->discard_changes;
        }
    });

    return $row;
}

sub create_related {
    my ($self, $rel, $col_data) = @_;

    if ($rel ne $self->tree_columns->{children_rel}) {
        return $self->next::method($rel => $col_data);
    }

    my %col_data = %{ $col_data };
    my ($root, $left, $right) = map {
        $self->tree_columns->{"${_}_column"}
    } qw/root left right/;

    my $row;
    my $get_row = $self->next::can;
    $self->result_source->schema->txn_do(sub {
        $self->discard_changes;
        my $p_rgt = $self->$right;

        $self->nodes_rs->update({
            $left  => \"CASE WHEN $left  >  $p_rgt THEN $left  + 2 ELSE $left  END",
            $right => \"CASE WHEN $right >= $p_rgt THEN $right + 2 ELSE $right END",
        });

        @col_data{$root, $left, $right} = ($self->$root, $p_rgt, $p_rgt + 1);
        $row = $get_row->($self, $rel => \%col_data);
    });

    return $row;
}

sub search_related {
    my ($self, $rel, $cond, @rest) = @_;
    my $pk = ($self->result_source->primary_columns)[0];

    $cond ||= {};
    if ($rel eq $self->tree_columns->{children_rel}) {
        $cond->{"parent.$pk"} = $self->$pk,
    }
    elsif ($rel eq $self->tree_columns->{parents_rel}) {
        $cond->{"child.$pk"} = $self->$pk,
    }

    return $self->next::method($rel, $cond, @rest);
}

{
    no warnings 'once';
    *search_related_rs = \&search_related;
}

1;
