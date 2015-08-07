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
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Lauri Võsandi <author@domain.com>
#
# === Copyright
#
# Copyright 2015 Your name here, unless otherwise noted.
#
class sssd(
  $default_domain,
  $domains = [$default_domain],
  $fallback_homedir = "/home/%u",
  $override_shell = "/bin/bash",
) {
  package { "sssd": ensure => installed } ->  
  package { "sssd-tools": ensure => installed } ->
  package { "libpam-sss": ensure => installed } ->
  package { "libnss-sss": ensure => installed } ->
  package { "libsss-sudo": ensure => installed } ->
  package { "sudo": ensure => installed } ->
  package { "krb5-user": ensure => installed } ->
  package { "kstart": ensure => installed } ->

  package { "accountsservice": ensure => installed } ->
  package { "libpam-cap": ensure => installed } ->
  package { "libpam-gnome-keyring": ensure => installed } ->
  package { "libpam-ck-connector": ensure => installed } ->
  package { "libpam-systemd": ensure => installed } ->
  package { "libsasl2-modules-gssapi-heimdal": ensure => installed } ->
  package { "libpam-pwquality": ensure => installed } ->
  package { "libsasl2-modules-ldap": ensure => installed }
  ->
  file_line { "nsswitch-passwd":
      path => "/etc/nsswitch.conf",
      match => "^passwd:",
      line => "passwd: compat sss"
  }
  ->
  file_line { "nsswitch-group":
      path => "/etc/nsswitch.conf",
      match => "^group:",
      line => "group: compat sss"
  }
  ->
  file_line { "nsswitch-shadow":
      path => "/etc/nsswitch.conf",
      match => "^shadow:",
      line => "shadow: compat sss"
  }
  ->
  file_line { "nsswitch-netgroup":
      path => "/etc/nsswitch.conf",
      match => "^netgroup:",
      line => "netgroup: compat"
  }
  ->
  file { "/etc/pam.d/common-auth":
      ensure => present,
      mode => 644,
      owner => root,
      group => root,
      content => template("sssd/pam.d/common-auth.erb")
  }
  ->
  file { "/etc/pam.d/common-account":
      ensure => present,
      mode => 644,
      owner => root,
      group => root,
      content => template("sssd/pam.d/common-account.erb")
  }
  ->
  file { "/etc/pam.d/common-session":
      ensure => present,
      mode => 644,
      owner => root,
      group => root,
      content => template("sssd/pam.d/common-session.erb")
  }
  ->
  file { "/etc/pam.d/common-password":
      ensure => present,
      mode => 644,
      owner => root,
      group => root,
      content => template("sssd/pam.d/common-password.erb")
  }
  ->
  file { "/etc/pam.d/lightdm":
      ensure => present,
      mode => 644,
      owner => root,
      group => root,
      content => template("sssd/pam.d/lightdm.erb")
  }
  ->
  file { "/etc/lightdm":
    ensure => directory,
    mode => 755,
    owner => root,
    group => root,
  }
  ->
  file { "/etc/lightdm/manual-login.conf":
    ensure => present,
    mode => 644,
    owner => root,
    group => root,
    content => "[SeatDefaults]\ngreeter-show-manual-login=true\n"
  }
  ->
  service { "sssd":
    ensure => running,
    enable => true
  }
  ->
  # Remove legacy
  file { "/etc/pam_ldap.conf": ensure => absent } ->
  file { "/etc/ldap.conf": ensure => absent } ->
  file { '/etc/libnss-ldap.conf': ensure => absent }
  ->
  package { "libpam-python": ensure => purged } ->
  package { "libpam-mklocaluser": ensure => purged } ->
  package { "libpam-ccreds": ensure => purged } ->
  package { "nsscache": ensure => purged } ->
  package { "libnss-db": ensure => purged } ->
  package { "libnss-cache": ensure => purged } ->
  package { "libpam-ldapd": ensure => purged } ->
  package { "libnss-ldapd": ensure => purged } ->
  package { "nslcd": ensure => purged } ->
  package { "nscd": ensure => purged } ->
  package { "libpam-ldap": ensure => purged } ->
  package { "libnss-ldap": ensure => purged }
  
  file { "/etc/sssd/sssd.conf":
    ensure => present,
    mode => 600,
    owner => root,
    group => root,
  }

  # Set available domains
  ini_setting { "sssd.conf -> [sssd] -> domains = $domains":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "sssd",
    setting => "domains",
    value => join($domains, ",")
  }

  ini_setting { "sssd.conf -> [sssd] -> services = nss, pam":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "sssd",
    setting => "services",
    value => "nss, pam"
  }
  
  
  ini_setting { "sssd.conf -> [sssd] -> config_file_version = 2":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "sssd",
    setting => "config_file_version",
    value => 2
  }

  ini_setting { "sssd.conf -> [nss] -> fallback_homedir = $fallback_homedir":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "nss",
    setting => "fallback_homedir",
    value => $fallback_homedir
  }

  ini_setting { "sssd.conf -> [nss] -> override_shell = $override_shell":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "nss",
    setting => "override_shell",
    value => $override_shell
  }  
  
  ini_setting { "sssd.conf -> [sssd] -> default_domain = $default_domain":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "sssd",
    setting => "default_domain",
    value => $default_domain
  }  
  
  # Reload SSSD after configuration change
  Ini_setting <| path == '/etc/sssd/sssd.conf' |>
  ~>
  Service["sssd"]


}