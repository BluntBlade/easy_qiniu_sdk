#!/usr/bin/env perl

use strict;
use warnings;

use Qiniu::Utils::SHA1;
use Qiniu::Utils::HMAC;

sub test_hmac_sha1 {
    my $case = shift;
    my $key  = shift;
    my $src  = shift;
    my $dst  = shift;

    my $ret = eqs_crypto_hmac(Qiniu::Utils::SHA1->new(), $key, $src);
    $ret = join("", map { sprintf("%02x", ord($_)) } split("", $ret));
    my $check = $ret eq $dst;
    print "$case: [$dst] [$ret] $check\n";
} # test_hmac_sha1

test_hmac_sha1("test_empty", "", "", "fbdb1d1b18aa6c08324b7d64b71fb76370690e1d");
test_hmac_sha1("test_key", "key", "The quick brown fox jumps over the lazy dog", "de7c9b85b8b78aa6bc8a7a36f70a90701c9db4d9");
