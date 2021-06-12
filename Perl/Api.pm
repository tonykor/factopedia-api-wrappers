package FactopediaAPI;

use strict;
use warnings;

use LWP::UserAgent;
use LWP::ConsoleLogger::Easy  qw( debug_ua );
use JSON 'from_json';
use MIME::Base64 'encode_base64';
use Data::Dumper;

my $URL_API = 'https://api.factopedia.org/';
my %endpoints = (
		objects => {
			get => 1,
			post =>1,
			put =>1,
	},
		properties => {
			get => 1,
			post => 1,
	},
		units => {
			get => 1,
			post => 1,
	},
);
my $contentType = 'multipart/form-data';
my $api_format = 'format=api';

my %expand_values = (
	properties => 1,
	suggestedProperties => 1,
	parents => 1,
	children => 1,
	countChildren => 1,
);
my %property_type = (
	int => 1,
	dec => 1,
	range_int=> 1,
	range_dec=> 1,
	bool=> 1,
	text=> 1,
	object=> 1,
	array=> 1,
	array_of_objects=> 1,
	dynamic=> 1,					 
);
my %property_settings = (
	property_id => 2,
	category_id => 1,
	unit_id => 1,
	value => 1,
	type => 1,
	order_by => 1,
	url => 1,
);
my %object_filter = (
	name => 1,
	parentId => 1,
	lang => 1,
	property => 1,
);
my %object_creation = (
	name => 2,
	lang => 2,
	description => 1,
	image => 1,
	parentID => 1,
	childrenID => 1,
	aliases => 1,
	properties =>1,
);
my %lang_values = ( 	# language codes can be specified here to be included in HTTP requests
	en=>1,
);
my %propertyunit_creation = (
	name => 2,
	lang => 2,
);

sub new {
	my $class = shift;
	my $KEY_API = shift;
	my $DEBUG = shift;
	my $AGENT_LWP = shift || "MyApp/0.1";
	
	my @temp = @_;
	die "Too many arguments" if @temp > 0;
	die "\nOnly 0 or 1 allowed for DEBUG in constructor\n" unless is_bool($DEBUG);
	
	my $self  = {};
	my %options = (
		"username" =>  $KEY_API,
		"password" => ''
		);
	my $ua = LWP::UserAgent->new(keep_alive=>1);
	debug_ua($ua) if $DEBUG;
	$ua->agent($AGENT_LWP);
	$ua->default_header(
		Authorization => 'Basic '. encode_base64( $options{username} . ':' . $options{password} )
	);
	$self->{"_HTTPUSERAGENT"} = \$ua;
	$self->{"_URL"} = \$URL_API;
	bless ($self, $class);
	return $self;
}

sub endPoints {
	my $self = shift;
	my @temp = @_;
	die "Too many arguments" if @temp > 0;
	my $response;
	$response = ${$self->{"_HTTPUSERAGENT"}}->get(${$self->{"_URL"}});
	if ( $response->is_success ) {
		print "This Perl API supports only these end points with HTTP methods\n", Dumper %endpoints, "\n";		
	}
	return [$response->status_line, $response->decoded_content];
}

sub getProperty_ID {
	my $self = shift;
	my $id = shift;
	my @temp = @_;
	die "Too many arguments" if @temp > 0;
	die "\nRequired Property ID\n" if not ($id);
	die "\nOnly integers allowed in ID\n" unless is_integer($id);

	my ($response,$queryString);
	$response = ${$self->{"_HTTPUSERAGENT"}}->get(${$self->{"_URL"}}."/properties/$id");
	
	return [$response->status_line, $response->decoded_content];
}

sub getUnit_ID {
	my $self = shift;
	my $id = shift;
	my @temp = @_;
	die "Too many arguments" if @temp > 0;
	die "\nRequired Unit ID\n" if not ($id);
	die "\nOnly integers allowed in ID\n" unless is_integer($id);

	my ($response,$queryString);
	$response = ${$self->{"_HTTPUSERAGENT"}}->get(${$self->{"_URL"}}."/units/$id");
	return [$response->status_line, $response->decoded_content];
}

sub getCategory_ID {
	my $self = shift;
	my $id = shift;
	my @temp = @_;
	die "Too many arguments" if @temp > 0;
	die "\nRequired Category ID\n" if not ($id);
	die "\nOnly integers allowed in ID\n" unless is_integer($id);

	my ($response,$queryString);
	$response = ${$self->{"_HTTPUSERAGENT"}}->get(${$self->{"_URL"}}."/properties-categories/$id");
	return [$response->status_line, $response->decoded_content];
}

sub getObject_ID {
	my $self = shift;
	my $id = shift;
	my $expand = shift || 0;
	my @temp = @_;
	die "Too many arguments" if @temp > 0;
	die "\nRequired Object ID\n" if not ($id);
	die "\nOnly integers allowed in ID\n" unless is_integer($id);
	
	my ($response,$queryString);
	if (defined $expand and ref($expand) and ref($expand) ne 'ARRAY') {
		die "\nThe input parameter should be a array reference\n";
	}
	elsif (defined $expand and ref($expand) and ref($expand) eq 'ARRAY') {
		foreach my $e (@$expand) {
			die "\nThe expand value '$e' is not a valid value\n" if (not exists($expand_values{$e}));
		}
		$queryString = '?expand='.join(",",keys @$expand);
	}
	else {		
		$response = ${$self->{"_HTTPUSERAGENT"}}->get(${$self->{"_URL"}}."/objects/$id");
	}
	$response = ${$self->{"_HTTPUSERAGENT"}}->get(${$self->{"_URL"}}."/objects/$id$queryString") if $queryString;
	return [$response->status_line, $response->decoded_content];
}

sub getObject_Name {
	my $self = shift;
	my $name = shift;
	my $expand = shift || 0;
	my @temp = @_;
	die "Too many arguments" if @temp > 0;
	die "\nRequired Object Name\n" if not ($name);
	my ($response,$queryString)=('',0);
	
	if ($expand and ref($expand) and ref($expand) ne 'ARRAY') {
		die "\nThe input parameter should be a ARRAY reference\n";
	}
	elsif ($expand and ref($expand) and ref($expand) eq 'ARRAY') {
		foreach my $e (@$expand) {
			die "\nThe expand value '$e' is not a valid value\n" if (not exists($expand_values{$e}));
		}
		$queryString = '&expand='.join(",",@$expand);
	}	
	else {
		$response = ${$self->{"_HTTPUSERAGENT"}}->get(${$self->{"_URL"}}."objects?name=$name");
	}
	$response = ${$self->{"_HTTPUSERAGENT"}}->get(${$self->{"_URL"}}."objects?name=$name$queryString")  if $queryString;
	return [$response->status_line, $response->decoded_content];
}

sub getObject_NameParentID {
	my $self = shift;
	my $name = shift;
	my $parentID = shift;
	my $expand = shift || 0;
	my @temp = @_;
	die "Too many arguments" if @temp > 0;
	die "\nRequired Object Name\n" if not ($name);
	die "\nRequired Object Parent ID\n" if not ($parentID);
	die "\nOnly integers allowed in ID\n" unless is_integer($parentID);
	
	my ($response,$queryString)=('',0);	
	if ($expand and ref($expand) and ref($expand) ne 'ARRAY') {
		die "\nThe input parameter should be a ARRAY reference\n";
	}
	elsif ($expand and ref($expand) and ref($expand) eq 'ARRAY') {
		foreach my $e (@$expand) {
			die "\nThe expand value '$e' is not a valid value\n" if (not exists($expand_values{$e}));
		}
		$queryString = '&expand='.join(",",@$expand);
	}	
	else {
		$response = ${$self->{"_HTTPUSERAGENT"}}->get(${$self->{"_URL"}}."objects?name=$name&parentId=$parentID");
	}
	$response = ${$self->{"_HTTPUSERAGENT"}}->get(${$self->{"_URL"}}."objects?name=$name&parentId=$parentID$queryString")  if $queryString;
	return [$response->status_line, $response->decoded_content];
}

sub getProperty_Name {
	my $self = shift;
	my $name = shift;
	my @temp = @_;
	die "Too many arguments" if @temp > 0;
	die "\nRequired Property Name\n" if not ($name);
	my $response;	
	$response = ${$self->{"_HTTPUSERAGENT"}}->get(${$self->{"_URL"}}."properties?filter[name]=$name&lang=en") if defined $name;
	return [$response->status_line, $response->decoded_content];
}

sub getPropertyLike_Name {
	my $self = shift;
	my $name = shift;
	my @temp = @_;
	die "Too many arguments" if @temp > 0;
	die "\nRequired Property Name\n" if not ($name);
	my $response;	
	$response = ${$self->{"_HTTPUSERAGENT"}}->get(${$self->{"_URL"}}."properties?filter[name][like]=$name&lang=en&sort=asc") if defined $name;
	return [$response->status_line, $response->decoded_content];
}

sub createObject {
	my $self = shift;
	my %arguments = @_;
	my (%payload, $response);
	my @invalidargs = grep { !exists $object_creation{$_} and !exists $object_creation{$_}==1 } keys %arguments;
	my @mandatoryargs = grep { $object_creation{$_} and $object_creation{$_} > 1 } keys %arguments;

	print "\nInvalid Arguments\n", Dumper @invalidargs if scalar @invalidargs>0;
	print "\nMandatory Arguments missing\n" if scalar @mandatoryargs!=2;
	die if scalar @invalidargs>0 or scalar @mandatoryargs!=2;
	die "\nAliases/Properties values should be array referenced\n" if (ref($arguments{'aliases'}) ne 'ARRAY' or ref($arguments{'properties'}) ne 'ARRAY');
	
	if (exists $arguments{'image'}) {
		die "\nInvalid Image File Name\n" if $arguments{'image'} !~ /[A-Za-z0-9_-]+\.(png|jpeg|gif|jpg)/;
	}
	
	die "\nInvalid Language\n" if not exists $lang_values{$arguments{'lang'}};
		
	my @alias = @{$arguments{'aliases'}};
	my @prop = @{$arguments{'properties'}};
	print "\nMissing Aliases\n" if scalar @alias==0;
	print "\nMissing Properties\n" if scalar @prop==0;
	die if scalar @alias==0 or scalar @prop==0;
	print "\nAliases can be maximum two only\n" if scalar @alias>2;
	
	my @invalidproperty = grep { !exists $property_settings{$_} and !exists $property_settings{$_}==1 } map { keys %$_ } @prop;
	my @mandatoryproperty = grep { $property_settings{$_} and $property_settings{$_} > 1 } map { keys %$_ } @prop;
	my @invalidproperty_type = grep { !exists $property_type{$_} and !exists $property_type{$_}==1 } map { ${$_}{'type'} } @prop;

	print "\nInvalid Property Settings\n", Dumper @invalidproperty if scalar @invalidproperty>0;
	print "\nMandatory PropertyID missing\n" if scalar @mandatoryproperty!=scalar @prop;
	print "\nInvalid Property Type\n", Dumper @invalidproperty_type if scalar @invalidproperty_type>0;
	die if scalar @invalidproperty>0 or scalar @mandatoryproperty!=scalar @prop or scalar @invalidproperty_type>0;
	
	foreach my $p (@prop) {
		die "\nProperty ID=".${$p}{'property_id'}." does not exist\n" if (@{getProperty_ID($self,${$p}{'property_id'})}[0] eq "404 Not Found" and exists ${$p}{'property_id'});
		if (exists ${$p}{'category_id'}) {
			die "\nUnit ID=".${$p}{'category_id'}." does not exist\n" if (@{getUnit_ID($self, ${$p}{'category_id'})}[0] eq "404 Not Found");
		}
		if (exists ${$p}{'unit_id'}) {
			die "\nCategory ID=".${$p}{'unit_id'}."does not exist\n" if (@{getCategory_ID($self, ${$p}{'unit_id'})}[0] eq "404 Not Found");
		}
	}	
	
	$payload{'name'} = $arguments{'name'};
    $payload{'lang'} = $arguments{'lang'};
    $payload{'description'} = $arguments{'description'} if exists $arguments{'description'};
	$payload{'parents[0][Objects][id]'} = $arguments{'parentID'} if exists $arguments{'parentID'};
	$payload{'aliases[0]'} = $alias[0];
	$payload{'aliases[1]'} = $alias[1] if exists $alias[1];
	$payload{'Objects[imageFiles][0]'} = [$arguments{'image'}] if exists $arguments{'image'};
	
	map {		
		$payload{"objectsPropertiesValues[".$_->{'property_id'}."][ObjectsPropertiesValues][property_id]"} = $_->{'property_id'};
		$payload{"objectsPropertiesValues[".$_->{'property_id'}."][ObjectsPropertiesValues][unit_id]"} = $_->{'unit_id'} if exists $_->{'unit_id'};
		$payload{"objectsPropertiesValues[".$_->{'property_id'}."][ObjectsPropertiesValues][category_id]"} = $_->{'category_id'} if exists $_->{'category_id'};
		$payload{"objectsPropertiesValues[".$_->{'property_id'}."][ObjectsPropertiesValues][type]"} = $_->{'type'} if exists $_->{'type'};
		$payload{"objectsPropertiesValues[".$_->{'property_id'}."][ObjectsPropertiesValues][value]"} = $_->{'value'} if exists $_->{'value'};
		$payload{"objectsPropertiesValues[".$_->{'property_id'}."][ObjectsPropertiesValues][order_by]"} = $_->{'order_by'} if exists $_->{'order_by'};
		$payload{"Links[".$_->{'property_id'}."][url]"} = $_->{'url'} if exists $_->{'url'};
		 } grep { %$_ } @prop;
		
	$response = ${$self->{"_HTTPUSERAGENT"}}->post(
												    ${$self->{"_URL"}}."/objects",
												    Content_Type => $contentType,
													Content => [ %payload ]
												   );
	return [$response->status_line, $response->decoded_content];
}

sub updateObject {
	my $self = shift;
	my $id = shift;
	my %arguments = @_;
	die "\nRequired Object ID\n" if not ($id);
	die "\nOnly integers allowed in ID\n" unless is_integer($id);
	
	die "\nUpdate Failed as ObjectID=$id does not exist\n" if (getObject_ID($self,$id) eq "404 Not Found");

	my (%payload, $response);
	my @invalidargs = grep { !exists $object_creation{$_} and !exists $object_creation{$_}==1 } keys %arguments;
	print "\nInvalid Arguments\n", Dumper @invalidargs if scalar @invalidargs>0;
	die if scalar @invalidargs>0;	
	
	if (exists $arguments{'image'}) {
		die "\nInvalid Image File Name\n" if $arguments{'image'} !~ /[A-Za-z0-9_-]+\.(png|jpeg|gif|jpg)/;
		$payload{'Objects[imageFiles][0]'} = [$arguments{'image'}];
	}
	
	if (exists $arguments{'lang'}) {
		die "\nInvalid Language\n" if not exists $lang_values{$arguments{'lang'}};
		$payload{'lang'} = $arguments{'lang'};
	}
	
	if (exists $arguments{'aliases'}) {
		die "\nAliases values should be array referenced\n" if (ref($arguments{'aliases'}) ne 'ARRAY');
		my @alias = @{$arguments{'aliases'}};
		die "\nMissing Aliases\n" if scalar @alias==0;
		print "\nAliases can be maximum two only\n" if scalar @alias>2;
		$payload{'aliases[0]'} = $alias[0];
		$payload{'aliases[1]'} = $alias[1] if exists $alias[1];
	}	
	
	if (exists $arguments{'properties'}) {
		die "\nProperties values should be array referenced\n" if (ref($arguments{'properties'}) ne 'ARRAY');
		my @prop = @{$arguments{'properties'}};
		die "\nMissing Properties\n" if scalar @prop==0;
		my @invalidproperty = grep { !exists $property_settings{$_} and !exists $property_settings{$_}==1 } map { keys %$_ } @prop;
		my @mandatoryproperty = grep { $property_settings{$_} and $property_settings{$_} > 1 } map { keys %$_ } @prop;		
		
		print "\nInvalid Property Settings\n", Dumper @invalidproperty if scalar @invalidproperty>0;
		print "\nMandatory PropertyID missing\n" if scalar @mandatoryproperty!=scalar @prop;		
		die if scalar @invalidproperty>0 or scalar @mandatoryproperty!=scalar @prop;
		
		foreach (@prop) {
			if (exists ${$_}{'type'}) {				
				die "\nInvalid Property Type\n" if !exists $property_type{${$_}{'type'}};
			}
		}
		
		foreach my $p (@prop) {
			die "\nProperty ID=".${$p}{'property_id'}." does not exist\n" if (@{getProperty_ID($self,${$p}{'property_id'})}[0] eq "404 Not Found" and exists ${$p}{'property_id'});
			if (exists ${$p}{'category_id'}) {
				die "\nUnit ID=".${$p}{'category_id'}." does not exist\n" if (@{getUnit_ID($self, ${$p}{'category_id'})}[0] eq "404 Not Found");
			}
			if (exists ${$p}{'unit_id'}) {
				die "\nCategory ID=".${$p}{'unit_id'}."does not exist\n" if (@{getCategory_ID($self, ${$p}{'unit_id'})}[0] eq "404 Not Found");
			}
		}
		
		map {		
		$payload{"objectsPropertiesValues[".$_->{'property_id'}."][ObjectsPropertiesValues][property_id]"} = $_->{'property_id'};
		$payload{"objectsPropertiesValues[".$_->{'property_id'}."][ObjectsPropertiesValues][unit_id]"} = $_->{'unit_id'} if exists $_->{'unit_id'};
		$payload{"objectsPropertiesValues[".$_->{'property_id'}."][ObjectsPropertiesValues][category_id]"} = $_->{'category_id'} if exists $_->{'category_id'};
		$payload{"objectsPropertiesValues[".$_->{'property_id'}."][ObjectsPropertiesValues][type]"} = $_->{'type'} if exists $_->{'type'};
		$payload{"objectsPropertiesValues[".$_->{'property_id'}."][ObjectsPropertiesValues][value]"} = $_->{'value'} if exists $_->{'value'};
		$payload{"objectsPropertiesValues[".$_->{'property_id'}."][ObjectsPropertiesValues][order_by]"} = $_->{'order_by'} if exists $_->{'order_by'};
		$payload{"Links[".$_->{'property_id'}."][url]"} = $_->{'url'} if exists $_->{'url'};
		 } grep { %$_ } @prop;
		
	}
	
	$payload{'name'} = $arguments{'name'} if exists $arguments{'name'};
    $payload{'description'} = $arguments{'description'} if exists $arguments{'description'};
	$payload{'parents[0][Objects][id]'} = $arguments{'parentID'} if exists $arguments{'parentID'};
		
	$response = ${$self->{"_HTTPUSERAGENT"}}->put(
												    ${$self->{"_URL"}}."/objects/$id",
												    Content_Type => $contentType,
													Content => [ %payload ]
												   );
	return [$response->status_line, $response->decoded_content];
}

sub createProperty {
	my $self = shift;
	my %arguments = @_;
	my ($response);
	my @invalidargs = grep { !exists $propertyunit_creation{$_} and !exists $propertyunit_creation{$_}==1 } keys %arguments;
	my @mandatoryargs = grep { $propertyunit_creation{$_} and $propertyunit_creation{$_} > 1 } keys %arguments;

	print "\nInvalid Arguments\n", Dumper @invalidargs if scalar @invalidargs>0;
	print "\nMandatory Arguments missing\n" if scalar @mandatoryargs!=2;
	die if scalar @invalidargs>0 or scalar @mandatoryargs!=2;
	
	die "\nInvalid Language\n" if not exists $lang_values{$arguments{'lang'}};
	
	$response = ${$self->{"_HTTPUSERAGENT"}}->post(
												    ${$self->{"_URL"}}."/properties",
													Content => [ name=>$arguments{'name'}, lang=>$arguments{'lang'} ]
												   );
	return [$response->status_line, $response->decoded_content];
}

sub createUnit {
	my $self = shift;
	my %arguments = @_;
	my ($response);
	my @invalidargs = grep { !exists $propertyunit_creation{$_} and !exists $propertyunit_creation{$_}==1 } keys %arguments;
	my @mandatoryargs = grep { $propertyunit_creation{$_} and $propertyunit_creation{$_} > 1 } keys %arguments;

	print "\nInvalid Arguments\n", Dumper @invalidargs if scalar @invalidargs>0;
	print "\nMandatory Arguments missing\n" if scalar @mandatoryargs!=2;
	die if scalar @invalidargs>0 or scalar @mandatoryargs!=2;
	
	die "\nInvalid Language\n" if not exists $lang_values{$arguments{'lang'}};
	
	$response = ${$self->{"_HTTPUSERAGENT"}}->post(
												    ${$self->{"_URL"}}."/units",
													Content => [ name=>$arguments{'name'}, lang=>$arguments{'lang'} ]
												   );
	return [$response->status_line, $response->decoded_content];
}

sub is_integer {
   defined $_[0] && $_[0] =~ /^[+-]?\d+$/;
}

sub is_bool {
   if ( $_[0] =~ /^(0|1)$/) {
	   return 1;
   }
   else {
	   return 0;
   }
}

1;
