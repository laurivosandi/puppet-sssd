
define sssd::ad(
  $workgroup = "WORKGROUP",
  $algorithmic_ids = true,
  $netbios_name = upcase($hostname),
  $spnego_whitelist = "*.$title",
  $kerberize_openssh = false,
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
  ini_setting { "/etc/sssd/sssd.conf -> domain-$title -> ldap_disable_referrals":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "ldap_disable_referrals",
    value => "true"
  }
  ->
  ini_setting { "/etc/sssd/sssd.conf -> domain-$title -> krb5_use_enterprise_principal":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "krb5_use_enterprise_principal",
    value => "false"
  }
  ->
  ini_setting { "/etc/samba/smb.conf -> global -> workgroup":
    ensure => present,
    path => "/etc/samba/smb.conf",
    section => "global",
    setting => "workgroup",
    value => "$workgroup"
  }
  ->
  ini_setting { "/etc/samba/smb.conf -> global -> security":
    ensure => present,
    path => "/etc/samba/smb.conf",
    section => "global",
    setting => "security",
    value => "ads"
  }
  ->
  ini_setting { "/etc/samba/smb.conf -> global -> netbios name":
    ensure => present,
    path => "/etc/samba/smb.conf",
    section => "global",
    setting => "netbios name",
    value => "$netbios_name"
  }
  ->
  ini_setting { "/etc/samba/smb.conf -> global -> realm":
    ensure => present,
    path => "/etc/samba/smb.conf",
    section => "global",
    setting => "realm",
    value => "$realm"
  }
  ->
  ini_setting { "/etc/samba/smb.conf -> global -> kerberos method":
    ensure => present,
    path => "/etc/samba/smb.conf",
    section => "global",
    setting => "kerberos method",
    value => "system keytab"
  }
  ->
  Package["sssd"]



  if $join_username and $join_password {
    Ini_setting <| path == '/etc/samba/smb.conf' |>
    ->
    exec { "net-ads-join":
      command => "/usr/bin/net ads join -U ${join_username}%${join_password}",
      unless => "/usr/bin/net ads testjoin"
    }
  }

  if $kerberize_openssh {
    if ! defined(Package["openssh-server"]) {
      package { "openssh-server": ensure => installed }
    }

    if ! defined(Service["ssh"]) {
      service { "ssh":
        ensure => running,
        enable => true
      }
    }

    Package["openssh-server"]
    ->
    Service["ssh"]
    ->
    file_line { "sshd_config -> KerberosAuthentication":
        path => "/etc/ssh/sshd_config",
        match => "^KerberosAuthentication ",
        line => "KerberosAuthentication yes"
    }
    ->
    file_line { "sshd_config -> KerberosOrLocalPasswd":
        path => "/etc/ssh/sshd_config",
        match => "^KerberosOrLocalPasswd ",
        line => "KerberosOrLocalPasswd yes"
    }
    ->
    file_line { "sshd_config -> KerberosTicketCleanup":
        path => "/etc/ssh/sshd_config",
        match => "^KerberosTicketCleanup ",
        line => "KerberosTicketCleanup yes"
    }
    ->
    file_line { "sshd_config -> GSSAPIAuthentication":
        path => "/etc/ssh/sshd_config",
        match => "^GSSAPIAuthentication ",
        line => "GSSAPIAuthentication yes"
    }
    ->
    file_line { "sshd_config -> GSSAPICleanupCredentials":
        path => "/etc/ssh/sshd_config",
        match => "^GSSAPICleanupCredentials ",
        line => "GSSAPICleanupCredentials yes"
    }
    ->
    file_line { "sshd_config -> GSSAPIStrictAcceptorCheck":
        path => "/etc/ssh/sshd_config",
        match => "^GSSAPIStrictAcceptorCheck ",
        line => "GSSAPIStrictAcceptorCheck yes"
    }

    File_line <| path == "/etc/ssh/sshd_config" |>
    ~>
    Service["ssh"]
  }

  if defined(Package["chromium-browser"]) {
    file { "/etc/chromium-browser/policies/managed/spnego.json":
      ensure => file,
      mode => 755,
      owner => root,
      group => root,
      content => "{\n  \"AuthServerWhitelist\":\"$spnego_whitelist\",\n  \"AuthNegotiateDelegateWhitelist\":\"$spnego_whitelist\"\n}\n"
    }
  }
}
