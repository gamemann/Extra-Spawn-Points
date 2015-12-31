#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.0"
#define MAXENTITIES 2048

public Plugin myinfo =
{
	name        = "Extra Spawn Points (stable)",
	author      = "Roy (Christian Deacon)",
	description = "Enforces a minimum amount of spawns for each team.",
	version     = PL_VERSION,
	url         = "GFLClan.com & AlliedMods.net & TheDevelopingCommunity.com"
};

// ConVars
Handle g_hTSpawns = INVALID_HANDLE;
Handle g_hCTSpawns = INVALID_HANDLE;
Handle g_hTeams = INVALID_HANDLE;
Handle g_hCourse = INVALID_HANDLE;
Handle g_hDebug = INVALID_HANDLE;
Handle g_hAuto = INVALID_HANDLE;
Handle g_hMapStartDelay = INVALID_HANDLE;


// ConVar Values
int g_icvarTSpawns;
int g_icvarCTSpawns;
int g_icvarTeams;
bool g_bcvarCourse;
bool g_bcvarDebug;
bool g_bcvarAuto;
float g_fcvarMapStartDelay;

// Other
bool g_bMapStart;

public void OnPluginStart()
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
	RegAdminCmd("sm_getspawncount", Command_GetSpawnCount, ADMFLAG_SLAY);
	
	// Automatically Execute Config
	AutoExecConfig(true, "plugin.ESP");
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

public void CVarChanged(Handle hCVar, const char[] sOldV, const char[] sNewV)
{
	OnConfigsExecuted();
}

public void OnConfigsExecuted() 
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

public Action timer_DelayAddSpawnPoints(Handle hTimer) 
{
	AddMapSpawns();
}

stock void GetValues() 
{
	g_icvarTSpawns = GetConVarInt(g_hTSpawns);
	g_icvarCTSpawns = GetConVarInt(g_hCTSpawns);
	g_icvarTeams = GetConVarInt(g_hTeams);
	g_bcvarCourse = GetConVarBool(g_hCourse);
	g_bcvarDebug = GetConVarBool(g_hDebug);
	g_bcvarAuto = GetConVarBool(g_hAuto);
	g_fcvarMapStartDelay = GetConVarFloat(g_hMapStartDelay);
}

stock void AddMapSpawns() 
{
	int iTSpawns = 0;
	int iCTSpawns = 0;
	
	int iToSpawnT = g_icvarTSpawns;
	int iToSpawnCT = g_icvarCTSpawns;
	
	float fVecCt[3];
	float fVecT[3];
	float angVec[3];
	
	char sClassName[MAX_NAME_LENGTH];
	
	for (int i = MaxClients; i <= MAXENTITIES; i++)
	{
		if (!IsValidEdict(i) || !IsValidEntity(i))
		{
			continue;
		}
		
		GetEdictClassname(i, sClassName, sizeof(sClassName));
		
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
	
	if (g_bcvarCourse) 
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
	
	if (g_bcvarDebug) 
	{
		LogMessage("[ESP]There are %d/%d CT points and %d/%d T points", iCTSpawns, iToSpawnCT, iTSpawns, iToSpawnT);
	}
	
	if(iCTSpawns && iCTSpawns < iToSpawnCT && iCTSpawns > 0)
	{
		if (g_icvarTeams == 1 || g_icvarTeams == 3) 
		{
			for(int i = iCTSpawns; i < iToSpawnCT; i++)
			{
				int iEnt = CreateEntityByName("info_player_counterterrorist");
				
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
	
	if(iTSpawns && iTSpawns < iToSpawnT && iTSpawns > 0)
	{
		if (g_icvarTeams == 1 || g_icvarTeams == 2) 
		{
			for(int i = iTSpawns; i < iToSpawnT; i++)
			{
				int iEnt = CreateEntityByName("info_player_terrorist");
				
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
		int idTSpawns = getTeamCount(2);
		int idCTSpawns = getTeamCount(3);
		
		LogMessage("[ESP]There are now %d CT spawns and %d T spawns", idCTSpawns, idTSpawns);
	}
}

stock int getTeamCount(int iTeam)
{
	int iAmount = 0;
	
	for (int i = MaxClients; i <= MAXENTITIES; i++)
	{
		if (!IsValidEdict(i) || !IsValidEntity(i))
		{
			continue;
		}
		
		char sClassName[MAX_NAME_LENGTH];
		GetEdictClassname(i, sClassName, sizeof(sClassName));
		
		if (StrEqual(sClassName, "info_player_counterterrorist") && iTeam == 3)
		{
			iAmount++;
		}
		else if (StrEqual(sClassName, "info_player_terrorist") && iTeam == 2)
		{
			iAmount++;
		}
	}
	
	return iAmount;
}