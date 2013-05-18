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

use Qiniu::Easy::Auth;
use Qiniu::Easy::Conf;

### OOP methods
sub new {
    my $class = shift || __PACKAGE__;
    my $access_key = shift || Qiniu::Easy::Conf::ACCESS_KEY;
    my $secret_key = shift || Qiniu::Easy::Conf::SECRET_KEY;
    my $self = {
        access_key => $access_key,
        secret_key => $secret_key,
    };
    $self->{client} = Qiniu::Easy::Auth::new_client(
        $access_key,
        $secret_key,
    );
    return bless $self, $class;
} # new

sub stat {
    my $self   = shift;
    my $bucket = shift;
    my $key    = shift;

    my $url = Qiniu::Easy::Conf::RS_HOST . uri_stat($bucket, $key);
    my ($ret, $err) = $self->{client}->get($url);
    if (defined($err)) {
        return $ret, $err;
    }

    my ($val, $err2) = Qiniu::Utils::JSON::unmarshal($ret);
    return $val, $err2;
} # stat

sub delete {
    my $self   = shift;
    my $bucket = shift;
    my $key    = shift;

    my $url = Qiniu::Easy::Conf::RS_HOST . uri_delete($bucket, $key);
    my ($ret, $err) = $self->{client}->get($url);
    if (defined($err)) {
        return $ret, $err;
    }

    my ($val, $err2) = Qiniu::Utils::JSON::unmarshal($ret);
    return $val, $err2;
} # delete

sub move {
    my $self       = shift;
    my $src_bucket = shift;
    my $src_key    = shift;
    my $dst_bucket = shift;
    my $dst_key    = shift;

    my $url = Qiniu::Easy::Conf::RS_HOST
            . uri_move($src_bucket, $src_key, $dst_bucket, $dst_key);
    my ($ret, $err) = $self->{client}->get($url);
    if (defined($err)) {
        return $ret, $err;
    }

    my ($val, $err2) = Qiniu::Utils::JSON::unmarshal($ret);
    return $val, $err2;
} # move

sub copy {
    my $self       = shift;
    my $src_bucket = shift;
    my $src_key    = shift;
    my $dst_bucket = shift;
    my $dst_key    = shift;

    my $url = Qiniu::Easy::Conf::RS_HOST
            . uri_copy($src_bucket, $src_key, $dst_bucket, $dst_key);
    my ($ret, $err) = $self->{client}->get($url);
    if (defined($err)) {
        return $ret, $err;
    }

    my ($val, $err2) = Qiniu::Utils::JSON::unmarshal($ret);
    return $val, $err2;
} # copy

sub batch {
    my $self = shift;
    my $op   = shift;
    my $url = Qiniu::Easy::Conf::RS_HOST . '/batch';
    my ($ret, $err) = $self->{client}->post_form($url, {op => $op});
    if (defined($err)) {
        return $ret, $err;
    }

    my ($val, $err2) = Qiniu::Utils::JSON::unmarshal($ret);
    return $val, $err2;
} # batch

sub batch_stat {
    my $self    = shift;
    my $entries = shift;
    my $op = map { uri_stat($_->{bucket}, $_->{key}) } @{$entries};
    return $self->batch($op);
} # batch_stat

sub batch_delete {
    my $self    = shift;
    my $entries = shift;
    my $op = map { uri_delete($_->{bucket}, $_->{key}) } @{$entries};
    return $self->batch($op);
} # batch_delete

sub batch_copy {
    my $self    = shift;
    my $entries = shift;
    my $op = map {
        uri_copy($_->{src_bucket},$_->{src_key},$_->{dst_bucket},$_->{dst_key})
    } @{$entries};
    return $self->batch($op);
} # batch_copy

sub batch_move {
    my $self    = shift;
    my $entries = shift;
    my $op = map {
        uri_move($_->{src_bucket},$_->{src_key},$_->{dst_bucket},$_->{dst_key})
    } @{$entries};
    return $self->batch($op);
} # batch_move

### module functions
sub uri_stat {
    my $bucket = shift;
    my $key    = shift;
    my $id = Qiniu::Utils::Base64::encode_url("${bucket}:${key}");
    return "/stat/${id}";
} # uri_stat

sub uri_delete {
    my $bucket = shift;
    my $key    = shift;
    my $id = Qiniu::Utils::Base64::encode_url("${bucket}:${key}");
    return "/delete/${id}";
} # uri_delete

sub uri_copy {
    my $src_bucket = shift;
    my $src_key    = shift;
    my $dst_bucket = shift;
    my $dst_key    = shift;

    my $src_id = Qiniu::Utils::Base64::encode_url("${src_bucket}:${src_key}");
    my $dst_id = Qiniu::Utils::Base64::encode_url("${dst_bucket}:${dst_key}");
    return "/copy/${src_id}/${dst_id}";
} # uri_copy

sub uri_move {
    my $src_bucket = shift;
    my $src_key    = shift;
    my $dst_bucket = shift;
    my $dst_key    = shift;

    my $src_id = Qiniu::Utils::Base64::encode_url("${src_bucket}:${src_key}");
    my $dst_id = Qiniu::Utils::Base64::encode_url("${dst_bucket}:${dst_key}");
    return "/move/${src_id}/${dst_id}";
} # uri_move

sub token_for_get {
    my $args = shift;
    my $policy = {};

    if (defined($args->{scope})) {
        $policy->{S} = $args->{scope};
    }

    if (defined($args->{expires})) {
        $policy->{E} = $args->{expires} + time();
    }

    my $access_key = $args->{access_key} || Qiniu::Easy::Conf::ACCESS_KEY;
    my $secret_key = $args->{secret_key} || Qiniu::Easy::Conf::SECRET_KEY;
    my $token = Qiniu::Easy::Auth::sign_json($access_key,$secret_key,$policy);
    return $token;
} # token_for_get

sub token_for_put {
    my $args = shift;
    my $policy = {};

    if (defined($args->{scope})) {
        $policy->{scope} = $args->{scope};
    }

    if (defined($args->{expires})) {
        $policy->{expires} = $args->{expires} + time();
    }

    if (defined($args->{callback_url})) {
        $policy->{callback_url} = $args->{callback_url};
    } elsif (defined($args->{callbackUrl})) {
        $policy->{callback_url} = $args->{callbackUrl};
    }

    if (defined($args->{callback_body_type})) {
        $policy->{callback_body_type} = $args->{callback_body_type};
    } elsif (defined($args->{callbackBodyType})) {
        $policy->{callback_body_type} = $args->{callbackBodyType};
    }

    if (defined($args->{async_ops})) {
        $policy->{async_ops} = $args->{async_ops};
    } elsif (defined($args->{asyncOps})) {
        $policy->{async_ops} = $args->{asyncOps};
    }

    if (defined($args->{customer})) {
        $policy->{customer} = $args->{customer};
    }

    if (defined($args->{escape})) {
        $policy->{escape} = $args->{escape};
    }

    if (defined($args->{detect_mime})) {
        $policy->{detect_mime} = $args->{detect_mime};
    } elsif (defined($args->{detectMime})) {
        $policy->{detect_mime} = $args->{detectMime};
    }

    my $access_key = $args->{access_key} || Qiniu::Easy::Conf::ACCESS_KEY;
    my $secret_key = $args->{secret_key} || Qiniu::Easy::Conf::SECRET_KEY;
    my $token = Qiniu::Easy::Auth::sign_json($access_key, $secret_key, $policy);
    return $token;
} # token_for_put

1;

__END__
