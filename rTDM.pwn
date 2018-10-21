/* Rogue team deathmatch fs created 2018 september the 9th
Command: jointdm
*/

#include <a_samp>
#include <zcmd>

#define RTDM_EVENT_COLOR -1
#define RTDM_MAX_EVENT_PLAYERS 6
#define RTDM_MAX_PAUSE_WARNS 10

#define rTDM_END_REASON_DISCONNECT 0
#define rTDM_END_REASON_NOLIVES 1
#define rTDM_END_REASON_TIMEUP 2
#define rTDM_END_REASON_PAUSED 3
#define rTDM_END_REASON_GLOBAL 4

#define RTDM_SKIN_RED_TEAM 212
#define RTDM_SKIN_BLUE_TEAM 287

#define RTDM_CLASS_RED_TEAM 1
#define RTDM_CLASS_BLUE_TEAM 2

#define RTDM_MAX_PTD 2
#define RTDM_MAX_TD 11

#define RTDM_MAX_OBJECTS 840
#define RTDM_VW_ID 789

#define RTDM_EVENT_ENTRYCASH 2500
#define RTDM_HIDE_TD_TIME 5000

#define RTDM_TD_KILLS 0
#define RTDM_TD_LIVES 1

#define RTDM_TD_EXTRA_LIFE 2
#define RTDM_TD_KILL_SPREE 5

#define RTDM_TD_TIME_REMAINING 3
#define RTDM_TD_TIMER_COUNT 6

#define RTDM_TD_YOU_WON 4

#define RTDM_PTD_KILLS_COUNT 0
#define RTDM_PTD_LIVES_COUNT 1

enum RTDM_PLAYER_INFO
{
	bool:rTdmPInEvent,
	bool:rTdmReinvite,
	bool:rTdmSong,
	bool:rTdmSongTwo,
	bool:rTdmJustShot,

	rTdmWeps[13],
	rTdmAmmo[13],

	rTdmPSkin,
	rTdmPColor,
	rTdmPTeam,
	rTdmPCount,
	rTdmKills,
	rTdmLives,
	rTdmSpree,
	rTdmPVW,
	rTdmPTicks,
	rTdmWarnTicks,
	rTdmPauseTimer,
	rTdmITO, 
	rTdmITW,
	rTdmITT,

	Float:rTdmHealth,
	Float:rTdmArmour,

	Float:rTdmPX,
	Float:rTdmPY,
	Float:rTdmPZ
}

enum RTDM_GLOBAL_INFO
{
	bool:rTDM_EventOn,

	rTDM_RedTeam,
	rTDM_BlueTeam,

	rTDM_WaitTimer,
	rTDM_TimerTimer,

	rTDM_ConstantTimer,
	rTDM_LastMatch,
	
	rTDM_PlayerCount,
	rTDM_TimerTicks,
	rTDM_TimerMins
}

static
	Text:rTDM_TD[RTDM_MAX_TD],
	PlayerText:rTDM_PTD[MAX_PLAYERS][RTDM_MAX_PTD],
	rTDM_Objects[RTDM_MAX_OBJECTS],
	rTDM_CountObjects,
	rTDM_Player[MAX_PLAYERS][RTDM_PLAYER_INFO],
	rTDM_Event[RTDM_GLOBAL_INFO]
	;

public OnFilterScriptInit()
{
	rTDM_CreateObjects();
	return 1;
}

public OnFilterScriptExit()
{
	for(new i; i < RTDM_MAX_OBJECTS; i++)
	{
		DestroyObject(rTDM_Objects[i]);
	}
	return 1;
}

public OnPlayerUpdate(playerid)
{
	rTDM_Player[playerid][rTdmPTicks] = GetTickCount();
	return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	if(rTDM_Player[playerid][rTdmPInEvent])
	{
		if(!rTDM_Player[playerid][rTdmJustShot])
		{
			rTDM_Player[playerid][rTdmJustShot] = true;
			SetPlayerColor(playerid, GetPlayerColor(playerid));
			SetTimerEx("rTDM_ResetShot", 2000, false, "i", playerid);
		}
	}
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(rTDM_Player[playerid][rTdmPInEvent])
	{
		rTDM_AnnouncePlayer(playerid);
		rTDM_RewardPlayer(playerid);
		rTDM_EndEventForPlayer(playerid, rTDM_END_REASON_DISCONNECT);
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if(rTDM_Player[playerid][rTdmPInEvent])
	{
		if(rTDM_Player[playerid][rTdmLives] > 0)
		{
			rTDM_Player[playerid][rTdmLives]--;
			rTDM_Player[playerid][rTdmSpree] = 0;
			rTDM_ReinvitePlayer(playerid);
		}
		else
		{
			StopAudioStreamForPlayer(playerid);
			PlayAudioStreamForPlayer(playerid, "https://s0.vocaroo.com/media/download_temp/Vocaroo_s0Y7kznHght8.mp3");
			rTDM_AnnouncePlayer(playerid);
			rTDM_RewardPlayer(playerid);
			rTDM_EndEventForPlayer(playerid, rTDM_END_REASON_NOLIVES);
		}

		rTDM_Player[killerid][rTdmSpree]++;
		rTDM_Player[killerid][rTdmKills]++;
		if( (rTDM_Player[killerid][rTdmKills] % 5) == 0)
		{
			rTDM_Player[killerid][rTdmLives]++, rTDM_ShowTDToHide(killerid, RTDM_TD_EXTRA_LIFE);
		}

		switch(rTDM_Player[killerid][rTdmSpree])
		{
			case 2:
			{
				StopAudioStreamForPlayer(killerid);
				PlayAudioStreamForPlayer(killerid, "https://s1.vocaroo.com/media/download_temp/Vocaroo_s1Gobvhq6Ohb.mp3");
			}

			case 4:
			{
				StopAudioStreamForPlayer(killerid);
				PlayAudioStreamForPlayer(killerid, "https://s1.vocaroo.com/media/download_temp/Vocaroo_s1K5pX8qgwQH.mp3");
			}

			case 6:
			{
				StopAudioStreamForPlayer(killerid);
				PlayAudioStreamForPlayer(killerid, "https://s1.vocaroo.com/media/download_temp/Vocaroo_s1T4dS2pJmG7.mp3");
			}

			case 8:
			{
				StopAudioStreamForPlayer(killerid);
				PlayAudioStreamForPlayer(killerid, "https://s1.vocaroo.com/media/download_temp/Vocaroo_s11OZfTxqoRA.mp3");
			}

			case 10:
			{
				StopAudioStreamForPlayer(killerid);
				PlayAudioStreamForPlayer(killerid, "https://s1.vocaroo.com/media/download_temp/Vocaroo_s14HTQETMYes.mp3");
			}
		}

		switch(rTDM_Player[killerid][rTdmSpree])
		{
			case 5, 15:
			{
				rTDM_Player[killerid][rTdmLives]++, rTDM_ShowTDToHide(killerid, RTDM_TD_EXTRA_LIFE);
				rTDM_ShowTDToHide(killerid, RTDM_TD_KILL_SPREE);
			}
			case 20, 30, 35:
			{
				rTDM_Player[killerid][rTdmLives] = rTDM_Player[killerid][rTdmLives]+2;
				rTDM_ShowTDToHide(killerid, RTDM_TD_EXTRA_LIFE);
				rTDM_ShowTDToHide(killerid, RTDM_TD_KILL_SPREE);
			}

		}
		new rTdm_TDString[5];
		format(rTdm_TDString, sizeof(rTdm_TDString), "%d", rTDM_Player[killerid][rTdmLives]);
		PlayerTextDrawSetString(killerid, rTDM_PTD[killerid][RTDM_PTD_LIVES_COUNT], rTdm_TDString);

		format(rTdm_TDString, sizeof(rTdm_TDString), "%d", rTDM_Player[playerid][rTdmLives]);
		PlayerTextDrawSetString(playerid, rTDM_PTD[playerid][RTDM_PTD_LIVES_COUNT], rTdm_TDString);

		format(rTdm_TDString, sizeof(rTdm_TDString), "%d", rTDM_Player[killerid][rTdmKills]);
		PlayerTextDrawSetString(killerid, rTDM_PTD[killerid][RTDM_PTD_KILLS_COUNT], rTdm_TDString);
	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(rTDM_Player[playerid][rTdmReinvite])
	{
		SetPlayerVirtualWorld(playerid, RTDM_VW_ID);
		rTDM_SetPlayerPos(playerid, rTDM_Player[playerid][rTdmPTeam], rTDM_Player[playerid][rTdmPCount]);
		rTDM_GiveEventWeapons(playerid);
	}
	return 1;
}

public OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid, bodypart)
{
	if(rTDM_Player[playerid][rTdmPInEvent])
	{
		PlayerPlaySound(playerid, 17802, 0.0, 0.0, 0.0);
	}
	return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart)
{
	if(issuerid != INVALID_PLAYER_ID)
	{
		if(rTDM_Player[playerid][rTdmPTeam] == rTDM_Player[issuerid][rTdmPTeam]) return 0;
	}
	return 1;
}

public OnPlayerText(playerid, text[])
{
	if(rTDM_Player[playerid][rTdmPInEvent])
	{
		for(new i, j = GetPlayerPoolSize(); i <= j; i++)
		{
			if(!rTDM_Player[i][rTdmPInEvent]) continue;
			if(rTDM_Player[playerid][rTdmPTeam] == rTDM_Player[i][rTdmPTeam])
			{
				new rTDM_TeamString[150], rTDM_PName[MAX_PLAYER_NAME +1];
				GetPlayerName(playerid, rTDM_PName, sizeof(rTDM_PName));
				if(rTDM_Player[playerid][rTdmPTeam] == RTDM_CLASS_BLUE_TEAM) format(rTDM_TeamString, sizeof(rTDM_TeamString), "{0000FF}Team_Chat: (%s): {FFFFFF}%s", rTDM_PName, text);
				if(rTDM_Player[playerid][rTdmPTeam] == RTDM_CLASS_RED_TEAM)  format(rTDM_TeamString, sizeof(rTDM_TeamString), "{FF0000}Team_Chat: (%s): {FFFFFF}%s", rTDM_PName, text);
				SendClientMessage(i, RTDM_EVENT_COLOR, rTDM_TeamString);
			}
		}
		return 0;
	}
	return 1;
}

forward rTDM_ConstTimer();
public rTDM_ConstTimer()
{
	if(rTDM_Event[rTDM_RedTeam] == 0)
	{
		rTDM_AnnounceTeam(RTDM_CLASS_BLUE_TEAM);
		rTDM_RewardTeam(RTDM_CLASS_BLUE_TEAM);
		rTDM_EndEvent();
		return 1;
	}
	else if(rTDM_Event[rTDM_BlueTeam] == 0)
	{
		rTDM_AnnounceTeam(RTDM_CLASS_RED_TEAM);
		rTDM_RewardTeam(RTDM_CLASS_RED_TEAM);
		rTDM_EndEvent();
		return 1;
	}

	if(rTDM_Event[rTDM_TimerTicks] > 0) rTDM_Event[rTDM_TimerTicks] --;
	if(rTDM_Event[rTDM_TimerMins] == 0 && rTDM_Event[rTDM_TimerTicks] == 0)
	{
		for(new i, j = GetPlayerPoolSize(); i <= j; i++)
		{
			if(!rTDM_Player[i][rTdmPInEvent]) continue;
			rTDM_AnnouncePlayer(i);
			rTDM_RewardPlayer(i);
			rTDM_EndEventForPlayer(i, rTDM_END_REASON_TIMEUP);
			StopAudioStreamForPlayer(i);
			PlayAudioStreamForPlayer(i, "https://s0.vocaroo.com/media/download_temp/Vocaroo_s0NjOwClWUWz.mp3");
		}
		return 1;
	}

	if(rTDM_Event[rTDM_TimerMins] >= 0)
	{
		if(rTDM_Event[rTDM_TimerTicks] == 0)
		{
			if(rTDM_Event[rTDM_TimerMins] != 0) rTDM_Event[rTDM_TimerMins]--;
			rTDM_Event[rTDM_TimerTicks] = 60;
		}
		new rTdm_String[15];
		format(rTdm_String, sizeof(rTdm_String), "%d:%d", rTDM_Event[rTDM_TimerMins], rTDM_Event[rTDM_TimerTicks]);
		TextDrawSetString(rTDM_TD[RTDM_TD_TIMER_COUNT], rTdm_String);
	}
	return 1;
}

forward rTDM_StartTimer();
public rTDM_StartTimer()
{
	if(rTDM_Event[rTDM_RedTeam] == 0 || rTDM_Event[rTDM_BlueTeam] == 0) 
	{
		SendClientMessageToAll(RTDM_EVENT_COLOR, "Team_Deathmatch:[ The event has stopped due to not enough players entering! ]");
		return rTDM_EndEvent();
	}
	for(new i, j = GetPlayerPoolSize(); i <= j; i++)
	{
		if(!rTDM_Player[i][rTdmPInEvent]) continue;
		rTDM_SavePlayerWeapons(i);
		ResetPlayerWeapons(i);
		rTDM_GiveEventWeapons(i);
		GivePlayerMoney(i, -RTDM_EVENT_ENTRYCASH);
		TogglePlayerControllable(i, 1);
		SetPlayerVirtualWorld(i, RTDM_VW_ID);
		rTDM_EndIntro(i);
		rTDM_Player[i][rTdmPauseTimer] = SetTimerEx("rTDM_PauseCheck", 1000, true, "i", i);
		PlayAudioStreamForPlayer(i, "https://s0.vocaroo.com/media/download_temp/Vocaroo_s0NjOwClWUWz.mp3");
	}

	SendClientMessageToAll(RTDM_EVENT_COLOR, "Team_Deathmatch:[ The event has started! ]");
	rTDM_Event[rTDM_TimerTicks] = 60;
	rTDM_Event[rTDM_TimerMins] = 9;
	TextDrawSetString(rTDM_TD[RTDM_TD_TIMER_COUNT], "9:60");
	rTDM_Event[rTDM_TimerTimer] = SetTimer("rTDM_TimerCounter", 15000, true);
	rTDM_Event[rTDM_ConstantTimer] = SetTimer("rTDM_ConstTimer", 1000, true);
	return 1;
}

forward rTDM_TimerCounter();
public rTDM_TimerCounter()
{
	for(new i, j = GetPlayerPoolSize(); i <= j; i++)
	{
		if(!rTDM_Player[i][rTdmPInEvent]) continue;
		rTDM_ShowTDToHide(i, RTDM_TD_TIMER_COUNT);
		rTDM_ShowTDToHide(i, RTDM_TD_TIME_REMAINING);
	}
	return 1;
}

forward rTDM_HideTD(playerid, TD_Number);
public rTDM_HideTD(playerid, TD_Number)
{
	return TextDrawHideForPlayer(playerid, rTDM_TD[TD_Number]);
}

forward rTDM_PauseCheck(playerid);
public rTDM_PauseCheck(playerid)
{
	if(GetPlayerVirtualWorld(playerid) != RTDM_VW_ID) SetPlayerVirtualWorld(playerid, RTDM_VW_ID);

	new Float:rTX, Float:rTY, Float:rTZ;
	GetPlayerPos(playerid, rTX, rTY, rTZ);
	if(rTZ < 300.000)
	{
		rTDM_SetPlayerPos(playerid, rTDM_Player[playerid][rTdmPTeam], rTDM_Player[playerid][rTdmPCount]);
	}

	if(!rTDM_Player[playerid][rTdmJustShot])
	{
		for(new i, j = GetPlayerPoolSize(); i <= j; i++)
		{
			if(!rTDM_Player[i][rTdmPInEvent] || i == playerid) continue;
			SetPlayerMarkerForPlayer( i, playerid, ( GetPlayerColor( playerid ) & 0xFFFFFF00 ) );
		}
	}

	if(rTDM_IsPlayerPaused(playerid) && rTDM_Player[playerid][rTdmWarnTicks] < RTDM_MAX_PAUSE_WARNS)
	{
		rTDM_Player[playerid][rTdmWarnTicks]++;
	}

	else if(rTDM_IsPlayerPaused(playerid) && rTDM_Player[playerid][rTdmWarnTicks] == RTDM_MAX_PAUSE_WARNS)
	{
		StopAudioStreamForPlayer(playerid);
		PlayAudioStreamForPlayer(playerid, "https://s0.vocaroo.com/media/download_temp/Vocaroo_s0Y7kznHght8.mp3");
		rTDM_AnnouncePlayer(playerid);
		rTDM_RewardPlayer(playerid);
		rTDM_EndEventForPlayer(playerid, rTDM_END_REASON_PAUSED);
	}

	if(!rTDM_Player[playerid][rTdmSong])
	{
		if(rTDM_Player[playerid][rTdmPTeam] == RTDM_CLASS_BLUE_TEAM)
		{
			if(rTDM_Event[rTDM_BlueTeam] == 1 && rTDM_Event[rTDM_RedTeam] > 1)
			{
				StopAudioStreamForPlayer(playerid);
				PlayAudioStreamForPlayer(playerid, "https://s1.vocaroo.com/media/download_temp/Vocaroo_s1zrQasts4CV.mp3");
				rTDM_Player[playerid][rTdmSong] = true;
			}
		}

		else if(rTDM_Player[playerid][rTdmPTeam] == RTDM_CLASS_RED_TEAM)
		{
			if(rTDM_Event[rTDM_RedTeam] == 1 && rTDM_Event[rTDM_BlueTeam] > 1)
			{
				StopAudioStreamForPlayer(playerid);
				PlayAudioStreamForPlayer(playerid, "https://s1.vocaroo.com/media/download_temp/Vocaroo_s1zrQasts4CV.mp3");
				rTDM_Player[playerid][rTdmSong] = true;
			}
		}
	}

	if(!rTDM_Player[playerid][rTdmSongTwo])
	{
		if(rTDM_Event[rTDM_BlueTeam] == 1 && rTDM_Event[rTDM_RedTeam] == 1)
		{
			StopAudioStreamForPlayer(playerid);
			PlayAudioStreamForPlayer(playerid, "https://s1.vocaroo.com/media/download_temp/Vocaroo_s1MHk8jXiJ5D.mp3");
			rTDM_Player[playerid][rTdmSongTwo] = true;		
		}
	}
	return 1;
}

forward rTDM_ResetShot(playerid);
public rTDM_ResetShot(playerid)
{
	rTDM_Player[playerid][rTdmJustShot] = false;
	return 1;
}

forward rTDM_NextCam(playerid);
public rTDM_NextCam(playerid)
{
	InterpolateCameraPos(playerid, 1637.9137, 1813.3501, 514.9413, 1560.0658, 1876.5508, 540.7526, 3000);
	InterpolateCameraLookAt(playerid, 1638.5304, 1812.5640, 514.4708, 1560.8433, 1875.9233, 539.9622, 3000);
	return 1;
}

forward rTDM_ThirdCam(playerid);
public rTDM_ThirdCam(playerid)
{
	InterpolateCameraPos(playerid, 1560.0658, 1876.5508, 540.7526, 1514.4540, 1915.0052, 604.1610, 10000);
	InterpolateCameraLookAt(playerid, 1560.8433, 1875.9233, 539.9622, 1515.2559, 1914.4094, 602.8357, 10000);
	return 1;
}

forward rTDM_FinalCam(playerid);
public rTDM_FinalCam(playerid)
{
	StopAudioStreamForPlayer(playerid);
	PlayAudioStreamForPlayer(playerid, "https://s0.vocaroo.com/media/download_temp/Vocaroo_s0OPTp8wp4iG.mp3");

	new 
		Float:rTDMFloatX, Float:rTDMFloatY, Float:rTDMFloatZ;
	GetPlayerPos(playerid, rTDMFloatX, rTDMFloatY, rTDMFloatZ);

	InterpolateCameraPos(playerid, 1514.4540, 1915.0052, 604.1610, rTDMFloatX, rTDMFloatY, rTDMFloatZ+3, 4500);
	InterpolateCameraLookAt(playerid, 1515.2559, 1914.4094, 602.8357, rTDMFloatX+1, rTDMFloatY-1, rTDMFloatZ-1, 4500);
	return 1;
}

CMD:jointdm(playerid)
{
	if(rTDM_Event[rTDM_EventOn]) return SendClientMessage(playerid, RTDM_EVENT_COLOR, "Team_Deathmatch:[ The event is already running! ]");
	if(GetPlayerMoney(playerid) < RTDM_EVENT_ENTRYCASH) return SendClientMessage(playerid, RTDM_EVENT_COLOR, "Team_Deathmatch:[ You don't have enough cash! ]");
	if(rTDM_Event[rTDM_PlayerCount] == RTDM_MAX_EVENT_PLAYERS) return SendClientMessage(playerid, RTDM_EVENT_COLOR, "Team_Deathmatch:[ The event is full! ]");
	if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT) return SendClientMessage(playerid, RTDM_EVENT_COLOR, "Team_Deathmatch:[ You need to be on foot! ]");
	
	rTDM_Player[playerid][rTdmPSkin] = GetPlayerSkin(playerid);
	rTDM_Player[playerid][rTdmPColor] = GetPlayerColor(playerid);
	TogglePlayerControllable(playerid, 0);
	rTDM_SetPlayerRTeam(playerid);
	GetPlayerPos(playerid, rTDM_Player[playerid][rTdmPX], rTDM_Player[playerid][rTdmPY], rTDM_Player[playerid][rTdmPZ]);
	rTDM_Player[playerid][rTdmPCount] = rTDM_Event[rTDM_PlayerCount];
	rTDM_Player[playerid][rTdmLives] = 10;

	SetPlayerWeather(playerid, 9);
	SetPlayerTime(playerid, 23, 00);
	PlayerTextDrawSetString(playerid, rTDM_PTD[playerid][RTDM_PTD_LIVES_COUNT], "10");

	if(rTDM_Event[rTDM_PlayerCount] == 0)
	{
		rTDM_CreateTextdraws();

		rTDM_Event[rTDM_WaitTimer] = SetTimer("rTDM_StartTimer", 60*1000, false);
		SendClientMessageToAll(RTDM_EVENT_COLOR, "Team_Deathmatch:[ The event is starting in 60 seconds please type /jointdm if you want in! ]");
	}

	rTDM_CreatePlayerTextdraws(playerid);
	rTDM_Event[rTDM_PlayerCount]++;
	rTDM_Player[playerid][rTdmPVW] = GetPlayerVirtualWorld(playerid);
	GetPlayerHealth(playerid, rTDM_Player[playerid][rTdmHealth]);
	GetPlayerArmour(playerid, rTDM_Player[playerid][rTdmArmour]);

	PlayerTextDrawShow(playerid, rTDM_PTD[playerid][RTDM_PTD_LIVES_COUNT]);
	PlayerTextDrawShow(playerid, rTDM_PTD[playerid][RTDM_PTD_KILLS_COUNT]);

	for(new i = 7; i < RTDM_MAX_TD; i++)
	{
		TextDrawShowForPlayer(playerid, rTDM_TD[i]);
	}

	TextDrawShowForPlayer(playerid, rTDM_TD[RTDM_TD_KILLS]);
	TextDrawShowForPlayer(playerid, rTDM_TD[RTDM_TD_LIVES]);

	rTDM_Player[playerid][rTdmPInEvent] = true;
	rTDM_SetPlayerPos(playerid, rTDM_Player[playerid][rTdmPTeam], rTDM_Player[playerid][rTdmPCount]);
	SendClientMessage(playerid, RTDM_EVENT_COLOR, "Team_Deathmatch:[ You've entered the event! you have 10 lives for starters. ]");
	
	InterpolateCameraPos(playerid, 1560.0658, 1876.5508, 540.7526, 1637.9137, 1813.3501, 514.9413, 6000);
	InterpolateCameraLookAt(playerid, 1560.8433, 1875.9233, 539.9622, 1638.5304, 1812.5640, 514.4708, 6000);

	StopAudioStreamForPlayer(playerid);
	PlayAudioStreamForPlayer(playerid, "https://s0.vocaroo.com/media/download_temp/Vocaroo_s07h5ea7Pcjd.mp3");

	rTDM_Player[playerid][rTdmITO] = SetTimerEx("rTDM_NextCam", 6000, false, "i", playerid);
	rTDM_Player[playerid][rTdmITW] = SetTimerEx("rTDM_ThirdCam", 9500, false, "i", playerid);
	rTDM_Player[playerid][rTdmITT] = SetTimerEx("rTDM_FinalCam", 19000, false, "i", playerid);
	return 1;
}

rTDM_ReinvitePlayer(playerid)
{
	return rTDM_Player[playerid][rTdmReinvite] = true;
}

rTDM_AnnounceTeam(Team_ID)
{
	for(new i, j = GetPlayerPoolSize(); i <= j; i++)
	{
		if(rTDM_Player[i][rTdmPTeam] != Team_ID) continue;
		rTDM_ShowTDToHide(i, RTDM_TD_YOU_WON);
		SendClientMessage(i, RTDM_EVENT_COLOR, "Team_Deathmatch:[ Your team won! ]");
		StopAudioStreamForPlayer(i);
		PlayAudioStreamForPlayer(i, "https://s1.vocaroo.com/media/download_temp/Vocaroo_s13TyjaYHzJw.mp3");
	}	

	SendClientMessageToAll(RTDM_EVENT_COLOR, (Team_ID == RTDM_CLASS_BLUE_TEAM) ? ("Team_Deathmatch:[ Blue team has won! ]") : ("Team_Deathmatch:[ Red team has won! ]") );
	return 1;
}

rTDM_RewardTeam(Team_ID)
{
	for(new i, j = GetPlayerPoolSize(); i <= j; i++)
	{
		if(rTDM_Player[i][rTdmPTeam] != Team_ID) continue;
		GivePlayerMoney(i, (rTDM_Player[i][rTdmKills] + RTDM_EVENT_ENTRYCASH)*2 );
	}
	return 1;
}

rTDM_AnnouncePlayer(playerid)
{
	new rTdm_PlayerName[MAX_PLAYER_NAME + 1], rTdm_PlayerString[128];
	GetPlayerName(playerid, rTdm_PlayerName, sizeof(rTdm_PlayerName));

	format(rTdm_PlayerString, sizeof(rTdm_PlayerString), "Team_Deathmatch:[ %s has finished the event! ]", rTdm_PlayerName);
	SendClientMessageToAll(RTDM_EVENT_COLOR, rTdm_PlayerString);
	SendClientMessage(playerid, RTDM_EVENT_COLOR, "Team_Deathmatch:[ You've finished the event! ]");
	return 1;
}

rTDM_RewardPlayer(playerid)
{
	GivePlayerMoney(playerid, rTDM_Player[playerid][rTdmKills] + RTDM_EVENT_ENTRYCASH);
	return 1;
}

rTDM_SetPlayerRTeam(playerid)
{
	new rtdm_Team = random(2);
	if(rtdm_Team == 0) rtdm_Team++;
	if(rTDM_Event[rTDM_LastMatch] == rtdm_Team)
	{
		switch(rTDM_Event[rTDM_LastMatch])
		{
			case RTDM_CLASS_RED_TEAM:
			{
				rtdm_Team = RTDM_CLASS_BLUE_TEAM;
			}
			case RTDM_CLASS_BLUE_TEAM:
			{
				rtdm_Team = RTDM_CLASS_RED_TEAM;
			}
		}
	}

	rTDM_Event[rTDM_LastMatch] = rtdm_Team;
	switch(rtdm_Team)
	{
		case RTDM_CLASS_RED_TEAM:
		{
			if(rTDM_Event[rTDM_RedTeam] == (RTDM_MAX_EVENT_PLAYERS/2) ) rTDM_SetPlayerBlueTeam(playerid);
			else rTDM_SetPlayerRedTeam(playerid);

		}
		case RTDM_CLASS_BLUE_TEAM:
		{
			if(rTDM_Event[rTDM_BlueTeam] == (RTDM_MAX_EVENT_PLAYERS/2) ) rTDM_SetPlayerRedTeam(playerid);
			else rTDM_SetPlayerBlueTeam(playerid);
		}
	}
	return 1;
}

rTDM_ShowTDToHide(playerid, TD_Number)
{
	TextDrawShowForPlayer(playerid, rTDM_TD[TD_Number]);
	return SetTimerEx("rTDM_HideTD", RTDM_HIDE_TD_TIME, false, "ii", playerid, TD_Number);
}

rTDM_SetPlayerRedTeam(playerid)
{
	rTDM_Event[rTDM_RedTeam]++;
	rTDM_Player[playerid][rTdmPTeam] = RTDM_CLASS_RED_TEAM;
	SetPlayerColor(playerid, 0xFF0000AA);
	SendClientMessage(playerid, RTDM_EVENT_COLOR, "Team_Deathmatch:[ You're in the red team! ]");
	SetPlayerSkin(playerid, RTDM_SKIN_RED_TEAM);
	return 1;
}

rTDM_SetPlayerBlueTeam(playerid)
{
	rTDM_Event[rTDM_BlueTeam]++;
	rTDM_Player[playerid][rTdmPTeam] = RTDM_CLASS_BLUE_TEAM;
	SetPlayerColor(playerid, 0x0000FFAA);
	SendClientMessage(playerid, RTDM_EVENT_COLOR, "Team_Deathmatch:[ You're in the blue team! ]");
	SetPlayerSkin(playerid, RTDM_SKIN_BLUE_TEAM);
	return 1;
}

rTDM_SavePlayerWeapons(playerid)
{
	for (new i; i < 13; i++)
	{
		if(rTDM_Player[playerid][rTdmWeps][i] == 0) continue;
		GetPlayerWeaponData(playerid, i,  rTDM_Player[playerid][rTdmWeps][i], rTDM_Player[playerid][rTdmAmmo][i]);
	}
	return 1;
}

rTDM_LoadPlayerWeapons(playerid)
{
	for (new i; i < 13; i++)
	{
		if(rTDM_Player[playerid][rTdmWeps][i] == 0) continue;
		GivePlayerWeapon(playerid, rTDM_Player[playerid][rTdmWeps][i], rTDM_Player[playerid][rTdmAmmo][i]);
	}
	return 1;
}

rTDM_ResetSavedWeps(playerid)
{
	for (new i; i < 13; i++)
	{
		if(rTDM_Player[playerid][rTdmWeps][i] == 0) continue;
		rTDM_Player[playerid][rTdmWeps][i] = 0;
		rTDM_Player[playerid][rTdmAmmo][i] = 0;
	}
	return 1;
}

rTDM_GiveEventWeapons(playerid)
{
	GivePlayerWeapon(playerid, 24, 100);
	GivePlayerWeapon(playerid, 27, 100);
	GivePlayerWeapon(playerid, 32, 100);
	GivePlayerWeapon(playerid, 31, 100);
	GivePlayerWeapon(playerid, 34, 100);
	GivePlayerWeapon(playerid, 16, 10);
	return 1;
}

rTDM_IsPlayerPaused(playerid)
{
	if(GetTickCount() > (rTDM_Player[playerid][rTdmPTicks] + 1500) ) return 1;
	return 0;
}

rTDM_CreatePlayerTextdraws(playerid)
{
	rTDM_PTD[playerid][0] = CreatePlayerTextDraw(playerid, 531.250000, 384.483276, "0");
	PlayerTextDrawLetterSize(playerid, rTDM_PTD[playerid][0], 0.945999, 2.514667);
	PlayerTextDrawAlignment(playerid, rTDM_PTD[playerid][0], 1);
	PlayerTextDrawColor(playerid, rTDM_PTD[playerid][0], 255);
	PlayerTextDrawSetShadow(playerid, rTDM_PTD[playerid][0], 0);
	PlayerTextDrawSetOutline(playerid, rTDM_PTD[playerid][0], 2);
	PlayerTextDrawBackgroundColor(playerid, rTDM_PTD[playerid][0], -2022022122);
	PlayerTextDrawFont(playerid, rTDM_PTD[playerid][0], 2);
	PlayerTextDrawSetProportional(playerid, rTDM_PTD[playerid][0], 1);

	rTDM_PTD[playerid][1] = CreatePlayerTextDraw(playerid, 531.449951, 405.184539, "0");
	PlayerTextDrawLetterSize(playerid, rTDM_PTD[playerid][1], 0.945999, 2.514667);
	PlayerTextDrawAlignment(playerid, rTDM_PTD[playerid][1], 1);
	PlayerTextDrawColor(playerid, rTDM_PTD[playerid][1], 255);
	PlayerTextDrawSetShadow(playerid, rTDM_PTD[playerid][1], 0);
	PlayerTextDrawSetOutline(playerid, rTDM_PTD[playerid][1], 2);
	PlayerTextDrawBackgroundColor(playerid, rTDM_PTD[playerid][1], -2022022122);
	PlayerTextDrawFont(playerid, rTDM_PTD[playerid][1], 2);
	PlayerTextDrawSetProportional(playerid, rTDM_PTD[playerid][1], 1);
	return 1;
}

rTDM_EndIntro(playerid)
{
	SetCameraBehindPlayer(playerid);
	StopAudioStreamForPlayer(playerid);
	KillTimer(rTDM_Player[playerid][rTdmITO]);
	rTDM_Player[playerid][rTdmITO] = 0;
	KillTimer(rTDM_Player[playerid][rTdmITW]);
	rTDM_Player[playerid][rTdmITW] = 0;
	KillTimer(rTDM_Player[playerid][rTdmITT]);
	rTDM_Player[playerid][rTdmITT] = 0;
	return 1;
}

rTDM_EndEvent()
{
	for(new i; i < RTDM_MAX_TD; i++)
	{
		TextDrawDestroy(rTDM_TD[i]);
	}

	for(new i, j = GetPlayerPoolSize(); i <= j; i++)
	{
		if(rTDM_Player[i][rTdmPInEvent])
		{
			rTDM_EndEventForPlayer(i, rTDM_END_REASON_GLOBAL);
			TogglePlayerControllable(i, 1);
		}		
	}

	rTDM_CountObjects = 0;
	rTDM_Event[rTDM_EventOn] = false;
	rTDM_Event[rTDM_PlayerCount] = 0;
	rTDM_Event[rTDM_RedTeam] = 0;
	rTDM_Event[rTDM_BlueTeam] = 0;
	rTDM_Event[rTDM_LastMatch] = 0;
	rTDM_Event[rTDM_TimerTicks] = 0;
	rTDM_Event[rTDM_TimerMins] = 0;

	KillTimer(rTDM_Event[rTDM_TimerTimer]);
	rTDM_Event[rTDM_TimerTimer] = 0;
	KillTimer(rTDM_Event[rTDM_ConstantTimer]);
	rTDM_Event[rTDM_ConstantTimer] = 0;
	KillTimer(rTDM_Event[rTDM_WaitTimer]);
	rTDM_Event[rTDM_WaitTimer] = 0;

	print("Rogue TDM has ended");
	return 1;
}

rTDM_EndEventForPlayer(playerid, rTDM_EndReason)
{
	for(new i; i < RTDM_MAX_PTD; i++)
	{
		PlayerTextDrawDestroy(playerid, rTDM_PTD[playerid][i]);
	}

	switch(rTDM_Player[playerid][rTdmPTeam])
	{
		case RTDM_CLASS_RED_TEAM:
		{
			if(rTDM_Event[rTDM_RedTeam] != 0) rTDM_Event[rTDM_RedTeam]--;
		}
		case RTDM_CLASS_BLUE_TEAM:
		{
			if(rTDM_Event[rTDM_BlueTeam] != 0) rTDM_Event[rTDM_BlueTeam]--;
		}
	}
	ResetPlayerWeapons(playerid);
	SetPlayerVirtualWorld(playerid, rTDM_Player[playerid][rTdmPVW]);
	SetPlayerHealth(playerid, rTDM_Player[playerid][rTdmHealth]);
	SetPlayerArmour(playerid, rTDM_Player[playerid][rTdmArmour]);
	SetPlayerColor(playerid, rTDM_Player[playerid][rTdmPColor]);
	rTDM_LoadPlayerWeapons(playerid);
	SetCameraBehindPlayer(playerid);
	SetPlayerSkin(playerid, rTDM_Player[playerid][rTdmPSkin]);

	rTDM_Player[playerid][rTdmPColor] = 0;
	rTDM_Player[playerid][rTdmHealth] = 0.0;
	rTDM_Player[playerid][rTdmArmour] = 0.0;
	rTDM_Player[playerid][rTdmPVW] = 0;
	rTDM_Player[playerid][rTdmPTeam] = 0;
	rTDM_Player[playerid][rTdmPCount] = 0;
	rTDM_Player[playerid][rTdmKills] = 0;
	rTDM_Player[playerid][rTdmLives] = 0;
	rTDM_Player[playerid][rTdmSpree] = 0;
	rTDM_Player[playerid][rTdmPTicks] = 0;
	rTDM_Player[playerid][rTdmWarnTicks] = 0;
	rTDM_Player[playerid][rTdmPSkin] = 0;

	if(rTDM_Event[rTDM_PlayerCount] != 0) rTDM_Event[rTDM_PlayerCount]--;
	rTDM_Player[playerid][rTdmPInEvent] = false;
	rTDM_Player[playerid][rTdmReinvite] = false;
	rTDM_Player[playerid][rTdmSong] 	= false;
	rTDM_Player[playerid][rTdmSongTwo]	= false;
	rTDM_Player[playerid][rTdmJustShot]	= false;

	SetPlayerPos(playerid, rTDM_Player[playerid][rTdmPX], rTDM_Player[playerid][rTdmPY], rTDM_Player[playerid][rTdmPZ]);
	rTDM_ResetSavedWeps(playerid);
	rTDM_EndIntro(playerid);

	KillTimer(rTDM_Player[playerid][rTdmPauseTimer]);
	rTDM_Player[playerid][rTdmPauseTimer] = 0;

	rTDM_Player[playerid][rTdmPX] = 0.0;
	rTDM_Player[playerid][rTdmPY] = 0.0;
	rTDM_Player[playerid][rTdmPZ] = 0.0;

	CallRemoteFunction("OnPlayerExitTDM", "i", playerid);
	if(rTDM_EndReason != rTDM_END_REASON_GLOBAL) printf("Rogue TDM end reason for player %d was %d", playerid, rTDM_EndReason);
	return 1;
}

rTDM_SetPlayerPos(playerid, Player_Team, Player_Count)
{ 
	switch(Player_Team)
	{
		case RTDM_CLASS_RED_TEAM:
		{
			switch(Player_Count)
			{
				case 0:
				{
					SetPlayerPos(playerid, 1630.7349, 1824.6779, 517.1581);  
					SetPlayerFacingAngle(playerid, 109.1133);
				}
				case 1:
				{
					SetPlayerPos(playerid, 1665.9106, 1785.1881, 501.0787);  
					SetPlayerFacingAngle(playerid, 5.3498);
				}
				case 2:
				{
					SetPlayerPos(playerid, 1639.2458, 1794.1783, 501.0781);  
					SetPlayerFacingAngle(playerid, 2.8433);
				}
				case 3:
				{
					SetPlayerPos(playerid, 1654.7048, 1795.6423, 501.0781);  
					SetPlayerFacingAngle(playerid, 359.7100);
				}
				case 4:
				{
					SetPlayerPos(playerid, 1651.9606, 1786.6222, 505.9569);  
					SetPlayerFacingAngle(playerid, 2.5300);
				}
				case 5:
				{
					SetPlayerPos(playerid, 1639.2333, 1786.7267, 505.9569);  
					SetPlayerFacingAngle(playerid, 355.9499);
				}
			}
		}
		case RTDM_CLASS_BLUE_TEAM:
		{
			switch(Player_Count)
			{
				case 0:
				{
					SetPlayerPos(playerid, 1516.1106, 1877.1451, 500.9297);  
					SetPlayerFacingAngle(playerid, 268.2156);
				}
				case 1:
				{
					SetPlayerPos(playerid, 1528.2795, 1881.3276, 505.9232);  
					SetPlayerFacingAngle(playerid, 90.8673);
				}
				case 2:
				{
					SetPlayerPos(playerid, 1532.2135, 1875.0428, 502.3938);  
					SetPlayerFacingAngle(playerid, 232.5422);
				}
				case 3:
				{
					SetPlayerPos(playerid, 1580.6561, 1859.9786, 517.1581);  
					SetPlayerFacingAngle(playerid, 335.9923);
				}
				case 4:
				{
					SetPlayerPos(playerid, 1532.3254, 1848.7137, 487.0228);  
					SetPlayerFacingAngle(playerid, 229.0487);
				}
				case 5:
				{
					SetPlayerPos(playerid, 1525.1809, 1874.3906, 507.3394);  
					SetPlayerFacingAngle(playerid, 273.5424);
				}
			}
		}
	}
	return 1;
}

rTDM_CreateTextdraws()
{
	rTDM_TD[0] = TextDrawCreate(443.125000, 382.733276, "Kills:");
	TextDrawLetterSize(rTDM_TD[0], 0.644000, 2.776003);
	TextDrawAlignment(rTDM_TD[0], 1);
	TextDrawColor(rTDM_TD[0], 255);
	TextDrawSetShadow(rTDM_TD[0], 0);
	TextDrawSetOutline(rTDM_TD[0], 2);
	TextDrawBackgroundColor(rTDM_TD[0], -773732587);
	TextDrawFont(rTDM_TD[0], 2);
	TextDrawSetProportional(rTDM_TD[0], 1);

	rTDM_TD[1] = TextDrawCreate(443.899993, 401.866882, "Lives:");
	TextDrawLetterSize(rTDM_TD[1], 0.611000, 2.934668);
	TextDrawAlignment(rTDM_TD[1], 1);
	TextDrawColor(rTDM_TD[1], 255);
	TextDrawSetShadow(rTDM_TD[1], 0);
	TextDrawSetOutline(rTDM_TD[1], 2);
	TextDrawBackgroundColor(rTDM_TD[1], -773732587);
	TextDrawFont(rTDM_TD[1], 2);
	TextDrawSetProportional(rTDM_TD[1], 1);

	rTDM_TD[2] = TextDrawCreate(368.999755, 179.799972, "You_gained_an_~n~extra_life!");
	TextDrawLetterSize(rTDM_TD[2], 0.762999, 3.391999);
	TextDrawAlignment(rTDM_TD[2], 1);
	TextDrawColor(rTDM_TD[2], 255);
	TextDrawSetShadow(rTDM_TD[2], 0);
	TextDrawSetOutline(rTDM_TD[2], 2);
	TextDrawBackgroundColor(rTDM_TD[2], -605698249);
	TextDrawFont(rTDM_TD[2], 2);
	TextDrawSetProportional(rTDM_TD[2], 1);

	rTDM_TD[3] = TextDrawCreate(162.999755, 95.800025, "Time_remaining:");
	TextDrawLetterSize(rTDM_TD[3], 0.915000, 3.457332);
	TextDrawAlignment(rTDM_TD[3], 1);
	TextDrawColor(rTDM_TD[3], 255);
	TextDrawSetShadow(rTDM_TD[3], 0);
	TextDrawSetOutline(rTDM_TD[3], 2);
	TextDrawBackgroundColor(rTDM_TD[3], -605698249);
	TextDrawFont(rTDM_TD[3], 2);
	TextDrawSetProportional(rTDM_TD[3], 1);

	rTDM_TD[4] = TextDrawCreate(7.999755, 215.266693, "You've_won_the~n~team_deathmatch!");
	TextDrawLetterSize(rTDM_TD[4], 0.725999, 3.373332);
	TextDrawAlignment(rTDM_TD[4], 1);
	TextDrawColor(rTDM_TD[4], 255);
	TextDrawSetShadow(rTDM_TD[4], 0);
	TextDrawSetOutline(rTDM_TD[4], 2);
	TextDrawBackgroundColor(rTDM_TD[4], -605698249);
	TextDrawFont(rTDM_TD[4], 2);
	TextDrawSetProportional(rTDM_TD[4], 1);

	rTDM_TD[5] = TextDrawCreate(323.999755, 305.800018, "You're_on_a_killing~n~spree!");
	TextDrawLetterSize(rTDM_TD[5], 0.695000, 3.055998);
	TextDrawAlignment(rTDM_TD[5], 1);
	TextDrawColor(rTDM_TD[5], 255);
	TextDrawSetShadow(rTDM_TD[5], 0);
	TextDrawSetOutline(rTDM_TD[5], 2);
	TextDrawBackgroundColor(rTDM_TD[5], -605698249);
	TextDrawFont(rTDM_TD[5], 2);
	TextDrawSetProportional(rTDM_TD[5], 1);

	rTDM_TD[6] = TextDrawCreate(273.999755, 133.133361, "00:00");
	TextDrawLetterSize(rTDM_TD[6], 0.915000, 3.457332);
	TextDrawAlignment(rTDM_TD[6], 1);
	TextDrawColor(rTDM_TD[6], 255);
	TextDrawSetShadow(rTDM_TD[6], 0);
	TextDrawSetOutline(rTDM_TD[6], 2);
	TextDrawBackgroundColor(rTDM_TD[6], -605698249);
	TextDrawFont(rTDM_TD[6], 2);
	TextDrawSetProportional(rTDM_TD[6], 1);

	rTDM_TD[7] = TextDrawCreate(605.999755, 62.200019, "l");
	TextDrawLetterSize(rTDM_TD[7], 0.383000, 1.730664);
	TextDrawAlignment(rTDM_TD[7], 1);
	TextDrawColor(rTDM_TD[7], 255);
	TextDrawSetShadow(rTDM_TD[7], 0);
	TextDrawSetOutline(rTDM_TD[7], 2);
	TextDrawBackgroundColor(rTDM_TD[7], -605698249);
	TextDrawFont(rTDM_TD[7], 1);
	TextDrawSetProportional(rTDM_TD[7], 1);

	rTDM_TD[8] = TextDrawCreate(546.999755, 63.133354, "l");
	TextDrawLetterSize(rTDM_TD[8], 0.374000, 1.413329);
	TextDrawAlignment(rTDM_TD[8], 1);
	TextDrawColor(rTDM_TD[8], 255);
	TextDrawSetShadow(rTDM_TD[8], 0);
	TextDrawSetOutline(rTDM_TD[8], 2);
	TextDrawBackgroundColor(rTDM_TD[8], -605698249);
	TextDrawFont(rTDM_TD[8], 1);
	TextDrawSetProportional(rTDM_TD[8], 1);

	rTDM_TD[9] = TextDrawCreate(535.899780, 64.900024, "l");
	TextDrawLetterSize(rTDM_TD[9], 9.355998, 0.274663);
	TextDrawAlignment(rTDM_TD[9], 1);
	TextDrawColor(rTDM_TD[9], 255);
	TextDrawSetShadow(rTDM_TD[9], 0);
	TextDrawSetOutline(rTDM_TD[9], 2);
	TextDrawBackgroundColor(rTDM_TD[9], -605698249);
	TextDrawFont(rTDM_TD[9], 1);
	TextDrawSetProportional(rTDM_TD[9], 1);

	rTDM_TD[10] = TextDrawCreate(535.899780, 73.300033, "l");
	TextDrawLetterSize(rTDM_TD[10], 9.355998, 0.274663);
	TextDrawAlignment(rTDM_TD[10], 1);
	TextDrawColor(rTDM_TD[10], 255);
	TextDrawSetShadow(rTDM_TD[10], 0);
	TextDrawSetOutline(rTDM_TD[10], 2);
	TextDrawBackgroundColor(rTDM_TD[10], -605698249);
	TextDrawFont(rTDM_TD[10], 1);
	TextDrawSetProportional(rTDM_TD[10], 1);
	return 1;
}

rTDM_CreateObjects()
{
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(7558, 1507.39063, 1833.22656, 500.00000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(7559, 1667.39063, 1833.22656, 500.00000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(7987, 1647.39063, 1743.22656, 500.14001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(7435, 1647.38281, 1953.22656, 499.92999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(5773, 1533.54004, 1833.28003, 497.56201,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(7474, 1607.39063, 1953.21875, 500.08499,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(8035, 1607.39844, 1793.22656, 500.60001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(8079, 1607.39063, 1774.89844, 513.38000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(5769, 1547.52002, 1772.91003, 506.01999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(5725, 1662.14001, 1833.23999, 509.29001,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(6959, 1678.05005, 1843.22998, 500.10999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(6959, 1678.05005, 1803.22998, 500.10999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(8400, 1663.69995, 1793.31006, 504.82001,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(8400, 1676.31006, 1793.31006, 510.73999,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10997, 1663.63000, 1761.28003, 506.04999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(6959, 1678.05005, 1762.92004, 500.10999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(6959, 1678.05005, 1743.59998, 500.10999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(6252, 1463.29236, 1789.89893, 485.84500,   0.00000, 0.00000, 225.11000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(6502, 1618.18994, 1965.18005, 487.89499,   0.00000, 0.00000, 49.50000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2653, 1537.93994, 1857.28003, 504.67999,   0.00000, 90.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2653, 1537.93994, 1849.39001, 504.67999,   0.00000, 90.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2653, 1537.93994, 1841.50000, 504.67999,   0.00000, 90.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3798, 1538.92004, 1859.96997, 500.07001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3798, 1538.92004, 1859.96997, 502.07001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3798, 1540.92004, 1859.96997, 500.07001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3798, 1540.92004, 1857.96997, 500.07001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3798, 1540.92004, 1859.96997, 502.07001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3798, 1542.92004, 1859.96997, 500.07001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(964, 1538.92004, 1857.96997, 500.07651,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2978, 1540.92004, 1857.96997, 502.04999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2978, 1540.92004, 1857.96997, 502.04999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2977, 1540.92004, 1857.96997, 502.04999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3630, 1542.73999, 1844.82996, 501.54999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2567, 1593.68994, 1816.72998, 502.01999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2567, 1622.58997, 1815.43005, 502.01999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3633, 1626.53003, 1815.43005, 500.54999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(942, 1618.72998, 1821.83997, 502.51999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3567, 1618.93005, 1841.15002, 500.89999,   0.00000, 0.00000, 45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3570, 1618.93005, 1841.15002, 503.12000,   0.00000, 0.00000, 135.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3571, 1618.93005, 1841.15002, 505.81000,   0.00000, 0.00000, 135.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(925, 1622.40991, 1837.68005, 502.85001,   0.00000, 0.00000, 45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(929, 1614.53015, 1845.65002, 502.70001,   0.00000, 0.00000, 45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3066, 1615.05005, 1825.84998, 501.13000,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(5262, 1632.03003, 1858.64001, 502.98999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2669, 1621.78003, 1819.52002, 501.42001,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2649, 1557.88000, 1834.55005, 501.72000,   0.00000, -90.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2678, 1622.54004, 1822.17004, 501.29001,   0.00000, 0.00000, 80.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2679, 1621.02002, 1822.17004, 501.29001,   0.00000, 0.00000, -80.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(5819, 1549.93994, 1729.45996, 500.06000,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(6959, 1536.71997, 1723.22998, 500.10999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19913, 1665.70996, 1874.18994, 505.34000,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1636.90002, 1782.66003, 506.31000,   -90.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1568.90002, 1782.65002, 506.31000,   -90.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1559.90002, 1782.65002, 506.31000,   -90.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1559.90002, 1782.65002, 497.31000,   -90.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1568.90002, 1782.65002, 497.31000,   -90.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1577.90002, 1782.65002, 497.31000,   -90.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19913, 1508.94995, 1875.31006, 505.34000,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1666.31995, 1867.67004, 506.31000,   0.00000, -90.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1654.90002, 1782.66003, 506.31000,   -90.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1636.90002, 1782.66003, 497.31000,   -90.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1645.90002, 1782.66003, 497.31000,   -90.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1654.90002, 1782.66003, 497.31000,   -90.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10630, 1482.85999, 1855.21997, 506.92001,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1577.90002, 1782.65002, 506.31000,   -90.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1508.33997, 1876.43005, 506.31000,   0.00000, 90.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1508.33997, 1885.43005, 506.31000,   0.00000, 90.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1508.33997, 1885.43005, 497.31000,   0.00000, 90.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1508.33997, 1876.43005, 497.31000,   0.00000, 90.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1508.33997, 1867.43005, 497.31000,   0.00000, 90.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19913, 1655.18005, 1783.25000, 505.34000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1645.90002, 1782.66003, 506.31000,   -90.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1666.31995, 1876.67004, 506.31000,   0.00000, -90.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1666.31995, 1885.67004, 506.31000,   0.00000, -90.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1666.31995, 1876.67004, 497.31000,   0.00000, -90.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1666.31995, 1885.67004, 497.31000,   0.00000, -90.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1666.31995, 1867.67004, 497.31000,   0.00000, -90.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19913, 1572.37000, 1783.23999, 505.34000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3095, 1508.33997, 1867.43005, 506.31000,   0.00000, 90.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(17553, 1583.33997, 1908.31006, 514.91998,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(9741, 1635.05005, 1902.68005, 524.41998,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(1498, 1639.88000, 1884.30005, 500.14999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10425, 1693.51001, 1908.83997, 515.38000,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(9764, 1725.75000, 1883.91003, 515.38000,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(5763, 1495.71997, 1982.42004, 500.04999,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10054, 1611.88000, 1671.55005, 503.23001,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10953, 1650.93994, 1662.48999, 507.82999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3630, 1633.92004, 1788.03003, 501.54999,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3279, 1582.04004, 1858.60010, 500.07999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(925, 1621.78003, 1819.52002, 501.25000,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2889, 1582.04004, 1858.60010, 520.08002,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2888, 1582.04004, 1858.60010, 520.08002,   -30.00000, 0.00000, -125.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2887, 1582.04004, 1858.60010, 520.08002,   -30.00000, 0.00000, -125.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3573, 1601.31006, 1858.65002, 502.75000,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3574, 1618.14001, 1857.32996, 502.75000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(1437, 1626.25000, 1853.83997, 501.34000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3568, 1656.82996, 1870.32996, 502.64999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10996, 1681.50000, 1852.40002, 502.25000,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10392, 1679.37000, 1732.37000, 506.04999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(9507, 1725.34998, 1837.14001, 512.21997,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(9812, 1658.73999, 1833.05005, 512.29999,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3568, 1646.27002, 1786.19995, 502.47000,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10985, 1484.07996, 1809.19995, 487.32999,   0.00000, 45.00000, 20.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10984, 1583.98340, 1922.38818, 485.50079,   0.00000, -60.00000, 60.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3576, 1662.80005, 1865.59998, 501.57999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3279, 1632.29004, 1825.81995, 500.07999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2889, 1632.29004, 1825.81995, 520.08002,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2888, 1632.29004, 1825.81995, 520.08002,   -30.00000, 0.00000, -25.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2887, 1632.29004, 1825.81995, 520.08002,   -30.00000, 0.00000, -25.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(5262, 1661.63000, 1878.44995, 502.98001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3577, 1580.17004, 1784.82996, 500.84000,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10985, 1647.67004, 1802.62000, 500.78000,   2.00000, 0.00000, 50.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10986, 1513.25000, 1868.90002, 500.87000,   0.00000, 0.00000, 89.50000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3798, 1654.08997, 1786.84998, 504.95001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10949, 1509.76001, 1903.76001, 510.48999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(6959, 1496.72998, 1903.20996, 500.12000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(17553, 1546.06250, 1936.30005, 514.91998,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3567, 1518.50000, 1870.84998, 502.64999,   20.00000, 0.00000, -60.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(852, 1513.33997, 1875.45996, 499.88000,   0.00000, 0.00000, 45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(851, 1510.64001, 1880.78003, 500.34000,   0.00000, 0.00000, 45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(852, 1519.50000, 1880.63000, 500.04999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(850, 1522.34998, 1875.79004, 500.01999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(849, 1521.43005, 1865.31006, 500.35999,   0.00000, 0.00000, 45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(853, 1529.51001, 1865.14001, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(851, 1526.01001, 1871.34998, 500.20001,   0.00000, 0.00000, 45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(852, 1528.95996, 1876.09998, 499.88000,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(12957, 1533.29004, 1875.72998, 500.60001,   0.00000, 0.00000, -45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(956, 1537.21997, 1863.44995, 500.48999,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(955, 1536.02002, 1863.53748, 500.48999,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1510.93994, 1875.81995, 500.22000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2671, 1516.89001, 1875.56006, 499.94000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2673, 1513.33997, 1873.51001, 500.01999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1521.33997, 1869.87000, 500.20001,   0.00000, 0.00000, 45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1520.17004, 1873.56995, 500.04001,   0.00000, 0.00000, -45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1523.44995, 1872.18005, 500.00000,   0.00000, 0.00000, 45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1514.90002, 1880.34998, 500.70001,   0.00000, 0.00000, -60.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1525.96997, 1875.54004, 500.20001,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1525.02002, 1865.58997, 500.14001,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2652, 1534.56995, 1863.59998, 500.57999,   0.00000, 0.00000, 135.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2673, 1526.31995, 1866.93005, 500.16000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2859, 1521.23999, 1879.10999, 500.09000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1522.47998, 1881.54004, 500.17999,   0.00000, 0.00000, -45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1525.52002, 1880.42004, 500.35999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(850, 1529.27002, 1881.21997, 500.17999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10984, 1567.69995, 1870.27002, 500.25000,   0.00000, 0.00000, 45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3571, 1516.76013, 1869.46997, 504.22000,   0.00000, 20.00000, -150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1540.56995, 1873.43005, 500.56000,   0.00000, 0.00000, 45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(853, 1542.16003, 1876.44995, 500.29999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3800, 1533.92004, 1876.35999, 500.47000,   0.00000, 0.00000, 15.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2041, 1534.85999, 1876.21997, 500.69000,   0.00000, 0.00000, 170.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1529.06995, 1872.09998, 500.04001,   0.00000, 0.00000, 135.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2840, 1530.25000, 1873.04004, 499.94000,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(12957, 1569.90002, 1867.69995, 501.59000,   10.00000, 20.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2669, 1548.18994, 1873.68005, 501.28000,   0.00000, 0.00000, 30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1547.62988, 1874.62012, 500.34000,   0.00000, 0.00000, 30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3052, 1547.69995, 1872.68005, 500.17001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(1810, 1549.51001, 1873.19995, 500.06000,   0.00000, 0.00000, 10.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2036, 1549.29004, 1873.15002, 500.60001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2047, 1546.93005, 1875.90002, 501.50000,   0.00000, 0.00000, 30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(850, 1538.73999, 1870.92004, 500.01999,   0.00000, 0.00000, 225.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(1308, 1567.75000, 1878.64001, 500.39999,   80.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(1308, 1527.75000, 1878.64001, 500.39999,   0.00000, 87.50000, 5.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(1308, 1607.75000, 1878.64001, 500.39999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(1308, 1647.75000, 1878.64001, 500.39999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1533.97998, 1881.55005, 500.17999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(851, 1545.62000, 1870.69995, 500.20001,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1535.47998, 1872.59998, 500.20001,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2838, 1542.18005, 1874.35999, 499.94000,   0.00000, 0.00000, -45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3568, 1556.98999, 1873.21997, 502.67999,   7.50000, 0.00000, 70.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1544.53003, 1860.72998, 500.20999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1545.72998, 1860.72998, 500.20999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1546.93005, 1860.72998, 500.20999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1548.13000, 1860.72998, 500.20999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1549.32996, 1860.72998, 500.20999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1550.53003, 1860.72998, 500.20999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1551.72998, 1860.72998, 500.20999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1552.93005, 1860.72998, 500.20999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1554.13000, 1860.72998, 500.20999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1555.32996, 1860.72998, 500.20999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1544.53003, 1860.72998, 500.45999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1544.53003, 1860.72998, 500.70999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1544.53003, 1860.72998, 500.95999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(1810, 1544.55005, 1860.21997, 500.07001,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2985, 1546.93005, 1860.17004, 500.07001,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2985, 1552.93005, 1860.17004, 500.07001,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1546.93005, 1860.72998, 500.45999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1548.13000, 1860.72998, 500.45999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1549.32996, 1860.72998, 500.45999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1550.53003, 1860.72998, 500.45999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1551.72998, 1860.72998, 500.45999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1545.72998, 1860.72998, 500.45999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1552.93005, 1860.72998, 500.45999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1554.13000, 1860.72998, 500.45999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1555.32996, 1860.72998, 500.45999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1545.72998, 1860.72998, 500.70999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1546.93005, 1860.72998, 500.70999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1548.13000, 1860.72998, 500.70999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1549.32996, 1860.72998, 500.70999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1550.53003, 1860.72998, 500.70999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1551.72998, 1860.72998, 500.70999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1552.93005, 1860.72998, 500.70999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1554.13000, 1860.72998, 500.70999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1555.32996, 1860.72998, 500.70999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1545.72998, 1860.72998, 500.95999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1548.13000, 1860.72998, 500.95999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1551.72998, 1860.72998, 500.95999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1554.13000, 1860.72998, 500.95999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1555.32996, 1860.72998, 500.95999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2064, 1549.93005, 1859.57605, 500.70001,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3867, 1553.62000, 1881.47998, 515.06000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3867, 1536.18994, 1881.47998, 515.06000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3867, 1465.18994, 1881.47998, 515.06000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3867, 1482.62000, 1881.47998, 515.06000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3576, 1563.90991, 1881.15002, 501.57001,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.51001, 1860.48999, 500.20999,   0.00000, 0.00000, 135.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1859.31006, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1858.10999, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1856.91003, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1855.70996, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1854.51001, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1853.31006, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1852.10999, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1848.62988, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1847.43005, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1846.22998, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1845.03003, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1843.82996, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.51001, 1860.48999, 500.45999,   0.00000, 0.00000, 135.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1859.31006, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1858.10999, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1856.91003, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1855.70996, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1854.51001, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1853.31006, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1852.10999, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1848.62988, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1847.43005, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1846.22998, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1845.03003, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1843.82996, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.51001, 1860.48999, 500.70999,   0.00000, 0.00000, 135.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1859.31006, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1858.10999, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1856.91003, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1855.70996, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1854.51001, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1853.31006, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1852.10999, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1848.62988, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1847.43005, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1846.22998, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1845.03003, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1843.82996, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.51001, 1860.48999, 500.95999,   0.00000, 0.00000, 135.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1859.31006, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1856.91003, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1852.10999, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1854.51001, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1855.70996, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1848.62988, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1847.43005, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1846.22998, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1845.03003, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.77002, 1843.82996, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2985, 1556.20996, 1858.10999, 500.07001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2985, 1556.20996, 1853.31006, 500.07001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1551.12000, 1859.63000, 500.20999,   0.00000, 0.00000, 80.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1556.01001, 1852.10999, 500.20999,   0.00000, 0.00000, 100.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3800, 1548.53003, 1859.54004, 500.06000,   0.00000, 0.00000, 15.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2042, 1548.56995, 1859.37000, 501.22000,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2040, 1548.56006, 1859.82996, 501.22000,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3800, 1555.79004, 1855.70996, 500.06000,   0.00000, 0.00000, 115.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2043, 1555.65002, 1855.87000, 501.22000,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2041, 1555.94995, 1855.46997, 501.35001,   0.00000, 0.00000, 30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(1665, 1548.17004, 1859.59998, 501.16000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19823, 1555.66003, 1855.38000, 501.14001,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(852, 1554.22998, 1870.05005, 499.88000,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1544.29004, 1873.82996, 500.22000,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1551.30005, 1870.43005, 500.04001,   0.00000, 0.00000, -135.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1537.83997, 1881.72998, 500.35999,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1540.10999, 1881.82996, 500.35999,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3577, 1542.88000, 1881.59998, 500.82999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(925, 1551.98132, 1876.68359, 501.14999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3630, 1558.93994, 1828.51001, 501.57001,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3567, 1647.75000, 1793.45996, 503.42001,   -25.00000, 20.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(851, 1536.33997, 1866.85999, 500.35001,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1532.69995, 1865.77002, 500.34000,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1569.12000, 1861.26001, 500.56000,   0.00000, 0.00000, -45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1564.50000, 1859.95996, 500.56000,   0.00000, 0.00000, 5.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(12957, 1569.67004, 1856.93994, 500.56000,   0.00000, 0.00000, -15.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(852, 1566.68005, 1855.16003, 499.88000,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3566, 1566.93994, 1844.12000, 502.57001,   0.00000, 0.00000, 10.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(849, 1564.38000, 1853.58997, 500.20001,   0.00000, 0.00000, 15.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1570.12000, 1851.66003, 500.04001,   0.00000, 0.00000, 245.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1567.83997, 1852.64001, 500.22000,   0.00000, 0.00000, 20.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1559.53003, 1846.56995, 500.35999,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1560.15002, 1843.44995, 500.17999,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2926, 1558.59998, 1844.43005, 500.07001,   0.00000, 0.00000, 80.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2925, 1558.59998, 1844.43005, 500.07001,   0.00000, 0.00000, 80.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1559.77002, 1840.43994, 500.14001,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2674, 1561.00000, 1841.80005, 500.10001,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1558.81006, 1838.82996, 500.35999,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2671, 1560.73999, 1836.89001, 500.12000,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2670, 1559.16003, 1835.08997, 500.20001,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2673, 1558.47998, 1836.81995, 500.17999,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(853, 1569.81995, 1848.45996, 500.29999,   0.00000, 0.00000, 20.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3798, 1570.62000, 1844.88000, 499.92001,   0.00000, 0.00000, 5.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1570.34998, 1842.31995, 500.26001,   0.00000, 0.00000, 245.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(852, 1564.17004, 1842.47998, 499.92001,   0.00000, 0.00000, 20.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1564.03003, 1845.48999, 500.20001,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1564.22998, 1839.46997, 500.07999,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2673, 1565.06006, 1840.67004, 500.07999,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(12957, 1565.27002, 1834.04004, 500.56000,   0.00000, 0.00000, 35.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1570.68994, 1832.97998, 500.56000,   0.00000, 0.00000, -15.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(850, 1564.60999, 1830.16003, 500.14001,   0.00000, 0.00000, 20.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(849, 1570.81006, 1826.93005, 500.32001,   0.00000, 0.00000, 50.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10986, 1561.01001, 1789.43005, 500.88000,   0.00000, 0.00000, 89.50000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(1308, 1561.38000, 1788.66003, 500.64001,   40.00000, 0.00000, 130.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10985, 1576.96997, 1873.56006, 500.25000,   0.00000, 0.00000, 135.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10984, 1585.41003, 1874.52002, 500.25000,   0.00000, 0.00000, 135.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1580.02002, 1874.06006, 500.85001,   0.00000, 40.00000, 10.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(1308, 1587.75000, 1878.64001, 500.39999,   40.00000, 0.00000, -60.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1582.67004, 1874.07996, 501.26999,   0.00000, -10.00000, -5.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(851, 1564.05005, 1825.80005, 500.26001,   0.00000, 0.00000, 50.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(852, 1567.81006, 1822.45996, 499.89999,   0.00000, 0.00000, 50.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(853, 1570.65002, 1818.41003, 500.29999,   0.00000, 0.00000, 50.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(854, 1564.69995, 1819.17004, 500.14001,   0.00000, 0.00000, 50.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2671, 1567.78003, 1830.06995, 500.13000,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2670, 1566.34998, 1828.95996, 500.14999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1568.65002, 1828.15002, 500.31000,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2673, 1566.66003, 1827.42004, 500.10999,   0.00000, 0.00000, 45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2674, 1563.95996, 1827.68994, 500.03000,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1567.64001, 1826.06995, 500.07001,   0.00000, 0.00000, -45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1570.25000, 1824.18994, 500.09000,   0.00000, 0.00000, -60.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1565.42004, 1822.94995, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2674, 1567.10999, 1823.93994, 499.97000,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1569.31006, 1820.60999, 500.20999,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1566.29004, 1820.84998, 500.03000,   0.00000, 0.00000, -45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1567.93994, 1818.31006, 499.98999,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1568.81006, 1816.39001, 500.20999,   0.00000, 0.00000, -60.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2673, 1565.93005, 1817.68005, 500.01001,   0.00000, 0.00000, 225.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1566.55005, 1814.39001, 500.60001,   0.00000, 0.00000, 60.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(12957, 1569.62000, 1809.01001, 500.64999,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2040, 1568.10999, 1807.93005, 500.64001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2041, 1568.43005, 1807.94995, 500.73001,   0.00000, 0.00000, 30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2042, 1569.15002, 1807.30005, 500.60999,   0.00000, 0.00000, 220.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2044, 1568.67004, 1807.56006, 500.54999,   0.00000, 0.00000, 220.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2045, 1569.22998, 1808.16003, 500.57001,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1565.09998, 1811.55005, 501.20001,   -10.00000, 15.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1566.84998, 1810.54004, 500.20999,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(925, 1558.71997, 1822.72998, 501.14999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3279, 1582.04004, 1825.81995, 500.07999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2889, 1582.04004, 1825.81995, 520.08002,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2888, 1582.04004, 1825.81995, 520.08002,   -30.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2887, 1582.04004, 1825.81995, 520.08002,   -30.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2840, 1561.18005, 1824.70996, 500.07999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1561.09998, 1828.70996, 500.19000,   0.00000, 0.00000, -60.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2671, 1561.15002, 1826.46997, 500.09000,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(849, 1561.04004, 1819.97998, 500.35001,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1558.82996, 1820.20996, 500.37000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2669, 1559.75000, 1815.57996, 501.42001,   0.00000, 0.00000, 15.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2678, 1559.69995, 1812.82495, 501.28751,   0.00000, 0.00000, 15.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2679, 1561.17505, 1813.21997, 501.28751,   0.00000, 0.00000, 15.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2680, 1560.48999, 1812.82996, 501.29999,   0.00000, 0.00000, 15.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10984, 1566.37000, 1794.81006, 500.25000,   0.00000, 0.00000, 135.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(1346, 1561.25000, 1882.35999, 501.44000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2846, 1560.85999, 1880.51001, 500.07001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(853, 1564.80005, 1805.97998, 500.29999,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(851, 1570.44995, 1806.01001, 500.26001,   0.00000, 0.00000, 250.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(852, 1559.13000, 1808.65002, 500.04001,   0.00000, 0.00000, 270.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(854, 1574.62000, 1810.46997, 500.29999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(849, 1564.05005, 1801.79004, 500.32001,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1514.77002, 1863.01001, 510.23001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1514.77002, 1863.01001, 510.48001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1515.96997, 1863.01001, 510.23001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1517.17004, 1863.01001, 510.23001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1518.37000, 1863.01001, 510.23001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1519.56995, 1863.01001, 510.23001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1520.77002, 1863.01001, 510.23001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1521.96997, 1863.01001, 510.23001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1523.17004, 1863.01001, 510.23001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1524.37000, 1863.01001, 510.23001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1515.96997, 1863.01001, 510.48001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1517.17004, 1863.01001, 510.48001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1518.37000, 1863.01001, 510.48001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1519.56995, 1863.01001, 510.48001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1520.77002, 1863.01001, 510.48001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1521.96997, 1863.01001, 510.48001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1515.96997, 1863.01001, 510.73001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1519.56995, 1863.01001, 510.73001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1520.77002, 1863.01001, 510.73001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1518.37000, 1863.01001, 510.73001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1517.17004, 1863.01001, 510.73001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1519.56995, 1863.01001, 510.98001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1518.37000, 1863.01001, 510.98001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1515.96997, 1863.01001, 510.98001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1514.77002, 1863.01001, 510.73001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(852, 1569.40002, 1785.13000, 499.89999,   0.00000, 0.00000, 50.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1567.19995, 1807.06995, 500.07001,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1570.89001, 1801.65002, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1566.28247, 1803.53369, 500.09000,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2673, 1563.47998, 1807.70996, 500.10999,   0.00000, 0.00000, 45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1568.37000, 1804.50000, 500.20999,   0.00000, 0.00000, -60.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1570.57117, 1803.66052, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2674, 1568.62000, 1802.67004, 499.95001,   0.00000, 0.00000, -60.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1564.18005, 1788.71997, 500.98001,   5.00000, 5.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1566.84998, 1797.56995, 500.98001,   -10.00000, -25.00000, -70.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1566.83997, 1793.22998, 501.51999,   0.00000, 5.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1574.32996, 1807.63000, 500.37000,   0.00000, 0.00000, 30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2673, 1576.28003, 1808.70996, 500.17001,   0.00000, 0.00000, 45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1576.09998, 1806.26001, 500.17001,   0.00000, 0.00000, 30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1574.43994, 1803.88000, 500.19000,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1575.79004, 1801.10999, 500.35001,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2671, 1574.40002, 1799.38000, 500.10999,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1560.14001, 1805.78003, 500.35001,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1559.07996, 1803.12000, 500.19000,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1559.93005, 1801.40002, 500.17001,   0.00000, 0.00000, 324.55991);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1560.54004, 1799.43994, 500.35001,   0.00000, 0.00000, 304.05890);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(850, 1558.15002, 1797.18994, 500.17999,   0.00000, 0.00000, -20.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2669, 1585.68994, 1800.18005, 501.42001,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3800, 1586.54004, 1798.13000, 500.19000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3800, 1585.47253, 1798.13000, 500.19000,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1585.56006, 1800.66003, 500.48001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3565, 1580.17004, 1791.43005, 501.45001,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3570, 1580.17004, 1791.43005, 504.14499,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1574.37000, 1784.93005, 500.35001,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1575.68994, 1786.59998, 500.19000,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1576.18994, 1789.25000, 500.37000,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1576.29004, 1792.51001, 500.17001,   0.00000, 0.00000, 210.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1574.65002, 1791.31995, 500.35001,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1575.93994, 1857.03003, 500.35001,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(851, 1573.80005, 1860.64001, 500.35001,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1575.56995, 1859.07996, 500.19000,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1575.43994, 1861.95996, 500.14999,   0.00000, 0.00000, -270.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3800, 1574.65002, 1864.23999, 500.07001,   0.00000, 0.00000, 30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3800, 1574.58997, 1865.58997, 500.07001,   0.00000, 0.00000, -10.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3800, 1575.93005, 1864.96997, 500.07001,   0.00000, 0.00000, 15.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3800, 1575.23010, 1864.93005, 501.14999,   0.00000, 0.00000, -5.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(850, 1579.63000, 1864.93005, 500.35001,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1581.06006, 1866.88000, 500.14999,   0.00000, 0.00000, -270.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2674, 1576.90002, 1866.31006, 500.09000,   0.00000, 0.00000, 30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1582.88000, 1864.63000, 500.37000,   0.00000, 0.00000, -270.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2671, 1585.33997, 1865.66003, 500.09000,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19362, 1568.44751, 1835.55005, 503.29999,   0.00000, 0.00000, 100.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(852, 1575.30005, 1795.68994, 500.04999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1591.56995, 1866.31995, 500.73999,   0.00000, 0.00000, 70.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(12957, 1595.12000, 1870.50000, 500.64001,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1597.25000, 1875.43005, 500.62000,   0.00000, 0.00000, 100.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1600.65002, 1871.84998, 500.62000,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(12957, 1605.47998, 1874.94995, 500.64001,   0.00000, 0.00000, 60.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1607.15002, 1871.01001, 500.62000,   0.00000, 0.00000, 80.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(12957, 1590.02002, 1872.43005, 501.50000,   30.00000, 0.00000, 25.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(851, 1591.31006, 1870.14001, 500.20001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(852, 1546.56995, 1881.17004, 500.04999,   0.00000, 0.00000, -20.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3800, 1547.31006, 1882.58997, 500.07001,   0.00000, 0.00000, -10.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3800, 1548.59998, 1882.19995, 500.07001,   0.00000, 0.00000, 20.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3800, 1549.82996, 1882.33997, 500.07001,   0.00000, 0.00000, 25.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3800, 1549.06006, 1882.12000, 501.16000,   0.00000, 0.00000, 5.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1598.69995, 1873.37000, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1602.54004, 1876.58997, 500.20999,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10984, 1619.29639, 1878.70874, 499.51001,   0.00000, 20.00000, -95.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(849, 1532.31995, 1870.47595, 500.20001,   0.00000, 0.00000, 135.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(849, 1602.79004, 1869.96997, 500.20001,   0.00000, 0.00000, -135.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(854, 1612.90002, 1870.23999, 500.14001,   0.00000, 0.00000, -15.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1608.37000, 1877.17004, 500.03000,   0.00000, 0.00000, 30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2674, 1608.92004, 1872.97998, 499.95001,   0.00000, 0.00000, 30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10985, 1619.07996, 1877.48999, 499.85001,   0.00000, 0.00000, 15.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(10985, 1617.17004, 1874.91003, 500.00000,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3570, 1620.07996, 1881.39001, 501.82999,   20.00000, 5.00000, -10.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(1308, 1627.75000, 1878.64001, 500.39999,   0.00000, -85.00000, -5.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3567, 1625.00000, 1874.80005, 500.73999,   0.00000, 0.00000, 80.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3565, 1620.21997, 1878.21997, 503.98001,   0.00000, -15.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3565, 1620.23755, 1878.21753, 503.98001,   180.00000, 15.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(850, 1569.06006, 1880.97998, 500.35001,   0.00000, 0.00000, 270.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1572.22998, 1881.97998, 500.37000,   0.00000, 0.00000, 270.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1574.18005, 1880.67004, 500.19000,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(851, 1580.48999, 1879.18994, 500.35001,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1576.77002, 1880.87000, 500.14999,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2674, 1578.58789, 1880.52197, 500.09000,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1581.20081, 1881.83423, 500.19000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1578.07996, 1881.82996, 500.35001,   0.00000, 0.00000, 270.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(849, 1584.27002, 1881.98999, 500.37000,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1589.07996, 1881.69995, 500.37000,   0.00000, 0.00000, 270.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1590.58997, 1880.13000, 500.35001,   0.00000, 0.00000, 270.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1592.07996, 1881.15002, 500.14999,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1595.58997, 1880.65002, 500.19000,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1593.87000, 1881.93005, 500.37000,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(853, 1599.13000, 1879.80005, 500.45001,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1598.54004, 1881.83997, 500.35999,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2673, 1600.53003, 1882.25000, 500.16000,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19560, 1599.68994, 1881.62000, 500.07001,   0.00000, 0.00000, 30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2859, 1600.43994, 1881.35999, 500.09000,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1602.93225, 1881.21570, 500.19000,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2860, 1601.70996, 1882.55005, 500.09000,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2858, 1601.39001, 1881.46997, 500.09000,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1603.43005, 1879.45996, 500.37000,   0.00000, 0.00000, -150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1605.44995, 1881.43005, 500.14999,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2674, 1606.69995, 1882.47998, 500.14999,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(852, 1609.53003, 1881.81995, 500.03000,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1609.16003, 1879.90002, 500.19000,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2669, 1599.76001, 1865.76001, 501.42001,   0.00000, 0.00000, 75.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2678, 1602.12000, 1864.33997, 501.28751,   0.00000, 0.00000, 75.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2679, 1602.51501, 1865.81006, 501.28751,   0.00000, 0.00000, 75.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2680, 1602.52002, 1865.04004, 501.29999,   0.00000, 0.00000, 75.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1607.76001, 1865.13000, 500.19000,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(851, 1605.44995, 1865.89001, 500.35001,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1610.01001, 1864.40002, 500.37000,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1610.67004, 1866.68677, 500.14999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2674, 1611.87000, 1864.80005, 500.14999,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1613.74988, 1864.75818, 500.35999,   0.00000, 0.00000, 330.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(849, 1614.26001, 1866.98999, 500.35001,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3798, 1616.92004, 1865.14001, 500.07001,   0.00000, 0.00000, -10.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3798, 1619.56006, 1865.89001, 500.07001,   0.00000, 0.00000, 30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1617.22998, 1867.20996, 500.37000,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3798, 1618.31006, 1865.39001, 502.10001,   0.00000, 0.00000, 60.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3798, 1618.30750, 1865.39001, 504.10001,   0.00000, 180.00000, 60.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1625.07996, 1870.68005, 500.62000,   0.00000, 0.00000, -75.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(12957, 1623.68005, 1866.03003, 500.79999,   0.00000, 0.00000, 30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(8171, 1508.94995, 1813.76001, 530.81000,   0.00000, -90.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(8171, 1600.85999, 1783.23999, 530.81000,   0.00000, -90.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(8171, 1665.70996, 1932.40002, 530.81000,   0.00000, -90.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(8171, 1670.00000, 1852.39001, 530.81000,   0.00000, -90.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(18451, 1629.76001, 1879.48999, 500.56000,   0.00000, 0.00000, 80.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(1503, 1628.32996, 1865.32996, 500.45001,   0.00000, 0.00000, 100.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(852, 1621.64001, 1864.29004, 500.03000,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(852, 1626.76001, 1879.40002, 500.03000,   0.00000, 0.00000, 210.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1626.29004, 1877.14001, 500.20999,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3578, 1635.06006, 1873.23999, 500.85001,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1879.22998, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1880.43005, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1882.55005, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1879.22998, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1879.22998, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1879.22998, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1880.43005, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1880.43005, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1880.43005, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1882.55005, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1882.55005, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1882.55005, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1867.17004, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1865.96997, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1863.84998, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1863.84998, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1863.84998, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1863.84998, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1867.17004, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1867.17004, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1867.17004, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1865.96997, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1865.96997, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1635.06006, 1865.96997, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3578, 1647.38000, 1862.63000, 500.85001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1641.38000, 1862.63000, 500.20999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1640.18005, 1862.63000, 500.20999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1638.00000, 1862.63000, 500.20999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1653.42004, 1862.63000, 500.20999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1654.62000, 1862.63000, 500.20999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1656.76001, 1862.63000, 500.20999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1638.00000, 1862.63000, 500.45999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1640.18005, 1862.63000, 500.45999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1641.38000, 1862.63000, 500.45999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1654.62000, 1862.63000, 500.45999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1656.76001, 1862.63000, 500.45999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1653.42004, 1862.63000, 500.45999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1638.00000, 1862.63000, 500.70999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1640.18005, 1862.63000, 500.70999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1641.38000, 1862.63000, 500.70999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1653.42004, 1862.63000, 500.70999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1654.62000, 1862.63000, 500.70999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1656.76001, 1862.63000, 500.70999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1638.00000, 1862.63000, 500.95999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1640.18005, 1862.63000, 500.95999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1641.38000, 1862.63000, 500.95999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1653.42004, 1862.63000, 500.95999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1654.62000, 1862.63000, 500.95999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1656.76001, 1862.63000, 500.95999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(12957, 1649.93005, 1852.13000, 500.64001,   0.00000, 0.00000, 10.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(12957, 1650.18994, 1858.27002, 500.64001,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1645.66003, 1855.91003, 500.62000,   0.00000, 0.00000, 45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1646.21997, 1849.16003, 500.62000,   0.00000, 0.00000, -15.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(12957, 1643.48999, 1852.37000, 500.64001,   0.00000, 0.00000, -5.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2669, 1653.95996, 1846.58997, 501.42001,   0.00000, 0.00000, 255.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(852, 1641.07996, 1858.08997, 500.03000,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1638.92004, 1856.32996, 500.37000,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(18451, 1648.48999, 1842.12000, 500.56000,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1639.60999, 1854.54004, 500.14999,   0.00000, 0.00000, 300.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3577, 1655.59998, 1849.91003, 500.82999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1639.00000, 1852.59998, 500.35001,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1640.47998, 1851.03003, 500.19000,   0.00000, 0.00000, 240.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(851, 1638.96997, 1848.18994, 500.35001,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(849, 1655.67004, 1857.66003, 500.35999,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1653.89001, 1856.08997, 500.19000,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1655.82996, 1853.90002, 500.35001,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1648.79358, 1845.54761, 500.03000,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(854, 1648.98999, 1848.26001, 500.14001,   0.00000, 0.00000, 135.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1647.31995, 1857.94995, 500.20999,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(853, 1646.06006, 1859.54004, 500.29999,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2969, 1651.03003, 1858.40002, 500.63000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3016, 1650.47998, 1858.83997, 500.66000,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2359, 1651.27002, 1859.16003, 500.72000,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(322, 1651.12000, 1859.03003, 500.64001,   90.00000, 5.00000, 60.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2035, 1650.66003, 1859.56006, 500.53000,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3566, 1647.20996, 1820.90002, 501.79001,   0.00000, 90.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19362, 1639.27002, 1817.17505, 501.60001,   0.00000, 0.00000, 30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3578, 1640.09998, 1833.20996, 500.81000,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(851, 1639.10999, 1822.41003, 500.35001,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1645.58997, 1825.70996, 500.62000,   0.00000, 0.00000, -45.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(12957, 1645.22998, 1829.08997, 501.39999,   -15.00000, 10.00000, 25.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1639.47998, 1825.01001, 500.19000,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(851, 1655.13062, 1842.60718, 500.35999,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1654.48999, 1840.25000, 500.37000,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1655.43994, 1838.17004, 500.35001,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3800, 1653.45996, 1828.40002, 500.07001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3800, 1653.45996, 1829.76001, 500.07001,   0.00000, 0.00000, 10.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3800, 1654.60999, 1829.23999, 500.07001,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3800, 1653.84998, 1829.04004, 501.14999,   0.00000, 0.00000, -110.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1648.03003, 1834.75000, 500.62000,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(853, 1649.97998, 1832.56006, 500.45999,   0.00000, 0.00000, 135.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(851, 1649.87000, 1828.14001, 500.28000,   0.00000, 0.00000, 15.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1647.92004, 1830.53003, 500.23001,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2653, 1551.45996, 1843.19995, 504.67999,   0.00000, 90.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2653, 1543.56995, 1843.19995, 504.67999,   0.00000, 90.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2653, 1535.68005, 1843.19995, 504.67999,   0.00000, 90.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1643.96997, 1835.28003, 500.19000,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2674, 1646.03003, 1836.20996, 500.10999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1649.14001, 1838.35999, 500.32999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1644.67004, 1841.77002, 500.09000,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1644.18994, 1839.35999, 500.32999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(854, 1643.01001, 1837.09998, 500.29999,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2670, 1645.85999, 1837.66003, 500.14999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1654.55005, 1834.83997, 500.14999,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1655.95996, 1833.72998, 500.19000,   0.00000, 0.00000, -120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1639.46997, 1810.97998, 500.19000,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1640.46997, 1808.44995, 500.35001,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1638.67004, 1806.78003, 500.37000,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(852, 1640.82996, 1813.64001, 500.03000,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1650.66003, 1816.35999, 500.32999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1649.65002, 1818.52002, 500.32999,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1644.96008, 1814.69287, 500.19000,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(851, 1648.45007, 1815.73010, 500.17999,   0.00000, 0.00000, 15.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1647.70996, 1817.93994, 500.32999,   0.00000, 0.00000, 60.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1645.98999, 1816.90002, 500.32999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3594, 1651.10999, 1808.56006, 501.29999,   -5.00000, 20.00000, 30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(12957, 1645.25000, 1809.34998, 501.39999,   -5.00000, -10.00000, -5.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2669, 1653.96997, 1818.18005, 501.42001,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2678, 1651.99500, 1816.28003, 501.28500,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2679, 1653.31494, 1815.52002, 501.28500,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2680, 1652.55005, 1815.71997, 501.29999,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(849, 1656.10999, 1815.06995, 500.35001,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(853, 1655.80005, 1806.73999, 500.45001,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(852, 1654.28003, 1811.39001, 500.03000,   0.00000, 0.00000, -150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1654.41357, 1813.55872, 500.35001,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1655.97998, 1811.15002, 500.20999,   0.00000, 0.00000, 270.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2674, 1655.79004, 1808.81995, 500.10999,   0.00000, 0.00000, 270.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(851, 1644.15002, 1795.82996, 500.17999,   0.00000, 0.00000, 135.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1644.82996, 1793.96997, 500.19000,   0.00000, 0.00000, -30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1646.89001, 1793.01001, 500.32999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(850, 1639.83997, 1797.57996, 500.17999,   0.00000, 0.00000, 135.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(852, 1644.08997, 1788.95996, 499.88000,   0.00000, 0.00000, 135.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1644.02319, 1791.75293, 500.32999,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1646.05005, 1790.54004, 500.19000,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(852, 1648.25000, 1791.81006, 499.88000,   0.00000, 0.00000, -34.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1647.92004, 1789.05005, 500.32999,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1650.60999, 1789.89001, 500.03000,   0.00000, 0.00000, -90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(853, 1650.57996, 1794.28003, 500.31000,   0.00000, 0.00000, 30.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1640.52002, 1795.35999, 500.37000,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1639.55005, 1793.16003, 500.19000,   0.00000, 0.00000, 150.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1640.83997, 1791.06995, 500.35001,   0.00000, 0.00000, 120.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3798, 1640.12000, 1788.97998, 500.07001,   0.00000, 0.00000, 0.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1802.62000, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1801.40002, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1800.19995, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1799.00000, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1797.80005, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1796.59998, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1802.62000, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1802.62000, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1801.40002, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1800.19995, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1799.00000, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1797.80005, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1796.59998, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1796.59998, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1796.59998, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1797.80005, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1801.40002, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1801.40002, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1799.00000, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1800.19995, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1800.19995, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1797.80005, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1799.00000, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1789.95996, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72888, 1788.73999, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1787.56006, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1786.35999, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1785.16003, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1783.95996, 500.20999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1783.95996, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1783.95996, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1785.16003, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1786.35999, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1787.56006, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72888, 1788.73999, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1789.95996, 500.45999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1789.95996, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72888, 1788.73999, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1787.56006, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1785.16003, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1786.35999, 500.70999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1789.95996, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72888, 1788.73999, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1785.16003, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1786.35999, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2060, 1657.72998, 1787.56006, 500.95999,   0.00000, 0.00000, 90.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(925, 1660.03003, 1784.34497, 501.14999,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(931, 1662.48999, 1784.34497, 501.14999,   0.00000, 0.00000, 180.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(5772, 1530.58997, 1855.94995, 492.01501,   0.00000, 0.00000, -43.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19913, 1515.91492, 1835.71143, 467.26999,   0.00000, 90.00000, 47.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19913, 1548.65088, 1870.81628, 467.26999,   0.00000, 90.00000, 47.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19913, 1565.01880, 1888.36877, 467.26999,   0.00000, 90.00000, 47.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19913, 1499.54700, 1818.15894, 467.26999,   0.00000, 90.00000, 47.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2669, 1564.29163, 1881.43079, 487.35999,   0.00000, 0.00000, -43.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(920, 1566.25195, 1882.43323, 486.63000,   0.00000, 0.00000, -28.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(964, 1562.03040, 1882.56873, 486.01999,   0.00000, 0.00000, -128.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3576, 1569.95972, 1881.61450, 487.51001,   0.00000, 0.00000, 47.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2671, 1565.04358, 1886.23999, 486.03000,   0.00000, 0.00000, 2.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2905, 1569.62183, 1879.74194, 486.09000,   0.00000, 0.00000, 17.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2674, 1568.51465, 1879.22925, 486.03000,   0.00000, 0.00000, -88.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1563.80872, 1876.37305, 486.13000,   0.00000, 0.00000, -43.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3585, 1521.43127, 1848.13733, 486.57999,   0.00000, 0.00000, 47.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3630, 1568.99829, 1828.48645, 487.51859,   0.00000, 0.00000, -317.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2674, 1561.53503, 1878.31335, 486.03000,   0.00000, 0.00000, -88.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1558.91711, 1877.70544, 486.09000,   0.00000, 0.00000, -43.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1569.31091, 1833.18066, 486.31000,   0.00000, 0.00000, -272.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2671, 1506.12183, 1819.72571, 486.03000,   0.00000, 0.00000, 47.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1564.75195, 1831.89661, 486.29001,   0.00000, 0.00000, -137.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1557.37024, 1875.60657, 486.31000,   0.00000, 0.00000, 2.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1508.58582, 1817.85193, 486.13000,   0.00000, 0.00000, -43.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2907, 1510.13269, 1817.92700, 486.13000,   0.00000, 0.00000, -13.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2906, 1566.82800, 1832.58813, 486.13000,   180.00000, 90.00000, -107.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(931, 1560.49097, 1874.17322, 486.87000,   90.00000, 0.00000, 2.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2905, 1560.93774, 1875.56140, 486.17001,   0.00000, 90.00000, -43.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2978, 1551.78918, 1863.60999, 486.01001,   0.00000, 0.00000, -13.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3787, 1552.62622, 1865.37268, 486.57001,   0.00000, 0.00000, -48.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1553.62012, 1868.31531, 486.31000,   0.00000, 0.00000, 2.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1551.34949, 1868.29980, 486.29001,   0.00000, 0.00000, 107.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1540.52136, 1858.85803, 486.09000,   0.00000, 0.00000, 167.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2674, 1542.54590, 1861.05847, 486.03000,   0.00000, 0.00000, 2.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(918, 1542.99316, 1857.97510, 486.39001,   0.00000, 0.00000, -43.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19812, 1541.46460, 1860.61743, 486.53000,   0.00000, 0.00000, 17.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3057, 1538.70361, 1846.27832, 486.39001,   0.00000, 0.00000, -28.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2908, 1540.17737, 1846.42175, 486.09000,   0.00000, 0.00000, -13.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1538.82861, 1847.76135, 486.29001,   0.00000, 0.00000, 107.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3057, 1541.18933, 1850.26367, 486.39001,   0.00000, 0.00000, 17.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(18260, 1561.16614, 1834.77405, 487.59000,   0.00000, 0.00000, -317.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2045, 1512.37268, 1825.71045, 488.04999,   0.00000, 0.00000, -58.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2044, 1559.61279, 1834.46033, 488.04999,   0.00000, 0.00000, -272.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2043, 1511.63208, 1825.23889, 488.13000,   0.00000, 0.00000, 2.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2061, 1559.98755, 1834.45447, 488.31000,   0.00000, 0.00000, -332.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2064, 1510.33569, 1827.51428, 486.67001,   0.00000, 0.00000, 122.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1560.67615, 1836.44336, 486.31000,   0.00000, 0.00000, -272.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1513.14063, 1820.53687, 486.13000,   0.00000, 0.00000, -43.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1562.65076, 1837.17029, 486.29001,   0.00000, 0.00000, -137.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1512.00378, 1817.83679, 486.29001,   0.00000, 0.00000, 137.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2671, 1564.91199, 1833.81079, 486.03000,   0.00000, 0.00000, -317.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(925, 1507.64685, 1823.86853, 487.09000,   0.00000, 0.00000, -43.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19918, 1548.79871, 1851.67151, 486.45761,   0.00000, 0.00000, -157.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2827, 1527.00452, 1836.85571, 486.47000,   0.00000, 0.00000, 47.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19626, 1549.67041, 1850.01965, 486.95999,   110.00000, 0.00000, -47.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2907, 1526.54102, 1835.94800, 486.76999,   -90.00000, 0.00000, 47.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2905, 1549.70813, 1850.49231, 486.59000,   0.00000, 90.00000, -257.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2908, 1526.52515, 1835.98999, 487.32999,   -90.00000, 0.00000, -43.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2906, 1550.27039, 1850.18274, 486.48999,   0.00000, 0.00000, -227.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1525.24280, 1835.43567, 486.31000,   0.00000, 0.00000, 2.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1549.18372, 1850.26306, 486.29001,   0.00000, 0.00000, -137.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2676, 1528.47168, 1838.60498, 486.13000,   0.00000, 0.00000, -43.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1547.40906, 1850.09851, 486.31000,   0.00000, 0.00000, -272.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(964, 1527.46179, 1835.30798, 486.01001,   0.00000, 0.00000, -43.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19812, 1549.63037, 1852.11536, 486.53000,   0.00000, 0.00000, -197.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2042, 1527.51770, 1835.73450, 487.03000,   0.00000, 0.00000, -43.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2036, 1551.17651, 1851.41040, 486.98999,   0.00000, 0.00000, -287.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(964, 1517.36292, 1822.41064, 486.01801,   0.00000, 0.00000, -58.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(918, 1562.54980, 1839.14075, 486.39001,   0.00000, 0.00000, -317.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2040, 1517.40283, 1822.27759, 487.07999,   0.00000, 0.00000, 17.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2035, 1562.66528, 1840.42444, 487.00000,   0.00000, 0.00000, -467.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19913, 1507.73096, 1826.93518, 467.26999,   0.00000, 90.00000, -313.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19913, 1524.09888, 1844.48767, 467.26999,   0.00000, 90.00000, -313.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19913, 1540.46680, 1862.04004, 467.26999,   0.00000, 90.00000, -313.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19913, 1556.83484, 1879.59253, 467.26999,   0.00000, 90.00000, -313.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19913, 1568.94031, 1892.57410, 467.26999,   0.00000, 90.00000, -313.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19913, 1496.48474, 1814.87512, 467.26999,   0.00000, 90.00000, -313.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(930, 1565.19727, 1883.66284, 486.63000,   0.00000, 0.00000, -403.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(964, 1561.17151, 1881.42798, 486.01999,   0.00000, 0.00000, -403.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(964, 1561.53931, 1882.04224, 486.95999,   0.00000, 0.00000, -508.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2670, 1564.30627, 1881.41724, 486.22000,   0.00000, 0.00000, -313.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1567.39832, 1884.45435, 486.31000,   0.00000, 0.00000, -358.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2673, 1566.79236, 1879.31763, 486.10999,   0.00000, 0.00000, -358.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2674, 1492.66528, 1832.67078, 486.03000,   0.00000, 0.00000, -268.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1566.46191, 1877.23303, 486.09000,   0.00000, 0.00000, -403.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1560.19946, 1879.88696, 486.29001,   0.00000, 0.00000, -403.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3630, 1505.87256, 1815.71948, 487.51859,   0.00000, 0.00000, -403.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2670, 1558.66101, 1879.36621, 486.10001,   0.00000, 0.00000, -433.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1510.57715, 1815.73511, 486.31000,   0.00000, 0.00000, -358.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1508.97815, 1820.19336, 486.29001,   0.00000, 0.00000, -223.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2671, 1555.92224, 1877.76367, 486.03000,   0.00000, 0.00000, -313.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1560.10352, 1876.35303, 486.29001,   0.00000, 0.00000, -223.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2906, 1509.81287, 1818.17065, 486.13000,   180.00000, 90.00000, -193.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2907, 1560.46021, 1875.25464, 486.57001,   -90.00000, 0.00000, -358.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2908, 1560.13416, 1875.47668, 486.09000,   0.00000, 0.00000, -493.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2977, 1551.78918, 1863.60999, 486.01001,   0.00000, 0.00000, -373.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(1218, 1551.63281, 1864.84985, 486.48999,   0.00000, 0.00000, -403.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1550.73523, 1866.43872, 486.09000,   0.00000, 0.00000, -193.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2674, 1553.05481, 1866.06689, 486.03000,   0.00000, 0.00000, -358.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1543.04980, 1858.98889, 486.29001,   0.00000, 0.00000, -253.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1541.67859, 1857.32776, 486.31000,   0.00000, 0.00000, -358.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19812, 1540.72156, 1860.21643, 486.53000,   0.00000, 0.00000, -403.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(3057, 1539.35449, 1845.67126, 486.39001,   0.00000, 0.00000, -403.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(1218, 1539.69214, 1846.94250, 486.47000,   0.00000, 0.00000, -403.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1541.08093, 1848.50513, 486.31000,   0.00000, 0.00000, -358.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2675, 1540.27271, 1850.29810, 486.09000,   0.00000, 0.00000, -193.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(18260, 1511.59851, 1823.97119, 487.59000,   0.00000, 0.00000, -403.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2044, 1511.17725, 1825.49878, 488.04999,   0.00000, 0.00000, -358.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2061, 1511.19739, 1825.12463, 488.31000,   0.00000, 0.00000, -418.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1513.22949, 1824.57654, 486.31000,   0.00000, 0.00000, -358.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1514.09241, 1822.65735, 486.29001,   0.00000, 0.00000, -223.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2671, 1510.89893, 1820.16724, 486.03000,   0.00000, 0.00000, -403.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19918, 1527.59216, 1837.48718, 486.45761,   0.00000, 0.00000, -243.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19626, 1526.00500, 1836.50244, 486.95999,   110.00000, 0.00000, -133.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2905, 1526.47925, 1836.49780, 486.59000,   0.00000, 90.00000, -343.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2908, 1534.65479, 1875.91003, 487.32999,   -90.00000, 0.00000, -223.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2906, 1526.20959, 1835.91528, 486.48999,   0.00000, 0.00000, -313.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2677, 1526.21399, 1837.00488, 486.29001,   0.00000, 0.00000, -223.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2672, 1525.92603, 1838.76367, 486.31000,   0.00000, 0.00000, -358.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(19812, 1528.09290, 1836.68848, 486.53000,   0.00000, 0.00000, -283.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2036, 1527.49756, 1835.09692, 486.98999,   0.00000, 0.00000, -373.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(918, 1516.05115, 1822.89551, 486.39001,   0.00000, 0.00000, -403.00000);
	rTDM_Objects[rTDM_CountObjects++] = CreateObject(2035, 1517.33972, 1822.86975, 487.00000,   0.00000, 0.00000, -553.00000);
	rTDM_CountObjects = 0;
	return 1;
}
