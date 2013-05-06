#!/usr/bin/env perl

##############################################################################
#
# Easy Qiniu Perl SDK
#
# Module: Qiniu/Utils/HTTP/Transport.pm
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  amethyst.black@gmail.com
#         liangtao@qiniu.com
#
##############################################################################

package Qiniu::Utils::HTTP::Transport;

use strict;
use warnings;

use English;
use IO::Socket::INET;

my $upcase = sub {
    my $str = shift;
    $str =~ s/^([a-z])/uc($1)/e;
    $str =~ s/(-[a-z])/uc($1)/ge;
    return $str;
}; # upcase

my $parse_response_body = undef;
$parse_response_body = sub {
    my $state_data = shift;
    my $data       = shift;
    my $resp       = shift;

    if (not defined($data)) {
        return undef, undef;
    }


    if ($state_data->{remainder} ne q{}) {
        push @{$resp->{body_data}}, $state_data->{remainder};
        $resp->{body_length} += length($state_data->{remainder});
        $state_data->{remainder} = q{};
    }

    if ($data ne q{}) {
        push @{$resp->{body_data}}, $data;
        $resp->{body_length} += length($data);
    }
    return $parse_response_body, undef;
}; # parse_response_body

my $parse_response_headers = undef;
$parse_response_headers = sub {
    my $state_data = shift;
    my $data       = shift;
    my $resp       = shift;

    if (not defined($data)) {
        return undef, qq{Invalid response};
    }

    my $remainder = $state_data->{remainder} .= $data;
    while (1) {
        if ($remainder =~ m/\G([-\w]+):[ \t]*([^\r\n]+)\r?\n/gmoc) {
            my $h = $upcase->($1);
            my $v = $2;
            $resp->{headers}{$h} ||= [];
            push @{$resp->{headers}{$h}}, $v;
            $state_data->{prev_header} = $h;

            if ($h eq q{Content-Length}) {
                $state_data->{content_length} = $v;
            }
            next;
        }
        if ($remainder =~ m/\G([ \t]+)([^\r\n]+)\r?\n/gmoc) {
            my $h = $state_data->{prev_header};
            my $v = $1;
            if (defined($h)) {
                push @{$resp->{headers}{$h}}, $v;
            } else {
                return undef, qq{Invalid response};
            }
        }
        if ($remainder =~ m/\G\r?\n/gmoc) {
            $state_data->{remainder} = q{};
            $data = substr($remainder, pos($remainder));
            return $parse_response_body->($state_data, $data, $resp);
        }
        last;
    } # while

    my $pos = pos($remainder);
    if (defined($pos) and $pos > 0) {
        $state_data->{remainder} = substr($remainder, $pos);
    }
    return $parse_response_headers, undef;
}; # parse_response_headers

my $parse_response_line = undef;
$parse_response_line = sub {
    my $state_data = shift;
    my $data       = shift;
    my $resp       = shift;

    if (not defined($data)) {
        return undef, qq{Invalid response};
    }

    my $remainder = $state_data->{remainder} .= $data;
    if ($remainder !~ m,^HTTP/(\d+)[.](\d+),gmoc) {
        return $parse_response_line, undef;
    }
    $resp->{major} = $1;
    $resp->{minor} = $2;

    if ($remainder !~ m,\s+(\d{3})\s+([^\r\n]*)\r?\n,gmoc) {
        return $parse_response_line, undef;
    }
    $resp->{code}  = $1;
    $resp->{msg}   = $2;

    $state_data->{remainder} = q{};
    $data = substr($remainder, pos($remainder));
    return $parse_response_headers->($state_data, $data, $resp);
}; # parse_response_line

sub new {
    my $class = shift || __PACKAGE__;
    my $self  = shift || {};
    return bless $self, $class;
} # new

use constant LINEBREAK => qq{\r\n};

sub round_trip {
    my $self = shift;
    my $req  = shift;

    my $package = (caller(1))[0] || q{};
    if ($package ne __PACKAGE__ and $self->{round_trip}) {
        return $self->{round_trip}->($self, $req);
    }

    my $host    = $req->{url}{host} || "";
    my $port    = $req->{url}{port}   || "";
    my $path    = $req->{url}{path}   || "";
    my $headers = $req->{headers}     || {};
    my $body    = $req->{body};

    my $socket = IO::Socket::INET->new(
        PeerHost => $host,
        PeerPort => $port,
        Proto    => q{tcp},
    );

    if (not defined($socket->connected())) {
        $socket->close();
        return undef, qq{Failed to connect to server. [$host]};
    }

    my $method = uc($req->{method});
    $socket->send(qq(${method} ${path} HTTP/1.1) . LINEBREAK);

    foreach my $h (keys(%{$headers})) {
        my $vs = $headers->{$h};
        my $oh = $upcase->($h);
        foreach my $v (@{$vs}) {
            $socket->send(qq(${oh}: $v) . LINEBREAK);
        } # foreach
    } # foreach

    $socket->send(LINEBREAK);

    if (defined($body) and defined($body->{read})) {
        while (my ($data, $read) = $body->{read}->(4096)) {
            my $sent = $socket->send($data);
            if (not defined($sent)) {
                $socket->close();
                return undef, qq(${OS_ERROR} [$host]);
            }
        } # while
    }

    my $err        = undef;
    my $state      = $parse_response_line;
    my $state_data = {
        remainder => q{},
    };
    my $resp       = {
        headers     => {},
        body_data   => [],
        body_length => 0,
    };

    my $buf = q{};
    while (1) {
        my $peer_addr = $socket->recv($buf, 65536);
        if (not defined($peer_addr)) {
            $err = qq(${OS_ERROR});
            last;
        }
        if ($buf eq q{}) {
            last;
        }
        ($state, $err) = $state->($state_data, $buf, $resp);
        if (defined($err) or not defined($state)) {
            last;
        }

        if (not defined($state_data->{content_length})) {
            next;
        }
        if ($resp->{body_length} < $state_data->{content_length}) {
            next;
        }
        last;
    } # while
    $state->($state_data, undef, $resp);
    $socket->close();

    return $resp, $err;
} # round_trip

1;

__END__
