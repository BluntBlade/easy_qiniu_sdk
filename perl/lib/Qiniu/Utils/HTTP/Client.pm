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

use English;

use IO::File;
use Qiniu::Utils::SHA1;
use Qiniu::Utils::HTTP::Transport;

use constant BODY_LIMIT => 1 << 23;

my $mktemp = sub {
    my $template = shift;
    my $dir      = shift;

    my $ts = time();
    srand($ts % $PID);
    my $rand = int(rand(65535)) . "$PID";
    my $xxx = join "", map {
        sprintf("%08X", $_)
    } unpack("N" x 5, Qiniu::Utils::SHA1->new()->sum($rand));

    my $fl = "${dir}/$template}";
    $fl =~ s/(X{6,})/substr($xxx, 0, length($1))/e;

    my $fh = IO::File->new($fl, "rw", 0600);
    return $fh, $fl;
}; # $mktemp

my $load_body = sub {
    my $req  = shift;
    my $body = shift;

    my $body_length = 0;

    my $body_type = ref($body);
    if ($body_type eq q{SCALAR} or $body_type eq q{}) {

        $body = "$body";
        my $new_body = [$body];
        $body = $new_body;

        $body_type = ref($body);

    } elsif ($body_type eq q{HASH} or $body_type eq q{IO} or $body_type =~ m/::/) {

        my $new_body = [];
        my $body_fh  = undef;

        while (1) {
            my $body_piece        = undef;
            my $body_piece_length = 0;
            
            if ($body_type eq q{HASH}) {
                ($body_piece, my $err) = $body->{read}->(4096);
                if (defined($err)) {
                    return $err;
                }

                $body_piece_length = length($body_piece);
            } elsif ($body_type eq q{IO}) {
                $body_piece_length = $body->read($body_piece, 4096);
                if (not defined($body_piece_length)) {
                    $body->close();
                    return "${OS_ERROR}";
                }
            } else {
                ($body_piece, my $err) = $body->read(4096);
                if (defined($err)) {
                    return $err;
                }

                $body_piece_length = length($body_piece);
            }

            if ($body_piece_length == 0) {
                last;
            }

            $body_length += $body_piece_length;
            if ($body_length < BODY_LIMIT) {
                push @{$new_body}, $body_piece;
                next;
            }

            if (not defined($body_fh)) {
                ($body_fh, my $body_fl) = $mktemp->(
                    q{.qnc_upload_file_XXXXXXXXXXXX},
                    q{./}
                );

                if (not defined($body_fh)) {
                    return "${OS_ERROR}";
                }
                unlink($body_fl);

                foreach my $body_piece (@{$new_body}) {
                    my $written = $body_fh->syswrite($body_piece);
                    if (not defined($written)) {
                        $body_fh->close();
                        return "${OS_ERROR}";
                    }
                } # foreach
                undef($new_body);
            }

            my $written = $body_fh->write($body_piece);
            if (not defined($written)) {
                $body_fh->close();
                return "${OS_ERROR}";
            }
        } # while

        if (not defined($body_fh)) {
            $body = $new_body;
        } else {
            $body_fh->seek(0, 0);

            my $body_done = undef;
            $body = sub {
                if ($body_done) {
                    return q{}, undef;
                }

                my $read = $body_fh->read(my $data, 4096);
                if (not defined($read)) {
                    $body_fh->close();
                    return undef, "${OS_ERROR}";
                }
                if ($read == 0) {
                    $body_fh->close();
                    $body_done = 1;
                    return q{}, undef;
                }
                return $data, undef;
            };
        }

        $body_type = ref($body);

    } # if
    
    if ($body_type eq q{ARRAY}) {

        if ($body_length == 0) {
            foreach my $body_piece (@{$body}) {
                $body_length += length($body_piece);
            } # foreach
        }

        push @{$body}, q{};

        my $body_idx  = 0;
        my $body_done = undef;
        my $body_pieces = $body;
        my $new_body = sub {
            if ($body_done) {
                return q{}, undef;
            }

            my $data = $body_pieces->[$body_idx];
            $body_idx += 1;

            if ($data eq q{}) {
                $body_done = 1;
            }
            return $data, undef;
        };

        $body = $new_body;
        $body_type = ref($body);

    } # if

    $req->{headers} ||= {};
    $req->{headers}{'Content-Length'} = ["${body_length}"];
    if ($body_length > 0) {
        $req->{body} = {
            read => $body,
        }
    }
    return undef;
}; # $load_body

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
            'Connection'   => [q{close}],
        },
    };

    if (defined($ct)) {
        $req->{headers}{'Content-Type'} = [$ct];
    }

    if (defined($body)) {
        my $err = $load_body->($req, $body);
        if (defined($err)) {
            return undef, $err;
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
