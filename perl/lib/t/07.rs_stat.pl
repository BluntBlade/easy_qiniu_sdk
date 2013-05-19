#!/usr/bin/env perl

use strict;
use warnings;

use Qiniu::Easy::RS;

my $access_key = shift @ARGV;
my $secret_key = shift @ARGV;
my $bucket     = shift @ARGV;
my $key        = shift @ARGV;

my $rs = Qiniu::Easy::RS->new($access_key, $secret_key);
my ($val, $code, $phrase) = $rs->stat($bucket, $key);

print "code=[${code}]\n";
print "phrase=[${phrase}]\n";

if ($code == 499) {
    exit(1);
}
if (defined($val->{error})) {
    print "error=[$val->{error}]\n";
    exit(1);
}

print "hash=[$val->{hash}]\n";
print "fsize=[$val->{fsize}]\n";
print "put_time=[$val->{putTime}]\n";

$val->{mimeType} ||= q{};
print "mime_type=[$val->{mimeType}]\n";
$val->{customer} ||= q{};
print "customer=[$val->{customer}]\n";
