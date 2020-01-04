-- SPDX-License-Identifier: FSFAP
BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "excluded" (
	"domain_name"	TEXT,
	PRIMARY KEY("domain_name")
);
CREATE TABLE IF NOT EXISTS "results" (
	"domain_name"	TEXT NOT NULL,
	"status_code"	INTEGER,
	"timestamp"	INTEGER,
	PRIMARY KEY("domain_name")
);
CREATE TABLE IF NOT EXISTS "settings" (
	"wait_mean"	FLOAT NOT NULL,
	"wait_stddev"	FLOAT NOT NULL
);
COMMIT;
