#!/usr/bin/perl

use Modern::Perl '2015';

use FindBin;
use File::Spec::Functions qw(catfile);

undef $/;
my $in = <>;

$in =~ s/CN=(.*?);/CN="$1";/gs;
$in =~ s/^RECURRENCE-ID;TZID=.*?:(\d{8})T\d{6}(?=\s)/RECURRENCE-ID:$1T000000Z/mg;

open(my $out, "|-", catfile($FindBin::RealBin, "dist/build/confluence-ical-fixer/confluence-ical-fixer")) or die $!;
print $out $in;
