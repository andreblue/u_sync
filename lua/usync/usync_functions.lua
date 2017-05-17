function usync.Message(...)
  MsgC(USYNC_COLOR_MAIN, "[uSync] ")
  MsgC(...)
  MsgN()
end

function usync.ImportAll()
  usync.Message("Importing Data. A bot will join the game. Wait 10 minutes and then restart your server.")
  RunConsoleCommand("bot")
  local groups = table.Copy(ULib.ucl.groups)
  local users = table.Copy(ULib.ucl.users)
  local bans = table.Copy(ULib.bans)
  for k,v in pairs(groups) do
    usync.AddGroup(k, v)
  end
  for k,v in pairs(users) do
    usync.AddUser(k, v.allow, v.deny, v.group or "")
  end
  for k,v in pairs(bans) do
    usync.AddBan(k, v)
  end
  file.Write( "usync_imported.txt", "If you want to prevent it from syncing, please delete this file." )
end
