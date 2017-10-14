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

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

RUN apt-get update
RUN apt-get install -yq apt debconf
RUN apt-get upgrade -yq
RUN apt-get -y -o Dpkg::Options::="--force-confdef" upgrade
RUN apt-get -y dist-upgrade

RUN apt-get -yq install python-pip python-ldap
RUN apt-get install -yq python-dev
RUN apt-get install -yq libsasl2-dev libldap2-dev libssl-dev
RUN pip install ssh-ldap-pubkey

RUN echo "AuthorizedKeysCommand /usr/local/bin/ssh-ldap-pubkey-wrapper" >> /etc/ssh/sshd_config
RUN echo "AuthorizedKeysCommandUser nobody" >> /etc/ssh/sshd_config
RUN sed -i 's/UsePAM no/UsePAM yes/g' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
RUN service ssh restart

#RUN echo "ldap-auth-config ldap-auth-config/rootbindpw password ${LDAP_PASSWORD}" | debconf-set-selections
#RUN echo "ldap-auth-config ldap-auth-config/bindpw password ${LDAP_PASSWORD}" | debconf-set-selections
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
RUN auth-client-config -a -p krb_ldap
ADD setupClient.sh /etc/setupClient.sh
RUN /bin/bash -c "/etc/setupClient.sh"
ADD ldap.secret /etc/ldap.secret
RUN chmod 600 /etc/ldap.secret

# Cleanup Apt
RUN apt-get autoremove
RUN apt-get autoclean
RUN apt-get clean

ADD bootstrap.sh /bootstrap.sh
RUN chmod +x /bootstrap.sh


EXPOSE 389 636 80
ENTRYPOINT ["/bootstrap.sh"]
