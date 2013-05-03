#!/usr/bin/perl

use Data::Dumper;

use Parse::RPN;
use Getopt::Std;

my %option;
getopts( "vhds:r:f:S", \%option );


if ( !defined $option{ r } && !defined $option{ v } && !defined $option{ f } &&  !defined $option{ S } )
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
    print "\t -s sep \tuse sep as separator fro the output\n";
    print "\t -r rpn \tuse rpn as string for the RPN test\n";
    print "\t -f file \tuse this file for the RPN test\n";
    print "\t -S \t\tshell mode\n";
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
    if ( $option{ f } )
    {
        if ( -f $option{ f } )
        {
            local $/;
            open FILE, $option{ f };
            my $buf = <FILE>;
            $ret = rpn( $buf );
            close FILE;
        }
        else
        {
            print "No source file " . $option{ f } . "\n";
        }
    }
    elsif ( $option{ r } )
    {
        $ret = rpn( $option{ r } );
    }
    elsif  ( $option{ S } )
    {
    while ( my $in = <> )
    {
    print $in;
    chomp $in;
    $ret = rpn($in);
    print "$ret";
    }
    
    }
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

sub save
{
    my $file = shift;
    my $data = shift;
    print "save file=$file\tdata=$data\n";
    open FILE, ">/tmp/$file";
    print FILE $data;
    close FILE;
}

sub restore
{
    my $file = shift;

    open FILE, "/tmp/$file";
    my $data = <FILE>;
    close FILE;
    print "restore file=$file\tdata=$data\n";
    return $data;
}
