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
    my $uptoken = shift;
    my $key     = shift;
    my $data    = shift;
    my $extra   = shift;

    ######
    my $bucket = $extra->{bucket};
    my $mt     = $extra->{mime_type}       || $extra->{mimeType};
    my $meta   = $extra->{custom_meta}     || $extra->{customMeta};
    my $params = $extra->{callback_params} || $extra->{callbackParams};

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

            if ($chunk eq q{}) {
                $multipart->end();
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
    my $uptoken    = shift;
    my $key        = shift;
    my $local_file = shift;
    my $extra      = shift;

    my $err = open(my $fh, "<", $local_file);
    if (not defined($err)) {
        return undef, "$OS_ERROR";
    }
    binmode($fh);

    my $data = {
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

    return put($uptoken, $key, $data, $extra);
} # put_file

1;

__END__
