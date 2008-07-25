use strict;
use warnings;
use Test::More tests => 13;
use DBICx::TestDatabase;

use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN { use_ok('TestSchema') }

my $schema = DBICx::TestDatabase->new('TestSchema');
isa_ok($schema, 'DBIx::Class::Schema');

my $trees = $schema->resultset('Tree');
isa_ok($trees, 'DBIx::Class::ResultSet');

my $root_node = $trees->create({ content => 'foo' });
isa_ok($root_node, 'DBIx::Class::Row');

is($root_node->root->id, $root_node->id, 'root field gets set automatically');
is($root_node->children->count, 0, 'no children, initially');
is($root_node->nodes->count, 1, 'nodes include self');

my $child_node = $root_node->add_to_children({ content => 'bar' });
is($root_node->children->count, 1, 'now one child');
is($root_node->nodes->count, 2, '... and two related nodes');

my $subchild = $child_node->add_to_children({ content => 'moo' });
is($root_node->children->count, 2, 'root now two childs');
is($root_node->nodes->count, 3, '... and three related nodes');
is($child_node->children->count, 1, 'subnode has one children');
is($child_node->nodes->count, 3, '... and three related nodes as well');
