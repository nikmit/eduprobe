#!/usr/bin/perl -w
use strict;
use Data::Dumper;
# This script can be used to start|stop the nc listening processes for every port listed in monitored_tcp or monitored_udp
# Please edit the arrays below to configure the monitored ports, ranges are acceptable e.g. 20-24 will expand to 20 21 22 23 24
# port 22 exluded in testing
my @monitored_tcp = qw (21 80 110 143 220 389 406 443 465 587 636 993 995 1194 1494 3128 3389 5900 8080);
my @monitored_udp = qw (123 1194 4500 5000-5110 7000-7007);

# run with either 'up' or 'down' as a parameter 
my $updown=shift;
my %monitored_all;

&get_ports('tcp');
&get_ports('udp');
&check_used_ports;

sub get_ports {
  my $proto = shift;
  my @array;
  if ($proto eq 'tcp') {
    @array = @monitored_tcp;
  } elsif ($proto eq 'udp') {
    @array = @monitored_udp;
  }
  foreach (@array) {
    if (($_ =~ /^(\d+)-(\d+)$/) and ($1 < $2)) {
      my $low = $1;
      my $high = $2;
      while ($low <= $high) {
	$monitored_all{$proto}{$low}++;
	$low++;
      }
    } elsif ($_ =~ /^\d+$/) {
      $monitored_all{$proto}{$_}++;
    } else {
      die "failed to parse configured port array at port $_";
    }
  }
}
  
sub start { 
  foreach my $proto (keys %monitored_all) {
    foreach my $port (keys %{$monitored_all{$proto}}) {
      system ("/bin/bash ./listener $proto $port &");
      print "started listener for $proto/$port\n";
    }
  }
}
#tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN     
#tcp        0      0 127.0.0.1:25            0.0.0.0:*               LISTEN     
#tcp6       0      0 :::4949                 :::*                    LISTEN     
#tcp6       0      0 :::22                   :::*                    LISTEN     
#tcp6       0      0 ::1:25                  :::*                    LISTEN     
#udp        0      0 158.125.10.31:123       0.0.0.0:*                          
#udp        0      0 127.0.0.1:123           0.0.0.0:*                     

sub check_used_ports {
  my %inuse;
  my @openports = `/bin/netstat -nlp`;
  foreach (@openports) {
    if ($_ =~ /^(tcp|udp)\s+\d+\s+\d+\s+[\d\.]+:(\d+)/) {
      $inuse{$1}{$2}++;
    }
  }
print Dumper %inuse;
}

#sub stop {
#  my @ps = `/bin/ps aux`;
#  foreach (@ps) {
#    if 
#}
