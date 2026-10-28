FROM ubuntu:24.04

# Build-time only: no installer prompts (not set in the running container)
ARG DEBIAN_FRONTEND=noninteractive

# Postfix + Dovecot with their SQLite modules, a local DNS resolver for
# blocklist lookups, and supervisord to run all three in one container.
RUN apt-get update && apt-get install -y --no-install-recommends \
      supervisor sqlite3 ca-certificates unbound unbound-anchor \
      postfix postfix-sqlite \
      dovecot-core dovecot-imapd dovecot-lmtpd dovecot-sqlite \
 && rm -rf /var/lib/apt/lists/*

# vmail (uid/gid 5000) owns the Maildirs.
RUN groupadd -g 5000 vmail \
 && useradd -u 5000 -g 5000 -d /home/vmail -M -s /usr/sbin/nologin vmail

# Turn on foreign keys in every interactive sqlite3 session as root.
RUN echo 'PRAGMA foreign_keys = ON;' > /root/.sqliterc

# Repo files last: they change most often, so the steps above stay cached.
COPY src/supervisord.conf /etc/supervisor/supervisord.conf
COPY src/postfix/ /etc/postfix/
COPY src/dovecot/ /etc/dovecot/
COPY src/sqlite/ /usr/share/mailbox/
COPY src/entrypoint /entrypoint
COPY src/mbox/ /usr/local/lib/mbox/

# Make the scripts executable, put the mbox admin tool on the PATH, and
# remove group/other write (files keep the checkout's mode; Postfix warns
# about writable config).
RUN chmod 0755 /entrypoint /usr/share/mailbox/import/*.sh \
               /usr/local/lib/mbox/mbox /usr/local/lib/mbox/utils/*.sh \
 && ln -s /usr/local/lib/mbox/mbox /usr/local/bin/mbox \
 && chmod -R go-w /etc/postfix /etc/dovecot /etc/supervisor /usr/share/mailbox \
                  /usr/local/lib/mbox

EXPOSE 25 465 587 993
VOLUME ["/home/vmail", "/etc/mailsql"]
ENTRYPOINT ["/entrypoint"]