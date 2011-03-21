package Geo::Coder::PlaceFinder;

use strict;
use warnings;

use Carp qw(croak);
use Encode ();
use JSON;
use LWP::UserAgent;
use URI;

our $VERSION = '0.04';
$VERSION = eval $VERSION;

sub new {
    my ($class, @params) = @_;
    my %params = (@params % 2) ? (appid => @params) : @params;

    croak q('appid' is required) unless $params{appid};

    my $self = bless \ %params, $class;

    $self->ua(
        $params{ua} || LWP::UserAgent->new(agent => "$class/$VERSION")
    );

    if ($params{debug}) {
        my $dump_sub = sub { $_[0]->dump(maxlength => 0); return };
        $self->ua->set_my_handler(request_send  => $dump_sub);
        $self->ua->set_my_handler(response_done => $dump_sub);
    }
    elsif (exists $self->{compress} ? $self->{compress} : 1) {
        $self->ua->default_header(accept_encoding => 'gzip,deflate');
    }

    return $self;
}

sub response { $_[0]->{response} }

sub ua {
    my ($self, $ua) = @_;
    if ($ua) {
        croak q('ua' must be (or derived from) an LWP::UserAgent')
            unless ref $ua and $ua->isa(q(LWP::UserAgent));
        $self->{ua} = $ua;
    }
    return $self->{ua};
}

sub geocode {
    my ($self, @params) = @_;
    my %params = (@params % 2) ? (location => @params) : @params;

    # Allow user to pass free-form, multi-line or fully-parsed formats.
    return unless grep { defined $params{$_} } qw(
        location q name line1 addr house woeid
    );

    while (my ($key, $val) = each %params) {
        $params{$key} = Encode::encode('utf-8', $val);
    }

    my $uri = URI->new('http://where.yahooapis.com/geocode');
    $uri->query_form(
        appid  => $self->{appid},
        flags  => 'JRST',
        gflags => 'AC',
        %params,
    );

    my $res = $self->{response} = $self->ua->get($uri);
    return unless $res->is_success;

    # Change the content type of the response from 'application/json' so
    # HTTP::Message will decode the character encoding.
    $res->content_type('text/plain');

    my $data = eval { from_json($res->decoded_content) };
    return unless $data;

    my @results = @{ $data->{ResultSet}{Results} || [] };
    return wantarray ? @results : $results[0];
}


1;

__END__

=head1 NAME

Geo::Coder::PlaceFinder - Geocode addresses with Yahoo PlaceFinder

=head1 SYNOPSIS

    use Geo::Coder::PlaceFinder;

    my $geocoder = Geo::Coder::PlaceFinder->new(appid => 'Your App ID');
    my $location = $geocoder->geocode(
        location => 'Hollywood and Highland, Los Angeles, CA'
    );

=head1 DESCRIPTION

The C<Geo::Coder::PlaceFinder> module provides an interface to the Yahoo
PlaceFinder geocoding service.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::PlaceFinder->new(appid => 'Your App ID')

Creates a new geocoding object.

A Yahoo API Key can be obtained here:
L<https://developer.apps.yahoo.com/dashboard/createKey.html>

Accepts an optional B<ua> parameter for passing in a custom LWP::UserAgent
object.

=head2 geocode

    $location = $geocoder->geocode(location => $location)
    @locations = $geocoder->geocode(location => $location)

In scalar context, this method returns the first location result; and in
list context it returns all location results.

Each location result is a hashref; a typical example looks like:

    {
        areacode     => 213,
        city         => "Los Angeles",
        country      => "United States",
        countrycode  => "US",
        county       => "Los Angeles County",
        countycode   => "",
        cross        => "",
        hash         => "",
        house        => "",
        latitude     => "34.101559",
        line1        => "Hollywood and Highland",
        line2        => "Los Angeles, CA  90028",
        line3        => "",
        line4        => "United States",
        longitude    => "-118.339073",
        name         => "Hollywood and Highland",
        neighborhood => "",
        offsetlat    => "34.101559",
        offsetlon    => "-118.339073",
        postal       => 90028,
        quality      => 90,
        radius       => 100,
        state        => "California",
        statecode    => "CA",
        street       => "",
        timezone     => "America/Los_Angeles",
        unit         => "",
        unittype     => "",
        uzip         => 90028,
        woeid        => 23529720,
        woetype      => 20,
        xstreet      => "",
    }

=head2 response

    $response = $geocoder->response()

Returns an L<HTTP::Response> object for the last submitted request. Can be
used to determine the details of an error.

=head2 ua

    $ua = $geocoder->ua()
    $ua = $geocoder->ua($ua)

Accessor for the UserAgent object.

=head1 SEE ALSO

L<http://developer.yahoo.com/geo/placefinder/>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Geo-Coder-PlaceFinder>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::PlaceFinder

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/geo-coder-placefinder>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Coder-PlaceFinder>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-PlaceFinder>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-PlaceFinder>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-PlaceFinder/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
