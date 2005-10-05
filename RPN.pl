#!/usr/bin/perl


sub Test {
my $a  = shift;
my $b = shift;
my $c = $a/$b;
print "a=$a\tb=$b\ttotal=$c\n";
return $c;

}

use Parse::RPN;

#print "rrrr".Test(7,7);

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
