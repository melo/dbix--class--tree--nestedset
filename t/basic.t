use strict;
use warnings;
use Test::More tests => 22;
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

my $child2 = $root->add_to_children({ content => 'kooh' });

my $subchild = $child->add_to_children({ content => 'moo' });
is($subchild->root->id, $root->id, 'root set for subchilds');
is($root->children->count, 3, 'root now two childs');
is($root->nodes->count, 4, '... and three related nodes');
is($child->children->count, 1, 'subnode has one children');
is($child->nodes->count, 4, '... and three related nodes as well');
is($subchild->children->count, 0, 'subchild does not have children yet');
is($subchild->parents->count, 2, '... but two parents');
is($subchild->parent->id, $child->id, 'direct parent is correct');

is_deeply(
    [map { $_->id } $subchild->parents],
    [map { $_->id } $child, $root],
    'parents are ordered correctly',
);

is_deeply(
    [map { $_->id } $root->children],
    [map { $_->id } $child, $subchild, $child2],
    'roots children are ordered correctly',
);
