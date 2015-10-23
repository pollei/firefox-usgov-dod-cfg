#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: dod_firefox_cli_cfg.pl
#
#        USAGE: ./dod_firefox_cli_cfg.pl  
#
#  DESCRIPTION: Add dod certs to a firefox profile
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: SPC Steve J Pollei
# ORGANIZATION: United States Army Reserve
#      VERSION: 0.0.1
#     REVISION: ---
#     # License: GPLv3+
#===============================================================================

use strict;
use warnings;
use utf8;
use 5.018;

say $ENV{'HOME'};

my $home_dir = $ENV{'HOME'};
my @profiles;
my $pname=$ARGV[0];
my $line;

die unless $home_dir =~ /^\/home\/[a-zA-Z][a-zA-Z0-9_]{0,30}\/?$/ ;
die unless $ARGV[0] =~ /^[a-zA-Z][a-zA-Z0-9_]{0,30}$/ ;
die unless -d $home_dir;

my $ff_dir= $home_dir . '/.mozilla/firefox/';
say $ff_dir;
die unless -d $ff_dir;
die unless -f ($ff_dir . 'profiles.ini');

opendir(my $dh, $ff_dir) || die ;
#@profiles = grep { /^[a-zA-Z0-9]{1,12}\.[a-zA-Z][a-zA-Z0-9_]{0,30}$/ && -d ($ff_dir . $_) } readdir($dh);
@profiles = grep { /^[a-zA-Z0-9]{1,12}\.${pname}$/ && -d ($ff_dir . $_) } readdir($dh);
closedir $dh;
#my @profiles=glob($ff_dir . '*.' . $ARGV[0]);
say $#profiles;
say $profiles[0];
die unless $#profiles == 0;
say 'still alive';

#my @cert_util_args=('certutil', '-L', '-d', ('dbm:' . $profiles[0] . '/'));
my @cert_util_args=('certutil', '-L', '-d', ('dbm:' . $ff_dir . $profiles[0] . '/'));
#my @cert_util_args=('certutil', '-H' );
#system (@cert_util_args);
open(my $cu_fh, '-|' , 'certutil', '-L', '-d', ('dbm:' . $ff_dir . $profiles[0] . '/'));
while ($line = <$cu_fh>) {
  if ($line =~ /[a-z0-9 \-]{1,50}\s+[a-z]{0,9},[a-z]{0,9},[a-z]{0,9}/i) {
    print 'match: ', $line;
  } else
  {
    print 'non-match: ', $line;
  }
}
say 'still alive';
# first get list nicknames in use
# add anything that isn't in there yet
exit;

# certutil -A -n "CN=My SSL Certificate" -t "u,u,u" -d sql:/home/my/sharednssdb -i /home/example-certs/cert.cer
# certutil -A -n "CN=DoD foo" -t "CT,C,c" -d dbm:/home/foo/.mozilla/firefox/foo.bar/ -i dod/dod_ca-123.pem -a
# certutil -A -n "CN=DoD foo" -t "CT,C,c" -d dbm:/home/foo/.mozilla/firefox/foo.bar/ -i dod/dod_ca-123.cer 

# certutil -B -i cert_batch.txt
#
# certutil -U -d dbm:/home/foo/.mozilla/firefox/bar.baz/
# slot: NSS User Private Key and Certificate Services
# token: NSS Certificate DB
#
# slot: NSS Internal Cryptographic Services
# token: NSS Generic Crypto Services
#
# slot: SCM Microsystems Inc. SCR 331 [CCID Interface] (21120816216817)
# token: FOO.BAR.BAZ.9999999999
# modutil -list 
# modutil -list -dbdir /home/spollei/.mozilla/firefox/ze5q0q5s.Army/
# modutil -rawlist -dbdir /home/spollei/.mozilla/firefox/ze5q0q5s.Army/
# modutil -add "Coolkey CAC Card" -libfile /lib64/libcoolkeypk11.so
