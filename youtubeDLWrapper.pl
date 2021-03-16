#!/usr/bin/env perl

#Custom archive script to run against youtube-dl and backup multiple channels/playlists at highest resolution up to 1080p

#Imports
use strict;
use warnings;
use Getopt::Long;

#Global Variables
my $youtubeCommand = "/usr/local/bin/youtube-dl -o '%(playlist)s/%(title)s.%(ext)s' -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --continue --sleep-interval 2 --verbose --ignore-errors --retries 10 --add-metadata --write-info-json --embed-subs --all-subs --download-archive PROGRESS.txt";my $counter = 0;
my $filename;
my $url;
my $logging;

#Get options
GetOptions(     'filename=s' => \$filename,
                'logging' => \ $logging,
                'url=s' => \$url);

#Check if multiple conflicting options used
if ( $url && $filename ) {
  print "Only use --url OR --filename flags! Exiting...\n";
  exit(-1);
  }

if ( $filename) {
  open(my $fh, '<:encoding(UTF-8)', $filename)
    or die "Could not open file '$filename' $!";

  while (my $row = <$fh>) {
    chomp $row;
    if ( $row =~ m/\#/ ) {
        print "Comment detected: $row \n\n";
    }
    else {
      print "URL: $row\n";
      if ($logging) {
        system("$youtubeCommand $row >> log_wrapper.txt 2>&1");
      }
      else {
        system("$youtubeCommand $row 2>&1");
      }
    $counter++;
    print "URL \#$counter completed!\n\n";
    }
  }
  exit(1);
}

if ( $url ) {
  print "URL flag used. Running against URL...\n";
  system("$youtubeCommand $url >> log_wrapper.txt 2>&1");
  print "Completed!\n";
  exit(1);
}

print "It appears no flags were used! Flag examples:\n" .
"--url=https://youtube.com/video \n" .
"--filename=urls.txt\n\n" .
"Exiting!\n";
exit(-1);
