#!/bin/bash
docker run -it -d --name ldap-client -h ldap-client --net cloud.com sumit/ldap-client /bin/bash
