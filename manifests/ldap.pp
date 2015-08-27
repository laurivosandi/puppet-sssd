/**
 * Set up SSSD with OpenLDAP
 *
 * - Note that you need TLS-enabled URI (ldaps:// or ldap:/ with StartTLS)
 *   for password authentication to work AT ALL!
 * - OpenLDAP pretty much ignores any configuration in slapd.conf, so follow
 *   ldapmodify instructions here:
 *   http://mindref.blogspot.com/2010/12/debian-openldap-ssl-tls-encryption.html
 * - If you mess up the configuration and end up with unusable slapd:
 *    - apt-get install libarchive-zip-perl
 *    - tail -n +3  /etc/ldap/slapd.d/cn=config.ldif  > /tmp/fixed.ldif
 *    - crc32 /tmp/fixed.ldif
 *    - Substitute checksum in original file
 * - DO NOT USE OpenSSL to generate CA or certificates for OpenLDAP, use
 *   GnuTLS instead:
 *    - certtool --generate-privkey --outfile /etc/ssl/private/ldap-ca.pem
 *    - certtool --generate-self-signed --load-privkey /etc/ssl/private/ldap-ca.pem --outfile /etc/ssl/certs/ldap-ca.pem
 *    - certtool --generate-privkey --outfile /etc/ssl/private/ldap.pem
 *    - certtool --generate-request --load-privkey /etc/ssl/private/ldap.pem --outfile /tmp/ldap.csr
 *    - certtool --generate-certificate --load-request /tmp/ldap.csr --load-ca-certificate /etc/ssl/certs/ldap-ca.pem --load-ca-privkey /etc/ssl/private/ldap-ca.pem --outfile /etc/ssl/certs/ldap.pem
 *    - chmod 600 /etc/ssl/private/ldap-ca.pem /etc/ssl/private/ldap.pem
 *    - chmod 755 /etc/ssl/certs/ldap-ca.pem /etc/ssl/certs/ldap.pem
 *    - chown openldap:openldap /etc/ssl/private/ldap.pem
 * - Make sure LDAP server's certificte gets generated with extended key usage: TLS Server
 * - DO NOT put keys and certificates to any other folder on Ubuntu,
 *   AppArmor prevents accessing arbitrary folders!
 * - Use following to debug
 *    - gnutls-cli-debug -p 636 ldap.example.org
 *    - openssl s_client -showcerts -connect ldap.example.org:636
 */

define sssd::ldap(
  $cacert_file,
  $bind_dn,
  $bind_password,
  $search_base = inline_template("<%= scope.lookupvar('title').split('.').map{|j| 'dc='+j}.join(',') %>"),
  $force_tls = true,
  $uri = "ldapi:///",
  $algorithmic_ids = true
) {

  # Set up SSSD domain section
  sssd::domain { "$title":
    auth_provider => "ldap",
    chpass_provider => "ldap",
    id_provider => "ldap",
    access_provider => "simple",
    autofs_provider => "ldap",
    sudo_provider => "ldap",
    ldap_id_mapping => $algorithmic_ids
  }

  file { "/etc/ldap":
      ensure => directory,
      mode => 755,
      owner => root,
      group => root
  }
  ->
  file { "/etc/ldap/ldap.conf":
      ensure => present,
      mode => 644,
      owner => root,
      group => root,
      content => template("sssd/ldap.conf.erb")
  }

  # LDAP URI
  ini_setting { "/etc/sssd/sssd.conf -> domain/$title -> ldap_uri":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "ldap_uri",
    value => "$uri"
  }

  # Search base
  ini_setting { "/etc/sssd/sssd.conf -> domain/$title -> ldap_search_base":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "ldap_search_base",
    value => "$search_base"
  }


  # TLS CA certficate path
  ini_setting { "/etc/sssd/sssd.conf -> domain/$title -> ldap_tls_cacert":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "ldap_tls_cacert",
    value => "$cacert_file"
  }

  # LDAP schema
  ini_setting { "/etc/sssd/sssd.conf -> domain/$title -> ldap_schema":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "ldap_schema",
    value => "rfc2307"
  }

  # Force StartTLS for 389 if true
  ini_setting { "/etc/sssd/sssd.conf -> domain/$title -> ldap_id_use_start_tls":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "ldap_id_use_start_tls",
    value => "$force_tls"
  }

  # Bind account settings
  ini_setting { "/etc/sssd/sssd.conf -> domain/$title -> ldap_default_bind_dn":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "ldap_default_bind_dn",
    value => "$bind_dn"
  }

  ini_setting { "/etc/sssd/sssd.conf -> domain/$title -> ldap_default_bind_password":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "ldap_default_authtok",
    value => "$bind_password"
  }

  ini_setting { "/etc/sssd/sssd.conf -> domain/$title -> ldap_default_authtok_type":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "ldap_default_authtok_type",
    value => "password"
  }
}


