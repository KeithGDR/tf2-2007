//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define PLUGIN_VERSION "1.0.7"
#define PLUGIN_DESCRIPTION "Simulates TF2 from 2007."

//Sourcemod Includes
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>

//ConVars
ConVar convar_Status;
ConVar convar_SetMapcycle;
ConVar convar_SetConVars;
ConVar convar_RemoveWearables;
ConVar convar_RemoveWeapons;
ConVar convar_DisableTaunts;
ConVar convar_DisableMoveBuildings;
ConVar convar_DisableAirblasts;
ConVar convar_ModifiedDamage;
ConVar convar_DisableDroppedWeapons;
ConVar convar_DisableGlows;
ConVar convar_FixedMedicSpeed;
ConVar convar_FixedRagdolls;
ConVar convar_BuildingLevels;
ConVar convar_LegacyPistol;
ConVar convar_UberOnActiveOnly;
ConVar convar_GodPipes;
ConVar convar_DisableTauntKills;
ConVar convar_DisableInspection;
ConVar convar_LowerWeaponSwitching;

//Globals
float g_Uber[MAXPLAYERS + 1];

enum
{
	OBJ_DISPENSER,
	OBJ_TELEPORTER,
	OBJ_SENTRY
}

Handle g_hSDKStartBuilding;

public Plugin myinfo = 
{
	name = "TF2007 Project", 
	author = "Keith Warren (Drixevel)", 
	description = "Simulates TF2 from 2007.", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/drixevel"
};

public void OnPluginStart()
{
	CreateConVar("sm_tf2007_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_DONTRECORD);
	convar_Status = CreateConVar("sm_tf2007_status", "1", "Status of this plugin.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_SetMapcycle = CreateConVar("sm_tf2007_set_mapcycle", "0", "Status of this plugin.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_SetConVars = CreateConVar("sm_tf2007_set_convars", "1", "Set proper console variables.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_RemoveWearables = CreateConVar("sm_tf2007_set_removewearables", "1", "Disable all wearables.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_RemoveWeapons = CreateConVar("sm_tf2007_set_removeweapons", "1", "Disable all non-stock weapons.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_DisableTaunts = CreateConVar("sm_tf2007_disable_taunts", "1", "Disables every taunt BUT default ones.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_DisableMoveBuildings = CreateConVar("sm_tf2007_disable_movebuildings", "1", "Disables moving buildings around for Engineers.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_DisableAirblasts = CreateConVar("sm_tf2007_disable_airblasts", "1", "Disables airblast for Pyro.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_ModifiedDamage = CreateConVar("sm_tf2007_modified_damage", "1", "Modify damage calculations for weapons.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_DisableDroppedWeapons = CreateConVar("sm_tf2007_disable_droppedweapons", "1", "Delete dropped weapons on creation.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_DisableGlows = CreateConVar("sm_tf2007_disable_glows", "1", "Disable glows on all entities.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_FixedMedicSpeed = CreateConVar("sm_tf2007_fixed_medic_speed", "1", "Prevents Medics from speeding up while healing Scouts.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_FixedRagdolls = CreateConVar("sm_tf2007_fixed_ragdolls", "1", "Fix ragdolls such as Spy backstabbing animations.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_BuildingLevels = CreateConVar("sm_tf2007_building_levels", "1", "Automatically sets the default building levels for Dispensers and Teleporters making them nonupgradable.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_LegacyPistol = CreateConVar("sm_tf2007_legacy_pistol", "1", "Lower the fire rate for pistols and allow for manual faster firing.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_UberOnActiveOnly = CreateConVar("sm_tf2007_uber_on_active_only", "1", "Ubercharge only depletes if you have your secondary active.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_GodPipes = CreateConVar("sm_tf2007_indestructable_pipes", "1", "Whether pipe bombs can take damage when shot.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_DisableTauntKills = CreateConVar("sm_tf2007_disable_taunt_kills", "1", "Disable taunt kills.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_DisableInspection = CreateConVar("sm_tf2007_disable_inspection", "1", "Disable player weapon inspections.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_LowerWeaponSwitching = CreateConVar("sm_tf2007_lower_weapon_switching", "1", "Lower the amount of time it takes to switch between weapons.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AutoExecConfig();
	
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("post_inventory_application", Event_OnResupply);

	AddCommandListener(OnTaunt, "taunt");
	AddCommandListener(OnTaunt, "+taunt");

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			OnClientPutInServer(i);

	int entity = -1; char classname[32];
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		GetEntityClassname(entity, classname, sizeof(classname));
		OnEntityCreated(entity, classname);
	}

	FindConVar("tf_cheapobjects").SetInt(1);
	HookEvent("player_builtobject", Event_OnObjectBuild);
	
	char sFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "gamedata/buildings.txt");
	
	if (FileExists(sFilePath))
	{
		Handle hGameConf = LoadGameConfigFile("buildings");
		
		if (hGameConf != null)
		{
			StartPrepSDKCall(SDKCall_Entity);
			PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseObject::StartBuilding");
			g_hSDKStartBuilding = EndPrepSDKCall();
			
			delete hGameConf;
		}
	}
}

public void OnConfigsExecuted()
{
	if (!convar_Status.BoolValue)
		return;
	
	if (convar_SetMapcycle.BoolValue)
	{
		char sPath[PLATFORM_MAX_PATH];
		strcopy(sPath, sizeof(sPath), "cfg/mapcycle.txt");

		Handle file = OpenFile(sPath, "w");

		WriteFileLine(file, "ctf_2fort");
		WriteFileLine(file, "cp_granary");
		WriteFileLine(file, "cp_well");
		WriteFileLine(file, "cp_dustbowl");
		WriteFileLine(file, "cp_gravelpit");
		WriteFileLine(file, "tc_hydro");

		delete file;
	}
	
	if (convar_SetConVars.BoolValue)
	{
		FindConVar("tf_allow_sliding_taunt").SetBool(true, true, true);
		FindConVar("tf_allow_taunt_switch").SetBool(true, true, true);
		FindConVar("sv_allow_votes").SetBool(false, true, true);
	}
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!convar_Status.BoolValue)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	UpdatePlayerItems(client);
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!convar_Status.BoolValue)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client == 0)
		return;
	
	if (convar_FixedRagdolls.BoolValue && event.GetInt("customkill") == TF_CUSTOM_BACKSTAB)
		RequestFrame(Frame_Ragdoll, GetClientUserId(client));
}

public void Frame_Ragdoll(any data)
{
	int client = GetClientOfUserId(data);

	if (client == 0 || !IsClientInGame(client) || IsPlayerAlive(client))
		return;
	
	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (!IsValidEdict(ragdoll))
		return;
	
	char classname[64];
	GetEdictClassname(ragdoll, classname, sizeof(classname));

	if (!StrEqual(classname, "tf_ragdoll", false))
		return;
	
	float vel[3];
	GetEntPropVector(ragdoll, Prop_Send, "m_vecForce", vel);

	RemoveEdict(ragdoll);
	TF2_SpawnRagdoll(client, 0.0, 0, vel);
}

public void Event_OnResupply(Event event, const char[] name, bool dontBroadcast)
{
	if (!convar_Status.BoolValue)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	UpdatePlayerItems(client);

	int primary = GetPlayerWeaponSlot(client, 0);

	if (IsValidEntity(primary))
		EquipWeapon(client, primary);
}

void EquipWeapon(int client, int weapon)
{
	char class[64];
	GetEntityClassname(weapon, class, sizeof(class));
	FakeClientCommand(client, "use %s", class);
}

void UpdatePlayerItems(int client)
{
	if (convar_RemoveWearables.BoolValue)
	{
		int entity;
		while ((entity = FindEntityByClassname(entity, "tf_wearable*")) != -1)
			if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
				TF2_RemoveWearable(client, entity);
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	g_Uber[client] = 0.0;
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!convar_Status.BoolValue || !convar_ModifiedDamage.BoolValue)
		return Plugin_Continue;
	
	if (damagecustom == TF_CUSTOM_STANDARD_STICKY)
	{
		damage *= 2.0;
		return Plugin_Changed;
	}
	
	if (convar_DisableTauntKills.BoolValue && (damagecustom == TF_CUSTOM_TAUNT_HADOUKEN || damagecustom == TF_CUSTOM_TAUNT_FENCING || damagecustom == TF_CUSTOM_TAUNT_HIGH_NOON))
	{
		damage = 0.0;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	TFClassType class = TF2_GetPlayerClass(client);

	if (class == TFClass_Medic)
	{
		if (convar_FixedMedicSpeed.BoolValue)
		{
			int secondary = GetPlayerWeaponSlot(client, 1);

			if (IsValidEntity(secondary) && GetEntProp(secondary, Prop_Send, "m_bHealing") && TF2_GetPlayerClass(GetEntPropEnt(secondary, Prop_Send, "m_hHealingTarget")) == TFClass_Scout)
				SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 320.0);
		}

		if (convar_UberOnActiveOnly.BoolValue)
		{
			if (GetActiveWeaponSlot(client) != 1 && g_Uber[client] > TF2_GetUberLevel(client))
				TF2_SetUberLevel(client, g_Uber[client], true);
			else
				g_Uber[client] = TF2_GetUberLevel(client);
		}
	}

	if (convar_FixedMedicSpeed.BoolValue && class == TFClass_Spy)
	{
		int knife = GetPlayerWeaponSlot(client, 2);

		if (IsValidEntity(knife))
			SetEntProp(knife, Prop_Send, "m_nSequence", 8);
	}

	if ((convar_DisableMoveBuildings.BoolValue && class == TFClass_Engineer))
	{
        buttons &= ~IN_ATTACK2;
    	return Plugin_Changed;
	}

	return Plugin_Continue;
}

public void TF2_OnButtonPressPost(int client, int button)
{
	if ((button & IN_ATTACK) == IN_ATTACK)
	{
		int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

		if (!IsValidEntity(iWeapon))
			return;
		
		char classname[64];
		GetEntityClassname(iWeapon, classname, sizeof(classname));

		if (StrContains(classname, "tf_weapon_pistol", false) == 0 && convar_LegacyPistol.BoolValue)
			SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.1);
	}
}

public void TF2_OnWeaponFirePost(int client, int weapon)
{
	if (convar_LegacyPistol.BoolValue)
	{
		char classname[64];
		GetEntityClassname(weapon, classname, sizeof(classname));

		if (StrContains(classname, "tf_weapon_pistol", false) == 0)
			CreateTimer(0.0, Timer_Delay, weapon);
	}
}

public Action Timer_Delay(Handle timer, any data)
{
	int weapon = data;
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1.0);
}

int GetActiveWeaponSlot(int client)
{
	if (client == 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
		return -1;
	
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if (weapon == 0 || weapon < MaxClients || !IsValidEntity(weapon))
		return -1;
	
	for (int i = 0; i < 5; i++)
	{
		if (GetPlayerWeaponSlot(client, i) != weapon)
			continue;

		return i;
	}

	return -1;
}

float TF2_GetUberLevel(int client)
{
	int secondary = GetPlayerWeaponSlot(client, 1);
	return (IsValidEntity(secondary) && HasEntProp(secondary, Prop_Send, "m_flChargeLevel")) ? GetEntPropFloat(secondary, Prop_Send, "m_flChargeLevel") : -1.0;
}

void TF2_SetUberLevel(int client, float amount, bool cap = false)
{
	int secondary = GetPlayerWeaponSlot(client, 1);
	
	if (!IsValidEntity(secondary) || !HasEntProp(secondary, Prop_Send, "m_flChargeLevel"))
		return;
	
	float set = amount;
	
	if (cap && set > 1.00)
		set = 1.00;
	else if (set < 0.0)
		set = 0.0;
	
	SetEntPropFloat(secondary, Prop_Send, "m_flChargeLevel", set);
}

stock bool HasClassname(int entity, const char[] classname, bool caseSensitive = false)
{
	if (!IsValidEntity(entity))
		return false;
	
	char buffer[64];
	GetEntityClassname(entity, buffer, sizeof(buffer));
	
	return StrContains(buffer, classname, caseSensitive) != -1;
}

public Action OnTaunt(int client, const char[] command, int args)
{
	if (!convar_Status.BoolValue || !convar_DisableTaunts.BoolValue)
		return Plugin_Continue;
	
	char sArg[32];
	GetCmdArgString(sArg, sizeof(sArg));
	
	if (!StrEqual(sArg, "0"))
	{
		FakeClientCommand(client, "taunt 0");
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle& hItem)
{
	//Handle item = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES);
	//TF2Items_SetNumAttributes(item, 0);
	//hItem = item;
	//return Plugin_Changed;
}

public void TF2Items_OnGiveNamedItem_Post(int client, char[] classname, int itemDefinitionIndex, int itemLevel, int itemQuality, int entityIndex)
{
	if (!convar_Status.BoolValue || !convar_RemoveWeapons.BoolValue)
		return;
	
	DataPack pack = new DataPack();
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(itemDefinitionIndex);
	pack.WriteCell(entityIndex);
	
	RequestFrame(Frame_ReplaceWeapon, pack);
}

public void Frame_ReplaceWeapon(DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	int itemDefinitionIndex = pack.ReadCell();
	int entityIndex = pack.ReadCell();
	delete pack;

	int slot = GetWeaponSlot(client, entityIndex);
	TFClassType class = TF2_GetPlayerClass(client);

	int default_index;
	if ((default_index = TF2_GetDefaultWeaponID(class, slot)) == itemDefinitionIndex)
		return;

	char classname[32];
	if (!TF2_GetDefaultWeaponClass(class, slot, classname, sizeof(classname)) || strlen(classname) == 0)
		return;
	
	TF2_RemoveWeaponSlot(client, slot);

	Handle hItem = TF2Items_CreateItem(PRESERVE_ATTRIBUTES | OVERRIDE_CLASSNAME | OVERRIDE_ITEM_DEF | OVERRIDE_ITEM_LEVEL | OVERRIDE_ITEM_QUALITY | OVERRIDE_ATTRIBUTES);
	TF2Items_SetClassname(hItem, classname);
	TF2Items_SetItemIndex(hItem, default_index);
	TF2Items_SetQuality(hItem, 1);
	TF2Items_SetLevel(hItem, 6);
	
	int attrs;
	
	if (convar_LowerWeaponSwitching.BoolValue)
	{
		TF2Items_SetAttribute(hItem, 0, 177, 1.60);
		attrs++;
	}
	
	if (convar_DisableAirblasts.BoolValue && StrContains(classname, "tf_weapon_flamethrower", false) == 0)
	{
		TF2Items_SetNumAttributes(hItem, 2);
		TF2Items_SetAttribute(hItem, 1, 356, 1.0);
		attrs++;
	}
	
	if (attrs > 0)
		TF2Items_SetNumAttributes(hItem, attrs);
	
	int weapon = TF2Items_GiveNamedItem(client, hItem);
	delete hItem;
	
	if (StrEqual(classname, "tf_weapon_builder", false) && default_index != 28)
	{
		SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
		SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
	}

	EquipPlayerWeapon(client, weapon);

	if (StrContains(classname, "tf_weapon_flamethrower", false) == 0)
		SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + (GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1) * 4), 200, 4, true);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!convar_Status.BoolValue)
		return;
	
	if (convar_DisableDroppedWeapons.BoolValue && StrContains(classname, "tf_dropped_weapon") == 0)
		SDKHook(entity, SDKHook_Spawn, OnPreventEntitySpawn);
	
	if (convar_DisableGlows.BoolValue)
		SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawnPost);
	
	if (convar_GodPipes.BoolValue && StrContains(classname, "tf_projectile_pipe_remote") == 0)
		SDKHook(entity, SDKHook_OnTakeDamage, OnPipeTakeDamage);
}

public Action OnPipeTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	damage = 0.0;
	return Plugin_Stop;
}

public Action OnPreventEntitySpawn(int entity)
{
	return Plugin_Stop;
}

public void OnEntitySpawnPost(int entity)
{
	if (HasEntProp(entity, Prop_Send, "m_bGlowEnabled"))
		SetEntProp(entity, Prop_Send, "m_bGlowEnabled", false);
}

#define RAG_GIBBED			(1<<0)
#define RAG_BURNING			(1<<1)
#define RAG_ELECTROCUTED	(1<<2)
#define RAG_FEIGNDEATH		(1<<3)
#define RAG_WASDISGUISED	(1<<4)
#define RAG_BECOMEASH		(1<<5)
#define RAG_ONGROUND		(1<<6)
#define RAG_CLOAKED			(1<<7)
#define RAG_GOLDEN			(1<<8)
#define RAG_ICE				(1<<9)
#define RAG_CRITONHARDCRIT	(1<<10)
#define RAG_HIGHVELOCITY	(1<<11)
#define RAG_NOHEAD			(1<<12)

int TF2_SpawnRagdoll(int client, float destruct = 10.0, int flags = 0, float vel[3] = NULL_VECTOR)
{
	int ragdoll = CreateEntityByName("tf_ragdoll");

	if (IsValidEntity(ragdoll))
	{
		float vecOrigin[3];
		GetClientAbsOrigin(client, vecOrigin);

		float vecAngles[3];
		GetClientAbsAngles(client, vecAngles);

		TeleportEntity(ragdoll, vecOrigin, vecAngles, NULL_VECTOR);

		SetEntProp(ragdoll, Prop_Send, "m_iPlayerIndex", client);
		SetEntProp(ragdoll, Prop_Send, "m_iTeam", GetClientTeam(client));
		SetEntProp(ragdoll, Prop_Send, "m_iClass", view_as<int>(TF2_GetPlayerClass(client)));
		SetEntProp(ragdoll, Prop_Send, "m_nForceBone", 1);
		SetEntProp(ragdoll, Prop_Send, "m_iDamageCustom", TF_CUSTOM_TAUNT_ENGINEER_SMASH);
		
		SetEntProp(ragdoll, Prop_Send, "m_bGib", (flags & RAG_GIBBED) == RAG_GIBBED);
		SetEntProp(ragdoll, Prop_Send, "m_bBurning", (flags & RAG_BURNING) == RAG_BURNING);
		SetEntProp(ragdoll, Prop_Send, "m_bElectrocuted", (flags & RAG_ELECTROCUTED) == RAG_ELECTROCUTED);
		SetEntProp(ragdoll, Prop_Send, "m_bFeignDeath", (flags & RAG_FEIGNDEATH) == RAG_FEIGNDEATH);
		SetEntProp(ragdoll, Prop_Send, "m_bWasDisguised", (flags & RAG_WASDISGUISED) == RAG_WASDISGUISED);
		SetEntProp(ragdoll, Prop_Send, "m_bBecomeAsh", (flags & RAG_BECOMEASH) == RAG_BECOMEASH);
		SetEntProp(ragdoll, Prop_Send, "m_bOnGround", (flags & RAG_ONGROUND) == RAG_ONGROUND);
		SetEntProp(ragdoll, Prop_Send, "m_bCloaked", (flags & RAG_CLOAKED) == RAG_CLOAKED);
		SetEntProp(ragdoll, Prop_Send, "m_bGoldRagdoll", (flags & RAG_GOLDEN) == RAG_GOLDEN);
		SetEntProp(ragdoll, Prop_Send, "m_bIceRagdoll", (flags & RAG_ICE) == RAG_ICE);
		SetEntProp(ragdoll, Prop_Send, "m_bCritOnHardHit", (flags & RAG_CRITONHARDCRIT) == RAG_CRITONHARDCRIT);
		
		SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollOrigin", vecOrigin);
		SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollVelocity", vel);
		SetEntPropVector(ragdoll, Prop_Send, "m_vecForce", vel);
		
		if ((flags & RAG_HIGHVELOCITY) == RAG_HIGHVELOCITY)
		{
			float HighVel[3];
			HighVel[0] = -180000.552734;
			HighVel[1] = -1800.552734;
			HighVel[2] = 800000.552734;
			
			SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollVelocity", HighVel);
			SetEntPropVector(ragdoll, Prop_Send, "m_vecForce", HighVel);
		}
		
		SetEntPropFloat(ragdoll, Prop_Send, "m_flHeadScale", (flags & RAG_NOHEAD) == RAG_NOHEAD ? 0.0 : 1.0);
		SetEntPropFloat(ragdoll, Prop_Send, "m_flTorsoScale", 1.0);
		SetEntPropFloat(ragdoll, Prop_Send, "m_flHandScale", 1.0);
		
		DispatchSpawn(ragdoll);
		ActivateEntity(ragdoll);
		
		SetEntPropEnt(client, Prop_Send, "m_hRagdoll", ragdoll, 0);
		
		if (destruct > 0.0)
		{
			char output[64];
			Format(output, sizeof(output), "OnUser1 !self:kill::%.1f:1", destruct);

			SetVariantString(output);
			AcceptEntityInput(ragdoll, "AddOutput");
			AcceptEntityInput(ragdoll, "FireUser1");
		}
	}

	return ragdoll;
}

int GetWeaponSlot(int client, int weapon)
{
	if (client == 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client) || weapon == 0 || weapon < MaxClients || !IsValidEntity(weapon))
		return -1;

	for (int i = 0; i < 8; i++)
	{
		if (GetPlayerWeaponSlot(client, i) != weapon)
			continue;

		return i;
	}

	return -1;
}

bool TF2_GetDefaultWeaponClass(TFClassType class, int slot, char[] buffer, int size)
{
	bool found;

	switch(class)
	{
		case TFClass_Scout:
		{
			switch(slot)
			{
				case 0: Format(buffer, size, "tf_weapon_scattergun"), found = true;
				case 1: Format(buffer, size, "tf_weapon_pistol_scout"), found = true;
				case 2: Format(buffer, size, "tf_weapon_bat"), found = true;
			}
		}
		case TFClass_Sniper:
		{
			switch(slot)
			{
				case 0: Format(buffer, size, "tf_weapon_sniperrifle"), found = true;
				case 1: Format(buffer, size, "tf_weapon_smg"), found = true;
				case 2: Format(buffer, size, "tf_weapon_club"), found = true;
			}
		}
		case TFClass_Soldier:
		{
			switch(slot)
			{
				case 0: Format(buffer, size, "tf_weapon_rocketlauncher"), found = true;
				case 1: Format(buffer, size, "tf_weapon_shotgun_soldier"), found = true;
				case 2: Format(buffer, size, "tf_weapon_shovel"), found = true;
			}
		}
		case TFClass_DemoMan:
		{
			switch(slot)
			{
				case 0: Format(buffer, size, "tf_weapon_grenadelauncher"), found = true;
				case 1: Format(buffer, size, "tf_weapon_pipebomblauncher"), found = true;
				case 2: Format(buffer, size, "tf_weapon_bottle"), found = true;
			}
		}
		case TFClass_Medic:
		{
			switch(slot)
			{
				case 0: Format(buffer, size, "tf_weapon_syringegun_medic"), found = true;
				case 1: Format(buffer, size, "tf_weapon_medigun"), found = true;
				case 2: Format(buffer, size, "tf_weapon_bonesaw"), found = true;
			}
		}
		case TFClass_Heavy:
		{
			switch(slot)
			{
				case 0: Format(buffer, size, "tf_weapon_minigun"), found = true;
				case 1: Format(buffer, size, "tf_weapon_shotgun_hwg"), found = true;
				case 2: Format(buffer, size, "tf_weapon_fists"), found = true;
			}
		}
		case TFClass_Pyro:
		{
			switch(slot)
			{
				case 0: Format(buffer, size, "tf_weapon_flamethrower"), found = true;
				case 1: Format(buffer, size, "tf_weapon_shotgun_pyro"), found = true;
				case 2: Format(buffer, size, "tf_weapon_fireaxe"), found = true;
			}
		}
		case TFClass_Spy:
		{
			switch(slot)
			{
				case 0: Format(buffer, size, "tf_weapon_revolver"), found = true;
				case 1: Format(buffer, size, "tf_weapon_builder"), found = true;
				case 2: Format(buffer, size, "tf_weapon_knife"), found = true;
				case 4: Format(buffer, size, "tf_weapon_invis"), found = true;
			}
		}
		case TFClass_Engineer:
		{
			switch(slot)
			{
				case 0: Format(buffer, size, "tf_weapon_shotgun_primary"), found = true;
				case 1: Format(buffer, size, "tf_weapon_pistol"), found = true;
				case 2: Format(buffer, size, "tf_weapon_wrench"), found = true;
				case 3: Format(buffer, size, "tf_weapon_pda_engineer_build"), found = true;
			}
		}
	}

	return found;
}

int TF2_GetDefaultWeaponID(TFClassType class, int slot)
{
	switch(class)
	{
		case TFClass_Scout:
		{
			switch(slot)
			{
				case 0: return 13; case 1: return 23; case 2: return 0;
			}
		}
		case TFClass_Sniper:
		{
			switch(slot)
			{
				case 0: return 14; case 1: return 16; case 2: return 3;
			}
		}
		case TFClass_Soldier:
		{
			switch(slot)
			{
				case 0: return 18; case 1: return 10; case 2: return 6;
			}
		}
		case TFClass_DemoMan:
		{
			switch(slot)
			{ case 0: return 19; case 1: return 20; case 2: return 1;
			}
		}
		case TFClass_Medic:
		{
			switch(slot)
			{
				case 0: return 17; case 1: return 29; case 2: return 8;
			}
		}
		case TFClass_Heavy:
		{
			switch(slot)
			{
				case 0: return 15; case 1: return 11; case 2: return 5;
			}
		}
		case TFClass_Pyro:
		{
			switch(slot)
			{
				case 0: return 21; case 1: return 12; case 2: return 2;
			}
		}
		case TFClass_Spy:
		{
			switch(slot)
			{
				case 0: return 24; case 1: return 735; case 2: return 4; case 4: return 30;
			}
		}
		case TFClass_Engineer:
		{
			switch(slot)
			{
				case 0: return 9; case 1: return 22; case 2: return 7; case 3: return 25;
			}
		}
	}

	return -1;
}

public void Event_OnObjectBuild(Event event, const char[] name, bool dontBroadcast)
{
	if (!convar_Status.BoolValue || !convar_BuildingLevels.BoolValue)
		return;
	
	int obj = event.GetInt("object");
	int index = event.GetInt("index");
	
	if (g_hSDKStartBuilding == null)
		return;
		
	RequestFrame(FrameCallback_StartBuilding, index);

	switch (obj)
	{
		case OBJ_DISPENSER:
		{
			SetEntProp(index, Prop_Send, "m_iUpgradeLevel", 4 - 1);
			SetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel", 4 - 1);
		}
		case OBJ_TELEPORTER:
		{
			SetEntProp(index, Prop_Send, "m_iUpgradeLevel", 4 - 1);
			SetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel", 4 - 1);
		}
	}

	SetVariantInt(GetEntProp(index, Prop_Data, "m_iMaxHealth"));
	AcceptEntityInput(index, "SetHealth");
}

public void FrameCallback_StartBuilding(any entity)
{
	SDKCall(g_hSDKStartBuilding, entity);
}

public Action OnClientCommandKeyValues(int client, KeyValues kv)
{
	char sBuffer[32];
	kv.GetSectionName(sBuffer, sizeof(sBuffer));
	
	if (convar_DisableInspection.BoolValue && StrEqual(sBuffer, "+inspect_server", false))
		return Plugin_Handled;
	
	return Plugin_Continue;
}