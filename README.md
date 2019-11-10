# Rogue_TDM

[![sampctl](https://shields.southcla.ws/badge/sampctl-Rogue_TDM-2f2f2f.svg?style=for-the-badge)](https://github.com/RogueDrifter/Rogue_TDM)

## Usage

Build with:

```pawn
sampctl package ensure
sampctl package build
```

Use command:

```pawn
/jointdm
```
## Dependencies

Zcmd: https://github.com/Southclaws/zcmd

## Explanation

It's a basic TDM with cool features and sound effects + an intro.
What you can change within the script:
```
#define RTDM_EVENT_COLOR -1
#define RTDM_SKIN_RED_TEAM 212
#define RTDM_SKIN_BLUE_TEAM 287
#define RTDM_EVENT_ENTRYCASH 2500
```

## Updates

I plan on adding more textdraws and progressing for levels and upgrading weapons if i feel like its worth it.

## Credits

SovietComrade is credited for the map.
Zeex for the command processor, rest of the script is basically done by me.

## Features

Streamed music i uploaded myself (but didn’t create, credits of those sounds go to their owners not me), textdraws, custom map (also not made by me), intro once you get inside the area and respawning ability.
```
forward OnPlayerExitTDM(playerid);
public OnPlayerExitTDM(playerid)
```
This function is called remotely from the filterscript, you can use it to reset player's weather (because its set once player enters the team deatmatch) and i couldn't retrieve it because there's no GetPlayerWeather function.
