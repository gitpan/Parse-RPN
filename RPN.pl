#!/usr/bin/perl

use Parse::RPN;

$test = shift;
if ( $test =~ /^-v/ )
{
    $ret = $Parse::RPN::VERSION;
}
else
{
    $ret = rpn( $test );
}
print "$ret\n";
