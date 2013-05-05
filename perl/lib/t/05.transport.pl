#!/usr/bin/env perl

use strict;
use warnings;

use Qiniu::Utils::HTTP::Transport;

my $req = {
    method => q{GET},
    url => {
        domain    => q{www.baidu.com},
        port      => q{80},
        path      => q{/},
        query_str => q{},
    },
    headers => {
        'Host'           => [q{www.baidu.com}],
        'User-Agent'     => [q{Easy-Qiniu-Perl-SDK/0.1}],
        'Content-Length' => [q{0}],
        'Connection'     => [q{Close}],
    },
};

my $tr = Qiniu::Utils::HTTP::Transport->new();

my ($resp, $err) = $tr->round_trip($req);
if (defined($err)) {
    print "error=[$err]\n";
    exit(1);
}

print join "", @{$resp->{body_data}};
print "\n";
