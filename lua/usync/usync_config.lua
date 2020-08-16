local Config = {
  db = {
    host = "127.0.0.1", --Database Host
    user = "root", --Database User
    password = "", --Database Password
    database = "usync", --Database Name
    --port = 3306 --Uncomment this line to set a port if you are not on the default port
  },
  RefreshTime = 60, --Time to refresh data in in seconds
  BansTable = "usync_bans", --The table name for bans
  UsersTable = "usync_users", --The table name for users
  GroupsTable = "usync_groups", --The table name for groups
}


--Do not touch this.
return Config
