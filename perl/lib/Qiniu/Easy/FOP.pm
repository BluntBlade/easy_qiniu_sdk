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

use Qiniu::Utils::HTTPClient;

sub exif_make_url {
    my $url = shift;
    return $url . '?exif';
} # exif_make_url

sub exif_call {
    my $url = shift;
    my ($ret, $err) = Qiniu::Utils::HTTPClient::get(exif_make_url($url));
    return $ret, $err;
} # exif_call

sub imageinfo_make_url {
    my $url = shift;
    return $url . '?imageInfo';
} # imageinfo_make_url

sub imageinfo_call {
    my $url = shift;
    my ($ret, $err) = Qiniu::Utils::HTTPClient::get(
        imageinfo_make_url($url)
    );
    return $ret, $err;
} # imageinfo_call

sub view_make_url {
    my $url  = shift;
    my $args = shift;

    $url .= '?imageView';
    if (defined($args->{width}) and $args->{width} > 0) {
        $url .= '/w/' . $args->{width};
    }
    if (defined($args->{height}) and $args->{height} > 0) {
        $url .= '/h/' . $args->{height};
    }
    if (defined($args->{quality}) and $args->{quality} > 0) {
        $url .= '/q/' . $args->{quality};
    }
    if (defined($args->{format}) and $args->{format} ne q{}) {
        $url .= '/format/' . $args->{format};
    }
} # view_make_url

sub view_call {
    my $url  = shift;
    my $args = shift;
    my ($ret, $err) = Qiniu::Utils::HTTPClient::get(
        view_make_url($url, $args)
    );
    return $ret, $err;
} # view_call 

1;

__END__
