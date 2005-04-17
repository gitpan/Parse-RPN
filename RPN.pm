#!/usr/bin/perl
###########################################################
# RPN package with DICT
# Gnu GPL2 license
#
# $Id: RPN.pm,v 2.9 2005/04/17 13:44:59 fabrice Exp $
# $Revision: 2.9 $
#
# Fabrice Dulaunoy <fabrice@dulaunoy.com>
###########################################################
# ChangeLog:
#
###########################################################

=head1 Parse-RPN (V 2.xx) - Introduction

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

=cut

package Parse::RPN;
use strict;

use Data::Dumper;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

use Carp;

use Data::Dumper;

@ISA = qw(Exporter AutoLoader);

@EXPORT = qw( rpn );

$VERSION = do { my @rev = (q$Revision: 2.9 $ =~ /\d+/g); sprintf "%d."."%d" x $#rev, @rev };
my $mod = "Tie::IxHash";
my %dict;
my %var;

my @loop;
my @begin;
my @return;

#use Tie::IxHash;

#BEGIN
#{
#    if ( eval "require $mod" )
#    {
#        $mod->import();
#tie %dict, "Tie::IxHash";
#tie %var,  "Tie::IxHash";

#    }
#}

########################
# mathematic operators
########################

=head1 MATHEMATIC operators
	
.
	
=head2 a b +

      return the result of 'a' + 'b' 
	
=cut

$dict{ '+' } = sub {

    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, $a + $b;
    return \@ret, 2;
};

=head2 a b -

      return the result of 'a' - 'b' 
	
=cut

$dict{ '-' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, $b - $a;
    return \@ret, 2;
};

=head2 a b *

      return the result of 'a' * 'b' 
	
=cut

$dict{ '*' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, $b * $a;
    return \@ret, 2;
};

=head2 a b /

      return the result of 'a' / 'b' 
	
=cut

$dict{ '/' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, $b / $a;
    return \@ret, 2;
};

=head2 a b **

      return the result of 'a' ** 'b'  (exponant)
	
=cut

$dict{ '**' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, $b**$a;
    return \@ret, 2;
};

=head2 a 1+

      return the result of 'a' +1 
	
=cut

$dict{ '1+' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, $a + 1;
    return \@ret, 1;
};

=head2 a 1-

      return the result of 'a' -1 
	
=cut

$dict{ '1-' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, $a - 1;
    return \@ret, 1;
};

=head2 a 2-

      return the result of 'a' -2 
	
=cut

$dict{ '2-' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, $a - 2;
    return \@ret, 1;
};

=head2 a 2+

      return the result of 'a' +2 
	
=cut

$dict{ '2+' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, $a + 2;
    return \@ret, 1;
};

=head2 a b MOD

      return the result of 'a' % 'b'
	
=cut

$dict{ 'MOD' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, $b % $a;
    return \@ret, 2;
};

=head2 a ABS

      return the result of  abs 'a'
	
=cut

$dict{ 'ABS' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, abs( $a );
    return \@ret, 1;

};

=head2 a INT

      return the result of INT 'a' 
	
=cut

$dict{ 'INT' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, int( $a );
    return \@ret, 1;
};

=head2 a +-

      return the result negate value of 'a' (- 'a' )
	
=cut

$dict{ '+-' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, -( $a );
    return \@ret, 1;
};

=head2 a REMAIN

      return the result of 'a' - int 'a' (fractional part of 'a' ) 
	
=cut

$dict{ 'REMAIN' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, $a - int( $a );
    return \@ret, 1;
};

=head2 a SIN

      return the result of sin 'a'  ('a' in RADIAN)
	
=cut

$dict{ 'SIN' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, sin( $a );
    return \@ret, 1;
};

=head2 a COS

      return the result of cos 'a'  ('a' in RADIAN)
	
=cut

$dict{ 'COS' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, cos( $a );
    return \@ret, 1;
};

=head2 a TAN

      return the result of tan 'a'  ('a' in RADIAN)
	
=cut

$dict{ 'TAN' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( sin( $a ) / cos( $a ) );
    return \@ret, 1;
};

=head2 a CTAN

      return the result of cotan 'a'  ('a' in RADIAN)
	
=cut

$dict{ 'CTAN' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( cos( $a ) / sin( $a ) );
    return \@ret, 1;
};

=head2 a LN

      return the result of ln 'a' 
	
=cut

$dict{ 'LN' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, log( $a );
    return \@ret, 1;
};

=head2 a EXP

      return the result of 'e' ** 'a' 
	
=cut

$dict{ 'EXP' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, exp( $a );
    return \@ret, 1;
};

=head2 PI

      return the value of PI (3.14159265358979)
	
=cut

$dict{ 'PI' } = sub {
    my @ret;
    push @ret, "3.14159265358979";
    return \@ret, 0;
};

########################
# logical operators
########################

=head1 LOGICAL operators

.

=head2 a b <

      return the result of 'a' < 'b'  ( BOOLEAN value ) 
	
=cut

$dict{ '<' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b < $a ? 1 : 0 );
    return \@ret, 2;
};

=head2 a b <=

      return the result of 'a' <= 'b'  ( BOOLEAN value )
	
=cut

$dict{ '<=' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b <= $a ? 1 : 0 );
    return \@ret, 2;
};

=head2 a b >

      return the result of 'a' > 'b'  ( BOOLEAN value )
	
=cut

$dict{ '>' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b > $a ? 1 : 0 );
    return \@ret, 2;
};

=head2 a b >=

      return the result of 'a' >= 'b'  ( BOOLEAN value )
	
=cut

$dict{ '>=' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b >= $a ? 1 : 0 );
    return \@ret, 2;
};

=head2 a b ==

      return the result of 'a' == 'b'  ( BOOLEAN value ) 1 if a == b else 0
	
=cut

$dict{ '==' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b == $a ? 1 : 0 );
    return \@ret, 2;
};

=head2 a b <=>

      return the result of 'a' <=> 'b'  ( BOOLEAN value  ) -1 if a < b ,0 if a == b, 1 if a > b
	
=cut

$dict{ '<=>' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b <=> $a );
    return \@ret, 2;
};

=head2 a b !=

      return the result of 'a' != 'b'  ( BOOLEAN value ) 0 if a == b else 1
	
=cut

$dict{ '!=' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b != $a ? 1 : 0 );
    return \@ret, 2;
};

########################
# misc operators
########################

=head1 MISC operators

.

=head2 a b MIN

      return the result smallest of the 2 arguments
	
=cut

$dict{ 'MIN' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $a < $b ? $a : $b );
    return \@ret, 2;
};

=head2 a b MAX

      return the result greatest of the 2 arguments
	
=cut

$dict{ 'MAX' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $a > $b ? $a : $b );
    return \@ret, 2;
};

=head2 TICK

      return the current time in ticks
	
=cut

$dict{ 'TICK' } = sub {
    my @ret;
    push @ret, ( time() );
    return \@ret, 1;
};

=head2 a LTIME

      return the localtime coresponding to the ticks value 'a'
      the format is 'sec' 'min' 'hour' 'day_in_the_month' 'month' 'year' 'day_in_week' 'day_year' 'dayloight_saving'
      'year' is the elapsed year since 1900
      'month' start to 0
      The format is the same as localtime() in perl
	
=cut

$dict{ 'LTIME' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( localtime( $a ) );
    return \@ret, 1;
};

=head2 a GTIME

      return the gmtime coresponding to the ticks value 'a'
      the format is 'sec' 'min' 'hour' 'day_in_the_month' 'month' 'year' 'day_in_week' 'day_year' 'dayloight_saving'
      'year' is the elapsed year since 1900
      'month' start to 0
      The format is the same as gmtime() in perl
	
=cut

$dict{ 'GTIME' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( gmtime( $a ) );
    return \@ret, 1;
};

=head2 a HLTIME

      return the localtime coresponding to the ticks value 'a' in a human readable format
	
=cut

$dict{ 'HLTIME' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, scalar( localtime( $a ) );
    return \@ret, 1;
};

=head2 a HGTIME

      return the gmtime coresponding to the ticks value 'a' in a human readable format
	
=cut

$dict{ 'HGTIME' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, scalar( gmtime( $a ) );
    return \@ret, 1;
};

=head2 RAND

      return a random value in the range [0,1[
	
=cut

$dict{ 'RAND' } = sub {
    my @ret;
    push @ret, rand();
    return \@ret, 0;
};

=head2 a LRAND

      return a random value in the range [0,'a'[
	
=cut

$dict{ 'LRAND' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, rand( $a );
    return \@ret, 1;
};

=head2 a SPACE

      return the number 'a' formated with space each 3 digits
	
=cut

$dict{ 'SPACE' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $text  = reverse $a;
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1 /g;
    $text = reverse $text;
    my @ret;
    push @ret, $text;
    return \@ret, 1;
};

=head2 a DOT

      return the number 'a' formated with . (dot) each 3 digits
	
=cut

$dict{ 'DOT' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $text  = reverse $a;
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1./g;
    $text = reverse $text;
    my @ret;
    push @ret, $text;
    return \@ret, 1;
};

=head2 a NORM

      return the number 'a' normalize by slice of 1000 with extra power value "K", "M", "G", "T", "P" (or nothing if lower than 1000)
	
=cut

$dict{ 'NORM' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $exp;
    $a = $a ? $a : 0;
    my @EXP = ( " ", "K", "M", "G", "T", "P" );
    while ( $a > 1000 )
    {
        $a = $a / 1000;
        $exp++;
    }
    $a = sprintf "%.2f", $a;
    my $ret = "$a $EXP[$exp]";
    my @ret;
    push @ret, "'" . $ret . "'";
    return \@ret, 1;
};

=head2 a NORM2

      return the number 'a' normalize by slice of 1024 with extra power value "K", "M", "G", "T", "P" (or nothing if lower than 1024)
	
=cut

$dict{ 'NORM2' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $exp;
    $a = $a ? $a : 0;
    my @EXP = ( " ", "K", "M", "G", "T", "P" );
    while ( $a > 1024 )
    {
        $a = $a / 1024;
        $exp++;
    }
    $a = sprintf "%.2f", $a;
    my $ret = "$a $EXP[$exp]";
    my @ret;
    push @ret, "'" . $ret . "'";
    return \@ret, 1;
};

########################
# string operators
########################

=head1 STRING operators

.

=head2 a b EQ

      return the result of 'a' EQ 'b'  ( BOOLEAN value )
	
=cut

$dict{ 'EQ' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b eq $a ? 1 : 0 );
    return \@ret, 2;
};

=head2 a b NE

      return the result of 'a' NE 'b'  ( BOOLEAN value )
	
=cut

$dict{ 'NE' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b ne $a ? 1 : 0 );
    return \@ret, 2;
};

=head2 a b LT

      return the result of 'a' LT 'b'  ( BOOLEAN value )
	
=cut

$dict{ 'LT' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b lt $a ? 1 : 0 );
    return \@ret, 2;
};

=head2 a b GT

      return the result of 'a' GT 'b'  ( BOOLEAN value )
	
=cut

$dict{ 'GT' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b gt $a ? 1 : 0 );
    return \@ret, 2;
};

=head2 a b LE

      return the result of 'a' LE 'b'  ( BOOLEAN value )
	
=cut

$dict{ 'LE' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b le $a ? 1 : 0 );
    return \@ret, 2;
};

=head2 a b GE

      return the result of 'a' GE 'b'  ( BOOLEAN value )
	
=cut

$dict{ 'GE' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b ge $a ? 1 : 0 );
    return \@ret, 2;
};

=head2 a b CMP

      return the result of 'a' CMP 'b'  ( BOOLEAN value )
	
=cut

$dict{ 'CMP' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b cmp $a );
    return \@ret, 2;
};

=head2 a LEN

      return the length of 'a' EQ 'b' 
	
=cut

$dict{ 'LEN' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( length $a );
    return \@ret, 1;
};

=head2 a b CAT

      return the concatenation 'a' and 'b' 
	
=cut

$dict{ 'CAT' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( "'" . $b . $a . "'" );
    return \@ret, 2;
};

=head2 a b REP

      return the result of 'a' x 'b'  duplicate 'a' by the number of 'x' 
	
=cut

$dict{ 'REP' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, ( $b x $a );
    return \@ret, 2;
};

=head2 a REV

      return the reverse of 'a' EQ 'b' 
	
=cut

$dict{ 'REV' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = reverse $a;
    my @ret;
    push @ret, ( $b );
    return \@ret, 1;
};

=head2 a b c SUBSTR

      return the substring of 'c' starting at 'b' with the length of 'a'
	
=cut

$dict{ 'SUBSTR' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my $c     = pop @{ $work1 };
    my @ret;
    push @ret, ( substr( $c, $b, $a ) );
    return \@ret, 3;
};

=head2 a UC

      return 'a' in uppercase
	
=cut

$dict{ 'UC' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( uc $a );
    return \@ret, 1;
};

=head2 a LC

      return 'a' in lowercase
	
=cut

$dict{ 'LC' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( lc $a );
    return \@ret, 1;
};

=head2 a UCFIRST

      return 'a' with the first letter in uppercase
	
=cut

$dict{ 'UCFIRST' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( ucfirst $a );
    return \@ret, 1;
};

=head2 a LCFIRST

      return 'a' with the first letter in lowercase
	
=cut

$dict{ 'LCFIRST' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, ( lcfirst $a );
    return \@ret, 1;
};

=head2 a b SPLIT

      return all splitted item of 'a' by the separator 'b' 
      'b' is a REGEX
	
=cut

$dict{ 'SPLIT' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @r     = split /$a/, $b;
    my @ret;
    push @ret, @r;
    return \@ret, 2;
};


=head2 a b SPLITI

      return all splitted item of 'a' by the separator 'b' 
      'b' is a REGEX case insensitive
	
=cut

$dict{ 'SPLITI' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @r     = split /$a/i, $b;
    my @ret;
    push @ret, @r;
    return \@ret, 2;
};

=head2 a b PAT

      return one or more occurance of 'b' in 'a' 
      'b' is a REGEX
	
=cut

$dict{ 'PAT' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @r     = ( $b =~ m/$a/g );
    my @ret;
    push @ret, @r;
    return \@ret, 2;
};

=head2 a b PATI

      return one or more occurance of 'b' in 'a' 
      'b' is a REGEX case insensitive
	
=cut

$dict{ 'PATI' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @r     = ( $b =~ m/$a/ig );
    my @ret;
    push @ret, @r;
    return \@ret, 2;
};

=head2 a b TPAT

      test if the pattern 'b' is in 'a' 
      'b' is a REGEX
	
=cut

$dict{ 'TPAT' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my $r     = ( $b =~ m/$a/g );
    my @ret;
    push @ret, ( $r ? 1 : 0 );
    return \@ret, 2;
};

=head2 a b TPATI

      test if the pattern 'b' is in 'a' 
      'b' is a REGEX
	
=cut

$dict{ 'TPATI' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my $r     = ( $b =~ m/$a/ig );
    my @ret;
    push @ret, ( $r ? 1 : 0 );
    return \@ret, 2;
};

=head2 a b c SPAT

      substitute the pattern 'b' by the pattern 'a'  in 'c'
      'b' and 'c' are a REGEX
	
=cut

$dict{ 'SPAT' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my $c     = pop @{ $work1 };
    $c =~ s/$b/$a/;
    my @ret;
    push @ret, $c;
    return \@ret, 3;
};

=head2 a b c SPATG

      substitute the pattern 'b' by the pattern 'a'  in 'c' as many time as possible (g flag in REGEX)
      'b' and 'c' are a REGEX
	
=cut

$dict{ 'SPATG' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my $c     = pop @{ $work1 };
    $c =~ s/$b/$a/g;
    my @ret;
    push @ret, $c;
    return \@ret, 3;
};

=head2 a b c SPATI

      substitute the pattern 'b' by the pattern 'a'  in 'c'case insensitive (i flag in REGEX)
      'b' and 'c' are a REGEX
	
=cut

$dict{ 'SPATI' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my $c     = pop @{ $work1 };
    $c =~ s/$b/$a/i;
    my @ret;
    push @ret, $c;
    return \@ret, 3;
};

=head2 a b c SPATGI

      substitute the pattern 'b' by the pattern 'a'  in 'c' as many time as possible (g flag in REGEX)
      and case insensitive (1 flag in REGEX)
      'b' and 'c' are a REGEX
	
=cut

$dict{ 'SPATGI' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my $c     = pop @{ $work1 };
    $c =~ s/$b/$a/gi;
    my @ret;
    push @ret, $c;
    return \@ret, 3;
};

=head2 a ... z PRINTF

     use the format 'z' to print the value(s) on the stack
     7,3,/,10,3,/,%d %f,PRINTF -> 2 3.333333
     see printf in perl
	
=cut

$dict{ 'PRINTF' } = sub {

    my $work1  = shift;
    my $format = pop @{ $work1 };
    my @r      = ( $format =~ m/(%[^ ])/g );
    my @var;
    for ( 0 .. $#r )
    {
        unshift @var, pop @{ $work1 };
    }
    my @ret;
    push @ret, sprintf $format, @var;
    return \@ret, 2 + $#r;
};

=head2 a b PACK

      pack the value 'a' with the format 'b'
      2004,06,08,a4 a2 a2,PACK -> 20040608
      see pack in perl
	
=cut

$dict{ 'PACK' } = sub {
    my $work1  = shift;
    my $format = " " . ( pop ( @{ $work1 } ) ) . " ";
    my @r      = ( $format =~ m/([a-zA-Z]\d*\s*)/g );
    my @var;
    for ( 0 .. $#r )
    {
        unshift @var, pop @{ $work1 };
    }
    my @ret;
    push @ret,, pack( $format, @var );
    return \@ret, 2 + $#r;
};

=head2 a b UNPACK

      unpack the value 'a' with the format 'b'
      20040608,a4 a2 a2,PACK -> 2004,06,08
      see unpack in perl
	
=cut

$dict{ 'UNPACK' } = sub {
    my $work1  = shift;
    my $format = pop @{ $work1 };
    my $var    = pop @{ $work1 };
    my @ret;
    push @ret, unpack( $format, $var );
    return \@ret, 2;
};

########################
# stack operators
########################

=head1 STACK operators

.

=head2	a b SWAP

	return 'b' 'a'

=cut

$dict{ 'SWAP' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, $a, $b;
    return \@ret, 2;
};

=head2	a b OVER

	return 'a' 'b' 'a'

=cut

$dict{ 'OVER' } = sub {
    my $work1 = shift;
    my @ret;
    push @ret, @{ $work1 }[-2];
    return \@ret, 0;
};

=head2	a DUP

	return 'a' 'a'

=cut

$dict{ 'DUP' } = sub {
    my $work1 = shift;
    my @ret;
    push @ret, @{ $work1 }[-1];
    return \@ret, 0;
};

=head2	a b DDUP

	return 'a' 'b' 'a' 'b'

=cut

$dict{ 'DDUP' } = sub {
    my $work1 = shift;
    my @ret;
    push @ret, @{ $work1 }[-2], @{ $work1 }[-1];
    return \@ret, 0;
};

=head2	a b c ROT

	return 'b' 'c' 'a'

=cut

$dict{ 'ROT' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my $c     = pop @{ $work1 };
    my @ret;
    push @ret, $b, $a, $c;
    return \@ret, 3;
};

=head2	a b c RROT

	return 'c' 'a' 'b'

=cut

$dict{ 'RROT' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my $c     = pop @{ $work1 };
    my @ret;
    push @ret, $a, $c, $b;
    return \@ret, 3;
};

=head2	DEPTH

	return the number of elements on the stack

=cut

$dict{ 'DEPTH' } = sub {
    my $work1 = shift;
    my $ret   = scalar @{ $work1 };
    my @ret;
    push @ret, $ret;
    return \@ret, 0;
};

=head2	a b POP

	remove the last element on the stack

=cut

$dict{ 'POP' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    return \@ret, 1;
};

=head2	a ... z POPN

	remove the 'z' last elemnet(s) from the stack

=cut

$dict{ 'POPN' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    for ( 1 .. $a )
    {
        pop @{ $work1 };
    }
    my @ret;
    return \@ret, 1 + $a;
};

=head2	a b c d e f ROLL

	rotate the stack on 'f' element
	a,b,c,d,e,4,ROLL -> a c d e b
	if n= 3 = ROT

=cut

$dict{ 'ROLL' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @tmp   = splice @{ $work1 }, -( $a - 1 );
    my $b     = pop @{ $work1 };
    my @ret;
    push @ret, @tmp, $b;
    return \@ret, 1 + $a;
};

=head2 a PICK
	
	copy element 'a' to the stack

=cut

$dict{ 'PICK' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    push @ret, @{ $work1 }[ -( $a + 1 ) ];
    return \@ret, 1;
};

=head2 a GET
	
	get (remove) element N'a' to the stack

=cut

$dict{ 'GET' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $b     = @{ $work1 }[ -( $a ) ];
    my @tmp   = splice @{ $work1 }, -( $a - 1 );
    $b     = pop @{ $work1 };
    my @ret;
    push @ret, @tmp, $b;
    return \@ret, 1 + $a;
};

=head2 a b PUT
	
	put element 'a' at the level 'b' of the stack
	if 'b' gretaer than the stack put at first place
	if 'b' < 0 start to the reverse order of the stack

=cut

$dict{ 'PUT' } = sub {
    my $work1 = shift;
    my $len   = scalar @{ $work1 };
    my $a     = pop @{ $work1 };
    my $b     = pop @{ $work1 };
    my @tmp;
    my @ret = @{ $work1 };
    if ( $a >= ( scalar( @{ $work1 } ) ) )
    {
        $a = scalar( @{ $work1 } );
    }
    if ( $a )
    {
        @tmp = splice @ret, -$a;
    }
    push ( @ret, $b, @tmp );
    return \@ret, $len;
};

=head2 a b DEL
	
	delete 'b' element on the stack from lebvel 'a'
	'a' and 'b' is get in absolute value 

=cut

$dict{ 'DEL' } = sub {
    my $work1  = shift;
    my $len    = scalar( @{ $work1 } );
    my $start  = abs pop @{ $work1 };
    my $length = abs pop @{ $work1 };
    my @temp;
    @temp = splice @{ $work1 }, $len - 2 - $start - $length, $length;
    my @ret;
    push ( @ret, @{ $work1 } );
    return \@ret, $len;
};

=head2 a FIND
	
	get the level of stack containing the value 'a'

=cut

$dict{ 'FIND' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my $ret;
    for ( 1 .. scalar( @{ $work1 } ) )
    {
        my $b = @{ $work1 }[ ( scalar( @{ $work1 } ) ) - $_ + 1 ];
        if ( $a =~ /^(\d+|\d+\.\d*|\.\d*)$/ )
        {
            if ( $b == $a )
            {
                $ret = $_;
                last;
            }
        }
        else
        {
            if ( $b eq $a )
            {
                $ret = $_;
                last;
            }
        }
    }
    my @ret;
    push ( @ret, $ret );
    return \@ret, 1;
};

########################
# DICT operator
########################

=head1 DICTIONARY and VARS operators

.

=head2 WORDS

        return as one stack element the list of WORD in DICT separated by a |
	
=cut

$dict{ 'WORDS' } = sub {
    my @tmp = join " | ", keys( %dict );
    my @ret;
    push @ret, @tmp;
    return \@ret, 0;

};

=head2 VARS

        return as one stack element the list of VARS  separated by a |
	
=cut

$dict{ 'VARS' } = sub {
    my @tmp = join " | ", keys( %var );
    my @ret;
    push @ret, @tmp;
    return \@ret, 0;
};

=head2 INC

        incremente (+ 1) the value of the variable on the statck
	
=cut

$dict{ 'INC' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    ( $var{ $a } )++;
    my @ret;
    return \@ret, 1;
};

=head2 DEC

        decremente (- 1) the value of the variable on the statck
	
=cut

$dict{ 'DEC' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    ( $var{ $a } )--;
    my @ret;
    return \@ret, 1;
};

=head2 VARIABLE xxx

       deckare the variable 'xxx' (reserve memory)
	
=cut

$dict{ 'VARIABLE' } = sub {
    my $work1 = shift;
    my $a     = pop @{ $work1 };
    my @ret;
    $var{ $a } = '';
    return \@ret, 1;
};

=head2 xx var1 !

        set the value xx to the variable var1
	
=cut

$dict{ '!' } = sub {
    my $work1 = shift;
    my $name  = pop @{ $work1 };
    my $val   = pop @{ $work1 };
    $var{ $name } = $val;
    my @ret;
    return \@ret, 2;
};

=head2  var1 @

        reyrn the value of the variable var1
	
=cut

$dict{ '@' } = sub {
    my $work1 = shift;
    my $name  = pop @{ $work1 };
    my @ret;
    push @ret, $var{ $name };
    return \@ret, 1;

};

=head2 : name1 xxx ;

        create a new entry in the dictionary whith name name1 and store the progam xxx
	
=cut

$dict{ ';' } = sub {
    my $work1   = shift;
    my $return1 = shift;
    my $len     = scalar( @{ $work1 } );
    my $b_ref   = pop @{ $return1 };
    my $a_ref   = pop @{ $return1 };
    my @pre     = @{ $work1 };
    my @BLOCK   = splice @pre, $a_ref, $b_ref - $a_ref;
    my @ret;
    pop @pre;
    my $name = shift @BLOCK;
    $dict{ $name } = sub {
        my $ret;
        @ret = @BLOCK;
        return \@ret, 0;
    };
    return \@ret, $#BLOCK + 2, 2;
};

=head2 a >R

        put 'a' on the return stack
	
=cut

$dict{ '>R' } = sub {
    my @ret;
    my $work1 = shift;
    my $val   = pop @{ $work1 };
    push @ret, $val;
    return \@ret, 1, -1;
};

=head2 R>

       remove first element from the return stack and copy on the normal stack
	
=cut

$dict{ 'R>' } = sub {
    my @ret;
    my $work1   = shift;
    my $return1 = shift;
    my $val;
    if ( scalar @{ $return1 } )
    {

        push @ret, pop @{ $return1 };
    }
    return \@ret, 0, 1;
};

=head2 RL

       return the depth of the return stack
	
=cut

$dict{ 'RL' } = sub {
    my @ret;
    my $work1   = shift;
    my $return1 = shift;
    push @ret, scalar @{ $return1 };
    return \@ret, 0;
};

=head2 R@

       copy return stack ion normal stack
	
=cut

$dict{ 'R@' } = sub {
    my @ret;
    my $work1   = shift;
    my $return1 = shift;
    push @ret, @{ $return1 };
    return \@ret, 0;
};

########################
# loop operators
########################

=head1 LOOP and DECISION operators

.

=head2 a IF xxx THEN

	test the element on top of stack 
		if ==0 execute 'xxx' block
		
	The loop is executed always one time

=cut

$dict{ 'THEN' } = sub {
    my @ret;
    my $work1   = shift;
    my $return1 = shift;
    my $b_ref   = pop @{ $return1 };
    my $a_ref   = pop @{ $return1 };
    my @pre     = @{ $work1 };
    my @BEGIN   = splice @pre, $a_ref +1   , $b_ref - $a_ref - 1;
    my $len     = scalar @BEGIN;
    my $r = scalar @{ $work1 };
    my $i = $r-$len-2;
    my $res=  $pre[$i];
    if ( $res )
    {
        process( \@BEGIN );
        push @ret, @BEGIN;
    }
    return \@ret, 2 + $len, 2;
};

=head2 a IF zzz ELSE xxx THEN

	test the element on top of stack 
		if ==0 execute 'xxx' block
		if != 0 execute 'zzz' block 
		
	The loop is executed always one time

=cut

$dict{ 'THENELSE' } = sub {
    my @ret;
    my $work1   = shift;
    my $return1 = shift;
    my $c_ref   = pop @{ $return1 };
    my $b_ref   = pop @{ $return1 };
    my $a_ref   = pop @{ $return1 };
    my @pre     = @{ $work1 };
    my @ELSE    = splice @pre, $a_ref +1  , $b_ref - $a_ref - 1;
    @pre = @{ $work1 };
    my @THEN = splice @pre, $b_ref +1  , $c_ref - $b_ref - 1;
    my $len = scalar @ELSE + scalar @THEN;
    my $r = scalar @{ $work1 };
    my $i = $r-$len-3;
    my $res= $pre[$i];
    if ( $res )
    {
        process( \@THEN );
        push @ret, @THEN;
    }
    else
    {
        process( \@ELSE );
        push @ret, @ELSE;
    }
    return \@ret, 3 + $len, 3;
};

=head2 BEGIN xxx WHILE zzz REPEAT

	execute 'xxx' block
	test the element on top of stack 
		if ==0 execute 'zzz' block and brabch again at 'BEGIN'
		if != 0 end the loop
		
	The loop is executed always one time


=cut

$dict{ 'REPEAT' } = sub {
    my @ret;
    my $work1   = shift;
    my $return1 = shift;
    my $c_ref   = pop @{ $return1 };
    my $b_ref   = pop @{ $return1 };
    my $a_ref   = pop @{ $return1 };
    my @pre     = @{ $work1 };
    my @BEGIN   = splice @pre, $a_ref, $b_ref - $a_ref;
    my @BEGIN2  = @BEGIN;
    my @BEGIN3  = @BEGIN;
    my $len     = scalar( @BEGIN );
    @pre = @{ $work1 };
    my @WHILE = splice @pre, $b_ref + 1, $c_ref - $b_ref;
    my @WHILE2 = @WHILE;
    @pre = @{ $work1 };
    process( \@BEGIN2 );
    my $res = pop @BEGIN2;

    if ( $res )
    {
        push @ret, @BEGIN2;
        $len += scalar( @WHILE );
        process( \@WHILE );
        push @ret, @WHILE;
        @BEGIN = splice @pre, $a_ref, $b_ref - $a_ref;
        push @ret, 'BEGIN', @BEGIN, 'WHILE', @WHILE2,, 'REPEAT';
        return \@ret, $len + 1, 3;
    }
    return \@ret, $len + 4, 3;
};

=head2  end start DO,block,LOOP

	process 'block' with iterator from value 'start' untill 'end' value,with increment of 1;
	The iterator variable is '_I_' (read only)
	
=cut

$dict{ 'LOOP' } = sub {
    my $work1   = shift;
    my $return1 = shift;
    my $len     = scalar( @{ $work1 } );
    my $b_ref   = pop @{ $return1 };
    my $a_ref   = pop @{ $return1 };
    my @pre     = @{ $work1 };
    my @BLOCK   = splice @pre, $a_ref + 1, $b_ref - $a_ref;
    pop @pre;
    my $a   = pop @pre;
    my $b   = pop @pre;
    my $ind = $a;
    my @ret;

    if ( $ind <= $b )
    {
        $ind++;
        my @OLD_BLOCK = @BLOCK;
        for ( my $i = 0 ; $i <= $#BLOCK ; $i++ )
        {
            if ( $BLOCK[$i] =~ /_I_/ )
            {
                $BLOCK[$i] = $ind;
            }
        }
        process( \@BLOCK );
        push @pre, @BLOCK, $b, $ind, "DO", @OLD_BLOCK, "LOOP";
    }
    return \@pre, $len + 1;
};

=head2  end start increment DO,block,LOOP

	process 'block' with iterator from value 'start' untill 'end' value,with increment of 'increment' 
	This allow rational or negative value
	The iterator variable is '_I_' (read only)
	Not like FORTH, ythe increment is on the stack before the DO
	
=cut

$dict{ '+LOOP' } = sub {
    my $work1   = shift;
    my $return1 = shift;
    my $len     = scalar( @{ $work1 } );
    my $b_ref   = pop @{ $return1 };
    my $a_ref   = pop @{ $return1 };
    my @pre     = @{ $work1 };
    my @BLOCK   = splice @pre, $a_ref + 1, $b_ref - $a_ref;
    pop @pre;
    my $b   = pop @pre;
    my $c   = pop @pre;
    my $a   = pop @BLOCK;
    my $ind = $b;
    my @ret;

    if ( $a < 0 )
    {
        if ( $ind >= $c )
        {
            $ind += $a;
            my @OLD_BLOCK = @BLOCK;
            for ( my $i = 0 ; $i <= $#BLOCK ; $i++ )
            {
                if ( $BLOCK[$i] =~ /_I_/ )
                {
                    $BLOCK[$i] = $ind;
                }
            }
            process( \@BLOCK );
            push @pre, @BLOCK, $c, $ind, "DO", @OLD_BLOCK, $a, "+LOOP";
        }
    }
    else
    {
        if ( $ind <= $c )
        {
            $ind += $a;
            my @OLD_BLOCK = @BLOCK;
            for ( my $i = 0 ; $i <= $#BLOCK ; $i++ )
            {
                if ( $BLOCK[$i] =~ /_I_/ )
                {
                    $BLOCK[$i] = $ind;
                }
            }
            process( \@BLOCK );
            push @pre, @BLOCK, $c, $ind, "DO", @OLD_BLOCK, $a, "+LOOP";
        }
    }
    return \@pre, $len + 1, 2;
};

#####################################
# main code
#####################################
sub parse
{
    my $remainder = shift;
    $remainder =~ s/^,//;
    my $before;
    my $is_string = 0;
    if ( $remainder =~ /^('|")(.*)/ )
    {
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
    my $item = shift;
    my @stack;   
    while ( $item )
    {
        my $elem;
        my $is_string;
        ( $elem, $item, $is_string ) = parse( $item );
        if ( $is_string )
        {
            push @stack, "'" . $elem . "'";
        }
        else
        {
            push @stack, $elem;
        }
    }
    process( \@stack );
    my $ret = join " ", @stack;
    return $ret;
}

sub process
{
    my $stack = shift;
    my $is_block;
    my $is_begin;
    my $is_while;
    my $is_do;
    my $is_else;
    my @work;
    while ( @{ $stack } )
    {
        my $op        = shift @{ $stack };
        my $is_string = 0;
        my $tmp_op    = $op;
        $tmp_op =~ s/^\s+//g;
        $tmp_op =~ s/\s+$//g;
        if ( exists( $dict{ $tmp_op } ) || exists( $var{ $tmp_op } ))
        {
            $op =~ s/^\s+//g;
            $op =~ s/\s+$//g;
        }
        if ( ( $op =~ /^VARIABLE$/g ) )
        {
            push @work, shift @{ $stack };
        }
        if ( $op =~ s/^'(.*)'$/$1/g )
        {
            $is_string = 1;
        }
        if ( $op =~ /^;$/g )
        {
            $is_block = 0;
            push @return, ( scalar( @work ) );
        }
        if ( $op =~ /^:$/g )
        {
            $is_block = 1;
            push @return, ( scalar( @work ) );
            next;
        }
        if ( $op =~ /^BEGIN$/g )
        {
            $is_begin = 1;
            push @return, ( scalar( @work ) );
            next;
        }
        if ( ( $op =~ /^WHILE$/g ) )
        {
            $is_begin = 0;
            $is_do    = 1;
            push @return, ( scalar( @work ) );
        }
        if ( $is_do && ( $op =~ /^REPEAT$/g ) )
        {
            $is_do = 0;
            push @return, ( scalar( @work ) - 1 );
        }
        if ( $op =~ /^DO$/g )
        {
            $is_do = 1;
            push @return, ( scalar( @work ) );
        }
        if ( ( $op =~ /^LOOP|\+LOOP$/g ) )
        {
            $is_do = 0;
            push @return, scalar( @work );
        }
        if ( $op =~ /^IF$/g )
        {
            $is_do = 1;
            push @return, ( scalar( @work ) );
        }
        if ( $op =~ /^ELSE$/g )
        {
            $is_else = 1;
            push @return, ( scalar( @work ) );
        }

        if ( $op =~ /^THEN$/g )
        {
            $is_do = 0;
            push @return, ( scalar( @work ) );
            if ( $is_else )
            {
                $op = "THENELSE";
            }
        }
        if ( !$is_string )
        {
            if ( $is_do || $is_begin )
            {
                push @work, $op;
            }
            else
            {
                if ( defined( $dict{ $op } ) )
                {
                    my @work_stack   = @work;
                    my @return_stack = @return;
                    my ( $ret, $remove_stack, $remove_return ) = $dict{ $op } ( \@work_stack, \@return_stack );
                    if ( $remove_return >= 0 )
                    {
                        for ( 1 .. $remove_return )
                        {
                            pop @return;
                        }
                    }
                    else
                    {
                        my $to_ret = pop @{ $ret };
                        push @return, $to_ret;
                    }
                    for ( 1 .. $remove_stack )
                    {
                        pop @work;
                    }
                    unshift @{ $stack }, @work, @{ $ret };
                    undef @work;
                }
                else
                {
                    push @work, $op;
                }
            }
        }
        else
        {
            push @work, $op;
        }

    }
    unshift @{ $stack }, @work;
}

1;
__END__

=head1 OPERATORS

     The operators get value from the stack and push the result on top
     In the following explanation, the stack is represented as a pair of brackets ()
     and each elements by a pair of square barcket []
     The left part is the state before evalutation 
     and the right part is the state of the stack after evaluation 

	Arithmetic operators
	---------------------
            +  			([a][b])		([a+b])
	    -  			([a][b])		([a-b])
	    *  			([a][b])		([a*b])
            /  			([a][b])		([a/b])
	    **     		([a][b])		([a**b])
            1+ 			([a]) 			([a+1])
	    1- 			([a]) 			([a-1])
	    2+ 			([a]) 			([a+2])
	    2- 			([a]) 			([a-2])    
            MOD  		([a][b])		([a%b])
            ABS     		([a][b])		([ABS a])
            INT     		([a][b])		([INT a])
	    +-		        ([a]) 			([-a])
	    REMAIN	        ([a]) 			([a- INT a])
	    
	Rationnal operators
	-------------------  
            SIN			([a]) 			([SIN a])	Unit in radian
            COS			([a]) 			([COS a])	Unit in radian
            TAN			([a]) 			([TAN a])	Unit in radian
            CTAN		([a]) 			([CTAN a])	Unit in radian
	    LN		        ([a]) 			([LOG a])
            EXP		        ([a]) 			([EXP a])
	    PI						([3.14159265358979])	
	    
	Logical operator
	----------------
	    <		       	([a][b])		([1]) if [a]<[b] else ([0])
	    <=		       	([a][b])		([1]) if [a]<=[b] else ([0])
	    >		       	([a][b])		([1]) if [a]>[b] else ([0])
	    >=		       	([a][b])		([1]) if [a]>=[b] else ([0])    
	    == 	        	([a][b])		([1]) if [a]==[b] else ([0])
	    <=>	     	       	([a][b])		([-1]) if [a]>[b],([1]) if [a]<[b], ([0])if [a]==[b]
            != 	        	([a][b])		([0]) if [a]==[b] else ([1])
	
	Other operator
	----------------
            MIN	     	       	([a][b])		([a]) if  [a]<[b] else ([b]) 
            MAX		       	([a][b])		([a]) if  [a]>[b] else ([b]) 
            TICK		()			([time]) time in ticks
	    LTIME		([a])			([min][hour][day_in_the_month][month][year][day_in_week][day_year][daylight_saving]
							localtime of [a] like PERL
	    GTIME		([a])			([min][hour][day_in_the_month][month][year][day_in_week][day_year][daylight_saving]
							([a]) gmtime of [a] like PERL
	    HLTIME		([a])			([a]) localtime human readeable
	    HGTIME		([a])			gmtime human readeable		
            RAND		()			([rand]) a random numder between 0 and 1
            LRAND		([a])			([rand]) a random numder between 0 and [a]
	    SPACE		([a])			Return [a] with space between each 3 digits
	    DOT			([a])			Return [a] with dot (.) between each 3 digits
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
            LEN 		([a])			([LENGTH a])
	    CAT			([a][b])		([ab])	String concatenation
            REP			([a][b])		([a x b]) repeat [b] time the motif [a]
	    REV			([a])			([REVERSE a])
            SUBSTR		([a][b][c])		([SUBSTR [a], [b], [c]) get substring of [a] starting from [b] untill [c]
            UC			([a])			([UC a])
            LC			([a])			([LC a])
            UCFIRST		([a])			([UCFIRST a])
            LCFIRST		([a])			([LCFIRST a])
            PAT			([a][b])		([r1]...) use the pattern [b] on the string [a] and return result 
	    						if more then one result like $1, $2 ... return all the results 
	    PATI		([a][b])		([r1]...) use the pattern CASE INSENSITIVE [b] on the string [a] and return result 
	    						if more then one result like $1, $2 ... return all the results 						
	    TPAT		([a][b])		([r]) use the pattern [b] on the string [a] and return 1 if pattern macth 
	    						otherwise return 0
	    TPATI		([a][b])		([r]) use the pattern CASE INSENSITIVE [b] on the string [a] and return 1 if pattern macth 
	    						otherwise return 0
	    SPLIT		([a][b])		split ([a]) using the pattern ([b]) and return all elements on stack
	    SPLITI					split ([a]) using the pattern CASE INSENSITIVE  ([b])) and return all elements on stack					
	    SPAT		([a][b][c])		Do a pattern subsititution following this rule I<[c] =~s/[a]/[b]/>
	    SPATG		([a][b][c])		Do a pattern subsititution following this rule I<[c] =~s/[a]/[b]/g>
	    SPATI		([a][b][c])		Do a pattern subsititution following this rule I<[c] =~s/[a]/[b]/i> 
	    						(case insensitive)
	    SPATGI		([a][b][c])		Do a pattern subsititution following this rule I<[c] =~s/[a]/[b]/gi> 
	    						(case insensitive)
	    PRINTF     	        ([a][b]...[x])          use the format present in [a] to print the value [b] to [x] 
	    						the format is the same as (s)printf 
	    PACK                ([a][b]...[x])	        Do an unpack on variable [b] to [x] using format [b] 
	    UNPACK              ([a][b])		Do an unpack on variable [b] using format [a]
	    
 
	 Stack operators
	 ---------------
            	
            SWAP		([a][b])		([b][a])
            OVER		([a][b])		([a][b][a])
	    DUP			([a])			([a][a])
	    DDUP		([a][b])		([a][b][a][b])
	    ROT			([a][b][c])     	([b][c][a])
	    RROT		([a][b][c])     	([c][a][b])
	    DEPTH		([r1]...)		([re1]...[nbr])	Return the number of elements in the statck
	    POP			([a][b])		([a])
	    POPN                ([a][b][c]...[x])	([l]...[x]) remove [b] element from the stack (starting at [c])
	    DEL			([a][b][c][d]...[x])	([c]...[n][m]...[x]) delete [b] elements from element number [a]
	    SWAP2		([a][b][c])     	([a][c][b])
            ROLL		([a][b][c][d][e][n])	([a][c][d][e][b]) rotate the [n] element of the stack (here [n]=4)
	    						if  [n] =3 it is equivalent to ROT
	    PICK		([a][b][c][d][e][n])    ([a][b][c][d][e][b]) copy element [n] on top 
	    GET			([a][b][c][d][e][n])    ([a][b][c][d][e][b]) get element [n] and put on top 
	    PUT			([a][b][c][d][v][n])	([a][v][b][c][d]) put element [v] at level [n] (here [n]=3)
	    DEL			([a][b])		delete [b] element on the stack from lebvel [a]
               						[a] and [b] is get in absolute value	    
	    FIND		([a])     		get the level of stack containing [a]

            
	 Dictionary operators
	 --------------------	 
	  
	    WORDS		()			([a])return as one stack element the list of WORD in DICT separated by a |	
	    VARS   		()			([a])return as one stack element the list of VARIABLE in VAR separated by a |				
            INC			([a])     		() increment (+1) the value of variable [a]
            DEC			([a])     		() decrement (-1) the value of variable [a]
            VARIABLE            ([a])			() create a entry in VAR for the variable [a]
	    !			([a][b])		store the value [a] in the variable [b]
	    @			([a])			([a]) return the value of the variable [a]
            : xxx ;					create a new word (sub) into the dictionary with the xxx "code"

	
 	 Return Stack operators
	 ----------------------
	 
	   >R        		([a])			put ^a$ on the return stack
	   R>			()			remove first element from the return stack and copy on the normal
	   RL			()			return the depth of the return stack
	   R@			()			copy return stack ion normal stack

	LOOP and DECISION operators
   	---------------------------
	
	 [a] IF [..xxx] THEN				Test the element on top of stack
                       					  if ==0, execute 'xxx' block
							The loop is executed always one time
	 
	 [a] IF [...zzz...] ELSE [..xxx...] THEN	Test the element on top of stack
                       					  if ==0, execute 'xxx' block
                       					  if != 0 execute 'zzz' block
							The loop is executed always one time

         BEGIN xxx WHILE zzz REPEAT			Execute 'xxx' block
							Test the element on top of stack
                       					  if ==0 execute 'zzz' block and branch again to BEGIN
                       					  if != 0 end the loop
							The loop is executed always one time

 	[a] [b] DO [...xxx...] LOOP	([a][b])	process block [...xxx...] with iterator from value [b] untill [a] value,
							with increment of 1;
               						The iterator variable is '_I_' (read only and scoop only the DO ... LOOP block)
	
	[a] [b] DO [...xxx...] [c] LOOP	([a][b])	rocess block [...xxx...] with iterator from value [b] untill [a] value,
							with increment of [c];
               						The iterator variable is '_I_' (read only and scoop only the DO ... LOOP block)


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
	
	$test = "'Hello,world',',',pat,',',eq,'Contain a coma','Without a coma',if";
	$ret = rpn($test);  # $ret = "Contain a coma"
	
	$test = "'Hello world',',',pat,',',eq,'Contain a coma','Without a coma',if";
	$ret = rpn($test);  # $ret = "Without a coma"
	
	$test = "3,10,/,5,+,82,*,%b,PRINTF";
	$ret = rpn($test);  # $ret = "110110010"
	
	$test = "3,10,/,5,+,82,*,%016b,PRINTF";
	$ret = rpn($test);  # $ret = "0000000110110010"
	
	$test = "55,N,pack,B32,unpack,^0+(?=\d), ,spat,'+',ds";
	$ret = rpn($test);  # $ret = 110111
	
	$test = "7,3,/,10,3,/,%d %f,PRINTF";
	@ret = rpn($test); # @ret = 2 3.333333
	
	$test = "VARIABLE,a,0,a,!,##,b,BEGIN,bbbb,a,INC,a,@,4,<,WHILE,####,a,@,****,REPEAT";
	@ret =rpn($test); # @ret = ## b bbbb #### 1 **** bbbb #### 2 **** bbbb #### 3 **** bbbb
	
	$test = "VARIABLE,a,0,a,!,z,0,5,-1,DO,a,INC,6,1,2,DO,A,_I_,+LOOP,#,+LOOP,##,a,@";
	@ret =rpn($test); # @ret = z A 3 A 5 A 7 # A 3 A 5 A 7 # A 3 A 5 A 7 # A 3 A 5 A 7 # A 3 A 5 A 7 # A 3 A 5 A 7 # ## 6

=head1 AUTHOR

	Fabrice Dulaunoy <fabrice@dulaunoy.com> 
	It is a full rewrite from the version 1.xx to allow DICTIONNARY use and STRUCTURE control
	Thanks to the module Math::RPN from  Owen DeLong, <owen@delong.com> for the idea of using RPN in a config file

=head1 SEE ALSO

	Math-RPN from  Owen DeLong, <owen@delong.com> 

=head1 TODO

	Error processing, stack underflow...
	
=head1 LICENSE

	Under the GNU GPL2

	This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public 
	License as published by the Free Software Foundation; either version 2 of the License, 
	or (at your option) any later version.

	This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
	without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License along with this program; 
	if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

	Parse::RPN   Copyright (C) 2004 DULAUNOY Fabrice  Parse::RPN comes with ABSOLUTELY NO WARRANTY; 
	for details See: L<http://www.gnu.org/licenses/gpl.html> 
	This is free software, and you are welcome to redistribute it under certain conditions;
   

=cut

