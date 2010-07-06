#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper;
use Geo::Coder::PlaceFinder;

unless ($ENV{YAHOO_APPID}) {
    die "YAHOO_APPID environment variable must be set";
}
my $location = join(' ', @ARGV) || die "Usage: $0 \$location_string";

# Custom useragent identifier.
my $ua = LWP::UserAgent->new(agent => 'My Geocoder');

# Load any proxy settings from environment variables.
$ua->env_proxy;

my $geocoder = Geo::Coder::PlaceFinder->new(
    appid => $ENV{YAHOO_APPID},
    ua    => $ua,
    debug => 1,
);
my $result = $geocoder->geocode(location => $location);

local $Data::Dumper::Indent = 1;
print Dumper($result);
