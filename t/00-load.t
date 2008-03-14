#!/usr/bin/env perl

use Test::More tests => 12;

BEGIN {
    use_ok('Carp');
    use_ok('URI');
    use_ok('WWW::Mechanize');
    use_ok('Class::Data::Accessor');
	use_ok( 'WWW::PastebinCa::Create' );
}

diag( "Testing WWW::PastebinCa::Create $WWW::PastebinCa::Create::VERSION, Perl $], $^X" );

my $o = WWW::PastebinCa::Create->new;

isa_ok( $o, 'WWW::PastebinCa::Create');
can_ok( $o, qw(new uri error mech paste valid_langs valid_expires
                    _set_error));

isa_ok( $o->mech, 'WWW::Mechanize');

my $uri = $o->paste('{ map { $_ => $_ } split /,/, $foos ',
expire => '5 minutes' );

if ( not defined $uri ) {
    diag "Got error: " . $o->error;
    ok( (defined $o->error and length $o->error), 'error must be defined' );
    ok( (not defined $o->uri), '->uri must be undefined');
    ok(1) for 1..2;
}
else {
    isa_ok($uri, 'URI::http');
    like( "$uri", qr|^http://pastebin\.ca/|, 'uri must be pointing to paste');
    isa_ok($o->uri, 'URI::http');
    is( $uri, $o->uri, '->uri and return from ->paste() must match');
}

