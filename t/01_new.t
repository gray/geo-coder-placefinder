use strict;
use warnings;
use Test::More tests => 6;
use Geo::Coder::PlaceFinder;

new_ok('Geo::Coder::PlaceFinder' => ['Your App ID']);
new_ok('Geo::Coder::PlaceFinder' => ['Your App ID', debug => 1]);
new_ok('Geo::Coder::PlaceFinder' => [appid => 'Your App ID']);
new_ok('Geo::Coder::PlaceFinder' => [appid => 'Your App ID', debug => 1]);

{
    local $@;
    eval {
        my $geocoder = Geo::Coder::PlaceFinder->new(debug => 1);
    };
    like($@, qr/^'appid' is required/, 'appid is required');
}

can_ok('Geo::Coder::PlaceFinder', qw(geocode response ua));
