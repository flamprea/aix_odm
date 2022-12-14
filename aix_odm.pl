#!perl
# Script Name: AIX ODM Data Dump
# Version: 1.0
# Date: March 5, 2008
# Author: Frank Lamprea
# BladeLogic, Inc.

# Description:
# Retrieve ODM information via a NEXEC call to the target server
# Once the data is returned the structure is converted to INI format
# The code is derived from AIX::ODM - A Perl module for retrieving 
# IBM AIX ODM information

# Extended Object:
# Mode: 	Central Execution
# Grammar:	INI
# Command: perl <script> ??TARGET.HOST?? <C|P>
# The path to the script needs to be in non-NSH format	

# Check Arguments
my $numArgs = $#ARGV + 1;
if ($numArgs ne 2) {
	print "Usage: <script.pl> hostname C|P ";
	print "Where C retrieves Custom ODM Objects\n";
	print "and P retrieves Predefined ODM Objects\n";
	exit 1;
}
	
my $hostName = "$ARGV[0]";
my $mode = "$ARGV[1]";	

sub odm_classes {
  my ${corp} = ${_[0]}?${_[0]}:'C';
  my @classes;
  my @devlist;
  my $class;
  my $devname;
  my %dev;
# Retrieve the list of classes from the ODM
  @classes = `nexec $hostName lsdev -${corp} -r class`;
  foreach ${class} (@classes) {
    chomp(${class});
# Retrieve the list of devices associated with each class from the ODM
    @devlist = `nexec $hostName lsdev -Cc ${class} -F name`;
    foreach ${devname} (@devlist) {
      chomp(${devname});
      ${dev{${devname}}} = ${class};
    }
  }
  return %dev;
};
################################################################
sub odm_class {
  my ${corp} = ${_[0]}?${_[0]}:'C';
  return -1 if ( ${corp} ne 'C' );
  return -1 if (!${_[1]});
# Retrieve the class of a device from the ODM
  my ${devclass} = `nexec $hostName lsdev -${corp} -r class -l ${_[1]}`;
  chomp(${devclass});
  return ${devclass};
};
################################################################
sub odm_subclass {
  my ${corp} = ${_[0]}?${_[0]}:'C';
  return -1 if ( ${corp} ne 'C' );
  return -1 if (!${_[1]});
# Retrieve the subclass of a device from the ODM
  my ${devsub} = `nexec $hostName lsdev -${corp} -r subclass -l ${_[1]}`;
  chomp(${devsub});
  return ${devsub};
};
################################################################
sub odm_attributes {
  my @{line};
  my ${ndx};
  my ${aname};
  my %attrib;

# Retrieve the attributes associated with the device from the ODM
# Two lines are returned, the attribute names are returned on the 
# first line, the attribute values returned on the second.
  my @lines = `nexec $hostName lsattr -EOl ${_[0]}`;

  chomp(${lines[0]});
  ${lines[0]} =~ s/^#//g;
  my (@attr_name) = split(/:/,${lines[0]});

  chomp(${lines[1]});
  ${lines[1]} =~ s/^#//g;
  my (@attr_valu) = split(/:/,${lines[1]});

  ${ndx} = 0;
  foreach ${aname} (@attr_name) {
    ${attrib{${aname}}} = ${attr_valu[${ndx}]};
    ${ndx} = ${ndx} + 1;
  }
  return %{attrib};
};
################################################################
sub odm_dump {
# Create a hash of devices by their associated class
  my ${corp} = ${_[0]}?${_[0]}:'C';
  my %devlist = &odm_classes(${corp});
  my %attrout;
  my %devices;
  my $ndx;
  my $subndx;
  foreach $ndx (keys %devlist) {
# create a hash of attributes associated with each device
    %{attrout} = &odm_attributes(${ndx});
# Add a hash value for 'class' and 'devname'
    ${devices{${ndx}}{'class'}} = ${devlist{${ndx}}};
    ${devices{${ndx}}{'subclass'}} = odm_subclass(${corp},${ndx});
    chomp(${devices{${ndx}}{'subclass'}});
    ${devices{${ndx}}{'devname'}} = $ndx;
    foreach ${subndx} (keys %attrout) {
      ${devices{${ndx}}{${subndx}}} = ${attrout{${subndx}}};
    }
  }
  return %devices;
}

#### MAIN ####
my %odm = odm_dump("$mode");
  while ( ($ndx1, $lev2) = each %odm ) {
    print "[${ndx1}]\n";
	    while ( ($ndx2, $val) = each %$lev2 ) {
	        print "${ndx2}=${odm{${ndx1}}{${ndx2}}}\n";
	    }
  }

exit 0;