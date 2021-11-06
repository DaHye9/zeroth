#!/usr/bin/perl

use encoding 'utf-8';

use JSON;
use Data::Dumper;
#binmode STDOUT, ":utf8";

my $file = $ARGV[0];

chmod 0755, $file;

open $jsonfile, $file or die "Can't open json file: $!";
sysread($jsonfile, my $text, -s $jsonfile);
close $jsonfile or die "Can't close json file: $!";

my $json = decode_json($text);
my $gen = $json->{'dataSet'}{'typeInfo'}{'speakers'}[0]{'gender'};
#my $gen="여";
#print ($gen);
if($gen eq '여'){
    print("f");
} else {
    print("m");
}
