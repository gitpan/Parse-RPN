# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;

BEGIN { plan tests => 1 };
use Parse::RPN;
ok( 1 );    # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script
$| = 1;
{
local @line;
push @line,  '2,3,4,5,6,7,+,*,++,-,--,NEG,+,+,2,+,10,/';
push @line,  '7';
push @tests, \@line;
}
{
local @line;
push @line,  '3,8,%016b %08b,PRINTF,du';
push @line,  '0000000000000011 00001000';
push @tests, \@line;
}
{
local @line;
push @line,  '55,N,pack,B32,unpack,^0+(?=\d), ,spat';
push @line,  '110111';
push @tests, \@line;
}
{
local @line;
push @line,  'Hello World,len,3,+';
push @line,  '14';
push @tests, \@line;
}
{
local @line;
push @line,  "'Hello,world',',',pat,',',eq,'Contain a coma','Without a coma',if";
push @line,  'Contain a coma';
push @tests, \@line;
}
{
local @line;
push @line,  "'Hello,world',',',pat,',',eq,'Contain a coma','Without a coma',if";
push @line,  'Contain a coma';
push @tests, \@line;
}
{
local @line;
push @line,  'PI,4,/,sin,1,swap,/,cos,log,exp,tan,PI,/';
push @line,  '0.0500447489498963';
push @tests, \@line;
}
{
local @line;
push @line,  '12,7,pow,NORM';
push @line,  '35.83 M';
push @tests, \@line;
}
{
local @line;
push @line,  "test,DUP,second,third,rot,rot3,4,roll,'+',ds";
push @line,  'test+third+second+test';
push @tests, \@line;
}
{
local @line;
push @line,  "test,DUP,second,third,rot,rot3,4,roll,depth,dup,1,+,put,4,popn";
push @line,  '4';
push @tests, \@line;
}



$nbr =1;
foreach ( @tests )
{
$nbr++;
    ( $test, $result ) = @{ $_ };
#print "test=$test \t result=$result\n";
    $ret = rpn( $test );
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
