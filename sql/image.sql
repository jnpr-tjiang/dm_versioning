-- table definitions
CREATE TABLE image (
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

-- CRUD stored procedures for dm_snapshot
DELIMITER $$
DROP PROCEDURE IF EXISTS createImage$$
CREATE PROCEDURE createImage (
  in imageName varchar(255), in imageData text, out uuidText varchar(36))
BEGIN
  declare uuidBin binary(16);

  set uuidText = uuid();
  set uuidBin = toOrderedBinUUID(uuidText);

  insert into image(uuid_bin, uuid_text, start_sid, name, json_data)
    values (uuidBin, uuidText, currentSID(), imageName, imageData);
END$$
DELIMITER ;
