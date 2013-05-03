#!/usr/bin/env perl

##############################################################################
#
# Easy Qiniu Perl SDK
#
# Module: Qiniu/Utils/SHA1.pm
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  amethyst.black@gmail.com
#         liangtao@qiniu.com
#
# Wiki:   http://en.wikipedia.org/wiki/SHA-1
#
##############################################################################

package Qiniu::Utils::SHA1;

use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
    qnc_crypto_sha1
);

sub qnc_crypto_sha1 {
    my $msg = shift;
    my $sha1 = __PACKAGE__->new();
    return $sha1->sum($msg);
} ## qnc_crypto_sha1

use constant CHUNK_SIZE   => 64;
use constant MSG_PADDING  => "\x80" . ("\x0" x 63);
use constant ZERO_PADDING => "\x0" x 56;

my $left_rotate = sub {
    my $val  = shift;
    my $bits = shift;
    return (($val << $bits) & 0xFFFFFFFF) | ($val >> (32 - $bits));
}; # left_rotate

my $mod_add = sub {
    my $sum = 0;
    foreach my $val (@_) {
        $sum += $val;
        $sum &= 0xFFFFFFFF;
    } # foreach
    return $sum;
}; # mod_add

my $calc = sub {
    my $self = shift;
    my $msg  = shift;

    my @w = unpack("N" x 16, $msg);
    for (my $i = 16; $i < 80; $i += 1) {
        $w[$i] = $left_rotate->(
            ($w[$i-3] ^ $w[$i-8] ^ $w[$i-14] ^ $w[$i-16]),
            1,
        );
    } # for

    my $a = $self->{hash}[0];
    my $b = $self->{hash}[1];
    my $c = $self->{hash}[2];
    my $d = $self->{hash}[3];
    my $e = $self->{hash}[4];

    my ($f, $k) = (0, 0);
    for (my $i = 0; $i < 80; $i += 1) {
        if (0 <= $i and $i <= 19) {
            $f = ($b & $c) | (((~$b) & 0xFFFFFFFF) & $d);
            $k = 0x5A827999;
        }
        if (20 <= $i and $i <= 39) {
            $f = $b ^ $c ^ $d;
            $k = 0x6ED9EBA1;
        }
        if (40 <= $i and $i <= 59) {
            $f = ($b & $c) | ($b & $d) | ($c & $d);
            $k = 0x8F1BBCDC;
        }
        if (60 <= $i and $i <= 79) {
            $f = $b ^ $c ^ $d;
            $k = 0xCA62C1D6;
        }

        my $temp = $mod_add->(
            $left_rotate->($a, 5),
            $f,
            $e,
            $k,
            $w[$i],
        );
        $e = $d;
        $d = $c;
        $c = $left_rotate->($b, 30);
        $b = $a;
        $a = $temp;
    } # for

    $self->{hash}[0] = $mod_add->($self->{hash}[0], $a);
    $self->{hash}[1] = $mod_add->($self->{hash}[1], $b);
    $self->{hash}[2] = $mod_add->($self->{hash}[2], $c);
    $self->{hash}[3] = $mod_add->($self->{hash}[3], $d);
    $self->{hash}[4] = $mod_add->($self->{hash}[4], $e);
}; # calc

sub new {
    my $class = shift || __PACKAGE__;
    my $self = {};
    bless $self, $class;
    $self->reset();
    return $self;
} # new

sub write {
    my $self = shift;
    my $msg  = shift;

    if (not defined($msg) or ref($msg) ne q{}) {
        return;
    }

    $self->{origin_len} += length($msg);
    $msg = $self->{remainder} . $msg;
    $self->{remainder} = "";

    my $data_len = length($msg);
    if ($data_len < CHUNK_SIZE) {
        $self->{remainder} = $msg;
        return $self;
    }

    for (my $pos = 0; $pos < $data_len; $pos += CHUNK_SIZE) {
        if ($data_len - $pos < CHUNK_SIZE) {
            $self->{remainder} = substr($msg, $pos);
            last;
        }
        $self->$calc(substr($msg, $pos, CHUNK_SIZE));
    } # for

    return $self;
} # write

sub sum {
    my $self = shift;
    my $msg  = shift;

    $self->write($msg);
    my $last_data = $self->{remainder} . MSG_PADDING;

    if (CHUNK_SIZE < (length($self->{remainder}) + 1 + 8)) {
        $self->$calc(substr($last_data, 0, CHUNK_SIZE));
        $last_data = ZERO_PADDING;
    }
    else {
        $last_data = substr($last_data, 0, 56);
    }
    my $origin_bits_len = $self->{origin_len} * 8;
    $last_data .= pack("N", ($origin_bits_len >> 32) & 0xFFFFFFFF);
    $last_data .= pack("N", $origin_bits_len & 0xFFFFFFFF);
    $self->$calc($last_data);
    return join("", map { pack("N", $_) } @{$self->{hash}});
} # sum

sub reset {
    my $self = shift;
    $self->{origin_len} = 0;
    $self->{remainder}  = "";

    $self->{hash} = [
        0x67452301,
        0xEFCDAB89,
        0x98BADCFE,
        0x10325476,
        0xC3D2E1F0,
    ];
    return $self;
} # reset

sub chunk_size {
    return CHUNK_SIZE;
} # chunk_size

1;

__END__
