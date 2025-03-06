#!/bin/sh
chown -R vmail:vmail /home/vmail
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf

