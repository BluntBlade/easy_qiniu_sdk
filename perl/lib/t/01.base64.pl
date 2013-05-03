#!/usr/bin/env perl

use strict;
use warnings;

use Qiniu::Utils::Base64;

my $text = "Man is distinguished, not only by his reason, but by this singular passion from other animals, which is a lust of the mind, that by a perseverance of delight in the continued and indefatigable generation of knowledge, exceeds the short vehemence of any carnal pleasure.";
my $encoded_text = "TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlz\r\nIHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlciBhbmltYWxzLCB3aGljaCBpcyBhIGx1c3Qgb2Yg\r\ndGhlIG1pbmQsIHRoYXQgYnkgYSBwZXJzZXZlcmFuY2Ugb2YgZGVsaWdodCBpbiB0aGUgY29udGlu\r\ndWVkIGFuZCBpbmRlZmF0aWdhYmxlIGdlbmVyYXRpb24gb2Yga25vd2xlZGdlLCBleGNlZWRzIHRo\r\nZSBzaG9ydCB2ZWhlbWVuY2Ugb2YgYW55IGNhcm5hbCBwbGVhc3VyZS4=";

sub test_base64_encode_mime {
    my $case = shift;
    my $src  = shift;
    my $dst  = shift;

    my $ret = Qiniu::Utils::Base64::qnc_base64_encode_mime($src);
    my $check = $ret eq $dst;
    print "$case: [$dst] [$ret] $check\n";
} # test_base64_encode_mime

sub test_base64_decode_mime {
    my $case = shift;
    my $src  = shift;
    my $dst  = shift;

    my $ret = Qiniu::Utils::Base64::qnc_base64_decode_mime($src);
    my $check = $ret eq $dst;
    print "$case: [$dst] [$ret] $check\n";
} # test_base64_decode_mime

test_base64_encode_mime("encode_mime_long", $text, $encoded_text);
test_base64_encode_mime("encode_mime_1", "", "");
test_base64_encode_mime("encode_mime_2", "H", "SA==");
test_base64_encode_mime("encode_mime_3", "He", "SGU=");
test_base64_encode_mime("encode_mime_4", "Hel", "SGVs");
test_base64_encode_mime("encode_mime_5", "Hell", "SGVsbA==");
test_base64_encode_mime("encode_mime_6", "Hello", "SGVsbG8=");
test_base64_encode_mime("encode_mime_7", "Hello\0", "SGVsbG8A");
test_base64_encode_mime("encode_mime_8", "\xff\xff\xff\xff", "/////w==");
test_base64_encode_mime("encode_mime_9", "f", "Zg==");
test_base64_encode_mime("encode_mime_10", "fo", "Zm8=");
test_base64_encode_mime("encode_mime_11", "foo", "Zm9v");
test_base64_encode_mime("encode_mime_12", "foob", "Zm9vYg==");
test_base64_encode_mime("encode_mime_13", "fooba", "Zm9vYmE=");
test_base64_encode_mime("encode_mime_14", "foobar", "Zm9vYmFy");

test_base64_decode_mime("decode_mime_long", $encoded_text, $text);
test_base64_decode_mime("decode_mime_1", "", "");
test_base64_decode_mime("decode_mime_2", "SA==", "H");
test_base64_decode_mime("decode_mime_3", "SGU=", "He");
test_base64_decode_mime("decode_mime_4", "SGVs", "Hel");
test_base64_decode_mime("decode_mime_5", "SGVsbA==", "Hell");
test_base64_decode_mime("decode_mime_6", "SGVsbG8=", "Hello");
test_base64_decode_mime("decode_mime_7", "SGVsbG8A", "Hello\0");
test_base64_decode_mime("decode_mime_8", "/////w==", "\xff\xff\xff\xff");
test_base64_decode_mime("decode_mime_9", "Zg==", "f");
test_base64_decode_mime("decode_mime_10", "Zm8=", "fo");
test_base64_decode_mime("decode_mime_11", "Zm9v", "foo");
test_base64_decode_mime("decode_mime_12", "Zm9vYg==", "foob");
test_base64_decode_mime("decode_mime_13", "Zm9vYmE=", "fooba");
test_base64_decode_mime("decode_mime_14", "Zm9vYmFy", "foobar");
