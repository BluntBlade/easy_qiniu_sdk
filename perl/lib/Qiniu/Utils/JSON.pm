#!/usr/bin/env perl

##############################################################################
#
# Easy Qiniu Perl SDK
#
# Module: Qiniu/Utils/JSON.pm
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  amethyst.black@gmail.com
#         liangtao@qiniu.com
#
##############################################################################

package Qiniu::Utils::JSON;

use strict;
use warnings;

use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
    qnc_json_marshal
);

sub qnc_json_marshal {
    return &marshal;
} # qnc_json_marshal

my $escape_str = sub {
    my $str = shift;
    $str =~ s/\\/\\\\/go;
    $str =~ s/"/\\"/go;
    $str =~ s,/,\\/,go;
    $str =~ s/[\b]/\\b/go;
    $str =~ s/\f/\\f/go;
    $str =~ s/\n/\\n/go;
    $str =~ s/\r/\\r/go;
    $str =~ s/\t/\\t/go;
    return $str;
}; # escape_str

my $unescape_str = sub {
    my $str = shift;
    $str =~ s/\\"/"/go;
    $str =~ s,\\/,/,go;
    $str =~ s/\\b/\b/go;
    $str =~ s/\\f/\f/go;
    $str =~ s/\\n/\n/go;
    $str =~ s/\\r/\r/go;
    $str =~ s/\\t/\t/go;
    $str =~ s/\\\\/\\/go;
    return $str;
}; # unescape_str

my $marshal_simply = undef;
$marshal_simply = sub {
    my $val = shift;
    my $buf = shift;

    my $t = ref($val);
    if ($t eq 'HASH') {
        $$buf .= '{';
        my $comma = '';
        foreach my $key (keys(%$val)) {
            my $fld = $key;
            $fld = $escape_str->($fld);

            $$buf .= $comma . qq{"$fld":};
            $marshal_simply->($val->{$key}, $buf);

            $comma = ',';
        } # foreach
        $$buf .= '}';
        return;
    }
    if ($t eq 'ARRAY') {
        $$buf .= '[';
        my $comma = '';
        foreach my $val (@$val) {
            $$buf .= $comma;
            $marshal_simply->($val, $buf);
            $comma = ',';
        } # foreach
        $$buf .= ']';
        return;
    }

    if ($t ne '') {
        die "Not a valid JSON value.";
    }

    if (not defined($val)) {
        $$buf .= 'null';
        return;
    }

    # The XOR result of two empty strings is an empty string.
    # The XOR result of two numbers is 0, which can be stringified as '0'.
    if (($val ^ $val) eq '0') {
        $$buf .= $val;
        return;
    }

    # The value is a string.
    my $str = $escape_str->($val);
    return;
}; # marshal_simply

sub marshal {
    my $val = shift;
    my $buf = shift;
    if (defined($buf)) {
        $marshal_simply->($val, $buf);
        return $buf;
    }

    $buf = "";
    $marshal_simply->($val, \$buf);
    return $buf;
} # marshal

use constant COMMA         => 0x001;
use constant COLON         => 0x002;
use constant OPEN_BRACE    => 0x004;
use constant CLOSE_BRACE   => 0x008;
use constant OPEN_BRACKET  => 0x010;
use constant CLOSE_BRACKET => 0x020;
use constant STRING        => 0x040;
use constant NUMBER        => 0x080;
use constant BOOLEAN       => 0x100;
use constant NULL          => 0x200;
use constant SPACES        => 0x400;
use constant ERROR         => 0x800;

use constant SCALAR        => (STRING | NUMBER | BOOLEAN | NULL);

my $lex = sub {
    my $str = shift;
    return sub {
        if ($str =~ m/\G"([^\\"]*(?:\\[^\\"]*)*)"/goc) {
            return STRING, $unescape_str->($1);
        }
        if ($str =~ m/\G([-+]?(?:[1-9]\d*|0)(?:[.]\d+))/goc) {
            return NUMBER, $1 + 0;
        }
        if ($str =~ m/\Gtrue/goc) {
            return BOOLEAN, 1; # TODO: This might cause bugs.
        }
        if ($str =~ m/\Gfalse/goc) {
            return BOOLEAN, undef; # TODO: This might cause bugs.
        }
        if ($str =~ m/\Gnull/goc) {
            return NULL, undef; # TODO: This might cause bugs.
        }
        if ($str =~ m/\G[,]/goc) {
            return COMMA, ',';
        }
        if ($str =~ m/\G[:]/goc) {
            return COLON, ':';
        }
        if ($str =~ m/\G[{]/goc) {
            return OPEN_BRACE, '{';
        }
        if ($str =~ m/\G[}]/goc) {
            return CLOSE_BRACE, '}';
        }
        if ($str =~ m/\G\[/goc) {
            return OPEN_BRACKET, '[';
        }
        if ($str =~ m/\G\]/goc) {
            return CLOSE_BRACKET, ']'; 
        }
        if ($str =~ m/\G\s+/goc) {
            return SPACES, undef;
        }
        return ERROR, undef;
    };
}; # $lex

my $unmarshal = sub {
}; # $unmarshal

sub unmarshal {
} # unmarshal

1;

__END__
