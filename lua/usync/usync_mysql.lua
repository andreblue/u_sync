--Connection Function
function usync.connect(connection_info)
  if type(connection_info) ~= "table" then
    return false, USYNC_INVALD_ARGS, "The passed arguments were not a table. Please correct this."
  end
  require( "mysqloo" )
  if not mysqloo then
    return false, USYNC_MISSING, "Mysqloo was not found. Please install it."
  end
  local db = mysqloo.connect( connection_info.host, connection_info.user, connection_info.password, connection_info.database, connection_info.port )
  function db:onConnected()
    usync.Message("Connected to database")
    usync.CreateTables()
  end
  function db:onConnectionFailed(error_msg)
    usync.Message("Failed to connect to database.")
    usync.Message("Error: " .. error_msg)

  end
  db:setAutoReconnect(true)
  db:setMultiStatements(true)
  db:connect()
  usync.DB = db
  return db
end
--Create our tables.
function usync.CreateTables()
  local db = usync.DB

  --Create user table
  local queryStrUsers = "CREATE TABLE IF NOT EXISTS `usync_users` (`user_id` int(11) NOT NULL,`steam_id` varchar(255) NOT NULL,`allow` longtext NOT NULL,`deny` longtext NOT NULL,`current_group` varchar(255) NOT NULL); ALTER TABLE `usync_users` ADD PRIMARY KEY(`user_id`); ALTER TABLE `usync_users` CHANGE `user_id` `user_id` INT(11) NOT NULL AUTO_INCREMENT; ALTER TABLE `usync_users` ADD UNIQUE(`user_id`);"
  local queryUsers = db:query(queryStrUsers)
    function queryUsers:onSuccess(data) end
    function queryUsers:onError(error_msg)
      usync.Message("Failed to create user table.")
      usync.Message("Error: " .. error_msg)
    end
  --Create group table
  local queryStrGroups = "CREATE TABLE IF NOT EXISTS `usync_groups` (`group_id` int(11) NOT NULL,`group_name` varchar(255) NOT NULL,`allow` longtext NOT NULL,`deny` longtext NOT NULL,`inherit_from` varchar(255) NOT NULL,`can_target` varchar(255) NOT NULL); ALTER TABLE `usync_groups` ADD PRIMARY KEY(`group_id`); ALTER TABLE `usync_groups` CHANGE `group_id` `group_id` INT(11) NOT NULL AUTO_INCREMENT;"
  local queryGroups = db:query(queryStrGroups)
    function queryGroups:onSuccess(data) end
    function queryGroups:onError(error_msg)
      usync.Message("Failed to create user table.")
      usync.Message("Error: " .. error_msg)
    end
  --Create bans table
  local queryStrBans = "CREATE TABLE IF NOT EXISTS `usync_bans` (`ban_id` int(11) NOT NULL,`banned_id` varchar(255) NOT NULL,`banned_at` bigint(20) NOT NULL,`unbanned_at` bigint(20) NOT NULL,`banning_admin` varchar(255) NOT NULL,`name` varchar(255) NOT NULL,`reason` text NOT NULL,`modified_at` bigint(20) NOT NULL,`modified_admin` varchar(255) NOT NULL);  ALTER TABLE `usync_bans` ADD PRIMARY KEY(`ban_id`); ALTER TABLE `usync_bans` CHANGE `ban_id` `ban_id` INT(11) NOT NULL AUTO_INCREMENT;"
  local queryBans = db:query(queryStrBans)
    function queryBans:onSuccess(data) end
    function queryBans:onError(error_msg)
      usync.Message("Failed to create user table.")
      usync.Message("Error: " .. error_msg)
    end
  --Start Querys
  queryUsers:start()
  queryGroups:start()
  queryBans:start()
end
--Just incase we need to check if connected
function usync.IsConnected()
  return usync.DB:ping()
end
--Grab and update bans with db ones.
function usync.QueryBans()
  local db = usync.DB
  local time = os.time()
  local queryStrBanData = "SELECT * FROM `usync_bans` WHERE unbanned_at=0 OR unbanned_at > " .. tostring(time) .. " ;"
  local queryBans = db:query(queryStrBanData)
    function queryBans:onSuccess(data)
      if #data < 1 then return end
      ULib.bans = {}
      for _, data in ipairs(data) do
        local tab = {
          admin = data.banning_admin or "Unknown",
          time = data.banned_at,
          unban = data.unbanned_at,
          reason = data.reason or "No Reason Specified",
          name = data.name or "Unknown"
        }
        if data.modified_admin ~= "" then
          tab.modified_admin = data.modified_admin
        end
        if data.modified_at ~= 0 then
          tab.modified_time  = data.modified_at
        end
        ULib.bans[data.banned_id] = tab
      end
      ULib.fileWrite( ULib.BANS_FILE, ULib.makeKeyValues( ULib.bans ) )  --Save the bans
    end
    function queryBans:onError(error_msg)
      usync.Message("Failed to retrieve ban data.")
      usync.Message("Error: " .. error_msg)
    end
    queryBans:start()
end
--Hook into player banned and add it to database
function usync.AddBan(steam_id, ban_data)
  local db = usync.DB
  local queryStrBanData = [[INSERT INTO `usync_bans` (`banned_id`,`banned_at`,`unbanned_at`,`banning_admin`,`name`,`reason`,`modified_admin`,`modified_at`) VALUES (?,?,?,?,?,?,?,?);]]
  local queryBanData = db:prepare(queryStrBanData)
  function queryBanData:onError(error_msg)
    usync.Message("Failed to add ban data.")
    usync.Message("Error: " .. error_msg)
  end
  function queryBanData:onSuccess()
    usync.Message("Ban added to database")
  end
  queryBanData:setString(1, steam_id) --banned_id
  queryBanData:setNumber(2, ban_data.time) --banned_at
  queryBanData:setNumber(3, ban_data.unban) --unbanned_at
  queryBanData:setString(4, ban_data.admin) --banning_admin
  queryBanData:setString(5, ban_data.name or "Unknown Name") --name
  queryBanData:setString(6, ban_data.reason or "No Reason Specified") --reason
  queryBanData:setString(7, ban_data.modified_admin or "") --modified_admin
  queryBanData:setNumber(8, ban_data.modified_time or 0) --modified_at
  queryBanData:start()
end
hook.Add("ULibPlayerBanned", "USync_BanSave", usync.AddBan)

--Hook into player unbanned and remove it from the database
function usync.RemoveBan(steam_id)
  local db = usync.DB
  local queryStrBanData = [[DELETE FROM `usync_bans` WHERE `banned_id` = ?;]]
  local queryBanData = db:prepare(queryStrBanData)
  function queryBanData:onError(error_msg)
    usync.Message("Failed to remove ban data.")
    usync.Message("Error: " .. error_msg)
  end
  function queryBanData:onSuccess()
    usync.Message("Ban removed from database")
  end
  queryBanData:setString(1, steam_id) --banned_id
  queryBanData:start()
end
hook.Add("ULibPlayerUnBanned", "USync_UnBanSave", usync.RemoveBan)

--Groups
--Query Groups
function usync.QueryGroups()
  local db = usync.DB
  local time = os.time()
  local queryStrGroupData = "SELECT * FROM `usync_groups`;"
  local queryGroups = db:query(queryStrGroupData)
    function queryGroups:onSuccess(data)
      if #data < 1 then return end
      ULib.ucl.groups = {}
      for _, data in ipairs(data) do
        local tab = {
          allow = util.JSONToTable(data.allow or ""),
          can_target = data.can_target or "",
          inherit_from = data.inherit_from or "",
        }
        ULib.ucl.groups[data.group_name] = tab
      end
      ULib.ucl.saveGroups()  --Save the groups
    end
    function queryGroups:onError(error_msg)
      usync.Message("Failed to retrieve group data.")
      usync.Message("Error: " .. error_msg)
    end
    queryGroups:start()
end


--Add Group
function usync.AddGroup(group_name, group_data)
  local db = usync.DB
  local queryStrGroupData = [[INSERT INTO `usync_groups` (`group_name`,`allow`,`inherit_from`,`can_target`) VALUES (?,?,?,?);]]
  local queryGroupData = db:prepare(queryStrGroupData)
  function queryGroupData:onError(error_msg)
    usync.Message("Failed to add group data.")
    usync.Message("Error: " .. error_msg)
  end
  function queryGroupData:onSuccess()
    usync.Message("Group added to database")
  end
  queryGroupData:setString(1, group_name) --group_name
  queryGroupData:setString(2, util.TableToJSON(group_data.allow or {}) ) --allow
  queryGroupData:setString(3, group_data.inherit_from or "") --inherit_from
  queryGroupData:setString(4, group_data.can_target or "") --can_target
  queryGroupData:start()

end
hook.Add("ULibGroupCreated", "USync_GroupAdded", usync.AddGroup)


--Remove group
function usync.RemoveGroup(group_name)
  local db = usync.DB
  local queryStrGroupData = [[DELETE FROM `usync_groups` WHERE `group_name` = ?;]]
  local queryGroupData = db:prepare(queryStrGroupData)
  function queryGroupData:onError(error_msg)
    usync.Message("Failed to remove group data.")
    usync.Message("Error: " .. error_msg)
  end
  function queryGroupData:onSuccess()
    usync.Message("Group remove from the database")
  end
  queryGroupData:setString(1, group_name) --group_name
  queryGroupData:start()

end
hook.Add("ULibGroupRemoved", "USync_GroupRemoved", usync.RemoveGroup)

function usync.updateGroupAccess(group_name)
  local group_data = ULib.ucl.groups[group_name]
  local db = usync.DB
  local queryStrGroupData = [[UPDATE `usync_groups` SET `allow` = ?, `deny` = ? WHERE `group_name` = ?;]]
  local queryGroupData = db:prepare(queryStrGroupData)
  function queryGroupData:onError(error_msg)
    usync.Message("Failed to update group data.")
    usync.Message("Error: " .. error_msg)
  end
  function queryGroupData:onSuccess()
    usync.Message("Group updated in the database")
  end
  queryGroupData:setString(1, util.TableToJSON(group_data.allow or {})) --allow
  queryGroupData:setString(2, util.TableToJSON(group_data.deny or {})) --deny
  queryGroupData:setString(3, group_name) --group_name
  queryGroupData:start()
end
hook.Add("ULibGroupAccessChanged","USync_GroupChanged",usync.updateGroupAccess)


function usync.updateGroupTarget(group_name, new_target)
  local group_data = ULib.ucl.groups[group_name]
  local db = usync.DB
  local queryStrGroupData = [[UPDATE `usync_groups` SET `can_target` = ? WHERE `group_name` = ?;]]
  local queryGroupData = db:prepare(queryStrGroupData)
  function queryGroupData:onError(error_msg)
    usync.Message("Failed to update group data.")
    usync.Message("Error: " .. error_msg)
  end
  function queryGroupData:onSuccess()
    usync.Message("Group updated in the database")
  end
  queryGroupData:setString(1, new_target) --can_target
  queryGroupData:setString(2, group_name) --group_name
  queryGroupData:start()
end
hook.Add("ULibGroupCanTargetChanged","USync_GroupChanged", usync.updateGroupTarget)


function usync.updateGroupInheritance(group_name, new_inherit)
  local group_data = ULib.ucl.groups[group_name]
  local db = usync.DB
  local queryStrGroupData = [[UPDATE `usync_groups` SET `inherit_from` = ? WHERE `group_name` = ?;]]
  local queryGroupData = db:prepare(queryStrGroupData)
  function queryGroupData:onError(error_msg)
    usync.Message("Failed to update group data.")
    usync.Message("Error: " .. error_msg)
  end
  function queryGroupData:onSuccess()
    usync.Message("Group updated in the database")
  end
  queryGroupData:setString(1, new_inherit) --inherit_from
  queryGroupData:setString(2, group_name) --group_name
  queryGroupData:start()
end
hook.Add("ULibGroupInheritanceChanged","USync_GroupChanged", usync.updateGroupInheritance)


function usync.updateGroupName(group_name, new_name)
  local db = usync.DB
  local queryStrGroupData = [[UPDATE `usync_groups` SET `group_name` = ? WHERE `group_name` = ?;]]
  local queryGroupData = db:prepare(queryStrGroupData)
  function queryGroupData:onError(error_msg)
    usync.Message("Failed to update group data.")
    usync.Message("Error: " .. error_msg)
  end
  function queryGroupData:onSuccess()
    usync.Message("Group updated in the database")
  end
  queryGroupData:setString(1, new_name) --inherit_from
  queryGroupData:setString(2, group_name) --group_name
  queryGroupData:start()
end
hook.Add("ULibGroupRenamed","USync_GroupChanged", usync.updateGroupName)


--Users
--Add Group
function usync.AddUser(steam_id, allows, denies, new_group, old_group)
  local db = usync.DB

  local queryStrUserData = [[INSERT INTO `usync_users` (`steam_id`,`allow`,`deny`,`current_group`) VALUES (?,?,?,?);]]
  if old_group and (old_group == "" or nil) then
    queryStrUserData = [[UPDATE `usync_users` SET `allow` = ?, `deny` = ?, `current_group` = ? WHERE `steam_id` = ?;]]
  end
  local queryUserData = db:prepare(queryStrUserData)
  function queryUserData:onError(error_msg)
    if string.find(error_msg, "Duplicate entry") then
      local newqueryStr = [[UPDATE `usync_users` SET `allow` = ?, `deny` = ?, `current_group` = ? WHERE `steam_id` = ?;]]
      local doquery = db:prepare(newqueryStr)
      doquery:setString(1, util.TableToJSON(allows or {})) --allow
      doquery:setString(2, util.TableToJSON(denies or {}) ) --deny
      doquery:setString(3, new_group or "") --new_group
      doquery:setString(4, steam_id) --steam_id
      function doquery:onError(error_msg)
        usync.Message("Failed to update group data.")
        usync.Message("Error: " .. error_msg)
      end

      function doquery:onSuccess()
        usync.Message("User added/updated to database")
      end
      doquery:start()

      return
    end
    usync.Message("Failed to add/update user data.")
    usync.Message("Error: " .. error_msg)
  end
  function queryUserData:onSuccess()
    usync.Message("User added/updated to database")
  end
  if old_group and (old_group == "" or nil) then
    queryUserData:setString(1, util.TableToJSON(allows or {})) --allow
    queryUserData:setString(2, util.TableToJSON(denies or {}) ) --deny
    queryUserData:setString(3, new_group or "") --new_group
    queryUserData:setString(4, steam_id) --steam_id
  else
    queryUserData:setString(1, steam_id) --steam_id
    queryUserData:setString(2, util.TableToJSON(allows or {}) ) --allow
    queryUserData:setString(3, util.TableToJSON(denies or {}) ) --deny
    queryUserData:setString(4, new_group or "") --current_group
  end
  queryUserData:start()

end
hook.Add("ULibUserGroupChange", "USync_UserAdded", usync.AddUser)

hook.Add("ULibUserAccessChange", "USync_UserChanged", function(id)
  local userData = ULib.ucl.users[id]
  usync.AddUser(id, userData.allow, userData.deny, userData.group or "")
end)

function usync.QueryUsers()
  local db = usync.DB
  local time = os.time()
  local queryStrUserData = "SELECT * FROM `usync_users`;"
  local queryUsers = db:query(queryStrUserData)
    function queryUsers:onSuccess(data)
      if #data < 1 then return end
      ULib.ucl.users = {}
      for _, data in ipairs(data) do
        local tab = {
          allow = util.JSONToTable(data.allow or ""),
          deny = util.JSONToTable(data.deny or ""),
          group = data.current_group or "",
        }
        ULib.ucl.users[data.steam_id] = tab
      end
      ULib.ucl.saveUsers()  --Save the users
    end
    function queryUsers:onError(error_msg)
      usync.Message("Failed to retrieve user data.")
      usync.Message("Error: " .. error_msg)
    end
    queryUsers:start()
end
