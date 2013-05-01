#!/usr/bin/env perl

##############################################################################
#
# Easy Qiniu Perl SDK
#
# Module: Qiniu/Easy/RS.pm
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

use Qiniu::Utils::Base64;
use Qiniu::Utils::HTTPClient;

use Qiniu::Easy::Conf;

sub new {
    my $class = shift || __PACKAGE__;
    my $args = shift || {};
    my $self = {
        access_key => (defined($args->{access_key})) ?
                      $args->{access_key}            :
                      Qiniu::Easy::Conf::ACCESS_KEY,
        secret_key => (defined($args->{secret_key})) ?
                      $args->{secret_key}            :
                      Qiniu::Easy::Conf::SECRET_KEY,
    };
    $self->{client} = Qiniu::Utils::HTTPClient->new({
        access_key => $self->{access_key},
        secret_key => $self->{secret_key},
    });
    return bless $self, $class;
} # new

sub stat {
    my $self = shift;
    my $args = shift || {};

    my $url = Qiniu::Easy::Conf::RS_HOST . uri_stat($args);
    my $ret = $self->{client}->call($url);
    my $stat_ret = {
        hash      => (defined($ret->{hash}))     ? $ret->{hash}     : "",
        fsize     => (defined($ret->{fsize}))    ? $ret->{fsize}    : 0,
        put_time  => (defined($ret->{putTime}))  ? $ret->{putTime}  : 0,
        mime_type => (defined($ret->{mimeType})) ? $ret->{mimeType} : "",
        customer  => (defined($ret->{customer})) ? $ret->{customer} : "",
    };
    return $stat_ret, undef;
} # stat

sub delete {
    my $self = shift;
    my $args = shift || {};

    my $url = Qiniu::Easy::Conf::RS_HOST . uri_delete($args);
    my ($ret, $err) = $self->{client}->call($url);
    return $ret, $err;
} # delete

sub move {
    my $self = shift;
    my $args = shift || {};
    my $url = Qiniu::Easy::Conf::RS_HOST . uri_move($args);
    my ($ret, $err) = $self->{client}->call($url);
    return $ret, $err;
} # move

sub copy {
    my $self = shift;
    my $args = shift || {};
    my $url = Qiniu::Easy::Conf::RS_HOST . uri_copy($args);
    my ($ret, $err) = $self->{client}->call($url);
    return $ret, $err;
} # copy

sub uri_stat {
    my $args = shift;
    my $id = Qiniu::Utils::Base64::encode_url(
        "$args->{bucket}:$args->{key}"
    );
    return "/stat/${id}";
} # uri_stat

sub uri_delete {
    my $args = shift;
    my $id =  Qiniu::Utils::Base64::encode_url(
        "$args->{bucket}:$args->{key}"
    );
    return "/delete/${id}";
} # uri_delete

sub uri_copy {
    my $args = shift;
    my $src_id = Qiniu::Utils::Base64::encode_url(
        "$args->{src_bucket}:$args->{src_key}"
    );
    my $dst_id = Qiniu::Utils::Base64::encode_url(
        "$args->{dst_bucket}:$args->{dst_key}"
    );
    return "/copy/${src_id}/${dst_id}";
} # uri_copy

sub uri_move {
    my $args = shift;
    my $src_id = Qiniu::Utils::Base64::encode_url(
        "$args->{src_bucket}:$args->{src_key}"
    );
    my $dst_id = Qiniu::Utils::Base64::encode_url(
        "$args->{dst_bucket}:$args->{dst_key}"
    );
    return "/move/${src_id}/${dst_id}";
} # uri_move

1;

__END__
