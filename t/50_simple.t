#!perl -T
use strict;
use warnings;
use Test::More tests => 11;
use LWP::Simple; 
use Data::Dumper; 

use_ok( 'Geo::Coder::PlaceFinder' );

ok(my $g = Geo::Coder::PlaceFinder->new(appid => 'perl-geocoder-test', compress => 0), 'new geocoder');

SKIP: {
   skip 'Requires a network connection allowing HTTP', 5 unless head('http://www.yahoo.com/');

   my $address = 'Hollywood & Highland, Los Angeles, CA';

   ok(my @p = $g->geocode(location => $address), 'geocode');
   ok(@p == 1, 'got just one result');
   is($p[0]->{uzip}, '90028', 'got the right zip');

   ok(my $rs = $g->geocode_to_resultset(location => $address), 'geocode_to_resultset');
   is $rs->{Error}, 0, 'error 0';
   is $rs->{Found}, 1, 'found 1';
   is_deeply $rs->{Results}[0], $p[0], 'matches'
    or warn Dumper($rs);

   @p = $g->geocode(city => 'Springfield');
   ok(@p, 'geocode "Springfield"');
   ok( @p > 5, 'there are many Springfields...');
}
