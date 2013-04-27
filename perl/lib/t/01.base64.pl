#!/usr/bin/env perl

use strict;
use warnings;

use Qiniu::Utils::Base64;

my $text = "Man is distinguished, not only by his reason, but by this singular passion from other animals, which is a lust of the mind, that by a perseverance of delight in the continued and indefatigable generation of knowledge, exceeds the short vehemence of any carnal pleasure.";
my $encoded_text = "TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlz\r\nIHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlciBhbmltYWxzLCB3aGljaCBpcyBhIGx1c3Qgb2Yg\r\ndGhlIG1pbmQsIHRoYXQgYnkgYSBwZXJzZXZlcmFuY2Ugb2YgZGVsaWdodCBpbiB0aGUgY29udGlu\r\ndWVkIGFuZCBpbmRlZmF0aWdhYmxlIGdlbmVyYXRpb24gb2Yga25vd2xlZGdlLCBleGNlZWRzIHRo\r\nZSBzaG9ydCB2ZWhlbWVuY2Ugb2YgYW55IGNhcm5hbCBwbGVhc3VyZS4=";

sub test_base64_mime {
    my $case = shift;
    my $src  = shift;
    my $dst  = shift;

    my $ret = Qiniu::Utils::Base64::eqs_base64_encode_mime($src);
    my $check = $ret eq $dst;
    print "$case: [$dst] [$ret] $check\n";
} # test_base64_mime

test_base64_mime("long", $text, $encoded_text);

test_base64_mime("1", "", "");
test_base64_mime("2", "H", "SA==");
test_base64_mime("3", "He", "SGU=");
test_base64_mime("4", "Hel", "SGVs");
test_base64_mime("5", "Hell", "SGVsbA==");
test_base64_mime("6", "Hello", "SGVsbG8=");
test_base64_mime("7", "Hello\0", "SGVsbG8A");
test_base64_mime("8", "\xff\xff\xff\xff", "/////w==");
test_base64_mime("9", "f", "Zg==");
test_base64_mime("10", "fo", "Zm8=");
test_base64_mime("11", "foo", "Zm9v");
test_base64_mime("12", "foob", "Zm9vYg==");
test_base64_mime("13", "fooba", "Zm9vYmE=");
test_base64_mime("14", "foobar", "Zm9vYmFy");
