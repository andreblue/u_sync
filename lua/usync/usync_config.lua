local Config = {
  db = {
    host = "127.0.0.1", --Database Host
    user = "root", --Database User
    password = "", --Database Password
    database = "usync", --Database Name
    --port = 3306 --Uncomment this line to set a port if you are not on the default port
  },
  BanRefreshTime = 60, --Tiem to refresh bans in in seconds
  GroupRefreshTime = 60, --Tiem to refresh groups in in seconds
  UserRefreshTime = 60, --Tiem to refresh users in in seconds
}


--Do not touch this.
return Config
