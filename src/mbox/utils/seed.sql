-- seed.sql: a new mailbox domain with an admin mailbox, a test mailbox,
-- and postmaster@/abuse@ aliases to the admin. seed.sh fills in the
-- @PLACEHOLDERS@. Safe to run again: existing rows are kept as they are.
PRAGMA foreign_keys = ON;
BEGIN;

INSERT OR IGNORE INTO Domain (name, class, uid) VALUES ('@DOMAIN@', 'mailbox', 5000);

-- Four addresses: the two mailboxes and the two role aliases
INSERT OR IGNORE INTO Address (localpart, domain)
  SELECT lp, D.id
  FROM Domain D,
       (SELECT '@ADMIN@' AS lp UNION SELECT 'test' UNION SELECT 'postmaster' UNION SELECT 'abuse')
  WHERE D.name = '@DOMAIN@';

-- The two mailboxes, each with its own random password hash
INSERT OR IGNORE INTO VMailbox (id, password)
  SELECT A.id, CASE A.localpart WHEN '@ADMIN@' THEN '@ADMIN_HASH@' ELSE '@TEST_HASH@' END
  FROM Address A JOIN Domain D ON D.id = A.domain
  WHERE D.name = '@DOMAIN@' AND A.localpart IN ('@ADMIN@', 'test');

-- postmaster@ and abuse@ deliver to the admin mailbox
INSERT OR IGNORE INTO Alias (address, target, note)
  SELECT A.id,
         (SELECT M.id FROM Address M WHERE M.domain = D.id AND M.localpart = '@ADMIN@'),
         'role address'
  FROM Address A JOIN Domain D ON D.id = A.domain
  WHERE D.name = '@DOMAIN@' AND A.localpart IN ('postmaster', 'abuse');

COMMIT;

-- What the domain now has
SELECT email, receive, login FROM Mailbox WHERE domain = '@DOMAIN@';
SELECT localpart || '@' || domain || ' -> ' || target FROM AliasTarget WHERE domain = '@DOMAIN@';
