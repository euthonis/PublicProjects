#!/usr/bin/perl

#Scipt to pull all devices as part of monitoring system

use Time::Piece;
use strict;
use warnings;
use DBI;

my $hostname = `hostname`; chomp $hostname;
my $ping = "ping -c1 -t2"; #Ping command
my $dbUser = "root"; #Database User
my $dbPass = ''; #Database password
my @devices;

##### Start DB Connection
my $dbh = DBI->connect('dbi:mysql:monitoring',$dbUser,$dbPass)
or die "Connection Error: $DBI::errstr\n";

#Debug DB connect
print "\nDEBUG: Connection Established to DB\n\n";

my $date = localtime->strftime('%F %T');
my $sql = "INSERT IGNORE INTO log VALUES ('','PollStart','','','$hostname','$date')";
print "DEBUG: SQL update: $sql\n";
my $sth = $dbh->prepare($sql);
$sth->execute
or die "SQL Error: $DBI::errstr\n";

$sql =  "SELECT name FROM objects WHERE monitored !='0' AND is_remote!=1;";
$sth = $dbh->prepare($sql);
$sth->execute
or die "Connection Error: $DBI::errstr\n";

while (my $device = $sth->fetchrow_array() ) {
        print $device . "\n";
        push @devices, $device;
}

foreach (@devices) {
        my $device = $_;
        $sql = "SELECT address FROM objects WHERE name='$_'";
        my $sth = $dbh->prepare($sql);
        $sth->execute
        or die "Connection Error: $DBI::errstr\n";
        my $address = $sth->fetchrow_array();
        my $ping_out = `$ping $address 2> /dev/null`;
        chomp ($ping_out);

        if ($ping_out !~ /bytes from/) {
                print "$hostname isn't pinging, logging\n";
                $date = localtime->strftime('%F %T');
                $sql = "INSERT IGNORE INTO log VALUES ('','$device','down','','$device','$date')";
                print "DEBUG: SQL update: $sql\n";
                $sth = $dbh->prepare($sql);
                $sth->execute
                or die "SQL Error: $DBI::errstr\n";
                print "Updating to down status\n";
                $sql = "UPDATE status SET last_down=NOW(),current_status=0 WHERE name='$device';";
                print "DEBUG: SQL update: $sql\n";
                $sth = $dbh->prepare($sql);
                $sth->execute
                or die "SQL Error: $DBI::errstr\n";
                #####Need to add logic for last change into table here
                print "Checking last status to confirm any changes...\n";
                $sql = "SELECT current_status FROM status WHERE name='$device';";
                $sth = $dbh->prepare($sql);
                $sth->execute
                or die "SQL Error: $DBI::errstr\n";
                my $temp_status = $sth->fetchrow_array();
                if ($temp_status == 0) {
                        print "Device was previously down, nothing to change or update\n";
                }
                else {
                        print "Device was previously up, modifying status accordingly...\n";
                        $sql = "UPDATE status SET last_change=NOW(),current_status=0 WHERE name='$device';";
                        $sth = $dbh->prepare($sql);
                        $sth->execute
                        or die "SQL Error: $DBI::errstr\n";
                }
        } else {
                print "$device is up\n";
                $sql = "UPDATE status SET last_up=NOW() WHERE name='$device';";
                print "$sql\n";
                $sth = $dbh->prepare($sql);
                $sth->execute
                or die "SQL Error: $DBI::errstr\n";
                #####Need to add logic for last change into table here
                print "Checking last status to confirm any changes...\n";
                $sql = "SELECT current_status FROM status WHERE name='$device';";
                $sth = $dbh->prepare($sql);
                $sth->execute
                or die "SQL Error: $DBI::errstr\n";
                my $temp_status = $sth->fetchrow_array();
                if ($temp_status == 1) {
                        print "Device was previously up, nothing to change or update\n";
                }
                else {
                        print "Device was previously down, modifying status accordingly...\n";
                        $sql = "UPDATE status SET last_change=NOW(),current_status=1 WHERE name='$device';";
                        $sth = $dbh->prepare($sql);
                        $sth->execute
                        or die "SQL Error: $DBI::errstr\n";
                }
        }
}

#####Log polling and script completion
$date = localtime->strftime('%F %T');
$sql = "INSERT IGNORE INTO log VALUES ('','PollComplete','','','$hostname','$date')";
print "DEBUG: SQL update: $sql\n";
$sth = $dbh->prepare($sql);
$sth->execute
or die "SQL Error: $DBI::errstr\n";

print "Done! $date\n";
