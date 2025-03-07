FROM ubuntu:24.04


# Install supervisor and all mailbox dependencies
RUN apt update && \
  apt install -y \
  supervisor \
  sqlite3 \
  postfix \
  dovecot-core \
  dovecot-imapd \
  dovecot-pop3d \
  dovecot-lmtpd


# Create virtual mailbox vmail user and group
RUN groupadd -g 5000 vmail
RUN useradd \
  -m \
  -u 5000 \
  -g 5000 \
  -s /bin/bash \
  vmail
## ownership for mounted vmail dir will granted in entrypoint script for persistent storage

## Copy usefull scripts
# to list active ports
COPY procnet ./
##

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
##

## DB setup, will be used later
# Copy the schema.sql script into the container
COPY src/sqlite/schema.sql /tmp/schema.sql
# Initialize the SQLite database
RUN sqlite3 -init /tmp/schema.sql /etc/postfix/private/mail.sqlite ".exit"
# HardLink to postfix db file for dovecot
RUN ln -vi /etc/postfix/private/mail.sqlite /etc/dovecot/private/mail.sqlite
# Clean up the SQL script
RUN rm /tmp/schema.sql
##

# Copy postfix config files
COPY src/postfix/. /etc/postfix/
COPY src/dovecot/. /etc/dovecot/


# Only for documentation: should expose ports (SMTP, IMAP, Relay)
EXPOSE 25 587 143 2525


##
#Copy entrypoint script
COPY src/entrypoint /entrypoint
RUN chmod +x /entrypoint
# Start container with this entrypoint to set permission on mounted volumes and start supervisor
ENTRYPOINT ["/entrypoint"]
##


##
## END Dockerfile

