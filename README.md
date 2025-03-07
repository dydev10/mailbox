# mailbox

A lightweight email server with SMTP replay and IMAP inbox service. Uses `postfix` for SMTP server, `dovecot` for IMAP server and `sqlite3` as database engine.

## Setup
Create a dirctory `mailbox` in your host machine. You will need to configure your own domain and users using by creating the following files inside `mailbox` directory:

```
mailbox
├── .domains.env
│   ├── passwd
│   ├── sasl_passwd
│   ├── vmail_ssl.map
│   └── vmaps
├── .env
└── compose.yaml
```

## Using docker compose to run image

```yaml
# compose.yaml

services:
  mailbox:
    # Build config    
    build: 
      context: .

    # User config
    image: dydev420/mailbox:latest
    container_name: mailbox
    hostname: mail.example.com
    ports:
      - "25:25"
      - "143:143"
      - "587:587"
      - "2525:2525"
    restart: on-failure
    volumes:
      - /etc/letsencrypt/live/mail.example.com:/etc/letsencrypt/live/mailbox:ro
      - /etc/letsencrypt/archive:/etc/letsencrypt/archive:ro
      #- /etc/letsencrypt/live:/etc/letsencrypt/live:ro
      - /home/vmail:/home/vmail
      - ./.domains.env:/.domains.env
    env_file:
      - path: ./.env
        required: true
```

## Usage with docker
A dockerfile is available to bundle and build a docker image for the server.
Run this command to build the image locally: 
  - `docker build .`

