use strict;
use warnings;

package TestSchema::Tree;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/Tree::NestedSet Core/);
__PACKAGE__->table('tree');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
    },
    root => {
        data_type   => 'integer',
        is_nullable => 1,
    },
    lft     => { data_type => 'integer' },
    rgt     => { data_type => 'integer' },
    content => { data_type => 'text'    },
);

__PACKAGE__->set_primary_key(qw/id/);

__PACKAGE__->tree_columns({
    root_column  => 'root',
    left_column  => 'lft',
    right_column => 'rgt',
});

1;
