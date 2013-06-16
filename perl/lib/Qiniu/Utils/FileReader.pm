#!/usr/bin/env perl

##############################################################################
#
# Easy Qiniu Perl SDK
#
# Module: Qiniu/Utils/FileReader.pm
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  amethyst.black@gmail.com
#         liangtao@qiniu.com
#
##############################################################################

package Qiniu::Utils::FileReader;

use strict;
use warnings;

use English;

use IO::Handle;
use IO::File;

sub new {
    my $class = shift || __PACKAGE__;
    my $in    = shift;
    my $self  = {
        done => undef,
    };

    my $in_type = ref($in);
    if ($in_type eq q{SCALAR} or $in_type eq q{}) {

        $self->{in} = IO::File->open($in, "<");
        if (not defined($self->{in})) {
            warn "${OS_ERROR}";
        }

    } elsif ($in_type eq q{IO}) {

        $self->{in} = IO::Handle->new();
        my $ret = $self->{in}->fdopen(fileno($in));
        if (not defined($ret)) {
            warn "${OS_ERROR}";
        }

    } elsif ($in_type eq q{IO::File} or $in_type eq q{IO::Handle}) {

        $self->{in} = $in;

    } else {
        warn "Not a valid file."
    }

    $self->{in}->binmode();
    return bless $self, $class;
} # new

sub close {
    my $self = shift;
    if ($self->{done}) {
        return;
    }
    $self->{in}->close();
    $self->{done} = 1;
} # close

sub read_at {
    my $self   = shift;
    my $offset = shift;
    my $bytes  = shift || 4096;

    if ($self->{done}) {
        return q{}, undef;
    }

    my $data       = undef;
    my $read_bytes = $self->{in}->sysread($data, $bytes, $offset);
    if (not defined($read_bytes)) {
        return undef, "${OS_ERROR}";
    }

    return $data, undef;
} # read_at

sub read {
    my $self  = shift;
    my $bytes = shift || 4096;

    if ($self->{done}) {
        return q{}, undef;
    }

    my $data       = undef;
    my $read_bytes = $self->{in}->sysread($data, $bytes);
    if (not defined($read_bytes)) {
        return undef, "${OS_ERROR}";
    }

    return $data, undef;
} # read

1;

__END__
