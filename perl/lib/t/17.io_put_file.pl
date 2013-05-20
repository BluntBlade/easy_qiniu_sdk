#!/usr/bin/env perl

use strict;
use warnings;

use Qiniu::Easy::RS;
use Qiniu::Easy::IO;

my $access_key = shift @ARGV;
my $secret_key = shift @ARGV;
my $bucket     = shift @ARGV;
my $key        = shift @ARGV;
my $file       = shift @ARGV;

my $policy = {
    scope => $bucket,
    deadline => 3600 * 9,
};
my $uptoken = Qiniu::Easy::RS::token_for_put(
    $access_key,
    $secret_key,
    $policy,
);

my $extra = {
    bucket    => $bucket,
    mime_type => q{text/plain},
};
my ($ret, $code, $phrase) = Qiniu::Easy::IO::put_file(
    $uptoken,
    $key,
    $file,
    $extra,
);

print "code=[${code}]\n";
print "phrase=[${phrase}]\n";

if ($code == 499) {
    exit(1);
}
if (defined($ret->{error})) {
    print "error=[$ret->{error}]\n";
    exit(1);
}

print "hash=[$ret->{hash}]\n";
$ret->{fsize} ||= q{};
print "fsize=[$ret->{fsize}]\n";
$ret->{putTime} ||= q{};
print "put_time=[$ret->{putTime}]\n";

$ret->{mimeType} ||= q{};
print "mime_type=[$ret->{mimeType}]\n";
$ret->{customer} ||= q{};
print "customer=[$ret->{customer}]\n";
