package WWW::PastebinCa::Create;

use warnings;
use strict;

our $VERSION = '0.001';
use Carp;
use URI;
use WWW::Mechanize;
use base 'Class::Data::Accessor';
__PACKAGE__->mk_classaccessors qw(
    mech
    uri
    error
);

my %Valid_Langs   = valid_langs();
my %Valid_Expires = map { $_ => $_ } valid_expires();

sub new {
    my $self = bless {}, shift;
    croak "Must have even number of arguments to new()"
        if @_ & 1;

    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;

    $args{timeout} ||= 30;
    $args{mech}    ||= WWW::Mechanize->new(
        timeout => $args{timeout},
        agent   => 'Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.8.1.12)'
                    .' Gecko/20080207 Ubuntu/7.10 (gutsy) Firefox/2.0.0.12',
    );

    $self->mech( $args{mech} );

    return $self;
}

sub paste {
    my ( $self, $content ) = splice @_, 0, 2;

    $self->$_(undef) for qw(uri error);
    
    defined $content
        or carp "first argument to paste() is not defined" and return;

    croak "Must have even number of optional arguments to paste()"
        if @_ & 1;

    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;
    %args = (
        content     => $content,
        name        => '',
        desc        => '',
        tags        => '',
        lang        => 1,
        expire      => '',
        %args,
    );

    croak q|Invalid 'lang' was specified to paste(). |
            . q|print Dumper { WWW::PastebinCa::Create::valid_langs }|
        unless exists $Valid_Langs{ $args{lang} };

    croak q|Invalid 'expire' was specified to paste(). |
            . q|print Dumper { WWW::PastebinCa::Create::valid_expires }|
        if length $args{expire}
            and not exists $Valid_Expires{ $args{expire} };

    my $mech = $self->mech;
    $mech->get('http://pastebin.ca');

    return $self->_set_error('Network error: ' . $mech->res->status_line)
        unless $mech->success;

    $mech->form_with_fields( 'content' )
        or return $self->_set_error('Paste form was not found');

    my $set = $mech->set_visible(
        $args{content},
        [ text      => $args{name}   ],
        [ textarea  => $args{desc}   ],
        [ text      => $args{tags}   ],
        [ option    => $args{lang}   ],
        [ option    => $args{expire} ],
    );

    $set == 6
        or return $self->_set_error("Failed to set all fields (only $set)");

    $mech->click('s')->is_success
        or return $self->_set_error(
            'Network error: ' . $mech->res->status_line
        );

    my ( $uri ) = $mech->content
    =~ m|<meta http-equiv="refresh" content="7;(http://pastebin.ca/[^"]+)"|;

    defined $uri
        or return $self->_set_error('Failed to locate link to paste');

    return $self->uri( URI->new($uri) );
}

sub _set_error {
    my ( $self, $error ) = @_;
    $self->error( $error );
    return;
}

sub valid_langs {
    return (
         1 => 'Raw',
         2 => 'Asterisk Configuration',
         3 => 'C Source',
         4 => 'C++ Source',
         5 => 'PHP Source',
         6 => 'Perl Source',
         7 => 'Java Source',
         8 => 'Visual Basic Source',
         9 => 'C# Source',
        10 => 'Ruby Source',
        11 => 'Python Source',
        12 => 'Pascal Source',
        13 => 'mIRC Script',
        14 => 'PL/I Source',
        15 => 'XML Document',
        16 => 'SQL Statement',
        17 => 'Scheme Source',
        18 => 'Action Script',
        19 => 'Ada Source',
        20 => 'Apache Configuration',
        21 => 'Assembly (NASM)',
        22 => 'ASP',
        23 => 'BASH Script',
        24 => 'CSS',
        25 => 'Delphi Source',
        26 => 'HTML 4.0 Strict',
        27 => 'JavaScript',
        28 => 'LISP Source',
        29 => 'Lua Source',
        30 => 'Microprocessor ASM',
        31 => 'Objective C',
        32 => 'Visual Basic .NET',
        33 => 'Script Log',
        34 => 'Diff / Patch',
    );
}

sub valid_expires {
    return (
        '2 hours',
        '4 hours',
        '1 year',
        '2 weeks',
        '45 minutes',
        '2 months',
        '30 minutes',
        '1 week',
        '1 hour',
        '15 minutes',
        '10 minutes',
        '3 days',
        '5 months',
        '4 months',
        '5 minutes',
        '8 hours',
        '2 days',
        '3 months',
        '1 day',
        '12 hours',
        '3 weeks',
        '6 months',
        '1 month',
    );
}

1;
__END__


=head1 NAME

WWW::PastebinCa::Create - create new pastes on http://pastebin.ca from Perl

=head1 SYNOPSYS

    use strict;
    use warnings;

    use WWW::PastebinCa::Create;

    my $paster = WWW::PastebinCa::Create->new;

    $paster->paste('testing')
        or die $paster->error;

    printf "Your paste can be found on %s\n", $paster->uri;

=head1 DESCRIPTION

The module provides means of pasting large texts into
L<http://pastebin.ca> pastebin site.

=head1 CONSTRUCTOR

=head2 new

    my $paster = WWW::PastebinCa::Create->new;

    my $paster = WWW::PastebinCa::Create->new( timeout => 10 );

    my $paster = WWW::PastebinCa::Create->new(
        mech => WWW::Mechanize->new( agent => '007', timeout => 10 ),
    );

Bakes and returns a fresh WWW::PastebinCa::Create object. Takes two
I<optional> arguments which are as follows:

=head3 timeout

    my $paster = WWW::PastebinCa::Create->new( timeout => 10 );

Takes a scalar as a value which is the value that will be passed to
the L<WWW::Mechanize> object to indicate connection timeout in seconds.
B<Defaults to:> C<30> seconds

=head3 mech

    my $paster = WWW::PastebinCa::Create->new(
        mech => WWW::Mechanize->new( agent => '007', timeout => 10 ),
    );

If a simple timeout is not enough for your needs feel free to specify
the C<mech> argument which takes a L<WWW::Mechanize> object as a value.
B<Defaults to:> plain L<WWW::Mechanize> object with C<timeout> argument
set to whatever WWW::PastebinCa::Create's C<timeout> argument is set to
as well as C<agent> argument is set to mimic FireFox.

=head1 METHODS

=head2 paste

    my $uri = $paster->paste('some long text')
        or die $paster->error;

    my $uri2 = $paster->paste(
        'some long text',
        name    => 'Zoffix',
        lang    => 6, # perl syntax highlights
        expire  => '5 minutes',
        desc    => 'some codes',
        tags    => 'some space separated tags',
    ) or die $paster->error;

Instructs the object to create a new paste. If an error occured during
pasting the method will return either C<undef> or an empty list
depending on the context and the error will be available via C<error()>
method. On success returns a L<URI> object poiting to the newly created
paste (see also C<uri()> method). The first argument is
I<mandatory> content of your paste. The rest are optional arguments which
are passed in a key/value pairs. The optional arguments are as follows:

=head3 name

    { name    => 'Zoffix' }

B<Optional>. Takes a scalar as an argument which specifies the name of the
poster or
the titles of the paste. B<Defaults to:> empty string, which in turn results
to word C<Stuff> being the title of the paste. B<Defaults to:> empty string.

=head2 lang

    { lang    => 6 }

B<Optional>. Takes an integer value from C<1> to C<34> representing the
(computer)
language of the paste, or, in other words, the syntax highlights to turn
on. B<Defaults to:> C<1> (Raw). The integer C<lang> codes are as follows:

         1 => 'Raw',
         2 => 'Asterisk Configuration',
         3 => 'C Source',
         4 => 'C++ Source',
         5 => 'PHP Source',
         6 => 'Perl Source',
         7 => 'Java Source',
         8 => 'Visual Basic Source',
         9 => 'C# Source',
        10 => 'Ruby Source',
        11 => 'Python Source',
        12 => 'Pascal Source',
        13 => 'mIRC Script',
        14 => 'PL/I Source',
        15 => 'XML Document',
        16 => 'SQL Statement',
        17 => 'Scheme Source',
        18 => 'Action Script',
        19 => 'Ada Source',
        20 => 'Apache Configuration',
        21 => 'Assembly (NASM)',
        22 => 'ASP',
        23 => 'BASH Script',
        24 => 'CSS',
        25 => 'Delphi Source',
        26 => 'HTML 4.0 Strict',
        27 => 'JavaScript',
        28 => 'LISP Source',
        29 => 'Lua Source',
        30 => 'Microprocessor ASM',
        31 => 'Objective C',
        32 => 'Visual Basic .NET',
        33 => 'Script Log',
        34 => 'Diff / Patch',

=head3 expire

    { expire  => '5 minutes' }

B<Optional>. Takes a "valid expire string" as an argument. Specifies when
the paste should
expire. If the value is set to an empty string, the paste will be set
to never expire. B<Defaults to:> empty string (Never). Possible
"valid expire string"s are as follows:

    '2 hours'
    '4 hours'
    '1 year'
    '2 weeks'
    '45 minutes'
    '2 months'
    '30 minutes'
    '1 week'
    '1 hour'
    '15 minutes'
    '10 minutes'
    '3 days'
    '5 months'
    '4 months'
    '5 minutes'
    '8 hours'
    '2 days'
    '3 months'
    '1 day'
    '12 hours'
    '3 weeks'
    '6 months'
    '1 month'

=head3 desc

    { desc => 'some codes' }

B<Optional>. Takes a scalar string representing the description of the paste.
B<Defaults to:> empty string.

=head3 tags

    { tags => 'some space separated tags' }

B<Optional>.
Takes a scalar string which should be space separated "tags" to tag
the paste with. B<Defaults to:> empty string.

=head2 error

    my $uri = $paster->paste('some long text')
        or die $paster->error;

If an error occured during
a call to C<paste()> it will return either C<undef> or an empty list
depending on the context and the error will be available via C<error()>
method. Takes no arguments, returns an error message explaining why
C<paste()> failed.

=head2 uri

    my $paste_uri = $paster->uri;

Must be called after a successfull call to C<paste()>. Takes no arguments,
returns a L<URI> object pointing to a newly created paste.

=head2 valid_langs

    my %valid_lang_codes_and_descriptions = $paster->valid_langs;
    use Data::Dumper;
    print Dumper \%valid_lang_codes_and_descriptions;

Takes no arguments. Returns a flatened hash of valid language codes
to use in C<lang> argument to C<paste()> method as keys and the language
descriptions as values.

=head2 valid_expires

    print "'$_' is a valid expire value\n"
        for $paster->valid_expires;

Takes no arguments. Returns a list of valid values for C<expire> argument
to C<paste()> method

=head2 mech

    my $old_mech = $paster->mech;

    $paster->mech( WWW::Mechanize->new( agent => '007' ) );

Returns a L<WWW::Mechanize> object used internally for pasting. When
called with an optional argument (which must be a L<WWW::Mechanize> object)
will use it for pasting.

=head1 NO SPAM

Please note that pastebin.ca has a spam protection and will ban you for
pasting too much. So don't abuse it, ktnx.

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-pastebinca-create at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-PastebinCa-Create>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::PastebinCa::Create

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-PastebinCa-Create>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-PastebinCa-Create>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-PastebinCa-Create>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-PastebinCa-Create>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

