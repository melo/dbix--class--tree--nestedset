use strict;
use warnings;
use Test::More tests => 6;
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

is($root_node->children->count, 0);

my $child_node = $root_node->add_to_children({ content => 'bar' });
is($root_node->children->count, 1);
