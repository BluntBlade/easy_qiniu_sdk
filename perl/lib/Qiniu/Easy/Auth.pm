#!/usr/bin/env perl

##############################################################################
#
# Easy Qiniu Perl SDK
#
# Module: Qiniu/Easy/Auth.pm
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  amethyst.black@gmail.com
#         liangtao@qiniu.com
#
##############################################################################

package Qiniu::Easy::RS;

use strict;
use warnings;

our @ISA = qw(Exporter);
our @EXPORT = qw(
    eqs_rs_sign
    eqs_rs_sign_json
);

use Qiniu::Utils::JSON;
use Qiniu::Utils::Base64;
use Qiniu::Utils::HMAC;
use Qiniu::Utils::SHA1;

sub eqs_rs_sign {
    return &sign;
} # eqs_rs_sign

sub eqs_rs_sign_json {
    return &sign_json;
} # eqs_rs_sign_json

# Qiniu authorization sign (count in Bytes)
#
# | len(key)   | 1 | 28                        | 1 | len(buf)               |
# | access key | : | base64 url encoded digest | : | base64 url encoded buf |

sub sign {
    my $access_key = shift;
    my $secret_key = shift;
    my $buf        = shift;

    my $encoded_buf = Qiniu::Utils::Base64::encode_url($buf);
    my $hmac = Qiniu::Utils::HMAC->new(
        Qiniu::Utils::SHA1->new(),
        $secret_key
    );

    $hmac->write($encoded_buf);
    my $digest = $hmac->sum();
    my $encoded_digest = Qiniu::Utils::Base64::encode_url($digest);

    return "${access_key}:${encoded_digest}:${encoded_buf}", undef;
} # sign

sub sign_json {
    my $access_key = shift;
    my $secret_key = shift;
    my $obj        = shift;

    my $buf = Qiniu::Utils::JSON::marshal($obj);
    return sign($access_key, $secret_key, $buf);
} # sign_json

1;

__END__
