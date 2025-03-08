# mailbox

A lightweight email server with SMTP replay and IMAP inbox service. Uses `postfix` for SMTP server, `dovecot` for IMAP server and `sqlite3` as database engine.

## Setup
Create a directory `mailbox` in your host machine. You will need to configure your own domain and users using by creating the following files inside `mailbox` directory:

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
- **.domains.env**: Contains lookup table files used by postfix and dovecot for users and virtual domains.
  Virtual domains are additional domains that will supported by this email services. Requires their own ssl certificates and configurations.

  `mail.example.com` in the following examples is used as hostname of the mail service. Should be same as the hostname given in docker compose file.
  All configurations related to hostname are required for mailbox to work. `mail.exmaple.com` will use `@example.com` as email domain.
  
  `mail.vdomain.com` can is used as exmaple for one of the virtual domains host that can be assigned to this server to handle mails from these domain.
  Virtual domain configurations are optional. They can have none or mutliple entries. An entry for `mail.vdomain.com` will use `@vdomain.com` as email domain.

  - **passwd**: email addresses allowed to use the email service for sending emails and log in to imap service.
    Generate a new password by running this command inside the container machine: `doveadm pw`.
    The format for the entries in this file is:
    ```plaintext
    # email:{schema}passwordHash::::::
    
    user@example.com:{CRYPT}cryptPass::::::
    user@vdomain.com:{CRYPT}cryptPass::::::
    ```
    
  - **sasl_passwd**: credentials for relay smtp services used as relayhost.
    The format for the entries in this file is:
    ```plaintext
    # [host]:port emaail:password
    
    [smtp.relayexample.com]:2525 postmaster@example.com:relayPass
    ```  

  - **vmail_ssl.map**: Directory for ssl certificates to be used by postfix and dovecot for all TLS connections.
    These are the path inside the conainer where the certificate directories are mounted as volume in docker compose file.
    Configuration for hostname uses `mailbox` as the diretory. The virtual domain use their own host as directory. 
    The format for the entries in this file is:
    ```plaintext
    # host /path/to/key.file /path/to/cert.file
    
    mail.example.com /etc/letsencrypt/live/mailbox/privkey.pem /etc/letsencrypt/live/mailbox/fullchain.pem
    mail.vdomain.com /etc/letsencrypt/live/mail.vdomain.com/privkey.pem /etc/letsencrypt/live/mail.vdomain.com/fullchain.pem
    ```  

  - **vmaps**: mapping for email addresses and their mail storage path in the system mail directory.
    The format for the entries in this file is:
    ```plaintext
    # email domain/username/
    
    user@example.com example.com/user/
    user@vdomain.com vdomain.com/user/
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

