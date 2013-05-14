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

my $marshal_simply = undef;
$marshal_simply = sub {
    my $obj = shift;
    my $buf = shift;

    my $t = ref($obj);
    if ($t eq 'HASH') {
        $$buf .= '{';
        my $comma = '';
        foreach my $key (keys(%$obj)) {
            my $fld = $key;
            $fld =~ s/"/\\"/;

            $$buf .= $comma . qq{"$fld":};
            $marshal_simply->($obj->{$key}, $buf);

            $comma = ',';
        } # foreach
        $$buf .= '}';
        return;
    }
    if ($t eq 'ARRAY') {
        $$buf .= '[';
        my $comma = '';
        foreach my $val (@$obj) {
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

    if (not defined($obj)) {
        $$buf .= 'null';
        return;
    }

    # The XOR result of two empty strings is an empty string.
    # The XOR result of two numbers is 0, which can be stringified as '0'.
    if (($obj ^ $obj) eq '0') {
        $$buf .= $obj;
        return;
    }

    # The object is a string.
    my $str = $obj;
    $str =~ s/\\/\\\\/go;
    $str =~ s/"/\\"/go;
    $str =~ s,/,\\/,go;
    $str =~ s/[\b]/\\b/go;
    $str =~ s/\f/\\f/go;
    $str =~ s/\n/\\n/go;
    $str =~ s/\r/\\r/go;
    $str =~ s/\t/\\t/go;
    $$buf .= qq("${str}");
    return;
}; # marshal_simply

sub marshal {
    my $obj = shift;
    my $buf = shift;
    if (defined($buf)) {
        $marshal_simply->($obj, $buf);
        return $buf;
    }

    $buf = "";
    $marshal_simply->($obj, \$buf);
    return $buf;
} # marshal

1;

__END__
