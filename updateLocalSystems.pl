#!/usr/bin/env perl
#Imports
use strict;
use warnings;
use JSON;
use Data::Dumper;
use LWP::UserAgent;
use Time::Piece;
my $json;
my $message;

#Set up slack connection
my $uri = '';
my $req = HTTP::Request->new( 'POST', $uri );
$req->header( 'Content-Type' => 'application/json' );
$req->content( $json );
my $lwp = LWP::UserAgent->new;
$lwp->request( $req );

my $ping = "ping -c1 -t2"; #Ping command
my @devices = ("syr-web","syr-access","syr-mail","syr-util","syr-sftp");
my @downDevices;
my @upDevices;

my $date = localtime->strftime('%F %T');

foreach (@devices) {
        my $device = $_;
        my $ping_out = `$ping $device 2> /dev/null`;
        chomp ($ping_out);

        if ($ping_out !~ /bytes from/) {
                print "$device isn't pinging, logging\n";
                $date = localtime->strftime('%F %T');
                push @downDevices, $device;
        } else {
                print "$device is up, adding to queue\n";
                push @upDevices, , $device;
        }
}

foreach (@upDevices) {
        print "Updating $_...";
        system("ssh asullivan\@$_ 'sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get autoremove -y'");
        print "done!\n"
}

#####Log polling and script completion
$date = localtime->strftime('%F %T');
my $lastCheck = "Devices checked $date\n";

if (@upDevices) {
$json = "Devices updated $date:\n";
$json = encode_json({text => $json});
#Build URL information
$req->content( $json );
#Make connection and post data
$lwp = LWP::UserAgent->new;
$lwp->request( $req );
}

foreach (@upDevices) {
        $json = "$_\n";
        $json = encode_json({text => $json});
        $req->content( $json );
        $lwp = LWP::UserAgent->new;
        $lwp->request( $req );
}
