puppet-sssd
===========

Introduction
------------

This is Puppet module for installing and configuring SSSD
including domain join for Ubuntu and Debian machines.


Usage with AD
-------------

Use following with Active Directory compliant domain controller:

.. code:: puppet

    class { sssd:
        default_domain => "example.lan"
    }

    sssd::ad { "example.lan":
        workgroup => "EXAMPLE",
        join_username => "create-me",
        join_password => "change-me",
    }

In this case the UID/GID numbers are generated algorithmically on the local machine
and no manual insertion is necessary on domain controller.
Otherwise you can make use of ``uidNumber``, ``gidNumber``,
``unixHomeDirectory`` and other RFC2307bis attributes stored with in domain controller by
specifying ``algorithmic_ids => false``.
In case the hostname is longer than 15 characters the join fails, as NetBIOS name
is derived from hostname, use ``netbios_name => "SHORTERNAME"`` to override.
The ``join_username`` and ``join_password`` parameters may be omitted,
in which case manual ``net ads join`` is necessary to complete the domain join.


Usage with OpenLDAP
-------------------

The LDAP interface assumes RFC2307 attributes such
as ``uidNumber``, ``gidNumber``, ``uid``, ``displayName``, ``homeDirectory``
on the LDAP server.
Note that you need TLS-enabled URI in order to everything work as expected,
that is either ldaps:// or ldap:// with StartTLS extension!
Bear in mind that ``uidNumber`` greater than 2^32 will overflow on most machines!

.. code:: puppet

    class { sssd:
        default_domain => "example.com"
    }

    sssd::ldap { "example.com":
        cacert_file => "/etc/ssl/certs/certificate-authority-of-ldap.pem",
        uri => "ldap://ldap.example.com",
        search_base => "cn=users,dc=example,dc=com",
        bind_dn => "userid=create-me,dc=example,dc=com",
        bind_password => "change-me"
    }
