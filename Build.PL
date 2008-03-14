use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::PastebinCa::Create',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/WWW/PastebinCa/Create.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                  => 1.04,
        'URI'                   => 1.35,
        'WWW::Mechanize'        => 1.34,
        'Class::Data::Accessor' => 0.04001,
    },
    add_to_cleanup      => [ 'WWW-PastebinCa-Create-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
