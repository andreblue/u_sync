usync = usync or {}

usync.version = Vector(2,0,0)

--Grab the config file.
usync.config = include "usync_config.lua"

function usync.prettyPrint(...)
    MsgC(Color(255,255,0), "[uSync]", Color(255,255,255), ...)
    MsgN()
end

usync.prettyPrint("Starting uSync version ", usync.version.x, ".", usync.version.y, ".", usync.version.z)

usync.prettyPrint("Loading mysql lib")
usync.database = include "usync_mysql.lua"

usync.prettyPrint("Loading functions")
include "usync_funcs.lua"

usync.database:Connect(usync.config.db.host,
                       usync.config.db.user,
                       usync.config.db.password,
                       usync.config.db.database,
                       usync.config.db.port or 3306)

