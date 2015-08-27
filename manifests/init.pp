# == Class: sssd
#
# Full description of class sssd here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { sssd:
#    default_domain => "example.org"
#  }
#
#  sssd::ad { "example.org":
#    workgroup => "EXAMPLE",
#  }
#
#  OR with more parameters specified
#
#  class { sssd:
#    default_domain => "apple.org",
#    domains => ["apple.org", "banana.org"],
#    fallback_homedir => "/home/%d/%u",
#    override_shell => "/bin/bash",
#  }
#
#  sssd::ad { "apple.org":
#    workgroup => "APPLE",
#    netbios_name => "EMPLOYEE1",
#    join_username => "joiner",
#    join_password => "verysecure",
#    algorithmic_ids => false
#  }
#
#  sssd::ldap { "banana.org":
#    cacert_file => "/etc/ssl/certs/ldap-ca.pem",
#    uri => "ldap://ldap.banana.org",
#    search_base => "cn=users,dc=banana,dc=org",
#    bind_dn => "userid=sssd,dc=banana,dc=org",
#    bind_password => "verysecure"
#  }

#
# === Authors
#
# Lauri Võsandi <author@domain.com>
#
# === Copyright
#
# Copyright 2015 Lauri Võsandi, unless otherwise noted.
#
class sssd(
  $default_domain,
  $domains = [$default_domain],
  $fallback_homedir = "/home/%u",
  $override_shell = "/bin/bash",
  $mkhomedir = true,
  $skel = undef,
  $umask = "0077"
) {
  if $mkhomedir {
    file { "/usr/share/pam-configs/mkhomedir":
      ensure  => present,
      owner   => "root",
      group   => "root",
      mode    => "0644",
      content => template("sssd/mkhomedir.erb"),
    }
    ~>
    Exec['pam_auth_update']
  } else {
    file { "/usr/share/pam-configs/mkhomedir": ensure  => absent }
    ~>
    Exec['pam_auth_update']
  }


  # Ensure winbind service is running
  package { "samba-common": ensure => installed }
  ->
  Ini_setting <| path == '/etc/samba/smb.conf' |>

  # Ensure nsswitch is updated after PAM config is set
  Exec["pam_auth_update"]
  ->
  File_line <| path == "/etc/nsswitch.conf" |>


  # Update PAM config
  exec { "pam_auth_update":
    command => "/usr/sbin/pam-auth-update",
    refreshonly => true
  }

  package { "sssd": ensure => installed }
  package { "sssd-tools": ensure => installed }
  package { "libpam-sss": ensure => installed, notify => Exec['pam_auth_update'] }
  package { "libnss-sss": ensure => installed }
  package { "libsss-sudo": ensure => installed }
  package { "krb5-user": ensure => installed }
  package { "kstart": ensure => installed }
  package { "libsasl2-modules-gssapi-heimdal": ensure => installed }
  package { "libsasl2-modules-ldap": ensure => installed }
  package { "libpam-winbind": ensure => absent, notify => Exec['pam_auth_update'] }
  package { "libnss-winbind": ensure => absent }

  # Remove legacy
  file { "/etc/pam_ldap.conf": ensure => absent } ->
  file { '/etc/libnss-ldap.conf': ensure => absent }

  package { "libpam-python": ensure => absent, notify => Exec['pam_auth_update']  }
  package { "libpam-mklocaluser": ensure => absent, notify => Exec['pam_auth_update']  }
  package { "libpam-ccreds": ensure => absent, notify => Exec['pam_auth_update']  }
  package { "nsscache": ensure => absent }
  package { "libnss-db": ensure => absent }
  package { "libnss-cache": ensure => absent }
  package { "libpam-ldapd": ensure => absent, notify => Exec['pam_auth_update']  }
  package { "libnss-ldapd": ensure => absent }
  package { "nslcd": ensure => absent }
  package { "nscd": ensure => absent }
  package { "libpam-ldap": ensure => absent, notify => Exec['pam_auth_update'] }
  package { "libnss-ldap": ensure => absent }

  file_line { "nsswitch-passwd":
      path => "/etc/nsswitch.conf",
      match => "^passwd:",
      line => "passwd: compat sss"
  }

  file_line { "nsswitch-group":
      path => "/etc/nsswitch.conf",
      match => "^group:",
      line => "group: compat sss"
  }

  file_line { "nsswitch-shadow":
      path => "/etc/nsswitch.conf",
      match => "^shadow:",
      line => "shadow: compat sss"
  }

  file_line { "nsswitch-netgroup":
      path => "/etc/nsswitch.conf",
      match => "^netgroup:",
      line => "netgroup: compat"
  }

  service { "sssd":
    ensure => running,
    enable => true
  }
  
  file { "/etc/sssd/sssd.conf":
    ensure => present,
    mode => 600,
    owner => root,
    group => root,
  }

  # Set available domains
  ini_setting { "/etc/sssd/sssd.conf -> sssd -> domains":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "sssd",
    setting => "domains",
    value => join($domains, ",")
  }

  ini_setting { "/etc/sssd/sssd.conf -> sssd -> services":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "sssd",
    setting => "services",
    value => "nss, pam"
  }
  
  
  ini_setting { "/etc/sssd/sssd.conf -> sssd -> config_file_version":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "sssd",
    setting => "config_file_version",
    value => 2
  }

  ini_setting { "/etc/sssd/sssd.conf -> nss -> fallback_homedir":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "nss",
    setting => "fallback_homedir",
    value => $fallback_homedir
  }

  ini_setting { "/etc/sssd/sssd.conf -> nss -> override_shell":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "nss",
    setting => "override_shell",
    value => $override_shell
  }  
  
  ini_setting { "/etc/sssd/sssd.conf -> sssd -> default_domain":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "sssd",
    setting => "default_domain",
    value => $default_domain
  }  
  

  if defined(Package["lightdm"]) {
    file { "/etc/lightdm/manual-login.conf":
      ensure => present,
      mode => 644,
      owner => root,
      group => root,
      content => "[SeatDefaults]\ngreeter-show-manual-login=true\n"
    }

    # Fix Ubuntu 14.04 bugs
    if $lsbdistcodename == "trusty" {
      file { "/etc/pam.d/lightdm":
        ensure => present,
        mode => 0644,
        owner => root,
        group => root,
        content => template("sssd/pam.d/lightdm.erb")
      }
    }
  }

  # Reload SSSD after configuration change
  Ini_setting <| path == '/etc/sssd/sssd.conf' |>
  ~>
  Service["sssd"]


}
