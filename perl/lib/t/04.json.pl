#!/usr/bin/env perl

use strict;
use warnings;

use Qiniu::Utils::JSON;

sub test_json_marshal {
    my $case = shift;
    my $src  = shift;
    my $dst  = shift;

    my $ret = Qiniu::Utils::JSON::qnc_json_marshal($src);
    my $check = $ret eq $dst;
    print "$case: [$dst] [$ret] $check\n";
} # test_json_marshal

test_json_marshal("test_marshal_obj1", {post => undef}, q({"post":null}));
test_json_marshal("test_marshal_obj2", {test => "abc  d", post => {second => 1234}}, q({"test":"abc  d","post":{"second":1234}}));
test_json_marshal("test_marshal_obj3", {test => ["abc  d", 123, undef], post => {second => 1234}}, q({"test":["abc  d",123,null],"post":{"second":1234}}));
test_json_marshal("test_marshal_arr1", ["abc  d", 123, undef], q(["abc  d",123,null]));
test_json_marshal("test_marshal_arr2", ["abc  d", {post => 123.456}, undef], q(["abc  d",{"post":123.456},null]));
test_json_marshal("test_marshal_arr3", ["abc  d", ["post", 123.456], undef], q(["abc  d",["post",123.456],null]));

sub test_json_unmarshal_object {
    my $case = "test_unmarshal_object";
    my $str = '{"type":"string", "time":123.456, "post":null, "arr":["1","2","3"], "obj":{"first":"1","second":2,"third":3}}';
    my ($val, $err) = Qiniu::Utils::JSON::qnc_json_unmarshal($str);
    if (defined($err)) {
        print "$case : [$err] 0\n";
        return;
    }
    if (not exists($val->{type})) {
        print "$case : [first key not exists] 0\n";
    }
    if ($val->{type} ne 'string') {
        print "$case : [first value is not correct] 0\n";
    }
    if (not exists($val->{time})) {
        print "$case : [second key not exists] 0\n";
    }
    if ($val->{time} != 123.456) {
        print "$case : [second value is not correct] 0\n";
    }
    if (not exists($val->{arr})) {
        print "$case : [fourth key not exists] 0\n";
    }
    if ($val->{arr}[0] ne "1") {
        print "$case : [array first key is not correct] 0\n";
    }
    if ($val->{arr}[2] ne "3") {
        print "$case : [array third key is not correct] 0\n";
    }
    if ($val->{obj}{second} != 2) {
        print "$case : [object second key is not correct] 0\n";
    }

    print "$case : 1\n";
} # test_json_unmarshal_object

test_json_unmarshal_object();

sub test_json_unmarshal_array {
    my $case = "test_unmarshal_array";
    my $str = '["string", -123.456, null, ["1","2","3"], {"first":"1","second":2,"third":3}]';
    my ($val, $err) = Qiniu::Utils::JSON::qnc_json_unmarshal($str);
    if (defined($err)) {
        print "$case : [$err] 0\n";
        return;
    }
    if ($val->[0] ne "string") {
        print "$case : [first element is not correct] 0\n";
    }
    if ($val->[1] != -123.456) {
        print "$case : [second element is not correct] 0\n";
    }
    if ($val->[3][0] ne "1") {
        print "$case : [array first element is not correct] 0\n";
    }
    if ($val->[3][2] ne "3") {
        print "$case : [array third element is not correct] 0\n";
    }
    if ($val->[4]{second} != 2) {
        print "$case : [object second value is not correct] 0\n";
    }

    print "$case : 1\n";
} # test_json_unmarshal_array

test_json_unmarshal_array();
