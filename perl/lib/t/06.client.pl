#!/usr/bin/env perl

use strict;
use warnings;

use Qiniu::Utils::HTTP::Client;

my ($resp, $err) = Qiniu::Utils::HTTP::Client::default_get('www.163.com');
if (defined($err)) {
    print STDERR "error=[$err]\n";
    exit(1);
}

print join "", @{$resp->{body_data}};
print "\n";
