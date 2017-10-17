#!/bin/bash
docker run -it --name ldap-client -h ldap-client.cloud.com --net cloud.com sumit/ldap-client /bin/bash
