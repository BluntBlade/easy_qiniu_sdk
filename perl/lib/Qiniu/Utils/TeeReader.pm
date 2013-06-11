#!/usr/bin/env perl

##############################################################################
#
# Easy Qiniu Perl SDK
#
# Module: Qiniu/Utils/TeeReader.pm
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  amethyst.black@gmail.com
#         liangtao@qiniu.com
#
##############################################################################

package Qiniu::Utils::TeeReader;

sub new {
    my $class = shift || __PACKAGE__;
    my $in    = shift;
    my $out   = shift;
    my $self  = {
        in      => $in,
        out     => $out,
        in_type => ref($in),

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

    my $data = undef;
    my $err  = undef;

    if ($self->{in_type} eq q{HASH}) {
        ($data, $err) = $self->{in}{read}($bytes);
    } else {
        ($data, $err) = $self->{in}->read($bytes);
    }
    if (defined($err)) {
        return undef, $err;
    }

    my $read_bytes = length($data);
    if ($read_bytes > 0) {
        $self->{out}->write($data);
    }

    if ($read_bytes == 0) {
        $self->{done} = 1;
    }

    return $data, undef;
} # read

1;

__END__
