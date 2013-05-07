#!/usr/bin/perl

use Data::Dumper;

use Parse::RPN;
use Getopt::Std;

my %option;
getopts( "vhdi:o:r:f:Sp", \%option );
my $sep_in = ',';
my %S      = (
    bytesin  => 100,
    bytesout => 222,
    name     => 'eth0',
    mac      => 0xccaabbff,
);
if ( !defined $option{ r } && !defined $option{ v } && !defined $option{ f } && !defined $option{ S } )
{
    $option{ h } = 1;
}

if ( $option{ h } )
{
    print "Usage: $0 [options ...]\n\n";
    print "Where options include:\n";
    print "\t -h \t\t this help (what else ?)\n";
    print "\t -v \t\t print version and exit\n";
    print "\t -d \t\t print debuging value\n";
    print "\t -o sep \t use sep as separator for the output\n";
    print "\t -i sep \t use sep as separator for the input\n";
    print "\t -r rpn \t use rpn as string for the RPN test\n";
    print "\t -f file \t use this file for the RPN test\n";
    print "\t -S \t\t shell mode\n";
    print "\t -p \t\t process partial RPN\n";
    exit;
}

if ( $option{ o } )
{
    rpn_separator_out( $option{ o } );
}
if ( $option{ i } )
{
    rpn_separator_in( $option{ i } );
    $sep_in = $option{ i };
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
        my $data = $option{ r };
        if ( $option{ p } )
        {
            $data = partial_rpn( $data );
            print "$ret\n";
        }
        $ret = rpn( $data );
    }
    elsif ( $option{ S } )
    {
        print "Shell mode\n";
        print "IN separator=" . $option{ i } . "\n"  if ( exists $option{ i } );
        print "OUT separator=" . $option{ o } . "\n" if ( exists $option{ o } );
        while ( my $ret = <> )
        {
            chomp $ret;
            print "=" x 50 . "\n";
            print "\n";
            if ( $option{ p } )
            {
                $ret = partial_rpn( $ret );

                print "$ret\n";
                print "\n";
                print "-" x 50 . "\n";
            }
            $ret = rpn( $ret );

            print "$ret\n\n";
            print "#" x 50 . "\n";
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

sub partial_rpn
{
    my $data = shift;
    if ( $data =~ /(^|(.*)$sep_in)(\d+)($sep_in)RPN($sep_in(.*)|$)/ )
    {
        my $before = $2;
        my $size   = $3;
        my $after  = $5;
        $before =~ s/((($sep_in)[^$sep_in]*){$size})$//;
        my $tmp = $1;
        my $r   = rpn( $tmp );
        $data = $before . $sep_in . $r . $sep_in . $after;
        $data =~ s/$sep_in+/$sep_in/g;
    }
    return $data;
}

sub substit
{
    my $var = shift;
#print "in substit with <$var>\n";
    return $S{ $var };

}
