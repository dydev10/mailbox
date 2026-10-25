-- ======================================================================
-- mailsql schema v3 -- Postfix 3.8 + Dovecot 2.3 on one SQLite database
-- Based on rob0's 2012 "postfix-dovecot-sqlite" howto, modernised.
--
-- Load with:   sqlite3 /etc/mailsql/mail.sqlite < schema.sql
-- (the entrypoint does this on first start). Needs SQLite 3.37 or later
-- for STRICT tables; Ubuntu 24.04 ships 3.45.
--
-- Kept from rob0's design:
--   * the six tables, an INTEGER PRIMARY KEY "id" on each, and
--     "Table.othertable" columns pointing at Othertable.id
--   * Domain.id = 0 (name NULL): Address.domain = 0 is a local
--     ($mydestination) address, as in aliases(5)
--   * the Transport, owner and rclass columns (unused in this deployment)
--
-- Changed from rob0's design:
--   * Domain.class is a word ('mailbox', 'alias', 'relay', 'local',
--     'nexthop') instead of a number, and the default mailbox UID has its
--     own column, Domain.uid (rob0 stored the UID in the class number).
--   * Address.active is 0/1 (receives mail). Blocking logins is a
--     separate flag, VMailbox.login, instead of Address.active = -1.
--     VMailbox.active is gone: Address.active covers it.
--   * |command, /file and :include: aliases go in Alias.action, instead of
--     pointing Alias.target at a special Address row 0.
--   * Postfix and Dovecot read two views, Mailbox and AliasTarget, so the
--     joins and defaults live here and the query files stay one line.
--   * STRICT tables: a value of the wrong type is an error.
--   * real foreign keys (deleting an Address removes its Alias rows and
--     VMailbox; anything still referenced cannot be deleted). SQLite only
--     enforces them with "PRAGMA foreign_keys = ON"; /root/.sqliterc
--     turns it on for the sqlite3 shell.
--   * names and localparts are case-insensitive (NOCASE) and stored
--     lower-case; CHECK constraints on every flag and class.
--   * created_at and note on Domain, Address and Alias; VMailbox.quota_mb.
-- ======================================================================

PRAGMA foreign_keys = ON;

BEGIN;

-- ----------------------------------------------------------------------
-- Transport: transport(5) results, "transport:nexthop:port"
-- For transport_maps; not used in this deployment.
-- ----------------------------------------------------------------------
CREATE TABLE Transport (
    id         INTEGER PRIMARY KEY,
    active     INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1)),
    -- master.cf service name (smtp, relay, lmtp, ...); NULL = default
    transport  TEXT,
    -- Domain.id of the next-hop host; NULL = default destination
    nexthop    INTEGER REFERENCES Domain(id) ON DELETE RESTRICT,
    -- 0 = no MX lookup ("[host]"), 1 = MX lookup
    mx         INTEGER NOT NULL DEFAULT 1 CHECK (mx IN (0, 1)),
    port       INTEGER CHECK (port BETWEEN 1 AND 65535)
) STRICT;
-- NULLs count as distinct in a plain UNIQUE, so index the coalesced values
CREATE UNIQUE INDEX Transport_unique ON Transport
    (coalesce(transport, ''), coalesce(nexthop, -1), mx, coalesce(port, 0));

-- ----------------------------------------------------------------------
-- Domain: every hostname the server refers to
--   class 'mailbox'  $virtual_mailbox_domains (Dovecot LMTP); needs uid
--         'alias'    $virtual_alias_domains
--         'relay'    $relay_domains
--         'local'    $mydestination
--         'nexthop'  only named as an alias target or Transport next hop
-- ----------------------------------------------------------------------
CREATE TABLE Domain (
    id         INTEGER PRIMARY KEY,
    name       TEXT COLLATE NOCASE UNIQUE,
    active     INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1)),
    class      TEXT NOT NULL DEFAULT 'nexthop'
               CHECK (class IN ('mailbox', 'alias', 'relay', 'local', 'nexthop')),
    -- default UID for this domain's mailboxes (5000 = vmail)
    uid        INTEGER CHECK (uid > 800),
    -- system UID of the person who controls the domain (informational)
    owner      INTEGER NOT NULL DEFAULT 0,
    -- default route and restriction class (unused in this deployment)
    transport  INTEGER REFERENCES Transport(id) ON DELETE RESTRICT,
    rclass     INTEGER DEFAULT 30 CHECK (rclass BETWEEN 0 AND 99),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    note       TEXT,
    -- a uid exactly when the domain holds mailboxes
    CHECK ((class = 'mailbox') = (uid IS NOT NULL)),
    CHECK (id = 0 OR name IS NOT NULL),
    -- stored lower-case, so queries and paths agree
    -- (BINARY: the column's NOCASE rule would make this always true)
    CHECK (name = lower(name) COLLATE BINARY)
) STRICT;

-- The NULL domain: Address.domain = 0 marks a local ($mydestination) address
INSERT INTO Domain (id, name, class, rclass, note)
VALUES (0, NULL, 'nexthop', NULL, 'local addresses ($mydestination)');

-- ----------------------------------------------------------------------
-- Address: every address the server refers to
-- ----------------------------------------------------------------------
CREATE TABLE Address (
    id         INTEGER PRIMARY KEY,
    localpart  TEXT NOT NULL COLLATE NOCASE
               CHECK (localpart <> '' AND localpart = lower(localpart) COLLATE BINARY),
    domain     INTEGER NOT NULL REFERENCES Domain(id) ON DELETE RESTRICT,
    -- 1 = in use, 0 = disabled (no mail in, and no login for a mailbox)
    active     INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1)),
    -- per-address route and restriction class (unused in this deployment)
    transport  INTEGER REFERENCES Transport(id) ON DELETE RESTRICT,
    rclass     INTEGER CHECK (rclass BETWEEN 0 AND 99),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    note       TEXT,
    UNIQUE (localpart, domain)
) STRICT;

-- ----------------------------------------------------------------------
-- Alias: one row per destination of an alias address.
--   target  -> another Address (optionally with a +extension), or
--   action  -> "|command", "/file/name" or ":include:/file"
--              (aliases(5) only; the virtual alias query ignores these)
-- ----------------------------------------------------------------------
CREATE TABLE Alias (
    id         INTEGER PRIMARY KEY,
    address    INTEGER NOT NULL REFERENCES Address(id) ON DELETE CASCADE,
    active     INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1)),
    -- RESTRICT: an address that aliases point to cannot be deleted until
    -- those aliases are removed or repointed (no silent loss of routing)
    target     INTEGER REFERENCES Address(id) ON DELETE RESTRICT,
    -- delivers to target+extension@domain; stored without the "+"
    extension  TEXT CHECK (extension <> '' AND extension NOT GLOB '*[@ ]*'),
    action     TEXT CHECK (action GLOB '|?*' OR action GLOB '/?*'
                           OR action GLOB ':include:/?*'),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    note       TEXT,
    -- exactly one of target and action; an extension only with a target
    CHECK ((target IS NULL) <> (action IS NULL)),
    CHECK (extension IS NULL OR target IS NOT NULL)
) STRICT;
-- NULL columns must not let the same mapping be inserted twice
CREATE UNIQUE INDEX Alias_unique ON Alias
    (address, coalesce(target, 0), coalesce(extension, ''), coalesce(action, ''));
CREATE INDEX Alias_target ON Alias(target);

-- ----------------------------------------------------------------------
-- VMailbox: virtual mailboxes and their credentials
-- ----------------------------------------------------------------------
CREATE TABLE VMailbox (
    id         INTEGER PRIMARY KEY REFERENCES Address(id) ON DELETE CASCADE,
    -- 1 = may log in, 0 = login blocked (mail still delivered)
    login      INTEGER NOT NULL DEFAULT 1 CHECK (login IN (0, 1)),
    uid        INTEGER CHECK (uid > 800),     -- NULL: Domain.uid
    gid        INTEGER CHECK (gid >= 800),    -- NULL: 5000 (vmail)
    -- relative to /home/vmail; NULL: <domain>/<localpart>
    home       TEXT CHECK (home NOT LIKE '/%' AND home NOT LIKE '%..%'),
    -- "{SCHEME}hash", e.g. from "doveadm pw -s SHA512-CRYPT"; NULL: no login
    password   TEXT,
    -- storage limit in MB; NULL: none (enforced once the quota plugin is on)
    quota_mb   INTEGER CHECK (quota_mb > 0)
) STRICT;

-- A mailbox must belong to a 'mailbox' domain, and stay in one
CREATE TRIGGER VMailbox_domain_insert
BEFORE INSERT ON VMailbox
WHEN coalesce((SELECT D.class FROM Address A JOIN Domain D ON D.id = A.domain
               WHERE A.id = NEW.id), '') <> 'mailbox'
BEGIN
    SELECT RAISE(ABORT, 'VMailbox address must be in a mailbox domain');
END;

CREATE TRIGGER VMailbox_address_move
BEFORE UPDATE OF domain ON Address
WHEN EXISTS (SELECT 1 FROM VMailbox WHERE id = NEW.id)
 AND coalesce((SELECT class FROM Domain WHERE id = NEW.domain), '') <> 'mailbox'
BEGIN
    SELECT RAISE(ABORT, 'address has a mailbox: target domain must be a mailbox domain');
END;

CREATE TRIGGER VMailbox_domain_class
BEFORE UPDATE OF class ON Domain
WHEN NEW.class <> 'mailbox'
 AND EXISTS (SELECT 1 FROM Address A JOIN VMailbox V ON V.id = A.id
             WHERE A.domain = NEW.id)
BEGIN
    SELECT RAISE(ABORT, 'domain still has mailboxes');
END;

-- ----------------------------------------------------------------------
-- BScat: sender patterns typical of backscatter -> restriction classes
-- For check_sender_access in rob0's restriction classes; not used here.
-- ----------------------------------------------------------------------
CREATE TABLE BScat (
    id         INTEGER PRIMARY KEY,
    sender     TEXT NOT NULL COLLATE NOCASE,
    priority   INTEGER NOT NULL,
    target     TEXT NOT NULL,     -- restriction class name from main.cf
    UNIQUE (sender, priority)
) STRICT;

-- ----------------------------------------------------------------------
-- Mailbox view: one row per mailbox in an active mailbox domain, with
-- every default filled in. Read by Postfix (virtual_mailbox_maps,
-- smtpd_sender_login_maps) and Dovecot (passdb, userdb, iterate).
--   receive  1 = deliver mail to it
--   login    1 = may log in (also needs a password)
-- ----------------------------------------------------------------------
CREATE VIEW Mailbox AS
SELECT A.id                                        AS id,
       A.localpart                                 AS localpart,
       D.name                                      AS domain,
       A.localpart || '@' || D.name                AS email,
       A.active                                    AS receive,
       A.active * V.login                          AS login,
       V.password                                  AS password,
       '/home/vmail/' || coalesce(V.home, D.name || '/' || A.localpart)
                                                   AS home,
       coalesce(V.uid, D.uid)                      AS uid,
       coalesce(V.gid, 5000)                       AS gid,
       '*:storage=' || V.quota_mb || 'M'           AS quota_rule
FROM VMailbox V
  JOIN Address A ON A.id = V.id
  JOIN Domain D  ON D.id = A.domain
WHERE D.class = 'mailbox' AND D.active = 1;

-- ----------------------------------------------------------------------
-- AliasTarget view: one row per alias destination, as Postfix wants it.
--   target     "user[+ext]@domain"; NULL for actions and local targets
--   target_id  Address.id of the target (to find its mailbox)
--   active     1 only if the alias row, its address and domain are all on
-- Read by Postfix (virtual_alias_maps, smtpd_sender_login_maps).
-- ----------------------------------------------------------------------
CREATE VIEW AliasTarget AS
SELECT L.id                                        AS id,
       A.localpart                                 AS localpart,
       D.name                                      AS domain,
       L.active * A.active * D.active              AS active,
       TA.localpart || coalesce('+' || L.extension, '') || '@' || TD.name
                                                   AS target,
       L.target                                    AS target_id,
       L.action                                    AS action
FROM Alias L
  JOIN Address A      ON A.id = L.address
  JOIN Domain D       ON D.id = A.domain
  LEFT JOIN Address TA ON TA.id = L.target
  LEFT JOIN Domain TD  ON TD.id = TA.domain;

COMMIT;

PRAGMA user_version = 2;