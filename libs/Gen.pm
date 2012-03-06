package Gen;

use strict;
use warnings;
use utf8;
use Encode;
use Carp;

sub import {
    strict->import;
    warnings->import;
    utf8->import;
}

1;
