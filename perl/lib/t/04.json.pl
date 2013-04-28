#!/usr/bin/env perl

use strict;
use warnings;

use Qiniu::Utils::JSON;

sub test_json_marshal {
    my $case = shift;
    my $src  = shift;
    my $dst  = shift;

    my $ret = Qiniu::Utils::JSON::eqs_json_marshal($src);
    my $check = $ret eq $dst;
    print "$case: [$dst] [$ret] $check\n";
} # test_json_marshal

test_json_marshal("test_marshal_hash1", {post => undef}, q({"post":null}));
test_json_marshal("test_marshal_hash2", {test => "abc  d", post => {second => 1234}}, q({"test":"abc  d","post":{"second":1234}}));
test_json_marshal("test_marshal_hash3", {test => ["abc  d", 123, undef], post => {second => 1234}}, q({"test":["abc  d",123,null],"post":{"second":1234}}));
test_json_marshal("test_marshal_arr1", ["abc  d", 123, undef], q(["abc  d",123,null]));
test_json_marshal("test_marshal_arr2", ["abc  d", {post => 123.456}, undef], q(["abc  d",{"post":123.456},null]));
test_json_marshal("test_marshal_arr3", ["abc  d", ["post", 123.456], undef], q(["abc  d",["post",123.456],null]));
