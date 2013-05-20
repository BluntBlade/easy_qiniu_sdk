#!/usr/bin/env perl

use strict;
use warnings;

use Qiniu::Easy::RS;

my $access_key = shift @ARGV;
my $secret_key = shift @ARGV;
my $src_bucket = shift @ARGV;
my $src_key    = shift @ARGV;
my $dst_bucket = shift @ARGV;
my $dst_key    = shift @ARGV;

my $rs = Qiniu::Easy::RS->new($access_key, $secret_key);
my ($ret, $code, $phrase) = $rs->move($src_bucket, $src_key, $dst_bucket, $dst_key);

print "code=[${code}]\n";
print "phrase=[${phrase}]\n";

if ($code == 499) {
    exit(1);
}
if (defined($ret->{error})) {
    print "error=[$ret->{error}]\n";
    exit(1);
}
