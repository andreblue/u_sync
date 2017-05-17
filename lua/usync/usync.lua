usync = usync or {}


--Grab the config file.
usync.config = include "usync_config.lua"

--Bring in the constants
include "usync_constants.lua"

--How about some functions now?
include "usync_functions.lua"

--And do not forget our database wrapper!
include "usync_mysql.lua"

usync.connect(usync.config.db)
usync.QueryBans()
--Refresh bans every x seconds
if file.Exists("usync_imported.txt", "DATA") then
  timer.Create("USync_Ban_Timer", usync.config.BanRefreshTime, 0, usync.QueryBans)
  timer.Simple(10, function()
    timer.Create("USync_Group_Timer", usync.config.GroupRefreshTime, 0, usync.QueryGroups)
  end)
  timer.Simple(20, function()
    timer.Create("USync_User_Timer", usync.config.UserRefreshTime, 0, usync.QueryUsers)
  end)
end
concommand.Add("usync_import", function(ply)
  if IsValid(ply) then return end
  usync.ImportAll()
end)
