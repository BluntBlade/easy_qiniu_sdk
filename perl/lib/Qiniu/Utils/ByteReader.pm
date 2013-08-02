#!/usr/bin/env perl

##############################################################################
#
# Easy Qiniu Perl SDK
#
# Module: Qiniu/Utils/ByteReader.pm
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  liangtao@qiniu.com
#         amethyst.black@gmail.com
#
##############################################################################

package Qiniu::Utils::ByteReader;

use strict;
use warnings;

sub new {
    my $class = shift || __PACKAGE__;
    my $in    = shift;
    my $self  = {
        in      => $in,
        pos     => 0,
        len     => length($in),
        done    => undef,
    };
    return bless $self, $class;
} # new

sub read {
    my $self  = shift;
    my $bytes = shift || 4096;

    if ($self->{done}) {
        return q{}, undef;
    }

    my $data = substr($self->{in}, $self->{pos}, $bytes);
    my $read_bytes = length($data);
    if ($read_bytes > 0) {
        $self->{pos} += $read_bytes;
    }

    if ($self->{pos} == $self->{len}) {
        $self->{done} = 1;
    }

    return $data, undef;
} # read

sub read_at {
    my $self   = shift;
    my $offset = shift;
    my $bytes  = shift || 4096;

    my $data = substr($self->{in}, $offset, $bytes);
    return $data, undef;
} # read_at

sub size {
    my $self = shift;
    return $self->{len};
} # size

1;

__END__
