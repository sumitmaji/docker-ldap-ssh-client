#!/bin/bash
docker run -it -e ENABLE_KRB='true' --name ldap-client -h ldap-client.cloud.com --net cloud.com sumit/ldap-client -d
