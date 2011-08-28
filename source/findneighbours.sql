DROP TABLE IF EXISTS nbs;
CREATE TABLE nbs(
	match_id INTEGER PRIMARY KEY ,
	source_name TEXT,
	target_name TEXT,
	status INTEGER
);

-- seed neighbours
INSERT INTO nbs ( 
	SELECT matches.match_id, source_name, target_name, status
	FROM matches
	INNER JOIN status on matches.match_id = status.match_id
	WHERE matches.match_id = 2 
);

-- can be executed recursively, build neighbours
INSERT IGNORE INTO nbs (
	SELECT matches.match_id, matches.source_name, matches.target_name, status.status -- DISTINCT may be optional, look at performance
	FROM matches
	INNER JOIN status ON (matches.match_id = status.match_id AND status IN (1,2))
	INNER JOIN nbs ON ((matches.match_id != nbs.match_id) 
		AND 
		((matches.target_name = nbs.source_name OR matches.source_name = nbs.source_name) OR (matches.target_name = nbs.target_name OR matches.source_name = nbs.target_name))
	)
);

INSERT IGNORE INTO nbs (
	SELECT matches.match_id, matches.source_name, matches.target_name, status.status -- DISTINCT may be optional, look at performance
	FROM matches
	INNER JOIN status ON (matches.match_id = status.match_id AND status IN (1,2))
	INNER JOIN nbs ON ((matches.match_id != nbs.match_id) 
		AND 
		((matches.target_name = nbs.source_name OR matches.source_name = nbs.source_name) OR (matches.target_name = nbs.target_name OR matches.source_name = nbs.target_name))
	)
);

INSERT IGNORE INTO nbs (
	SELECT matches.match_id, matches.source_name, matches.target_name, status.status -- DISTINCT may be optional, look at performance
	FROM matches
	INNER JOIN status ON (matches.match_id = status.match_id AND status IN (1,2))
	INNER JOIN nbs ON ((matches.match_id != nbs.match_id) 
		AND 
		((matches.target_name = nbs.source_name OR matches.source_name = nbs.source_name) OR (matches.target_name = nbs.target_name OR matches.source_name = nbs.target_name))
	)
);

INSERT IGNORE INTO nbs (
	SELECT matches.match_id, matches.source_name, matches.target_name, status.status -- DISTINCT may be optional, look at performance
	FROM matches
	INNER JOIN status ON (matches.match_id = status.match_id AND status IN (1,2))
	INNER JOIN nbs ON ((matches.match_id != nbs.match_id) 
		AND 
		((matches.target_name = nbs.source_name OR matches.source_name = nbs.source_name) OR (matches.target_name = nbs.target_name OR matches.source_name = nbs.target_name))
	)
);

INSERT IGNORE INTO nbs (
	SELECT matches.match_id, matches.source_name, matches.target_name, status.status -- DISTINCT may be optional, look at performance
	FROM matches
	INNER JOIN status ON (matches.match_id = status.match_id AND status IN (1,2))
	INNER JOIN nbs ON ((matches.match_id != nbs.match_id) 
		AND 
		((matches.target_name = nbs.source_name OR matches.source_name = nbs.source_name) OR (matches.target_name = nbs.target_name OR matches.source_name = nbs.target_name))
	)
);

INSERT IGNORE INTO nbs (
	SELECT matches.match_id, matches.source_name, matches.target_name, status.status -- DISTINCT may be optional, look at performance
	FROM matches
	INNER JOIN status ON (matches.match_id = status.match_id AND status IN (1,2))
	INNER JOIN nbs ON ((matches.match_id != nbs.match_id) 
		AND 
		((matches.target_name = nbs.source_name OR matches.source_name = nbs.source_name) OR (matches.target_name = nbs.target_name OR matches.source_name = nbs.target_name))
	)
);

-- internal nodes (correct)
DROP TABLE IF EXISTS internal_nodes;
CREATE TABLE internal_nodes(
	fragment_id INTEGER PRIMARY KEY AUTO_INCREMENT,
	name TEXT,
	UNIQUE index_name (name(100))
);

INSERT IGNORE INTO internal_nodes (
	SELECT fragment_id, name
	FROM fragments
	INNER JOIN nbs ON (nbs.source_name = name OR nbs.target_name = name)
);

-- find extra neighbours with no restrictions
DROP TABLE IF EXISTS nbs_extra;
CREATE TABLE nbs_extra(
	match_id INTEGER PRIMARY KEY ,
	source_name TEXT,
	target_name TEXT,
	status INTEGER
);

INSERT IGNORE INTO nbs_extra (
	SELECT matches.match_id, matches.source_name, matches.target_name, status.status -- DISTINCT may be optional, look at performance
	FROM matches
	INNER JOIN status on matches.match_id = status.match_id
	INNER JOIN internal_nodes ON (matches.target_name = name OR matches.source_name = name)
	WHERE NOT EXISTS (SELECT 1 FROM nbs WHERE nbs.match_id = matches.match_id) -- I hate MySQL (should be: EXCEPT/MINUS nbs)
);

-- find extra neighbours with no duplicates
DROP TABLE IF EXISTS nbs_extra_nodup;
CREATE TABLE nbs_extra_nodup(
	match_id INTEGER PRIMARY KEY ,
	source_name TEXT,
	target_name TEXT,
	status INTEGER
);

INSERT IGNORE INTO nbs_extra_nodup (
	SELECT matches.match_id, matches.source_name, matches.target_name, status.status -- DISTINCT may be optional, look at performance
	FROM matches
	INNER JOIN status on matches.match_id = status.match_id
	INNER JOIN internal_nodes ON (matches.target_name = name OR matches.source_name = name)
	WHERE NOT EXISTS (SELECT 1 FROM nbs WHERE nbs.match_id = matches.match_id) -- I hate MySQL
	GROUP BY source_name, target_name
);

-- external nodes
DROP TABLE IF EXISTS external_nodes;
CREATE TABLE external_nodes(
	fragment_id INTEGER PRIMARY KEY AUTO_INCREMENT,
	name TEXT,
	cnt INTEGER,
	UNIQUE index_name (name(100))
);

-- we should try to keep out the duplicate links! (even if they're not real duplicates)
INSERT IGNORE INTO external_nodes (
	SELECT fragment_id, name, COUNT(*)
	FROM fragments
	INNER JOIN nbs_extra_nodup ON (nbs_extra_nodup.source_name = name OR nbs_extra_nodup.target_name = name)
	WHERE NOT EXISTS (SELECT 1 FROM internal_nodes WHERE internal_nodes.fragment_id = fragments.fragment_id)
	GROUP BY fragment_id
	HAVING COUNT(*) > 1
);

-- actually it's not necessary to calculate external_nodes, we can just take the neighbours
DROP TABLE IF EXISTS nbs_extra_filtered;
CREATE TABLE nbs_extra_filtered(
	match_id INTEGER PRIMARY KEY ,
	source_name TEXT,
	target_name TEXT,
	status INTEGER
);

INSERT IGNORE INTO nbs_extra_filtered (
	SELECT nbs_extra.*
	FROM nbs_extra
	INNER JOIN external_nodes ON (name = nbs_extra.source_name OR name = nbs_extra.target_name)
);

INSERT IGNORE INTO nbs_extra_filtered (
	SELECT nbs_extra.*
	FROM nbs_extra
	WHERE (
		SELECT COUNT(*) AS internhit
		FROM internal_nodes
		WHERE (internal_nodes.name = nbs_extra.source_name OR internal_nodes.name = nbs_extra.target_name)
	) > 1
);

DROP TABLE IF EXISTS matches_processed;
CREATE TABLE matches_processed (
	match_id INTEGER PRIMARY KEY AUTO_INCREMENT,
	source_name TEXT,
	target_name TEXT,
	transformation TEXT
);

INSERT IGNORE INTO matches_processed (
	SELECT matches.*
	FROM matches 
	INNER JOIN nbs_extra_filtered ON (matches.match_id = nbs_extra_filtered.match_id)
);

INSERT IGNORE INTO matches_processed (
	SELECT matches.*
	FROM matches 
	INNER JOIN nbs ON (matches.match_id = nbs.match_id)
);