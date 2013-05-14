# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;

BEGIN { plan tests => 1 };
$DEBUG = shift;
use Parse::RPN;
ok( 1 );    # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script
$| = 1;
{
local @line;
push @line,  '2,3,4,5,6,7,+,*,1+,-,1-,+-,+,+,2,+,10,/';
push @line,  '7';
push @tests, \@line;
}
{
local @line;
push @line,  '3,8,%016b %08b,PRINTF';
push @line,  '0000000000000011 00001000';
push @tests, \@line;
}
{
local @line;
push @line,  '55,N,PACK,B32,UNPACK,^0+(?=\d), ,SPAT';
push @line,  '110111';
push @tests, \@line;
}
{
local @line;
push @line,  'Hello World,LEN,3,+';
push @line,  '14';
push @tests, \@line;
}
{
local @line;
push @line,  "'Hello,world',',',PAT,',',EQ,IF,'Without a coma',ELSE,'Contain a coma',THEN";
push @line,  'Contain a coma';
push @tests, \@line;
}
{
local @line;
push @line,  '2,3,4,5,6,7,+,*,1+,-,1-,+-,+,+,2,+,10,/';
push @line,  '7';
push @tests, \@line;
}
{
local @line;
push @line,  "'Hello world',',',PAT,',',EQ,IF,'Without a coma',ELSE,'Contain a coma',THEN";
push @line,  'Without a coma';
push @tests, \@line;
}
{
local @line;
push @line,  'PI,4,/,SIN,1,SWAP,/,COS,LN,EXP,TAN,PI,/';
push @line,  '0.0500447489498963';
push @tests, \@line;
}
{
local @line;
push @line,  '12,7,**,NORM';
push @line,  '35.83 M';
push @tests, \@line;
}
{
local @line;
push @line,  "test,DUP,second,third,ROT,4,ROLL,3,PICK,3,GET,DEPTH,PUT";
push @line,  'second test third test third';
push @tests, \@line;
}
{
local @line;
push @line,  "test,DUP,second,third,ROT,4,ROLL,4,ROLL,DEPTH,DUP,1,+,PUT,4,POPN";
push @line,  'third';
push @tests, \@line;
}
{
local @line;
push @line, "VARIABLE,a,0,a,!,##,b,BEGIN,bbbb,a,INC,a,@,3,>,WHILE,####,a,@,****,REPEAT";
push @line,  '## b bbbb #### 1 **** bbbb #### 2 **** bbbb #### 3 **** bbbb';
push @tests, \@line;
}	
{
local @line;
push @line,"0,a,!,z,0,4,DO,a,INC,6,1,DO,A,_I_,2,+LOOP,#,-1,+LOOP,##,a,@";
push @line,"z A 1 A 3 A 5 # A 1 A 3 A 5 # A 1 A 3 A 5 # A 1 A 3 A 5 # A 1 A 3 A 5 # ## 6" ;
push @tests, \@line;
}


$nbr =1;
foreach ( @tests )
{
$nbr++;
    ( $test, $result ) = @{ $_ };
    print "*** $test\n" if ( $DEBUG );
    $ret = rpn( $test );
    print "+++ $ret\n" if ( $DEBUG );
    print "--- $result\n" if ( $DEBUG );
    if ( $ret eq $result )
    {
        state( 0,$nbr );
    }
    else
    {
        state( 1,$nbr );
    }

}

sub state
{
    my ( $stat, $ws ) = @_;

    wait();

    print( $stat ? "not ok $ws\n" : "ok $ws\n" );
}
