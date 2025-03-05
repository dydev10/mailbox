FROM ubuntu:24.04

# Set hostname
RUN echo "gcp.dydev.art" > /etc/hostname

## install r syslog
#RUN apt update
#RUN apt install -y rsyslog

# Install mailbox server dependencies
RUN apt update
RUN apt install -y sqlite3 postfix dovecot-core dovecot-imapd dovecot-pop3d

# Create virtual mailbox vmail user and group
RUN groupadd -g 5000 vmail
RUN useradd \
  -m \
  -u 5000 \
  -g 5000 \
  -s /bin/bash \
  vmail


# Copy usefull scripts
COPY procnet ./

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

## hash files
# hash postfix vmail_ssl.map text config
RUN postmap /etc/postfix/vmail_ssl.map
RUN rm /etc/postfix/vmail_ssl.map
# hash vmaps text
RUN postmap /etc/postfix/vmaps
RUN rm /etc/postfix/vmaps
# hash postfix sasl_passwd text
RUN postmap /etc/postfix/sasl_passwd
RUN rm /etc/postfix/sasl_passwd
##

# copy dovecot passwd text
COPY src/dovecot/passwd /etc/dovecot/
##

## Start services Command
#CMD service postfix start ; service dovecot start
##

## Test test test
#USER ubuntu
#WORKDIR /home/ubuntu
#COPY --chown=ubuntu hello.txt ./
#RUN echo "$(whoami)" >> hello.txt
#RUN echo "$(hostname)" >> hello.txt

