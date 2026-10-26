-- migrate.sql: move the staged passwd/vmaps rows into the mailsql schema.
-- import-legacy.sh runs it in the same sqlite3 session as the output of
-- passwd-vmaps-to-sql.sh, because the staging tables are temporary.
PRAGMA foreign_keys = ON;
BEGIN;

-- 1. Report addresses that appear in only one of the two old files
SELECT 'login only (no inbound mail today): ' || email FROM import_passwd
  WHERE email NOT IN (SELECT email FROM import_vmaps);
SELECT 'mail only (no password today):      ' || email FROM import_vmaps
  WHERE email NOT IN (SELECT email FROM import_passwd);

-- 2. Every address from either file
CREATE TEMP TABLE import_all AS
  SELECT email,
         substr(email, 1, instr(email, '@') - 1)  AS localpart,
         substr(email, instr(email, '@') + 1)     AS domain
  FROM (SELECT email FROM import_passwd UNION SELECT email FROM import_vmaps)
  WHERE instr(email, '@') > 1;

-- 3. Domains: mailbox domains, default uid 5000 (vmail)
INSERT OR IGNORE INTO Domain (name, class, uid, note)
  SELECT DISTINCT domain, 'mailbox', 5000, 'imported' FROM import_all;

-- 4. Addresses
INSERT OR IGNORE INTO Address (localpart, domain)
  SELECT I.localpart, D.id FROM import_all I JOIN Domain D ON D.name = I.domain;

-- 5. Mailboxes: home NULL = <domain>/<localpart> under /home/vmail, the
--    path the old static userdb used. Password hash copied unchanged;
--    NULL for "mail only" addresses (they still cannot log in).
--    The domain must be a 'mailbox' domain (an existing one may not be).
INSERT OR IGNORE INTO VMailbox (id, password)
  SELECT A.id, P.password
  FROM import_all I
    JOIN Domain D  ON D.name = I.domain
    JOIN Address A ON A.domain = D.id AND A.localpart = I.localpart
    LEFT JOIN import_passwd P ON P.email = I.email
  WHERE D.class = 'mailbox';

-- 6. Summary
SELECT 'domains:   ' || count(*) FROM Domain    WHERE class = 'mailbox';
SELECT 'mailboxes: ' || count(*) FROM VMailbox;
COMMIT;