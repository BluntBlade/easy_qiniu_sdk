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
use Qiniu::Utils::JSON;
use Qiniu::Utils::HTTP::Client;
use Qiniu::Utils::MIME::Multipart;

use Qiniu::Easy::Conf;

sub put {
    my $uptoken = shift;
    my $key     = shift;
    my $data    = shift;
    my $extra   = shift;

    ######
    my $bucket = $extra->{bucket};

    # 可选。在 uptoken 没有指定 DetectMime 时，用户客户端可自己指定 MimeType
    my $mt     = $extra->{mime_type}       || $extra->{mimeType};
    
    # 可选。用户自定义 Meta，不能超过 256 字节
    my $meta   = $extra->{custom_meta}     || $extra->{customMeta};

    # 当 uptoken 指定了 CallbackUrl，则 CallbackParams 必须非空
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
        my $encoded_mt = Qiniu::Utils::Base64::encode_url($mt);
        $action .= "/mimeType/${encoded_mt}";
    }
    if (defined($meta) && $meta ne q{}) {
        my $encoded_meta = Qiniu::Utils::Base64::encode_url($meta);
        $action .= "/meta/${encoded_meta}";
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
    
    my $new_data = undef;
    my $data_type = ref($new_data);
    if ($data_type eq q{}) {
        my $done = undef;
        $new_data = {
            read => sub {
                if ($done) {
                    return q{};
                }
                $done = 1;
                return $data;
            },
        };
    } elsif ($data_type eq q{CODE}) {
        $new_data = {
            read => $data,
        }
    } elsif ($data_type eq q{HASH}) {
        $new_data = $data;
    } else {
        return undef, 499, q{Invalid data type};
    }
    my $source_done = undef;
    my $source = {
        read => sub {
            if ($source_done) {
                return q{};
            }

            my $content = $multipart->read();
            if ($content ne q{}) {
                return $content;
            }

            my ($chunk, $err) = $new_data->{read}->();
            if (defined($err)) {
                return undef, $err;
            }

            if ($chunk ne q{}) {
                $err = $buf->{write}->($chunk);
                if (defined($err)) {
                    return undef, $err;
                }
            } else {
                $source_done = 1;
                $multipart->end();
            }

            $content = $multipart->read();
            return $content;
        },
    };

    (my $resp, $err) = Qiniu::Utils::HTTP::Client::default_post(
        Qiniu::Easy::Conf::UP_HOST . '/upload',
        $source,
        $multipart->content_type()
    );

    if (defined($err)) {
        return undef, 499, $err;
    }

    my $body = join "", @{$resp->{body}};
    my ($val, $err2) = Qiniu::Utils::JSON::unmarshal($body);
    if (defined($err2)) {
        return undef, 499, $err2;
    }
    return $val, $resp->{code}, $resp->{phrase};
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
