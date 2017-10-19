#!/bin/bash

[[ "TRACE" ]] && set -x

: ${REALM:=CLOUD.COM}
: ${DOMAIN_REALM:=cloud.com}
: ${KERB_MASTER_KEY:=masterkey}
: ${KERB_ADMIN_USER:=root}
: ${KERB_ADMIN_PASS:=admin}
: ${KDC_ADDRESS:=kerberos.cloud.com}
: ${LDAP_HOST:=ldap://ldap.cloud.com}
: ${ENABLE_KRB:=false}
fix_nameserver() {
  cat>/etc/resolv.conf<<EOF
nameserver $NAMESERVER_IP
search $SEARCH_DOMAINS
EOF
}

fix_hostname() {
  sed -i "/^hosts:/ s/ *files dns/ dns files/" /etc/nsswitch.conf
}

enable_krb() {
  mkdir -p /var/log/kerberos

 touch /var/log/kerberos/krb5libs.log
 touch /var/log/kerberos/krb5kdc.log
 touch /var/log/kerberos/kadmind.log
 cat>/etc/krb5.conf<<EOF
[logging]
 default = FILE:/var/log/kerberos/krb5libs.log
 kdc = FILE:/var/log/kerberos/krb5kdc.log
 admin_server = FILE:/var/log/kerberos/kadmind.log

[libdefaults]
 default_realm = $REALM
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
 proxiable = true

[realms]
 $REALM = {
  kdc = $KDC_ADDRESS
  admin_server = $KDC_ADDRESS
  database_module = openldap_ldapconf
 }

[domain_realm]
 .$DOMAIN_REALM = $REALM
 $DOMAIN_REALM = $REALM

[dbdefaults]
        ldap_kerberos_container_dn = cn=krbContainer,dc=cloud,dc=com

[dbmodules]
        openldap_ldapconf = {
                db_library = kldap
                ldap_kdc_dn = cn=kdc-srv,ou=krb5,dc=cloud,dc=com
                ldap_kadmind_dn = cn=adm-srv,ou=krb5,dc=cloud,dc=com
                ldap_service_password_file = /etc/krb5kdc/service.keyfile
                ldap_conns_per_server = 5
                ldap_servers = $LDAP_HOST
        }
EOF

}

enableGss() {
 echo 'GSSAPIAuthentication yes
 GSSAPICleanupCredentials yes' >> /etc/ssh/sshd_config 
}

initialize() {
  if [ "$ENABLE_KRB" == 'true' ]
   then
     /utility/kerberos/enableKerbPam.sh
     enable_krb
     enableGss
  else
    /utility/ldap/enableLdapPam.sh
  fi

}

start_ldap() {
   service nscd start
   service ssh restart
}

main() {
  if [ ! -f /ldap_initialized ]; then
    initialize
    start_ldap 
    touch /ldap_initialized
  else
    start_ldap
  fi
  if [[ $1 == "-d" ]]; then
    while true; do sleep 1000; done
  fi
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
