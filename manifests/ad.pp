
define sssd::ad(
  $workgroup = "WORKGROUP",
  $algorithmic_ids = true,
  $netbios_name = upcase($hostname),
  $join_username = undef,
  $join_password = undef
) {
  $realm = upcase($title)

  # Set up SSSD domain section
  sssd::domain { "$title":
    auth_provider => "ad",
    chpass_provider => "ad",
    id_provider => "ad",
    access_provider => "ad",
    autofs_provider => "ad",
    sudo_provider => "ad",
    ldap_id_mapping => $algorithmic_ids
  }

  package { "samba-common-bin": ensure => installed }
  ->
  ini_setting { "/etc/sssd/sssd.conf -> domain-$title -> ldap_disable_referrals = true":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "ldap_disable_referrals",
    value => "true"
  }
  ->
  ini_setting { "/etc/sssd/sssd.conf -> domain-$title -> krb5_use_enterprise_principal = false":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "krb5_use_enterprise_principal",
    value => "false"
  }
  ->
  ini_setting { "/etc/samba/smb.conf -> global -> workgroup = $workgroup":
    ensure => present,
    path => "/etc/samba/smb.conf",
    section => "global",
    setting => "workgroup",
    value => "$workgroup"
  }
  ->
  ini_setting { "/etc/samba/smb.conf -> global -> security = ads":
    ensure => present,
    path => "/etc/samba/smb.conf",
    section => "global",
    setting => "security",
    value => "ads"
  }
  ->
  ini_setting { "/etc/samba/smb.conf -> global -> netbios name = $hostname":
    ensure => present,
    path => "/etc/samba/smb.conf",
    section => "global",
    setting => "netbios name",
    value => "$netbios_name"
  }
  ->
  ini_setting { "/etc/samba/smb.conf -> global -> realm = $realm":
    ensure => present,
    path => "/etc/samba/smb.conf",
    section => "global",
    setting => "realm",
    value => "$realm"
  }
  ->
  ini_setting { "/etc/samba/smb.conf -> global -> kerberos method = system keytab":
    ensure => present,
    path => "/etc/samba/smb.conf",
    section => "global",
    setting => "kerberos method",
    value => "system keytab"
  }
  ->
  exec { "/usr/bin/net ads join -U ${join_username}%${join_password}":
    unless => "/usr/bin/net ads testjoin"
  }
  ->
  Package["sssd"]
}
