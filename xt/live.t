use strict;
use warnings;
use Encode qw(decode encode);
use Geo::Coder::PlaceFinder;
use Test::More;

unless ($ENV{YAHOO_APPID}) {
    plan skip_all => 'YAHOO_APIPID environment variable must be set';
}
else {
    plan tests => 8;
}

my $debug = $ENV{GEO_CODER_PLACEFINDER_DEBUG};
unless ($debug) {
    diag "Set GEO_CODER_PLACEFINDER_DEBUG to see request/response data";
}

my $geocoder = Geo::Coder::PlaceFinder->new(
    appid => $ENV{YAHOO_APPID},
    debug => $debug,
);

{
    my $address = 'Hollywood & Highland, Los Angeles, CA';
    my $location = $geocoder->geocode($address);
    is($location->{postal}, 90028, "correct zip code for $address");
}
{
    my @locations = $geocoder->geocode('Main Street, Los Angeles, CA');
    ok(@locations > 1, 'there are many Main Streets in Los Angeles, CA');
}
{
    my $address = qq(Ch\xE2teau d Uss\xE9, 37420);

    my $location = $geocoder->geocode($address);
    ok($location, 'latin1 bytes');
    is($location->{countrycode}, 'FR', 'latin1 bytes');

    $location = $geocoder->geocode(location => decode('latin1', $address));
    ok($location, 'UTF-8 characters');
    is($location->{countrycode}, 'FR', 'UTF-8 characters');

    $location = $geocoder->geocode(
        location => encode('utf-8', decode('latin1', $address))
    );
    ok($location, 'UTF-8 bytes');
    is($location->{countrycode}, 'FR', 'UTF-8 bytes');
}
