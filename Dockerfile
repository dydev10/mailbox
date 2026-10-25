FROM ubuntu:24.04

# Build-time only: no installer prompts (not set in the running container)
ARG DEBIAN_FRONTEND=noninteractive

# Install supervisor and all mailbox dependencies
RUN apt update && \
  apt install -y \
  supervisor \
  sqlite3 \
  ca-certificates \
  unbound \
  unbound-anchor \
  postfix \
  postfix-sqlite \
  dovecot-core \
  dovecot-imapd \
  dovecot-lmtpd \
  dovecot-sqlite
&& rm -rf /var/lib/apt/lists/*


# Create virtual mailbox vmail user and group
RUN groupadd -g 5000 vmail && \
  useradd \
    -M \
    -u 5000 \
    -g 5000 \
    -d /home/vmail \
    -s /usr/sbin/nologin \
    vmail
## ownership for mounted vmail dir will granted in entrypoint script for persistent storage

# Turn on foreign keys in every interactive sqlite3 session as root.
RUN echo 'PRAGMA foreign_keys = ON;' > /root/.sqliterc

## Copy usefull scripts
# to list active ports
#COPY procnet ./
##

## supervisor setup
# Create log directory
#RUN mkdir -p /var/log/supervisor
# Copy Supervisor config
COPY src/supervisord.conf /etc/supervisor/supervisord.conf
##

### postfix dovecot setup
## Create private folders with postfix and dovecot access groups
#RUN mkdir -p /etc/postfix/private
#RUN mkdir -p /etc/dovecot/private
#RUN chgrp postfix /etc/postfix/private
#RUN chgrp dovecot /etc/dovecot/private
###

### DB setup, will be used later
## Copy the schema.sql script into the container
#COPY src/sqlite/schema.sql /tmp/schema.sql
## Initialize the SQLite database
#RUN sqlite3 -init /tmp/schema.sql /etc/postfix/private/mail.sqlite ".exit"
## HardLink to postfix db file for dovecot
#RUN ln -vi /etc/postfix/private/mail.sqlite /etc/dovecot/private/mail.sqlite
## Clean up the SQL script
#RUN rm /tmp/schema.sql
###

# Copy sqlite files
COPY src/sqlite/ /usr/share/mailbox

# Copy postfix config files
COPY src/postfix/ /etc/postfix/
COPY src/dovecot/ /etc/dovecot/

# Copy entrypoint script
COPY src/entrypoint /entrypoint

# make entrypoint and import scripts executable
RUN chmod +x /entrypoint /usr/share/mailbox/import/*.sh

# Start container with this entrypoint to set permission on mounted volumes and start supervisor
ENTRYPOINT ["/entrypoint"]
VOLUME ["/home/vmail", "/etc/mailsql"]

# Only for documentation: should expose ports (SMTP, IMAP, Relay)
#EXPOSE 25 587 143 2525
EXPOSE 25 465 587 993

##
## END Dockerfile

