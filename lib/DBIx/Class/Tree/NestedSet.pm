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
            { where => 'me.left = 1', },
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

1;
