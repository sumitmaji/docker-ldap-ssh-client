FROM sumit/base
MAINTAINER Sumit Kumar Maji

# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
RUN sed -i "s/^exit 101$/exit 0/" /usr/sbin/policy-rc.d

ARG DEBIAN_FRONTEND=noninteractive
ARG LDAP_DOMAIN=cloud.com
ARG LDAP_ORG=CloudInc
ARG LDAP_HOSTNAME=ldap.cloud.com
ARG LDAP_PASSWORD=sumit

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl
RUN apt-get install -yq nmap
RUN apt-get install -yq apt debconf
RUN apt-get upgrade -yq
RUN apt-get -y -o Dpkg::Options::="--force-confdef" upgrade
RUN apt-get -y dist-upgrade

RUN echo "ldap-auth-config ldap-auth-config/dblogin boolean false" | debconf-set-selections
RUN echo "ldap-auth-config ldap-auth-config/override boolean true" | debconf-set-selections
RUN echo "ldap-auth-config ldap-auth-config/ldapns/ldap-server string ldap://$LDAP_HOSTNAME" | debconf-set-selections
RUN echo "ldap-auth-config ldap-auth-config/pam_password string md5" | debconf-set-selections
RUN echo "ldap-auth-config ldap-auth-config/dbrootlogin boolean true" | debconf-set-selections
RUN echo "ldap-auth-config ldap-auth-config/binddn string cn=proxyuser,dc=example,dc=net" | debconf-set-selections
RUN echo "ldap-auth-config ldap-auth-config/ldapns/ldap_version string 3" | debconf-set-selections
RUN echo "ldap-auth-config ldap-auth-config/move-to-debconf boolean true" | debconf-set-selections
RUN echo "ldap-auth-config ldap-auth-config/ldapns/base-dn string dc=cloud,dc=com" | debconf-set-selections
RUN echo "ldap-auth-config ldap-auth-config/rootbinddn string cn=admin,dc=cloud,dc=com" | debconf-set-selections

ADD krb-ldap-config /etc/auth-client-config/profile.d/krb-ldap-config
RUN apt-get install -yq ldap-auth-client nscd krb5-user libpam-krb5 libpam-ccreds
RUN apt-get install -yq ntp ntpdate nmap libsasl2-modules-gssapi-mit
#RUN auth-client-config -a -p krb_ldap
ADD setupClient.sh /etc/setupClient.sh
RUN /bin/bash -c "/etc/setupClient.sh"
ADD ldap.secret /etc/ldap.secret
RUN chmod 600 /etc/ldap.secret
RUN apt-get install -yq nmap ntp ntpdate
# Cleanup Apt
RUN apt-get autoremove
RUN apt-get autoclean
RUN apt-get clean

ADD bootstrap.sh /bootstrap.sh
RUN chmod +x /bootstrap.sh


EXPOSE 389 636 80
ENTRYPOINT ["/bootstrap.sh"]
