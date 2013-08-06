#!/usr/bin/env perl

##############################################################################
#
# Easy Qiniu Perl SDK
#
# Module: Qiniu/Easy/UP.pm
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  liangtao@qiniu.com
#         amethyst.black@gmail.com
#
##############################################################################

package Qiniu::Easy::UP;

use strict;
use warnings;

use Qiniu::Utils::JSON;
use Qiniu::Utils::Base64;
use Qiniu::Utils::CRC32;

use Qiniu::Utils::ByteReader;
use Qiniu::Utils::SectionReader;
use Qiniu::Utils::TeeReader;
use Qiniu::Utils::FileReader;

use Qiniu::Utils::HTTP::Transport;
use Qiniu::Utils::HTTP::Client;

use Qiniu::Easy::Conf;

use constant INVALID_CTX => 701;
use constant BLOCK_BITS  => 22;
use constant BLOCK_SIZE  => (1 << BLOCK_BITS);
use constant CHUNK_SIZE  => 256 * 1024;

my $settings = {
    workers    => 1,
    chunk_size => CHUNK_SIZE,
    try_times  => 3,
    notify     => sub { return 1; },
    notify_err => sub { return 1; },
};

sub set_settings {
    my $v = shift;
    
    if (defined($v->{workers}) and $v->{workers} > 0) {
        $settings->{workers} = $v->{workers};
    }

    my $chunk_size = $v->{chunk_size} || $v->{chunkSize};
    if (defined($chunk_size) and $chunk_size > 0) {
        $settings->{chunk_size} = $chunk_size;
    }

    my $try_times = $v->{try_times} || $v->{tryTimes};
    if (defined($try_times) and $try_times > 0) {
        $settings->{try_times} = $try_times;
    }

    if (defined($v->{notify}) and ref($v->{notify}) eq q{CODE}) {
        $settings->{notify} = $v->{notify};
    }

    my $notify_err = $v->{notify_err} || $v->{notifyErr};
    if (defined($notify_err) and ref($notify_err) eq q{CODE}) {
        $settings->{notify_err} = $notify_err;
    }
} # set_settings

my $round_trip = sub {
    my $self = shift;
    my $req  = shift;
    $req->{headers} ||= {};
    $req->{headers}{Authorization} = ["UpToken $self->{token}"];
    return $self->round_trip($req);
}; # round_trip

sub new_transport {
    my $token = shift;
    my $tr = {
        token      => $token,
        round_trip => $round_trip,
    };
    return Qiniu::Utils::HTTP::Transport->new($tr);
} # new_transport

sub new_client {
    my $tr = &new_transport;
    my $client = Qiniu::Utils::HTTP::Client->new($tr);
    return $client;
} # new_client

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

sub mkblock {
    my $client   = shift;
    my $blk_size = shift;
    my $body     = shift;
    my $size     = shift;
    my $up_host  = shift;

    my ($resp, $err) = $client->post(
        $up_host . "/mkblk/${blk_size}",
        $body,
        "application/octet-stream",
    );
    
    my ($ret, $code, $phrase) = $parse_resp->($resp, $err);
    return $ret, $code, $phrase;
} # mkblock

sub blockput {
    my $client   = shift;
    my $last_ret = shift;
    my $body     = shift;
    my $size     = shift;
    
    my ($resp, $err) = $client->post(
        "$last_ret->{host}/bput/$last_ret->{ctx}/$last_ret->{offset}",
        $body,
        "application/octet-stream",
    );

    (my $ret, my $code, $err) = $parse_resp->($resp, $err);
    return $ret, $code, $err;
} # blockput

my $save_ret = sub {
    my $prog = shift;
    my $ret  = shift;

    $prog->{ctx}      = $ret->{ctx};
    $prog->{checksum} = $ret->{checksum};
    $prog->{crc32}    = $ret->{crc32};
    $prog->{offset}   = $ret->{offset};
    $prog->{host}     = $ret->{host};
}; # $save_ret

sub resumable_blockput {
    my $client   = shift;
    my $prog     = shift;
    my $f        = shift;
    my $blk_idx  = shift;
    my $blk_size = shift;
    my $extra    = shift || {};

    my $up_host = $extra->{up_host} || Qiniu::Easy::Conf::UP_HOST;

    my $h = Qiniu::Utils::CRC32->new();
    my $off_base = $blk_idx << BLOCK_BITS;
    my $chk_size = $extra->{chunk_size} || $extra->{chunkSize} || CHUNK_SIZE;

    my $body_len = 0;
    if (not defined($prog->{ctx}) or $prog->{ctx} eq q{}) {
        if ($chk_size < $blk_size) {
            $body_len = $chk_size;
        } else {
            $body_len = $blk_size;
        }

        my $body1 = Qiniu::Utils::SectionReader->new($f, $off_base, $body_len);
        my $body  = Qiniu::Utils::TeeReader->new($body1, $h);

        my ($ret, $code, $phrase) = mkblock($client, $blk_size, $body, $body_len, $up_host);
        if ($code >= 400) {
            return $ret, $code, $phrase;
        }
        my $crc32 = $h->sum();
        if ($ret->{crc32} != $crc32 || $ret->{offset} != $body_len) {
            return $ret, 499, "unmatched checksum";
        }

        if (ref($extra->{notify}) eq q{CODE}) {
            my $continue = $extra->{notify}->($blk_idx, $blk_size, $ret);
            if (not defined($continue)) {
                return $ret, $code, $phrase;
            }
        }

        $save_ret->($prog, $ret);
    }

    my $try_times = $extra->{try_times} || $extra->{tryTimes} || 3;
    while ($prog->{offset} < $blk_size) {
        if ($chk_size < $blk_size - $prog->{offset}) {
            $body_len = $chk_size;
        } else {
            $body_len = $blk_size - $prog->{offset};
        }

        for (my $i = 0; $i < $try_times + 1; ++$i) {
            $h->reset();

            my $body1 = Qiniu::Utils::SectionReader->new(
                $f,
                $off_base + $prog->{offset},
                $body_len
            );
            my $body  = Qiniu::Utils::TeeReader->new($body1, $h);

            my ($ret, $code, $phrase) = blockput($client, $prog, $body, $body_len);
            if ($code >= 400) {
                return $ret, $code, $phrase;
            }
            
            if ($code == INVALID_CTX) {
                return $ret, $code, "ResumableBlockput: invalid ctx, please retry";
            }

            if ($i == $try_times + 1) {
                return $ret, $code, $phrase;
            }

            if ($code != 200) {
                # Retry bput
                next;
            }
            if ($ret->{crc32} != $h->sum()) {
                # Retry bput
                next;
            }

            $save_ret->($prog, $ret);
            last;
        } # for
    } # while

    return $prog, 200, undef;
} # resumable_blockput

sub mkfile {
    my $client = shift;
    my $key    = shift;
    my $fsize  = shift;
    my $extra  = shift;

    my $up_host = $extra->{up_host} || Qiniu::Easy::Conf::UP_HOST;

    my $entry = "$extra->{bucket}:${key}";
    my $url = $up_host
            . "/rs-mkfile/"
            . Qiniu::Utils::Base64::encode_url($entry)
            . "/fsize/${fsize}";

    my $mt = $extra->{mime_type} || $extra->{mimeType};
    if (defined($mt) and $mt eq q{}) {
        $url .= "/mimeType/" . Qiniu::Utils::Base64::encode_url($mt);
    }

    my $custom = $extra->{custom_meta} || $extra->{customMeta};
    if (defined($custom) and $custom eq q{}) {
        $url .= "/meta/" . Qiniu::Utils::Base64::encode_url($custom);
    }

    my $params = $extra->{callback_params} || $extra->{callbackParams};
    if (defined($params) and $params eq q{}) {
        $url .= "/params/" . Qiniu::Utils::Base64::encode_url($params);
    }

    my $buf  = join(",", map { $_->{ctx} } @{$extra->{progresses}});
    my $body = Qiniu::Utils::ByteReader->new($buf);
    my ($resp, $err) = $client->post($url, $body, "text/plain");
    my ($ret, $code, $phrase) = $parse_resp->($resp, $err);
    return $ret, $code, $phrase;
} # mkfile

my $put_one_block = sub {
    my $client   = shift;
    my $f        = shift;
    my $blk_idx  = shift;
    my $blk_size = shift;
    my $prog     = shift;
    my $extra    = shift;

    my $try_times = $extra->{try_times} || $extra->{tryTimes} || 3;
    my $ret       = undef;
    my $code      = undef;
    my $phrase    = undef;
    for (my $i = 0; $i < $try_times + 1; ++$i) {
        ($ret, $code, $phrase) = resumable_blockput(
            $client,
            $prog,
            $f,
            $i,
            $blk_size,
            $extra,
        );
        if ($code >= 400) {
            my $continue = $extra->{notify_err}->($blk_idx, $blk_size, $phrase);
            if (not defined($continue)) {
                return $ret, $code, $phrase;
            }
            next;
        }

        return $ret, 200, undef;
    } # for

    return $ret, $code, $phrase;
}; # $put_one_block

my $put_serially = sub {
    my $client  = shift;
    my $key     = shift;
    my $f       = shift;
    my $fsize   = shift;
    my $blk_cnt = shift;
    my $extra   = shift;
    
    my $sent_size = 0;
    for (my $i = 1; $i <= $blk_cnt; ++$i) {
        my $blk_size = ($i < $blk_cnt) ? BLOCK_SIZE : ($fsize - $sent_size);
        my ($ret, $code, $phrase) = $put_one_block->(
            $client,
            $f,
            $i,
            $blk_size,
            $extra->{progresses}[$i - 1],
            $extra,
        );
        if ($code >= 400) {
            return $code, $phrase;
        }
        $sent_size += $blk_size;
    } # for
    return 200, undef;
}; # $put_serially

my $put_parallel = sub {
}; # $put_parallel

sub block_count {
    my $fsize = shift;
    return ($fsize + (BLOCK_SIZE - 1)) >> BLOCK_BITS;
} # block_count

sub put {
    my $uptoken = shift;
    my $key     = shift;
    my $f       = shift;
    my $fsize   = shift;
    my $extra   = shift || {};

    my $blk_cnt = block_count($fsize);
    if (not defined($extra->{progresses})) {
        $extra->{progresses} = [];
        for (my $i = 0; $i < $blk_cnt; ++$i) {
            push @{$extra->{progresses}}, {};
        } # for
    } elsif (scalar(@{$extra->{progresses}}) != $blk_cnt) {
        return undef, "invalid put progress";
    }

    $extra->{chunk_size} ||= $settings->{chunk_size};
    $extra->{try_times}  ||= $settings->{try_times};
    $extra->{notify}     ||= $settings->{notify};
    $extra->{notify_err} ||= $settings->{notify_err};

    my $client = new_client($uptoken);
    my $code   = undef;
    my $phrase = undef;
    if ($settings->{workers} == 1) {
        ($code, $phrase) =
            $put_serially->($client, $key, $f, $fsize, $blk_cnt, $extra);
    } else {
        ($code, $phrase) =
            $put_parallel->($client, $key, $f, $fsize, $blk_cnt, $extra);
    }
    if ($code >= 400) {
        return undef, $code, $phrase;
    }

    return mkfile($client, $key, $fsize, $extra);
} # put

sub put_file {
    my $uptoken    = shift;
    my $key        = shift;
    my $local_file = shift;
    my $extra      = shift;

    my $f = Qiniu::Utils::FileReader->new($local_file);
    return put($uptoken, $key, $f, $f->size(), $extra);
} # put_file

1;

__END__
