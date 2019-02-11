CREATE TABLE device (
  uuid_bin binary(16),
  uuid_text varchar(36) NOT NULL,
  version int unsigned NOT NULL DEFAULT 0,
  start_sid int unsigned NOT NULL,
  end_sid int unsigned NOT NULL DEFAULT 4294967295,
  name varchar(255) NOT NULL,
  json_data text,
  PRIMARY KEY (uuid_bin, version),
  UNIQUE (name, version),
  INDEX (start_sid, end_sid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- CRUD stored procedures for device
DELIMITER $$
DROP PROCEDURE IF EXISTS createDevice$$
CREATE PROCEDURE createDevice (in deviceName varchar(255), in deviceJson text, out uuidText varchar(36))
BEGIN
  declare uuidBin binary(16);

  set uuidText = uuid();
  set uuidBin = toOrderedBinUUID(uuidText);

  insert into device(uuid_bin, uuid_text, start_sid, name, json_data)
    values (uuidBin, uuidText, currentSID(), deviceName, deviceJson);
END$$

DROP PROCEDURE IF EXISTS updateDevice$$
CREATE PROCEDURE updateDevice (in deviceName varchar(255), in deviceJson text)
BEGIN
  declare uuidBin binary(16);
  declare ver int;
  declare startSid int;
  declare currentSid int;

  set uuidBin = NULL;
  set ver = NULL;
  set startSid = NULL;
  set currentSid = currentSID();

  -- find the latest object version first
  select uuid_bin, version, start_sid into uuidBin, ver, startSid from device
    where name = deviceName COLLATE utf8_unicode_ci and end_sid = 4294967295 limit 1;

  if (uuidBin is not NULL and ver is not NULL) then
    -- found the latest version
    if (startSid < currentSid) then
      -- db snapshot created after this latest version, so need to change the end_sid
      -- of this latest version to make it older version and insert a new version
      update device set end_sid = currentSid
        where uuid_bin = uuidBin and version = ver;
      insert into device(uuid_bin, uuid_text, version, start_sid, name, json_data)
        values (uuidBin, orderedBinUUIDToText(uuidBin), ver+1, currentSid, deviceName, deviceJson);
    else
      -- no db snapshot created after this latest version, so let's do in-place update
      update device set json_data = deviceJson
        where uuid_bin = uuidBin and version = ver;
    end if;
  else
    signal SQLSTATE '45000' set MESSAGE_TEXT = 'object not found';
  end if;
END$$

DROP PROCEDURE IF EXISTS deleteDevice$$
CREATE PROCEDURE deleteDevice (in deviceName varchar(255))
BEGIN
  declare uuidBin binary(16);
  declare ver int;
  declare startSid int;
  declare currentSid int;

  set uuidBin = NULL;
  set ver = NULL;
  set startSid = NULL;
  set currentSid = currentSID();

  -- find the latest object version first
  select uuid_bin, version, start_sid into uuidBin, ver, startSid from device
    where name = deviceName COLLATE utf8_unicode_ci and end_sid = 4294967295 limit 1;

  if (uuidBin is not NULL and ver is not NULL) then
    -- found the latest version
    if (startSid < currentSid) then
      -- db snapshot created after this latest version, so need to change the end_sid
      -- of this latest version to make it older version
      update device set end_sid = currentSid
        where uuid_bin = uuidBin and version = ver;
    else
      -- no db snapshot created after this latest version, so let's delete the record
      delete from device where uuid_bin = uuidBin and version = ver;
    end if;
  else
    -- object nof found
    signal SQLSTATE '45000' set MESSAGE_TEXT = 'object not found';
  end if;
END$$

DROP PROCEDURE IF EXISTS getDeviceByName$$
CREATE PROCEDURE getDeviceByName (in deviceName varchar(255), in sid int, out deviceJson text)
BEGIN
  if sid is NULL then
    select json_data into deviceJson from device
      where name = deviceName COLLATE utf8_unicode_ci and sid = 4294967295 limit 1;
  else
    select json_data into deviceJson from device
      where name = deviceName COLLATE utf8_unicode_ci and sid <= start_sid and sid < end_sid limit 1;
  end if;
END$$
DELIMITER ;
