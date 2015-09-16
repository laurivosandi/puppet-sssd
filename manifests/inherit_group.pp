# Add user to system groups (audio,video,dip,...) during authentication phase using pam_group
define sssd::inherit_group(
  $ensure = present
) {
  File['/etc/security/group.conf']
  ->
  file_line { "inherit-group-$title":
      ensure => $ensure,
      path => '/etc/security/group.conf',
      line => "*;*;*;Al0000-2400;$title"
  }
}
