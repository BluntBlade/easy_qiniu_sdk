#!/usr/bin/env perl

##############################################################################
#
# Easy Qiniu Perl SDK
#
# Module: Qiniu/Easy/UP.pm
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  amethyst.black@gmail.com
#         liangtao@qiniu.com
#
##############################################################################

package Qiniu::Easy::UP;

use strict;
use warnings;

use Qiniu::Utils::JSON;
use Qiniu::Utils::SectionReader;
use Qiniu::Utils::TeeReader;
use Qiniu::Utils::HTTP::Transport;
use Qiniu::Utils::HTTP::Client;

use Qiniu::Easy::Conf;

use constant INVALID_CTX => 701;
use constant BLOCK_BITS  => 22;
use constant CHUNK_SIZE  => 256 * 1024;

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

    my ($resp, $err) = $client->call(
        Qiniu::Easy::Conf::UP_HOST . "/mkblk/${blk_size}",
        "application/octet-stream",
        $body,
        $size
    );
    
    (my $ret, my $code, $err) = $parse_resp->($resp, $err);
    return $ret, $code, $err;
} # mkblock

sub blockput {
    my $client   = shift;
    my $last_ret = shift;
    my $body     = shift;
    my $size     = shift;
    
    my ($resp, $err) = $client->call(
        "$last_ret->{host}/bput/$last_ret->{ctx}/$last_ret->{offset}",
        "application/octet-stream",
        $body,
        $size
    );

    (my $ret, my $code, $err) = $parse_resp->($resp, $err);
    return $ret, $code, $err;
} # blockput

sub resumable_blockput {
    my $client   = shift;
    my $ret      = shift;
    my $f        = shift;
    my $blk_idx  = shift;
    my $blk_size = shift;
    my $extra    = shift || {};

    my $h = Qiniu::Utils::CRC32->new();
    my $off_base = $blk_idx << BLOCK_BITS;
    my $chk_size = $extra->{chunk_size} || $extra->{chunkSize} || CHUNK_SIZE;

    my $body_len = 0;
    if (not defined($ret->{ctx}) or $ret->{ctx} eq q{}) {
        if ($chk_size < $blk_size) {
            $body_len = $chk_size;
        } else {
            $body_len = $blk_size;
        }

        my $body1 = Qiniu::Utils::SectionReader->new($f, $off_base, $body_len);
        my $body  = Qiniu::Utils::TeeReader->new($body1, $h);

        ($ret, my $code, my $err) = mkblock($client, $blk_size, $body, $body_len);
        if (defined($err)) {
            return $ret, $code, $err;
        }
        if ($ret->{crc32} != $h->sum() || $ret->{offset} != $body_len) {
            return $ret, 499, "unmatched checksum";
        }

        if (ref($extra->{notify}) eq q{CODE}) {
            $extra->{notify}->($blk_idx, $blk_size, $ret);
        }
    }

    my $try_times = $extra->{try_times} || $extra->{tryTimes} || 3;
    while ($ret->{offset} < $blk_size) {
        if ($chk_size < $blk_size - $ret->{offset}) {
            $body_len = $chk_size;
        } else {
            $body_len = $blk_size - $ret->{offset};
        }

        for (my $i = 0; $i < $try_times + 1; ++$i) {
            $h->reset();

            my $body1 = Qiniu::Utils::SectionReader->new(
                $f,
                $off_base + $ret->{offset},
                $body_len
            );
            my $body  = Qiniu::Utils::TeeReader->new($body1, $h);

            ($ret, my $code, my $err) = blockput($client, $ret, $body, $body_len);
            if (defined($err)) {
                return $ret, $code, $err;
            }
            
            if ($code == INVALID_CTX) {
                return $ret, $code, "ResumableBlockput: invalid ctx, please retry";
            }
            if ($code != 200) {
                # Retry bput
                next;
            }

            if ($ret->{crc32} != $h->sum()) {
                # Retry bput
                next;
            }

            last;
        } # for
    } # while
} # resumable_blockput

1;

__END__
