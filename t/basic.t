use strict;
use warnings;
use Test::More tests => 20;
use DBICx::TestDatabase;

use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN { use_ok('TestSchema') }

my $schema = DBICx::TestDatabase->new('TestSchema');
isa_ok($schema, 'DBIx::Class::Schema');

my $trees = $schema->resultset('Tree');
isa_ok($trees, 'DBIx::Class::ResultSet');

my $root = $trees->create({ content => 'foo' });
isa_ok($root, 'DBIx::Class::Row');

is($root->root->id, $root->id, 'root field gets set automatically');
is($root->children->count, 0, 'no children, initially');
is($root->nodes->count, 1, 'nodes include self');

my $child = $root->add_to_children({ content => 'bar' });
is($child->root->id, $root->id, 'root set for children');
is($child->parents->count, 1, 'child got one parent');
is($child->parent->id, $root->id, 'parent rel works');
is($root->children->count, 1, 'now one child');
is($root->nodes->count, 2, '... and two related nodes');

my $subchild = $child->add_to_children({ content => 'moo' });
is($subchild->root->id, $root->id, 'root set for subchilds');
is($root->children->count, 2, 'root now two childs');
is($root->nodes->count, 3, '... and three related nodes');
is($child->children->count, 1, 'subnode has one children');
is($child->nodes->count, 3, '... and three related nodes as well');
is($subchild->children->count, 0, 'subchild does not have children yet');
is($subchild->parents->count, 2, '... but two parents');
is($subchild->parent->id, $child->id, 'direct parent is correct');
