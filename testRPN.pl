#!/usr/bin/perl

use Parse::RPN;

$test = shift;

$ret = rpn($test);

print "$ret\n";
