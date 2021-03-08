#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.3"
#define MAXSPAWNS 256

public Plugin myinfo =
{
	name        = "Extra Spawn Points",
	author      = "Christian Deacon (gamemann)",
	description = "Enforces a minimum amount of spawns for each team.",
	version     = PL_VERSION,
	url         = "GFLClan.com & AlliedMods.net"
};

/* ConVars */
ConVar g_cvTSpawns = null;
ConVar g_cvCTSpawns = null;
ConVar g_cvTeams = null;
ConVar g_cvCourse = null;
ConVar g_cvDebug = null;
ConVar g_cvAuto = null;
ConVar g_cvMapStartDelay = null;
ConVar g_cvMoveZAxis = null;

/* Other */
bool g_bMapStart;

public void OnPluginStart()
{
	/* ConVars */
	g_cvTSpawns = CreateConVar("sm_ESP_spawns_t", "32", "Amount of spawn points to enforce on the T team.");
	g_cvCTSpawns = CreateConVar("sm_ESP_spawns_ct", "32", "Amount of spawn points to enforce on the CT team.");
	g_cvTeams = CreateConVar("sm_ESP_teams", "1", "0 = Disabled, 1 = All Teams, 2 = Terrorist only, 3 = Counter-Terrorist only.");
	g_cvCourse = CreateConVar("sm_ESP_course", "1", "1 = When T or CT spawns are at 0, the opposite team will get double the spawn points.");
	g_cvDebug = CreateConVar("sm_ESP_debug", "0", "1 = Enable debugging.");
	g_cvAuto = CreateConVar("sm_ESP_auto", "0", "1 = Add the spawn points as soon as a ConVar is changed.");
	g_cvMapStartDelay = CreateConVar("sm_ESP_mapstart_delay", "1.0", "The delay of the timer on map start to add in spawn points.");
	g_cvMoveZAxis = CreateConVar("sm_ESP_zaxis", "16.0", "Increase Z axis by this amount when spawning a spawn point. This may resolve some issues.");
	
	/* AlliedMods Release ConVar (required). */
	CreateConVar("sm_ESP_version", PL_VERSION, "Extra Spawn Points version.");
	
	/* Commands. */
	RegAdminCmd("sm_addspawns", Command_AddSpawns, ADMFLAG_ROOT);
	RegAdminCmd("sm_getspawncount", Command_GetSpawnCount, ADMFLAG_SLAY);
	RegAdminCmd("sm_listspawns", Command_ListSpawns, ADMFLAG_SLAY);
	
	/* Automatically Execute Config. */
	AutoExecConfig(true, "plugin.ESP");
}

public void OnMapStart()
{
	/* Set Map Start bool. This is executed BEFORE OnConfigsExecuted() via https://sm.alliedmods.net/new-api/sourcemod/OnConfigsExecuted so it should be fine. */
	g_bMapStart = false;
}

public Action Command_AddSpawns(int iClient, int iArgs) 
{
	AddMapSpawns();
	
	if (iClient == 0) 
	{
		PrintToServer("[ESP] Added map spawns!");
	} 
	else 
	{
		PrintToChat(iClient, "\x02[ESP] \x03Added map spawns!");
	}
	
	return Plugin_Handled;
}

public Action Command_GetSpawnCount(int iClient, int iArgs)
{
	int idTSpawns = getTeamCount(2);
	int idCTSpawns = getTeamCount(3);
	
	ReplyToCommand(iClient, "[ESP]There are now %d CT spawns and %d T spawns", idCTSpawns, idTSpawns);
	
	return Plugin_Handled;
}

public Action Command_ListSpawns(int iClient, int iArgs)
{
	float fVec[3];
	float fAng[3];

	int i = 1;
	int iEnt = -1;

	PrintToConsole(iClient, "Listing T spawns...");

	while ((iEnt = FindEntityByClassname(iEnt, "info_player_terrorist")) != -1)
	{
		GetEntPropVector(iEnt, Prop_Data, "m_vecOrigin", fVec);
		GetEntPropVector(iEnt, Prop_Data, "m_angRotation", fAng);

		PrintToConsole(iClient, "T Spawn #%d - Vector => %f, %f, %f. Angle => %f, %f, %f.", i, fVec[0], fVec[1], fVec[2], fAng[0], fAng[1], fAng[2]);

		i++;
	}

	i = 1;

	PrintToConsole(iClient, "Listing CT spawns...");

	while  ((iEnt = FindEntityByClassname(iEnt, "info_player_counterterrorist")) != -1)
	{
		GetEntPropVector(iEnt, Prop_Data, "m_vecOrigin", fVec);
		GetEntPropVector(iEnt, Prop_Data, "m_angRotation", fAng);

		PrintToConsole(iClient, "CT Spawn #%d - Vector => %f, %f, %f. Angle => %f, %f, %f.", i, fVec[0], fVec[1], fVec[2], fAng[0], fAng[1], fAng[2]);

		i++;
	}

	return Plugin_Handled;
}

public void OnConfigsExecuted() 
{	
	if (!g_bMapStart) 
	{
		CreateTimer(g_cvMapStartDelay.FloatValue, timer_DelayAddSpawnPoints);

		g_bMapStart = true;
	}
	
	if (g_cvAuto.BoolValue && g_bMapStart) 
	{
		AddMapSpawns();
	}
}

public Action timer_DelayAddSpawnPoints(Handle hTimer) 
{
	AddMapSpawns();
}

stock void AddMapSpawns() 
{
	int iTSpawns = 0;
	int iCTSpawns = 0;
	
	int iToSpawnT = g_cvTSpawns.IntValue;
	int iToSpawnCT = g_cvCTSpawns.IntValue;
	
	float fVecCT[MAXSPAWNS][3];
	float fVecT[MAXSPAWNS][3];

	float fAngT[MAXSPAWNS][3];
	float fAngCT[MAXSPAWNS][3];
	
	int iSpawnEnt = -1;
	
	/* Receive all the T Spawns. */
	while ((iSpawnEnt = FindEntityByClassname(iSpawnEnt, "info_player_terrorist")) != -1)
	{
		GetEntPropVector(iSpawnEnt, Prop_Data, "m_vecOrigin", fVecT[iTSpawns]);
		GetEntPropVector(iSpawnEnt, Prop_Data, "m_angRotation", fAngT[iTSpawns]);

		if (g_cvMoveZAxis.FloatValue > 0.0)
		{
			fVecT[iTSpawns][2] += g_cvMoveZAxis.FloatValue;
		}

		iTSpawns++;
	}	
	
	/* Receive all the CT Spawns. */
	while ((iSpawnEnt = FindEntityByClassname(iSpawnEnt, "info_player_counterterrorist")) != -1)
	{
		GetEntPropVector(iSpawnEnt, Prop_Data, "m_vecOrigin", fVecCT[iCTSpawns]);
		GetEntPropVector(iSpawnEnt, Prop_Data, "m_angRotation", fAngCT[iCTSpawns]);

		if (g_cvMoveZAxis.FloatValue > 0.0)
		{
			fVecCT[iCTSpawns][2] += g_cvMoveZAxis.FloatValue;
		}

		iCTSpawns++;
	}
	
	/* Double the spawn count if Course Mode is enabled along with the amount of spawn points being above 0. */
	if (g_cvCourse.BoolValue) 
	{
		if (iCTSpawns == 0 && iTSpawns > 0) 
		{
			iToSpawnT *= 2;
		}
		
		if (iTSpawns == 0 && iCTSpawns > 0) 
		{
			iToSpawnCT *= 2;
		}
	}
	
	/* Debugging message. */
	if (g_cvDebug.BoolValue) 
	{
		LogMessage("[ESP]There are %d/%d CT points and %d/%d T points", iCTSpawns, iToSpawnCT, iTSpawns, iToSpawnT);
	}
	
	/* Add the CT spawn points. */
	if (g_cvTeams.IntValue == 1 || g_cvTeams.IntValue == 3) 
	{
		for(int i = iCTSpawns; i < iToSpawnCT; i++)
		{
			int iEnt = CreateEntityByName("info_player_counterterrorist");
			
			if (iEnt != -1 && DispatchSpawn(iEnt))
			{
				int iRandSpawn = GetRandomInt(0, (iCTSpawns - 1));

				TeleportEntity(iEnt, fVecCT[iRandSpawn], fAngCT[iRandSpawn], NULL_VECTOR);
				
				if (g_cvDebug.BoolValue) 
				{
					LogMessage("[ESP]+1 CT spawn added!");
				}
			}
		}
	}
	
	/* Add the T spawn points. */
	if (g_cvTeams.IntValue == 1 || g_cvTeams.IntValue == 2) 
	{
		for(int i = iTSpawns; i < iToSpawnT; i++)
		{
			int iEnt = CreateEntityByName("info_player_terrorist");
			
			if (iEnt != -1 && DispatchSpawn(iEnt))
			{
				int iRandSpawn = GetRandomInt(0, (iTSpawns - 1));

				TeleportEntity(iEnt, fVecT[iRandSpawn], fAngT[iRandSpawn], NULL_VECTOR);
				
				if (g_cvDebug.BoolValue) 
				{
					LogMessage("[ESP]+1 T spawn added!");
				}
			}
		}
	}
	
	/* Finally, enter one last debug message. */
	if (g_cvDebug.BoolValue) 
	{
		int idTSpawns = getTeamCount(2);
		int idCTSpawns = getTeamCount(3);
		
		LogMessage("[ESP]There are now %d CT spawns and %d T spawns", idCTSpawns, idTSpawns);
	}
}

/* Gets the spawn count for a specific team (e.g. CT and T). */
stock int getTeamCount(int iTeam)
{
	int iAmount = 0;
	int iEnt;
	
	/* Receive all the T Spawns. */
	if (iTeam == 2)
	{
		while ((iEnt = FindEntityByClassname(iEnt, "info_player_terrorist")) != -1)
		{
			iAmount++;
		}
	}
	
	/* Receive all the CT Spawns. */
	if (iTeam == 3)
	{
		while ((iEnt = FindEntityByClassname(iEnt, "info_player_counterterrorist")) != -1)
		{
			iAmount++;
		}
	}
	
	return iAmount;
}