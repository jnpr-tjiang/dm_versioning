SET GLOBAL group_concat_max_len=100000;

-- custom functions
DELIMITER $$
CREATE FUNCTION currentSID() RETURNS int(10)
  DETERMINISTIC
BEGIN
  declare retval int(10);
  select sid into retval from dm_snapshot order by sid desc limit 1;
  if (retval is NULL) then
    return 0;
  else
    return retval;
  end if;
END$$ 
DELIMITER ;

DELIMITER $$
CREATE FUNCTION orderedBinUUIDToText(u binary(16)) RETURNS varchar(36)
  DETERMINISTIC
BEGIN
  return (insert(insert(insert(insert(hex(concat(substr(u, 5, 4), substr(u, 3, 2), substr(u, 1, 2), substr(u, 9, 8))), 9, 0, '-'), 14, 0, '-'), 19, 0, '-'), 24, 0, '-'));
END$$
DELIMITER ;

DELIMITER $$
CREATE FUNCTION orderedBinUUID() RETURNS binary(16)
  DETERMINISTIC
BEGIN
  RETURN toOrderedBinUUID(uuid());
END$$
DELIMITER ;

DELIMITER $$
CREATE FUNCTION toOrderedBinUUID(uuidText varchar(36)) RETURNS binary(16)
  DETERMINISTIC
BEGIN
  declare u binary(16);
  set u = unhex(replace(uuidText, '-', ''));
  RETURN (concat(substr(u, 7, 2), substr(u, 5, 2), substr(u, 1, 4), substr(u, 9, 8)));
END$$
DELIMITER ;


-- table definitions
CREATE TABLE dm_snapshot (
  sid int(10) unsigned NOT NULL AUTO_INCREMENT,
  description varchar(255) DEFAULT NULL,
  timestamp datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (sid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE device (
  uuid_bin binary(16),
  uuid_text varchar(36) NOT NULL,
  version int unsigned NOT NULL DEFAULT 0,
  start_sid int unsigned NOT NULL,
  end_sid int unsigned NOT NULL DEFAULT 4294967295,
  name varchar(255) NOT NULL,
  json_data text,
  PRIMARY KEY (uuid_bin, version),
  INDEX (name),
  INDEX (start_sid, end_sid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE physical_interface (
  uuid_bin binary(16),
  uuid_text varchar(36) NOT NULL,
  version int unsigned NOT NULL DEFAULT 0,
  start_sid int unsigned NOT NULL,
  end_sid int unsigned NOT NULL DEFAULT 4294967295,
  name varchar(255) NOT NULL,
  parent_uuid binary(16) NOT NULL,
  json_data text,
  PRIMARY KEY (uuid_bin, version),
  INDEX (name),
  INDEX (start_sid, end_sid),
  INDEX (parent_uuid),
  FOREIGN KEY (parent_uuid)
    REFERENCES device(uuid_bin)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE image (
  uuid_bin binary(16),
  uuid_text varchar(36) NOT NULL,
  version int unsigned NOT NULL DEFAULT 0,
  start_sid int unsigned NOT NULL,
  end_sid int unsigned NOT NULL DEFAULT 4294967295,
  name varchar(255) NOT NULL,
  json_data text,
  PRIMARY KEY (uuid_bin, version),
  INDEX (name),
  INDEX (start_sid, end_sid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- CRUD stored procedures for dm_snapshot
DELIMITER $$
CREATE PROCEDURE createSnapshot (in description varchar(255))
BEGIN
  insert into dm_snapshot
    set description = description;
END$$
DELIMITER ;

-- CRUD stored procedures for device 
DELIMITER $$
CREATE PROCEDURE createDevice (in deviceName varchar(255), in deviceJson text, out uuidText varchar(36))
BEGIN
  declare uuidBin binary(16);

  set uuidText = uuid();
  set uuidBin = toOrderedBinUUID(uuidText);

  insert into device(uuid_bin, uuid_text, start_sid, name, json_data)
    values (uuidBin, uuidText, currentSID(), deviceName, deviceJson);
END$$
DELIMITER ;

-- CRUD stored procedures for physical_interface
DELIMITER $$
CREATE PROCEDURE createPhysicalInterface (in deviceName varchar(255), in interfaceName varchar(255), in interfaceJson text, out uuidText varchar(36))
BEGIN
  declare uuidBin binary(16);
  declare parentUuid binary(16);

  set uuidText = uuid();
  set uuidBin = toOrderedBinUUID(uuidText);
  select uuid_bin into parentUuid from device where name = deviceName COLLATE utf8_unicode_ci and end_sid = 4294967295 limit 1;

  insert into physical_interface(uuid_bin, uuid_text, start_sid, name, parent_uuid, json_data)
    values (uuidBin, uuidText, currentSID(), interfaceName, parentUuid, interfaceJson);
END$$
DELIMITER ;

-- CRUD stored procedures for image
DELIMITER $$
CREATE PROCEDURE createImage (in imageName varchar(255), in imageData text, out uuidText varchar(36))
BEGIN
  declare uuidBin binary(16);
  declare parentUuid binary(16);

  set uuidText = uuid();
  set uuidBin = toOrderedBinUUID(uuidText);

  insert into image(uuid_bin, uuid_text, start_sid, name, json_data)
    values (uuidBin, uuidText, currentSID(), imageName, imageData);
END$$
DELIMITER ;

-- CRUD stored procedures for query device
DELIMITER $$
CREATE PROCEDURE getDeviceByUuid (in devId varchar(36), in imageData text, out uuidText varchar(36))
BEGIN
  declare uuidBin binary(16);
  declare parentUuid binary(16);

  set uuidText = uuid();
  set uuidBin = toOrderedBinUUID(uuidText);

  insert into image(uuid_bin, uuid_text, start_sid, name, json_data)
    values (uuidBin, uuidText, currentSID(), imageName, imageData);
END$$
DELIMITER ;

-- unit tests
set @dev_uuid = NULL;
call createDevice('dev-1', '{"name": "dev-1"}', @dev_uuid);
call createSnapshot("right after creating dev-1");
select @dev_uuid;

set @pi_uuid = NULL;
call createPhysicalInterface('dev-1', 'ge-0/0/0', '{"name": "ge-0/0/0"}', @pi_uuid);
select @pi_uuid;

set @img_uuid = NULL;
call createImage('img-1', '{"name": "img-1"}', @img_uuid);
select @img_uuid;

select * from dm_snapshot;
select * from device;
select *  from physical_interface;
select * from image;
