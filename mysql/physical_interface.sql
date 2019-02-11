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
  UNIQUE (name, version),
  INDEX (start_sid, end_sid),
  FOREIGN KEY (parent_uuid)
    REFERENCES device(uuid_bin)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- CRUD stored procedures for device
DELIMITER $$
DROP PROCEDURE IF EXISTS createPhysicalInterface$$
CREATE PROCEDURE createPhysicalInterface (in deviceName varchar(255), in interfaceName varchar(255), in interfaceJson text, out uuidText varchar(36))
BEGIN
  declare uuidBin binary(16);
  declare parentUuid binary(16);

  set uuidText = uuid();
  set uuidBin = toOrderedBinUUID(uuidText);

  select uuid_bin into parentUuid from device where name = deviceName COLLATE utf8_unicode_ci and end_sid = 4294967295 limit 1;
  if parentUuid is not NULL then
    insert into physical_interface(uuid_bin, uuid_text, start_sid, name, parent_uuid, json_data)
      values (uuidBin, uuidText, currentSID(), interfaceName, parentUuid, interfaceJson);
  end if;
END$$
DELIMITER ;
