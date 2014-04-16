#!/usr/bin/perl -w

#########################################################################
### Name: AntiPhishing Rules Center for Spamassassin                    #
### Script to detect phishing for spamassassin                          #
### Phishing url addresses from web phishtank.com                       #
### Created by stanislav.vastyl@vsb.cz                                  #
#########################################################################

use strict;
use warnings;
use Text::CSV;
use LWP::Simple;
use Data::Dumper;

### url + activation key for phishtank (Without this key, you will be limited to a few downloads per day.)
my $status = getstore("http://data.phishtank.com/data/71f588497fd15acf20bb79087b1dfd5c91cb770649dd76887f50387b1d6a2578/online-valid.csv", "online-valid.csv");

if ( is_success($status) ){
	print "File downloaded correctly\n";
	} else {
	print "Error downloading file: $status\n";
	exit 0;
}

my $csv = Text::CSV->new();
open (my $csvfile, "<", "online-valid.csv") or die $!;

### parse csv + push array @result
my @result=();
while (my $row = $csv->getline($csvfile)) {
	if ($row) {
		my @columns = @$row;
		if ($columns[1] ne "url"){
#    		my $first = substr($columns[1],0,7);
#    		if ($first eq "http://" ){
#    			my $url = substr($columns[1],7); #7 http://
    			push(@result,$columns[1]);
#    			} 
		}  	
    } else {
    my $err = $csv->error_input;
    print "Failed to parse line: $err";
    exit 0;
    }
}
close $csvfile;
print "Parse and push is correctly \n";	

### escape chars for spamassassin
### uri LOCAL_URI_EXAMPLE   /www\.example\.com\/
### score LOCAL_URI_EXAMPLE 0.1
my $sum = 0;
open my $OUT, ">output.out" or die $!;
print $OUT "###\n### Create file: " .gmtime()."\n### \n\n";
foreach my $item (@result){
	$sum = $sum + 1;
	my $backslash = "\\/";
	$item =~ s/\./\\./g;
	$item =~ s/\//$backslash/g;
	### file dump
	print $OUT "uri PHISHTANK\[".$sum."\] \t".$item."\n";
	print $OUT "score PHISHTANK\[".$sum."\] \t 12.0 \n \n";
} 
close $OUT;
print "Script successful";