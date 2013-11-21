#!/usr/bin/env perl

##############################################################################
#
# Easy Qiniu Perl SDK
#
# Module: Qiniu/Easy/RS.pm
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  liangtao@qiniu.com
#         amethyst.black@gmail.com
#
##############################################################################

package Qiniu::Easy::RS;

use strict;
use warnings;

use Qiniu::Utils::Base64;

use Qiniu::Utils::Base64;
use Qiniu::Utils::HMAC;
use Qiniu::Utils::SHA1;

use Qiniu::Easy::Auth;
use Qiniu::Easy::Conf;

### OOP methods
sub new {
    my $class      = shift || __PACKAGE__;
    my $access_key = shift || Qiniu::Easy::Conf::ACCESS_KEY;
    my $secret_key = shift || Qiniu::Easy::Conf::SECRET_KEY;
    my $rs_host    = shift || Qiniu::Easy::Conf::RS_HOST;
    my $rsf_host   = shift || Qiniu::Easy::Conf::RSF_HOST;
    my $self = {
        access_key => $access_key,
        secret_key => $secret_key,
        rs_host    => $rs_host,
        rsf_host   => $rsf_host,
    };
    $self->{client} = Qiniu::Easy::Auth::new_client(
        $access_key,
        $secret_key,
    );
    return bless $self, $class;
} # new

my $parse_resp = sub {
    my $resp = shift;
    my $err  = shift;

    if (defined($err)) {
        return undef, 499, $err;
    }

    my $body = join "", @{$resp->{body}};
    my ($val, $err2) = Qiniu::Utils::JSON::unmarshal($body);
    if (defined($err2)) {
        return undef, 499, $err2;
    }
    return $val, $resp->{code}, $resp->{phrase};
}; # $parse_resp

sub stat {
    my $self   = shift;
    my $bucket = shift;
    my $key    = shift;

    my $url = $self->{rs_host} . uri_stat($bucket, $key);
    my ($resp, $err) = $self->{client}->get($url);
    return $parse_resp->($resp, $err);
} # stat

sub delete {
    my $self   = shift;
    my $bucket = shift;
    my $key    = shift;

    my $url = $self->{rs_host} . uri_delete($bucket, $key);
    my ($resp, $err) = $self->{client}->get($url);
    return $parse_resp->($resp, $err);
} # delete

sub move {
    my $self       = shift;
    my $src_bucket = shift;
    my $src_key    = shift;
    my $dst_bucket = shift;
    my $dst_key    = shift;

    my $url = $self->{rs_host}
            . uri_move($src_bucket, $src_key, $dst_bucket, $dst_key);
    my ($resp, $err) = $self->{client}->get($url);
    return $parse_resp->($resp, $err);
} # move

sub copy {
    my $self       = shift;
    my $src_bucket = shift;
    my $src_key    = shift;
    my $dst_bucket = shift;
    my $dst_key    = shift;

    my $url = $self->{rs_host}
            . uri_copy($src_bucket, $src_key, $dst_bucket, $dst_key);
    my ($resp, $err) = $self->{client}->get($url);
    return $parse_resp->($resp, $err);
} # copy

sub batch {
    my $self = shift;
    my $op   = shift;
    my $url = $self->{rs_host} . '/batch';
    my ($resp, $err) = $self->{client}->post_form($url, {op => $op});
    return $parse_resp->($resp, $err);
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

sub list {
    my $self   = shift;
    my $bucket = shift;
    my $limit  = shift;
    my $prefix = shift;

    my $ctx = $self->{list_ctx};
    if (not defined($ctx)) {
        $ctx = $self->{list_ctx} = {};
    }

    if (not defined($ctx->{bucket}) or $ctx->{bucket} ne $bucket) {
        $ctx->{bucket} = $bucket;
        $ctx->{marker} = "";
    }
    if (not defined($ctx->{prefix}) or $ctx->{prefix} ne $prefix) {
        $ctx->{prefix} = $prefix;
        $ctx->{marker} = "";
    }

    my $rsf_host = $self->{rsf_host} || Qiniu::Easy::Conf::RSF_HOST;
    my $url = "${rsf_host}/list?bucket=${bucket}";
    if (defined($prefix) and $prefix ne "") {
        $url .= "&prefix=${prefix}";
    }
    if (defined($limit) and $limit ne "") {
        $url .= "&limit=${limit}";
    }
    if (defined($ctx->{marker}) and $ctx->{marker} ne "") {
        $url .= "&marker=$ctx->{marker}";
    }

    my $access_token = token_for_access(
        $self->{access_key},
        $self->{secret_key},
        {
            url => $url,
        }
    );
    my ($resp, $err) = Qiniu::Utils::HTTP::Client::default_post(
        $url,
        undef,
        "application/x-www-form-urlencoded",
        {
            Authorization => "QBox ${access_token}",
        }
    );
    if (defined($err)) {
        return undef, 499, $err;
    }

    my $body = join "", @{$resp->{body}};
    my ($val, $err2) = Qiniu::Utils::JSON::unmarshal($body);
    if (defined($err2)) {
        return undef, 499, $err2;
    }

    $ctx->{marker} = $val->{marker};
    return $val->{items}, 200, "ok";
} # list

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
    my $access_key = shift;
    my $secret_key = shift;
    my $args       = shift;

    my $policy = {};

    if (defined($args->{scope})) {
        $policy->{S} = $args->{scope};
    }

    if (defined($args->{deadline})) {
        $policy->{E} = $args->{deadline} + time();
    }

    $access_key ||= Qiniu::Easy::Conf::ACCESS_KEY;
    $secret_key ||= Qiniu::Easy::Conf::SECRET_KEY;
    my $token = Qiniu::Easy::Auth::sign_json($access_key,$secret_key,$policy);
    return $token;
} # token_for_get

sub token_for_put {
    my $access_key = shift;
    my $secret_key = shift;
    my $args       = shift;

    my $policy = {};

    if (defined($args->{scope})) {
        $policy->{scope} = $args->{scope};
    }

    if (defined($args->{deadline})) {
        $policy->{deadline} = time() + $args->{deadline};
    } else {
        $policy->{deadline} = time() + 3600;
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

    $access_key ||= Qiniu::Easy::Conf::ACCESS_KEY;
    $secret_key ||= Qiniu::Easy::Conf::SECRET_KEY;
    my $token = Qiniu::Easy::Auth::sign_json($access_key,$secret_key,$policy);
    return $token;
} # token_for_put

sub token_for_access {
    my $access_key = shift;
    my $secret_key = shift;
    my $args       = shift;

    my ($path) = $args->{url} =~ m,^http://[^/]+(.+)$,;
    my $body = $args->{body} || "";

    my $buf = "${path}\n${body}";

    $access_key ||= Qiniu::Easy::Conf::ACCESS_KEY;
    $secret_key ||= Qiniu::Easy::Conf::SECRET_KEY;

    my $hmac = Qiniu::Utils::HMAC->new(
        Qiniu::Utils::SHA1->new(),
        $secret_key
    );

    $hmac->write($buf);
    my $digest = $hmac->sum();
    my $encoded_digest = Qiniu::Utils::Base64::encode_url($digest);
    return "${access_key}:${encoded_digest}";
} # token_for_access

1;

__END__
