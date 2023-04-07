#!/usr/bin/perl
use strict;
use warnings;

sub sql_get_base { return 'dbi:mysql:maillog'; }
sub sql_get_user { return 'root'; }
sub sql_get_pass { return ''; }

1;
