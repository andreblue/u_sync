function usync.importBans()
    for id, bandata in pairs(ULib.bans) do
        usync.addBan(id, bandata, true)
    end
end

function usync.addBan(steamid, ban_data, importRun)
    local isModify = false
    if ban_data.modified_admin or ban_data.modified_time then
        isModify = true
    end
    if isModify and not importRun then
        local updateObj = usync.database:Update(usync.config.BansTable)
            updateObj:Update("modified_admin", ban_data.modified_admin)
            updateObj:Update("modified_time", ban_data.modified_time)
            updateObj:Update("admin", ban_data.admin)
            updateObj:Update("unban", ban_data.unban)
            updateObj:Update("reason", ban_data.reason)
            updateObj:Update("name", ban_data.name or "")
            updateObj:Where("steamid", steamid)
        updateObj:Execute()
    else
        local insertObj = usync.database:Insert(usync.config.BansTable)
            insertObj:Insert("admin", ban_data.admin)
            insertObj:Insert("unban", ban_data.unban)
            insertObj:Insert("reason", ban_data.reason)
            insertObj:Insert("name", ban_data.name or "")
            insertObj:Insert("steamid", steamid)
            if importRun then
                if ban_data.modified_admin then insertObj:Insert("modified_admin", ban_data.modified_admin) end
                if ban_data.modified_time then insertObj:Insert("modified_time", ban_data.modified_time) end
            end
        insertObj:Execute()
    end
end
hook.Add("ULibPlayerBanned", "uSync Ban Add", usync.addBan)

function usync.unbanPlayer(steamid)
    local selectObj = usync.database:Select(usync.config.BansTable)
        selectObj:Where("steamid", steamid)
        selectObj:Callback(function(result, status, lastID)
            if #result == 0 then
                usync.prettyPrint("Ban for STEAM ID '" .. steamid .. "' can not be found in DB. Can not removed from DB.")
            else
                local updateObj = usync.database:Update(usync.config.BansTable)
                    updateObj:Update("active", 0)
                    updateObj:Where("steamid", steamid)
                updateObj:Execute()
            end
        end)
    selectObj:Execute()
end
hook.Add("ULibPlayerUnBanned", "uSync Unban", usync.unbanPlayer)

function usync.importGroups()
    for name, group_data in pairs(ULib.ucl.groups) do
        usync.addGroup(name, group_data, false, true)
    end
end

function usync.addGroup(name, group_data, updateGroup, importRun)
    if importRun then
        local selectObj = usync.database:Select(usync.config.GroupsTable)
            selectObj:Where("name", name)
            selectObj:Callback(function(result, status, lastID)
                if #result > 0 then
                    usync.prettyPrint("Group '" .. name .. "' exists in DB. Delete it from the DB if you wish for the importer to import it from the server.")
                else
                    local insertObj = usync.database:Insert(usync.config.GroupsTable)
                        insertObj:Insert("group_data", util.TableToJSON(group_data))
                        insertObj:Insert("name", name)
                    insertObj:Execute()
                end
            end)
        selectObj:Execute()
    else
        if updateGroup then
            local updateObj = usync.database:Update(usync.config.GroupsTable)
                updateObj:Update("group_data", util.TableToJSON(group_data))
                updateObj:Where("name", name)
            updateObj:Execute()
        else
            local insertObj = usync.database:Insert(usync.config.GroupsTable)
                insertObj:Insert("group_data", util.TableToJSON(group_data))
                insertObj:Insert("name", name)
            insertObj:Execute()
        end
    end
end
hook.Add("ULibGroupCreated", "uSync Group Add", usync.addGroup)

function usync.updateGroup(group_name)
    usync.addGroup(group_name, ULib.ucl.groups[group_name], true, false)
end
hook.Add("ULibGroupCanTargetChanged", "uSync Group Edited - Target", usync.updateGroup)
hook.Add("ULibGroupInheritanceChanged", "uSync Group Edited - Inheritance", usync.updateGroup)
hook.Add("ULibGroupAccessChanged", "uSync Group Edited - Access", usync.updateGroup)

function usync.updateGroupName(old_name, new_name)
    local selectObj = usync.database:Select(usync.config.GroupsTable)
        selectObj:Where("name", old_name)
        selectObj:Callback(function(result, status, lastID)
            if #result == 0 then
                usync.prettyPrint("Group '" .. old_name .. "' does not exist in DB, thus cannot up update it.")
            else
                local updateObj = usync.database:Update(usync.config.GroupsTable)
                    updateObj:Update("name", new_name)
                    updateObj:Where("name", old_name)
                updateObj:Execute()
            end
        end)
    selectObj:Execute()
end
hook.Add("ULibGroupRenamed", "uSync Group Renamed", usync.updateGroupName)

function usync.deleteGroup(name)
    local selectObj = usync.database:Select(usync.config.GroupsTable)
        selectObj:Where("name", name)
        selectObj:Callback(function(result, status, lastID)
            if #result == 0 then
                usync.prettyPrint("Group '" .. name .. "' does not exist in DB, thus cannot be deleted.")
            else
                local deleteObj = usync.database:Delete(usync.config.GroupsTable)
                    deleteObj:Where("name", name)
                deleteObj:Execute()
            end
        end)
    selectObj:Execute()
end
hook.Add("ULibGroupRemoved", "uSync Group Removed", usync.deleteGroup)

function usync.importUsers()
    for id, user_data in pairs(ULib.ucl.users) do
        usync.addUser(id, true)
    end
end

function usync.addUser(steamid, importRun)
    local selectObj = usync.database:Select(usync.config.UsersTable)
        selectObj:Where("steamid", steamid)
        selectObj:Callback(function(result, status, lastID)
            if #result == 0 then
                local insertObj = usync.database:Insert(usync.config.UsersTable)
                    insertObj:Insert("user_data", util.TableToJSON(ULib.ucl.users[ steamid ]))
                    insertObj:Insert("steamid", steamid)
                insertObj:Execute()
            else
                if importRun then usync.prettyPrint("User '" .. steamid .. "' exists in the DB. Delete them if you want to import them!") return end
                local updateObj = usync.database:Update(usync.config.UsersTable)
                    updateObj:Update("user_data", util.TableToJSON(ULib.ucl.users[ steamid ]))
                    updateObj:Where("steamid", steamid)
                updateObj:Execute()
            end
        end)
    selectObj:Execute()
end

hook.Add("ULibUserGroupChange", "uSync User Added/Update", usync.addUser)
hook.Add("ULibUserAccessChange", "uSync User Added/Update 2", usync.addUser)

function usync.removeUser(steamid)
    local selectObj = usync.database:Select(usync.config.UsersTable)
        selectObj:Where("steamid", steamid)
        selectObj:Callback(function(result, status, lastID)
            if #result == 0 then
                usync.prettyPrint("User '" .. steamid .. "' does not exists in the DB, thus cannot delete them from the DB")
            else
                local deleteObj = usync.database:Delete(usync.config.UsersTable)
                    deleteObj:Where("steamid", steamid)
                deleteObj:Execute()
            end
        end)
    selectObj:Execute()
end
hook.Add("ULibUserRemoved", "uSync User Remove", usync.removeUser)

function usync.CreateTables()
    local BanTable = [[
    CREATE TABLE IF NOT EXISTS ]] .. usync.config.BansTable .. [[ ( 
        `id` INT NOT NULL AUTO_INCREMENT , 
        `steamid` VARCHAR(255) NOT NULL , 
        `admin` VARCHAR(255) NULL , 
        `unban` VARCHAR(255) NOT NULL , 
        `time` VARCHAR(255) NOT NULL DEFAULT '0', 
        `reason` TEXT NULL , 
        `name` VARCHAR(255) NULL , 
        `modified_admin` VARCHAR(255) NULL , 
        `modified_time` VARCHAR(255) NULL , 
        `active` tinyint(1) NOT NULL DEFAULT '1',
        PRIMARY KEY (`id`)
    )]]
    usync.database:RawQuery(BanTable)
    local GroupTable = [[
    CREATE TABLE IF NOT EXISTS ]] .. usync.config.GroupsTable .. [[ (
        `id` INT NOT NULL AUTO_INCREMENT , 
        `name` VARCHAR(255) NOT NULL , 
        `group_data` LONGTEXT NOT NULL , 
        PRIMARY KEY (`id`), 
        UNIQUE (`name`)
    )]]
    usync.database:RawQuery(GroupTable)
    local UserTable = [[
    CREATE TABLE IF NOT EXISTS ]] .. usync.config.UsersTable .. [[ (
        `id` INT NOT NULL AUTO_INCREMENT , 
        `steamid` VARCHAR(255) NOT NULL , 
        `user_data` LONGTEXT NOT NULL , 
        PRIMARY KEY (`id`), 
        UNIQUE (`steamid`)
    )]]
    usync.database:RawQuery(UserTable)

end
hook.Add("DatabaseConnected", "uSyncDBConnected", usync.CreateTables)

concommand.Add( "usync_import_bans", function(ply, cmd, args, argStr)
    if ply and ply:IsValid() then return end
    usync.importBans()
end, function() end, "Imports the bans from ULib. Can only be run from the server console.", FCVAR_UNREGISTERED)
concommand.Add( "usync_import_groups", function(ply, cmd, args, argStr)
    if ply and ply:IsValid() then return end
    usync.importGroups()
end, function() end, "Imports the groups from ULib. Can only be run from the server console.", FCVAR_UNREGISTERED)
concommand.Add( "usync_import_users", function(ply, cmd, args, argStr)
    if ply and ply:IsValid() then return end
    usync.importUsers()
end, function() end, "Imports the users from ULib. Can only be run from the server console.", FCVAR_UNREGISTERED)


usync.ConvarName = "usync_autosync"
usync.RunUpdates = CreateConVar(usync.ConvarName, 0, FCVAR_ARCHIVE, "Sets usync to auto update the groups on the server from the DB. Defaults to off, allowing you to import.")
timer.Create("uSync-DB-Pull", usync.config.RefreshTime, 0, function()
    if usync.RunUpdates:GetBool() then
        usync.pullBans()
        usync.pullGroups()
        usync.pullUsers()
    end
end)

function usync.pullUsers()
    local selectObj = usync.database:Select(usync.config.UsersTable)
        selectObj:Callback(function(result, status, lastID)
            if #result then
                for id, data in pairs(result) do
                    ULib.ucl.users[data.id] = util.JSONToTable(data.user_data)
                end
                ULib.ucl.saveUsers()
            else
                usync.prettyPrint("Users could not be pulled. It returned 0 results!")
            end
        end)
    selectObj:Execute()
end

function usync.pullGroups()
    local selectObj = usync.database:Select(usync.config.GroupsTable)
        selectObj:Callback(function(result, status, lastID)
            if #result then
                for id, data in pairs(result) do
                    ULib.ucl.groups[data.name] = util.JSONToTable(data.group_data)
                end
                ULib.ucl.saveGroups()
            else
                usync.prettyPrint("Groups could not be pulled. It returned 0 results!")
            end
        end)
    selectObj:Execute()
end

--Copied from https://github.com/TeamUlysses/ulib/blob/c44d23fd82e394982eb361516140757f2fabcc54/lua/ulib/server/bans.lua#L105
--This ensures I can write the same way to the sql db like they do
local function escapeOrNull( str )
    if not str then return "NULL"
    else return sql.SQLStr(str) end
end

local function writeBan( bandata )
    sql.Query(
        "REPLACE INTO ulib_bans (steamid, time, unban, reason, name, admin, modified_admin, modified_time) " ..
        string.format( "VALUES (%s, %i, %i, %s, %s, %s, %s, %s)",
        util.SteamIDTo64( bandata.steamID ),
        bandata.time or 0,
        bandata.unban or 0,
        escapeOrNull( bandata.reason ),
        escapeOrNull( bandata.name ),
        escapeOrNull( bandata.admin ),
        escapeOrNull( bandata.modified_admin ),
        escapeOrNull( bandata.modified_time )
    )
)
end

function usync.pullBans()
    local selectObj = usync.database:Select(usync.config.BansTable)
        selectObj:Where("active", 1)
        selectObj:Callback(function(result, status, lastID)
            if #result then
                for id, data in pairs(result) do
                    local expiredBan = false
                    data.unban = tonumber(data.unban)
                    if data.unban ~= 0 and data.unban < os.time() then
                        usync.unbanPlayer(data.steamid)
                        expiredBan = true
                        ULib.unban( data.steamid, "" )
                    end
                    if not expiredBan then
                        local ban_data = {}
                        ban_data.steamID = data.steamid
                        ban_data.time = data.time
                        ban_data.unban = data.unban
                        ban_data.reason = data.reason
                        ban_data.name = data.name
                        ban_data.modified_admin = data.modified_admin
                        ban_data.modified_time = data.modified_time
                        writeBan(ban_data)
                    end
                end
                ULib.refreshBans()
            else
                usync.prettyPrint("Bans could not be pulled. It returned 0 results!")
            end
        end)
    selectObj:Execute()
end
