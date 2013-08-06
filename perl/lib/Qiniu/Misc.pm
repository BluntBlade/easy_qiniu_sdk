#!/usr/bin/env perl

##############################################################################
#
# Easy Qiniu Perl SDK
#
# Module: Qiniu/Misc.pm
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  liangtao@qiniu.com
#         amethyst.black@gmail.com
#
##############################################################################

package Qiniu::Misc;

sub select_value {
    my $map     = shift;
    my $default = shift;

    for my $fld (@_) {
        if (exists($map->{$fld})) {
            return $map->{$fld};
        }
    } # for

    return $default;
} # select_value

1;

__END__
