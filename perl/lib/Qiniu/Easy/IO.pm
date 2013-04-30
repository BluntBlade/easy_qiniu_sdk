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

    my $err       = undef;
    my $multipart = Qiniu::Utils::MIME::Multipart->new();

    $err = $multipart->field("auth", $args->{uptoken});
    if (defined($err)) {
        return undef, $err;
    }

    my $action = '/rs-put/' .
                 Qiniu::Utils::Base64::encode_url(
                     "$args->{bucket}:$args->{key}"
                 );
    if (defined($args->{mime_type}) && $args->{mime_type} ne q{}) {
        $action .= '/mimeType/' .
                   Qiniu::Utils::Base64::encode_url(
                       $args->{mime_type}
                   );
    }
    if (defined($args->{custom_meta}) && $args->{custom_meta} ne q{}) {
        $action .= '/meta/' .
                   Qiniu::Utils::Base64::encode_url(
                       $args->{custom_meta}
                   );
    }
    $err = $multipart->field('action', $action);
    if (defined($err)) {
        return undef, $err;
    }

    if (defined($args->{callback_params}) &&
        $args->{callback_params} ne q{}) {
        $err = $multipart->field('params', $args->{callback_params});
        if (defined($err)) {
            return undef, $err;
        }
    }

    my $buf = undef;
    ($buf, $err) = $multipart->form_file('file', $args->{key});
    if (defined($err)) {
        return undef, $err;
    }
    
    my $source = {
        read => sub {
            my ($chunk, $err) = $args->{data}->read();
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

    my $ret = undef;
    ($ret, $err) = Qiniu::Utils::HTTPClient::post(
        Qiniu::Easy::Conf::UP_HOST . '/upload',
        $multipart->content_type(),
        $source
    );
    return $ret, $err;
} # put

sub put_file {
    my $args = shift;
    my $fh = undef;
    my $err = open($fh, "<", $args->{local_file});
    if (not defined($err)) {
        return "$OS_ERROR";
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
