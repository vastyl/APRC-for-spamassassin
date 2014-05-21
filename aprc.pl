#!/usr/bin/perl -w

#########################################################################
### AntiPhishing Rules Center for Spamassassin                          
### Script to detect phishing for spamassassin                          
### Phishing url addresses from web phishtank.com                       
###                                                                     
### Copyright (C) 2014 Stanislav Vaštyl (stanislav@vastyl.cz)
###
### This program is free software: you can redistribute it and/or modify
### it under the terms of the GNU General Public License as published by
### the Free Software Foundation, either version 3 of the License, or
### any later version.
###
### This program is distributed in the hope that it will be useful,
### but WITHOUT ANY WARRANTY; without even the implied warranty of
### MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
### GNU General Public License for more details.
###
### You should have received a copy of the GNU General Public License
### along with this program. If not, see <http://www.gnu.org/licenses/>.
#########################################################################

use strict;
use warnings;
use Text::CSV;
use LWP::Simple;
use Data::Dumper;

my $apikey = $ARGV[0] || "";

### url + activation key for phishtank (Without this key, you will be limited to a few downloads per day.)
my $status = getstore("http://data.phishtank.com/data/$apikey/online-valid.csv", "online-valid.csv");

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
#           my $first = substr($columns[1],0,7);
#           if ($first eq "http://" ){
#               my $url = substr($columns[1],7); #7 http://
                push(@result,$columns[1]);
#           } 
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
    my $last = substr($item, -1);
    if ($last eq "/"){
            $item = substr($item, 0, -1);
    }

    my $backslash = "\\/";
    $item =~ s/\./\\./g;
    $item =~ s/\//$backslash/g;
    $item =~ s/\#/\\#/g;
    $item =~ s/\@/\\@/g;
    ### file dump
    print $OUT "uri PHISHTANK_".$sum." \t/".$item."/is\n";
    print $OUT "score PHISHTANK_".$sum." \t 12.0 \n \n";

    print $OUT "uri PHISHTANK_".$sum."_1 \t/".$item."\\//is\n";
    print $OUT "score PHISHTANK_".$sum."_1 \t 12.0 \n \n";
}
close $OUT;
print "Script successful";
