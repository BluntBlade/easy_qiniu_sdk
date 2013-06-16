#!/usr/bin/env perl

##############################################################################
#
# Easy Qiniu Perl SDK
#
# Module: Qiniu/Utils/SectionReader.pm
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  amethyst.black@gmail.com
#         liangtao@qiniu.com
#
##############################################################################

package Qiniu::Utils::SectionReader;

use strict;
use warnings;

sub new {
    my $class  = shift || __PACKAGE__;
    my $in     = shift;
    my $offset = shift;
    my $total  = shift;
    my $self   = {
        in        => $in,
        offset    => $offset,
        total     => $total,
        in_type   => ref($in),

        begin     => $offset,
        remainder => $total,
        done      => undef,
    };
    return bless $self, $class;
} # new

sub read {
    my $self  = shift;
    my $bytes = shift || 4096;

    if ($self->{done}) {
        return q{}, undef;
    }

    if ($bytes > $self->{remainder}) {
        $bytes = $self->{remainder};
    }

    my $data = undef;
    my $err  = undef;

    if ($self->{in_type} eq q{HASH}) {
        ($data, $err) = $self->{in}{read_at}($self->{begin}, $bytes);
    } else {
        ($data, $err) = $self->{in}->read_at($self->{begin}, $bytes);
    }
    if (defined($err)) {
        return undef, $err;
    }

    my $read_bytes = length($data);
    if ($read_bytes > 0) {
        $self->{begin}     += $read_bytes;
        $self->{remainder} -= $read_bytes;

        if ($self->{remainder} == 0) {
            $self->{done} = 1;
        }
    } else {
        $self->{done} = 1;
    }
    
    return $data, undef;
} # read

1;

__END__
