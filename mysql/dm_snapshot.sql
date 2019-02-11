-- table definition
CREATE TABLE dm_snapshot (
  sid int(10) unsigned NOT NULL AUTO_INCREMENT,
  description varchar(255) DEFAULT NULL,
  timestamp datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (sid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- CRUD stored procedures for dm_snapshot
DELIMITER $$
CREATE PROCEDURE createSnapshot (in description varchar(255))
BEGIN
  insert into dm_snapshot
    set description = description;
END$$
DELIMITER ;
