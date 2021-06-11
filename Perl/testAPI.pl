use lib 'D:/Projects/Perl/factopedia'; ## Path to folder factopedia which contains both files FactopediaAPI.pm and testAPI.pl
use strict;
use warnings;

use FactopediaAPI;
use Data::Dumper;

my $f = FactopediaAPI->new('---API KEY---',0);  # use value 1 for printing DEBUG information of
# HTTP request  while 0 for not printing. The default user-agent is "MyApp/0.1" unless specified as third argument of constructor

my $p = $f->endPoints();  # information about endpoints which this Perl Factopedia API class provides
print Dumper $p;

my $ep; # this object contains return values of function; HTTP status code and result of HTTP request, which is an array where first  element
# of array is HTTP code while second element of array is HTTP result in JSON format.

# getCategory_ID(); to search category via its ID.

#$ep= $f->getObject_ID(42094); # search object via its ID
print "\n\n";
#$ep= $f->getObject_ID(42094, ['properties','suggestedProperties','parents','children','countChildren']); # search object via its ID and expand parameter
#
$ep= $f->getProperty_ID(502);  # search property via its ID
print @$ep[0];  # function return array value at index 0 (HTTP Status Code)
print "\n\n";
print @$ep[1]; # function return array value at index 1 (HTTP response)
print "\n\n";
#
$ep= $f->getProperty_Name('test'); # to get exact property match via its name
print Dumper $ep;
#
$ep= $f->getPropertyLike_Name('test'); # to get property name match with near matches
print Dumper $ep;
#
#$ep= $f->getUnit_ID(92); # search unit via its ID
#
#$ep = $f->getObject_Name('Astronomy',['parents','children','countChildren']);  # search object via its name with or without expand parameter
#
#$ep = $f->getObject_Name('Internet', ['properties','suggestedProperties','parents','children','countChildren'] );
#
#$ep = $f->getObject_Name('Internet');  # search object via its name
##print "\n\n";
#$ep = $f->getObject_NameParentID('BitCoin', 42100, ['properties','suggestedProperties','parents','children','countChildren']);
## search object via its name and Parent ID
#
print "\n\n";
#$ep = $f->getObject_NameParentID('LiteCoin', 42100);
#
## create object method
#$ep = $f->createObject((name=>'abc', lang=>'en', description=>'abcdef', aliases=>['y','z'], parentID=>42100, image=> "4.png",
#	properties=>[ {property_id=>154, category_id => 8, unit_id => 8, value => 125, type => 'int', order_by => 1},
#	                {property_id=>151, value => 'TestProp2', type => 'text', order_by => 2} ],
#	));  ### Object abc details => "id":95890,"url":"https://factopedia.org/95890/abc"
#
#print  $ep;
#
## update object method
#$ep = $f->updateObject(95890, ( 
#	properties=>[ {property_id=>155, category_id => 8, unit_id => 8, value => 24, type => 'int', order_by => 3},
#	                {property_id=>151, value => 'TestProp2', type => 'text', order_by => 2, url => 'http://www.example1.com'} ],
#	));
#print "\n\n";
#
print "\n\n";
## create property method
$ep=$f->createProperty(name=>'testprop', lang=>'en');
print Dumper $ep;
print "\n\n";
## create unit method
$ep=$f->createUnit(name=>'testunit12323', lang=>'en');
print Dumper $ep;
