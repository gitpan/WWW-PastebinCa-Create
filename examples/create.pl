#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';
use WWW::PastebinCa::Create;

my $paster = WWW::PastebinCa::Create->new;

$paster->paste('testing', expire => '5 minutes' )
    or die $paster->error;

printf "Your paste can be found on %s\n", $paster->uri;