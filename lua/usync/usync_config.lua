local Config = {
  db = {
    host = "127.0.0.1", --Database Host
    port = 0000, --Database Port
    user = "root", --Database User
    password = "", --Database Password
    database = "usync" --Database Name
  },
  BanRefreshTime = 60, --Tiem to refresh bans in in seconds
  GroupRefreshTime = 60, --Tiem to refresh groups in in seconds
  UserRefreshTime = 60, --Tiem to refresh users in in seconds
}


--Do not touch this.
return Config
