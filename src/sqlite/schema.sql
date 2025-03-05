/*
 *  Schema for multidomain virtual mailbox service
 *
 */

PRAGMA foreign_keys=ON;
BEGIN TRANSACTION;

CREATE TABLE "Transport" (
    id INTEGER PRIMARY KEY,
    active INTEGER DEFAULT 1, 
    transport TEXT, 
    nexthop INTEGER,
    mx INTEGER DEFAULT 1, 
    port INTEGER,
    UNIQUE (transport, nexthop, mx, port)
);
-- Transport.nexthop would be a pointer to Domain.id, but without a
-- foreign key constraint because the Domain table has yet to be
-- created at this point.


CREATE TABLE "Domain" (
    id INTEGER PRIMARY KEY, 
    name TEXT,
    active INTEGER DEFAULT 1, 
    class INTEGER DEFAULT 0,
    owner INTEGER DEFAULT 0, 
    transport INTEGER,
    rclass INTEGER DEFAULT 30, 
    UNIQUE (name),
    FOREIGN KEY(transport) REFERENCES Transport(id)
);
-- Insert a special record Domain.id=0 with Domain.name=NULL,
-- which maintains a defacto NOT NULL constraint for other rows.
INSERT INTO "Domain" VALUES(0, NULL, NULL, NULL, NULL, NULL, NULL);


CREATE TABLE "Address" (
    id INTEGER PRIMARY KEY,
    localpart TEXT NOT NULL, 
    domain INTEGER NOT NULL,
    active INTEGER DEFAULT 1, 
    transport INTEGER, 
    rclass INTEGER,
    FOREIGN KEY(domain) REFERENCES Domain(id),
    FOREIGN KEY(transport) REFERENCES Transport(id),
    UNIQUE (localpart, domain)
);
-- Insert a special record Address.id=0 with Address.domain=0
-- to differentiate aliases(5) commands, paths or includes from
-- address targets.
INSERT INTO "Address" VALUES(0, X'00', 0, NULL, NULL, NULL);


CREATE TABLE "Alias" (
    id INTEGER PRIMARY KEY,
    address INTEGER NOT NULL, 
    active INTEGER DEFAULT 1,
    target INTEGER NOT NULL, 
    extension TEXT,
    FOREIGN KEY(address) REFERENCES Address(id),
    FOREIGN KEY(target) REFERENCES Address(id),
    UNIQUE (address, target, extension)
);


CREATE TABLE "VMailbox" (
    id INTEGER PRIMARY KEY,
    active INTEGER DEFAULT 1, 
    uid INTEGER,
    gid INTEGER, 
    home TEXT, 
    password TEXT,
    FOREIGN KEY(id) REFERENCES Address(id)
);


CREATE TABLE "BScat" (
    id INTEGER PRIMARY KEY,
    sender TEXT NOT NULL, 
    priority INTEGER NOT NULL,
    target TEXT NOT NULL, 
    UNIQUE (sender, priority)
);


COMMIT;

