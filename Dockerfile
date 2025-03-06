FROM ubuntu:24.04





# Install supervisor to manage logs and services
RUN apt update
RUN apt install -y supervisor

# Install mailbox server dependencies
RUN apt update
RUN apt install -y sqlite3 postfix dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd

# Create virtual mailbox vmail user and group
RUN groupadd -g 5000 vmail
RUN useradd \
  -m \
  -u 5000 \
  -g 5000 \
  -s /bin/bash \
  vmail
## ownership for mounted vmail dir will granted in entrypoint script for persistent storage


# Copy usefull scripts
COPY procnet ./

## supervisor setup
# Create log directory
RUN mkdir -p /var/log/supervisor
# Copy Supervisor config
COPY src/supervisord.conf /etc/supervisor/supervisord.conf
##

## postfix dovecot setup
# Create private folders with postfix and dovecot access groups
RUN mkdir -p /etc/postfix/private
RUN mkdir -p /etc/dovecot/private
RUN chgrp postfix /etc/postfix/private
RUN chgrp dovecot /etc/dovecot/private

# Copy the schema.sql script into the container
COPY src/sqlite/schema.sql /tmp/schema.sql
# Initialize the SQLite database
RUN sqlite3 -init /tmp/schema.sql /etc/postfix/private/mail.sqlite ".exit"
# HardLink to postfix db file for dovecot
RUN ln -vi /etc/postfix/private/mail.sqlite /etc/dovecot/private/mail.sqlite

# Clean up the SQL script
RUN rm /tmp/schema.sql


# Copy postfix config files
COPY src/postfix/. /etc/postfix/
COPY src/dovecot/. /etc/dovecot/

## hash files from .domains.env
# hash postfix vmail_ssl.map text config
COPY .domains.env/vmail_ssl.map /etc/postfix/vmail_ssl.map
#RUN postmap /etc/postfix/vmail_ssl.map
RUN postmap -F hash:/etc/postfix/vmail_ssl.map
RUN rm /etc/postfix/vmail_ssl.map
# hash vmaps text
COPY .domains.env/vmaps /etc/postfix/vmaps
RUN postmap /etc/postfix/vmaps
RUN rm /etc/postfix/vmaps
# hash postfix sasl_passwd text
COPY .domains.env/sasl_passwd /etc/postfix/sasl_passwd
RUN postmap /etc/postfix/sasl_passwd
RUN rm /etc/postfix/sasl_passwd
##

# copy dovecot passwd text
COPY .domains.env/passwd /etc/dovecot/passwd
##


# Only for documentation: should expose ports (SMTP, IMAP, Relay)
EXPOSE 25 587 143 2525


##
#Copy entrypoint script
COPY src/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
# Start container with this entrypoint to set permission on mounted volumes and start supervisor
ENTRYPOINT ["/entrypoint.sh"]
##


##
## END Dockerfile

