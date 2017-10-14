#!/bin/bash

[[ "TRACE" ]] && set -x

start_ldap() {
   service nscd start
   service ssh restart
}

main() {
  if [ ! -f /ldap_initialized ]; then
    start_ldap 
    touch /ldap_initialized
  else
    start_ldap
  fi

  while true; do sleep 1000; done
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
