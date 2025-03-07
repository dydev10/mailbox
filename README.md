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


## Usage with docker
A dockerfile is available to bundle and build a docker image for the server.
Run this command to build the image locally: 
  - `docker build .`

