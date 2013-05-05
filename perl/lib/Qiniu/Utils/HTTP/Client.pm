#!/usr/bin/env perl

##############################################################################
#
# Easy Qiniu Perl SDK
#
# Module: Qiniu/Utils/HTTP/Client.pm
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  amethyst.black@gmail.com
#         liangtao@qiniu.com
#
##############################################################################

package Qiniu::Utils::HTTP::Client;

use strict;
use warnings;

use Qiniu::Utils::HTTP::Transport;

my $call = sub {
    my $self   = shift;
    my $method = shift;
    my $url    = shift;
    my $body   = shift;
    my $ct     = shift;

    if ($url !~ m,^(?:https?://)?([^/]+)(.*)$,o) {
        return undef, qq{Invalid URL. [$url]};
    }

    my $peer = $1;
    my $uri  = $2;

    my ($host, $port) = split(/:/, $peer, 2);
    my ($path, $query_str) = split(/[?]/, $uri, 2);

    my $req = {
        method  => uc($method),
        url     => {
            raw       => $url,
            host      => $host,
            port      => $port || q{80},
            path      => $path || q{/},
            query_str => $query_str,
        },
        headers => {
            'Host'         => [$host],
            'User-Agent'   => [q{Easy-Qiniu-Perl-SDK/0.1}],
            'Connection'   => [q{Close}],
        },
    };

    if (defined($ct)) {
        $req->{headers}{'Content-Type'} = [$ct];
    }

    if (defined($body)) {
        if (ref($body) eq 'HASH') {
            $req->{body} = $body;
        }
        if (ref($body) eq q{}) {
            $body = "${body}";
            if ($body ne q{}) {
                $req->{headers}{'Content-Length'} = [length($body)];
                $req->{body} = {
                    read => sub {
                        return $body, undef;
                    },
                };
            }
        }
    } elsif ($method eq q{GET}) {
        $req->{headers}{'Content-Length'} = [q{0}];
    }

    my ($resp, $err) = $self->{tr}->round_trip($req);
    return $resp, $err;
}; # call

sub new {
    my $class = shift || __PACKAGE__;
    my $tr = shift || Qiniu::Utils::HTTP::Transport->new();
    my $self = {
        tr => $tr,
    };
    return bless $self, $class;
} # new

sub get {
    my $self = shift;
    my $url  = shift;
    return $self->$call(q{GET}, $url);
} # get

sub post {
    my $self = shift;
    my $url  = shift;
    my $body = shift;
    my $ct   = shift || q{application/octet-stream};
    return $self->$call(q{POST}, $url, $body, $ct);
} # post

sub default_get {
    my $client = __PACKAGE__->new();
    return $client->get(@_);
} # default_get

sub default_post {
    my $client = __PACKAGE__->new();
    return $client->post(@_);
} # default_post

1;

__END__
