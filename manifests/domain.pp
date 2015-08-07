define sssd::domain(
  $sudo_provider = "ad",
  $auth_provider = "ad",
  $chpass_provider = "ad",
  $autofs_provider = "ad",
  $id_provider = "ad",
  $dyndns_update = false,
  $access_provider = "simple",
  $cache_credentials = true,
  $ldap_id_mapping = true
) {

  ini_setting { "/etc/sssd/sssd.conf -> domain-$title -> dns_update = $dyndns_update":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "dyndns_update",
    value => "$dyndns_update"
  }

  ini_setting { "/etc/sssd/sssd.conf -> domain-$title -> cache_credentials = $cache_credentials":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "cache_credentials",
    value => "$cache_credentials"
  }

  # LDAP IP mapping
  ini_setting { "sssd.conf -> domain/$title -> ldap_id_mapping = $id_mapping":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "ldap_id_mapping",
    value => "$ldap_id_mapping"
  }

  if ($ldap_id_mapping) {
    ini_setting { "sssd.conf -> domain/$title -> ldap_idmap_range_min = absent":
      ensure => absent,
      path => "/etc/sssd/sssd.conf",
      section => "domain/$title",
      setting => "ldap_idmap_range_min",
    }

    ini_setting { "sssd.conf -> domain/$title -> ldap_idmap_range_max = absent":
      ensure => absent,
      path => "/etc/sssd/sssd.conf",
      section => "domain/$title",
      setting => "ldap_idmap_range_max",
    }
  } else {
    ini_setting { "sssd.conf -> domain/$title -> ldap_idmap_range_min = 5000":
      ensure => present,
      path => "/etc/sssd/sssd.conf",
      section => "domain/$title",
      setting => "ldap_idmap_range_min",
      value => 5000
    }

    ini_setting { "sssd.conf -> domain/$title -> ldap_idmap_range_max = 2000000000":
      ensure => present,
      path => "/etc/sssd/sssd.conf",
      section => "domain/$title",
      setting => "ldap_idmap_range_max",
      value => 2000000000
    }
  }

  ini_setting { "sssd-conf-domain-$title-id-provider":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "id_provider",
    value => "$id_provider"
  }

  ini_setting { "sssd-conf-domain-$title-auth-provider":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "auth_provider",
    value => "$auth_provider"
  }

  ini_setting { "sssd-conf-domain-$title-chpass-provider":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "chpass_provider",
    value => "$chpass_provider"
  }

  ini_setting { "sssd-conf-domain-$title-access-provider":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "access_provider",
    value => $access_provider
  }

  ini_setting { "sssd-conf-domain-$title-sudo-provider":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "sudo_provider",
    value => $sudo_provider
  }

  ini_setting { "sssd-conf-domain-$title-autofs-provider":
    ensure => present,
    path => "/etc/sssd/sssd.conf",
    section => "domain/$title",
    setting => "autofs_provider",
    value => $autofs_provider
  }
}
