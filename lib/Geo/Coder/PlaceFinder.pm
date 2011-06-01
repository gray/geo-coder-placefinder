package Geo::Coder::PlaceFinder;

use strict;
use warnings;

use Carp qw(croak);
use Encode ();
use JSON;
use LWP::UserAgent;
use URI;

our $VERSION = '0.05';
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
        $self->{compress} ||= 0;
    }
    if (exists $self->{compress} ? $self->{compress} : 1) {
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
    my $raw = delete $params{raw};

    $_ = Encode::encode('utf-8', $_) for values %params;

    my $uri = URI->new('http://where.yahooapis.com/geocode');
    $uri->query_form(
        appid  => $self->{appid},
        flags  => 'JRSTX',
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
    return $data if $raw;

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
        location => '701 First Ave, Sunnyvale, CA'
    );

=head1 DESCRIPTION

The C<Geo::Coder::PlaceFinder> module provides an interface to the Yahoo
PlaceFinder geocoding service.

=head1 METHODS

=head2 new

   $geocoder = Geo::Coder::PlaceFinder->new('Your App ID')
   $geocoder = Geo::Coder::PlaceFinder->new(
       appid => 'Your App ID',
       # debug => 1,
   )

Creates a new geocoding object.

Accepts the following named arguments:

=over

=item * I<appid>

A Yahoo Application ID. (required)

An ID can be obtained here:
L<https://developer.apps.yahoo.com/dashboard/createKey.html>

=item * I<ua>

A custom LWP::UserAgent object. (optional)

=item * I<compress>

Enable compression. (default: 1, unless I<debug> is enabled)

=item * I<debug>

Enable debugging. This prints the headers and content for requests and
responses. (default: 0)

=back

=head2 geocode

    $location = $geocoder->geocode(location => $location)
    @locations = $geocoder->geocode(location => $location)

In scalar context, this method returns the first location result; and in
list context it returns all location results.

Accepts the following named arguments:

=over

=item * I<location>

The free-form, single line address to be located. (optional)

=item * I<raw>

Returns the raw data structure converted from the response, not split into
location results.

=back

Any additional arguments will added to the request. See the Yahoo
PlaceFinder documention for the full list of accepted arguments.

By default the following arguments are added:

=over

=item * I<flags>

JRSTX

=item * I<gflags>

AC

=back

Example of the data structure representing a location result:

    {
        areacode    => 408,
        boundingbox => {
            east  => "-122.025092",
            north => "37.416275",
            south => "37.416275",
            west  => "-122.025092",
        },
        city        => "Sunnyvale",
        country     => "United States",
        countrycode => "US",
        county      => "Santa Clara County",
        countycode  => "",
        cross =>
            "Near the intersection of 1st Ave and N Mathilda Ave/Bordeaux Dr",
        hash         => "DDAD1896CC0CDC41",
        house        => 701,
        latitude     => "37.416275",
        line1        => "701 1st Ave",
        line2        => "Sunnyvale, CA  94089-1019",
        line3        => "",
        line4        => "United States",
        longitude    => "-122.025092",
        name         => "",
        neighborhood => "",
        offsetlat    => "37.416397",
        offsetlon    => "-122.025055",
        postal       => "94089-1019",
        quality      => 87,
        radius       => 500,
        state        => "California",
        statecode    => "CA",
        street       => {
            stbody   => "1ST",
            stfull   => "1st Ave",
            stpredir => undef,
            stprefix => undef,
            stsufdir => undef,
            stsuffix => "AVE",
        },
        timezone => "America/Los_Angeles",
        unit     => "",
        unittype => "",
        uzip     => 94089,
        woeid    => 12797150,
        woetype  => 11,
        xstreet  => "",
    }

Example of the data structure returned using the I<raw> option:

    ResultSet => {
        Error        => 0,
        ErrorMessage => "No error",
        Found        => 1,
        Locale       => "us_US",
        Quality      => 60,
        Results      => [ $location ]
        version      => "1.0",
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
