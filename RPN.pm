#!/usr/bin/perl
#
# Parse::RPN Package for Perl version 5 and later.
#
# Gnu GPL2 license
#
# $Id: RPN.pm,v 1.22 2004/08/06 08:41:47 fabrice Exp $
# $Revision: 1.22 $
#
# Fabrice Dulaunoy <fabrice@dulaunoy.com>
#

package Parse::RPN;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

use Carp;

@ISA = qw(Exporter AutoLoader);

@EXPORT = qw( rpn );

$VERSION = do { my @rev = (q$Revision: 1.22 $ =~ /\d+/g); sprintf "%d."."%2d" x $#rev, @rev }; # must be all one line, for MakeMaker

sub parse
{
    my $remainder = shift;
    $remainder =~ s/^,//;
    my $before;
    my $is_string = 0;
    if ( $remainder =~ /^('|")(.*)/ )
    {
        my $extracted = $1;
        $is_string = 1;
        $remainder = $2;

        if ( $remainder =~ /^([^\"']*)('|")(.*)/ )
        {
            $before    = $1;
            $remainder = $3;
        }
    }
    else
    {
        ( $before, $remainder ) = split /,/, $remainder, 2;
    }
    return ( $before, $remainder, $is_string );
}

sub rpn
{
    my @stack     = ();
    my $inbrace   = 0;
    my $bracexp   = "";
    my @completed = ();
    my $dump_all  = 0;
    my $sep       = " ";
    my @ops       = ();
    my $item      = shift;

    while ( $item )
    {
        my $elem;
        my $is_string;
        ( $elem, $item, $is_string ) = parse( $item );
        if ( $is_string )
        {
            push @ops, "'" . $elem . "'";
        }
        else
        {
            push @ops, $elem;
        }
    }

    while ( @ops )
    {
        my $is_string;
        $_ = shift @ops;
        s/^\s+//g;
        s/\s+$//g;
        if ( s/^'//g )
        {
            $is_string = 1;
        }
        s/'$//g;

##############################
# Arithmetics functions
##############################	
        if ( !$is_string )
        {
            if ( $_ =~ /^\+$/ || $_ =~ /^ADD$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, pop ( @stack ) + pop ( @stack ) );
            }
            elsif ( $_ =~ /^\+\+$/ || $_ =~ /^INCR$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, pop ( @stack ) + 1 );
            }
            elsif ( $_ =~ /^-$/ || $_ =~ /^SUB$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, $elem2 - $elem1 );
            }
            elsif ( $_ =~ /^--$/ || $_ =~ /^DECR$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, pop ( @stack ) - 1 );
            }
            elsif ( $_ =~ /^\*$/ || $_ =~ /^MUL$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, pop ( @stack ) * pop ( @stack ) );
            }
            elsif ( $_ =~ /^\/$/ || $_ =~ /^DIV$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, $elem2 / $elem1 );
            }
            elsif ( $_ =~ /^%$/ || $_ =~ /^MOD$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, $elem2 % $elem1 );
            }
            elsif ( $_ =~ /^POW$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, $elem2**$elem1 );
            }
            elsif ( $_ =~ /^SQRT$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, sqrt( pop ( @stack ) ) );
            }
            elsif ( $_ =~ /^ABS$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, abs( pop ( @stack ) ) );
            }
            elsif ( $_ =~ /^INT$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, int( pop ( @stack ) ) );
            }
            elsif ( $_ =~ /^\+-$/ || $_ =~ /^NEG$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, -( pop ( @stack ) ) );
            }

##############################
# logical functions
##############################
            elsif ( $_ =~ /^&$/ || $_ =~ /^AND$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = int( pop ( @stack ) );
                my $elem2 = int( pop ( @stack ) );
                push ( @stack, ( $elem1 & $elem2 ) );
            }
            elsif ( $_ =~ /^\|$/ || $_ =~ /^OR$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack,
                    ( int( pop ( @stack ) ) | int( pop ( @stack ) ) ) );
            }
            elsif ( $_ =~ /^XOR$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack,
                    ( int( pop ( @stack ) ) ^ int( pop ( @stack ) ) ) );
            }
            elsif ( $_ =~ /^NOT$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, !( int( pop ( @stack ) ) ) );
            }
            elsif ( $_ =~ /^~$/ )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, ( int( pop ( @stack ) ) ) );
            }

##############################
# rational functions
##############################
            elsif ( $_ =~ /^SIN$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, sin( pop ( @stack ) ) );
            }
            elsif ( $_ =~ /^COS$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, cos( pop ( @stack ) ) );
            }
            elsif ( $_ =~ /^TAN$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                push ( @stack, ( sin( $elem1 ) / cos( $elem1 ) ) );
            }
            elsif ( $_ =~ /^LOG$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, log( pop ( @stack ) ) );
            }
            elsif ( $_ =~ /^EXP$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, exp( pop ( @stack ) ) );
            }
            elsif ( $_ =~ /^PI$/i )
            {
                push ( @stack, "3.14159265358979" );
            }

##############################
# test functions
##############################
            elsif ( $_ =~ /^<$/ )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, ( $elem2 < $elem1 ? 1 : 0 ) );
            }
            elsif ( $_ =~ /^<=$/ )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, ( $elem2 <= $elem1 ? 1 : 0 ) );
            }
            elsif ( $_ =~ /^=$/ || $_ eq "==" )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, ( $elem2 == $elem1 ? 1 : 0 ) );
            }
            elsif ( $_ =~ /^>=$/ )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, ( $elem2 >= $elem1 ? 1 : 0 ) );
            }
            elsif ( $_ =~ /^>$/ )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, ( $elem2 > $elem1 ? 1 : 0 ) );
            }
            elsif ( $_ =~ /^!=$/ )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, ( $elem2 != $elem1 ? 1 : 0 ) );
            }
            elsif ( $_ =~ /^<=>$/ )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, ( $elem2 <=> $elem1 ) );
            }
            elsif ( $_ =~ /^IF$/i )
            {
                unless ( stackcheck( 3, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $el = pop ( @stack );
                my $th = pop ( @stack );
                my $co = pop ( @stack );
                my $ve = ( $co ? $th : $el );

                push ( @stack, $ve );

            }

##############################
# other various functions
##############################
            elsif ( $_ =~ /^MIN$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, ( $elem1 < $elem2 ? $elem1 : $elem2 ) );
            }
            elsif ( $_ =~ /^MAX$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, ( $elem1 > $elem2 ? $elem1 : $elem2 ) );
            }
            elsif ( $_ =~ /^TIME$/i )
            {
                push ( @stack, time() );
            }
            elsif ( $_ =~ /^RAND$/i )
            {
                push ( @stack, rand() );
            }
            elsif ( $_ =~ /^LRAND$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, rand( pop ( @stack ) ) );
            }
            elsif ( $_ =~ /^SPACE$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $text = reverse pop @stack;
                $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1 /g;
                $text = reverse $text;
                push ( @stack, $text );
            }
            elsif ( $_ =~ /^NORM$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $value = pop @stack;

                my $exp;
                $value = $value ? $value : 0;
                my @EXP = ( " ", "K", "M", "G", "T", "P" );
                while ( $value > 1000 )
                {
                    $value = $value / 1000;
                    $exp++;
                }
                $value = sprintf "%.2f", $value;
                my $ret = "$value $EXP[$exp]";
                push ( @stack, $ret );
            }
            elsif ( $_ =~ /^NORM2$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $value = pop @stack;

                my $exp;
                $value = $value ? $value : 0;
                my @EXP = ( " ", "K", "M", "G", "T", "P" );
                while ( $value > 1024 )
                {
                    $value = $value / 1024;
                    $exp++;
                }
                $value = sprintf "%.2f", $value;
                my $ret = "$value $EXP[$exp]";
                push ( @stack, $ret );
            }

##############################
# strings functions
##############################
            elsif ( $_ =~ /^EQ$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, ( $elem2 eq $elem1 ? 1 : 0 ) );
            }
            elsif ( $_ =~ /^NE$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, ( $elem2 ne $elem1 ? 1 : 0 ) );
            }
            elsif ( $_ =~ /^LT$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, ( $elem2 lt $elem1 ? 1 : 0 ) );
            }
            elsif ( $_ =~ /^GT$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, ( $elem2 gt $elem1 ? 1 : 0 ) );
            }
            elsif ( $_ =~ /^LE$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, ( $elem2 le $elem1 ? 1 : 0 ) );
            }
            elsif ( $_ =~ /^GE$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, ( $elem2 ge $elem1 ? 1 : 0 ) );
            }
            elsif ( $_ =~ /^CMP$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, ( $elem2 cmp $elem1 ) );
            }
            elsif ( $_ =~ /^LEN$/i || $_ =~ /^LENGTH$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, ( length( pop ( @stack ) ) ) );
            }
            elsif ( $_ =~ /^CAT$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, ( $elem2 . $elem1 ) );
            }
            elsif ( $_ =~ /^REP$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                my $r     = $elem2 x $elem1;
                push ( @stack, ( $r ) );
            }
            elsif ( $_ =~ /^REV$/i || $_ =~ /^REVERSE$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $r     = reverse( $elem1 );
                push ( @stack, ( $r ) );
            }
            elsif ( $_ =~ /^SUBSTR$/i )
            {
                unless ( stackcheck( 3, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $offset = pop ( @stack );
                my $len    = pop ( @stack );
                my $str    = pop ( @stack );
                push ( @stack, ( substr( $str, $len, $offset ) ) );
            }
            elsif ( $_ =~ /^UC$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, ( uc( pop ( @stack ) ) ) );
            }
            elsif ( $_ =~ /^LC$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, ( lc( pop ( @stack ) ) ) );
            }
            elsif ( $_ =~ /^UCFIRST$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, ( ucfirst( pop ( @stack ) ) ) );
            }
            elsif ( $_ =~ /^LCFIRST$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, ( lcfirst( pop ( @stack ) ) ) );
            }
            elsif ( $_ =~ /^PAT$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $pat = pop ( @stack );
                my $var = pop ( @stack );
                my $r   = ( $var =~ qr/$pat/ );
                for ( 0 .. $#+ )
                {
                    push ( @stack, substr( $var, $-[$_], $+[$_] - $-[$_] ) );
                }
            }
            elsif ( $_ =~ /^TPAT$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $pat = pop ( @stack );
                my $var = pop ( @stack );
                my $r   = ( $var =~ qr/$pat/ );

                push ( @stack, ( $r ? 1 : 0 ) );
            }
            elsif ( $_ =~ /^SPATI$/i )
            {
                unless ( stackcheck( 3, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $patreplace = pop ( @stack );
                my $patsearch  = pop ( @stack );
                my $var        = pop ( @stack );
                $var =~ s/$patsearch/$patreplace/i;

                push ( @stack, $var );
            }
            elsif ( $_ =~ /^SPAT$/i )
            {
                unless ( stackcheck( 3, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $patreplace = pop ( @stack );
                my $patsearch  = pop ( @stack );
                my $var        = pop ( @stack );
                $var =~ s/$patsearch/$patreplace/;

                push ( @stack, $var );
            }
            elsif ( $_ =~ /^PRINTF$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }

                my $format = pop ( @stack );
		my @r = ( $format =~ m/(%[^ ])/g ); 
		my @var;
		for ( 0 .. $#r )
                {
                    unshift @var, pop @stack;
                }
                
               
                push ( @stack, sprintf $format, @var );
            }
            elsif ( $_ =~ /^PACK$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $format = " " . ( pop ( @stack ) ) . " ";
                my @r = ( $format =~ m/([a-zA-Z]\d*\s*)/g );
                my @var;
                for ( 0 .. $#r )
                {
                    unshift @var, pop @stack;
                }
                push ( @stack, pack( $format, @var ) );
            }
            elsif ( $_ =~ /^UNPACK$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $format = pop ( @stack );
                my $var    = pop ( @stack );
                push ( @stack, ( unpack $format, $var ) );

            }

##############################
# stack functions
##############################
            elsif ( $_ =~ /^DEPTH$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                push ( @stack, scalar @stack );
            }
            elsif ( $_ =~ /^DUP$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                push ( @stack, $elem1, $elem1 );
            }
            elsif ( $_ =~ /^SWAP$/i || $_ =~ /^EXCH$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                push ( @stack, $elem1, $elem2 );
            }
            elsif ( $_ =~ /^POP$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                pop ( @stack );
            }
	    elsif ( $_ =~ /^POPN$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
		my $nbr =  pop ( @stack );
		for (1 .. $nbr){
                pop ( @stack );
		}
            }
            elsif ( $_ =~ /^SWAP2$/i || $_ =~ /^EXCH2$/i )
            {
                unless ( stackcheck( 3, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                my $elem3 = pop ( @stack );
                push ( @stack, $elem2, $elem3, $elem1 );
            }
            elsif ( $_ =~ /^ROT3$/i || $_ =~ /^ROT3$/i )
            {
                unless ( stackcheck( 3, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                my $elem3 = pop ( @stack );
                push ( @stack, $elem1, $elem2, $elem3 );
            }
            elsif ( $_ =~ /^ROT$/i )
            {
                unless ( stackcheck( 3, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                my $elem3 = pop ( @stack );
                push ( @stack, $elem2, $elem1, $elem3 );
            }
            elsif ( $_ =~ /^RROT$/i )
            {
                unless ( stackcheck( 3, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                my $elem3 = pop ( @stack );
                push ( @stack, $elem1, $elem3, $elem2 );
            }
            elsif ( $_ =~ /^ROLL$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my @tmp = splice @stack, -( $elem1 - 1 );
                $elem1 = pop ( @stack );
                push ( @stack, @tmp, $elem1 );
            }
            elsif ( $_ =~ /^PICK$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                push ( @stack, $stack[ -( $elem1 ) ] );
            }
            elsif ( $_ =~ /^PUT$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                my $elem1 = pop ( @stack );
                my $elem2 = pop ( @stack );
                my @tmp;
                if ( $elem1 > $#stack + 1 )
                {
                    $elem1 = $#stack + 1;
                }
                if ( $elem1 )
                {
                    @tmp = splice @stack, -$elem1;
                }
                push ( @stack, $elem2, @tmp );
            }
            elsif ( $_ =~ /^DU$/i || $_ =~ /^DUMP$/i )
            {
                unless ( stackcheck( 1, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                $dump_all = 1;
            }
            elsif ( $_ =~ /^DS$/i || $_ =~ /^DUMPS$/i )
            {
                unless ( stackcheck( 2, \@stack, \@completed, $_, \@ops ) )
                {
                    @stack = ( undef );
                    last;
                }
                $dump_all = 1;
                $sep      = pop ( @stack );
                if ( $sep =~ /\\n/ )
                {
                    $dump_all = 2;
                }
            }
            else
            {
                push ( @stack, $_ );
            }
        }
        else
        {
            push ( @stack, $_ );
        }
    }
    unless ( @stack )
    {
        @stack = ( undef );
        db_print( 'err',
            "Stack underflow for expr " . "$item, no value at end." );
    }
    elsif ( $#stack > 0 && wantarray == 0 && !$dump_all )
    {
        db_print( 'warning',
            "Extra values left on stack for "
            . "expr $item left "
            . join ( ",", @stack )
            . " (right one used)." );
    }
    elsif ( $#stack > 0 && wantarray == 0 && $dump_all == 1 )
    {
        return ( join ( "$sep", @stack ) );
    }
    elsif ( $#stack > 0 && wantarray == 0 && $dump_all == 2 )
    {
        return ( join ( "\n", @stack ) );
    }

    if ( wantarray )
    {
        return ( @stack );
    }
    else
    {
        return ( pop ( @stack ) );
    }
}

sub db_print
{
    my $severity;
    my $message;

    if ( scalar( @_ ) > 1 )
    {
        $severity = shift;
    }
    else
    {
        $severity = "err";    # Default to LOG_ERR severity
    }
    $message = join ( "", @_ );
    $message =~ s/\r/\\r/g;
    $message =~ s/\n/\\n/g;
    print STDERR "$0 pid[$$]: $severity: $message at ", scalar localtime, "\n";
}

sub stackcheck
{
    my $required  = shift;
    my $sp        = shift;
    my $completed = shift;
    my $current   = shift;
    my $todo      = shift;
    my @stack     = @$sp;

    if ( scalar( @stack ) < $required )
    {
        my $msg = "Stack Underflow in ";
        db_print(
            'err', $msg,
            join ( ",", ( @$completed ) ), ",<<<$current>>>,",
            join ( ",", ( @$todo ) )
        );
        return ( undef );
    }
    return ( scalar( @stack ) );
}

1;
__END__

=head1 NAME

Parse::RPN - Is a minimalist RPN parser/processor (a little like FORTH)

=head1 SYNOPSIS

  use Parse::RPN;
  $result=rpn(string ...);
  @results=rpn(string ...);

  string... is a list of RPN operator and value separated by a coma
  in scalar mode RPN return the result of the calculation (If the stack contain more then one element, 
  you receive a warning and the top value on the stack)
  in array mode, you receive the content of the stack after evaluation

=head1 DESCRIPTION

  RPN receive in entry a scalar of one or more elements coma separated 
  and evaluate as an RPN (Reverse Polish Notation) command.
  The function split all elements and put in the stack.
  The operator are case insensitive.
  The operator are detect as is, if they are alone in the element of the stack. 
  Extra space before or after are allowed
  (e.g "3,4,ADD" here ADD is an opeartor but it is not the case in "3,4,ADD 1")
  If element is not part of the predefined operator (dictionary), the element is push as a litteral.
  If you would like to put a string which is part of the dictionary, put it between quote or double-quote 
  (e.g "3,4,'ADD'" here ADD is a literal and the evaluation reurn ADD and a warning because the stack is not empty)
  If the string contain a coma, you need also to quote or double-quote the string. 
  (be care to close your quoted or double-quoted string)

  The evaluation follow the rule of RPN or FORTH or POSTCRIPT or pockect calcutor HP.
  Look on web for documentation about the use of RPN notation.
  
  I use this module in a application where the final user need to create an maintain 
  a configuration file with the possibility to do calculation on variable returned from application.
  
  The idea of this module is comming from Math::RPN of Owen DeLong, owen@delong.com that I used for more then a year
  before some of my customer would like more ...
  I correct a bug (interversion of > and >=), add the STRING function, pattern search and some STACK functions.

=head1 OPERATORS

     The operators get value from the stack and push the result on top
     In the following explanation, the stack is represented as a pair of brackets ()
     and each elements by a pair of square barcket []
     The left part is the state before evalutation 
     and the right part is the state of the stack after evaluation 

	Arithmetic operators
	---------------------
            +  | ADD		([a][b])		([a+b])
            ++ | INCR		([a]) 			([a+1])
            -  | SUB		([a][b])		([a-b])
            -- | DECR		([a]) 			([a-1])
            *  | MUL		([a][b])		([a*b])
            /  | DIV		([a][b])		([a/b])
            %  | MOD		([a][b])		([a%b])
            POW     		([a][b])		([a*a])
            SQRT    		([a][b])		([SQRT a])
            ABS     		([a][b])		([ABS a])
            INT     		([a][b])		([INT a])
            &  | AND		([a][b])		([a&b])
            |  | OR		([a][b])		([a|b])
            XOR		        ([a][b])		([a^b])
            NOT		        ([a][b])		([NOT a])	Logically negate of [a]
	    ~  		        ([a][b])		([~ a])		Bitwise complement of [a] 
	    +-	| NEG	        ([a]) 			([-a])
	    
	Rationnal operators
	-------------------  
            SIN			([a]) 			([SIN a])	Unit in radian
            COS			([a]) 			([COS a])	Unit in radian
            TAN			([a]) 			([TAN a])	Unit in radian
            LOG		        ([a]) 			([LOG a])
            EXP		        ([a]) 			([EXP a])
	    PI						([3.14159265358979])	
	    
	Logical operator
	----------------
	    <		       	([a][b])		([1]) if [a]<[b] else ([0])
	    <=		       	([a][b])		([1]) if [a]<=[b] else ([0])
	    =  | ==	       	([a][b])		([1]) if [a]==[b] else ([0])
	    >=		       	([a][b])		([1]) if [a]>=[b] else ([0])
	    >		       	([a][b])		([1]) if [a]>[b] else ([0])
	    <=>	     	       	([a][b])		([-1]) if [a]>[b],([1]) if [a]<[b], ([0])if [a]==[b]
            IF                 	([a][b][c])		([c]) if [a]==0 else ([b])
	
	Other operator
	----------------
            MIN	     	       	([a][b])		([a]) if  [a]<[b] else ([b]) 
            MAX		       	([a][b])		([a]) if  [a]>[b] else ([b]) 
            TIME		()			([time]) time in ticks
            RAND		()			([rand]) a random numder between 0 and 1
            LRAND		([a])			([rand]) a random numder between 0 and [a]
	    SPACE		([a])			Return [a] with space between each 3 digits
	    NORM		([a])			Return [a] normalized by 1000 (K,M,G = 1000 * unit)
	    NORM2		([a])			Return [a] normalized by 1000 (K,M,G = 1024 * unit)
	    
	String operators
	----------------
            EQ	       		([a][b])		([1]) if [a] eq [b] else ([0])
	    NE	       		([a][b])		([1]) if [a] ne [b] else ([0])
            LT			([a][b])		([1]) if [a] lt [b] else ([0])
            GT			([a][b])		([1]) if [a] gt [b] else ([0])
            LE			([a][b])		([1]) if [a] le [b] else ([0])
            GE			([a][b])		([1]) if [a] ge [b] else ([0])
            CMP			([a][b])		([-1]) if [a] gt [b],([1]) if [a] lt [b], ([0])if [a] eq [b]
            LEN | LENGTH	([a])			([LENGTH a])
	    CAT			([a][b])		([ab])	String concatenation
            REP			([a][b])		([a x b]) repeat [b] time the motif [a]
	    REV	| REVERSE	([a])			([REVERSE a])
            SUBSTR		([a][b][c])		([SUBSTR [a], [b], [c]) get substring of [a] starting from [b] untill [c]
            UC			([a])			([UC a])
            LC			([a])			([LC a])
            UCFIRST		([a])			([UCFIRST a])
            LCFIRST		([a])			([LCFIRST a])
            PAT			([a][b])		([r1]...) use the pattern [b] on the string [a] and return result 
	    						if more then one result like $1, $2 ... return all the results 
	    TPAT		([a][b])		([r]) use the pattern [b] on the string [a] and return 1 if pattern macth 
	    						otherwise return 0
	    SPAT		([a][b][c])		Do a pattern subsititution following this rule I<[c] =~s/[a]/[b]/>
	    SPATI		([a][b][c])		Do a pattern subsititution following this rule I<[c] =~s/[a]/[b]/i> (case insensitive)
	    PACK                ([a][b]...[x])	        Do an unpack on variable [b] to [x] using format [b] 
	    UNPACK              ([a][b])		Do an unpack on variable [b] using format [a]
	    PRINTF     	        ([a][b]...[x])          use the format present in [a] to print the value [b] to [x] 
	    						the format is the same as (s)printf 
	    
	 Stack operators
	 ---------------
            DEPTH		([r1]...)		([re1]...[nbr])	Return the number of elements in the statck
            DUP			([a])			([a][a])	
            SWAP		([a][b])		([b][a])
            POP			([a][b])		([a])
	    POPN                ([a][b][c]...[x])	([l]...[x]) remove [b] element from the stack (starting at [c])
	    SWAP2		([a][b][c])     	([a][c][b])
            ROT			([a][b][c])     	([b][c][a])
	    RROT		([a][b][c])     	([c][a][b])
	    ROT3		([a][b][c])     	([c][b][a])
            ROLL		([a][b][c][d][e][n])	([a][c][d][e][b]) rotate the [n] element of the stack (here [n]=4)
	    						if  [n] =3 it is equivalent to ROT
            PICK		([a][b][c][d][e][n])    ([a][b][c][d][e][b]) copy element [n] on top 
            PUT			([a][b][c][d][v][n])	([a][v][b][c][d]) put element [v] at level [n] (here [n]=3)
            DU  |DUMP		([a][b][c][d])		() dump the stack in a string, each elements separated by a blank
	    						This avoid the warning if the stack is not empty and prevent use of array
            DS |DUMPS           ([a][b][c][d][sep])     () dump the stack in a string, each elements separated by [sep] (could be \n)
	    						This avoid the warning if the stack is not empty and prevent use of array


=head1 EXAMPLES

	use Parse::RPN;
	
	$test ="3,5,+";
	$ret = rpn($test);  # $ret = 8
	
	$test = "Hello World,len,3,+";
	$ret = rpn($test);  # $ret = 14
	
	$test = "'Hello,World',len,3,+";
	$ret = rpn($test);  # $ret = 14
	
	$test = "'Hello,World,len,3,+";
	---------^-----------^-
	$ret = rpn($test);  # $ret = 8 with a warning because the stack is not empty ([Hello] [8])
			    # be care to close your quoted string 
	
	$test = "'Hello,world',',',pat,',',eq,'Contain a coma','Without a coma',if"
	$ret = rpn($test);  # $ret = "Contain a coma"
	
	$test = "'Hello world',',',pat,',',eq,'Contain a coma','Without a coma',if"
	$ret = rpn($test);  # $ret = "Without a coma"
	
	$test = "3,10,/,5,+,82,*,%b,PRINTF"
	$ret = rpn($test);  # $ret = "110110010"
	
	$test = "3,10,/,5,+,82,*,%016b,PRINTF"
	$ret = rpn($test);  # $ret = "0000000110110010"
	
	$test = "55,N,pack,B32,unpack,^0+(?=\d), ,spat,'+',ds";
	$ret = rpn($test);  # $ret = 110111

=head1 AUTHOR

	Fabrice Dulaunoy <fabrice@dulaunoy.com> 
	It is a rewrite of the module Math::RPN from  Owen DeLong, <owen@delong.com> 
	with extension for STRING management and some extra STACK functions


=head1 SEE ALSO
	Math-RPN from  Owen DeLong, <owen@delong.com> 

=head1 TODO
	REPEAT, WHILE, FOR, BLOCK, FUNCTION

perl(1).

=cut

