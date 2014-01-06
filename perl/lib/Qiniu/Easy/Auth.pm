#!/usr/bin/env perl

##############################################################################
#
# Easy Qiniu Perl SDK
#
# Module: Qiniu/Easy/Auth.pm
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  liangtao@qiniu.com
#         amethyst.black@gmail.com
#
##############################################################################

package Qiniu::Easy::Auth;

use strict;
use warnings;

our @ISA = qw(Exporter);
our @EXPORT = qw(
    qnc_rs_sign
    qnc_rs_sign_json
);

use Qiniu::Utils::JSON;
use Qiniu::Utils::Base64;
use Qiniu::Utils::HMAC;
use Qiniu::Utils::SHA1;

use Qiniu::Utils::HTTP::Transport;
use Qiniu::Utils::HTTP::Client;

sub qnc_rs_sign {
    return &sign;
} # qnc_rs_sign

sub qnc_rs_sign_json {
    return &sign_json;
} # qnc_rs_sign_json

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

    return "${access_key}:${encoded_digest}:${encoded_buf}";
} # sign

sub sign_json {
    my $access_key = shift;
    my $secret_key = shift;
    my $obj        = shift;

    my $buf = Qiniu::Utils::JSON::marshal($obj);
    return sign($access_key, $secret_key, $buf);
} # sign_json

sub sign_request {
    my $req        = shift;
    my $secret_key = shift;
    my $inc_body   = shift;

    my $hmac = Qiniu::Utils::HMAC->new(
        Qiniu::Utils::SHA1->new(),
        $secret_key
    );

    my $path = $req->{url}{path};
    $hmac->write($path . "\n");
    if ($inc_body) {
        my $body = $req->{body};
        if (defined($body) and defined($body->{read})) {
            while (1) {
                my ($data, $err) = $body->{read}->(4096);
                if (defined($err)) {
                    return undef, $err;
                }

                if ($data eq q{}) {
                    last;
                }

                $hmac->write($data);
            } # while
        }
        if (defined($body->{reset})) {
            $body->{reset}->();
        }
    }

    my $digest = Qiniu::Utils::Base64::encode_url($hmac->sum());
    return $digest;
} # sign_request

sub is_inc_body {
    my $req = shift;
    my $headers = $req->{headers};
    if (not defined($headers)) {
        return undef;
    }
    foreach my $h (keys(%{$headers})) {
        if (uc($h) ne q{CONTENT-TYPE}) {
            next;
        }
        foreach my $v (values(@{$headers->{$h}})) {
            if ($v =~ m,application/x-www-form-urlencoded,i) {
                return 1;
            }
        } # foreach
    } # foreach
    return undef;
} # is_inc_body

sub new_transport {
    my $access_key = shift;
    my $secret_key = shift;
    my $tr = {
        round_trip => sub {
            my $self = shift;
            my $req  = shift;
            if (not defined($req->{headers}{Authorization})) {
                my $digest = sign_request(
                    $req,
                    $secret_key,
                    is_inc_body($req),
                );
                my $token = "${access_key}:${digest}";
                $req->{headers} ||= {};
                $req->{headers}{Authorization} = ["QBox ${token}"];
            }
            return $self->round_trip($req);
        },
    };
    return Qiniu::Utils::HTTP::Transport->new($tr);
} # new_transport

sub new_client {
    my $tr = &new_transport;
    my $client = Qiniu::Utils::HTTP::Client->new($tr);
    return $client;
} # new_client

1;

__END__
