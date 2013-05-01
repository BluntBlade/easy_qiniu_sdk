#!/usr/bin/env perl

##############################################################################
#
# Easy Qiniu Perl SDK
#
# Module: Qiniu/Easy/IO.pm
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  amethyst.black@gmail.com
#         liangtao@qiniu.com
#
##############################################################################

package Qiniu::Easy::IO;

use strict;
use warnings;

use English;

use Qiniu::Utils::Base64;
use Qiniu::Utils::HTTPClient;
use Qiniu::Utils::MIME::Multipart;

use Qiniu::Easy::Conf;

sub put {
    my $args = shift;

    ######
    my $uptoken = "$args->{uptoken}";
    my $bucket  = "$args->{bucket}";
    my $key     = "$args->{key}";
    my $data    = $args->{data};

    my $mt     = $args->{mime_type}       || $args->{mimeType};
    my $meta   = $args->{custom_meta}     || $args->{customMeta};
    my $params = $args->{callback_params} || $args->{callbackParams};

    ######
    my $err       = undef;
    my $multipart = Qiniu::Utils::MIME::Multipart->new();

    ###
    $err = $multipart->field("auth", $uptoken);
    if (defined($err)) {
        return undef, $err;
    }

    ###
    my $id = Qiniu::Utils::Base64::encode_url("$bucket:$key");
    my $action = "/rs-put/${id}";

    if (defined($mt) && $mt ne q{}) {
        my $mt = Qiniu::Utils::Base64::encode_url($mt);
        $action .= "/mimeType/${mt}";
    }
    if (defined($meta) && $meta ne q{}) {
        $meta = Qiniu::Utils::Base64::encode_url($meta);
        $action .= "/meta/${meta}";
    }

    $err = $multipart->field('action', $action);
    if (defined($err)) {
        return undef, $err;
    }

    ###
    if (defined($params) && $params ne q{}) {
        $err = $multipart->field('params', $params);
        if (defined($err)) {
            return undef, $err;
        }
    }

    (my $buf, $err) = $multipart->form_file('file', $key);
    if (defined($err)) {
        return undef, $err;
    }
    
    my $source = {
        read => sub {
            my ($chunk, $err) = $data->read();
            if (defined($err)) {
                return undef, $err;
            }

            $err = $buf->write($chunk);
            if (defined($err)) {
                return undef, $err;
            }

            return $multipart->read();
        },
    };

    (my $ret, $err) = Qiniu::Utils::HTTPClient::post(
        Qiniu::Easy::Conf::UP_HOST . '/upload',
        $multipart->content_type(),
        $source
    );
    return $ret, $err;
} # put

sub put_file {
    my $args = shift;

    my $err = open(my $fh, "<", $args->{local_file});
    if (not defined($err)) {
        return undef, "$OS_ERROR";
    }
    binmode($fh);

    $args->{data} = {
        read => sub {
            my $chunk = q{};
            my $bytes = sysread($fh, $chunk, 4096);
            if (not defined($bytes)) {
                close($fh);
                return undef, "$OS_ERROR";
            }
            if ($bytes == 0) {
                close($fh);
                return q{}, undef;
            }
            return $chunk, undef;
        },
    };

    return put($args);
} # put_file

1;

__END__
