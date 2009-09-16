use strict;
use Test::More tests => 1;

use FindBin;
use DBIx::DBHResolver;

DBIx::DBHResolver->load("$FindBin::Bin/db.conf.yaml");

my $info = DBIx::DBHResolver->config;

is_deeply(
    {
        connect_info => {
            DB_W => {
                dsn => 'dbi:mysql:dbname=user;host=db_w',
                user => 'hoge',
                password => undef,
                attrs => {
                    AutoCommit => 0,
                    PrintError => 0,
                    RaiseError => 1,
                    Warn => 0,
                },
            },
            DB_R1 => {
                dsn => 'dbi:mysql:dbname=user;host=db_r1',
                user => 'hoge',
                password => undef,
                attrs => {
                    AutoCommit => 0,
                    PrintError => 0,
                    RaiseError => 1,
                    Warn => 0,
                },
            },
            DB_R2 => {
                dsn => 'dbi:mysql:dbname=user;host=db_r2',
                user => 'hoge',
                password => undef,
                attrs => {
                    AutoCommit => 0,
                    PrintError => 0,
                    RaiseError => 1,
                    Warn => 0,
                },
            },
        },
        clusters => {
            DB_R => [ qw(DB_R1 DB_R2) ],
        },
    },
    $info,
);
