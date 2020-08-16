
# u_sync
A simple way to sync ULib details to more then one server.


## Changes

### V 1.0.0

+ Basic Sync

+ Basic Import

+ Basic User Integration

+ Basic Group Integration

+ Basic Ban Integration


## Info

## Requirements
+ MySQL Database
+ [MySQLOO](https://github.com/FredyH/MySQLOO)

### Setup
1. Drop into addons folder.
2. Fill the config values.
3. Start the server.
4. Run usync_import_users thru console to bring in the users.
4. Run usync_import_groups thru console to bring in the groups.
4. Run usync_import_bans thru console to bring in the bans.
5. Wait up to 10 minutes. If you have a large number of users, groups, and/or bans or if your mysql server is slow, will cause this to take some time.
6. Restart server, syncing will fully start.

### Errors:
If you get a "[uSync] Error: Multiple primary key defined", then you can ignore it. IT will not effect the addon.
