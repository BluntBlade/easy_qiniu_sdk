#!/usr/bin/env perl

##############################################################################
#
# Easy Qiniu Perl SDK
#
# Module: Qiniu/Easy/FOP.pm
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  amethyst.black@gmail.com
#         liangtao@qiniu.com
#
##############################################################################

package Qiniu::Easy::FOP;

use strict;
use warnings;

use Qiniu::Utils::JSON;
use Qiniu::Utils::HTTP::Client;

sub exif_make_url {
    my $url = shift;
    return $url . '?exif';
} # exif_make_url

sub exif_call {
    my $url = shift;
    my $new_url = exif_make_url($url);
    my ($ret, $err) = Qiniu::Utils::HTTP::Client::get($new_url);
    if (defined($err)) {
        return $ret, $err;
    }

    my ($val, $err2) = Qiniu::Utils::JSON::unmarshal($ret);
    return $val, $err2;
} # exif_call

sub imageinfo_make_url {
    my $url = shift;
    return $url . '?imageInfo';
} # imageinfo_make_url

sub imageinfo_call {
    my $url = shift;
    my $new_url = imageinfo_make_url($url);
    my ($ret, $err) = Qiniu::Utils::HTTP::Client::get($new_url);
    if (defined($err)) {
        return $ret, $err;
    }

    my ($val, $err2) = Qiniu::Utils::JSON::unmarshal($ret);
    return $val, $err2;
} # imageinfo_call

sub view_make_url {
    my $url  = shift;
    my $args = shift;

    my $new_url = $url . '?imageView';
    if (defined($args->{width}) and $args->{width} > 0) {
        $new_url .= '/w/' . $args->{width};
    }
    if (defined($args->{height}) and $args->{height} > 0) {
        $new_url .= '/h/' . $args->{height};
    }
    if (defined($args->{quality}) and $args->{quality} > 0) {
        $new_url .= '/q/' . $args->{quality};
    }
    if (defined($args->{format}) and $args->{format} ne q{}) {
        $new_url .= '/format/' . $args->{format};
    }
    return $new_url;
} # view_make_url

sub view_call {
    my $url  = shift;
    my $args = shift;
    my $new_url = view_make_url($url, $args);
    my ($ret, $err) = Qiniu::Utils::HTTP::Client::get($url);
    if (defined($err)) {
        return $ret, $err;
    }

    my ($val, $err2) = Qiniu::Utils::JSON::unmarshal($ret);
    return $val, $err2;
} # view_call 

1;

__END__
