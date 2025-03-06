#!/bin/sh

## hash files from .domains.env
# change ownership of domains config to root
chown -R root:root .domains.env
# hash postfix vmail_ssl.map text config
cp .domains.env/vmail_ssl.map /etc/postfix/vmail_ssl.map
#RUN postmap /etc/postfix/vmail_ssl.map
postmap -F hash:/etc/postfix/vmail_ssl.map
rm /etc/postfix/vmail_ssl.map
# hash vmaps text
cp .domains.env/vmaps /etc/postfix/vmaps
postmap /etc/postfix/vmaps
rm /etc/postfix/vmaps
# hash postfix sasl_passwd text
cp .domains.env/sasl_passwd /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd
rm /etc/postfix/sasl_passwd
# copy dovecot passwd text
cp .domains.env/passwd /etc/dovecot/passwd
##

## Update hostname in postfix conf
postconf -e "myhostname=$(hostname)"
##

# Change ownership of vmail
chown -R vmail:vmail /home/vmail

# Finally run starup commands to launch supervisor
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf

