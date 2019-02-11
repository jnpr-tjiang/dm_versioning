set @dev_uuid = NULL;
set @dev_json = NULL;
call createDevice('dev-1', '{"name": "dev-1"}', @dev_uuid);
call createSnapshot("right after creating dev-1");

call getDeviceByName('dev-1', NULL, @dev_json);
select @dev_json;

call getDeviceByName('dev-1', 1, @dev_json);
select @dev_json;

call updateDevice('dev-1', '{"name": "dev-1", "description": "first modification"}');
call getDeviceByName('dev-1', 1, @dev_json);
select @dev_json;

call updateDevice('dev-1', '{"name": "dev-1", "description": "second modification"}');
call getDeviceByName('dev-1', 1, @dev_json);
select @dev_json;

