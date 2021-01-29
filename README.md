# Extra Spawn Points
## Description
Adds extra CT and T spawn points in Counter-Strike: Source and Counter-Strike: Global Offensive. This is useful for large servers that have to deal with maps with not enough map spawn points.

This would only work on Counter-Strike games.

## ConVars
* **sm_ESP_spawns_t** - Amount of spawn points to enforce on the T team (Default 32).
* **sm_ESP_spawns_ct** - Amount of spawn points to enforce on the CT team (Default 32).
* **sm_ESP_teams** - Which team to add additional spawn points for. 0 = Disabled, 1 = All Teams, 2 = Terrorist only, 3 = Counter-Terrorist only (Default 1).
* **sm_ESP_course** - Whether to enable course mode or not. If 1, when T or CT spawns are at 0, the opposite team will get double the spawn points (Default 1).
* **sm_ESP_debug** - Whether to enable debugging (Default 0).
* **sm_ESP_auto** - Whether to add spawn points when a ConVar is changed. If 1, will add the spawn points as soon as a ConVar is changed (Default 0).
* **sm_ESP_mapstart_delay** - The delay of the timer on map start to add in spawn points (Default 1.0).

## Installation
You'll want to compile the source code (`scripting/ExtraSpawnPoints.sp`). Afterwards, copy/move the compiled `ExtraSpawnPoints.smx` file into the server's `addons/sourcemod/plugins` directory.

## Credits
* [Christian Deacon](https://github.com/gamemann)