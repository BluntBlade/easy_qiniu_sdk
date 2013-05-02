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
}; # gen_boundary

sub new {
    my $class = shift || __PACKAGE__;
    my $self = {
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

    my $content_type = $headers->{content_type}
                    || q{text/plain; charset=utf-8};
    my $content_transfer_encoding = $headers->{content_transfer_encoding}
                                 || q{8bit};

    my $part  = "";
    $part .= q{--} . $self->{boundary} . LINEBREAK;
    $part .= qq(Content-Disposition: form-data; name="${name}") . LINEBREAK;
    $part .= qq(Content-Type: ${content_type}) . LINEBREAK;
    $part .= qq(Content-Transfer-Encoding: ${content_transfer_encoding})
           . LINEBREAK;
    $part .= LINEBREAK;
    $part .= $value . LINEBREAK;

    push @{$self->{parts}}, $part;
    return undef;
} # field

sub form_file {
    my $self  = shift;
    my $name  = shift;
    my $value = shift;
    my $extra = shift || {};

    my $headers = $extra->{headers} || {};

    my $content_type = $headers->{content_type} || q{application/octet-stream};
    my $content_transfer_encoding = $headers->{content_transfer_encoding}
                                 || q{binary};

    my $part  = "";
    $part .= q{--} . $self->{boundary} . LINEBREAK;
    $part .= qq(Content-Disposition: form-data;)
           . qq( name="${name}")
           . qq( filename="${value}")
           . LINEBREAK;
    $part .= qq(Content-Type: ${content_type}) . LINEBREAK;
    $part .= qq(Content-Transfer-Encoding: ${content_transfer_encoding})
           . LINEBREAK;
    $part .= LINEBREAK;

    push @{$self->{parts}}, $part;

    my $buf = {
        write => sub {
            my $data = shift;
            push @{$self->{parts}}, $data;
            return undef;
        },
    };
    return $buf, undef;
} # form_file

sub end {
    my $self = shift;
    push @{$self->{parts}}, q{--} . $self->{boundary} . q{--} . LINEBREAK;
} # end

sub read {
    my $self = shift;
    my $part = (shift @{$self->{parts}}) || q{};
    return $part;
} # read

sub content_type {
    return q{multipart/form-data};
} # content_type

1;

__END__
