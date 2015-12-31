#include <sourcemod>
#include <sdktools>
#define PL_VERSION "1.3"

public Plugin:myinfo =
{
	name        = "[CS] Extra Spawn Points [ESP]",
	author      = "Roy (Christian Deacon)",
	description = "Enforces a minimum amount of spawns for each team.",
	version     = PL_VERSION,
	url         = "GFLClan.com & AlliedMods.net & TheDevelopingCommunity.com"
};

// ConVars
new Handle:g_hTSpawns = INVALID_HANDLE;
new Handle:g_hCTSpawns = INVALID_HANDLE;
new Handle:g_hTeams = INVALID_HANDLE;
new Handle:g_hCourse = INVALID_HANDLE;
new Handle:g_hDebug = INVALID_HANDLE;
new Handle:g_hAuto = INVALID_HANDLE;
new Handle:g_hMapStartDelay = INVALID_HANDLE;


// ConVar Values
new g_icvarTSpawns;
new g_icvarCTSpawns;
new g_icvarTeams;
new bool:g_bcvarCourse;
new bool:g_bcvarDebug;
new bool:g_bcvarAuto;
new Float:g_fcvarMapStartDelay;

// Other
new bool:g_bMapStart;

public OnPluginStart()
{
	// ConVars
	g_hTSpawns = CreateConVar("sm_ESP_spawns_t", "32", "Amount of spawn points to enforce on the T team.");
	g_hCTSpawns = CreateConVar("sm_ESP_spawns_ct", "32", "Amount of spawn points to enforce on the CT team.");
	g_hTeams = CreateConVar("sm_ESP_teams", "1", "0 = Disabled, 1 = All Teams, 2 = Terrorist only, 3 = Counter-Terrorist only.");
	g_hCourse = CreateConVar("sm_ESP_course", "1", "1 = When T or CT spawns are at 0, the opposite team will get double the spawn points.");
	g_hDebug = CreateConVar("sm_ESP_debug", "0", "1 = Enable debugging.");
	g_hAuto = CreateConVar("sm_ESP_auto", "0", "1 = Add the spawn points as soon as a ConVar is changed.");
	g_hMapStartDelay = CreateConVar("sm_ESP_mapstart_delay", "1.0", "The delay of the timer on map start to add in spawn points.");
	
	// AlliedMods Release
	CreateConVar("sm_ESP_version", PL_VERSION, "Extra Spawn Points version.");
	
	// Hook ConVar Changes
	HookConVarChange(g_hTSpawns, CVarChanged);
	HookConVarChange(g_hCTSpawns, CVarChanged);
	HookConVarChange(g_hTeams, CVarChanged);
	HookConVarChange(g_hCourse, CVarChanged);
	HookConVarChange(g_hDebug, CVarChanged);
	HookConVarChange(g_hAuto, CVarChanged);
	HookConVarChange(g_hMapStartDelay, CVarChanged);
	
	// Get ConVar Values.
	GetValues();
	g_bMapStart = false;
	
	// Commands
	RegAdminCmd("sm_addspawns", Command_AddSpawns, ADMFLAG_ROOT);
	
	// Automatically Execute Config
	AutoExecConfig(true, "sm_ExtraSpawnPoints");
}

public Action:Command_AddSpawns(iClient, sArgs) 
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

public CVarChanged(Handle:hCVar, const String:sOldV[], const String:sNewV[])
{
	OnConfigsExecuted();
}

public OnConfigsExecuted() 
{
	GetValues();
	
	if (!g_bMapStart) 
	{
		if (g_fcvarMapStartDelay > 0.0) 
		{
			CreateTimer(g_fcvarMapStartDelay, timer_DelayAddSpawnPoints);
		}
		g_bMapStart = true;
	}
	
	if (g_bcvarAuto && g_bMapStart) 
	{
		AddMapSpawns();
	}
}

public Action:timer_DelayAddSpawnPoints(Handle:hTimer) 
{
	AddMapSpawns();
}

stock GetValues() 
{
	g_icvarTSpawns = GetConVarInt(g_hTSpawns);
	g_icvarCTSpawns = GetConVarInt(g_hCTSpawns);
	g_icvarTeams = GetConVarInt(g_hTeams);
	g_bcvarCourse = GetConVarBool(g_hCourse);
	g_bcvarDebug = GetConVarBool(g_hDebug);
	g_bcvarAuto = GetConVarBool(g_hAuto);
	g_fcvarMapStartDelay = GetConVarFloat(g_hMapStartDelay);
}

stock AddMapSpawns() 
{
	new iTSpawns = 0;
	new iCTSpawns = 0;
	
	new idTSpawns = 0;
	new idCTSpawns = 0;
	
	new Float:fVecCt[3];
	new Float:fVecT[3];
	new Float:angVec[3];
	decl String:sClassName[64];
	
	for (new i = MaxClients; i < GetMaxEntities(); i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i) && GetEdictClassname(i, sClassName, sizeof(sClassName)))
		{
			if (StrEqual(sClassName, "info_player_terrorist"))
			{
				iTSpawns++;
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", fVecT);
			}
			else if (StrEqual(sClassName, "info_player_counterterrorist"))
			{
				iCTSpawns++;
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", fVecCt);
			}
		}
	}
	
	if (g_bcvarDebug) 
	{
		LogMessage("[ESP]There are %d/%d CT points and %d/%d T points", iCTSpawns, g_icvarCTSpawns, iTSpawns, g_icvarTSpawns);
	}
	
	if (g_bcvarCourse) 
	{
		if (iCTSpawns == 0 && iTSpawns > 0) 
		{
			g_icvarTSpawns *= 2;
		}
		
		if (iTSpawns == 0 && iCTSpawns > 0) 
		{
			g_icvarCTSpawns *= 2;
		}
	}
	
	if(iCTSpawns && iCTSpawns < g_icvarCTSpawns && iCTSpawns > 0)
	{
		if (g_icvarTeams == 1 || g_icvarTeams == 3) 
		{
			for(new i = iCTSpawns; i < g_icvarCTSpawns; i++)
			{
				new iEnt = CreateEntityByName("info_player_counterterrorist");
				if (DispatchSpawn(iEnt))
				{
					TeleportEntity(iEnt, fVecCt, angVec, NULL_VECTOR);
					if (g_bcvarDebug) 
					{
						LogMessage("[ESP]+1 CT spawn added!");
					}
				}
			}
		}
	}
	
	if(iTSpawns && iTSpawns < g_icvarTSpawns && iTSpawns > 0)
	{
		if (g_icvarTeams == 1 || g_icvarTeams == 2) 
		{
			for(new i = iTSpawns; i < g_icvarTSpawns; i++)
			{
				new iEnt = CreateEntityByName("info_player_terrorist");
				if (DispatchSpawn(iEnt))
				{
					TeleportEntity(iEnt, fVecT, angVec, NULL_VECTOR);
					if (g_bcvarDebug) 
					{
						LogMessage("[ESP]+1 T spawn added!");
					}
				}
			}
		}
	}
	if (g_bcvarDebug) 
	{
		for (new i = MaxClients; i < GetMaxEntities(); i++)
		{
			if (IsValidEdict(i) && IsValidEntity(i) && GetEdictClassname(i, sClassName, sizeof(sClassName)))
			{
				if (StrEqual(sClassName, "info_player_terrorist"))
				{
					idTSpawns++;
				}
				else if (StrEqual(sClassName, "info_player_counterterrorist"))
				{
					idCTSpawns++;
				}
			}
		}
		LogMessage("[ESP]There are now %d CT spawns and %d T spawns", idCTSpawns, idTSpawns);
	}
}