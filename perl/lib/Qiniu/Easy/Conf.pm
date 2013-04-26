##############################################################################
#
# Easy Qiniu Perl SDK
#
# Module: Qiniu/Easy/Conf.pm
#
# Author: LIANG Tao
# Weibo:  @无锋之刃
# Email:  amethyst.black@gmail.com
#         liangtao@qiniu.com
#
##############################################################################

package Qiniu::Easy::Conf;

use strict;
use warnings;

### Qiniu hosts' domain names may be changed in the future.
use constant UP_HOST => 'http://up.qbox.me';
use constant RS_HOST => 'http://rs.qbox.me';

### Don't initialize the following constants on client sides.
use constant ACCESS_KEY => '<Put your ACCESS KEY here>';
use constant SECRET_KEY => '<Put your SECRET KEY here>';

1;

__END__
