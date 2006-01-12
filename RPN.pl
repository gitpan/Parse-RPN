#!/usr/bin/perl

use Data::Dumper;

use Parse::RPN;
use Getopt::Std;

my %option;
getopts( "vhds:r:", \%option );

if ( !defined $option{ r } && !defined $option{ v } )
{
    $option{ h } = 1;
}

if ( $option{ h } )
{
    print "Usage: $0 [options ...]\n\n";
    print "Where options include:\n";
    print "\t -h \t\tthis help (what else ?)\n";
    print "\t -v \t\tprint version and exit\n";
    print "\t -d \t\tprint debuging value\n";
    print "\t -s sep \t\tuse sep as separator fro the output\n";
    print "\t -r rpn \tuse rpn as string for the RPN test\n";
    exit;
}

if ( $option{ s } )
{
    rpn_separator( $option{ s } );
}

if ( $option{ v } )
{
    $ret = $Parse::RPN::VERSION;
}
else
{
    $ret = rpn( $option{ r } );

}
print "$ret\n";

if ( $option{ d } )
{
    print rpn_error() . "\n";
}

sub print1
{

    return shift;
}
