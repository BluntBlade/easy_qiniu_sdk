#!/usr/bin/env perl

##############################################################################
#
# Easy Qiniu Perl SDK
#
# Module: Qiniu/Utils/MIME/Multipart.pm
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  amethyst.black@gmail.com
#         liangtao@qiniu.com
#
# Wiki:   http://en.wikipedia.org/wiki/MIME#Multipart_subtypes
#         http://tools.ietf.org/html/rfc2388
#
##############################################################################

package Qiniu::Utils::MIME::Multipart;

use strict;
use warnings;

use English;

use Qiniu::Utils::SHA1;

my $gen_boundary = sub {
    my $ts = time();
    srand($ts % $PID);
    my $rand = int(rand(65535)) . "$PID";
    my $boundary = join "", map {
        sprintf("%08X", $_)
    } unpack("N" x 5, Qiniu::Utils::SHA1->new()->sum($rand));
    return $boundary;
}; # gen_boundary

sub new {
    my $class = shift || __PACKAGE__;
    my $self = {
        done     => undef,
        parts    => [],
        boundary => $gen_boundary->(),
    };
    return bless $self, $class;
} # new

use constant LINEBREAK => qq{\r\n};

sub field {
    my $self  = shift;
    my $name  = shift;
    my $value = shift;
    my $extra = shift || {};

    my $headers = $extra->{headers} || {};

    my $content_type = $headers->{content_type};
    my $content_transfer_encoding = $headers->{content_transfer_encoding};

    if (defined($content_type) and
        $content_type =~ m,application/x-www-form-urlencoded,io) {
        $value =~ s/([!#\$&'\(\)*+,\/:;=?@\[\]])/sprintf("%%%02X", ord($1))/goe;
    }

    my $part  = "";
    $part .= q{--} . $self->{boundary} . LINEBREAK;
    $part .= qq(Content-Disposition: form-data; name="${name}") . LINEBREAK;
    if (defined($content_type)) {
        $part .= qq(Content-Type: ${content_type}) . LINEBREAK;
    }
    if (defined($content_transfer_encoding)) {
        $part .= qq(Content-Transfer-Encoding: ${content_transfer_encoding})
               . LINEBREAK;
    }
    $part .= LINEBREAK;
    $part .= $value . LINEBREAK;

    push @{$self->{parts}}, $part;
    return undef;
} # field

sub form_file {
    my $self  = shift;
    my $name  = shift;
    my $value = shift;
    my $data  = shift;
    my $extra = shift || {};

    my $headers = $extra->{headers} || {};

    my $content_type = $headers->{content_type} || q{application/octet-stream};
    my $content_transfer_encoding = $headers->{content_transfer_encoding}
                                 || q{binary};

    my $part  = "";
    $part .= q{--} . $self->{boundary} . LINEBREAK;
    $part .= qq(Content-Disposition: form-data;)
           . qq( name="${name}";)
           . qq( filename="${value}")
           . LINEBREAK;
    $part .= qq(Content-Type: ${content_type}) . LINEBREAK;
    $part .= qq(Content-Transfer-Encoding: ${content_transfer_encoding})
           . LINEBREAK;
    $part .= LINEBREAK;

    push @{$self->{parts}}, $part;
    push @{$self->{parts}}, $data;

    return undef;
} # form_file

sub read {
    my $self  = shift;
    my $bytes = shift || 4096;

    if ($self->{done}) {
        return q{}, undef;
    }
    if (scalar(@{$self->{parts}}) == 0) {
        $self->{done} = 1;
        my $part = LINEBREAK . q{--} . $self->{boundary} . q{--} . LINEBREAK;
        return $part, undef;
    }

    my $part_type = ref($self->{parts}[0]);
    if ($part_type eq q{HASH}) {
        my ($part, $err) = $self->{parts}[0]{read}->($bytes);
        if (defined($err)) {
            return undef, $err;
        }

        if ($part eq q{}) {
            if (exists($self->{parts}[0]{close})) {
                $self->{parts}[0]{close}->();
            }
            shift @{$self->{parts}};
            return $self->read($bytes);
        }

        return $part, undef;
    }

    my $part = (shift @{$self->{parts}}) || q{};
    return $part;
} # read

sub content_type {
    my $self = shift;
    return q{multipart/form-data; boundary=} . $self->{boundary};
} # content_type

1;

__END__
