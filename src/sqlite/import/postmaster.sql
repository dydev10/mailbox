-- postmaster@ and abuse@ for every mailbox domain -> the admin mailbox.
-- import-legacy.sh fills in @ADMIN_LOCALPART@ and @ADMIN_DOMAIN@.
PRAGMA foreign_keys = ON;
BEGIN;
CREATE TEMP TABLE admin AS
  SELECT A.id FROM Address A JOIN Domain D ON D.id = A.domain
  WHERE A.localpart = '@ADMIN_LOCALPART@' AND D.name = '@ADMIN_DOMAIN@';
SELECT CASE WHEN count(*) = 0 THEN 'admin mailbox not found: no aliases added'
            ELSE 'postmaster@/abuse@ -> @ADMIN_LOCALPART@@@ADMIN_DOMAIN@' END FROM admin;
INSERT OR IGNORE INTO Address (localpart, domain)
  SELECT r.lp, D.id FROM Domain D, (SELECT 'postmaster' AS lp UNION SELECT 'abuse') r
  WHERE D.class = 'mailbox' AND (SELECT count(*) FROM admin) = 1;
INSERT OR IGNORE INTO Alias (address, target, note)
  SELECT A.id, (SELECT id FROM admin), 'role address' FROM Address A JOIN Domain D ON D.id = A.domain
  WHERE D.class = 'mailbox' AND A.localpart IN ('postmaster', 'abuse')
    AND A.id NOT IN (SELECT id FROM VMailbox)
    AND (SELECT count(*) FROM admin) = 1;
COMMIT;