SET GLOBAL group_concat_max_len=100000;

-- custom functions
DELIMITER $$
DROP FUNCTION IF EXISTS currentSID$$
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

DROP FUNCTION IF EXISTS orderedBinUUIDToText$$
CREATE FUNCTION orderedBinUUIDToText(u binary(16)) RETURNS varchar(36)
  DETERMINISTIC
BEGIN
  return (insert(insert(insert(insert(hex(concat(substr(u, 5, 4), substr(u, 3, 2), substr(u, 1, 2), substr(u, 9, 8))), 9, 0, '-'), 14, 0, '-'), 19, 0, '-'), 24, 0, '-'));
END$$

DROP FUNCTION IF EXISTS orderedBinUUID$$
CREATE FUNCTION orderedBinUUID() RETURNS binary(16)
  DETERMINISTIC
BEGIN
  RETURN toOrderedBinUUID(uuid());
END$$

DROP FUNCTION IF EXISTS toOrderedBinUUID$$
CREATE FUNCTION toOrderedBinUUID(uuidText varchar(36)) RETURNS binary(16)
  DETERMINISTIC
BEGIN
  declare u binary(16);
  set u = unhex(replace(uuidText, '-', ''));
  RETURN (concat(substr(u, 7, 2), substr(u, 5, 2), substr(u, 1, 4), substr(u, 9, 8)));
END$$
DELIMITER ;
