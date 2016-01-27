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
#      VERSION: 0.0.4
#     REVISION: ---
#     # License: GPLv3+
#===============================================================================

use strict;
use warnings;
use utf8;
use 5.010;
our $VERSION = 0.000_004 ;

use Convert::ASN1;
# http://search.cpan.org/dist/Convert-ASN1/lib/Convert/ASN1.pod
use Convert::PEM;
# http://search.cpan.org/~btrott/Convert-PEM-0.08/lib/Convert/PEM.pm
use Crypt::X509;
# http://search.cpan.org/~ajung/Crypt-X509-0.51/lib/Crypt/X509.pm
use MIME::Base64;
# http://perldoc.perl.org/MIME/Base64.html
use Getopt::Long;
# http://perldoc.perl.org/Getopt/Long.html

# https://metacpan.org/pod/Gtk3
# https://github.com/GNOME/perl-Gtk3
# https://github.com/perl6/gtk-simple/

my %args ;

# say $ENV{'HOME'};

sub default_args {
  my ($arg_ref)=@_;
  my %default_args = (
    'gui' => 0, 'tui' => 0, 'profile-name' => 'USGOV-DOD-default',
    'add-profile' => 1 , 'probe-only' => 0 , 'add-cac-card' => 1,
    'add-now-certs' => 1, 'add-old-certs' => 0, 'add-future-certs' => 0,
    );

  ${$arg_ref}{'profile-name'} //= 'USGOV-DOD-default';
  if (${$arg_ref}{'profile-name'} eq q{} ) {
    ${$arg_ref}{'profile-name'} = 'USGOV-DOD-default';
  }

  if ( (exists ${$arg_ref}{'gui'}) &&
       (exists ${$arg_ref}{'tui'}) &&
       (${$arg_ref}{'gui'} == ${$arg_ref}{'tui'})
    ) {
      say 'confused if graphics or terminal wanted';
      exit 1; }

  if ( !(exists ${$arg_ref}{'gui'}) && !(exists ${$arg_ref}{'tui'}) ) {
    ${$arg_ref}{'gui'} = 0;
    ${$arg_ref}{'tui'} = 1;
  }
  ${$arg_ref}{'probe-only'} //= 0;
  if (${$arg_ref}{'probe-only'}) {
    ${$arg_ref}{'add-profile'} =0;
    ${$arg_ref}{'add-cac-card'} =0;
    ${$arg_ref}{'add-now-certs'} =0;
    ${$arg_ref}{'add-old-certs'} =0;
    ${$arg_ref}{'add-future-certs'} =0;
  }
  ${$arg_ref}{'add-profile'} //=1;
  ${$arg_ref}{'add-cac-card'} //=1;
  ${$arg_ref}{'add-now-certs'} //=1;
  ${$arg_ref}{'add-old-certs'} //=0;
  ${$arg_ref}{'add-future-certs'} //=0;
  return $arg_ref;
}


sub find_profile {
  my ($arg_ref)=@_;
  my $home_dir = $ENV{'HOME'};
  my %ret = (home_exists => 0, profiles_ini_exists => 0, errors => 0 );
  # require a sane environ HOME, PATH, USER
  # USER(bsd) USERNAME LOGNAME(sysv)
  # HOME should be /home/${USERNAME} , /home/foo/${USERNAME}
  # UT_NAMESIZE utmp name limits us to 31 plus null
  # http://www.dwheeler.com/essays/fixing-unix-linux-filenames.html
  # Portable Filename Character Set, defined in 3.276
  #              A-Z, a-z, 0-9, <period>, <underscore>, and <hyphen>
  my @profiles;
  my @lib_dirs = [ '/lib/' , '/lib64/', '/usr/lib64' ];
  # have a list of potential lib directories
  # /usr/lib64/libcoolkeypk11.so
  #
  my $pname=${$arg_ref}{'profile-name'};

  #die unless $home_dir =~ /^\/home\/[a-zA-Z][a-zA-Z0-9_-]{0,30}\/?$/ ;
  #die unless $pname =~ /^(USGOV-DOD-|)[a-zA-Z][a-zA-Z0-9_-]{0,30}$/ ;
  #die unless -d $home_dir;
  if (!($home_dir =~ /^\/home\/[a-zA-Z][a-zA-Z0-9_-]{0,30}\/?$/x ) ||
      !($pname =~ /^(USGOV-DOD-|)[a-zA-Z][a-zA-Z0-9_-]{0,30}$/x ) ||
      !(-d $home_dir) ) {
    $ret{'errors'}=1; return %ret;
  }
  $ret{'home_exists'}=1;

  my $ff_dir= $home_dir . '/.mozilla/firefox/';
  say $ff_dir;
  #die unless -d $ff_dir;
  #die unless -f ($ff_dir . 'profiles.ini');
  if ( !(-d $ff_dir) || !(-f ($ff_dir . 'profiles.ini')) ) {
    $ret{'errors'}=1; return %ret;
  }
  $ret{'profiles_ini_exists'}=1;

  # http://kb.mozillazine.org/Transferring_data_to_a_new_profile_-_Firefox
  # http://kb.mozillazine.org/Profile_folder_-_Firefox

  # find the profile given on the command line
  my $dh;
  opendir $dh, $ff_dir;

  if (! $dh ) { $ret{'errors'}=1; return %ret; }
  #@profiles = grep { /^[a-zA-Z0-9]{1,12}\.[a-zA-Z][a-zA-Z0-9_]{0,30}$/ && -d ($ff_dir . $_) } readdir($dh);
  #
  @profiles = grep { /^[a-zA-Z0-9]{1,12}\.${pname}$/x &&
                  -d ($ff_dir . $_) } readdir $dh;
  closedir $dh;

  #my @profiles=glob($ff_dir . '*.' . $ARGV[0]);
  say $#profiles;
  say $profiles[0];
  #die unless $#profiles == 0;
  if ($#profiles != 0) {
    $ret{'errors'}=1; return %ret;
  }
  $ret{'profile_exists'}=1;
  say 'still alive';
  return %ret;
}

# 'new-profile' => 0 , 'probe-only' => 0
GetOptions( \%args,
  'gui!' , 'tui!' , 'profile-name:s' , 'probe-only!',
  'add-cac-card!', 'add-now-certs!', 'add-old-certs!', 'add-future-certs!',
  'help|?');

default_args(\%args);

my %profile_info = find_profile(\%args);

exit 0;

__END__

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
close($cu_fh);
say 'still alive';
# first get list nicknames in use
# add anything that isn't in there yet
exit 0;

1;

__END__

# https://tools.ietf.org/html/rfc5280#section-4.2.1.10
# Internet X.509 PKI Certificate -- Name Constraints
# .gov .mil
# ASN1 OID 2.5.29.30
#
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
#
