/*========================================================================
==========================================================================

					P	E	R	K	M	O	D	2
					-----------------------------
						by tPoncho, aka tP

				   I owe a great deal of thanks to:

							Skorpion1976
							  Uyukio
							spiderlemur
								olj
							grandwazir

						and a special thanks to
							AtomicStryker

			and to everyone else in the Sourcemod community
					for feedback and support! ^^
==========================================================================
========================================================================*/



//=============================
// Start
//=============================

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#include <pm_base_enums>
#include <pm_perk_enums>
#include <pm_perk_structs>
#include <pm_convars>

#define PLUGIN_NAME "PerkMod"
#define PLUGIN_VERSION "3.0.0"
// #define PM_DEBUG 1

#define PM_PLAYERS_COUNT (1 + MAXPLAYERS)

// MARK: - Plugin Info

public Plugin myinfo=
{
	name = PLUGIN_NAME,
	author = "tPoncho",
	description = "Adds Call Of Duty-style perks for L4D",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=889437"
}

// MARK: - Global Variables

// MARK: Player perk vars

SurvivorPerks g_spSur[PM_PLAYERS_COUNT];
InfectedPerks g_ipInf[PM_PLAYERS_COUNT];
bool g_bConfirm[PM_PLAYERS_COUNT] = {false};

//timer perks handle
Handle g_hTimerPerks = null;

//PYROTECHNICIAN PERK
//track how many grenades are carried for pyrotechnician perk
int g_iGren[MAXPLAYERS+1] = {0};
//used so functions don't confuse legitimate grenade pickups
//with acquisitions from grenadier perk
int g_iGrenThrow[MAXPLAYERS+1] = {0};
//used to track which type of grenade was used;
//1 = pipe, 2 = molotov
int g_iGrenType[MAXPLAYERS+1] = {0};
//used to track how many "ticks" have passed
//since we want to give pipe bombs after a given
//number of ticks
int g_iPyroTicks[MAXPLAYERS+1] = {0};
int g_iPyroRegisterIndex[MAXPLAYERS+1] = {-1};
//and this tracks how many have DT
int g_iPyroRegisterCount = 0;

//SPIRIT PERK
bool g_bPIncap[MAXPLAYERS+1] = {false};
//used to keep track of whether cooldown is in effect
int g_iSpiritCooldown[MAXPLAYERS+1];
//used to track the timers themselves
Handle g_iSpiritTimer[MAXPLAYERS+1] = {null};

//DOUBLE TAP PERK
//used to track who has the double tap perk.
//The index goes up to 18, but each index has
//a value indicating a client index with DT
//so the plugin doesn't have to cycle a full
//18 times per game frame just for double tap.
int g_iDTRegisterIndex[MAXPLAYERS+1] = {-1};
//and this tracks how many have DT
int g_iDTRegisterCount = 0;
//this tracks the current active weapon id
//in case the player changes guns
int g_iDTEntid[MAXPLAYERS+1] = {-1};
//this tracks the engine time of the next
//attack for the weapon, after modification
//(modified interval + engine time)
float g_flDTNextTime[MAXPLAYERS+1] = {-1.0};
//this tracks whether the equipped gun is
//a semi auto weapon, saves us a lot of processing time
bool g_bDTsemiauto[MAXPLAYERS+1] = {false};

//SLEIGHT OF HAND PERK
//this keeps track of the default values for
//reload speeds for the different shotgun types
//NOTE: I got these values over testing earlier
//and since it's a waste of processing time to
//retrieve these values constantly, we just use
//the pre-retrieved values
//NOTE: updated for L4D2, pump and chrome have
//identical values
const float g_flSoHAutoS = 0.666666;
const float g_flSoHAutoI = 0.4;
const float g_flSoHAutoE = 0.675;
const float g_flSoHSpasS = 0.5;
const float g_flSoHSpasI = 0.375;
const float g_flSoHSpasE = 0.699999;
const float g_flSoHPumpS = 0.5;
const float g_flSoHPumpI = 0.5;
const float g_flSoHPumpE = 0.6;

//MARTIAL ARTIST PERK
//similar to Double Tap
int g_iMARegisterIndex[MAXPLAYERS+1] = {-1};
//and this tracks how many have MA
int g_iMARegisterCount = 0;
//these are similar to those used by Double Tap
float g_flMANextTime[MAXPLAYERS+1] = {-1.0};
int g_iMAEntid[MAXPLAYERS+1] = {-1};
int g_iMAEntid_notmelee[MAXPLAYERS+1] = {-1};
//this tracks the attack count, similar to twinSF
int g_iMAAttCount[MAXPLAYERS+1] = {-1};

//PACK RAT PERK
//prevents perk from applying multiple times within a short interval
//ie. when two related events fire at the same time that both trigger PR
bool g_bPRalreadyApplying[MAXPLAYERS+1] = {false};

//VARIOUS INFECTED PERKS
//this is used by most cooldown-reducing SI
//perks, keeps track of when an ability was used

float g_flTimeStamp[MAXPLAYERS+1] = {-1.0};
//contains id of target, for given disabler
int g_iMyDisableTarget[MAXPLAYERS+1] = {-1};
//contains id of disabler, for given survivor
int g_iMyDisabler[MAXPLAYERS+1] = {-1};

//BARF BAGGED PERK
//used to track how many survivors are boomed at a given time
//because spawning a whole mob per player is WAY too many
//also used indirectly to check if someone is currently vomited on
int g_iSlimed=0;

//DEAD WRECKENING PERK
//used to track who vomited on a survivor last
int g_iSlimerLast=0;

//TWIN SPITFIRE PERK
//similar to Double Tap
int g_iTwinSFShotCount[MAXPLAYERS+1] = {0};

//MEGA ADHESIVE PERK
Handle g_hMegaAdTimer[MAXPLAYERS+1] = {null};
int g_iMegaAdCount[MAXPLAYERS+1] = {0};

//TANKS
//tracks whether tanks are existent, and what perks have been given
//0 = no tank;
//1 = tank, but no special perks assigned yet;
//2 = tank, juggernaut has been given;
//3 = tank, double trouble has been given;
//4 = frustrated tank with double trouble is being passed to another player;
int g_iTank=0;
int g_iTankCount=0;		//tracks how many tanks there under double trouble modification
int g_iTankBotTicks=0;	//after 3 ticks, if tank is still a bot then give buffs
int g_iTank_MainId=0;	//tracks which tank is the "original", for Double Trouble
//similar to Double Tap, only used for punches
int g_iAdrenalRegisterCount = 0;
int g_iAdrenalRegisterIndex[MAXPLAYERS+1] = {-1};
float g_flAdrenalTimeStamp[MAXPLAYERS+1] = {-1.0};

//VARS TO STORE CONVAR VALUES
//declare revive time var
float g_flReviveTime= -1.0;
//declare vomit fatigue var
float g_flVomitFatigue= -1.0;
//declare yoink tongue speed var
float g_flTongueSpeed= -1.0;
float g_flTongueFlySpeed= -1.0;
float g_flTongueRange= -1.0;
//declare drag and drop vars
float g_flTongueDropTime= -1.0;

//OFFSETS
int g_iHPBuffO			= -1;
int g_iHPBuffTimeO		= -1;
int g_iRevCountO		= -1;
int g_iMeleeFatigueO	= -1;
int g_iNextPAttO		= -1;
int g_iNextSAttO		= -1;
int g_iActiveWO			= -1;
int g_iShotStartDurO	= -1;
int g_iShotInsertDurO	= -1;
int g_iShotEndDurO		= -1;
int g_iPlayRateO		= -1;
int g_iShotRelStateO	= -1;
int g_iNextAttO			= -1;
int g_iTimeIdleO		= -1;
int g_iLaggedMovementO	= -1;
int g_iFrustrationO		= -1;
int g_iAbilityO			= -1;
int g_iClassO			= -1;
int g_iVMStartTimeO		= -1;
int g_iViewModelO		= -1;
int g_iIncapO			= -1;
int g_iIsGhostO			= -1;

// netprop: m_nextActivationTimer
int g_iNextActO;
int g_iAttackTimerO;

//=============================
// Declare Variables that track
// base L4D ConVars
//=============================

//tracks game mode
GameModeType g_L4D_GameMode = GameMode_Campaign;

//tracks if the game is L4D2
bool g_bIsL4D2 = false;

//prevents certain functions from spamming too often
bool g_bIsRoundStart	 = false;
bool g_bIsLoading		 = false;

//this var keeps track of whether
//to enable DT and Stopping or not, so we don't
//have to do the checks every game frame, or
//every time someone gets hurt

bool g_bDT_meta_enable = true;
bool g_bStopping_meta_enable = true;
bool g_bMA_meta_enable = true;

//=============================
// Hooking, Initialize Vars
//=============================

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev = GetEngineVersion();
	if (ev == Engine_Left4Dead) {
		g_bIsL4D2 = false;
	} else if (ev == Engine_Left4Dead2) {
		g_bIsL4D2 = true;
	} else {
		SetFailState("Perkmod only supports L4D 1 or 2.");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	//Plugin version for online tracking
	CreateConVar("l4d_perkmod_version", PLUGIN_VERSION, "Version of Perkmod2 for L4D2", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	//PERK FUNCTIONS
	//anything here that pertains to the actual
	//workings of the perks (ie, events and timers)

	//hooks for Sur1 perks
	HookEvent("player_hurt", Event_PlayerHurtPre, EventHookMode_Pre);
	HookEvent("infected_hurt", Event_InfectedHurtPre, EventHookMode_Pre);
	HookEvent("item_pickup", Event_ItemPickup);
	HookEvent("spawner_give_item", Event_ItemPickup);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("lunge_pounce", Event_PounceLanded);
	HookEvent("pounce_stopped", Event_PounceStop);
	HookEvent("player_ledge_grab", Event_LedgeGrab);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("weapon_reload", Event_Reload);
	HookEvent("heal_success", Event_PlayerHealed);
	HookEvent("survivor_rescued", Event_PlayerRescued);
	HookEvent("pills_used", Event_PillsUsed, EventHookMode_Pre);
	HookEvent("revive_begin", Event_ReviveBeginPre, EventHookMode_Pre);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("ammo_pickup", Event_AmmoPickup);
	HookEvent("player_incapacitated", Event_Incap);
	HookEvent("player_now_it", Event_PlayerNowIt);
	HookEvent("ability_use", Event_AbilityUsePre, EventHookMode_Pre);
	HookEvent("tongue_grab", Event_TongueGrabPre, EventHookMode_Pre);
	HookEvent("tongue_release", Event_TongueRelease);
	HookEvent("choke_end", Event_TongueRelease);
	HookEvent("tongue_broke_bent", Event_TongueRelease_novictimid);
	HookEvent("choke_stopped", Event_TongueRelease_newsmokerid);
	HookEvent("tongue_pull_stopped", Event_TongueRelease_newsmokerid);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("ability_use", Event_AbilityUse);
	HookEvent("tank_spawn", Event_Tank_Spawn);
	HookEvent("tank_frustrated", Event_Tank_Frustrated, EventHookMode_Pre);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_transitioned", Event_PlayerTransitioned);
	HookEvent("player_connect_full", Event_PConnect);
	HookEvent("player_disconnect", Event_PDisconnect);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);

	RegConsoleCmd("sm_perks", MenuOpen_OnSay);
	RegConsoleCmd("sm_setperks", SS_SetPerks);

	FindConVar("mp_gamemode").AddChangeHook(Convar_GameMode);

	//l4d2 only hooks
	if (g_bIsL4D2)
	{
		HookEvent("jockey_ride", Event_JockeyRide);
		HookEvent("jockey_ride_end", Event_JockeyRideEnd);
		HookEvent("charger_pummel_start", Event_ChargerPummelStart);
		HookEvent("charger_pummel_end", Event_ChargerPummelEnd);
		HookEvent("charger_impact", Event_ChargerImpact);
		HookEvent("charger_charge_end", Event_ChargerChargeEnd);
		HookEvent("charger_carry_end", Event_ChargerChargeEnd);
		HookEvent("adrenaline_used", Event_PillsUsed, EventHookMode_Pre);
		HookEvent("player_jump", Event_Jump);
	}

	#if defined PM_DEBUG
	RegConsoleCmd("say", Debug_OnSay);
	RegConsoleCmd("say_team", Debug_OnSay);
	#endif

	//init vars
	g_flVomitFatigue	=	FindConVar("z_vomit_fatigue").FloatValue;
	g_flTongueSpeed		=	FindConVar("tongue_victim_max_speed").FloatValue;
	g_flTongueFlySpeed	=	FindConVar("tongue_fly_speed").FloatValue;
	g_flTongueRange		=	FindConVar("tongue_range").FloatValue;
	g_flTongueDropTime	=	FindConVar("tongue_player_dropping_to_ground_time").FloatValue;
	g_flReviveTime		=	FindConVar("survivor_revive_duration").FloatValue;

	//get offsets
	g_iHPBuffO			=	FindSendPropInfo("CTerrorPlayer","m_healthBuffer");
	g_iHPBuffTimeO		=	FindSendPropInfo("CTerrorPlayer","m_healthBufferTime");
	g_iRevCountO		=	FindSendPropInfo("CTerrorPlayer","m_currentReviveCount");
	g_iMeleeFatigueO	=	FindSendPropInfo("CTerrorPlayer","m_iShovePenalty");
	g_iNextPAttO		=	FindSendPropInfo("CBaseCombatWeapon","m_flNextPrimaryAttack");
	g_iNextSAttO		=	FindSendPropInfo("CBaseCombatWeapon","m_flNextSecondaryAttack");
	g_iActiveWO			=	FindSendPropInfo("CBaseCombatCharacter","m_hActiveWeapon");
	g_iShotStartDurO	=	FindSendPropInfo("CBaseShotgun","m_reloadStartDuration");
	g_iShotInsertDurO	=	FindSendPropInfo("CBaseShotgun","m_reloadInsertDuration");
	g_iShotEndDurO		=	FindSendPropInfo("CBaseShotgun","m_reloadEndDuration");
	g_iPlayRateO		=	FindSendPropInfo("CBaseCombatWeapon","m_flPlaybackRate");
	g_iShotRelStateO	=	FindSendPropInfo("CBaseShotgun","m_reloadState");
	g_iNextAttO			=	FindSendPropInfo("CTerrorPlayer","m_flNextAttack");
	g_iTimeIdleO		=	FindSendPropInfo("CTerrorGun","m_flTimeWeaponIdle");
	g_iLaggedMovementO	=	FindSendPropInfo("CTerrorPlayer","m_flLaggedMovementValue");
	g_iFrustrationO		=	FindSendPropInfo("Tank","m_frustration");
	g_iAbilityO			=	FindSendPropInfo("CTerrorPlayer","m_customAbility");
	g_iClassO			=	FindSendPropInfo("CTerrorPlayer","m_zombieClass");
	g_iVMStartTimeO		=	FindSendPropInfo("CTerrorViewModel","m_flLayerStartTime");
	g_iViewModelO		=	FindSendPropInfo("CTerrorPlayer","m_hViewModel");
	g_iIncapO			=	FindSendPropInfo("CTerrorPlayer","m_isIncapacitated");
	g_iIsGhostO			=	FindSendPropInfo("CTerrorPlayer","m_isGhost");

	g_iNextActO			=	FindSendPropInfo("CBaseAbility","m_nextActivationTimer");
	g_iAttackTimerO		=	FindSendPropInfo("CClaw","m_attackTimer");
	
	LogMessage("Retrieved g_iNextActO = %i", g_iNextActO);
	LogMessage("Retrieved g_iAttackTimerO = %i", g_iAttackTimerO);

	//CREATE AND INITIALIZE CONVARS
	//everything related to the convars that adjust
	//certain values for the perks
	CreateConvars();

	//finally, run a command to exec the .cfg file
	//to load the server's preferences for these cvars
	AutoExecConfig(true, "perkmod");

	//and load translations
	LoadTranslations("plugin.perkmod");
}

//tracks changes in game mode
void Convar_GameMode(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (StringInsensitiveContains(newValue, "versus") || StringInsensitiveContains(newValue, "scavenge"))
		g_L4D_GameMode = GameMode_Versus;
	else if (StrEqual(newValue, "survival", false))
		g_L4D_GameMode = GameMode_Survival;
	else
		g_L4D_GameMode = GameMode_Campaign;

	#if defined PM_DEBUG
	PrintToChatAll("\x03gamemode change detected, new value: \x01%i", g_L4D_GameMode);
	#endif
}

//====================================================
//====================================================
// MARK: - 	P	E	R	K	S
//====================================================
//====================================================

//=============================
// MARK: - Events Directly related to perks
//=============================

//this trigger only runs on players, not common infected
Action Event_PlayerHurtPre(Event event, const char[] name, bool dontBroadcast)
{
	int iAtt = GetClientOfUserId(event.GetInt("attacker"));
	int iVic = GetClientOfUserId(event.GetInt("userid"));

	if (iVic == 0) return Plugin_Continue;

	int iType = event.GetInt("type");
	int iDmgOrig = event.GetInt("dmg_health");

	#if defined PM_DEBUG
	char sWeapon[128];
	event.GetString("weapon", sWeapon, sizeof(sWeapon));
	PrintToChatAll("\x03attacker:\x01%i\x03 weapon:\x01%s\x03 type:\x01%i\x03 amount: \x01%i", iAtt, sWeapon, iType, iDmgOrig);
	#endif

	//check for dead wreckening damage add for zombies
	if (DeadWreckening_DamageAdd(iAtt, iVic, iType, iDmgOrig))
		return Plugin_Continue;

	if (iAtt == 0) return Plugin_Continue;

	char stWpn[16];
	event.GetString("weapon", stWpn, sizeof(stWpn));

	ClientTeamType iTA = SM_GetClientTeamType(iAtt);
	#if defined PM_DEBUG
	if (iTA == ClientTeam_Survivor) PrintToChatAll("\x03weapon:\x01%s\x03 type:\x01%i", stWpn, iType);
	#endif

	//if damage is from survivors to a non-survivor,
	//check for damage add (stopping power)
	if (Stopping_DamageAdd(iAtt, iVic, iTA, iDmgOrig, stWpn))
		return Plugin_Continue;

	//otherwise, check for infected damage add types
	//(body slam, efficient killer, squeezer)

	//...check for body slam
	if (BodySlam_DamageAdd(iAtt, iVic, iTA, iType, stWpn, iDmgOrig))
		return Plugin_Continue;

	//run speed demon checks
	if (SpeedDemon_DamageAdd(iAtt, iVic, iTA, iType, stWpn, iDmgOrig))
		return Plugin_Continue;

	//run efficient killer checks
	if (EfficientKiller_DamageAdd(iAtt, iVic, iTA, iType, stWpn, iDmgOrig))
		return Plugin_Continue;

	//check for squeezer
	if (Squeezer_DamageAdd(iAtt, iVic, iTA, stWpn, iDmgOrig))
		return Plugin_Continue;

	//run mega adhesive checks
	if (MegaAd_SlowEffect(iAtt, iVic, stWpn))
		return Plugin_Continue;

	//run frogger checks
	if (Frogger_DamageAdd(iAtt, iVic, iTA, stWpn, iDmgOrig))
		return Plugin_Continue;

	return Plugin_Continue;
}

Action Event_Incap(Event event, const char[] name, bool dontBroadcast)
{
	int iCid = GetClientOfUserId(event.GetInt("userid"));

	if (iCid == 0) return Plugin_Continue;

	if (SM_GetClientTeamType(iCid) == ClientTeam_Infected && GetEntData(iCid, g_iIncapO) != 0)
		g_bPIncap[iCid] = true;

	HardToKill_OnIncap(iCid);
	return Plugin_Continue;
}

//called when player is healed
Action Event_PlayerHealed(Event event, const char[] name, bool dontBroadcast)
{
	int iCid = GetClientOfUserId(event.GetInt("subject"));
	if (iCid == 0 || g_bConfirm[iCid] == false) return Plugin_Continue;

	Unbreakable_OnHeal(iCid);
	return Plugin_Continue;
}

//called when survivor spawns from closet
Action Event_PlayerRescued(Event event, const char[] name, bool dontBroadcast)
{
	int iCid = GetClientOfUserId(event.GetInt("victim"));
	if (iCid == 0 || g_bConfirm[iCid] == false)
		return Plugin_Continue;

	//reset vars related to spirit perk
	g_iMyDisabler[iCid] = -1;
	g_bPIncap[iCid] = false;
	g_iSpiritCooldown[iCid] = 0;
	//reset var related to blind luck perk
	SetEntProp(iCid, Prop_Send, "m_iHideHUD", 0);
	//rebuilds double tap registry
	CreateTimer(0.3, Delayed_Rebuild, 0);

	//checks for unbreakable health bonus
	Unbreakable_OnRescue(iCid);
	//check for pyrotechnician bonus grenade
	Event_Confirm_Grenadier (iCid);
	//check for chem reliant bonus pills
	Event_Confirm_ChemReliant(iCid);

	return Plugin_Continue;
}

//on game frame
public void OnGameFrame()
{
	//if frames aren't being processed,
	//don't bother - otherwise we get LAG
	//or even disconnects on map changes, etc...

	if (IsServerProcessing() == false || g_bIsLoading || g_bIsRoundStart)
		return;

	DT_OnGameFrame();
	MA_OnGameFrame();
	Adrenal_OnGameFrame();
}

//on reload
Action Event_Reload(Event event, const char[] name, bool dontBroadcast)
{
	int iCid = GetClientOfUserId(event.GetInt("userid"));
	if (iCid == 0)
		return Plugin_Continue;

	SoH_OnReload(iCid);

	return Plugin_Continue;
}

//on weapon fire
Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int iCid = GetClientOfUserId(event.GetInt("userid"));
	if (iCid == 0)
		return Plugin_Continue;

	char stWpn[24];
	GetEventString(event, "weapon", stWpn, sizeof(stWpn));

	Pyro_OnWeaponFire(iCid, stWpn);

	return Plugin_Continue;
}

//on drug use
Action Event_PillsUsed (Event event, const char[] name, bool dontBroadcast)
{
	int iCid = GetClientOfUserId(event.GetInt("subject"));
	if (iCid == 0) return Plugin_Continue;

	Chem_OnDrugUsed(iCid);

	return Plugin_Continue;
}

//on revive begin
Action Event_ReviveBeginPre (Event event, const char[] name, bool dontBroadcast)
{
	int iCid = GetClientOfUserId(event.GetInt("userid"));

	if (iCid == 0) return Plugin_Continue;

	HelpHand_OnReviveBegin(iCid);

	return Plugin_Continue;
}

//on revive end
Action Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int iCid = GetClientOfUserId(event.GetInt("userid"));
	int iSub = GetClientOfUserId(event.GetInt("subject"));

	if (iCid == 0 || iSub == 0)
		return Plugin_Continue;

	int iLedge = event.GetInt("ledge_hang");
	//player is labelled as no longer incapped
	g_bPIncap[iSub] = false;

	Unbreakable_OnRevive(iSub, iLedge);
	HelpHand_OnReviveSuccess(iCid, iSub, iLedge);

	return Plugin_Continue;
}

//detects when a person is hanging from a ledge
Action Event_LedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	int iCid = GetClientOfUserId(event.GetInt("userid"));

	if (iCid == 0) return Plugin_Continue;

	#if defined PM_DEBUG
	PrintToChatAll("\x03spirit ledge grab detected, client: \x01%i", iCid);
	#endif

	g_bPIncap[iCid] = true;
	g_iMyDisabler[iCid] = 0;

	return Plugin_Continue;
}

Action Event_AbilityUsePre (Event event, const char[] name, bool dontBroadcast)
{
	int iCid = GetClientOfUserId(event.GetInt("userid"));

	if (iCid == 0 || g_bConfirm[iCid] == false) return Plugin_Continue;

	char stAb[24];
	GetEventString(event, "ability", stAb, sizeof(stAb));

	#if defined PM_DEBUG
	PrintToChatAll("\x03ability used: \x01%s", stAb);
	#endif

	TongueTwister_OnAbilityUse(iCid, stAb);

	return Plugin_Continue;
}

Action Event_AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
	int iCid = GetClientOfUserId(event.GetInt("userid"));
	if (iCid == 0)
		return Plugin_Continue;

	char stAb[24];
	GetEventString(event, "ability", stAb, sizeof(stAb));

	#if defined PM_DEBUG
	PrintToChatAll("\x03ability used: \x01%s", stAb);
	#endif

	if (Grass_OnAbilityUse(iCid, stAb))
		return Plugin_Continue;

	if (Bullet_OnAbilityUse(iCid, stAb))
		return Plugin_Continue;

	return Plugin_Continue;
}

Action Event_Jump(Event event, const char[] name, bool dontBroadcast)
{
	int iCid = GetClientOfUserId(event.GetInt("userid"));
	if (iCid == 0)
		return Plugin_Continue;

	Frogger_OnJump(iCid);

	return Plugin_Continue;
}

//on becoming slimed, check if player will lose hud
Action Event_PlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
	int iAtt = GetClientOfUserId(event.GetInt("attacker"));
	int iVic = GetClientOfUserId(event.GetInt("userid"));

	if (iAtt == 0 || iVic == 0) return Plugin_Continue;

	#if defined PM_DEBUG
	PrintToChatAll("\x03slimed detected, victim/client: \x01%i\x03, attacker: \x01%i", iVic, iAtt);
	#endif
	//tell plugin another one got slimed (pungent)
	g_iSlimed++;
	//update plugin var for who vomited last (dead wreckening)
	g_iSlimerLast = iAtt;

	//check for blind luck
	BlindLuck_OnIt(iAtt, iVic);

	//check for barf bagged
	BarfBagged_OnIt(iAtt);

	CreateTimer(15.0, PlayerNoLongerIt, iVic);

	return Plugin_Continue;
}

Action Event_TongueGrabPre (Event event, const char[] name, bool dontBroadcast)
{
	int iCid = GetClientOfUserId(event.GetInt("userid"));
	int iVic = GetClientOfUserId(event.GetInt("victim"));
	if (iCid == 0) return Plugin_Continue;

	//spirit perk, tell plugin player is disabled by smoker
	g_iMyDisabler[iVic] = iCid;
	//+Inf, tell plugin attacker is disabling
	g_iMyDisableTarget[iCid] = iVic;

	TongueTwister_OnTongueGrab(iCid);
	Drag_OnTongueGrab(iCid);
	SmokeIt_OnTongueGrab(iCid, iVic);

	return Plugin_Continue;
}

Action Event_TongueRelease(Event event, const char[] name, bool dontBroadcast)
{
	//+Inf, tell plugin attacker is no longer disabling
	int iCid = GetClientOfUserId(event.GetInt("userid"));
	if (iCid != 0) g_iMyDisableTarget[iCid] = -1;
	//tell plugin player is free
	int iVic = GetClientOfUserId(event.GetInt("victim"));
	if (iVic != 0) g_iMyDisabler[iVic] = -1;

	TongueTwister_OnTongueRelease();
	SmokeIt_OnTongueRelease(iCid);

	return Plugin_Continue;
}

Action Event_TongueRelease_novictimid(Event event, const char[] name, bool dontBroadcast)
{
	//+Inf, tell plugin attacker is no longer disabling
	int iCid = GetClientOfUserId(event.GetInt("userid"));
	if (iCid != 0) g_iMyDisableTarget[iCid] = -1;
	//tell plugin player is free
	//int iVic = GetClientOfUserId(event.GetInt("victim"));
	//if (iVic!=0) g_iMyDisabler[iVic] = -1;

	TongueTwister_OnTongueRelease();
	SmokeIt_OnTongueRelease(iCid);

	return Plugin_Continue;
}

Action Event_TongueRelease_newsmokerid(Event event, const char[] name, bool dontBroadcast)
{
	//+Inf, tell plugin attacker is no longer disabling
	int iCid = GetClientOfUserId(event.GetInt("smoker"));
	if (iCid!=0) g_iMyDisableTarget[iCid] = -1;
	//tell plugin player is free
	int iVic = GetClientOfUserId(event.GetInt("victim"));
	if (iVic!=0) g_iMyDisabler[iVic] = -1;

	TongueTwister_OnTongueRelease();
	SmokeIt_OnTongueRelease(iCid);

	return Plugin_Continue;
}

Action Event_PounceLanded(Event event, const char[] name, bool dontBroadcast)
{
	int iAtt = GetClientOfUserId(event.GetInt("userid"));
	int iVic = GetClientOfUserId(event.GetInt("victim"));

	if (iVic == 0 || iAtt == 0) return Plugin_Continue;

	#if defined PM_DEBUG
	PrintToChatAll("\x03pounce land detected, client: \x01%i\x03, victim: \x01%i", iAtt, iVic);
	#endif
	//spirit victim state is disabled by hunter
	g_iMyDisabler[iVic] = iAtt;
	//+Inf, attacker is disabling someone
	g_iMyDisableTarget[iAtt] = iVic;

	return Plugin_Continue;
}

Action Event_PounceStop(Event event, const char[] name, bool dontBroadcast)
{
	int iAtt = GetClientOfUserId(event.GetInt("userid"));
	int iVic = GetClientOfUserId(event.GetInt("victim"));

	if (iVic == 0 || iAtt == 0) return Plugin_Continue;

	#if defined PM_DEBUG
	PrintToChatAll("\x03pounce stop detected, attacker: \x01%i\x03, victim: \x01%i", iAtt, iVic);
	#endif
	//victim is no longer disabled
	g_iMyDisabler[iVic] = -1;
	//+Inf, attacker no longer disabling
	g_iMyDisableTarget[iAtt] = -1;

	return Plugin_Continue;
}

Action Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	int iAtt = GetClientOfUserId(event.GetInt("userid"));
	int iVic = GetClientOfUserId(event.GetInt("victim"));

	if (iVic == 0 || iAtt == 0) return Plugin_Continue;

	#if defined PM_DEBUG
	PrintToChatAll("\x03ride start detected, client: \x01%i\x03, victim: \x01%i", iAtt, iVic);
	#endif
	//spirit victim state is disabled
	g_iMyDisabler[iVic] = iAtt;
	//+Inf, attacker is disabling someone
	g_iMyDisableTarget[iAtt] = iVic;

	Wind_OnRideStart(iAtt, iVic);

	return Plugin_Continue;
}

Action Event_JockeyRideEnd(Event event, const char[] name, bool dontBroadcast)
{
	int iAtt = GetClientOfUserId(event.GetInt("userid"));
	int iVic = GetClientOfUserId(event.GetInt("victim"));

	if (iVic == 0 || iAtt == 0) return Plugin_Continue;

	#if defined PM_DEBUG
	PrintToChatAll("\x03ride end detected, attacker: \x01%i\x03, victim: \x01%i", iAtt, iVic);
	#endif
	//victim is no longer disabled
	g_iMyDisabler[iVic] = -1;
	//+Inf, attacker no longer disabling
	g_iMyDisableTarget[iAtt] = -1;

	Wind_OnRideEnd(iAtt, iVic);

	//since ride like the wind changes the survivor's speeds,
	//reapply extreme conditioning if necessary
	CreateTimer(0.3, Delayed_Rebuild, 0);

	return Plugin_Continue;
}

Action Event_ChargerPummelStart(Event event, const char[] name, bool dontBroadcast)
{
	int iAtt = GetClientOfUserId(event.GetInt("userid"));
	int iVic = GetClientOfUserId(event.GetInt("victim"));

	if (iVic == 0 || iAtt == 0) return Plugin_Continue;

	#if defined PM_DEBUG
	PrintToChatAll("\x03ride start detected, client: \x01%i\x03, victim: \x01%i", iAtt, iVic);
	#endif
	//spirit victim state is disabled
	g_iMyDisabler[iVic] = iAtt;
	//+Inf, attacker is disabling someone
	g_iMyDisableTarget[iAtt] = iVic;

	return Plugin_Continue;
}

Action Event_ChargerPummelEnd(Event event, const char[] name, bool dontBroadcast)
{
	int iAtt = GetClientOfUserId(event.GetInt("userid"));
	int iVic = GetClientOfUserId(event.GetInt("victim"));

	if (iVic == 0 || iAtt == 0) return Plugin_Continue;

	#if defined PM_DEBUG
	PrintToChatAll("\x03ride end detected, attacker: \x01%i\x03, victim: \x01%i", iAtt, iVic);
	#endif
	//victim is no longer disabled
	g_iMyDisabler[iVic] = -1;
	//+Inf, attacker no longer disabling
	g_iMyDisableTarget[iAtt] = -1;

	return Plugin_Continue;
}

Action Event_ChargerImpact(Event event, const char[] name, bool dontBroadcast)
{
	int iAtt = GetClientOfUserId(event.GetInt("userid"));
	int iVic = GetClientOfUserId(event.GetInt("victim"));

	if (iVic == 0 || iAtt == 0) return Plugin_Continue;

	#if defined PM_DEBUG
	PrintToChatAll("\x03charger impact detected, attacker: \x01%i\x03, victim: \x01%i", iAtt, iVic);
	#endif
	Scatter_OnImpact(iAtt, iVic);

	return Plugin_Continue;
}

Action Event_ChargerChargeEnd(Event event, const char[] name, bool dontBroadcast)
{
	int iCid = GetClientOfUserId(event.GetInt("userid"));
	if (iCid == 0) return Plugin_Continue;

	SetEntDataFloat(iCid, g_iLaggedMovementO, 1.0, true);

	return Plugin_Continue;
}

//** a very important event! =P
Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	//stop if game hasn't finished loading
	if (g_bIsLoading || g_bIsRoundStart)
		return Plugin_Continue;

	int iCid = GetClientOfUserId(event.GetInt("userid"));

	//show the perk menu if their perks are unconfirmed
	if (IsClientInGame(iCid) && IsFakeClient(iCid) == false && g_bConfirm[iCid] == false)
		CreateTimer(3.0, Timer_ShowTopMenu, iCid);

	SetEntDataFloat(iCid, g_iLaggedMovementO, 1.0, true);
	TwinSF_ResetShotCount(iCid);

	ClientTeamType iTeam = SM_GetClientTeamType(iCid);

	//check survivors for max health
	//they probably don't have any confirmed perks
	//since they just spawned, so set max to 100
	if (iTeam == ClientTeam_Survivor)
	{
		if (g_bSurAll_enable == false)
		{
			g_bConfirm[iCid] = false;
			return Plugin_Continue;
		}

		if ( GetEntProp(iCid, Prop_Data,"m_iHealth") > 100 )
			SetEntProp(iCid, Prop_Data,"m_iHealth", 100 );

		//set survivor bot's perks
		if (IsFakeClient(iCid))
		{
			g_bConfirm[iCid] = true;
			g_spSur[iCid].firstPerk = BotPickRandomSurvivorFirstPerk();
			g_spSur[iCid].secondPerk = BotPickRandomSurvivorSecondPerk();
			g_spSur[iCid].thirdPerk = BotPickRandomSurvivorThirdPerk();

			#if defined PM_DEBUG
			PrintToChatAll("\x03survivor bot 1: \x01%i\x03, 2:\x01%i", g_spSur[iCid].firstPerk, g_spSur[iCid].secondPerk);
			#endif
		}

		#if defined PM_DEBUG
		PrintToChatAll("\x03spawned survivor \x01%i\x03 health \x01%i", iCid, GetEntProp(iCid, Prop_Data,"m_iHealth") );
		#endif
		return Plugin_Continue;
	}

	if (iTeam == ClientTeam_Infected && g_bInfAll_enable == false)
	{
		g_bConfirm[iCid] = false;
		return Plugin_Continue;
	}

	InfectedType infectedType = SM_IntToInfectedType(GetEntData(iCid, g_iClassO), g_bIsL4D2);

	if (infectedType == Infected_Smoker)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x03smoker model detected");
		#endif
		//run a max health check before
		//doing anything else
		int iMaxHP = FindConVar("z_gas_health").IntValue;
		if (GetEntProp(iCid, Prop_Data, "m_iHealth") > iMaxHP)
			SetEntProp(iCid, Prop_Data, "m_iHealth", iMaxHP);

		//set bot perks
		if (IsFakeClient(iCid))
		{
			g_ipInf[iCid].smokerPerk = BotPickRandomSmokerPerk();
			g_bConfirm[iCid] = true;

			#if defined PM_DEBUG
			PrintToChatAll("\x03-smoker bot perk \x01%i", g_ipInf[iCid].smokerPerk);
			#endif
		}

		#if defined PM_DEBUG
		PrintToChatAll("\x03spawned smoker \x01%i\x03 health \x01%i\x03, maxhp \x01%i", iCid, GetEntProp(iCid, Prop_Data,"m_iHealth"), iMaxHP );
		#endif
		TongueTwister_OnSpawn(iCid);
		Drag_OnSpawn(iCid);

		return Plugin_Continue;
	}
	else if (infectedType == Infected_Hunter)
	{
		//run a max health check before
		//doing anything else
		int iMaxHP = FindConVar("z_hunter_health").IntValue;
		if (GetEntProp(iCid, Prop_Data, "m_iHealth") > iMaxHP)
			SetEntProp(iCid, Prop_Data, "m_iHealth", iMaxHP);

		//set bot perks
		if (IsFakeClient(iCid))
		{
			g_ipInf[iCid].hunterPerk = BotPickRandomHunterPerk();
			g_bConfirm[iCid] = true;

			#if defined PM_DEBUG
			PrintToChatAll("\x03-hunter bot perk \x01%i", g_ipInf[iCid].hunterPerk);
			#endif
		}

		#if defined PM_DEBUG
		PrintToChatAll("\x03spawned hunter \x01%i\x03 health \x01%i\x03, maxhp \x01%i", iCid, GetEntProp(iCid, Prop_Data,"m_iHealth"), iMaxHP );
		#endif
		SpeedDemon_OnSpawn(iCid);

		return Plugin_Continue;
	}
	else if (infectedType == Infected_Boomer)
	{
		//run a max health check before
		//doing anything else
		int iMaxHP = FindConVar("z_exploding_health").IntValue;
		if (GetEntProp(iCid, Prop_Data, "m_iHealth") > iMaxHP)
			SetEntProp(iCid, Prop_Data, "m_iHealth", iMaxHP);

		//set bot perks
		if (IsFakeClient(iCid))
		{
			g_ipInf[iCid].boomerPerk = BotPickRandomBoomerPerk();
			g_bConfirm[iCid] = true;

			#if defined PM_DEBUG
			PrintToChatAll("\x03-boomer bot perk \x01%i", g_ipInf[iCid].boomerPerk);
			#endif
		}

		#if defined PM_DEBUG
		PrintToChatAll("\x03spawned boomer \x01%i\x03 health \x01%i\x03, maxhp \x01%i", iCid, GetEntProp(iCid, Prop_Data,"m_iHealth"), iMaxHP );
		#endif
		Motion_OnSpawn(iCid);
		BlindLuck_OnSpawn(iCid);

		return Plugin_Continue;
	}
	else if (infectedType == Infected_Spitter)
	{
		int iMaxHP = FindConVar("z_spitter_health").IntValue;
		if (GetEntProp(iCid, Prop_Data, "m_iHealth") > iMaxHP)
			SetEntProp(iCid, Prop_Data, "m_iHealth", iMaxHP);

		#if defined PM_DEBUG
		PrintToChatAll("\x03spitter spawned");
		#endif
		//set bot perks
		if (IsFakeClient(iCid))
		{
			g_ipInf[iCid].spitterPerk = BotPickRandomSpitterPerk();
			g_bConfirm[iCid] = true;

			#if defined PM_DEBUG
			PrintToChatAll("\x03-spitter bot perk \x01%i", g_ipInf[iCid].spitterPerk);
			#endif
		}

		#if defined PM_DEBUG
		PrintToChatAll("\x03spawned spitter \x01%i\x03 health \x01%i\x03, maxhp \x01%i", iCid, GetEntProp(iCid, Prop_Data,"m_iHealth"), iMaxHP );
		#endif
		TwinSF_OnSpawn(iCid);

		return Plugin_Continue;
	}
	else if (infectedType == Infected_Jockey)
	{
		int iMaxHP = FindConVar("z_jockey_health").IntValue;
		if (GetEntProp(iCid, Prop_Data, "m_iHealth") > iMaxHP)
			SetEntProp(iCid, Prop_Data, "m_iHealth", iMaxHP);

		//set bot perks
		if (IsFakeClient(iCid))
		{
			g_ipInf[iCid].jockeyPerk = BotPickRandomJockeyPerk();
			g_bConfirm[iCid] = true;

			#if defined PM_DEBUG
			PrintToChatAll("\x03-jockey bot perk \x01%i", g_ipInf[iCid].jockeyPerk);
			#endif
		}

		#if defined PM_DEBUG
		PrintToChatAll("\x03spawned jockey \x01%i\x03 health \x01%i\x03, maxhp \x01%i", iCid, GetEntProp(iCid, Prop_Data,"m_iHealth"), iMaxHP );
		#endif
		Cavalier_OnSpawn(iCid);
		Ghost_OnSpawn(iCid);

		return Plugin_Continue;
	}
	else if (infectedType == Infected_Charger)
	{
		int iMaxHP = FindConVar("z_charger_health").IntValue;
		if (GetEntProp(iCid, Prop_Data, "m_iHealth") > iMaxHP)
			SetEntProp(iCid, Prop_Data, "m_iHealth", iMaxHP);

		#if defined PM_DEBUG
		PrintToChatAll("\x03charger spawned");
		#endif
		//set bot perks
		if (IsFakeClient(iCid))
		{
			g_ipInf[iCid].chargerPerk = BotPickRandomChargerPerk();
			g_bConfirm[iCid] = true;

			#if defined PM_DEBUG
			PrintToChatAll("\x03-charger bot perk \x01%i", g_ipInf[iCid].chargerPerk);
			#endif
		}

		#if defined PM_DEBUG
		PrintToChatAll("\x03spawned charger \x01%i\x03 health \x01%i\x03, maxhp \x01%i", iCid, GetEntProp(iCid, Prop_Data,"m_iHealth"), iMaxHP );
		#endif
		Scatter_OnSpawn(iCid);

		return Plugin_Continue;
	}

	return Plugin_Continue;
}

//if item that was picked up is a grenade type, set carried amount in var
Action Event_ItemPickup(Event event, const char[] name, bool dontBroadcast)
{
	int iCid = GetClientOfUserId(event.GetInt("userid"));
	if (iCid == 0 || g_bConfirm[iCid] == false)
		return Plugin_Continue;

	char stWpn[24];
	GetEventString(event, "item", stWpn, sizeof(stWpn));

	//check for grenadier perk
	Pyro_Pickup(iCid, stWpn);

	//check for pack rat perk
	PR_Pickup(iCid, stWpn);

	return Plugin_Continue;
}

//set default perks for connecting players
Action Event_PConnect(Event event, const char[] name, bool dontBroadcast)
{
	//stop if game is loading
	if (g_bIsLoading || g_bIsRoundStart)
		return Plugin_Continue;

	int iCid = GetClientOfUserId(event.GetInt("userid"));
	if (iCid == 0) return Plugin_Continue;

	//if any of the perks are set to 0, set default values
	if (g_spSur[iCid].firstPerk == SurvivorFirstPerk_Unknown)	g_spSur[iCid].firstPerk = PM_IntToSurvivorFirstPerkType(g_iSur1_default);
	if (g_spSur[iCid].secondPerk == SurvivorSecondPerk_Unknown) g_spSur[iCid].secondPerk = PM_IntToSurvivorSecondPerkType(g_iSur2_default);
	if (g_spSur[iCid].thirdPerk == SurvivorThirdPerk_Unknown)	g_spSur[iCid].thirdPerk = PM_IntToSurvivorThirdPerkType(g_iSur3_default);

	if (g_ipInf[iCid].boomerPerk == InfectedBoomerPerk_Unknown) 	g_ipInf[iCid].boomerPerk = PM_IntToInfectedBoomerPerkType(g_iInfBoomer_default);
	if (g_ipInf[iCid].tankPerk == InfectedTankPerk_Unknown)			g_ipInf[iCid].tankPerk = PM_IntToInfectedTankPerkType(g_iInfTank_default);
	if (g_ipInf[iCid].smokerPerk == InfectedSmokerPerk_Unknown)		g_ipInf[iCid].smokerPerk = PM_IntToInfectedSmokerPerkType(g_iInfSmoker_default);
	if (g_ipInf[iCid].hunterPerk == InfectedHunterPerk_Unknown)		g_ipInf[iCid].hunterPerk = PM_IntToInfectedHunterPerkType(g_iInfHunter_default);
	if (g_ipInf[iCid].jockeyPerk == InfectedJockeyPerk_Unknown)		g_ipInf[iCid].jockeyPerk = PM_IntToInfectedJockeyPerkType(g_iInfJockey_default);
	if (g_ipInf[iCid].spitterPerk == InfectedSpitterPerk_Unknown)	g_ipInf[iCid].spitterPerk = PM_IntToInfectedSpitterPerkType(g_iInfSpitter_default);
	if (g_ipInf[iCid].chargerPerk == InfectedChargerPerk_Unknown)	g_ipInf[iCid].chargerPerk = PM_IntToInfectedChargerPerkType(g_iInfCharger_default);

	g_bConfirm[iCid] = true;
	g_iMyDisabler[iCid] = -1;
	g_iMyDisableTarget[iCid] = -1;
	g_bPIncap[iCid] = false;
	g_iSpiritCooldown[iCid] = 0;
	g_iGren[iCid] = 0;
	g_iGrenThrow[iCid] = 0;
	g_iGrenType[iCid] = 0;
	g_iPyroTicks[iCid] = 0;

	return Plugin_Continue;
}

//reset perk values when disconnected
//closes timer for spirit cooldown
//and rebuilds DT registry
Action Event_PDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bIsLoading || g_bIsRoundStart)
		return Plugin_Continue;

	int iCid = GetClientOfUserId(event.GetInt("userid"));
	if (iCid == 0) return Plugin_Continue;

	g_spSur[iCid].ResetState();
	g_ipInf[iCid].ResetState();
	g_bConfirm[iCid] = false;

	g_iGren[iCid] = 0;
	g_iGrenThrow[iCid] = 0;
	g_iGrenType[iCid] = 0;
	g_iPyroTicks[iCid] = 0;
	g_iMyDisabler[iCid] = -1;
	g_iMyDisableTarget[iCid] = -1;
	g_bPIncap[iCid] = false;
	g_iSpiritCooldown[iCid] = 0;

	if (g_iSpiritTimer[iCid] != INVALID_HANDLE)
	{
		KillTimer(g_iSpiritTimer[iCid]);
		g_iSpiritTimer[iCid] = null;
	}

	RebuildAll();
	TwinSF_ResetShotCount(iCid);

	return Plugin_Continue;
}

//call menu on first spawn, otherwise set default values for bots
Action Event_PlayerFirstSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bIsLoading || g_bIsRoundStart)
		return Plugin_Continue;

	int iCid = GetClientOfUserId(event.GetInt("userid"));
	if (iCid == 0) return Plugin_Continue;

	if (g_bConfirm[iCid] == false && IsFakeClient(iCid) == false)
	{
		CreateTimer(3.0, Timer_ShowTopMenu, iCid);
		PrintHintText(iCid, "%t", "WelcomeMessageHint");
		PrintToChat(iCid, "\x03[SM] %t", "WelcomeMessageChat");
	}

	return Plugin_Continue;
}

//checks to show perks menu on roundstart
//and resets various vars to default
Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	//tell plugin to not run this function repeatedly until we're done
	if (g_bIsRoundStart)
		return Plugin_Continue;
	
	g_bIsRoundStart = true;

	#if defined PM_DEBUG
	PrintToChatAll("\x03round start detected");
	#endif

	//AutoExecConfig(false , "perkmod");

	for (int iI = 1; iI<=MaxClients; iI++)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x03-cycle %i", iI);
		#endif
		//reset vars related to spirit perk
		g_bPIncap[iI] = false;
		g_iSpiritCooldown[iI] = 0;
		//reset var related to pack rat perk
		g_bPRalreadyApplying[iI] = false;
		//reset var related to various hunter/smoker perks
		g_iMyDisabler[iI] = -1;
		g_iMyDisableTarget[iI] = -1;

		//reset var pointing to client's spirit timer
		//and close the timer handle
		if (g_iSpiritTimer[iI] != INVALID_HANDLE)
		{
			KillTimer(g_iSpiritTimer[iI]);
			g_iSpiritTimer[iI] = null;
		}

		TwinSF_ResetShotCount(iI);

		//before we run any functions on players
		//check if the game has any players to prevent
		//stupid error messages cropping up on the server
		if (IsServerProcessing() == false)
			return Plugin_Continue;

		//only run these commands if player is in-game
		if (IsClientInGame(iI))
		{
			//reset run speeds for martial artist
			SetEntityMoveType(iI, MOVETYPE_CUSTOM);
			SetEntDataFloat(iI, g_iLaggedMovementO, 1.0, true);

			if (IsFakeClient(iI)) continue;
			//show the perk menu if their perks are unconfirmed
			if (g_bConfirm[iI] == false)
				CreateTimer(3.0, Timer_ShowTopMenu, iI);
			//reset var related to blind luck perk
			//SendConVarValue(iI, hCvar,"0");
			SetEntProp(iI, Prop_Send, "m_iHideHUD", 0);
		}

	}

	ConVar hCvar;

	//reset vomit vars

	if (g_bInfBoomer_enable && g_bMotion_enable)
	{
		hCvar = FindConVar("z_vomit_fatigue");
		hCvar.RestoreDefault(false, false);
		g_flVomitFatigue = GetConVarFloat(hCvar);
	}

	//reset tongue vars

	if (g_bInfSmoker_enable && g_bTongue_enable)
	{
		hCvar = FindConVar("tongue_victim_max_speed");
		hCvar.RestoreDefault(false, false);
		g_flTongueSpeed = GetConVarFloat(hCvar);

		hCvar = FindConVar("tongue_range");
		hCvar.RestoreDefault(false, false);
		g_flTongueRange = GetConVarFloat(hCvar);

		hCvar = FindConVar("tongue_fly_speed");
		hCvar.RestoreDefault(false, false);
		g_flTongueFlySpeed=GetConVarFloat(hCvar);
	}

	if (g_bInfSmoker_enable && g_bDrag_enable)
	{
		FindConVar("tongue_allow_voluntary_release").RestoreDefault(false, false);

		hCvar = FindConVar("tongue_player_dropping_to_ground_time");
		hCvar.RestoreDefault(false, false);
		g_flTongueDropTime = GetConVarFloat(hCvar);
	}

	//reset tank attack intervals
	//and rock throw force

	//finally, clear DT and MA registry
	ClearAll();
	//recalculate DT and stopping power
	//permissions on game frame
	RunChecksAll();
	//reset boomer vars
	g_iSlimed		= 0;
	g_iSlimerLast	= 0;
	//reset tank vars
	g_iTank			= 0;
	g_iTankCount	= 0;

	//detect gamemode and difficulty
	char stArg[MAXPLAYERS+1];
	//next, check gamemode
	FindConVar("mp_gamemode").GetString(stArg, sizeof(stArg));

	if (StrEqual(stArg, "survival", false))
		g_L4D_GameMode = GameMode_Survival;
	else if (StringInsensitiveContains(stArg, "versus") || StringInsensitiveContains(stArg, "scavenge"))
		g_L4D_GameMode = GameMode_Versus;
	else
		g_L4D_GameMode = GameMode_Campaign;

	//start global timer that
	//forces bots to have some perks
	//among other things
	if (g_hTimerPerks != INVALID_HANDLE)
	{
		KillTimer(g_hTimerPerks);
		g_hTimerPerks = null;
	}
	g_hTimerPerks = CreateTimer(2.0, TimerPerks, 0, TIMER_REPEAT);

	//finally, tell plugin that loading is over and that roundstart can run again
	g_bIsRoundStart = false;
	g_bIsLoading = false;

	#if defined PM_DEBUG
	PrintToChatAll("\x03-end round start routine");
	#endif

	return Plugin_Continue;
}

//resets some temp vars related to perks
Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bIsLoading || g_bIsRoundStart)
		return Plugin_Continue;

	int iCid = GetClientOfUserId(event.GetInt("userid"));
	if (iCid == 0) return Plugin_Continue;

	//reset vars related to spirit perk
	g_iMyDisabler[iCid] = -1;
	g_iMyDisableTarget[iCid] = -1;
	g_bPIncap[iCid] = false;
	g_iSpiritCooldown[iCid] = 0;
	//and also close the spirit cooldown timer
	//and nullify the var pointing to it
	if (g_iSpiritTimer[iCid] != INVALID_HANDLE)
	{
		KillTimer(g_iSpiritTimer[iCid]);
		g_iSpiritTimer[iCid] = null;
	}
	TwinSF_ResetShotCount(iCid);

	if (IsClientInGame(iCid) && IsFakeClient(iCid) == false)
	{
		//reset var related to blind luck perk
		//SendConVarValue(iCid, FindConVar("sv_cheats"),"0");
		SetEntProp(iCid, Prop_Send, "m_iHideHUD", 0);
	}

	//rebuild registries for double tap and martial artist
	RebuildAll();

	//and while we're at it, the player just died so reset pyro's tick count
	g_iPyroTicks[iCid] = 0;

	//reset movement rate from martial artist
	SetEntDataFloat(iCid, g_iLaggedMovementO, 1.0, true);

	//Tank Routine
	//------------
	InfectedType infectedType = SM_IntToInfectedType(GetEntData(iCid, g_iClassO), g_bIsL4D2);

	#if defined PM_DEBUG
	PrintToChatAll("\x03player model: %s", infectedType);
	#endif
	//just because I'm not exactly sure...
	if (infectedType == Infected_Tank)
	{
		//if a tank is dead, recount the number of tanks left
		//start from zero...
		g_iTankCount = 0;
		//...and count up
		for (int iI = 1; iI<=MaxClients; iI++)
		{
			if (IsClientInGame(iI) && IsPlayerAlive(iI) && SM_GetClientTeamType(iI) == ClientTeam_Infected)
			{
				infectedType = SM_IntToInfectedType(GetEntData(iI, g_iClassO), g_bIsL4D2);
				if (infectedType == Infected_Tank)
					g_iTankCount++;

				#if defined PM_DEBUG
				PrintToChatAll("\x03-counting \x01%i", iI);
				#endif
			}
		}

		#if defined PM_DEBUG
		PrintToChatAll("\x03int g_iTankCount= \x01%i", g_iTankCount);
		#endif
		//if there are no more double trouble tanks, tell plugin there's no more tanks
		if (g_iTankCount == 0)
			g_iTank = 0;
		//if for some reason it goes below 0, reset vars
		else if (g_iTankCount < 0)
		{
			g_iTankCount = 0;
			g_iTank = 0;
		}

		#if defined PM_DEBUG
		PrintToChatAll("\x03-end tank death routine");
		#endif
	}

	#if defined PM_DEBUG
	PrintToChatAll("\x03end death routine for \x01%i", iCid);
	#endif

	return Plugin_Continue;
}

//sets confirm to 0 and redisplays perks menu
Action Event_PlayerTransitioned(Event event, const char[] name, bool dontBroadcast)
{
	int iCid = GetClientOfUserId(event.GetInt("userid"));
	if (iCid == 0) return Plugin_Continue;
	//reset their confirm perks var and show the menu
	g_bConfirm[iCid] = false;
	/*CreateTimer(1.0, Timer_ShowTopMenu, iCid);
	//since we just changed maps
	//reset everything for the spirit cooldown timer
	if (g_iSpiritTimer[iCid]!=INVALID_HANDLE)
	{
		KillTimer(g_iSpiritTimer[iCid]);
		g_iSpiritTimer[iCid]=INVALID_HANDLE;
	}*/

	return Plugin_Continue;
}

//resets everyone's confirm values on round end, mainly for survival and campaign
Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	#if defined PM_DEBUG
	PrintToChatAll("round end detected");
	#endif
	ClearAll();

	for (int iI = 1; iI<=MaxClients; iI++)
	{
		g_bConfirm[iI] = false;
	}

	if (g_hTimerPerks != INVALID_HANDLE)
	{
		KillTimer(g_hTimerPerks);
		g_hTimerPerks = null;
	}

	//tells plugin we're about to start loading
	g_bIsLoading = true;

	return Plugin_Continue;
}

//as round end function above
public void OnMapEnd()
{
	#if defined PM_DEBUG
	PrintToChatAll("map end detected");
	#endif
	ClearAll();

	for (int iI = 1; iI<=MaxClients; iI++)
	{
		g_bConfirm[iI] = false;
	}

	if (g_hTimerPerks != INVALID_HANDLE)
	{
		KillTimer(g_hTimerPerks);
		g_hTimerPerks = null;
	}

	//tells plugin we're about to start loading
	g_bIsLoading = true;
}

//Anything that uses a global timer for periodic
//checks is also called here; current functions called here:
//Sur2: Spirit
//Sur1: Pyrotechnician
//NOTE: called every 2 seconds
Action TimerPerks (Handle timer, any data)
{
	//if (IsServerProcessing() == false)
	//{
		//KillTimer(timer);
		//g_hTimerPerks = INVALID_HANDLE;
		//return Plugin_Stop;
	//}

	Spirit_Timer();
	Pyro_Timer();

	return Plugin_Continue;
}

//called on a player changing teams
//and rebuilds DT registry (and MA as well)
Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	#if defined PM_DEBUG
	PrintToChatAll("\x03change team detected");
	#endif
	if (g_bIsLoading || g_bIsRoundStart)
		return Plugin_Continue;

	int iCid = GetClientOfUserId(event.GetInt("userid"));
	if (iCid == 0 || IsValidEntity(iCid) == false || IsClientInGame(iCid) == false)
		return Plugin_Continue;

	//reset vars related to spirit perk
	g_bPIncap[iCid] = false;
	g_iSpiritCooldown[iCid] = 0;
	//reset var related to various hunter/smoker perks
	g_iMyDisabler[iCid] = -1;
	g_iMyDisableTarget[iCid] = -1;

	TwinSF_ResetShotCount(iCid);

	//reset var pointing to client's spirit timer
	//and close the timer handle
	if (g_iSpiritTimer[iCid] != INVALID_HANDLE)
	{
		KillTimer(g_iSpiritTimer[iCid]);
		g_iSpiritTimer[iCid] = null;
	}

	//reset runspeed
	SetEntDataFloat(iCid, g_iLaggedMovementO, 1.0, true);

	//reset blind perk sendprop
	if (IsFakeClient(iCid) == false)
		SetEntProp(iCid, Prop_Send, "m_iHideHUD", 0);

	//rebuild MA and DT registries
	CreateTimer(0.3, Delayed_Rebuild, 0);

	//only allow changes of perks if team change was
	//to or from the infected team (implying it's versus)
	if (PM_IntToClientTeam(event.GetInt("team")) == ClientTeam_Infected || PM_IntToClientTeam(event.GetInt("oldteam")) == ClientTeam_Infected)
	{
		g_bConfirm[iCid] = false;
		CreateTimer(1.0, Timer_ShowTopMenu, iCid);
		//apply perks if changing into survivors
		CreateTimer(0.3, Delayed_PerkChecks, iCid);
	}

	#if defined PM_DEBUG
	PrintToChatAll("\x03-end change team routine");
	#endif

	return Plugin_Continue;
}

//called when plugin is unloaded
//reset all the convars that had permission to run
public void OnPluginEnd()
{
	g_bIsRoundStart = true;
	g_bIsLoading = true;

	#if defined PM_DEBUG
	PrintToChatAll("\x03begin pluginend routine");
	#endif
	for (int iI = 1; iI<=MaxClients; iI++)
	{
		//reset var pointing to client's spirit timer
		//and close the timer handle
		if (g_iSpiritTimer[iI] != INVALID_HANDLE)
		{
			KillTimer(g_iSpiritTimer[iI]);
			g_iSpiritTimer[iI] = null;
		}

		//before we run any functions on players
		//check if the game has any players to prevent
		//stupid error messages cropping up on the server
		if (IsServerProcessing() == false)
			continue;

		//only run these commands if player is in-game
		if (IsClientInGame(iI))
		{
			//reset run speeds for martial artist
			SetEntDataFloat(iI, g_iLaggedMovementO, 1.0, true);

			//reset var related to blind luck perk
			//SendConVarValue(iI, hCvar,"0");
			SetEntProp(iI, Prop_Send, "m_iHideHUD", 0);
		}

	}

	ConVar hCvar;

	//reset vomit vars
	if (g_bInfBoomer_enable && g_bMotion_enable)
	{
		hCvar = FindConVar("z_vomit_fatigue");
		hCvar.RestoreDefault(false, false);
	}

	//reset tongue vars
	if (g_bInfSmoker_enable && g_bTongue_enable)
	{
		hCvar = FindConVar("tongue_victim_max_speed");
		hCvar.RestoreDefault(false, false);

		hCvar = FindConVar("tongue_range");
		hCvar.RestoreDefault(false, false);

		hCvar = FindConVar("tongue_fly_speed");
		hCvar.RestoreDefault(false, false);
	}

	if (g_bInfSmoker_enable && g_bDrag_enable)
	{
		FindConVar("tongue_allow_voluntary_release").RestoreDefault(false, false);

		hCvar = FindConVar("tongue_player_dropping_to_ground_time");
		hCvar.RestoreDefault(false, false);
	}

	//finally, clear DT and MA registry
	ClearAll();

	if (g_hTimerPerks != INVALID_HANDLE)
		KillTimer(g_hTimerPerks);
	g_hTimerPerks = null;

	g_bIsRoundStart = false;
	g_bIsLoading = false;

	#if defined PM_DEBUG
	PrintToChatAll("\x03-end pluginend routine");
	#endif
}

//=============================
// Misc. Perk Functions
//=============================

//This is a recently-added function adapted from the complex function I originally wrote
//for body slam. Simpler code I wrote for the other infected-to-survivor perks kept
//inadvertently killing the survivors when they weren't black-and-white... but since
//body slam never had that problem, I decided to use body slam's code to avoid that
//problem altogether... hence this giant function. However, since body slam doesn't fire
//if the original damage exceeds a minimum, it still has its own code.
void InfToSurDamageAdd(int iVic, int iDmgAdd, int iDmgOrig)
{
	//don't bother running if client id is zero
	//since sourcemod is intolerant of local servers
	//and if damage add is zero... why bother?
	if (iVic == 0 || iDmgAdd <= 0) return;

	int iHP = GetEntProp(iVic, Prop_Data, "m_iHealth");

	//CONDITION 1:
	//HEALTH > DMGADD
	//-----------------
	//if health>Min, then run normally
	//easiest condition, since we can
	//apply the damage directly to their hp
	if (iHP > iDmgAdd)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x03iHP>%i condition", iDmgAdd);
		#endif
		SetEntProp(iVic, Prop_Data,"m_iHealth", iHP-iDmgAdd );

		#if defined PM_DEBUG
		PrintToChatAll("\x03-%i bonus damage", iDmgAdd );
		#endif
		return;
	}

	//CONDITION 2:
	//HEALTH <= DMGADD
	//-----------------
	//otherwise, we gotta do a bit of work
	//if survivor's health is
	//less than or equal to 8
	else
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x03iHP<=%i condition", iDmgAdd);
		PrintToChatAll("\x03-pre-mod iHP: \x01%i", iHP);
		#endif

		float flHPBuff = GetEntDataFloat(iVic, g_iHPBuffO);

		//CONDITION 2A:
		//HEALTH <= DMGADD
		//&& BUFFER > 0
		//-----------------
		//if victim has health buffer,
		//we need to do some extra work
		//to reduce health buffer as well
		if (flHPBuff > 0)
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x03-flHPBuff>0 condition, pre-mod HPbuffer: \x01%f", flHPBuff);
			#endif
			//since we know the damage add exceeds
			//health, we need to take the difference
			//and apply it to health buffer instead

			//we leave the survivor with 1 health
			//because the engine will take it away
			//when it applies the original damage
			//and we want to avoid strange death behaviour
			//(which occurs if victim's health falls below 0)
			int iDmgCount = iHP - 1;
			iDmgAdd -= iDmgCount;
			SetEntProp(iVic, Prop_Data, "m_iHealth", iHP - iDmgCount);

			//and now we take the remainder of the
			//damage add and apply it to the health buffer.

			//if damage add is more than health buffer,
			//set damage add to health buffer amount
			int iHPBuff = RoundToFloor(flHPBuff);
			if (iHPBuff < iDmgAdd) iDmgAdd = iHPBuff;
			//and here we apply the damage to the buffer
			SetEntDataFloat(iVic, g_iHPBuffO, flHPBuff - iDmgAdd, true);

			//finally, set the proper value in the event info

			#if defined PM_DEBUG
			PrintToChatAll("\x03-damage to health: \x01%i\x03, current health: \x01%i", iDmgCount, GetEntProp(iVic, Prop_Data,"m_iHealth"));
			PrintToChatAll("\x03-damage to buffer: \x01%i\x03, current buffer: \x01%f", iDmgAdd, GetEntDataFloat(iVic, g_iHPBuffO));
			#endif

			return;
		}

		//CONDITION 2B:
		//HEALTH <= DMGADD
		//&& BUFFER <= 0
		//-----------------
		//without health buffer, it's straightforward
		//since we just need to apply however much
		//of the damage add we can to the victim's health
		else
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x03no temp hp condition");
			#endif
			//if original damage exceeds health,
			//just skip the rest since there's no
			//health buffer to worry about,
			//and the engine will incap or kill
			//the survivor anyways with the base damage
			if (iDmgOrig >= iHP) return;

			//to prevent strange death behaviour,
			//reduce damage add to less than that
			//of remaining health if necessary
			if (iDmgAdd >= iHP) iDmgAdd = iHP - 1;
			//and if this puts it below 0, just skip everything
			if (iDmgAdd < 0) return;

			SetEntProp(iVic, Prop_Data, "m_iHealth", iHP - iDmgAdd);

			#if defined PM_DEBUG
			PrintToChatAll("\x03-%i bonus damage", iDmgAdd );
			#endif
			return;
		}
	}
}


//just because Sourcemod's RoundToCeil and RoundToFloor functions are
//currently unreliable, I've just written my own workable version
//returns the damage add, randomly picks between higher and lower rounded value
int DamageAddRound (int iDmgOrig, float flDmgMult)
{
	//calculate the damage add
	int iDmgAdd;
	float flDmg = iDmgOrig * flDmgMult;
	int iDmgRound = RoundToNearest(flDmg);

	#if defined PM_DEBUG
	PrintToChatAll("\x03- fldmg \x01%f\x03 idmground \x01%i", flDmg, iDmgRound);
	#endif
	//if rounding error can occur...
	float flDmgDiff = iDmgRound - flDmg;
	//check if the rounded value is different from the actual value
	if (flDmgDiff != 0)
	{
		//if it is, check if we had rounded up
		if (flDmgDiff > 0)
		{
			//if it was rounded up, then randomize between the upper and lower value
			//and weigh it by each 0.1 amount the rounded value was off by
			if (GetRandomInt(1, 10) <= (flDmgDiff * 10))
				//since we rounded up earlier, just set dmgadd to rounded value
				iDmgAdd = iDmgRound;
			//otherwise, set the damage add to the rounded value minus 1
			else
				iDmgAdd = iDmgRound - 1;
		}
		//the other case is if we rounded down
		else
		{
			//same as above, except multiply it by a negative number to get the abs value
			if (GetRandomInt(1, 10) <= (flDmgDiff * (-10)))
				//since we rounded down earlier, set dmgadd to rounded value plus 1
				iDmgAdd = iDmgRound + 1;
			//otherwise, set the damage add to the rounded value
			else
				iDmgAdd = iDmgRound;
		}
	}
	//if the bonus damage is a clean integer value...
	else
	{
		//just use the value without further fussing
		iDmgAdd = iDmgRound;
	}

	//stop if damage add is <= 0
	if (iDmgAdd <= 0)
		return 0;

	#if defined PM_DEBUG
	PrintToChatAll("\x03- idmgadd \x01%i\x03, idmgorig \x01%i", iDmgAdd, iDmgOrig );
	#endif
	return iDmgAdd;
}

//on drying from slime, remove hud changes
//and lower count of people slimed (pungent)
Action PlayerNoLongerIt(Handle timer, any iCid)
{
	KillTimer(timer);
	if (IsServerProcessing() == false)
		return Plugin_Stop;

	if (IsClientInGame(iCid) && IsFakeClient(iCid) == false)
		SetEntProp(iCid, Prop_Send, "m_iHideHUD", 0);
		//SendConVarValue(iCid, FindConVar("sv_cheats"),"0");

	#if defined PM_DEBUG
	PrintToChatAll("\x03client \x01%i\x03 no longer it \n attempting to restore hud", iCid);
	#endif	//PrintToChatAll("\x03old g_iSlimed: \x01%i", g_iSlimed);

	if (g_iSlimed > 4) g_iSlimed = 3;
	else if (g_iSlimed < 0) g_iSlimed = 0;
	else g_iSlimed -- ;

	#if defined PM_DEBUG
	PrintToChatAll("\x03int g_iSlimed: \x01%i", g_iSlimed);
	#endif
	return Plugin_Stop;
}

Action Delayed_Rebuild(Handle timer, any data)
{
	KillTimer(timer);
	if (IsServerProcessing() == false)
		return Plugin_Continue;

	RebuildAll();

	return Plugin_Stop;
}

//delayed show menu to prevent weird not-showing on
//campaign round restarts...
//... since 1.3, also checks if force random perks server
//setting is on; if so, then assigns perks instead
Action Timer_ShowTopMenu(Handle timer, any iCid)
{
	KillTimer(timer);
	if (IsServerProcessing() == false || IsClientInGame(iCid) == false || IsFakeClient(iCid) || g_bIsLoading)
		return Plugin_Stop;

	if (g_hMenuAutoShow_enable.IntValue == 0)
		return Plugin_Stop;

	#if defined PM_DEBUG
	PrintToChatAll("\x03showing menu to \x01%i", iCid);
	#endif
	ClientTeamType clientTeam = SM_GetClientTeamType(iCid);

	//don't show menu if perks are disabled
	if ((g_bSurAll_enable == false && clientTeam == ClientTeam_Survivor) || (g_bInfAll_enable == false && clientTeam == ClientTeam_Infected))
	{
		g_bConfirm[iCid] = false;
		return Plugin_Stop;
	}

	if (g_bForceRandom == false)
	{
		//default case
		if (clientTeam == ClientTeam_Survivor)
			SendPanelToClient(Menu_Initial(iCid), iCid, Menu_ChooseInit, MENU_TIME_FOREVER);
		else if (clientTeam == ClientTeam_Infected)
			SendPanelToClient(Menu_Initial(iCid), iCid, Menu_ChooseInit_Inf, MENU_TIME_FOREVER);
	}
	else
		AssignRandomPerks(iCid);

	return Plugin_Stop;
}

Action Delayed_PerkChecks(Handle timer, any iCid)
{
	KillTimer(timer);
	if (IsServerProcessing() == false)
		return Plugin_Stop;

	if (IsClientConnected(iCid) == false || IsClientInGame(iCid) == false || SM_GetClientTeamType(iCid) != ClientTeam_Survivor)
		return Plugin_Stop;

	Event_Confirm_Unbreakable(iCid);
	Event_Confirm_Grenadier(iCid);
	Event_Confirm_ChemReliant(iCid);

	return Plugin_Stop;
}

void RunChecksAll()
{
	if (g_bIsLoading || g_bIsRoundStart)
		return;

	Stopping_RunChecks();
	DT_RunChecks();
	MA_RunChecks();
}

void RebuildAll()
{
	DT_Rebuild();
	MA_Rebuild();
	Adrenal_Rebuild();
	Extreme_Rebuild();
	Pyro_Rebuild();
}

//RebuildAll and ClearAll are only called on round starts,
//round ends, and plugin end, so yeah (important for Pyro's tick counter)
void ClearAll()
{
	DT_Clear();
	MA_Clear();
	Adrenal_Clear();
	Extreme_Rebuild();
	Pyro_Clear(true);
}

// MARK: - Random perks

void AssignRandomPerks(int iCid)
{
	//don't do anything if
	//the client id is whacked
	//or if confirm perks is set
	if (iCid > MaxClients || iCid <= 0 || g_bConfirm[iCid])
		return;

	int iPerkCount;

	//SUR1 PERK
	//---------
	SurvivorFirstPerkType firstPerkType[SurvivorFirstPerk_Count];
	iPerkCount = 0;

	//1 stopping power
	if (GameModeCheck(true, g_iStopping_enable))
	{
		firstPerkType[iPerkCount] = SurvivorFirstPerk_StoppingPower;
		iPerkCount++;
	}

	//2 double tap
	if (GameModeCheck(true, g_iDT_enable))
	{
		firstPerkType[iPerkCount] = SurvivorFirstPerk_DoubleTap;
		iPerkCount++;
	}

	//3 sleight of hand
	if (GameModeCheck(true, g_iSoH_enable))
	{
		firstPerkType[iPerkCount] = SurvivorFirstPerk_SleightOfHand;
		iPerkCount++;
	}

	//4 pyrotechnician
	if (GameModeCheck(true, g_iPyro_enable))
	{
		firstPerkType[iPerkCount] = SurvivorFirstPerk_Pyrotechnician;
		iPerkCount++;
	}

	//randomize a perk
	if (iPerkCount > 0)
		g_spSur[iCid].firstPerk = firstPerkType[GetRandomInt(1, iPerkCount)];

	//SUR2 PERK
	//---------
	SurvivorSecondPerkType secondPerkType[SurvivorSecondPerk_Count];
	iPerkCount = 0;

	//1 unbreakable
	if (GameModeCheck(true, g_iUnbreak_enable))
	{
		secondPerkType[iPerkCount] = SurvivorSecondPerk_Unbreakable;
		iPerkCount++;
	}

	//2 spirit
	if (GameModeCheck(true, g_iSpirit_enable))
	{
		secondPerkType[iPerkCount] = SurvivorSecondPerk_Spirit;
		iPerkCount++;
	}

	//3 helping hand
	if (GameModeCheck(true, g_iHelpHand_enable))
	{
		secondPerkType[iPerkCount] = SurvivorSecondPerk_HelpingHand;
		iPerkCount++;
	}

	//4 martial artist
	if (GameModeCheck(true, g_iMA_enable))
	{
		secondPerkType[iPerkCount] = SurvivorSecondPerk_MartialArtist;
		iPerkCount++;
	}

	//randomize a perk
	if (iPerkCount > 0)
		g_spSur[iCid].secondPerk = secondPerkType[GetRandomInt(1, iPerkCount)];

	//SUR3 PERK
	//------------------
	SurvivorThirdPerkType thirdPerkType[SurvivorThirdPerk_Count];
	iPerkCount = 0;

	//1 pack rat
	if (GameModeCheck(true, g_iPack_enable))
	{
		thirdPerkType[iPerkCount] = SurvivorThirdPerk_PackRat;
		iPerkCount++;
	}

	//2 chem reliant
	if (GameModeCheck(true, g_iChem_enable))
	{
		thirdPerkType[iPerkCount] = SurvivorThirdPerk_ChemReliant;
		iPerkCount++;
	}

	//3 hard to kill
	if (GameModeCheck(true, g_iHard_enable))
	{
		thirdPerkType[iPerkCount] = SurvivorThirdPerk_HardToKill;
		iPerkCount++;
	}

	//4 extreme conditioning
	if (GameModeCheck(true, g_iExtreme_enable))
	{
		thirdPerkType[iPerkCount] = SurvivorThirdPerk_ExtremeConditioning;
		iPerkCount++;
	}

	if (GameModeCheck(true, g_iLittle_enable))
	{
		thirdPerkType[iPerkCount] = SurvivorThirdPerk_LittleLeaguer;
		iPerkCount++;
	}

	//randomize a perk
	if (iPerkCount > 0)
		g_spSur[iCid].thirdPerk = thirdPerkType[ GetRandomInt(1, iPerkCount)];

	//------------------
	InfectedBoomerPerkType boomerPerkType[InfectedBoomerPerk_Count];
	iPerkCount = 0;

	//1 barf bagged
	if (g_iBarf_enable)
	{
		boomerPerkType[iPerkCount] = InfectedBoomerPerk_BarfBagged;
		iPerkCount++;
	}

	//2 blind luck
	if (g_iBlind_enable)
	{
		boomerPerkType[iPerkCount] = InfectedBoomerPerk_BlindLuck;
		iPerkCount++;
	}

	//3 dead wreckening
	if (g_bDead_enable)
	{
		boomerPerkType[iPerkCount] = InfectedBoomerPerk_DeadWreckening;
		iPerkCount++;
	}

	//4 motion sickness
	if (g_bMotion_enable)
	{
		boomerPerkType[iPerkCount] = InfectedBoomerPerk_MotionSickness;
		iPerkCount++;
	}

	//randomize a perk
	if (iPerkCount > 0)
		g_ipInf[iCid].boomerPerk = boomerPerkType[GetRandomInt(1, iPerkCount)];

	//------------------
	InfectedSmokerPerkType smokerPerkType[InfectedSmokerPerk_Count];
	iPerkCount = 0;

	//1 tongue twister
	if (g_bTongue_enable)
	{
		smokerPerkType[iPerkCount] = InfectedSmokerPerk_TongueTwister;
		iPerkCount++;
	}

	//2 squeezer
	if (g_bSqueezer_enable)
	{
		smokerPerkType[iPerkCount] = InfectedSmokerPerk_Squeezer;
		iPerkCount++;
	}

	//3 drag and drop
	if (g_bDrag_enable)
	{
		smokerPerkType[iPerkCount] = InfectedSmokerPerk_DragAndDrop;
		iPerkCount++;
	}

	if (g_bSmokeIt_enable)
	{
		smokerPerkType[iPerkCount] = InfectedSmokerPerk_SmokeIt;
		iPerkCount++;
	}

	//randomize a perk
	if (iPerkCount > 0)
		g_ipInf[iCid].smokerPerk = smokerPerkType[GetRandomInt(1, iPerkCount)];

	//------------------
	InfectedHunterPerkType hunterPerkType[InfectedHunterPerk_Count];
	iPerkCount = 0;

	//1 body slam
	if (g_bBody_enable)
	{
		hunterPerkType[iPerkCount] = InfectedHunterPerk_BodySlam;
		iPerkCount++;
	}

	//2 efficient killer
	if (g_bEfficient_enable)
	{
		hunterPerkType[iPerkCount] = InfectedHunterPerk_EfficientKiller;
		iPerkCount++;
	}

	//3 grasshopper
	if (g_bGrass_enable)
	{
		hunterPerkType[iPerkCount] = InfectedHunterPerk_Grasshopper;
		iPerkCount++;
	}

	//4 speed demon
	if (g_bSpeedDemon_enable)
	{
		hunterPerkType[iPerkCount] = InfectedHunterPerk_SpeedDemon;
		iPerkCount++;
	}

	//randomize a perk
	if (iPerkCount > 0)
		g_ipInf[iCid].hunterPerk = hunterPerkType[GetRandomInt(1, iPerkCount)];

	//------------------
	InfectedJockeyPerkType jockeyPerkType[InfectedJockeyPerk_Count];
	iPerkCount = 0;

	//1 wind
	if (g_bWind_enable)
	{
		jockeyPerkType[iPerkCount] = InfectedJockeyPerk_Wind;
		iPerkCount++;
	}

	//2 cavalier
	if (g_bCavalier_enable)
	{
		jockeyPerkType[iPerkCount] = InfectedJockeyPerk_Cavalier;
		iPerkCount++;
	}

	//3 frogger
	if (g_bFrogger_enable)
	{
		jockeyPerkType[iPerkCount] = InfectedJockeyPerk_Frogger;
		iPerkCount++;
	}

	//4 ghost
	if (g_bGhost_enable)
	{
		jockeyPerkType[iPerkCount] = InfectedJockeyPerk_Ghost;
		iPerkCount++;
	}

	//randomize a perk
	if (iPerkCount > 0)
		g_ipInf[iCid].jockeyPerk = jockeyPerkType[GetRandomInt(1, iPerkCount)];

	//------------------
	InfectedSpitterPerkType spitterPerkType[InfectedSpitterPerk_Count];
	iPerkCount = 0;

	//1 twin spitfire
	if (g_bTwinSF_enable)
	{
		spitterPerkType[iPerkCount] = InfectedSpitterPerk_TwinSpitfire;
		iPerkCount++;
	}

	//2 mega adhesive
	if (g_bMegaAd_enable)
	{
		spitterPerkType[iPerkCount] = InfectedSpitterPerk_MegaAdhesive;
		iPerkCount++;
	}

	//randomize a perk
	if (iPerkCount > 0)
		g_ipInf[iCid].spitterPerk = spitterPerkType[GetRandomInt(1, iPerkCount)];

	//------------------
	InfectedChargerPerkType chargerPerkType[InfectedChargerPerk_Count];
	iPerkCount = 0;

	//1 scatter
	if (g_bScatter_enable)
	{
		chargerPerkType[iPerkCount] = InfectedChargerPerk_Scatter;
		iPerkCount++;
	}

	//2 bullet
	if (g_bBullet_enable)
	{
		chargerPerkType[iPerkCount] = InfectedChargerPerk_Bullet;
		iPerkCount++;
	}

	//randomize a perk
	if (iPerkCount > 0)
		g_ipInf[iCid].chargerPerk = chargerPerkType[GetRandomInt(1, iPerkCount)];

	//----------------
	InfectedTankPerkType tankPerkType[InfectedTankPerk_Count];
	iPerkCount = 0;

	//1 adrenal glands
	if (g_bAdrenal_enable)
	{
		tankPerkType[iPerkCount] = InfectedTankPerk_AdrenalGlands;
		iPerkCount++;
	}

	//2 Juggernaut
	if (g_bJuggernaut_enable)
	{
		tankPerkType[iPerkCount] = InfectedTankPerk_Juggernaut;
		iPerkCount++;
	}

	//3 metabolic boost
	if (g_bMetabolic_enable)
	{
		tankPerkType[iPerkCount] = InfectedTankPerk_MetabolicBoost;
		iPerkCount++;
	}

	//4 stormcaller
	if (g_bStorm_enable)
	{
		tankPerkType[iPerkCount] = InfectedTankPerk_Stormcaller;
		iPerkCount++;
	}

	//5 double the trouble
	if (g_iDouble_enable)
	{
		tankPerkType[iPerkCount] = InfectedTankPerk_DoubleTrouble;
		iPerkCount++;
	}

	//randomize a perk
	if (iPerkCount > 0)
		g_ipInf[iCid].tankPerk = tankPerkType[GetRandomInt(1, iPerkCount)];

	//finally, confirm perks
	//and run the necessary functions
	//as if the player had confirmed
	//their perks through the traditional way
	g_bConfirm[iCid] = true;
	Event_Confirm_Unbreakable(iCid);
	Event_Confirm_Grenadier(iCid);
	Event_Confirm_ChemReliant(iCid);
	Event_Confirm_DT(iCid);
	Event_Confirm_MA(iCid);
	Extreme_Rebuild();

	//lastly, show a panel to the player
	//showing what perks they were given
	SendPanelToClient(Menu_ShowChoices(iCid), iCid, Menu_DoNothing, 15);
}

//picks a random perk for bots
SurvivorFirstPerkType BotPickRandomSurvivorFirstPerk()
{
	//stop if sur1 perks are disabled
	if (g_bSur1_enable == false) return SurvivorFirstPerk_Unknown;

	SurvivorFirstPerkType iPerkType[SurvivorFirstPerk_Count];
	int iPerkCount = 0;

	char stPerk[24];
	if (g_hBot_Sur1 != INVALID_HANDLE)
		GetConVarString(g_hBot_Sur1, stPerk, sizeof(stPerk));
	else
		stPerk = "1, 2, 3, 4";

	if (StringInsensitiveContains(stPerk, "1") && GameModeCheck(true, g_iStopping_enable))
	{
		iPerkType[iPerkCount] = SurvivorFirstPerk_StoppingPower;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "2") && GameModeCheck(true, g_iDT_enable))
	{
		iPerkType[iPerkCount] = SurvivorFirstPerk_DoubleTap;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "3") && GameModeCheck(true, g_iSoH_enable))
	{
		iPerkType[iPerkCount] = SurvivorFirstPerk_SleightOfHand;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "4") && GameModeCheck(true, g_iPyro_enable))
	{
		iPerkType[iPerkCount] = SurvivorFirstPerk_Pyrotechnician;
		iPerkCount++;
	}

	//randomize
	if (iPerkCount > 0)
		return iPerkType[GetRandomInt(1, iPerkCount)];
	else
		return SurvivorFirstPerk_Unknown;
}

SurvivorSecondPerkType BotPickRandomSurvivorSecondPerk()
{
	//stop if sur2 perks are disabled
	if (g_bSur2_enable == false) return SurvivorSecondPerk_Unknown;

	SurvivorSecondPerkType iPerkType[SurvivorSecondPerk_Count];
	int iPerkCount = 0;

	char stPerk[24];
	if (g_hBot_Sur2 != INVALID_HANDLE)
		GetConVarString(g_hBot_Sur2, stPerk, sizeof(stPerk));
	else
		stPerk = "1, 2, 3, 4";

	if (StringInsensitiveContains(stPerk, "1") && GameModeCheck(true, g_iUnbreak_enable))
	{
		iPerkType[iPerkCount] = SurvivorSecondPerk_Unbreakable;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "2") && GameModeCheck(true, g_iSpirit_enable))
	{
		iPerkType[iPerkCount] = SurvivorSecondPerk_Spirit;
		iPerkCount++;
	}

	//helping hand
	if (StringInsensitiveContains(stPerk, "3") && GameModeCheck(true, g_iHelpHand_enable))
	{
		iPerkType[iPerkCount] = SurvivorSecondPerk_HelpingHand;
		iPerkCount++;
	}

	//martial artist
	if (StringInsensitiveContains(stPerk, "4") && GameModeCheck(true, g_iMA_enable))
	{
		iPerkType[iPerkCount] = SurvivorSecondPerk_MartialArtist;
		iPerkCount++;
	}

	//randomize
	if (iPerkCount > 0)
		return iPerkType[GetRandomInt(1, iPerkCount)];
	else
		return SurvivorSecondPerk_Unknown;
}

SurvivorThirdPerkType BotPickRandomSurvivorThirdPerk()
{
	//stop if sur2 perks are disabled
	if (g_bSur3_enable == false) return SurvivorThirdPerk_Unknown;

	SurvivorThirdPerkType iPerkType[SurvivorThirdPerk_Count];
	int iPerkCount = 0;

	char stPerk[24];
	if (g_hBot_Sur3 != INVALID_HANDLE)
		GetConVarString(g_hBot_Sur3, stPerk, sizeof(stPerk));
	else
		stPerk = "1, 2, 3";

	if (StringInsensitiveContains(stPerk, "1") && GameModeCheck(true, g_iPack_enable))
	{
		iPerkType[iPerkCount] = SurvivorThirdPerk_PackRat;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "2") && GameModeCheck(true, g_iChem_enable))
	{
		iPerkType[iPerkCount] = SurvivorThirdPerk_ChemReliant;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "3") && GameModeCheck(true, g_iHard_enable))
	{
		iPerkType[iPerkCount] = SurvivorThirdPerk_HardToKill;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "4") && GameModeCheck(true, g_iExtreme_enable))
	{
		iPerkType[iPerkCount] = SurvivorThirdPerk_ExtremeConditioning;
		iPerkCount++;
	}

	//randomize
	if (iPerkCount > 0)
		return iPerkType[GetRandomInt(1, iPerkCount)];
	else
		return SurvivorThirdPerk_Unknown;
}

// MARK: - Random infected perks

InfectedSmokerPerkType BotPickRandomSmokerPerk()
{
	//stop if smoker perks are disabled
	if (g_bInfSmoker_enable == false) return InfectedSmokerPerk_Unknown;

	InfectedSmokerPerkType iPerkType[InfectedSmokerPerk_Count];
	int iPerkCount = 0;

	char stPerk[24];
	if (g_hBot_inf_smoker != INVALID_HANDLE)
		GetConVarString(g_hBot_inf_smoker, stPerk, sizeof(stPerk));
	else
		stPerk = "1, 2, 3";

	if (StringInsensitiveContains(stPerk, "1") && g_bTongue_enable)
	{
		iPerkType[iPerkCount] = InfectedSmokerPerk_TongueTwister;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "2") && g_bSqueezer_enable)
	{
		iPerkType[iPerkCount] = InfectedSmokerPerk_Squeezer;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "3") && g_bDrag_enable)
	{
		iPerkType[iPerkCount] = InfectedSmokerPerk_DragAndDrop;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "4") && g_hSmokeIt_enable)
	{
		iPerkType[iPerkCount] = InfectedSmokerPerk_SmokeIt;
		iPerkCount++;
	}

	//randomize
	if (iPerkCount > 0)
		return iPerkType[GetRandomInt(1, iPerkCount)];
	else
		return InfectedSmokerPerk_Unknown;
}

InfectedBoomerPerkType BotPickRandomBoomerPerk()
{
	//stop if boomer perks are disabled
	if (g_bInfBoomer_enable == false) return InfectedBoomerPerk_Unknown;

	#if defined PM_DEBUG
	PrintToChatAll("\x03begin random perk for boomer");
	#endif

	InfectedBoomerPerkType iPerkType[InfectedBoomerPerk_Count];
	int iPerkCount = 0;

	char stPerk[24];
	if (g_hBot_inf_boomer != INVALID_HANDLE)
		GetConVarString(g_hBot_inf_boomer, stPerk, sizeof(stPerk));
	else
		stPerk = "1, 2, 3";

	#if defined PM_DEBUG
	PrintToChatAll("\x03-stPerk: \x01%s", stPerk);
	#endif

	if (StringInsensitiveContains(stPerk, "1") && g_iBarf_enable)
	{
		iPerkType[iPerkCount] = InfectedBoomerPerk_BarfBagged;
		iPerkCount++;

		#if defined PM_DEBUG
		PrintToChatAll("\x03-count \x01%i\x03, type \x01%i", iPerkCount, iPerkType[iPerkCount]);
		#endif
	}

	if (StringInsensitiveContains(stPerk, "2") && g_iBlind_enable)
	{
		iPerkType[iPerkCount] = InfectedBoomerPerk_BlindLuck;
		iPerkCount++;

		#if defined PM_DEBUG
		PrintToChatAll("\x03-count \x01%i\x03, type \x01%i", iPerkCount, iPerkType[iPerkCount]);
		#endif
	}

	//dead wreckening
	if (StringInsensitiveContains(stPerk, "3") && g_bDead_enable)
	{
		iPerkType[iPerkCount] = InfectedBoomerPerk_DeadWreckening;
		iPerkCount++;

		#if defined PM_DEBUG
		PrintToChatAll("\x03-count \x01%i\x03, type \x01%i", iPerkCount, iPerkType[iPerkCount]);
		#endif
	}

	if (StringInsensitiveContains(stPerk, "4") && g_hMotion_enable)
	{
		iPerkType[iPerkCount] = InfectedBoomerPerk_MotionSickness;
		iPerkCount++;
	}

	//randomize
	InfectedBoomerPerkType iReturn;
	if (iPerkCount > 0)
		iReturn = iPerkType[GetRandomInt(1, iPerkCount)];
	else
		iReturn = InfectedBoomerPerk_Unknown;

	#if defined PM_DEBUG
	PrintToChatAll("\x03-returning \x01%i", iReturn);
	#endif

	return iReturn;
}

InfectedHunterPerkType BotPickRandomHunterPerk()
{
	//stop if hunter perks are disabled
	if (g_bInfHunter_enable == false) return InfectedHunterPerk_Unknown;

	InfectedHunterPerkType iPerkType[InfectedHunterPerk_Count];
	int iPerkCount = 0;

	char stPerk[24];
	if (g_hBot_inf_hunter != INVALID_HANDLE)
		GetConVarString(g_hBot_inf_hunter, stPerk, sizeof(stPerk));
	else
		stPerk = "2, 4";

	if (StringInsensitiveContains(stPerk, "1") && g_hBody_enable)
	{
		iPerkType[iPerkCount] = InfectedHunterPerk_BodySlam;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "2") && g_bEfficient_enable)
	{
		iPerkType[iPerkCount] = InfectedHunterPerk_EfficientKiller;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "3") && g_hGrass_enable)
	{
		iPerkType[iPerkCount] = InfectedHunterPerk_Grasshopper;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "4") && g_bSpeedDemon_enable)
	{
		iPerkType[iPerkCount] = InfectedHunterPerk_SpeedDemon;
		iPerkCount++;
	}

	//randomize
	if (iPerkCount > 0)
		return iPerkType[GetRandomInt(1, iPerkCount)];
	else
		return InfectedHunterPerk_Unknown;
}

InfectedSpitterPerkType BotPickRandomSpitterPerk()
{
	//stop if spitter perks are disabled
	if (g_bInfSpitter_enable == false) return InfectedSpitterPerk_Unknown;

	InfectedSpitterPerkType iPerkType[InfectedSpitterPerk_Count];
	int iPerkCount = 0;

	char stPerk[24];
	if (g_hBot_inf_spitter != INVALID_HANDLE)
		GetConVarString(g_hBot_inf_spitter, stPerk, sizeof(stPerk));
	else
		stPerk = "1, 2";

	if (StringInsensitiveContains(stPerk, "1") && g_bTwinSF_enable)
	{
		iPerkType[iPerkCount] = InfectedSpitterPerk_TwinSpitfire;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "2") && g_bMegaAd_enable)
	{
		iPerkType[iPerkCount] = InfectedSpitterPerk_MegaAdhesive;
		iPerkCount++;
	}

	//randomize
	if (iPerkCount > 0)
		return iPerkType[GetRandomInt(1, iPerkCount)];
	else
		return InfectedSpitterPerk_Unknown;
}

InfectedJockeyPerkType BotPickRandomJockeyPerk()
{
	//stop if jockey perks are disabled
	if (g_bInfJockey_enable == false) return InfectedJockeyPerk_Unknown;

	InfectedJockeyPerkType iPerkType[InfectedJockeyPerk_Count];
	int iPerkCount = 0;

	char stPerk[24];
	if (g_hBot_inf_jockey != INVALID_HANDLE)
		GetConVarString(g_hBot_inf_jockey, stPerk, sizeof(stPerk));
	else
		stPerk = "1, 2, 3, 4";

	if (StringInsensitiveContains(stPerk, "1") && g_bWind_enable)
	{
		iPerkType[iPerkCount] = InfectedJockeyPerk_Wind;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "2") && g_bCavalier_enable)
	{
		iPerkType[iPerkCount] = InfectedJockeyPerk_Cavalier;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "3") && g_bFrogger_enable)
	{
		iPerkType[iPerkCount] = InfectedJockeyPerk_Frogger;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "4") && g_bGhost_enable)
	{
		iPerkType[iPerkCount] = InfectedJockeyPerk_Ghost;
		iPerkCount++;
	}

	//randomize
	if (iPerkCount > 0)
		return iPerkType[GetRandomInt(1, iPerkCount)];
	else
		return InfectedJockeyPerk_Unknown;
}

InfectedChargerPerkType BotPickRandomChargerPerk()
{
	//stop if charger perks are disabled
	if (g_bInfCharger_enable == false) return InfectedChargerPerk_Unknown;

	InfectedChargerPerkType iPerkType[InfectedChargerPerk_Count];
	int iPerkCount = 0;

	char stPerk[24];
	if (g_hBot_inf_charger != INVALID_HANDLE)
		GetConVarString(g_hBot_inf_charger, stPerk, sizeof(stPerk));
	else
		stPerk = "1, 2";

	if (StringInsensitiveContains(stPerk, "1") && g_bScatter_enable)
	{
		iPerkType[iPerkCount] = InfectedChargerPerk_Scatter;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "2") && g_bBullet_enable)
	{
		iPerkType[iPerkCount] = InfectedChargerPerk_Bullet;
		iPerkCount++;
	}

	//randomize
	if (iPerkCount > 0)
		return iPerkType[GetRandomInt(1, iPerkCount)];
	else
		return InfectedChargerPerk_Unknown;
}

InfectedTankPerkType BotPickRandomTankPerk()
{
	//stop if tank perks are disabled
	if (g_bInfTank_enable == false) return InfectedTankPerk_Unknown;

	InfectedTankPerkType iPerkType[InfectedTankPerk_Count];
	int iPerkCount = 0;

	char stPerk[24];
	if (g_hBot_inf_tank != INVALID_HANDLE)
		GetConVarString(g_hBot_inf_tank, stPerk, sizeof(stPerk));
	else
		stPerk = "1, 2, 3, 4, 5";

	if (StringInsensitiveContains(stPerk, "1") && g_bAdrenal_enable)
	{
		iPerkType[iPerkCount] = InfectedTankPerk_AdrenalGlands;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "2") && g_bJuggernaut_enable)
	{
		iPerkType[iPerkCount] = InfectedTankPerk_Juggernaut;
		iPerkCount++;
	}

	if (StringInsensitiveContains(stPerk, "3") && g_bMetabolic_enable)
	{
		iPerkType[iPerkCount] = InfectedTankPerk_MetabolicBoost;
		iPerkCount++;
	}

	//storm caller
	if (StringInsensitiveContains(stPerk, "4") && g_bStorm_enable)
	{
		iPerkType[iPerkCount] = InfectedTankPerk_Stormcaller;
		iPerkCount++;
	}

	//double trouble
	if (StringInsensitiveContains(stPerk, "5") && g_iDouble_enable)
	{
		iPerkType[iPerkCount] = InfectedTankPerk_DoubleTrouble;
		iPerkCount++;
	}

	//randomize
	if (iPerkCount > 0)
		return iPerkType[GetRandomInt(1, iPerkCount)];
	else
		return InfectedTankPerk_Unknown;
}

//=============================
// MARK: - Sur1: Stopping Power
//=============================

//pre-calculates whether stopping power should
//run, since damage events can occur pretty often
void Stopping_RunChecks()
{
	g_bStopping_meta_enable = GameModeCheck(g_bSur1_enable, g_iStopping_enable);
}

//main damage add function
bool Stopping_DamageAdd(int iAtt, int iVic, ClientTeamType iTA, int iDmgOrig, const char[] stWpn)
{
	//check if perk is disabled
	if (!g_bStopping_meta_enable) return true;

	if (iTA == ClientTeam_Survivor
		&& g_spSur[iAtt].firstPerk == SurvivorFirstPerk_StoppingPower
		&& g_bConfirm[iAtt]
		&& SM_GetClientTeamType(iVic) != ClientTeam_Survivor)
	{
		if (StrEqual(stWpn, "melee", false))
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x03melee weapon detected, not firing");
			#endif
			return true;
		}

		int iDmgAdd = RoundToNearest(iDmgOrig * g_flStopping_dmgmult);
		int iHP = GetEntProp(iVic, Prop_Data, "m_iHealth");
		//to prevent strange death behaviour,
		//only deal the full damage add if health > damage add
		if (iHP > iDmgAdd) {
			SetEntProp(iVic, Prop_Data, "m_iHealth", iHP-iDmgAdd);
		}
		//if health < damage add, only deal health-1 damage
		else
		{
			iDmgAdd = iHP - 1;
			//don't bother if the modified damage add
			//ends up being an insignificant amount
			if (iDmgAdd < 0)
				return true;
			SetEntProp(iVic, Prop_Data, "m_iHealth", iHP-iDmgAdd);
		}

		return true;
	}

	return false;
}

//against common infected
Action Event_InfectedHurtPre(Event event, const char[] name, bool dontBroadcast)
{
	int iCid = GetClientOfUserId(event.GetInt("attacker"));

	if (iCid == 0 || g_bConfirm[iCid] == false)
		return Plugin_Continue;

	//check if perk is disabled
	if (!g_bStopping_meta_enable)
		return Plugin_Continue;

	if (g_spSur[iCid].firstPerk == SurvivorFirstPerk_StoppingPower && SM_GetClientTeamType(iCid) == ClientTeam_Survivor)
	{
		int iEntid = event.GetInt("entityid");
		int i_odmg = event.GetInt("amount");
		int i_dmga = RoundToNearest(i_odmg * g_flStopping_dmgmult);

		#if defined PM_DEBUG
		PrintToChatAll("\x03Pre-mod damage: \x01%i, \x03pre-mod health: \x01%i", event.GetInt("amount"), GetEntProp(iEntid, Prop_Data,"m_iHealth"));
		#endif
		SetEntProp(iEntid, Prop_Data,"m_iHealth", GetEntProp(iEntid, Prop_Data,"m_iHealth")-i_dmga );
		//******SetEventInt(event,"dmg_health", i_odmg+i_dmga );

		#if defined PM_DEBUG
		PrintToChatAll("\x03Post-mod damage: \x01%i, \x03post-mod health: \x01%i", event.GetInt("amount"), GetEntProp(iEntid, Prop_Data,"m_iHealth"));
		#endif
	}

	return Plugin_Continue;
}

//=============================
// MARK: - Sur1: Double Tap
//=============================

//called on round starts and on convar changes
//does the checks to determine whether DT
//should be run every game frame
void DT_RunChecks()
{
	g_bDT_meta_enable = GameModeCheck(g_bSur1_enable, g_iDT_enable);
}

//called on confirming perks
//simply adds player to registry of DT users
void Event_Confirm_DT(int iCid)
{
	if (g_iDTRegisterCount < 0) g_iDTRegisterCount = 0;

	if (IsClientInGame(iCid)
		&& IsPlayerAlive(iCid)
		&& g_spSur[iCid].firstPerk == SurvivorFirstPerk_DoubleTap
		&& g_bConfirm[iCid] == true
		&& SM_GetClientTeamType(iCid) == ClientTeam_Survivor)
	{
		g_iDTRegisterCount++;
		g_iDTRegisterIndex[g_iDTRegisterCount] = iCid;

		#if defined PM_DEBUG
		PrintToChatAll("\x03double tap on confirm, registering \x01%i", iCid);
		#endif
	}
}

//called whenever the registry needs to be rebuilt
//to cull any players who have left or died, etc.
//(called on: player death, player disconnect,
//closet rescue, change teams)
void DT_Rebuild()
{
	//clears all DT-related vars
	DT_Clear();

	//if the server's not running or
	//is in the middle of loading, stop
	if (IsServerProcessing() == false)
		return;

	#if defined PM_DEBUG
	PrintToChatAll("\x03double tap rebuilding registry");
	#endif
	for (int iI = 1 ; iI<=MaxClients ; iI++)
	{
		if (IsClientInGame(iI)
			&& IsPlayerAlive(iI)
			&& g_spSur[iI].firstPerk == SurvivorFirstPerk_DoubleTap
			&& g_bConfirm[iI]
			&& SM_GetClientTeamType(iI) == ClientTeam_Survivor)
		{
			g_iDTRegisterCount++;
			g_iDTRegisterIndex[g_iDTRegisterCount]=iI;

			#if defined PM_DEBUG
			PrintToChatAll("\x03-registering \x01%i", iI);
			#endif
		}
	}
}

//called to clear out DT registry
//(called on: round start, round end, map end)
void DT_Clear()
{
	g_iDTRegisterCount=0;
	for (int iI = 1 ; iI<=MaxClients ; iI++)
	{
		g_iDTRegisterIndex[iI]= -1;
		g_iDTEntid[iI] = -1;
		g_flDTNextTime[iI]= -1.0;
		g_bDTsemiauto[iI] = false;
	}
}

//this is the big momma!
//since this is called EVERY game frame,
//we need to be careful not to run too many functions
//kinda hard, though, considering how many things
//we have to check for =.=
void DT_OnGameFrame()
{
	//or if no one has DT, don't bother either
	if (g_iDTRegisterCount == 0)
		return;

	//stop if perk is disabled
	if (g_bDT_meta_enable == false)
		return;

	//this tracks the player's id, just to
	//make life less painful...
	int iCid;
	//this tracks the player's gun id
	//since we adjust numbers on the gun,
	//not the player
	int iEntid;
	//this tracks the calculated next attack
	float flNextTime_calc;
	//this, on the other hand, tracks the current next attack
	float flNextTime_ret;
	//and this tracks next melee attack times
	float flNextTime2_ret;
	//and this tracks the game time
	float flGameTime = GetGameTime();

	//theoretically, to get on the DT registry
	//all the necessary checks would have already
	//been run, so we don't bother with any checks here
	for (int iI = 1; iI <= g_iDTRegisterCount; iI++)
	{
		//PRE-CHECKS: RETRIEVE VARS
		//-------------------------

		iCid = g_iDTRegisterIndex[iI];
		//stop on this client
		//when the next client id is null
		if (iCid <= 0 || IsValidEntity(iCid) == false)
			return;
		//skip this client if they're disabled
		//if (g_iMyDisabler[iCid] != -1) continue;

		//we have to adjust numbers on the gun, not the player
		//so we get the active weapon id here
		iEntid = GetEntDataEnt2(iCid, g_iActiveWO);
		//if the retrieved gun id is -1, then...
		//wtf mate? just move on
		if (iEntid == -1 || IsValidEntity(iEntid) == false)
			continue;

		//----DEBUG----
		/*
		int iNextAttO = 	FindSendPropInfo("CTerrorPlayer","m_flNextAttack");
		int iIdleTimeO = 	FindSendPropInfo("CTerrorGun","m_flTimeWeaponIdle");
		PrintToChatAll("\x03DT, NextAttack \x01%i %f\x03, TimeIdle \x01%i %f",
			iNextAttO,
			GetEntDataFloat(iCid, iNextAttO),
			iIdleTimeO,
			GetEntDataFloat(iEntid, iIdleTimeO)
			);
		*/


		//PRE-CHECK 1
		//-----------
		int iEntid_stored = g_iDTEntid[iCid];
		float flNextTime_stored = g_flDTNextTime[iCid];
		//and here is the retrieved next attack time
		flNextTime_ret = GetEntDataFloat(iEntid, g_iNextPAttO);


		//CHECK 1: BEFORE ADJUSTED SHOT IS MADE
		//------------------------------------
		//since this will probably be the case most of
		//the time, we run this first
		//checks: gun is unchanged; time of shot has not passed
		//actions: skip this player
		if (iEntid_stored == iEntid && flNextTime_stored >= flNextTime_ret)
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x03DT client \x01%i\x03; before shot made", iCid );
			#endif
			continue;
		}

		//PRE-CHECK 2
		//-----------
		//and for retrieved next melee time
		flNextTime2_ret = GetEntDataFloat(iEntid, g_iNextSAttO);

		//CHECK 2: INFER IF MELEEING
		//--------------------------
		//since we don't want to shorten the interval
		//incurred after shoving, we try to guess when
		//a melee attack is made
		//checks: if melee attack time > engine time
		//actions: skip this player
		if (flNextTime2_ret > flGameTime)
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x03DT client \x01%i\x03; melee attack inferred", iCid );
			#endif
			g_flDTNextTime[iCid]=flNextTime_ret;

			continue;
		}

		//CHECK 3: AFTER ADJUSTED SHOT IS MADE
		//------------------------------------
		//at this point, either a gun was swapped, or
		//the attack time needs to be adjusted
		//checks: stored gun id same as retrieved gun id,
		// and retrieved next attack time is after stored value
		if (iEntid_stored == iEntid && flNextTime_stored < flNextTime_ret)
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x03DT after adjusted shot\n-pre, client \x01%i\x03; entid \x01%i\x03; enginetime\x01 %f\x03; NextTime_orig \x01 %f\x03; interval \x01%f", iCid, iEntid, flGameTime, flNextTime_ret, flNextTime_ret-flGameTime );
			#endif
			//first, check if the weapon is a valid semi-auto
			//these checks are run on CHECK 4 below
			if (g_bDTsemiauto[iCid] == false)
			{
				#if defined PM_DEBUG
				PrintToChatAll("\x03 - non semi auto used!");
				#endif
				continue;
			}

			//this is a calculation of when the next primary attack
			//will be after applying double tap values
			flNextTime_calc = ( flNextTime_ret - flGameTime ) * g_flDT_rate + flGameTime;

			//then we store the value
			g_flDTNextTime[iCid] = flNextTime_calc;

			//and finally adjust the value in the gun
			SetEntDataFloat(iEntid, g_iNextPAttO, flNextTime_calc, true);

			#if defined PM_DEBUG
			PrintToChatAll("\x03-post, NextTime_calc \x01 %f\x03; new interval \x01%f", GetEntDataFloat(iEntid, g_iNextPAttO), GetEntDataFloat(iEntid, g_iNextPAttO)-flGameTime );
			#endif
			continue;
		}


		//CHECK 4: ON WEAPON SWITCH
		//-------------------------
		//at this point, the only reason DT hasn't fired
		//should be that the weapon had switched
		//checks: retrieved gun id doesn't match stored id
		// or stored id is null
		//actions: updates stored gun id
		// and sets stored next attack time to retrieved value
		if (iEntid_stored != iEntid)
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x03DT client \x01%i\x03; weapon switch inferred", iCid );
			#endif
			//now we update the stored vars
			g_iDTEntid[iCid] = iEntid;
			g_flDTNextTime[iCid] = flNextTime_ret;

			//and now we check whether the equipped weapon is a semi auto or not
			char stWpn[32];
			GetEntityNetClass(iEntid, stWpn, sizeof(stWpn));
			if (StringInsensitiveContains(stWpn, "CSMG_") || StringInsensitiveContains(stWpn, "CSub"))
			{
				#if defined PM_DEBUG
				PrintToChatAll("\x03 - smg detected, weaponid:\x01 %s", stWpn);
				#endif
				g_bDTsemiauto[iCid] = false;
			}
			else if (StringInsensitiveContains(stWpn, "CRifle_") || StringInsensitiveContains(stWpn, "CAssault"))
			{
				#if defined PM_DEBUG
				PrintToChatAll("\x03 - assault rifle detected, weaponid:\x01 %s", stWpn);
				#endif
				g_bDTsemiauto[iCid] = false;
			}
			else
			{
				#if defined PM_DEBUG
				PrintToChatAll("\x03 - VALID weapon detected! weaponid:\x01 %s", stWpn);
				#endif
				g_bDTsemiauto[iCid] = true;
			}

			continue;
		}

		#if defined PM_DEBUG
		PrintToChatAll("\x03DT client \x01%i\x03; reached end of checklist...", iCid );
		#endif
	}
}


//==================================
// MARK: - Sur1: Sleight of Hand, Double Tap
//==================================

//on the start of a reload
void SoH_OnReload(int iCid)
{
	//check if perk is disabled
	if (GameModeCheck(g_bSur1_enable, g_iSoH_enable) == false)
		return;

	SurvivorFirstPerkType iSur1 = g_spSur[iCid].firstPerk;
	if ((iSur1 == SurvivorFirstPerk_DoubleTap || iSur1 == SurvivorFirstPerk_SleightOfHand)
		&& g_bConfirm[iCid]
		&& SM_GetClientTeamType(iCid) == ClientTeam_Survivor)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x03SoH client \x01%i\x03; start of reload detected", iCid );
		#endif
		int iEntid = GetEntDataEnt2(iCid, g_iActiveWO);
		if (IsValidEntity(iEntid) == false) return;

		char stClass[32];
		GetEntityNetClass(iEntid, stClass, sizeof(stClass));

		float flRate = 0.0;
		if (iSur1 == SurvivorFirstPerk_DoubleTap)
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x03 - using DT values");
			#endif
			flRate = g_flDT_rate_reload;
		}
		else
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x03 - using SoH values");
			#endif
			flRate = g_flSoH_rate;
		}

		#if defined PM_DEBUG
		PrintToChatAll("\x03-class of gun: \x01%s", stClass );
		#endif
		//for non-shotguns
		if (StrContains(stClass,"shotgun", false) == -1)
		{
			SoH_MagStart(iEntid, iCid, flRate);
			return;
		}

		//shotguns are a bit trickier since the game
		//tracks per shell inserted - and there's TWO
		//different shotguns with different values =.=
		else if (StringInsensitiveContains(stClass, "autoshotgun"))
		{
			//crate a pack to send clientid and gunid through to the timer
			DataPack hPack = CreateDataPack();
			hPack.WriteCell(iCid);
			hPack.WriteCell(iEntid);
			hPack.WriteFloat(flRate);

			CreateTimer(0.1, SoH_AutoshotgunStart, hPack);
			return;
		}
		else if (StringInsensitiveContains(stClass, "shotgun_spas"))
		{
			//crate a pack to send clientid and gunid through to the timer
			DataPack hPack = CreateDataPack();
			hPack.WriteCell(iCid);
			hPack.WriteCell(iEntid);
			hPack.WriteFloat(flRate);

			CreateTimer(0.1, SoH_SpasShotgunStart, hPack);
			return;
		}

		else if (StringInsensitiveContains(stClass, "pumpshotgun") || StringInsensitiveContains(stClass, "shotgun_chrome"))
		{
			//crate a pack to send clientid and gunid through to the timer
			DataPack hPack = CreateDataPack();
			WritePackCell(hPack, iCid);
			WritePackCell(hPack, iEntid);
			WritePackFloat(hPack, flRate);

			CreateTimer(0.1, SoH_PumpshotgunStart, hPack);
			return;
		}
	}
}

//called for mag loaders
void SoH_MagStart(int iEntid, int iCid, float flRate)
{
	#if defined PM_DEBUG
	PrintToChatAll("\x05-magazine loader detected,\x03 gametime \x01%f", GetGameTime());
	#endif
	float flGameTime = GetGameTime();
	float flNextTime_ret = GetEntDataFloat(iEntid, g_iNextPAttO);

	//----DEBUG----
	/*PrintToChatAll("\x03- pre, gametime \x01%f\x03, retrieved nextattack\x01 %i %f\x03, retrieved time idle \x01%i %f",
		flGameTime,
		g_iNextAttO,
		GetEntDataFloat(iCid, g_iNextAttO),
		g_iTimeIdleO,
		GetEntDataFloat(iEntid, g_iTimeIdleO)
		);*/

	//this is a calculation of when the next primary attack
	//will be after applying sleight of hand values
	//NOTE: at this point, only calculate the interval itself,
	//without the actual game engine time factored in
	float flNextTime_calc = ( flNextTime_ret - flGameTime ) * flRate ;

	//we change the playback rate of the gun
	//just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/flRate, true);

	//create a timer to reset the playrate after
	//time equal to the modified attack interval
	CreateTimer(flNextTime_calc, SoH_MagEnd, iEntid);

	//experiment to remove double-playback bug
	DataPack hPack = CreateDataPack();
	hPack.WriteCell(iCid);
	//this calculates the equivalent time for the reload to end
	//if the survivor didn't have the SoH perk
	float flStartTime_calc = flGameTime - ( flNextTime_ret - flGameTime ) * ( 1 - flRate ) ;
	hPack.WriteFloat(flStartTime_calc);
	//now we create the timer that will prevent the annoying double playback
	if ((flNextTime_calc - 0.4) > 0)
		CreateTimer( flNextTime_calc - 0.4, SoH_MagEnd2, hPack);

	//and finally we set the end reload time into the gun
	//so the player can actually shoot with it at the end
	flNextTime_calc += flGameTime;
	SetEntDataFloat(iEntid, g_iTimeIdleO, flNextTime_calc, true);
	SetEntDataFloat(iEntid, g_iNextPAttO, flNextTime_calc, true);
	SetEntDataFloat(iCid, g_iNextAttO, flNextTime_calc, true);

	//----DEBUG----
	/*PrintToChatAll("\x03- post, calculated nextattack \x01%f\x03, gametime \x01%f\x03, retrieved nextattack\x01 %i %f\x03, retrieved time idle \x01%i %f",
		flNextTime_calc,
		flGameTime,
		g_iNextAttO,
		GetEntDataFloat(iCid, g_iNextAttO),
		g_iTimeIdleO,
		GetEntDataFloat(iEntid, g_iTimeIdleO)
		);*/
}

//called for autoshotguns
Action SoH_AutoshotgunStart(Handle timer, DataPack hPack)
{
	KillTimer(timer);
	if (IsServerProcessing() == false) {
		CloseHandle(hPack);
		return Plugin_Stop;
	}

	hPack.Reset();
	int iCid = hPack.ReadCell();
	int iEntid = hPack.ReadCell();
	float flRate = hPack.ReadFloat();
	CloseHandle(hPack);

	hPack = CreateDataPack();
	hPack.WriteCell(iCid);
	hPack.WriteCell(iEntid);

	if (iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid) == false
		|| IsValidEntity(iEntid) == false
		|| IsClientInGame(iCid) == false)
		return Plugin_Stop;

	//----DEBUG----
	/*PrintToChatAll("\x03-autoshotgun detected, iEntid \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i",
		iEntid,
		g_iShotStartDurO,
		g_iShotInsertDurO,
		g_iShotEndDurO
		);
	PrintToChatAll("\x03- pre mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_flSoHAutoS,
		g_flSoHAutoI,
		g_flSoHAutoE
		);*/

	//then we set the new times in the gun
	SetEntDataFloat(iEntid,	g_iShotStartDurO,	g_flSoHAutoS*flRate,	true);
	SetEntDataFloat(iEntid,	g_iShotInsertDurO,	g_flSoHAutoI*flRate,	true);
	SetEntDataFloat(iEntid,	g_iShotEndDurO,		g_flSoHAutoE*flRate,	true);

	//we change the playback rate of the gun
	//just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/flRate, true);

	//and then call a timer to periodically check whether the
	//gun is still reloading or not to reset the animation
	//but first check the reload state; if it's 2, then it
	//needs a pump/cock before it can shoot again, and thus
	//needs more time
	if (g_bIsL4D2)
		CreateTimer(0.3, SoH_ShotgunEnd, hPack, TIMER_REPEAT);
	else
	{
		if (GetEntData(iEntid, g_iShotRelStateO) == 2)
			CreateTimer(0.3, SoH_ShotgunEndCock, hPack, TIMER_REPEAT);
		else
			CreateTimer(0.3, SoH_ShotgunEnd, hPack, TIMER_REPEAT);
	}

	//----DEBUG----
	/*PrintToChatAll("\x03- after mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_flSoHAutoS,
		g_flSoHAutoI,
		g_flSoHAutoE
		);*/

	return Plugin_Stop;
}

Action SoH_SpasShotgunStart(Handle timer, DataPack hPack)
{
	KillTimer(timer);
	if (IsServerProcessing() == false) {
		CloseHandle(hPack);
		return Plugin_Stop;
	}

	hPack.Reset();
	int iCid = hPack.ReadCell();
	int iEntid = hPack.ReadCell();
	float flRate = hPack.ReadFloat();
	CloseHandle(hPack);

	hPack = CreateDataPack();
	hPack.WriteCell(iCid);
	hPack.WriteCell(iEntid);

	if (iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid) == false
		|| IsValidEntity(iEntid) == false
		|| IsClientInGame(iCid) == false)
		return Plugin_Stop;

	//----DEBUG----
	/*PrintToChatAll("\x03-autoshotgun detected, iEntid \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i",
		iEntid,
		g_iShotStartDurO,
		g_iShotInsertDurO,
		g_iShotEndDurO
		);
	PrintToChatAll("\x03- pre mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_flSoHSpasS,
		g_flSoHSpasI,
		g_flSoHSpasE
		);*/

	//then we set the new times in the gun
	SetEntDataFloat(iEntid,	g_iShotStartDurO,	g_flSoHSpasS*flRate,	true);
	SetEntDataFloat(iEntid,	g_iShotInsertDurO,	g_flSoHSpasI*flRate,	true);
	SetEntDataFloat(iEntid,	g_iShotEndDurO,		g_flSoHSpasE*flRate,	true);

	//we change the playback rate of the gun
	//just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/flRate, true);

	//and then call a timer to periodically check whether the
	//gun is still reloading or not to reset the animation
	//but first check the reload state; if it's 2, then it
	//needs a pump/cock before it can shoot again, and thus
	//needs more time
	CreateTimer(0.3, SoH_ShotgunEnd, hPack, TIMER_REPEAT);

	//----DEBUG----
	/*PrintToChatAll("\x03- after mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_flSoHSpasS,
		g_flSoHSpasI,
		g_flSoHSpasE
		);*/

	return Plugin_Stop;
}

//called for pump shotguns
Action SoH_PumpshotgunStart(Handle timer, DataPack hPack)
{
	KillTimer(timer);
	if (IsServerProcessing() == false) {
		CloseHandle(hPack);
		return Plugin_Stop;
	}

	hPack.Reset();
	int iCid = hPack.ReadCell();
	int iEntid = hPack.ReadCell();
	float flRate = hPack.ReadFloat();
	CloseHandle(hPack);

	hPack = CreateDataPack();
	hPack.WriteCell(iCid);
	hPack.WriteCell(iEntid);

	if (iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid) == false
		|| IsValidEntity(iEntid) == false
		|| IsClientInGame(iCid) == false)
		return Plugin_Stop;

	//----DEBUG----
	/*PrintToChatAll("\x03-pumpshotgun detected, iEntid \x01%i\x03, startO \x01%i\x03, insertO \x01%i\x03, endO \x01%i",
		iEntid,
		g_iShotStartDurO,
		g_iShotInsertDurO,
		g_iShotEndDurO
		);
	PrintToChatAll("\x03- pre mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_flSoHPumpS,
		g_flSoHPumpI,
		g_flSoHPumpE
		);*/

	//then we set the new times in the gun
	SetEntDataFloat(iEntid,	g_iShotStartDurO,	g_flSoHPumpS*flRate,	true);
	SetEntDataFloat(iEntid,	g_iShotInsertDurO,	g_flSoHPumpI*flRate,	true);
	SetEntDataFloat(iEntid,	g_iShotEndDurO,		g_flSoHPumpE*flRate,	true);

	//we change the playback rate of the gun
	//just so the player can "see" the gun reloading faster
	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0/flRate, true);

	//and then call a timer to periodically check whether the
	//gun is still reloading or not to reset the animation
	if (g_bIsL4D2)
		CreateTimer(0.3, SoH_ShotgunEnd, hPack, TIMER_REPEAT);
	else
	{
		if (GetEntData(iEntid, g_iShotRelStateO) == 2)
			CreateTimer(0.3, SoH_ShotgunEndCock, hPack, TIMER_REPEAT);
		else
			CreateTimer(0.3, SoH_ShotgunEnd, hPack, TIMER_REPEAT);
	}

	//----DEBUG----
	/*PrintToChatAll("\x03- after mod, start \x01%f\x03, insert \x01%f\x03, end \x01%f",
		g_flSoHPumpS,
		g_flSoHPumpI,
		g_flSoHPumpE
		);*/

	return Plugin_Stop;
}

//this resets the playback rate on non-shotguns
Action SoH_MagEnd(Handle timer, int iEntid)
{
	KillTimer(timer);
	if (IsServerProcessing() == false)
		return Plugin_Stop;

	#if defined PM_DEBUG
	PrintToChatAll("\x03SoH reset playback, magazine loader");
	#endif
	if (iEntid <= 0 || IsValidEntity(iEntid) == false)
		return Plugin_Stop;

	SetEntDataFloat(iEntid, g_iPlayRateO, 1.0, true);

	return Plugin_Stop;
}

Action SoH_MagEnd2(Handle timer, DataPack hPack)
{
	KillTimer(timer);
	if (IsServerProcessing() == false)
	{
		CloseHandle(hPack);
		return Plugin_Stop;
	}

	#if defined PM_DEBUG
	PrintToChatAll("\x03SoH reset playback, magazine loader");
	#endif

	hPack.Reset();
	int iCid = hPack.ReadCell();
	float flStartTime_calc = hPack.ReadFloat();
	CloseHandle(hPack);

	if (iCid <= 0 || IsValidEntity(iCid) == false || IsClientInGame(iCid) == false)
		return Plugin_Stop;

	//experimental, remove annoying double-playback
	int iVMid = GetEntDataEnt2(iCid, g_iViewModelO);
	SetEntDataFloat(iVMid, g_iVMStartTimeO, flStartTime_calc, true);

	#if defined PM_DEBUG
	PrintToChatAll("\x03- end SoH mag loader, icid \x01%i\x03 starttime \x01%f\x03 gametime \x01%f", iCid, flStartTime_calc, GetGameTime());
	#endif

	return Plugin_Stop;
}

Action SoH_ShotgunEnd(Handle timer, DataPack hPack)
{
	#if defined PM_DEBUG
	PrintToChatAll("\x03-autoshotgun tick");
	#endif

	hPack.Reset();
	int iCid = hPack.ReadCell();
	int iEntid = hPack.ReadCell();

	if (IsServerProcessing() == false
		|| iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid) == false
		|| IsValidEntity(iEntid) == false
		|| IsClientInGame(iCid) == false)
	{
		KillTimer(timer);
		CloseHandle(hPack);
		return Plugin_Stop;
	}

	if (GetEntData(iEntid, g_iShotRelStateO) == 0)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x03-shotgun end reload detected");
		#endif
		SetEntDataFloat(iEntid, g_iPlayRateO, 1.0, true);

		//int iCid = GetEntPropEnt(iEntid, Prop_Data,"m_hOwner");
		float flTime = GetGameTime() + 0.2;
		SetEntDataFloat(iCid,	g_iNextAttO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iTimeIdleO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iNextPAttO,	flTime,	true);

		KillTimer(timer);
		CloseHandle(hPack);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

//since cocking requires more time, this function does
//exactly as the above, except it adds slightly more time
Action SoH_ShotgunEndCock (Handle timer, DataPack hPack)
{
	#if defined PM_DEBUG
	PrintToChatAll("\x03-autoshotgun tick");
	#endif

	hPack.Reset();
	int iCid = hPack.ReadCell();
	int iEntid = hPack.ReadCell();

	if (IsServerProcessing() == false
		|| iCid <= 0
		|| iEntid <= 0
		|| IsValidEntity(iCid) == false
		|| IsValidEntity(iEntid) == false
		|| IsClientInGame(iCid) == false)
	{
		KillTimer(timer);
		CloseHandle(hPack);
		return Plugin_Stop;
	}

	if (GetEntData(iEntid, g_iShotRelStateO) == 0)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x03-shotgun end reload + cock detected");
		#endif
		SetEntDataFloat(iEntid, g_iPlayRateO, 1.0, true);

		//int iCid = GetEntPropEnt(iEntid, Prop_Data,"m_hOwner");
		float flTime = GetGameTime() + 1.0;
		SetEntDataFloat(iCid,	g_iNextAttO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iTimeIdleO,	flTime,	true);
		SetEntDataFloat(iEntid,	g_iNextPAttO,	flTime,	true);

		KillTimer(timer);
		CloseHandle(hPack);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}


//=============================
// MARK: - Sur1: Pyrotechnician
//=============================

//on pickup
void Pyro_Pickup(int iCid, const char[] stWpn)
{
	if (g_spSur[iCid].firstPerk == SurvivorFirstPerk_Pyrotechnician && GameModeCheck(g_bSur1_enable, g_iPyro_enable))
	{
		//only bother with checks if they aren't throwing
		if (g_iGrenThrow[iCid] == 0)
		{
			//check if the weapon is a grenade type
			if (StrEqual(stWpn, "pipe_bomb", false) || StrEqual(stWpn, "molotov", false) || StrEqual(stWpn, "vomitjar", false))
			{
				char stWpn2[24];
				if (stWpn[0]== 'p')
					stWpn2 = "pipe bomb";
				else if (stWpn[0]=='v' && g_bIsL4D2)
					stWpn2 = "vomit jar";
				else
					stWpn2 = "molotov";
				//if so, then check if either 0 or 2 are being carried
				//if true, then act normally and give player 2 grenades
				if (g_iGren[iCid] == 0 || g_iGren[iCid] == 2)
				{
					g_iGren[iCid] = 2;
					PrintHintText(iCid, "%t: %t %i %s(s)", "PerkMenuSurvivorFirstPerkPyrotechnician", "GrenadierCarryHint", g_iGren[iCid], stWpn2);
				}
				//otherwise, only give them one and tell them to
				//throw the grenade before picking up another one;
				//this is to prevent abuses with throwing infinite nades
				else
				{
					g_iGren[iCid] = 1;
					PrintHintText(iCid, "%t %s! %t", "GrenadierCantTake2Grenades_A", stWpn2, "GrenadierCantTake2Grenades_B");
				}
			}
		}
		//if they are in the middle of throwing, then reset the var
		else if (g_iGrenThrow[iCid] == 1)
			g_iGrenThrow[iCid] = 0;
	}
}

//called when tossing
void Pyro_OnWeaponFire(int iCid, const char[] stWpn)
{
	//check if perk is enabled
	if (GameModeCheck(g_bSur1_enable, g_iPyro_enable) == false)
		return;

	if (g_bConfirm[iCid] == false || g_spSur[iCid].firstPerk != SurvivorFirstPerk_Pyrotechnician) return;

	#if defined PM_DEBUG
	PrintToChatAll("\x03 weapon fired: \x01%s", stWpn);
	#endif

	bool bPipe = StrEqual(stWpn,	"pipe_bomb",	false);
	bool bMol = StrEqual(stWpn,		"molotov",		false);
	bool bVomit = StrEqual(stWpn,	"vomitjar",		false);

	if (bPipe || bMol || bVomit)
	{
		g_iGren[iCid]--;		//reduce count by 1
		char stWpn2[24];

		if (g_iGren[iCid] > 0)		//do they still have grenades left?
		{
			if (bPipe)
			{
				g_iGrenType[iCid] = 1;
				stWpn2 = "pipe bomb";
			}
			else if (bMol)
			{
				g_iGrenType[iCid] = 2;
				stWpn2 = "molotov";
			}
			else
			{
				g_iGrenType[iCid] = 3;
				stWpn2 = "vomit jar";
			}

			PrintHintText(iCid, "%t: %t %i %s(s) %t", 
				"PerkMenuSurvivorFirstPerkPyrotechnician", "GrenadierCounter_A", g_iGren[iCid], stWpn2, "GrenadierCounter_B");
			CreateTimer(2.5, Grenadier_DelayedGive, iCid);
		}
	}
}

//gives the grenade a few seconds later
//(L4D takes a while to remove the grenade from inventory after it's been thrown)
Action Grenadier_DelayedGive (Handle timer, int iCid)
{
	KillTimer(timer);
	if (IsServerProcessing() == false)
		return Plugin_Stop;

	if (iCid == 0 || g_bConfirm[iCid] == false || g_spSur[iCid].firstPerk != SurvivorFirstPerk_Pyrotechnician)
		return Plugin_Continue;

	int iflags = GetCommandFlags("give");
	char st_give[24];

	if (g_iGrenType[iCid] == 1)
		st_give = "give pipe_bomb";
	else if (g_iGrenType[iCid] == 2)
		st_give = "give molotov";
	else
		st_give = "give vomitjar";

	g_iGrenType[iCid] = 0;
	g_iGrenThrow[iCid] = 1;	//client now considered to be "in the middle of throwing"
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(iCid, st_give);
	SetCommandFlags("give", iflags);

	return Plugin_Stop;
}


//called on roundstarts or on confirming perks
//gives a pipe bomb to the player
void Event_Confirm_Grenadier(int iCid)
{
	if (iCid==0
		|| SM_GetClientTeamType(iCid) != ClientTeam_Survivor
		|| IsPlayerAlive(iCid) == false
		|| g_bConfirm[iCid] == false
		|| g_spSur[iCid].firstPerk != SurvivorFirstPerk_Pyrotechnician)
		return;

	//check if perk is enabled
	if (GameModeCheck(g_bSur1_enable, g_iPyro_enable) == false)
		return;

	//reset grenade count on player
	g_iGren[iCid] = 0;

	int iflags = GetCommandFlags("give");
	char st_give[24];

	int iMax = (g_bIsL4D2 ? 2 : 1);

	int iI = GetRandomInt(0, iMax);
	if (iI == 0)
		st_give = "give pipe_bomb";
	else if (iI == 1)
		st_give = "give molotov";
	else if (iI == 2)
		st_give = "give vomitjar";

	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(iCid, st_give);
	SetCommandFlags("give", iflags);

	g_iPyroTicks[iCid] = 0;
	g_iPyroRegisterCount++;
	g_iPyroRegisterIndex[g_iPyroRegisterCount] = iCid;

	return;
}

//called every 2 seconds from global timer
//checks for ammo and adds to the player's "ticker"
//for every 2s tick that they don't have any grenades
void Pyro_Timer()
{
	int iCid;
	int iTicks;

	//check if perk is enabled
	if (g_iPyro_maxticks == 0 || GameModeCheck(g_bSur1_enable, g_iPyro_enable) == false)
		return;

	//or if no one has DT, don't bother either
	if (g_iPyroRegisterCount == 0)
		return;

	//theoretically, to get on the DT registry
	//all the necessary checks would have already
	//been run, so we don't bother with any checks here
	for (int iI = 1; iI<=g_iPyroRegisterCount; iI++)
	{
		//PRE-CHECKS: RETRIEVE VARS
		//-------------------------

		iCid = g_iPyroRegisterIndex[iI];
		iTicks = g_iPyroTicks[iI];
		//stop on this client
		//when the next client id is null
		if (iCid <= 0 || IsValidEntity(iCid) == false)
			return;

		#if defined PM_DEBUG
		PrintToChatAll("\x03Pyro tick \x01%i\x03 for \x01%i", iTicks, iCid);
		#endif
		//now we check if enough ticks have elapsed
		//to give the survivor their pipe bomb
		if (iTicks >= g_iPyro_maxticks)
		{
			int iflags = GetCommandFlags("give");
			SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
			FakeClientCommand(iCid, "give pipe_bomb");
			SetCommandFlags("give", iflags);

			g_iPyroTicks[iCid] = 0;

			#if defined PM_DEBUG
			PrintToChatAll("\x03- max ticks reached, gave pipe bomb and resetting", g_iPyroTicks[iCid], iCid);
			#endif
			continue;
		}

		int iAmmoO = FindDataMapInfo(iCid, "m_iAmmo");

		//+48 = pipe bombs
		//+52 = molotovs
		//+56 = bile jars
		if (GetEntData(iCid, iAmmoO + 48) > 0 || GetEntData(iCid, iAmmoO + 52) > 0 || GetEntData(iCid, iAmmoO + 56) > 0)
		{
			g_iPyroTicks[iCid] = 0;

			continue;
		}

		g_iPyroTicks[iCid]++;
	}
}

//called whenever the registry needs to be rebuilt
//to cull any players who have left or died, etc.
//(called on: player death, player disconnect,
//closet rescue, change teams)
void Pyro_Rebuild()
{
	//clears all DT-related vars
	Pyro_Clear(false);

	//if the server's not running or
	//is in the middle of loading, stop
	if (IsServerProcessing() == false)
		return;

	#if defined PM_DEBUG
	PrintToChatAll("\x03double tap rebuilding registry");
	#endif
	for (int iI = 1; iI<=MaxClients; iI++)
	{
		if (IsClientInGame(iI)
			&& IsPlayerAlive(iI)
			&& g_spSur[iI].firstPerk == SurvivorFirstPerk_Pyrotechnician
			&& g_bConfirm[iI]
			&& SM_GetClientTeamType(iI) == ClientTeam_Survivor)
		{
			g_iPyroRegisterCount++;
			g_iPyroRegisterIndex[g_iPyroRegisterCount] = iI;

			#if defined PM_DEBUG
			PrintToChatAll("\x03-registering \x01%i", iI);
			#endif
		}
	}
}

//called to clear out DT registry
//(called on: round start, round end, map end)
//the boolean is to only reset the tick counter per player
//if we are at the round start, because we don't want late
//comers to the game to mess up other people's Pyro tickers
void Pyro_Clear(bool bRoundStart)
{
	g_iPyroRegisterCount = 0;
	for (int iI = 1; iI <= MaxClients; iI++)
	{
		g_iPyroRegisterIndex[iI]= -1;
		if (bRoundStart)
			g_iPyroTicks[iI] = 0;
	}
}

//=============================
// MARK: - Sur2: Martial Artist
//=============================

void MA_RunChecks()
{
	g_bMA_meta_enable = GameModeCheck(g_bSur2_enable, g_iMA_enable);
}

//called on confirming perks
//adds player to registry of MA users
//and sets movement speed
void Event_Confirm_MA(int iCid)
{
	if (g_iMARegisterCount < 0)
		g_iMARegisterCount = 0;

	//check if perk is enabled
	if (GameModeCheck(g_bSur1_enable, g_iMA_enable) == false)
		return;

	if (IsClientInGame(iCid)
		&& IsPlayerAlive(iCid)
		&& g_spSur[iCid].secondPerk == SurvivorSecondPerk_MartialArtist
		&& g_bConfirm[iCid] == true
		&& SM_GetClientTeamType(iCid) == ClientTeam_Survivor)
	{
		g_iMARegisterCount++;
		g_iMARegisterIndex[g_iMARegisterCount] = iCid;

		#if defined PM_DEBUG
		PrintToChatAll("\x03martial artist on confirm, registering \x01%i", iCid);
		#endif
	}
}

//called whenever the registry needs to be rebuilt
//to cull any players who have left or died, etc.
//resets survivor's speeds and reassigns speed boost
//(called on: player death, player disconnect,
//closet rescue, change teams, convar change)
void MA_Rebuild()
{
	//clears all DT-related vars
	MA_Clear();

	//if the server's not running or
	//is in the middle of loading, stop
	if (IsServerProcessing() == false)
		return;

	//check if perk is enabled
	if (GameModeCheck(g_bSur2_enable, g_iMA_enable) == false)
		return;

	#if defined PM_DEBUG
	PrintToChatAll("\x03martial artist rebuilding registry");
	#endif
	for (int iI = 1; iI <= MaxClients; iI++)
	{
		if (IsClientInGame(iI)
			&& IsPlayerAlive(iI)
			&& g_spSur[iI].secondPerk == SurvivorSecondPerk_MartialArtist
			&& g_bConfirm[iI]
			&& SM_GetClientTeamType(iI) == ClientTeam_Survivor)
		{
			g_iMARegisterCount++;
			g_iMARegisterIndex[g_iMARegisterCount] = iI;

			#if defined PM_DEBUG
			PrintToChatAll("\x03-registering \x01%i", iI);
			#endif
		}
	}
}

//called to clear out registry
//and reset movement speeds
//(called on: round start, round end, map end)
void MA_Clear()
{
	g_iMARegisterCount = 0;
	for (int iI = 1; iI <= MaxClients; iI++)
	{
		g_iMARegisterIndex[iI] = -1;
	}
}

void MA_OnGameFrame()
{
	//stop if MA is disabled in any way
	if (g_bMA_meta_enable == false)
		return;

	//or if no one has DT, don't bother either
	if (g_iMARegisterCount == 0)
		return;

	int iCid;
	//this tracks the player's ability id
	int iEntid;
	//this tracks the calculated next attack
	float flNextTime_calc;
	//this, on the other hand, tracks the current next attack
	float flNextTime_ret;
	//and this tracks the game time
	float flGameTime=GetGameTime();

	for (int iI = 1; iI <= g_iMARegisterCount; iI++)
	{
		//PRE-CHECKS 1: RETRIEVE VARS
		//---------------------------

		iCid = g_iMARegisterIndex[iI];
		//stop on this client
		//when the next client id is null
		if (iCid <= 0) return;
		//skip this client if they're disabled, or, you know, dead
		//if (g_iMyDisabler[iCid] != -1) continue;
		//if (IsPlayerAlive(iCid) == false) continue;

		//we have to adjust numbers on the gun, not the player
		//so we get the active weapon id here
		iEntid = GetEntDataEnt2(iCid, g_iActiveWO);
		//if the retrieved gun id is -1, then...
		//wtf mate? just move on
		if (iEntid == -1) continue;
		//and here is the retrieved next attack time
		flNextTime_ret = GetEntDataFloat(iEntid, g_iNextPAttO);

		#if defined PM_DEBUG
		PrintToChat(iCid,"\x03shove penalty \x01%i\x03, max penalty \x01%i", GetEntData(iCid, g_iMeleeFatigueO), g_iMA_maxpenalty);
		#endif
		//PRE-CHECKS 2: MOD SHOVE FATIGUE
		//-------------------------------
		if ( GetEntData(iCid, g_iMeleeFatigueO) > g_iMA_maxpenalty )
		{
			SetEntData(iCid, g_iMeleeFatigueO, g_iMA_maxpenalty);
		}

		//CHECK 1: IS PLAYER USING A KNOWN NON-MELEE WEAPON?
		//--------------------------------------------------
		//as the title states... to conserve processing power,
		//if the player's holding a gun for a prolonged time
		//then we want to be able to track that kind of state
		//and not bother with any checks
		//checks: weapon is non-melee weapon
		//actions: do nothing
		if (iEntid == g_iMAEntid_notmelee[iCid])
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x03MA client \x01%i\x03; non melee weapon, ignoring", iCid );
			#endif
			g_iMAAttCount[iCid] = 0;
			continue;
		}


		//PRE CHECK 1.5
		//-------------
		int iMAEntid = g_iMAEntid[iCid];
		int iMAAttCount = g_iMAAttCount[iCid];

		//CHECK 1.5: THE PLAYER HASN'T SWUNG HIS WEAPON FOR A WHILE
		//-------------------------------------------------------
		//in this case, if the player made 1 swing of his 2 strikes,
		//and then paused long enough, we should reset his strike count
		//so his next attack will allow him to strike twice
		//checks: is the delay between attacks greater than 0.8s?
		//actions: set attack count to 0, and CONTINUE CHECKS
		if (iMAEntid == iEntid && iMAAttCount != 0 && (flGameTime - flNextTime_ret) > 0.8)
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x03MA client \x01%i\x03; hasn't swung weapon", iCid );
			#endif
			g_iMAAttCount[iCid] = 0;
		}

		//PRE CHECK 2
		//-----------
		float flMANextTime = g_flMANextTime[iCid];

		//CHECK 2: BEFORE ADJUSTED ATT IS MADE
		//------------------------------------
		//since this will probably be the case most of
		//the time, we run this first
		//checks: weapon is unchanged; time of shot has not passed
		//actions: do nothing
		if (iMAEntid == iEntid && flMANextTime >= flNextTime_ret)
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x03DT client \x01%i\x03; before shot made", iCid );
			#endif
			continue;
		}

		//CHECK 3: AFTER ADJUSTED ATT IS MADE
		//------------------------------------
		//at this point, either a gun was swapped, or
		//the attack time needs to be adjusted
		//checks: stored gun id same as retrieved gun id,
		// and retrieved next attack time is after stored value
		//actions: adjusts next attack time
		if (iMAEntid == iEntid && flMANextTime < flNextTime_ret)
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x03DT after adjusted shot\n-pre, client \x01%i\x03; entid \x01%i\x03; enginetime\x01 %f\x03; NextTime_orig \x01 %f\x03; interval \x01%f", iCid, iEntid, flGameTime, flNextTime_ret, flNextTime_ret-flGameTime );
			float flNextTime_retSA = GetEntDataFloat(iEntid, g_iNextSAttO);
			PrintToChatAll("\x05DT\x03 enginetime\x01 %f\x03; nextPA \x01%f\x03; PAinterval \x01%f\x03\n nextSA \x01%f\x03 SAinterval \x01%f", flGameTime, flNextTime_ret, flNextTime_ret-flGameTime, flNextTime_retSA, flNextTime_retSA-flGameTime );
			#endif


			//> CHECK FOR SHOVES/WEAPON DRAWS
			//-------------------------------
			float flInterval = flNextTime_ret-flGameTime;
			if (flInterval > 0.7331 && flInterval < 0.7335)
			{
				#if defined PM_DEBUG
				PrintToChatAll("\x05DT\x03 shove inferred");
				#endif
				g_flMANextTime[iCid] = flNextTime_ret;
				continue;
			}
			if (flInterval < 0.534)
			{
				#if defined PM_DEBUG
				PrintToChatAll("\x05DT\x03 weapon draw inferred");
				#endif
				g_flMANextTime[iCid] = flNextTime_ret;
				continue;
			}

			g_iMAAttCount[iCid]++;
			if (g_iMAAttCount[iCid] > 2)
				g_iMAAttCount[iCid] = 0;
			iMAAttCount = g_iMAAttCount[iCid];

			//> MOD ATTACK
			//------------
			if (iMAAttCount == 1 || iMAAttCount == 2)
			{
				//this is a calculation of when the next primary attack
				//will be after applying double tap values
				//flNextTime_calc = ( flNextTime_ret - flGameTime ) * g_flMA_attrate + flGameTime;
				flNextTime_calc = flGameTime + 0.3 ;

				//then we store the value
				g_flMANextTime[iCid] = flNextTime_calc;

				//and finally adjust the value in the gun
				SetEntDataFloat(iEntid, g_iNextPAttO, flNextTime_calc, true);

				#if defined PM_DEBUG
				PrintToChatAll("\x03-post, NextTime_calc \x01 %f\x03; new interval \x01%f", GetEntDataFloat(iEntid, g_iNextPAttO), GetEntDataFloat(iEntid, g_iNextPAttO)-flGameTime );
				#endif
				continue;
			}

			//> DON'T MOD ATTACK
			//------------------
			if (g_iMAAttCount[iCid] == 0)
			{
				g_flMANextTime[iCid] = flNextTime_ret;
				continue;
			}
		}

		//CHECK 4: CHECK THE WEAPON
		//-------------------------
		//lastly, at this point we need to check if we are, in fact,
		//using a melee weapon =P we check if the current weapon is
		//the same one stored in memory; if it is, move on;
		//otherwise, check if it's a melee weapon - if it is,
		//store and continue; else, continue.
		//checks: if the active weapon is a melee weapon
		//actions: store the weapon's entid into either
		// the known-melee or known-non-melee variable

		#if defined PM_DEBUG
		PrintToChatAll("\x03DT client \x01%i\x03; weapon switch inferred", iCid );
		#endif
		//check if the weapon is a melee
		char stName[32];
		GetEntityNetClass(iEntid, stName, sizeof(stName));
		if (StrEqual(stName, "CTerrorMeleeWeapon", false))
		{
			//if yes, then store in known-melee var
			g_iMAEntid[iCid] = iEntid;
			g_flMANextTime[iCid] = flNextTime_ret;
			continue;
		}
		else
		{
			//if no, then store in known-non-melee var
			g_iMAEntid_notmelee[iCid] = iEntid;
			continue;
		}
	}

	return;
}

//=============================
// MARK: - Sur2: Unbreakable
//=============================

//on heal; gives 80% of bonus hp
void Unbreakable_OnHeal(int iCid)
{
	//check if perk is enabled
	if (GameModeCheck(g_bSur2_enable, g_iUnbreak_enable) == false)
		return;

	if (g_spSur[iCid].secondPerk == SurvivorSecondPerk_Unbreakable)
	{
		CreateTimer(0.5, Unbreakable_Delayed_Heal, iCid);
		//SetEntProp(iCid, Prop_Data,"m_iHealth", GetEntProp(iCid, Prop_Data,"m_iHealth")+(g_iUnbreak_hp*8/10) );

		//run a check to see if for whatever reason
		//the player's health is above 200
		//since 200 is the clamped maximum for unbreakable
		//in which case we set their health to 200
		if (GetEntProp(iCid, Prop_Data,"m_iHealth") > 200)
			CreateTimer(0.5, Unbreakable_Delayed_SetHigh, iCid);

		PrintHintText(iCid, "%t: %t!", "PerkMenuSurvivorSecondPerkUnbreakable", "UnbreakableHint");
	}
}

//called when player confirms his choices;
//gives 30 hp (to bring hp to 130, assuming survivor
//wasn't stupid and got himself hurt before confirming perks)
void Event_Confirm_Unbreakable(int iCid)
{
	int iHP = GetEntProp(iCid, Prop_Data, "m_iHealth");
	if (iCid == 0 || g_bConfirm[iCid] == false) return;

	ClientTeamType TC = SM_GetClientTeamType(iCid);

	//check if perk is enabled
	if (GameModeCheck(g_bSur2_enable, g_iUnbreak_enable) == false)
	{
		//if not, check if hp is higher than it should be
		if (iHP > 100 && TC == ClientTeam_Survivor)
		{
			//if it IS higher, reduce hp to 100
			//otherwise, no way to know whether previous owner
			//had unbreakable, so give the incoming player
			//the benefit of doubt
			CreateTimer(0.5, Unbreakable_Delayed_SetLow, iCid);
		}
		return;
	}

	//if we've gotten up to this point, the perk is enabled
	if (g_spSur[iCid].secondPerk == SurvivorSecondPerk_Unbreakable && TC == ClientTeam_Survivor)
	{
		if (iHP > 100 && iHP < (100 + g_iUnbreak_hp) )
			CreateTimer(0.5, Unbreakable_Delayed_Max, iCid);
		else if (iHP <= 100)
			CreateTimer(0.5, Unbreakable_Delayed_Normal, iCid);
		PrintHintText(iCid, "%t: %t!", "PerkMenuSurvivorSecondPerkUnbreakable", "UnbreakableHint");

		//run a check to see if for whatever reason
		//the player's health is above 200
		//since 200 is the clamped maximum for unbreakable
		//in which case we set their health to 200
		if (GetEntProp(iCid, Prop_Data, "m_iHealth") > 200)
			CreateTimer(0.5, Unbreakable_Delayed_SetHigh, iCid);
	}
	//if not, check if hp is higher than it should be
	else if (g_spSur[iCid].secondPerk != SurvivorSecondPerk_Unbreakable && iHP > 100 && TC == ClientTeam_Survivor)
	{
		//if it IS higher, reduce hp to 100
		//otherwise, no way to know whether previous owner
		//had unbreakable, so give the incoming player
		//the benefit of doubt
		CreateTimer(0.5, Unbreakable_Delayed_SetLow, iCid);
	}
}

//on rescue; gives 50% of bonus hp
void Unbreakable_OnRescue(int iCid)
{
	if (g_spSur[iCid].secondPerk == SurvivorSecondPerk_Unbreakable)
	{
		//check if perk is enabled
		if (GameModeCheck(g_bSur2_enable, g_iUnbreak_enable) == false)
			return;

		CreateTimer(0.5, Unbreakable_Delayed_Rescue, iCid);
		PrintHintText(iCid, "%t: %t!", "PerkMenuSurvivorSecondPerkUnbreakable", "UnbreakableHint");

		//run a check to see if for whatever reason
		//the player's health is above 200
		//since 200 is the clamped maximum for unbreakable
		//in which case we set their health to 200
		if (GetEntProp(iCid, Prop_Data, "m_iHealth") > 200)
			CreateTimer(0.5, Unbreakable_Delayed_SetHigh, iCid);
	}
}

//on revive; gives 50% of bonus hp in temp hp
void Unbreakable_OnRevive(int iSub, int iLedge)
{
	//check for unbreakable for the subject
	//only fires if they were NOT hanging from a ledge
	if (g_spSur[iSub].secondPerk == SurvivorSecondPerk_Unbreakable && g_bConfirm[iSub] && iLedge == 0)
	{
		//check if perk is enabled
		if (GameModeCheck(g_bSur1_enable, g_iUnbreak_enable))
		{
			SetEntDataFloat(iSub, g_iHPBuffO, GetEntDataFloat(iSub, g_iHPBuffO)+(g_iUnbreak_hp/2), true);
			PrintHintText(iSub, "%t: %t!", "PerkMenuSurvivorSecondPerkUnbreakable", "UnbreakableHint");
		}
	}
}

//these timer functions apply health bonuses
//after a delay, hopefully to avoid bugs
Action Unbreakable_Delayed_Max(Handle timer, int iCid)
{
	if (IsServerProcessing() && IsValidEntity(iCid) && IsClientInGame(iCid))
		SetEntProp(iCid, Prop_Data, "m_iHealth", 100 + g_iUnbreak_hp);

	KillTimer(timer);
	return Plugin_Stop;
}

Action Unbreakable_Delayed_Normal(Handle timer, int iCid)
{
	if (IsServerProcessing() && IsValidEntity(iCid) && IsClientInGame(iCid))
	{
		SetEntProp(iCid, Prop_Data, "m_iHealth", GetEntProp(iCid, Prop_Data, "m_iHealth") + g_iUnbreak_hp );

		if (GetEntProp(iCid, Prop_Data, "m_iHealth") > (100 + g_iUnbreak_hp) )
			SetEntProp(iCid, Prop_Data, "m_iHealth", 100 + g_iUnbreak_hp );
	}

	KillTimer(timer);
	return Plugin_Stop;
}

Action Unbreakable_Delayed_Heal(Handle timer, int iCid)
{
	if (IsServerProcessing() && IsValidEntity(iCid) && IsClientInGame(iCid))
	{
		SetEntProp(iCid, Prop_Data,"m_iHealth", GetEntProp(iCid, Prop_Data, "m_iHealth") + (g_iUnbreak_hp * 8/10) );

		if (GetEntProp(iCid, Prop_Data, "m_iHealth") > (100 + g_iUnbreak_hp) )
			SetEntProp(iCid, Prop_Data, "m_iHealth", 100 + g_iUnbreak_hp );
	}

	KillTimer(timer);
	return Plugin_Stop;
}

Action Unbreakable_Delayed_Rescue(Handle timer, int iCid)
{
	if (IsServerProcessing() && IsValidEntity(iCid) && IsClientInGame(iCid))
	{
		SetEntProp(iCid, Prop_Data, "m_iHealth", GetEntProp(iCid, Prop_Data, "m_iHealth") + (g_iUnbreak_hp / 2) );

		if (GetEntProp(iCid, Prop_Data, "m_iHealth") > (100 + g_iUnbreak_hp) )
			SetEntProp(iCid, Prop_Data, "m_iHealth", 100 + g_iUnbreak_hp );
	}

	KillTimer(timer);
	return Plugin_Stop;
}

Action Unbreakable_Delayed_SetHigh(Handle timer, int iCid)
{
	if (IsServerProcessing() && IsValidEntity(iCid) && IsClientInGame(iCid))
		SetEntProp(iCid, Prop_Data, "m_iHealth", 200);

	KillTimer(timer);
	return Plugin_Stop;
}

Action Unbreakable_Delayed_SetLow(Handle timer, int iCid)
{
	if (IsServerProcessing() && IsValidEntity(iCid) && IsClientInGame(iCid))
		SetEntProp(iCid, Prop_Data, "m_iHealth", 100);

	KillTimer(timer);
	return Plugin_Stop;
}

//=============================
// MARK: - Sur2: Spirit
//=============================

//called by global timer "TimerPerks"
//periodically runs checks to see if anyone should self-revive
//since sometimes self-revive won't fire if someone's being disabled
//by, say, a hunter
void Spirit_Timer()
{
	//check if perk is enabled
	if (GameModeCheck(g_bSur2_enable, g_iSpirit_enable) == false)
		return;

	//this var counts how many people are incapped
	//but for the first part, it checks whether anyone has spirit
	int iCount = 0;

	//preliminary check; if no one has
	//the spirit perk, this function will return
	for (int iI = 1; iI <= MaxClients; iI++)
	{
		if (g_spSur[iI].secondPerk == SurvivorSecondPerk_Spirit)
		{
			iCount++;
			break;
		}
	}
	if (iCount <= 0) return;
	else iCount = 0;

	#if defined PM_DEBUG
	PrintToChatAll("\x03spirit timer check");
	#endif
	//this array will hold client ids
	//for the possible candidates for self-revives
	int iCid[18];

	for (int iI = 1; iI <= MaxClients; iI++)
	{
		//fill array with whoever's incapped
		if (IsClientInGame(iI) && SM_GetClientTeamType(iI) == ClientTeam_Survivor && GetEntData(iI, g_iIncapO) != 0)
		{
			iCount++;
			iCid[iCount] = iI;

			#if defined PM_DEBUG
			PrintToChatAll("\x03-incap registering \x01%i", iI);
			#endif
		}
	}

	//if the first two client ids are null, or
	//if the count was zero OR one, return
	//since someone can't self-revive if they're
	//the only ones incapped!
	if (iCount <= 1 || iCid[1] <= 0 || iCid[2] <= 0)
		return;

	#if defined PM_DEBUG
	PrintToChatAll("\x03-beginning self-revive checks, iCount=\x01%i", iCount);
	#endif
	//now we check for someone to revive
	//and we only revive one person at a time
	for (int iI = 1; iI<=iCount; iI++)
	{
		//client ids are stored incrementally (X in 1, Y in 2, Z in 3,...)
		//in the array iCid[], and iI increases per tick, hence this mess =P
		//in short, here we use iCid[iI], NOT iI!
		if (g_bConfirm[iCid[iI]]
			&& g_spSur[iCid[iI]].secondPerk == SurvivorSecondPerk_Spirit
			&& g_iMyDisabler[iCid[iI]] == -1
			&& g_iSpiritCooldown[iCid[iI]] == 0
			&& IsClientInGame(iCid[iI])
			&& IsPlayerAlive(iCid[iI])
			&& SM_GetClientTeamType(iCid[iI]) == ClientTeam_Survivor)
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x03-reviving \x01%i", iCid[iI]);
			#endif
			//retrieve revive count
			int iRevCount_ret = GetEntData(iCid[iI], g_iRevCountO, 1);

			//create a data pack to pass down info
			//so we effectively only execute spirit's state changes
			//if we detect that the self-revive did in fact execute
			DataPack hPack = CreateDataPack();
			hPack.WriteCell(iCid[iI]);
			hPack.WriteCell(iRevCount_ret);

			//here we give health through the console command
			//which is used to revive the player (no other way
			//I know of, setting the m_isIncapacitated in
			//CTerrorPlayer revives them but they can't move!)
			int iflags = GetCommandFlags("give");
			SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
			FakeClientCommand(iCid[iI],"give health");
			SetCommandFlags("give", iflags);

			//and remove their health here (since "give health" gives them 100!)
			CreateTimer(0.5, Spirit_ChangeHP, hPack);

			//here we check if there's anyone else with
			//the spirit perk who's also incapped, so we
			//know if we should continue allowing crawling

			//first, check if crawling adjustments are allowed
			//if not, then just break right away
			/*if (g_iSpirit_crawling==0
				|| g_iSpirit_enable == 0)
				break;

			int iCrawlClient = -1;
			for (int iI2 = 1 ; iI2<=MaxClients ; iI2++)
			{
				if (g_iConfirm[iI2]==0) continue;
				if (g_iSur1[iI2]==3
					&& g_iPIncap[iI2]!=0)
				{
					iCrawlClient=iI2;
					break;
				}
			}
			if (iCrawlClient>0)
				SetConVarInt(FindConVar("survivor_allow_crawling"), 1, false, false);
			else
				SetConVarInt(FindConVar("survivor_allow_crawling"), 0, false, false);*/

			//finally, since spirit fired, break the loop
			//since we only want one person to self-revive at a time
			return;
		}
	}
	return;
}

//cooldown timer
Action Spirit_CooldownTimer(Handle timer, int iCid)
{
	KillTimer(timer);
	g_iSpiritTimer[iCid] = null;
	//if the cooldown's been turned off,
	//that means a new round has started
	//and we can skip everything here

	//if (IsServerProcessing() == false
		//|| g_iSpiritCooldown[iCid] == 0)
		//return Plugin_Stop;

	if (g_iSpiritCooldown[iCid] == 0)
		return Plugin_Stop;

	g_iSpiritCooldown[iCid] = 0;

	//and this sends the client a hint message
	if (IsClientInGame(iCid)
		&& IsPlayerAlive(iCid)
		&& SM_GetClientTeamType(iCid) == ClientTeam_Survivor
		&& IsFakeClient(iCid) == false)
		PrintHintText(iCid, "%t", "SpiritTimerFinishedMessage");

	return Plugin_Stop;
}

//timer for removing hp
//(like juggernaut, removing it too quickly
//confuses the game and doesn't remove it =/)
Action Spirit_ChangeHP(Handle timer, DataPack hPack)
{
	#if defined PM_DEBUG
	PrintToChatAll("\x05spirit\x03 init changehp");
	#endif

	//retrieve vars from pack
	hPack.Reset();
	int iCid = hPack.ReadCell();
	int iRevCount_ret = hPack.ReadCell();
	CloseHandle(hPack);

	//only execute spirit functions after checks pass
	if (IsServerProcessing()
		&& IsClientInGame(iCid)
		&& GetEntData(iCid, g_iIncapO) == 0
		&& IsPlayerAlive(iCid)
		&& SM_GetClientTeamType(iCid) == ClientTeam_Survivor)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x05spirit\x03 checks passed");
		#endif
		//set revive count after self-revive
		SetEntData(iCid, g_iRevCountO, iRevCount_ret+1, 1);
		if (iRevCount_ret+1 >= 2)
		{
			//borrowed from Crimson Fox's Black and White Defib code
			SetEntProp(iCid, Prop_Send, "m_isGoingToDie", 1);

			CreateTimer(1.0, Spirit_Warning1, iCid);
			CreateTimer(1.5, Spirit_Warning1, iCid);
			CreateTimer(2.0, Spirit_Warning1, iCid);
			CreateTimer(2.5, Spirit_Warning1, iCid);
		}
		//and we give them bonus health buffer here
		SetEntDataFloat(iCid, g_iHPBuffO, GetEntDataFloat(iCid, g_iHPBuffO) + g_iSpirit_buff, true);
		//set their health back to 1
		SetEntityHealth(iCid, 1);

		//get the proper cd number for the game mode
		int iTime;
		if (g_L4D_GameMode == GameMode_Versus)
			iTime = g_iSpirit_cd_vs;
		else if (g_L4D_GameMode == GameMode_Survival)
			iTime = g_iSpirit_cd_sur;
		else
			iTime = g_iSpirit_cd;

		//spirit-specific functions
		g_iSpiritTimer[iCid] = CreateTimer(iTime * 1.0, Spirit_CooldownTimer, iCid);
		g_bPIncap[iCid] = false;
		g_iSpiritCooldown[iCid] = 1;

		//show a message if it's not a bot
		if (iRevCount_ret + 1 >= 2)
			PrintHintText(iCid, "%t", "SpiritBWWarning");
		else
			PrintHintText(iCid, "%t: %t!", "PerkMenuSurvivorSecondPerkSpirit", "SpritSuccessMessage");
	}

	//always destroy the timer, since it's possible spirit may not have executed
	KillTimer(timer);
	CloseHandle(hPack);
	return Plugin_Stop;
}

Action Spirit_Warning1(Handle timer, int iCid)
{
	PrintToChat(iCid,"\x01***** \x03%t \x01*****", "SpiritBWWarning");

	KillTimer(timer);
	return Plugin_Stop;
}

//=============================
// MARK: - Sur2: Helping Hand
//=============================

//fired before reviving begins, reduces revive time
void HelpHand_OnReviveBegin(int iCid)
{
	//check if cvar changes are allowed
	//for this perk; if not, then stop
	if (g_bHelpHand_convar == false)
		return;

	//check if perk is enabled
	if (GameModeCheck(g_bSur2_enable, g_iHelpHand_enable) == false)
		return;

	//check for helping hand
	if (g_spSur[iCid].secondPerk == SurvivorSecondPerk_HelpingHand && g_bConfirm[iCid])
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x03-perk present, setting revive time to \x01%f", g_flReviveTime/2);
		#endif
		SetConVarFloat(FindConVar("survivor_revive_duration"), g_flReviveTime * g_flHelpHand_timemult, false, false);
		return;
	}

	//otherwise, reset the revive duration
	else
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x03-no perk, attempting to reset revive time to \x01%f", g_flReviveTime);
		#endif
		SetConVarFloat(FindConVar("survivor_revive_duration"), g_flReviveTime, false, false);
		return;
	}
}

void HelpHand_OnReviveSuccess(int iCid, int iSub, int iLedge)
{
	#if defined PM_DEBUG
	PrintToChatAll("\x05helphand\x03 reviver: \x01%i\x03, subject: \x01%i", iCid, iSub);
	#endif
	//then check for helping hand
	if (g_bConfirm[iCid] && g_spSur[iCid].secondPerk == SurvivorSecondPerk_HelpingHand && GameModeCheck(g_bSur2_enable, g_iHelpHand_enable))
	{
		switch (iLedge)
		{
		case 1:
			{
				g_iMyDisabler[iSub] = -1;

				#if defined PM_DEBUG
				PrintToChatAll("\x03-ledge hang save detected");
				#endif
			}
		case 0:
			{
				#if defined PM_DEBUG
				PrintToChatAll("\x03-m_healthBuffer offset: \x01%i", g_iHPBuffO);
				PrintToChatAll("\x03-client \x01%i\x03 value at offset: \x01%f", iSub, GetEntDataFloat(iSub, g_iHPBuffO));
				#endif

				int iBuff = (g_L4D_GameMode == GameMode_Versus ? g_iHelpHand_buff_vs : g_iHelpHand_buff);
				SetEntDataFloat(iSub, g_iHPBuffO, GetEntDataFloat(iSub, g_iHPBuffO) + iBuff, true);

				CreateTimer(0.5, HelpHand_Delayed, iCid);

				#if defined PM_DEBUG
				PrintToChatAll("\x03-value at offset, post-mod: \x01%f", GetEntDataFloat(iSub, g_iHPBuffO));
				#endif
				char st_name[24];
				GetClientName(iSub, st_name, sizeof(st_name));
				PrintHintText(iCid,"%t: %t %s!", "PerkMenuSurvivorSecondPerkHelpingHand", "HelpingHandDonorHint", st_name);
				GetClientName(iCid, st_name, sizeof(st_name));
				PrintHintText(iSub, "%t: %s %t", "PerkMenuSurvivorSecondPerkHelpingHand", st_name, "HelpingHandReceiverHint");
			}
		}
	}

	#if defined PM_DEBUG
	PrintToChatAll("\x03-revive end, attempting to reset revive time to \x01%f", g_flReviveTime);
	#endif
	//only adjust the convar if
	//convar changes are allowed
	//for this perk
	if (g_bHelpHand_convar && GameModeCheck(g_bSur2_enable, g_iHelpHand_enable))
		SetConVarFloat(FindConVar("survivor_revive_duration"), g_flReviveTime, false, false);

	//and then check if we need to continue allowing crawling
	//by running checks through everyone...
	//...but first, check if spirit convar changes are allowed
	/*if (g_iSur1_enable==1
		&& g_iSpirit_crawling==1
		&& (g_iSpirit_enable==1		&&	g_iL4D_GameMode==0
		|| g_iSpirit_enable_sur==1	&&	g_iL4D_GameMode==1
		|| g_iSpirit_enable_vs==1	&&	g_iL4D_GameMode==2))
	{
		int iCrawlClient = -1;
		for (int iI2 = 1 ; iI2<=MaxClients ; iI2++)
		{
			if (g_iConfirm[iI2]==0) continue;
			if (g_iSur2[iI2]==2
				&& g_iPIncap[iI2]!=0)
			{
				iCrawlClient=iI2;
				break;
			}
		}
		if (iCrawlClient>0)
			SetConVarInt(FindConVar("survivor_allow_crawling"), 1, false, false);
		else
			SetConVarInt(FindConVar("survivor_allow_crawling"), 0, false, false);
	}*/

	return;
}

Action HelpHand_Delayed(Handle timer, int iCid)
{
	if (IsServerProcessing() && IsValidEntity(iCid) && IsClientInGame(iCid) && SM_GetClientTeamType(iCid) == ClientTeam_Survivor)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x05helphand\x03 attempting to give reviver bonus to \x01%i", iCid);
		PrintToChatAll("\x03- health buffer time \x01%i %f", g_iHPBuffTimeO, GetEntDataFloat(iCid, g_iHPBuffTimeO));
		#endif

		SetEntDataFloat(iCid, g_iHPBuffTimeO, GetGameTime(), true);
		float flBuff_ret = GetEntDataFloat(iCid, g_iHPBuffO);
		if (flBuff_ret <= 0)
			flBuff_ret = 0.0;

		int iBuff = (g_L4D_GameMode == GameMode_Versus ? g_iHelpHand_buff_vs : g_iHelpHand_buff);
		SetEntDataFloat(iCid, g_iHPBuffO, flBuff_ret + iBuff/2 , true);
	}

	KillTimer(timer);
	return Plugin_Stop;
}

//=============================
// MARK: - Sur3: Pack Rat
//=============================

//on gun pickup
void PR_Pickup(int iCid, const char[] stWpn)
{
	if (g_spSur[iCid].thirdPerk == SurvivorThirdPerk_PackRat && GameModeCheck(g_bSur2_enable, g_iPack_enable))
	{
		if (StringInsensitiveContains(stWpn, "smg")
			|| StringInsensitiveContains(stWpn, "rifle")
			|| StringInsensitiveContains(stWpn, "shotgun")
			|| StringInsensitiveContains(stWpn, "sniper"))
		{
			PR_GiveFullAmmo(iCid);
		}
	}
}

//on ammo pickup, check if pack rat is in effect
Action Event_AmmoPickup(Event event, const char[] name, bool dontBroadcast)
{
	int iCid = GetClientOfUserId(event.GetInt("userid"));
	if (iCid == 0) return Plugin_Continue;

	if (g_bConfirm[iCid] && g_spSur[iCid].thirdPerk == SurvivorThirdPerk_PackRat &&  GameModeCheck(g_bSur3_enable, g_iPack_enable))
	{
		PR_GiveFullAmmo(iCid);
	}

	return Plugin_Continue;
}

void PR_GiveFullAmmo(int iCid)
{
	//formula: max + pack rat + max clip size - currently in clip
	//int iAmmoO = FindDataMapOffs(iCid,"m_iAmmo");

	if (g_bIsL4D2)
	{
		if (g_bPRalreadyApplying[iCid] == false)
		{
			g_bPRalreadyApplying[iCid] = true;
			CreateTimer(0.1, PR_GiveFullAmmo_delayed, iCid);
		}
	}
	else
	{
		int iAmmoO = FindDataMapInfo(iCid, "m_iAmmo");
		int iAmmoCount;

		//huntingrifle offset +8
		iAmmoCount = GetEntData(iCid, iAmmoO + 8);
		SetEntData(iCid, iAmmoO	+ 8, RoundToNearest(iAmmoCount * (1 + g_flPack_ammomult)) );
		//rifle - offset +12
		iAmmoCount = GetEntData(iCid, iAmmoO + 12);
		SetEntData(iCid, iAmmoO	+ 12, RoundToNearest(iAmmoCount * (1 + g_flPack_ammomult)) );
		//smg - offset +20
		iAmmoCount = GetEntData(iCid, iAmmoO + 20);
		SetEntData(iCid, iAmmoO	+ 20, RoundToNearest(iAmmoCount * (1 + g_flPack_ammomult)) );
		//shotgun - offset +24
		iAmmoCount = GetEntData(iCid, iAmmoO +24);
		SetEntData(iCid, iAmmoO	+ 24, RoundToNearest(iAmmoCount * (1 + g_flPack_ammomult)) );
	}

	return;
}

//new technique - instead of running off a convar, adjusts ammo
//relative to what player already has in inventory after a delay
Action PR_GiveFullAmmo_delayed (Handle timer, int iCid)
{
	KillTimer(timer);

	if (g_bPRalreadyApplying[iCid] == true)
		g_bPRalreadyApplying[iCid] = false;
	else
		return Plugin_Stop;

	if (IsServerProcessing() == false
		|| IsValidEntity(iCid) == false
		|| IsClientInGame(iCid) == false
		|| IsPlayerAlive(iCid) == false
		|| SM_GetClientTeamType(iCid) != ClientTeam_Survivor)
		return Plugin_Stop;

	int iAmmoO = FindDataMapInfo(iCid, "m_iAmmo");
	int iAmmoO_offset;
	int iAmmoCount;

	//checks each weapon type ammo in player's inventory
	//if non-zero, then assume player has that weapon
	//and adjust only that weapon's ammo

	#if defined PM_DEBUG
	int iI = 0;
	PrintToChatAll("\x05PR\x03 being feedback loop");
	while (iI <= 64)
	{
		iAmmoCount = GetEntData(iCid, iAmmoO + iI);
		PrintToChatAll("\x05PR\x03 iI = \x01%i\x03, value = \x01%i", iI, iAmmoCount);
		iI++;
	}
	#endif

	//rifle - offset +12
	iAmmoO_offset = 12;
	iAmmoCount = GetEntData(iCid, iAmmoO + iAmmoO_offset);
	if (iAmmoCount > 0)
	{
		SetEntData(iCid, iAmmoO	+ iAmmoO_offset, RoundToNearest(iAmmoCount * (1 + g_flPack_ammomult)) );
		//return Plugin_Stop;
	}
	//smg - offset +20
	iAmmoO_offset = 20;
	iAmmoCount = GetEntData(iCid, iAmmoO + iAmmoO_offset);
	if (iAmmoCount > 0)
	{
		SetEntData(iCid, iAmmoO	+ iAmmoO_offset, RoundToNearest(iAmmoCount * (1 + g_flPack_ammomult)) );
		//return Plugin_Stop;
	}
	//auto-shotgun - now offset +32
	iAmmoO_offset = 32;
	iAmmoCount = GetEntData(iCid, iAmmoO + iAmmoO_offset);
	if (iAmmoCount > 0)
	{
		SetEntData(iCid, iAmmoO	+ iAmmoO_offset, RoundToNearest(iAmmoCount * (1 + g_flPack_ammomult)) );
		//return Plugin_Stop;
	}
	//pump shotgun - now offset +28
	iAmmoO_offset = 28;
	iAmmoCount = GetEntData(iCid, iAmmoO + iAmmoO_offset);
	if (iAmmoCount > 0)
	{
		SetEntData(iCid, iAmmoO	+ iAmmoO_offset, RoundToNearest(iAmmoCount * (1 + g_flPack_ammomult)) );
		//return Plugin_Stop;
	}
	//huntingrifle offset +32 - now +36
	iAmmoO_offset = 36;
	iAmmoCount = GetEntData(iCid, iAmmoO + iAmmoO_offset);
	if (iAmmoCount > 0)
	{
		SetEntData(iCid, iAmmoO	+ iAmmoO_offset, RoundToNearest(iAmmoCount * (1 + g_flPack_ammomult)) );
		//return Plugin_Stop;
	}
	//militarysniper offset +36 - now +40
	iAmmoO_offset = 40;
	iAmmoCount = GetEntData(iCid, iAmmoO + iAmmoO_offset);
	if (iAmmoCount > 0)
	{
		SetEntData(iCid, iAmmoO	+ iAmmoO_offset, RoundToNearest(iAmmoCount * (1 + g_flPack_ammomult)) );
		//return Plugin_Stop;
	}
	//grenade launcher offset +64
	iAmmoO_offset = 64;
	iAmmoCount = GetEntData(iCid, iAmmoO + iAmmoO_offset);
	if (iAmmoCount > 0)
	{
		SetEntData(iCid, iAmmoO	+ iAmmoO_offset, RoundToNearest(iAmmoCount * (1 + g_flPack_ammomult)) );
		//return Plugin_Stop;
	}

	return Plugin_Stop;
}

//=============================
// MARK: - Sur3: Chem Reliant
//=============================

//on drug used
void Chem_OnDrugUsed(int iCid)
{
	//check if perk is enabled
	if (GameModeCheck(g_bSur3_enable, g_iChem_enable) == false)
		return;

	#if defined PM_DEBUG
	PrintToChatAll("\x03Pill user: \x01%i", iCid);
	#endif
	if (g_spSur[iCid].thirdPerk == SurvivorThirdPerk_ChemReliant && g_bConfirm[iCid])
	{
		float flBuff = GetEntDataFloat(iCid, g_iHPBuffO);
		int iHP = GetEntProp(iCid, Prop_Data, "m_iHealth");

		//so we need to test the maxbound for
		//how much health buffer we can give
		//which can vary depending on whether
		//they have unbreakable or not

		//CASE 1: HAS UNBREAKABLE
		if (g_spSur[iCid].secondPerk == SurvivorSecondPerk_Unbreakable && GameModeCheck(g_bSur3_enable, g_iUnbreak_enable))
		{
			//CASE 1A:
			//combined health + chem reliant < max health possible
			if (flBuff + iHP + g_iChem_buff < 100 + g_iUnbreak_hp)
				//this is the easiest, just give them chem reliant bonus
				SetEntDataFloat(iCid, g_iHPBuffO, flBuff+g_iChem_buff, true);

			//CASE 1B:
			//combined health + chem reliant > max health possible
			else
				//this is a bit trickier, give them the difference
				//between the max health possible and their current health
				SetEntDataFloat(iCid, g_iHPBuffO, (100.0+g_iUnbreak_hp)-iHP, true);
		}
		//CASE 2: DOES NOT HAVE UNBREAKABLE
		else
		{
			//CASE 1A:
			//combined health + chem reliant < max health possible
			if (flBuff + iHP + g_iChem_buff < 100)
				//this is the easiest, just give them chem reliant bonus
				SetEntDataFloat(iCid, g_iHPBuffO, flBuff+g_iChem_buff, true);

			//CASE 1B:
			//combined health + chem reliant > max health possible
			else
				//this is a bit trickier, give them the difference
				//between the max health possible and their current health
				SetEntDataFloat(iCid, g_iHPBuffO, 100.0-iHP, true);
		}
	}
	return;
}

//called on roundstart or on confirming perks,
//gives pills off the start
void Event_Confirm_ChemReliant(int iCid)
{
	if (iCid==0
		|| SM_GetClientTeamType(iCid) != ClientTeam_Survivor
		|| IsPlayerAlive(iCid) == false
		|| g_bConfirm[iCid] == false
		|| g_spSur[iCid].thirdPerk != SurvivorThirdPerk_ChemReliant)
		return;

	//check if perk is enabled
	if (GameModeCheck(g_bSur3_enable, g_iChem_enable) == false)
		return;

	int iflags = GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	if (g_bIsL4D2 == false || GetRandomInt(0, 1) == 1)
		FakeClientCommand(iCid,"give pain_pills");
	else
		FakeClientCommand(iCid,"give adrenaline");
	SetCommandFlags("give", iflags);

	return;
}

//=============================
// MARK: - Sur3: Hard to Kill
//=============================

void HardToKill_OnIncap(int iCid)
{
	if (SM_GetClientTeamType(iCid) != ClientTeam_Survivor || g_bConfirm[iCid] == false)
		return;

	if (GameModeCheck(g_bSur3_enable, g_iHard_enable) == false)
		return;

	if (g_spSur[iCid].thirdPerk == SurvivorThirdPerk_HardToKill)
	{
		CreateTimer(0.5, HardToKill_Delayed, iCid);

		#if defined PM_DEBUG
		PrintToChatAll("\x03-postfire values, health \x01%i", GetEntProp(iCid, Prop_Data, "m_iHealth"));
		#endif
	}
}

Action HardToKill_Delayed(Handle timer, int iCid)
{
	if (IsServerProcessing() && IsValidEntity(iCid) && IsClientInGame(iCid) && SM_GetClientTeamType(iCid) == ClientTeam_Survivor)
	{
		int iHP = GetEntProp(iCid, Prop_Data, "m_iHealth");

		SetEntProp(iCid, Prop_Data, "m_iHealth", iHP + RoundToNearest(iHP * g_flHard_hpmult));

		iHP = RoundToNearest(300 * (g_flHard_hpmult + 1));
		if (GetEntProp(iCid, Prop_Data, "m_iHealth") > iHP)
			SetEntProp(iCid, Prop_Data, "m_iHealth", iHP);
	}

	KillTimer(timer);
	return Plugin_Stop;
}

//=============================
// MARK: - Sur3: Little Leaguer
//=============================

void Event_Confirm_LittleLeaguer(int iCid)
{
	if (iCid == 0
		|| SM_GetClientTeamType(iCid) != ClientTeam_Survivor
		|| IsPlayerAlive(iCid) == false
		|| g_bConfirm[iCid] == false
		|| g_spSur[iCid].thirdPerk != SurvivorThirdPerk_LittleLeaguer)
		return;

	//check if perk is enabled
	if (GameModeCheck(g_bSur3_enable, g_iChem_enable) == false)
		return;

	int iflags = GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(iCid, "give baseball_bat");
	SetCommandFlags("give", iflags);

	return;
}

//=============================
// MARK: - Sur3: Extreme Conditioning
//=============================

void Extreme_Rebuild()
{
	//if the server's not running or
	//is in the middle of loading, stop
	if (IsServerProcessing() == false) return;

	//check if perk is enabled
	if (GameModeCheck(g_bSur3_enable, g_iExtreme_enable) == false)
		return;

	#if defined PM_DEBUG
	PrintToChatAll("\x03extreme cond rebuilding");
	#endif
	for (int iI = 1; iI <= MaxClients; iI++)
	{
		if (IsClientInGame(iI)
			&& IsPlayerAlive(iI)
			&& g_spSur[iI].thirdPerk == SurvivorThirdPerk_ExtremeConditioning
			&& g_bConfirm[iI]
			&& SM_GetClientTeamType(iI) == ClientTeam_Survivor)
		{
			SetEntDataFloat(iI, g_iLaggedMovementO, 1.0 * g_flExtreme_rate, true);

			#if defined PM_DEBUG
			PrintToChatAll("\x03-registering \x01%i", iI);
			#endif
		}
	}
}

//=============================
// MARK: - Boomer: Blind Luck
//=============================

void BlindLuck_OnIt(int iAtt, int iVic)
{
	//don't blind bots as per grandwaziri's plugin, they suck enough anyways
	if (g_ipInf[iAtt].boomerPerk == InfectedBoomerPerk_BlindLuck
		&& g_bConfirm[iAtt]
		&& IsFakeClient(iVic) == false)
	{
		//check if perk is enabled
		if (GameModeCheck(g_bInfBoomer_enable, g_iBlind_enable) == false)
			return;

		SetEntProp(iVic, Prop_Send, "m_iHideHUD", 64);

		#if defined PM_DEBUG
		PrintToChatAll("\x03-attempting to hide hud");
		#endif
	}
	return;
}

void BlindLuck_OnSpawn(int iCid)
{
	//stop if convar changes are disallowed for this perk
	if (GameModeCheck(g_bInfBoomer_enable, g_iBlind_enable) == false) return;

	if (g_ipInf[iCid].boomerPerk == InfectedBoomerPerk_BlindLuck)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x05drag\x03 creating timer");
		#endif
		CreateTimer(1.0, Timer_BlindLuckChecks, iCid, TIMER_REPEAT);
	}

	return ;
}

Action Timer_BlindLuckChecks(Handle timer, int iCid)
{
	//INITIAL CHECKS
	//--------------
	if (IsServerProcessing() == false
		|| iCid <= 0
		|| IsClientInGame(iCid) == false
		|| IsPlayerAlive(iCid) == false
		|| GetEntData(iCid, g_iClassO)!=2)
	{
		#if defined PM_DEBUG
		if (IsServerProcessing() == false)			PrintToChatAll("\x03- server not processing, stopping");
		else if (iCid <= 0)							PrintToChatAll("\x03- icid <= 0, stopping, client id \x01%i", iCid);
		else if (IsClientInGame(iCid) == false)		PrintToChatAll("\x03- client not in game, stopping");
		else if (IsPlayerAlive(iCid) == false)		PrintToChatAll("\x03- client not alive, stopping");
		else if (GetEntData(iCid, g_iClassO)!=1)	PrintToChatAll("\x03- class not correct, stopping, class id \x01%i", GetEntData(iCid, g_iClassO));
		#endif

		KillTimer(timer);
		return Plugin_Stop;
	}

	#if defined PM_DEBUG
	PrintToChatAll("\x03- \x05blind luck \x03 tick");
	#endif
	//RETRIEVE VARIABLES
	//------------------
	//get the ability ent id
	int iEntid = GetEntDataEnt2(iCid, g_iAbilityO);
	//if the retrieved gun id is -1, then move on
	if (iEntid == -1)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x03- ientid == -1, stopping");
		#endif

		KillTimer(timer);
		return Plugin_Stop;
	}

	//CHECK 1: AFTER ADJUSTED SHOT IS MADE
	//------------------------------------
	//at this point, either a gun was swapped, or
	//the attack time needs to be adjusted
	//also, only change timer if it's the first shot

	//retrieve current timestamp
	float flTimeStamp_ret = GetEntDataFloat(iEntid , g_iNextActO + 8);

	if (g_flTimeStamp[iCid] < flTimeStamp_ret)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x05BlindLuck:\x03 after adjusted shot\n-pre, client \x01%i\x03; entid \x01%i\x03; enginetime\x01 %f\x03; nextactivation: dur \x01 %f\x03 timestamp \x01%f", iCid, iEntid, GetGameTime(), GetEntDataFloat(iEntid, g_iNextActO+4), GetEntDataFloat(iEntid, g_iNextActO+8) );
		#endif

		//update the timestamp stored in plugin
		g_flTimeStamp[iCid] = flTimeStamp_ret;

		//this calculates the time that the player theoretically
		//should have used his ability in order to use it
		//with the shortened cooldown
		//FOR EXAMPLE:
		//vomit, normal cooldown 30s, desired cooldown 6s
		//player uses it at T = 1:30
		//normally, game predicts it to be ready at T + 30s
		//so if we modify T to 1:06, it will be ready at 1:36
		//which is 6s after the player used the ability
		float flTimeStamp_calc = flTimeStamp_ret - (FindConVar("z_vomit_interval").FloatValue * (1 - g_flBlind_cdmult));
		SetEntDataFloat(iEntid, g_iNextActO + 8, flTimeStamp_calc, true);

		#if defined PM_DEBUG
		PrintToChatAll("\x03-post, nextactivation dur \x01 %f\x03 timestamp \x01%f", GetEntDataFloat(iEntid, g_iNextActO+4), GetEntDataFloat(iEntid, g_iNextActO+8) );
		#endif
	}

	return Plugin_Continue;
}

//=============================
// MARK: - Boomer: Barf Bagged
//=============================

void BarfBagged_OnIt(int iAtt)
{
	//only spawn a mob if one guy got slimed
	//or if all four got slimed (max 2 extra mobs)
	if (g_ipInf[iAtt].boomerPerk == InfectedBoomerPerk_BarfBagged
		&& g_bConfirm[iAtt]
		&& (g_iSlimed == 1 || g_iSlimed == 4)
		&& SM_GetClientTeamType(iAtt) == ClientTeam_Infected)
	{
		//check if perk is enabled
		if (GameModeCheck(g_bInfBoomer_enable, g_iBarf_enable) == false) return;

		#if defined PM_DEBUG
		PrintToChatAll("\x03-attempting to spawn a mob, g_iSlimed=\x01%i", g_iSlimed);
		#endif
		int iflags = GetCommandFlags("z_spawn");
		SetCommandFlags("z_spawn", iflags & ~FCVAR_CHEAT);
		FakeClientCommand(iAtt,"z_spawn mob auto");
		SetCommandFlags("z_spawn", iflags);

		if (g_iSlimed == 4) PrintHintText(iAtt, "%t! %t", "PerkMenuInfectedBoomerBarfBagged", "BarfBaggedMobHint");
	}
	return;
}

//=============================
// MARK: - Boomer: Dead Wreckening
//=============================

//damage add
bool DeadWreckening_DamageAdd(int iAtt, int iVic, int iType, int iDmgOrig)
{
	if (iAtt == 0
		&& iType == 128
		&& g_iSlimed > 0
		&& g_bConfirm[g_iSlimerLast]
		&& g_ipInf[g_iSlimerLast].boomerPerk == InfectedBoomerPerk_DeadWreckening)
	{
		//check if perk is enabled
		if (!g_bInfBoomer_enable || !g_bDead_enable) return true;

		#if defined PM_DEBUG
		PrintToChatAll("\x03dead wreckening fire");
		#endif

		int iDmgAdd = DamageAddRound(iDmgOrig, g_flDead_dmgmult);
		if (iDmgAdd == 0) return false;

		InfToSurDamageAdd(iVic, iDmgAdd , iDmgOrig);

		return true;
	}
	return false;
}


//=============================
// MARK: - Boomer: Motion Sickness
//=============================

void Motion_OnSpawn(int iCid)
{
	//stop here if the perk is disabled
	if (!g_bMotion_enable || !g_bInfBoomer_enable) return;

	//check for motion sickness
	if (g_ipInf[iCid].boomerPerk == InfectedBoomerPerk_MotionSickness && g_bConfirm[iCid])
	{
		SetConVarFloat(FindConVar("z_vomit_fatigue"), 0.0, false, false);
		SetEntDataFloat(iCid, g_iLaggedMovementO, 1.0*g_flMotion_rate, true);
	}
	else
		SetConVarFloat(FindConVar("z_vomit_fatigue"), g_flVomitFatigue , false, false);
}

//=============================
// MARK: - Smoker: Tongue Twister
//=============================

void TongueTwister_OnAbilityUse(int iCid, const char[] stAb)
{
	//check for smoker-type perks
	if (StrEqual(stAb, "ability_tongue", false))
	{
		//stop if twister is disabled
		if (!g_bTongue_enable) return;

		//check for twister
		if (g_ipInf[iCid].smokerPerk == InfectedSmokerPerk_TongueTwister)
			SetConVarFloat(FindConVar("tongue_fly_speed"), g_flTongueFlySpeed*g_flTongue_speedmult, false, false);
		else
			SetConVarFloat(FindConVar("tongue_fly_speed"), g_flTongueFlySpeed, false, false);
	}
}

void TongueTwister_OnTongueGrab(int iCid)
{
	//stop if twister is disabled
	if (!g_bInfSmoker_enable || !g_bTongue_enable) return;

	#if defined PM_DEBUG
	PrintToChatAll("\x03yoink grab fired, client: \x01%i", iCid);
	#endif

	if (g_bConfirm[iCid] && g_ipInf[iCid].smokerPerk == InfectedSmokerPerk_TongueTwister)
		SetConVarFloat(FindConVar("tongue_victim_max_speed"), g_flTongueSpeed*g_flTongue_pullmult, false, false);
	else
		SetConVarFloat(FindConVar("tongue_victim_max_speed"), g_flTongueSpeed, false, false);
}

void TongueTwister_OnTongueRelease()
{
	if (g_bInfSmoker_enable && g_bTongue_enable)
	{
		CreateTimer(3.0, Timer_TongueRelease, 0);
	}
}

Action Timer_TongueRelease(Handle timer, any data)
{
	KillTimer(timer);
	if (IsServerProcessing() == false) return Plugin_Stop;

	SetConVarFloat(FindConVar("tongue_victim_max_speed"), g_flTongueSpeed, false, false);
	SetConVarFloat(FindConVar("tongue_fly_speed"), g_flTongueFlySpeed, false, false);

	return Plugin_Stop;
}

void TongueTwister_OnSpawn(int iCid)
{
	//stop here if twister is disabled
	if (!g_bInfSmoker_enable || !g_bTongue_enable) return;

	//check for tongue twister
	if (g_ipInf[iCid].smokerPerk == InfectedSmokerPerk_TongueTwister && g_bConfirm[iCid])
	{

		SetConVarFloat(FindConVar("tongue_range"), g_flTongueRange*g_flTongue_rangemult, false, false);
		#if defined PM_DEBUG
		PrintToChatAll("\x03-tongue range modified");
		#endif
	}
	//otherwise, just reset convar
	else
	{
		SetConVarFloat(FindConVar("tongue_range"), g_flTongueRange, false, false);

		#if defined PM_DEBUG
		PrintToChatAll("\x03-tongue range reset");
		#endif
	}
}


//=============================
// MARK: - Smoker: Squeezer
//=============================

//damage add function
bool Squeezer_DamageAdd(int iAtt, int iVic, ClientTeamType iTA, const char[] stWpn, int iDmgOrig)
{
	if (iTA == ClientTeam_Infected
		&& g_bConfirm[iAtt]
		&& StrEqual(stWpn, "smoker_claw")
		&& g_ipInf[iAtt].smokerPerk == InfectedSmokerPerk_Squeezer
		&& g_iMyDisableTarget[iAtt] == iVic)
	{
		//stop if perk is disabled
		if (!g_bInfSmoker_enable	|| !g_bSqueezer_enable) return true;

		int iDmgAdd = DamageAddRound(iDmgOrig, g_flSqueezer_dmgmult);
		if (iDmgAdd == 0) return false;

		InfToSurDamageAdd(iVic, iDmgAdd, iDmgOrig);
		return true;
	}
	return false;
}

//=============================
// MARK: - Smoker: Drag and Drop
//=============================

//alters cooldown to be faster
void Drag_OnTongueGrab(int iCid)
{
	#if defined PM_DEBUG
	PrintToChatAll("\x03drag and drop running checks");
	#endif
	//stop if drag and drop is disabled
	if (!g_bInfSmoker_enable || !g_bDrag_enable) return;

	//if attacker id is null, reset vars
	if (iCid <= 0)
	{
		SetConVarInt(FindConVar("tongue_allow_voluntary_release"), 0, false, false);
		SetConVarFloat(FindConVar("tongue_player_dropping_to_ground_time"), g_flTongueDropTime, false, false);
		return ;
	}

	//check for drag and drop
	if (g_ipInf[iCid].smokerPerk == InfectedSmokerPerk_DragAndDrop && g_bConfirm[iCid])
	{
		SetConVarInt(FindConVar("tongue_allow_voluntary_release"), 1, false, false);
		SetConVarFloat(FindConVar("tongue_player_dropping_to_ground_time"), 0.2, false, false);

		return ;
	}
	//all else fails, reset vars
	else
	{
		SetConVarInt(FindConVar("tongue_allow_voluntary_release"), 0, false, false);
		SetConVarFloat(FindConVar("tongue_player_dropping_to_ground_time"), g_flTongueDropTime, false, false);
		return ;
	}
}

bool Drag_OnSpawn(int iCid)
{
	//stop if grasshopper is disabled
	if (!g_bInfSmoker_enable || !g_bDrag_enable) return false;

	if (SM_GetClientTeamType(iCid) == ClientTeam_Infected
		&& g_ipInf[iCid].smokerPerk == InfectedSmokerPerk_DragAndDrop
		&& g_bConfirm[iCid])
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x05drag\x03 creating timer");
		#endif
		CreateTimer(1.0, Timer_DragChecks, iCid, TIMER_REPEAT);
		return true;
	}

	return false;
}

Action Timer_DragChecks(Handle timer, int iCid)
{
	//INITIAL CHECKS
	//--------------
	if (IsServerProcessing() == false
		|| iCid <= 0
		|| IsClientInGame(iCid) == false
		|| IsPlayerAlive(iCid) == false
		|| GetEntData(iCid, g_iClassO) != 1)
	{
		#if defined PM_DEBUG
		if (IsServerProcessing() == false)			PrintToChatAll("\x03- server not processing, stopping");
		else if (iCid <= 0)							PrintToChatAll("\x03- icid <= 0, stopping, client id \x01%i", iCid);
		else if (IsClientInGame(iCid) == false)		PrintToChatAll("\x03- client not in game, stopping");
		else if (IsPlayerAlive(iCid) == false)		PrintToChatAll("\x03- client not alive, stopping");
		else if (GetEntData(iCid, g_iClassO)!=1)	PrintToChatAll("\x03- class not correct, stopping, class id \x01%i", GetEntData(iCid, g_iClassO));
		#endif
		KillTimer(timer);
		return Plugin_Stop;
	}

	#if defined PM_DEBUG
	PrintToChatAll("\x03- \x05drag\x03 tick");
	#endif
	//RETRIEVE VARIABLES
	//------------------
	//get the ability ent id
	int iEntid = GetEntDataEnt2(iCid, g_iAbilityO);
	//if the retrieved gun id is -1, then move on
	if (iEntid == -1)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x03- ientid == -1, stopping");
		#endif
		KillTimer(timer);
		return Plugin_Stop;
	}
	//retrieve the next act time
	float flDuration_ret = GetEntDataFloat(iEntid, g_iNextActO + 4);

	//CHECK 1: PAUSE?
	//---------------
	//Valve seems to have a weird way of forcing a
	//pause before the cooldown timer starts: by setting
	//the timers to some arbitrarily high number =/
	//IIRC no cooldown exceeds 100s (highest is 30?) so
	//if any values exceed 100, then let timer continue running
	if (flDuration_ret > 100.0)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x03DT retrieved duration > 100");
		#endif
		return Plugin_Continue;
	}

	//CHECK 2: AFTER ADJUSTED SHOT IS MADE
	//------------------------------------
	//at this point, either a gun was swapped, or
	//the attack time needs to be adjusted
	//also, only change timer if it's the first shot

	//retrieve current timestamp
	float flTimeStamp_ret = GetEntDataFloat(iEntid, g_iNextActO + 8);

	if (g_flTimeStamp[iCid] < flTimeStamp_ret)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x05Drag:\x03 after adjusted shot\n-pre, client \x01%i\x03; entid \x01%i\x03; enginetime\x01 %f\x03; nextactivation: dur \x01 %f\x03 timestamp \x01%f", iCid, iEntid, GetGameTime(), GetEntDataFloat(iEntid, g_iNextActO+4), GetEntDataFloat(iEntid, g_iNextActO+8) );
		#endif
		//update the timestamp stored in plugin
		g_flTimeStamp[iCid] = flTimeStamp_ret;

		//this calculates the time that the player theoretically
		//should have used his ability in order to use it
		//with the shortened cooldown
		//FOR EXAMPLE:
		//vomit, normal cooldown 30s, desired cooldown 6s
		//player uses it at T = 1:30
		//normally, game predicts it to be ready at T + 30s
		//so if we modify T to 1:06, it will be ready at 1:36
		//which is 6s after the player used the ability
		float flTimeStamp_calc = flTimeStamp_ret - (FindConVar("tongue_hit_delay").FloatValue * (1 - g_flDrag_cdmult));
		SetEntDataFloat(iEntid, g_iNextActO + 8, flTimeStamp_calc, true);

		#if defined PM_DEBUG
		PrintToChatAll("\x03-post, nextactivation dur \x01 %f\x03 timestamp \x01%f", GetEntDataFloat(iEntid, g_iNextActO+4), GetEntDataFloat(iEntid, g_iNextActO+8) );
		#endif
	}

	return Plugin_Continue;
}

//=============================
// MARK: - Smoker: Smoke IT!
//=============================

Action SmokeIt_OnTongueGrab(int smoker, int victim)
{
	if (!g_bInfSmoker_enable || !g_bSmokeIt_enable || g_ipInf[smoker].smokerPerk != InfectedSmokerPerk_SmokeIt || !g_bConfirm[smoker])
		return Plugin_Continue;

	//new Smoker = GetClientOfUserId(event.GetInt("userid"));
	if (IsFakeClient(smoker)) return Plugin_Continue;

	g_bSmokeItGrabbed[smoker] = true;
	SetEntityMoveType(smoker, MOVETYPE_ISOMETRIC);
	SetEntDataFloat(smoker, g_iLaggedMovementO, g_flSmokeItSpeed, true);

	DataPack pack = CreateDataPack();
	pack.WriteCell(smoker);
	pack.WriteCell(victim);
	g_hSmokeItTimer[smoker] = CreateDataTimer(0.2, SmokeItTimerFunction, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);

	return Plugin_Continue;
}

Action SmokeItTimerFunction(Handle timer, DataPack pack)
{
	pack.Reset();

	int smoker = pack.ReadCell();
	if (!IsValidClient(smoker) || IsFakeClient(smoker) || (SM_GetClientTeamType(smoker) != ClientTeam_Infected) || (g_bSmokeItGrabbed[smoker] = false))
	{
		g_hSmokeItTimer[smoker] = null;
		CloseHandle(pack);
		return Plugin_Stop;
	}

	int victim = pack.ReadCell();
	if (!IsValidClient(victim) || (SM_GetClientTeamType(victim) != ClientTeam_Survivor) || (g_bSmokeItGrabbed[smoker] = false))
	{
		g_hSmokeItTimer[smoker] = null;
		CloseHandle(pack);
		return Plugin_Stop;
	}

	float smokerPosition[3];
	float victimPosition[3];
	GetClientAbsOrigin(smoker, smokerPosition);
	GetClientAbsOrigin(victim, victimPosition);

	int distance = RoundToNearest(GetVectorDistance(smokerPosition, victimPosition));
	if (distance > g_iSmokeItMaxRange)
	{
		SlapPlayer(smoker, 0, false);
	}
	return Plugin_Continue;
}

Action SmokeIt_OnTongueRelease(int smoker)
{
	//new Smoker = GetClientOfUserId(event.GetInt("userid"));
	g_bSmokeItGrabbed[smoker] = false;

	SetEntityMoveType(smoker, MOVETYPE_CUSTOM);
	SetEntDataFloat(smoker, g_iLaggedMovementO, 1.0, true);

	if (g_hSmokeItTimer[smoker] != INVALID_HANDLE)
	{
		KillTimer(g_hSmokeItTimer[smoker], true);
		g_hSmokeItTimer[smoker] = null;
	}

	return Plugin_Continue;
}

bool IsValidClient(int client)
{
	if (client == 0) return false;

	if (!IsClientConnected(client))
		return false;

	//if (IsFakeClient(client))
		//return false;

	if (!IsClientInGame(client))
		return false;

	if (!IsPlayerAlive(client))
		return false;
	return true;
}


//=============================
// MARK: - Hunter: Body Slam
//=============================

//damage function
bool BodySlam_DamageAdd(int iAtt, int iVic, ClientTeamType iTA, int iType, const char[] stWpn, int iDmgOrig)
{
	if (iTA == ClientTeam_Infected
		&& g_bConfirm[iAtt]
		&& StrEqual(stWpn, "hunter_claw")
		&& iType == 1
		&& g_ipInf[iAtt].hunterPerk == InfectedHunterPerk_BodySlam)
	{
		//stop if body slam is disabled
		if (!g_bInfHunter_enable || !g_bBody_enable) return true;

		#if defined PM_DEBUG
		PrintToChatAll("\x03body slam check");
		#endif

		int iMinBound = g_iBody_minbound;
		//body slam only fires if pounce damage
		//was less than 8 (sets minimum pounce damage)
		//or whatever the minimum bound is (was originally 8...)
		if (iDmgOrig < iMinBound)
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x03body slam fire, running checks");
			#endif
			int iHP = GetEntProp(iVic, Prop_Data, "m_iHealth");

			//if health>8, then run normally
			if (iHP > iMinBound)
			{
				#if defined PM_DEBUG
				PrintToChatAll("\x03iHP>8 condition");
				#endif
				SetEntProp(iVic, Prop_Data, "m_iHealth", iHP-(iMinBound-iDmgOrig) );
				PrintHintText(iAtt, "%t: %i %t!", "PerkMenuInfectedHunterBodySlam", iMinBound-iDmgOrig, "BonusDamageText");

				#if defined PM_DEBUG
				PrintToChatAll("\x03-%i bonus damage", (iMinBound-iDmgOrig) );
				#endif
				return true;
			}
			//otherwise, we gotta do a bit of work
			//if survivor's health is
			//less than or equal to 8
			else
			{
				#if defined PM_DEBUG
				PrintToChatAll("\x03iHP<8 condition");
				PrintToChatAll("\x03-iDmgOrig<8 and iHP>1, iDmgOrig: \x01%i\x03, pre-mod iHP: \x01%i", iDmgOrig, iHP);
				#endif

				float flHPBuff = GetEntDataFloat(iVic, g_iHPBuffO);

				//if victim has health buffer,
				//we need to do some extra work
				//to reduce health buffer as well
				if (flHPBuff > 0)
				{
					#if defined PM_DEBUG
					PrintToChatAll("\x03-flHPBuff>0 condition, pre-mod HPbuffer: \x01%f", flHPBuff);
					#endif
					int iDmgAdd = iMinBound - iDmgOrig;

					//if damage add exceeds health,
					//then we need to take the difference
					//and apply it to health buffer instead
					if (iDmgAdd >= iHP)
					{
						#if defined PM_DEBUG
						PrintToChatAll("\x03-iDmgAdd>=iHP condition, pre-mod iDmgAdd: \x01%i", iDmgAdd);
						#endif
						//we leave the survivor with 1 health
						//because the engine will take it away
						//when it applies the original damage
						//and we want to avoid strange death behaviour
						int iDmgCount = iHP - 1;
						iDmgAdd -= iDmgCount;
						SetEntProp(iVic, Prop_Data, "m_iHealth", iHP-iDmgCount);

						//if damage add is more than health buffer,
						//set damage add to health buffer amount
						int iHPBuff = RoundToFloor(flHPBuff);
						if (iHPBuff < iDmgAdd) iDmgAdd = iHPBuff;
						SetEntDataFloat(iVic, g_iHPBuffO, flHPBuff-iDmgAdd, true);
						PrintHintText(iAtt, "%t: %i bonus damage!", "PerkMenuInfectedHunterBodySlam", iDmgCount+iDmgAdd);

						#if defined PM_DEBUG
						PrintToChatAll("\x03-damage to health: \x01%i\x03, current health: \x01%i", iDmgCount, GetEntProp(iVic, Prop_Data,"m_iHealth"));
						#endif						//PrintToChatAll("\x03-damage to buffer: \x01%i\x03, current buffer: \x01%f", iDmgAdd, GetEntDataFloat(iVic, g_iHPBuffO));

						return true;
					}

					//if damage add is less than health
					//remaining, then we simply deal
					//the extra damage and let the engine
					//deal with the rest
					else
					{
						#if defined PM_DEBUG
						PrintToChatAll("\x03-iDmgAdd<iHP condition");
						#endif
						SetEntProp(iVic, Prop_Data, "m_iHealth", iHP-iDmgAdd);
						PrintHintText(iAtt, "Body Slam: %i bonus damage!", iDmgAdd);
						return true;
					}
				}

				//otherwise, it's straightforward
				//- just reduce victim's hp
				else
				{
					#if defined PM_DEBUG
					PrintToChatAll("\x03no temp hp condition");
					#endif
					//if original damage exceeds health,
					//just skip the rest since there's no
					//health buffer to worry about
					if (iDmgOrig >= iHP) return true;
					int iDmgAdd = iMinBound - (iHP - iDmgOrig);
					//to prevent strange death behaviour,
					//reduce damage add to less than that
					//of remaining health if necessary
					if (iDmgAdd >= iHP) iDmgAdd = iHP - 1;
					SetEntProp(iVic, Prop_Data, "m_iHealth", iHP-iDmgAdd);
					PrintHintText(iAtt, "%t: %i bonus damage!", "PerkMenuInfectedHunterBodySlam", iDmgAdd);

					#if defined PM_DEBUG
					PrintToChatAll("\x03-iHP<8, %i bonus damage", iDmgAdd);
					#endif
					return true;
				}
			}
		}
		return true;
	}

	return false;
}


//=============================
// MARK: - Hunter: Efficient Killer
//=============================

//damage function
bool EfficientKiller_DamageAdd(int iAtt, int iVic, ClientTeamType iTA, int iType, const char[] stWpn, int iDmgOrig)
{
	if (iTA == ClientTeam_Infected
		&& g_bConfirm[iAtt]
		&& StrEqual(stWpn, "hunter_claw")
		&& iType == 128
		&& g_ipInf[iAtt].hunterPerk == InfectedHunterPerk_EfficientKiller)
	{
		//stop if eff.killer is disabled
		if (!g_bInfHunter_enable || g_bEfficient_enable) return true;

		int iDmgAdd = DamageAddRound(iDmgOrig, g_flEfficient_dmgmult);
		if (iDmgAdd == 0) return false;

		InfToSurDamageAdd(iVic, iDmgAdd , iDmgOrig);
		return true;
	}

	return false;
}

//=============================
// MARK: - Hunter: Speed Demon
//=============================

//damage function
bool SpeedDemon_DamageAdd(int iAtt, int iVic, ClientTeamType iTA, int iType, const char[] stWpn, int iDmgOrig)
{
	if (iTA == ClientTeam_Infected
		&& g_bConfirm[iAtt]
		&& StrEqual(stWpn,"hunter_claw")
		&& iType == 128
		&& g_ipInf[iAtt].hunterPerk == InfectedHunterPerk_SpeedDemon
		&& g_iMyDisableTarget[iAtt] == -1)
	{
		//stop if eff.killer is disabled
		if (!g_bInfHunter_enable || !g_bEfficient_enable) return true;

		int iDmgAdd = DamageAddRound(iDmgOrig, g_flSpeedDemon_dmgmult);
		if (iDmgAdd == 0) return false;

		#if defined PM_DEBUG
		PrintToChatAll("\x05speed demon\x03 damage bonus \x01%i", iDmgAdd);
		#endif

		InfToSurDamageAdd(iVic, iDmgAdd, iDmgOrig);
		return true;
	}

	return false;
}

bool SpeedDemon_OnSpawn(int iCid)
{
	//stop here if the perk is disabled
	if (!g_bSpeedDemon_enable || !g_bInfHunter_enable)
		return false;

	//check for motion sickness
	if (g_ipInf[iCid].hunterPerk == InfectedHunterPerk_SpeedDemon && g_bConfirm[iCid])
	{
		SetEntDataFloat(iCid, g_iLaggedMovementO, 1.0*g_flSpeedDemon_rate, true);
		return true;
	}
	else
		SetEntDataFloat(iCid, g_iLaggedMovementO, 1.0, true);

	return false;
}

//=============================
// MARK: - Hunter: Grasshopper
//=============================

bool Grass_OnAbilityUse(int iCid, const char[] stAb)
{
	//stop if grasshopper is disabled
	if (!g_bInfHunter_enable || !g_bGrass_enable)
		return false;

	if (SM_GetClientTeamType(iCid) == ClientTeam_Infected
		&& g_ipInf[iCid].hunterPerk == InfectedHunterPerk_Grasshopper
		&& g_bConfirm[iCid])
	{
		//check if it's a pounce/lunge
		if (StrEqual(stAb, "ability_lunge", false))
		{
			CreateTimer(0.1, Grasshopper_DelayedVel, iCid);

			#if defined PM_DEBUG
			PrintToChatAll("\x03grasshopper fired");
			#endif
			return true;
		}
	}

	return false;
}

//delayed velocity change, since the hunter doesn't
//actually start moving until some time after the event
Action Grasshopper_DelayedVel(Handle timer, int iCid)
{
	KillTimer(timer);
	if (IsServerProcessing() == false)
		return Plugin_Stop;

	float vecVelocity[3];
	GetEntPropVector(iCid, Prop_Data, "m_vecVelocity", vecVelocity);
	vecVelocity[0] *= g_flGrass_rate;
	vecVelocity[1] *= g_flGrass_rate;
	vecVelocity[2] *= g_flGrass_rate;
	TeleportEntity(iCid, NULL_VECTOR, NULL_VECTOR, vecVelocity);

	return Plugin_Stop;
}


//=============================
// MARK: - Jockey: Ride Like the Wind
//=============================

//for wind to work, must change VICTIM's speed
void Wind_OnRideStart(int iAtt, int iVic)
{
	if (g_ipInf[iAtt].jockeyPerk == InfectedJockeyPerk_Wind
		&& g_bConfirm[iAtt]
		&& g_bInfJockey_enable
		&& g_bWind_enable)
	{
		SetEntDataFloat(iVic, g_iLaggedMovementO, 1.0 * g_flWind_rate, true);

		#if defined PM_DEBUG
		PrintToChatAll("\x03-wind apply");
		#endif
	}
	else
		//reset their run speed
		SetEntDataFloat(iVic, g_iLaggedMovementO, 1.0, true);
}

void Wind_OnRideEnd(int iAtt, int iVic)
{
	#if defined PM_DEBUG
	PrintToChatAll("\x03-wind remove");
	#endif

	//reset their run speed
	SetEntDataFloat(iAtt, g_iLaggedMovementO, 1.0, true);
	SetEntDataFloat(iVic, g_iLaggedMovementO, 1.0, true);
}

//=============================
// MARK: - Jockey: Cavalier
//=============================

//set hp after a small delay, to avoid stupid bugs
bool Cavalier_OnSpawn(int iCid)
{
	//stop here if the perk is disabled
	if (!g_bCavalier_enable || !g_bInfJockey_enable) return false;

	//check for perk
	if (g_ipInf[iCid].jockeyPerk == InfectedJockeyPerk_Cavalier && g_bConfirm[iCid])
	{
		CreateTimer(0.1, Cavalier_ChangeHP, iCid);
		return true;
	}
	return false;
}

Action Cavalier_ChangeHP(Handle timer, int iCid)
{
	KillTimer(timer);

	if (IsServerProcessing() == false
		|| iCid <= 0
		|| IsClientInGame(iCid) == false
		|| SM_GetClientTeamType(iCid) != ClientTeam_Infected)
		return Plugin_Stop;

	SetEntityHealth(iCid, RoundToNearest(GetEntProp(iCid, Prop_Data, "m_iHealth") * (1+g_flCavalier_hpmult) ) );

	float flMaxHP = FindConVar("z_jockey_health").IntValue * (1+g_flCavalier_hpmult);
	if (GetEntProp(iCid, Prop_Data, "m_iHealth") > flMaxHP)
		SetEntProp(iCid, Prop_Data, "m_iHealth", RoundToNearest(flMaxHP));

	return Plugin_Stop;
}

//=============================
// MARK: - Jockey: Frogger
//=============================

bool Frogger_DamageAdd(int iAtt, int iVic, ClientTeamType iTA, const char[] stWpn, int iDmgOrig)
{
	if (iTA == ClientTeam_Infected
		&& g_bConfirm[iAtt]
		&& StrEqual(stWpn, "jockey_claw")
		&& g_ipInf[iAtt].jockeyPerk == InfectedJockeyPerk_Frogger)
	{
		//stop if frogger is disabled
		if (!g_bInfJockey_enable || !g_bFrogger_enable) return true;

		int iDmgAdd = DamageAddRound(iDmgOrig, g_flFrogger_dmgmult);
		if (iDmgAdd == 0) return false;

		#if defined PM_DEBUG
		PrintToChatAll("\x05frogger\x03 damage \x01%i", iDmgAdd);
		#endif
		InfToSurDamageAdd(iVic, iDmgAdd, iDmgOrig);
		return true;
	}

	return false;
}

bool Frogger_OnJump(int iCid)
{
	//stop if frogger is disabled
	if (!g_bInfJockey_enable || !g_bFrogger_enable || SM_IntToInfectedType(GetEntData(iCid, g_iClassO), g_bIsL4D2) != Infected_Jockey) return false;

	if (SM_GetClientTeamType(iCid) == ClientTeam_Infected
		&& g_ipInf[iCid].jockeyPerk == InfectedJockeyPerk_Frogger
		&& g_bConfirm[iCid])
	{
		CreateTimer(0.1, Frogger_DelayedVel, iCid);

		#if defined PM_DEBUG
		PrintToChatAll("\x05frogger\x03 fired");
		#endif
		return true;
	}

	return false;
}

//delayed velocity change, since the hunter doesn't
//actually start moving until some time after the event
Action Frogger_DelayedVel(Handle timer, int iCid)
{
	KillTimer(timer);
	if (IsServerProcessing() == false)
		return Plugin_Stop;

	float vecVelocity[3];
	GetEntPropVector(iCid, Prop_Data, "m_vecVelocity", vecVelocity);
	vecVelocity[0] *= g_flFrogger_rate;
	vecVelocity[1] *= g_flFrogger_rate;
	vecVelocity[2] *= g_flFrogger_rate;
	TeleportEntity(iCid, NULL_VECTOR, NULL_VECTOR, vecVelocity);

	return Plugin_Stop;
}

//=============================
// MARK: - Jockey: Ghost Rider
//=============================

bool Ghost_OnSpawn(int iCid)
{
	//stop if frogger is disabled
	if (!g_bInfJockey_enable || !g_bGhost_enable) return false;

	if (SM_GetClientTeamType(iCid) == ClientTeam_Infected
		&& g_ipInf[iCid].jockeyPerk == InfectedJockeyPerk_Ghost
		&& g_bConfirm[iCid])
	{
		SetEntityRenderMode(iCid, RENDER_TRANSCOLOR);
		SetEntityRenderColor(iCid, 190, 190, 255, g_iGhost_alpha);

		#if defined PM_DEBUG
		PrintToChatAll("\x03ghost rider fired");
		#endif
		return true;
	}

	return false;
}



//=============================
// MARK: - Spitter: Twin Spitfire
//=============================

void TwinSF_ResetShotCount(int iCid)
{
	g_iTwinSFShotCount[iCid] = 0;
}

bool TwinSF_OnSpawn(int iCid)
{
	#if defined PM_DEBUG
	PrintToChatAll("\x05twin sf\x03 on spawn");
	#endif

	//stop if grasshopper is disabled
	if (!g_bInfSpitter_enable || !g_bTwinSF_enable) return false;

	if (SM_GetClientTeamType(iCid) == ClientTeam_Infected
		&& g_ipInf[iCid].spitterPerk == InfectedSpitterPerk_TwinSpitfire
		&& g_bConfirm[iCid])
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x03- creating timer");
		#endif
		//update the timestamp stored in plugin to prevent confusion for timer function
		g_flTimeStamp[iCid] = GetEntDataFloat(GetEntDataEnt2(iCid, g_iAbilityO), g_iNextActO+8);
		//reset the shot count
		TwinSF_ResetShotCount(iCid);

		//create the timer to keep changing the spitter's delay
		CreateTimer(1.0, Timer_TwinSFChecks, iCid, TIMER_REPEAT);

		return true;
	}

	return false;
}

Action Timer_TwinSFChecks(Handle timer, int iCid)
{
	//INITIAL CHECKS
	//--------------
	if (IsServerProcessing() == false
		|| iCid <= 0
		|| IsClientInGame(iCid) == false
		|| IsPlayerAlive(iCid) == false
		|| SM_IntToInfectedType(GetEntData(iCid, g_iClassO), g_bIsL4D2) != Infected_Spitter)
	{
		g_iTwinSFShotCount[iCid] = 0;
		KillTimer(timer);
		return Plugin_Stop;
	}

	#if defined PM_DEBUG
	PrintToChatAll("\x03- tick");
	#endif
	//RETRIEVE VARIABLES
	//------------------
	//get the ability ent id
	int iEntid = GetEntDataEnt2(iCid, g_iAbilityO);
	//if the retrieved gun id is -1, then move on
	if (iEntid == -1)
	{
		g_iTwinSFShotCount[iCid] = 0;
		KillTimer(timer);
		return Plugin_Stop;
	}
	//retrieve the next act time
	float flDuration_ret = GetEntDataFloat(iEntid, g_iNextActO + 4);

	//CHECK 1: PAUSE?
	//---------------
	//Valve seems to have a weird way of forcing a
	//pause before the cooldown timer starts: by setting
	//the timers to some arbitrarily high number =/
	//IIRC no cooldown exceeds 100s (highest is 30?) so
	//if any values exceed 100, then let timer continue running
	if (flDuration_ret > 100.0)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x03TS retrieved duration > 100");
		#endif
		return Plugin_Continue;
	}

	//CHECK 2: AFTER ADJUSTED SHOT IS MADE
	//------------------------------------
	//at this point, either a gun was swapped, or
	//the attack time needs to be adjusted
	//also, only change timer if it's the first shot

	//retrieve current timestamp
	float flTimeStamp_ret = GetEntDataFloat(iEntid, g_iNextActO + 8);

	if (g_flTimeStamp[iCid] < flTimeStamp_ret)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x05TwinSF:\x03 after adjusted shot\n-pre, client \x01%i\x03; entid \x01%i\x03; enginetime\x01 %f\x03; nextactivation: dur \x01 %f\x03 timestamp \x01%f", iCid, iEntid, GetGameTime(), GetEntDataFloat(iEntid, g_iNextActO+4), GetEntDataFloat(iEntid, g_iNextActO+8) );
		#endif
		//update the timestamp stored in plugin
		g_flTimeStamp[iCid] = flTimeStamp_ret;
		//increase the shot count
		g_iTwinSFShotCount[iCid]++;

		#if defined PM_DEBUG
		PrintToChatAll("\x05TwinSF\x03 shot count \x01%i", g_iTwinSFShotCount[iCid]);
		#endif
		//check how many shots have been made
		if (g_iTwinSFShotCount[iCid] >= 3)
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x05TwinSF\x03 shot count >=3, setting to x-2");
			#endif
			//reset shot count if more than 3 shots have been made
			g_iTwinSFShotCount[iCid] -= 2;
		}
		else if (g_iTwinSFShotCount[iCid] == 2)
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x05TwinSF\x03 shot count ==2, continuing");
			#endif
			//don't do anything if one shot has been made
			return Plugin_Continue;
		}

		//this calculates the time that the player theoretically
		//should have used his ability in order to use it
		//with the shortened cooldown
		//FOR EXAMPLE:
		//vomit, normal cooldown 30s, desired cooldown 6s
		//player uses it at T = 1:30
		//normally, game predicts it to be ready at T + 30s
		//so if we modify T to 1:06, it will be ready at 1:36
		//which is 6s after the player used the ability
		float flTimeStamp_calc = flTimeStamp_ret - (FindConVar("z_spit_interval").FloatValue - g_flTwinSF_delay);
		SetEntDataFloat(iEntid, g_iNextActO + 8, flTimeStamp_calc, true);

		#if defined PM_DEBUG
		PrintToChatAll("\x03-post, nextactivation dur \x01 %f\x03 timestamp \x01%f", GetEntDataFloat(iEntid, g_iNextActO+4), GetEntDataFloat(iEntid, g_iNextActO+8) );
		#endif
	}

	return Plugin_Continue;
}

//=============================
// MARK: - Spitter: Mega Adhesive
//=============================

bool MegaAd_SlowEffect(int iAtt, int iVic, const char[] stWpn)
{
	if (g_bConfirm[iAtt]
		&& StrEqual(stWpn, "insect_swarm")
		&& g_ipInf[iAtt].spitterPerk == InfectedSpitterPerk_MegaAdhesive)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x05megaadhesive\x03 fire, client \x01%i\x03, pre-mod amount \x01%i", iVic, g_iMegaAdCount[iVic]);
		#endif
		if (g_iMegaAdCount[iVic] <= 0)
		{
			g_iMegaAdCount[iVic] = 10;

			//check if another SI is disabling the survivor
			int iDisabler = g_iMyDisabler[iVic];
			if (iDisabler == -1)
				SetEntDataFloat(iVic, g_iLaggedMovementO, g_flMegaAd_slow, true);
			else
			{
				//check if disabler is valid
				//if not, then just apply normal effects
				if (IsValidEntity(iDisabler) == false
					|| IsClientConnected(iDisabler) == false
					|| IsClientInGame(iDisabler) == false)
					SetEntDataFloat(iVic, g_iLaggedMovementO, g_flMegaAd_slow, true);
				//otherwise if it's valid, then check the class
				//don't apply slow for jockeys or smokers
				else
				{
					InfectedType iType = SM_IntToInfectedType(GetEntData(iDisabler, g_iClassO), g_bIsL4D2);
					if (iType != Infected_Smoker && iType != Infected_Jockey)
						SetEntDataFloat(iVic, g_iLaggedMovementO, g_flMegaAd_slow, true);
				}
			}
		}
		else
			g_iMegaAdCount[iVic]++;

		if (g_hMegaAdTimer[iVic] == INVALID_HANDLE)
			g_hMegaAdTimer[iVic] = CreateTimer(0.3, MegaAd_Timer, iVic, TIMER_REPEAT);

		return true;
	}
	return false;
}

Action MegaAd_Timer(Handle timer, int iVic)
{
	if (IsServerProcessing() == false
		|| IsValidEntity(iVic) == false
		|| IsClientConnected(iVic) == false
		|| IsClientInGame(iVic) == false)
	{
		KillTimer(timer);
		g_hMegaAdTimer[iVic] = null;
		return Plugin_Stop;
	}

	g_iMegaAdCount[iVic]--;

	#if defined PM_DEBUG
	PrintToChatAll("\x03- tick, client \x01%i\x03 amount \x01%i", iVic, g_iMegaAdCount[iVic] );
	#endif
	if (g_iMegaAdCount[iVic] > 0)
	{
		//SetEntDataFloat(iVic, g_iLaggedMovementO, g_flMegaAd_slow, true);

		//check if another SI is disabling the survivor
		int iDisabler = g_iMyDisabler[iVic];
		if (iDisabler == -1)
			SetEntDataFloat(iVic, g_iLaggedMovementO, g_flMegaAd_slow, true);
		else
		{
			//check if disabler is valid
			//if not, then just apply normal effects
			if (IsValidEntity(iDisabler) == false
				|| IsClientConnected(iDisabler) == false
				|| IsClientInGame(iDisabler) == false)
				SetEntDataFloat(iVic, g_iLaggedMovementO, g_flMegaAd_slow, true);
			//otherwise if it's valid, then check the class
			//don't apply slow for jockeys or smokers
			else
			{
				InfectedType iType = SM_IntToInfectedType(GetEntData(iDisabler, g_iClassO), g_bIsL4D2);
				if (iType != Infected_Smoker && iType != Infected_Jockey)
					SetEntDataFloat(iVic, g_iLaggedMovementO, g_flMegaAd_slow, true);
			}
		}

		return Plugin_Continue;
	}
	else
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x03- duration over, killing timer");
		#endif
		g_iMegaAdCount[iVic] = 0;
		SetEntDataFloat(iVic, g_iLaggedMovementO, 1.0, true);

		//check if survivor has extra run speed
		Extreme_Rebuild();

		KillTimer(timer);
		g_hMegaAdTimer[iVic] = null;
		return Plugin_Stop;
	}
}

//=============================
// MARK: - Charger: Scattering Ram
//=============================

bool Scatter_OnImpact(int iAtt, int iVic)
{
	//stop if disabled
	if (!g_bInfCharger_enable || !g_bScatter_enable) return false;

	if (SM_GetClientTeamType(iAtt) == ClientTeam_Infected
		&& g_ipInf[iAtt].chargerPerk == InfectedChargerPerk_Scatter
		&& g_bConfirm[iAtt])
	{
		CreateTimer(0.1, Timer_ScatterForce, iVic);

		#if defined PM_DEBUG
		PrintToChatAll("\x05Scatter \x03fired");
		#endif
		return true;
	}

	return false;
}

bool Scatter_OnSpawn(int iCid)
{
	//stop here if the perk is disabled
	if (!g_bScatter_enable || !g_bInfCharger_enable) return false;

	//check for perk
	if (g_ipInf[iCid].chargerPerk == InfectedChargerPerk_Scatter && g_bConfirm[iCid])
	{
		CreateTimer(0.1, Scatter_ChangeHP, iCid);
		return true;
	}
	return false;
}

Action Timer_ScatterForce(Handle timer, int iVic)
{
	KillTimer(timer);

	if (IsServerProcessing() == false)
		return Plugin_Stop;

	float vecVelocity[3];
	GetEntPropVector(iVic, Prop_Data, "m_vecVelocity", vecVelocity);
	vecVelocity[0] *= g_flScatter_force;
	vecVelocity[1] *= g_flScatter_force;
	vecVelocity[2] *= g_flScatter_force;
	TeleportEntity(iVic, NULL_VECTOR, NULL_VECTOR, vecVelocity);

	return Plugin_Stop;
}

Action Scatter_ChangeHP(Handle timer, int iCid)
{
	KillTimer(timer);

	if (IsServerProcessing() == false || iCid <= 0 || IsClientInGame(iCid) == false || SM_GetClientTeamType(iCid) != ClientTeam_Infected)
		return Plugin_Stop;

	SetEntityHealth(iCid, RoundToNearest(GetEntProp(iCid, Prop_Data, "m_iHealth") * (1 + g_flScatter_hpmult) ) );

	float flMaxHP = FindConVar("z_charger_health").IntValue * (1 + g_flScatter_hpmult);

	if (GetEntProp(iCid, Prop_Data, "m_iHealth") > flMaxHP)
		SetEntProp(iCid, Prop_Data, "m_iHealth", RoundToNearest(flMaxHP) );

	return Plugin_Stop;
}

//=============================
// MARK: - Charger: Speeding Bullet
//=============================

bool Bullet_OnAbilityUse(int iCid, const char[] stAb)
{
	//stop if frogger is disabled
	if (!g_bInfCharger_enable || !g_bBullet_enable) return false;

	if (SM_GetClientTeamType(iCid) == ClientTeam_Infected
		&& g_ipInf[iCid].chargerPerk == InfectedChargerPerk_Bullet
		&& g_bConfirm[iCid])
	{
		//check if it's a pounce/lunge
		if (StrEqual(stAb, "ability_charge", false))
		{
			SetEntDataFloat(iCid, g_iLaggedMovementO, 1.0 * g_flBullet_rate, true);

			#if defined PM_DEBUG
			PrintToChatAll("\x03speeding bullet fired");
			#endif
			return true;
		}
	}

	return false;
}

//=============================
// MARK: - Tank: Tank Perks
//=============================


//PRIMARY TANK FUNCTION		----------------------
//primary function for handling tank spawns
Action Event_Tank_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int iCid = GetClientOfUserId(event.GetInt("userid"));
	if (iCid == 0 || SM_GetClientTeamType(iCid) != ClientTeam_Infected)
		return Plugin_Continue;

	#if defined PM_DEBUG
	PrintToChatAll("\x03Tank Spawn detected, client \x01%i\x03, g_iTank \x01%i", iCid, g_iTank);
	#endif
	//reset their run speed
	//from martial artist or speed demon
	SetEntityMoveType(iCid, MOVETYPE_CUSTOM);
	SetEntDataFloat(iCid, g_iLaggedMovementO, 1.0, true);

	//stop if tank perks are disallowed
	if (!g_bInfTank_enable)
		return Plugin_Continue;

	//start a check if it's a bot
	if (IsFakeClient(iCid))
	{
		g_iTankBotTicks = 0;
		CreateTimer(2.5, Timer_TankBot, iCid, TIMER_REPEAT);
	}
	else
		CreateTimer(1.0, Timer_Tank_ApplyPerk, iCid);

	return Plugin_Continue;
}

Action Timer_Tank_ApplyPerk(Handle timer, int iCid)
{
	KillTimer(timer);
	Tank_ApplyPerk(iCid);

	return Plugin_Continue;
}

void Tank_ApplyPerk(int iCid)
{
	//why apply tank perks to non-infected?
	if (IsClientInGame(iCid) == false || SM_GetClientTeamType(iCid) != ClientTeam_Infected)
		return;

	//and make sure we're dealing with a tank
	char st_class[32];
	GetClientModel(iCid, st_class, sizeof(st_class));

	if (StringInsensitiveContains(st_class, "hulk") == false)
		return;

	#if defined PM_DEBUG
	PrintToChatAll("\x03applying perks; tank detected, model: \x01%s", st_class);
	#endif

	//first battery of tests for perks 1-4 (not double trouble)
	if (g_iTank < 2 && g_bConfirm[iCid] && g_ipInf[iCid].tankPerk < InfectedTankPerk_DoubleTrouble)
	{
		switch (g_ipInf[iCid].tankPerk)
		{
		//check for adrenal glands
		case InfectedTankPerk_AdrenalGlands:
			{
				#if defined PM_DEBUG
				PrintToChatAll("\x03applying adrenal glands");
				#endif
				g_iTank = 1;

				//stop if adrenal glands is disabled
				if (!g_bAdrenal_enable) return;

				Adrenal_Rebuild();

				if (IsFakeClient(iCid) == false)
					PrintHintText(iCid, "%t: %t", "PerkMenuInfectedTankAdrenalGlands", "AdrenalGlandsHint");
				return;
			}
		//check for juggernaut perk
		case InfectedTankPerk_Juggernaut:
			{
				//at least tell plugin that there's a tank
				g_iTank = 1;

				//stop if juggernaut is disabled
				if (!g_bJuggernaut_enable) return;

				#if defined PM_DEBUG
				PrintToChatAll("\x03applying juggernaut");
				#endif
				CreateTimer(0.1, Juggernaut_ChangeHP, iCid);

				//if it's gotten this far, juggernaut's
				//about to get applied so we tell plugin the news
				g_iTank = 2;

				if (IsFakeClient(iCid) == false)
					PrintHintText(iCid, "%t: %t", "PerkMenuInfectedTankJuggernaut", "JuggernautHint");

				return ;
			}

		//check for metabolic boost
		case InfectedTankPerk_MetabolicBoost:
			{
				#if defined PM_DEBUG
				PrintToChatAll("\x03applying metabolic boost");
				#endif
				g_iTank = 1;

				SetEntDataFloat(iCid, g_iLaggedMovementO, 1.0 * g_flMetabolic_speedmult, true);
				if (IsFakeClient(iCid) == false)
					PrintHintText(iCid,"Metabolic Boost: %t", "MetabolicHint");
				return ;
			}

		//check for storm caller
		case InfectedTankPerk_Stormcaller:
			{
				g_iTank = 1;

				//stop if storm caller is disabled
				if (!g_bStorm_enable) return;

				#if defined PM_DEBUG
				PrintToChatAll("\x03applying storm caller");
				#endif

				int iflags = GetCommandFlags("z_spawn");
				SetCommandFlags("z_spawn", iflags & ~FCVAR_CHEAT);
				for (int iI = 0; iI <= g_iStorm_mobcount; iI++)
				{
					FakeClientCommand(iCid, "z_spawn mob auto");
				}
				SetCommandFlags("z_spawn", iflags);
				if (IsFakeClient(iCid) == false)
					PrintHintText(iCid, "%t: %t", "PerkMenuInfectedTankStormcaller", "StormCallerHint");

				return;
			}
		}
	}

	//check for double trouble activation;
	//must have perk confirmed (g_iConfirm==1)
	//and double trouble must not be in effect (g_iTank!=3, 4)
	else if (g_ipInf[iCid].tankPerk == InfectedTankPerk_DoubleTrouble && g_iTank < 3 && g_bConfirm[iCid])
	{
		g_iTank = 3;
		g_iTank_MainId = iCid;

		//stop if double trouble is disabled
		if (!g_iDouble_enable) return;

		//recount the number of tanks left
		g_iTankCount = 0;
		for (int iI = 1; iI <= MaxClients; iI++)
		{
			if (IsClientInGame(iI) && IsPlayerAlive(iI) && SM_GetClientTeamType(iI) == ClientTeam_Infected)
			{
				GetClientModel(iI, st_class, sizeof(st_class));
				if (StringInsensitiveContains(st_class, "hulk"))
					g_iTankCount++;

				#if defined PM_DEBUG
				PrintToChatAll("\x03-counting \x01%i", iI);
				#endif
			}
		}

		#if defined PM_DEBUG
		PrintToChatAll("\x03double trouble 1st tank apply");
		#endif

		CreateTimer(1.0, DoubleTrouble_ChangeHP, iCid);
		CreateTimer(1.0, DoubleTrouble_SpawnTank, iCid);

		CreateTimer(3.0, DoubleTrouble_FrustrationTimer, iCid, TIMER_REPEAT);

		if (IsFakeClient(iCid) == false)
			PrintHintText(iCid, "%t: %t", "PerkMenuInfectedTankDoubleTrouble", "DoubleTroubleHint1");
		return ;
	}

	//if double trouble is activated (g_iTank==3)
	//subsequent tanks will have reduced hp
	else if (g_iTank == 3)
	{
		//stop if double trouble is disabled
		if (!g_iDouble_enable) return;

		//recount the number of tanks left
		g_iTankCount = 0;
		for (int iI = 1; iI <= MaxClients; iI++)
		{
			if (IsClientInGame(iI) && IsPlayerAlive(iI) && SM_GetClientTeamType(iI) == ClientTeam_Infected)
			{
				GetClientModel(iI, st_class, sizeof(st_class));
				if (StringInsensitiveContains(st_class, "hulk"))
					g_iTankCount++;

				#if defined PM_DEBUG
				PrintToChatAll("\x03-counting \x01%i", iI);
				#endif
			}
		}

		#if defined PM_DEBUG
		PrintToChatAll("\x03double trouble 2nd+ tank apply");
		#endif

		if (IsFakeClient(iCid) == false)
			PrintHintText(iCid, "%t", "DoubleTroubleHint2");

		CreateTimer(0.1, DoubleTrouble_ChangeHP, iCid);

		float vecOrigin[3];
		GetClientAbsOrigin(g_iTank_MainId, vecOrigin);
		TeleportEntity(iCid, vecOrigin, NULL_VECTOR, NULL_VECTOR);

		return ;
	}
	//if frustrated double trouble tank is being passed, do nothing
	else if (g_iTank == 4)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x03double trouble, frustration pass (no perks granted)");
		#endif
		g_iTank = 3;
		return;
	}
	//if none of the special perks apply, just tell plugin that there's a tank
	else
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x03nothing applied, setting g_iTank to 1");
		#endif
		g_iTank = 1;
		return ;
	}
}
//END PRIMARY TANK FUNCTION ----------------------

//timer functions to change tank's hp
//since doing it immediately doesn't seem to work =/
Action Juggernaut_ChangeHP(Handle timer, int iTankid)
{
	KillTimer(timer);

	if (IsServerProcessing() == false || iTankid == 0 || IsClientInGame(iTankid) == false || SM_GetClientTeamType(iTankid) != ClientTeam_Infected)
		return Plugin_Stop;

	SetEntityHealth(iTankid, GetEntProp(iTankid, Prop_Data, "m_iHealth") + g_iJuggernaut_hp);

	#if defined PM_DEBUG
	PrintToChatAll("\x03juggernaut apply hp boost, health\x01 %i", GetEntProp(iTankid, Prop_Data, "m_iHealth"));
	#endif
	return Plugin_Stop;
}

Action DoubleTrouble_ChangeHP(Handle timer, int iTankid)
{
	KillTimer(timer);

	if (IsServerProcessing() == false || iTankid == 0 || IsClientInGame(iTankid) == false || SM_GetClientTeamType(iTankid) != ClientTeam_Infected)
		return Plugin_Stop;

	SetEntityHealth(iTankid, RoundToCeil(GetEntProp(iTankid, Prop_Data, "m_iHealth") * g_flDouble_hpmult));

	#if defined PM_DEBUG
	PrintToChatAll("\x03double trouble apply hp reduction, health \x01%i", GetEntProp(iTankid, Prop_Data,"m_iHealth"));
	#endif
	return Plugin_Stop;
}

Action DoubleTrouble_SpawnTank(Handle timer, int iCid)
{
	KillTimer(timer);

	if (IsServerProcessing() == false)
		return Plugin_Stop;

	//strip flags
	int iflags = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", iflags & ~FCVAR_CHEAT);

	int iSpawner;
	int iCount = 0;
	int iReg[8] = {0};
	//before we can spawn the tank, need to find a suitable players
	for (int iI = 1; iI <= MaxClients; iI++)
	{
		if (IsClientInGame(iI) && IsFakeClient(iI) == false && SM_GetClientTeamType(iI) == ClientTeam_Infected && iI != iCid
			//check if client is either dead or a ghost
			&& ( GetClientHealth(iI)<=1 || GetEntData(iI, g_iIsGhostO) !=0 ))
		{
			iCount++;
			iReg[iCount]=iI;
		}
	}

	//check if any players were available
	if (iCount == 0)
	{
		iSpawner = CreateFakeClient("perkmod - bot tank spawner");
		CreateTimer(5.0, DoubleTrouble_KickBotSpawner, iSpawner, TIMER_REPEAT);
	}
	else
		iSpawner = iReg[GetRandomInt(1, iCount)];

	#if defined PM_DEBUG
	PrintToChatAll("\x05double trouble\x03 spawner id \x01%i", iSpawner);
	#endif

	//spawn the tank and reset flags
	FakeClientCommand(iSpawner, "z_spawn tank");
	SetCommandFlags("z_spawn", iflags);

	#if defined PM_DEBUG
	PrintToChatAll("\x03double trouble attempting to spawn 2nd tank");
	#endif
	return Plugin_Stop;
}

Action DoubleTrouble_KickBotSpawner(Handle timer, int iSpawner)
{
	if ((IsServerProcessing() == false
		&& IsFakeClient(iSpawner))
		|| (IsClientInGame(iSpawner)
		&& IsClientInKickQueue(iSpawner) == false
		&& IsPlayerAlive(iSpawner) == false
		&& IsFakeClient(iSpawner)) )
	{
		KickClient(iSpawner);
		KillTimer(timer);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

void Adrenal_Rebuild()
{
	//clears all DT-related vars
	Adrenal_Clear();

	//if the server's not running or
	//is in the middle of loading, stop
	if (IsServerProcessing() == false) return;

	#if defined PM_DEBUG
	PrintToChatAll("\x03martial artist rebuilding registry");
	#endif

	if (!g_bInfTank_enable) return;

	for (int iI = 1; iI <= MaxClients; iI++)
	{
		if (IsClientInGame(iI)
			&& IsPlayerAlive(iI)
			&& SM_GetClientTeamType(iI) == ClientTeam_Infected
			&& g_ipInf[iI].tankPerk == InfectedTankPerk_AdrenalGlands
			&& g_bConfirm[iI])
		{
			g_iAdrenalRegisterCount++;
			g_iAdrenalRegisterIndex[g_iAdrenalRegisterCount] = iI;

			#if defined PM_DEBUG
			PrintToChatAll("\x03-registering \x01%i", iI);
			#endif
		}
	}
}

void Adrenal_Clear()
{
	g_iAdrenalRegisterCount = 0;

	for (int iI = 1; iI <= MaxClients; iI++)
	{
		g_iAdrenalRegisterIndex[iI] = -1;
	}

	#if defined PM_DEBUG
	PrintToChatAll("\x03cleared");
	#endif
}

void Adrenal_OnGameFrame()
{
	//or if no one has DT, don't bother either
	if (g_iAdrenalRegisterCount == 0 || g_iTank <= 0)
		return;

	int iCid;
	//this tracks the player's ability id
	int iEntid;
	//this tracks the calculated next attack
	float flTimeStamp_calc;
	//this, retrieved next attack
	float flDuration_ret;
	//this, on the other hand, tracks the current next attack
	float flTimeStamp_ret;

	for (int iI = 1; iI <= g_iAdrenalRegisterCount; iI++)
	{
		//PUNCH MOD
		//---------

		//PRE-CHECKS 1: RETRIEVE VARS
		//---------------------------

		iCid = g_iAdrenalRegisterIndex[iI];
		//stop on this client
		//when the next client id is null
		if (iCid <= 0) return;

		//we have to adjust numbers on the gun, not the player
		//so we get the active weapon id here
		iEntid = GetEntDataEnt2(iCid, g_iActiveWO);
		//if the retrieved gun id is -1, then...
		//wtf mate? just move on
		if (iEntid == -1) continue;

		flDuration_ret = GetEntDataFloat(iEntid, g_iAttackTimerO + 4);
		flTimeStamp_ret = GetEntDataFloat(iEntid, g_iAttackTimerO + 8);

		//reset frustration
		SetEntData(iCid, g_iFrustrationO, 0);

		//CHECK 1: AFTER ADJUSTED ATT IS MADE
		//------------------------------------
		//at this point, either a gun was swapped, or
		//the attack time needs to be adjusted
		//checks: stored gun id same as retrieved gun id,
		// and retrieved next attack time is after stored value
		//actions: adjusts next attack time
		if (g_flAdrenalTimeStamp[iCid] < flTimeStamp_ret)
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x05Adrenal\x03 after adjusted shot\n-pre, client \x01%i\x03; entid \x01%i\x03; enginetime\x01 %f\x03; nextactivation: dur \x01 %f\x03 timestamp \x01%f", iCid, iEntid, GetGameTime(), GetEntDataFloat(iEntid, g_iAttackTimerO+4), GetEntDataFloat(iEntid, g_iAttackTimerO+8) );
			#endif
			//update the timestamp stored in plugin
			g_flAdrenalTimeStamp[iCid] = flTimeStamp_ret;

			//this calculates the time that the player theoretically
			//should have used his ability in order to use it
			//with the shortened cooldown
			//FOR EXAMPLE:
			//vomit, normal cooldown 30s, desired cooldown 6s
			//player uses it at T = 1:30
			//normally, game predicts it to be ready at T + 30s
			//so if we modify T to 1:06, it will be ready at 1:36
			//which is 6s after the player used the ability
			flTimeStamp_calc = flTimeStamp_ret - (flDuration_ret * (1 - g_flAdrenal_punchcdmult));
			SetEntDataFloat(iEntid, g_iAttackTimerO + 8, flTimeStamp_calc, true);
			SetEntDataFloat(iEntid, g_iNextPAttO, flTimeStamp_calc, true);

			//SetEntDataFloat(iEntid, g_iAttackTimerO+4, 0, true); //experimental
			//SetEntDataFloat(iEntid, 5464+4, 0, true); //experimental
			//SetEntDataFloat(iEntid, 5464+8, flTimeStamp_calc, true); //experimental

			//SetEntDataFloat(iEntid, g_iNextSAttO, flTimeStamp_calc, true); //experimental

			//similar logic to above, but this change is necessary
			//so that the little cooldown gui is shown properly
			//SetEntDataFloat(iEntid, g_iNextActO+4, 0 , true); //experimental
			//SetEntDataFloat(iEntid, g_iNextActO+8, flTimeStamp_calc, true); //experimental

			#if defined PM_DEBUG
			PrintToChatAll("\x03-post, nextactivation dur \x01 %f\x03 timestamp \x01%f", GetEntDataFloat(iEntid, g_iAttackTimerO+4), GetEntDataFloat(iEntid, g_iAttackTimerO+8) );
			#endif
			continue;
		}

		//THROW MOD
		//---------

		//RETRIEVE VARIABLES
		//------------------
		//get the ability ent id
		iEntid = GetEntDataEnt2(iCid, g_iAbilityO);
		//if the retrieved gun id is -1, then move on
		if (iEntid == -1) continue;
		//retrieve the next act time
		flDuration_ret = GetEntDataFloat(iEntid, g_iNextActO + 4);

		//CHECK 1: PAUSE?
		//---------------
		//Valve seems to have a weird way of forcing a
		//pause before the cooldown timer starts: by setting
		//the timers to some arbitrarily high number =/
		//IIRC no cooldown exceeds 100s (highest is 30?) so
		//if any values exceed 100, then let timer continue running
		if (flDuration_ret > 100.0)
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x03DT retrieved duration > 100");
			#endif
			continue;
		}


		//CHECK 2: AFTER ADJUSTED SHOT IS MADE
		//------------------------------------
		//at this point, either a gun was swapped, or
		//the attack time needs to be adjusted
		//also, only change timer if it's the first shot

		//retrieve current timestamp
		flTimeStamp_ret = GetEntDataFloat(iEntid, g_iNextActO + 8);

		if (g_flTimeStamp[iCid] < flTimeStamp_ret)
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x05TwinSF:\x03 after adjusted shot\n-pre, client \x01%i\x03; entid \x01%i\x03; enginetime\x01 %f\x03; nextactivation: dur \x01 %f\x03 timestamp \x01%f", iCid, iEntid, GetGameTime(), GetEntDataFloat(iEntid, g_iNextActO+4), GetEntDataFloat(iEntid, g_iNextActO+8) );
			#endif
			//update the timestamp stored in plugin
			g_flTimeStamp[iCid] = flTimeStamp_ret;

			//this calculates the time that the player theoretically
			//should have used his ability in order to use it
			//with the shortened cooldown
			//FOR EXAMPLE:
			//vomit, normal cooldown 30s, desired cooldown 6s
			//player uses it at T = 1:30
			//normally, game predicts it to be ready at T + 30s
			//so if we modify T to 1:06, it will be ready at 1:36
			//which is 6s after the player used the ability

			#if defined PM_DEBUG
			PrintToChatAll("\x03-calc, flTimeStamp_ret \x01%f\x03 flDuration_ret \x01%f\x03 g_flRockInterval \x01%f", flTimeStamp_ret, flDuration_ret, g_flAdrenal_throwcdmult );
			#endif
			flTimeStamp_calc = flTimeStamp_ret - (flDuration_ret * g_flAdrenal_throwcdmult);
			SetEntDataFloat(iEntid, g_iNextActO+8, flTimeStamp_calc, true);

			#if defined PM_DEBUG
			PrintToChatAll("\x03-post, nextactivation dur \x01 %f\x03 timestamp \x01%f", GetEntDataFloat(iEntid, g_iNextActO+4), GetEntDataFloat(iEntid, g_iNextActO+8) );
			#endif
		}
	}

	return;
}

//resets frustration for double trouble tanks
//which is a band-aid solution =P for disappearing
//tanks whenever one becomes frustrated when there's
//two or more active tanks
Action DoubleTrouble_FrustrationTimer(Handle timer, int iCid)
{
	if (IsServerProcessing() == false)
	{
		KillTimer(timer);
		return Plugin_Stop;
	}

	//recount the number of tanks left
	char st_class[32];
	g_iTankCount = 0;

	for (int iI = 1; iI <= MaxClients; iI++)
	{
		if (IsClientInGame(iI) && IsPlayerAlive(iI) && SM_GetClientTeamType(iI) == ClientTeam_Infected)
		{
			GetClientModel(iI, st_class, sizeof(st_class));
			if (StringInsensitiveContains(st_class, "hulk"))
				g_iTankCount++;

			#if defined PM_DEBUG
			PrintToChatAll("\x03-counting \x01%i", iI);
			#endif
		}
	}

	#if defined PM_DEBUG
	if (g_iTankCount <= 1)
		PrintToChatAll("\x03- 1 or less tanks");
	#endif

	//stop the timer if any of these
	//conditions are true
	if (GameModeCheck(true, g_iDouble_enable) == false
		|| IsClientInGame(iCid) == false
		|| IsFakeClient(iCid) == true
		|| IsPlayerAlive(iCid) == false
		|| SM_GetClientTeamType(iCid) != ClientTeam_Infected
		|| g_iTankCount <= 1
		|| g_bInfTank_enable == false)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x03- stopping, tankcount \x01%i", g_iTankCount);
		#endif
		KillTimer(timer);
		return Plugin_Stop;
	}

	#if defined PM_DEBUG
	PrintToChatAll("\x03- checks passed, tankcount \x01%i", g_iTankCount);
	#endif
	SetEntData(iCid, g_iFrustrationO, 0);

	#if defined PM_DEBUG
	PrintToChatAll("\x03- client \x01%i\x03, current frustration \x01%i", iCid, GetEntData(iCid, g_iFrustrationO) );
	#endif
	return Plugin_Continue;
}

//when switching players from frustration, reset tank's hp and speed boost
Action Event_Tank_Frustrated(Event event, const char[] name, bool dontBroadcast)
{
	#if defined PM_DEBUG
	PrintToChatAll("\x03tank frustration detected");
	#endif

	int iCid = GetClientOfUserId(event.GetInt("userid"));

	if (IsServerProcessing() == false
		|| iCid == 0
		|| IsClientInGame(iCid) == false
		|| SM_GetClientTeamType(iCid) != ClientTeam_Infected)
		return Plugin_Continue;

	//if this is a tank spawned under double trouble, it gets no perks
	//setting g_iTank to 4 means any tank "spawns" get no perks
	//and the main tank spawn function won't do anything to the tank
	if (g_iTank == 3) g_iTank = 4;

	SetEntDataFloat(iCid, g_iLaggedMovementO, 1.0, true);

	return Plugin_Continue;
}

//timer to check for bots
Action Timer_TankBot(Handle timer, int iTankid)
{
	KillTimer(timer);

	if (IsServerProcessing() == false
		|| IsValidEntity(iTankid) == false
		|| IsClientInGame(iTankid) == false
		|| IsFakeClient(iTankid) == false
		|| g_iTankBotTicks >= 4
		|| g_bInfTank_enable == false)
	{
		#if defined PM_DEBUG
		PrintToChatAll("\x03stopping bot timer");
		#endif

		return Plugin_Stop;
	}

	if (IsClientInGame(iTankid) && IsFakeClient(iTankid))
	{
		g_iTankBotTicks++;

		#if defined PM_DEBUG
		PrintToChatAll("\x03tankbot tick %i", g_iTankBotTicks);
		#endif

		if (g_iTankBotTicks >= 3)
		{
			#if defined PM_DEBUG
			PrintToChatAll("\x03bot tank detected");
			#endif

			//set bot perks
			g_ipInf[iTankid].tankPerk = BotPickRandomTankPerk();
			g_bConfirm[iTankid] = true;

			#if defined PM_DEBUG
			PrintToChatAll("\x03-tank bot perk \x01%i", g_ipInf[iTankid].tankPerk);
			#endif

			Tank_ApplyPerk(iTankid);
			return Plugin_Stop;
		}
	}
	return Plugin_Stop;
}

//====================================================
//====================================================
// MARK: - M	E	N	U
//====================================================
//====================================================



//======================================
//	CHAT CHECK, TOP MENU, SELECT SUBMENU
//======================================

//check chat
Action MenuOpen_OnSay(int iCid, int args)
{
	ClientTeamType clientTeam = SM_GetClientTeamType(iCid);

	//don't show the menu if all perks are disabled
	bool isSurv = clientTeam == ClientTeam_Survivor;
	bool isInf = clientTeam == ClientTeam_Infected;

	if ((!g_bSurAll_enable && isSurv) || (!g_bInfAll_enable && isInf))
	{
		g_bConfirm[iCid] = false;
		return Plugin_Continue;
	}

	if (g_bConfirm[iCid] == false)
	{
		if (isSurv)
			SendPanelToClient(Menu_Initial(iCid), iCid, Menu_ChooseInit, MENU_TIME_FOREVER);
		else if (isInf)
			SendPanelToClient(Menu_Initial(iCid), iCid, Menu_ChooseInit_Inf, MENU_TIME_FOREVER);
		return Plugin_Continue;
	}

	if (isSurv)
		SendPanelToClient(Menu_ShowChoices(iCid), iCid, Menu_DoNothing, 15);
	else if (isInf)
		SendPanelToClient(Menu_ShowChoices_Inf(iCid), iCid, Menu_DoNothing, 15);

	return Plugin_Continue;
}

//build initial menu
Panel Menu_Initial(int iCid)
{
	Panel menu = CreatePanel();
	char stPanel[75];

	menu.SetTitle("tPoncho's Perkmod");

	//"This server is using Perkmod"
	Format(stPanel, sizeof(stPanel), "%t", "InitialMenuTitle");
	menu.DrawText(stPanel);
	//"Customize Perks"
	Format(stPanel, sizeof(stPanel), "%t", "InitialMenuManualSelect");
	menu.DrawItem(stPanel);

	//random perks, enable only if cvar is set
	if (!g_bRandomEnable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		//"Randomize Perks"
		Format(stPanel, sizeof(stPanel), "%t", "InitialMenuRandomSelect");
		menu.DrawItem(stPanel);
	}

	//"by using option 3"
	Format(stPanel, sizeof(stPanel), "%t", "InitialMenuPreviousSelectText");
	menu.DrawText(stPanel);
	//"PLAY NOW!"
	Format(stPanel, sizeof(stPanel), "%t", "InitialMenuPreviousSelectItem");
	menu.DrawItem(stPanel);

	return menu;
}

int Menu_ChooseInit(Menu topmenu, MenuAction action, int client, int param2)
{
	if (topmenu != INVALID_HANDLE) CloseHandle(topmenu);

	if (action == MenuAction_Select)
	{
		switch(param2)
		{
			case 1:
				SendPanelToClient(Menu_Top(client), client, Menu_ChooseSubMenu, MENU_TIME_FOREVER);
			case 2:
				{
					AssignRandomPerks(client);
					PrintHintText(client, "Perkmod: %t", "InitialMenuCompleteText");
				}
			case 3:
				{
					g_bConfirm[client] = true;
					Event_Confirm_Unbreakable(client);
					Event_Confirm_Grenadier(client);
					Event_Confirm_ChemReliant(client);
					Event_Confirm_DT(client);
					Event_Confirm_MA(client);
					Event_Confirm_LittleLeaguer(client);
					Extreme_Rebuild();
					PrintHintText(client, "Perkmod: %t", "InitialMenuCompleteText");
				}
			default:
				{
					if (IsClientInGame(client))
						SendPanelToClient(Menu_Top(client), client, Menu_ChooseSubMenu, MENU_TIME_FOREVER);
				}
		}
	}

	else
	{
		if (IsClientInGame(client))
			SendPanelToClient(Menu_Top(client), client, Menu_ChooseSubMenu, MENU_TIME_FOREVER);
	}

	return 0;
}

int Menu_ChooseInit_Inf(Handle topmenu, MenuAction action, int client, int param2)
{
	if (topmenu != INVALID_HANDLE) CloseHandle(topmenu);

	if (action == MenuAction_Select)
	{
		switch(param2)
		{
			case 1:
				SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);
			case 2:
				{
					AssignRandomPerks(client);
					PrintHintText(client, "Perkmod: %t", "InitialMenuCompleteText");
				}
			case 3:
				{
					g_bConfirm[client] = true;
					PrintHintText(client, "Perkmod: %t", "InitialMenuCompleteText");
				}
			default:
				{
					if (IsClientInGame(client))
						SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);
				}
		}
	}
	else
	{
		if (IsClientInGame(client))
			SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);
	}

	return 0;
}

//build top menu
Panel Menu_Top(int iCid)
{
	char buffer[75];

	char notSetText[25];
	Format(notSetText, sizeof(notSetText), "%t", "NotSet");
	
	Panel menu = CreatePanel();

	Format(buffer, sizeof(buffer), "%t", "MainMenuSurvivorTitle");
	menu.SetTitle(buffer);

	Format(buffer, sizeof(buffer), "%t", "MainMenuSurvivorDescription");
	menu.DrawText(buffer);

	char st_perk[50];
	char st_display[75];

	//set name for sur1 perk
	if (g_spSur[iCid].firstPerk == SurvivorFirstPerk_StoppingPower && GameModeCheck(true, g_iStopping_enable))
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuSurvivorFirstPerkStoppingPower");
	else if (g_spSur[iCid].firstPerk == SurvivorFirstPerk_DoubleTap && GameModeCheck(true, g_iDT_enable))
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuSurvivorFirstPerkDoubleTap");
	else if (g_spSur[iCid].firstPerk == SurvivorFirstPerk_SleightOfHand && GameModeCheck(true, g_iSoH_enable))
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuSurvivorFirstPerkSleightOfHand");
	else if (g_spSur[iCid].firstPerk == SurvivorFirstPerk_Pyrotechnician && GameModeCheck(true, g_iPyro_enable))
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuSurvivorFirstPerkPyrotechnician");
	else
		st_perk = notSetText;

	Format(st_display, sizeof(st_display), "%t (%s)", "PerkMenuSurvivorFirstPerkTitle", st_perk);
	if (g_bSur1_enable)
		menu.DrawItem(st_display);
	else
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);

	//set name for sur2 perk
	if (g_spSur[iCid].secondPerk == SurvivorSecondPerk_Unbreakable && GameModeCheck(true, g_iUnbreak_enable))
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuSurvivorSecondPerkUnbreakable");
	else if (g_spSur[iCid].secondPerk == SurvivorSecondPerk_Spirit && GameModeCheck(true, g_iSpirit_enable))
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuSurvivorSecondPerkSpirit");
	else if (g_spSur[iCid].secondPerk == SurvivorSecondPerk_HelpingHand && GameModeCheck(true, g_iHelpHand_enable))
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuSurvivorSecondPerkHelpingHand");
	else if (g_spSur[iCid].secondPerk == SurvivorSecondPerk_MartialArtist	&& g_bIsL4D2 && GameModeCheck(true, g_iMA_enable))
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuSurvivorSecondPerkMartialArtist");
	else
		st_perk = notSetText;

	Format(st_display, sizeof(st_display), "%t (%s)", "PerkMenuSurvivorSecondPerkTitle", st_perk);
	if (g_bSur2_enable)
		menu.DrawItem(st_display);
	else
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);

	//set name for sur3 perk
	if (g_spSur[iCid].thirdPerk == SurvivorThirdPerk_PackRat && GameModeCheck(true, g_iPack_enable))
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuSurvivorThirdPerkPackRat");
	else if (g_spSur[iCid].thirdPerk == SurvivorThirdPerk_ChemReliant && GameModeCheck(true, g_iChem_enable))
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuSurvivorThirdPerkChemReliant");
	else if (g_spSur[iCid].thirdPerk == SurvivorThirdPerk_HardToKill && GameModeCheck(true, g_iHard_enable))
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuSurvivorThirdPerkHardToKill");
	else if (g_spSur[iCid].thirdPerk == SurvivorThirdPerk_ExtremeConditioning && GameModeCheck(true, g_iExtreme_enable))
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuSurvivorThirdPerkExtremeConditioning");
	else if (g_spSur[iCid].thirdPerk == SurvivorThirdPerk_LittleLeaguer && GameModeCheck(true, g_iLittle_enable))
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuSurvivorThirdPerkLittleLeaguer");
	else
		st_perk = notSetText;

	Format(st_display, sizeof(st_display), "%t (%s)", "PerkMenuSurvivorThirdPerkTitle", st_perk);
	if (g_bSur3_enable)
		menu.DrawItem(st_display);
	else
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);

	menu.DrawItem(st_display, ITEMDRAW_NOTEXT);
	menu.DrawItem(st_display, ITEMDRAW_NOTEXT);
	menu.DrawItem(st_display, ITEMDRAW_NOTEXT);
	menu.DrawItem(st_display, ITEMDRAW_NOTEXT);

	Format(st_display, sizeof(st_display), "%t", "DoneNagPanel1");
	menu.DrawText(st_display);
	Format(st_display, sizeof(st_display), "%t", "PerkMenuDoneText");
	menu.DrawItem(st_display);

	return menu;
}

//choose a submenu from top perk menu
int Menu_ChooseSubMenu(Menu topmenu, MenuAction action, int client, int param2)
{
	if (topmenu != INVALID_HANDLE) CloseHandle(topmenu);

	if (action == MenuAction_Select)
	{
		switch(param2)
		{
			case 1:
				SendPanelToClient(Menu_Sur1Perk(client), client, Menu_ChooseSur1Perk, MENU_TIME_FOREVER);
			case 2:
				SendPanelToClient(Menu_Sur2Perk(client), client, Menu_ChooseSur2Perk, MENU_TIME_FOREVER);
			case 3:
				SendPanelToClient(Menu_Sur3Perk(client), client, Menu_ChooseSur3Perk, MENU_TIME_FOREVER);
			case 8:
				SendPanelToClient(Menu_Confirm(client), client, Menu_ChooseConfirm, MENU_TIME_FOREVER);
			default:
				{
					if (IsClientInGame(client))
						SendPanelToClient(Menu_Top(client), client, Menu_ChooseSubMenu, MENU_TIME_FOREVER);
				}
		}
	}
	else
	{
		if (IsClientInGame(client))
			SendPanelToClient(Menu_Top(client), client, Menu_ChooseSubMenu, MENU_TIME_FOREVER);
	}

	return 0;
}

//build top menu, infected
Panel Menu_Top_Inf(int iCid)
{
	char buffer[75];
	char notSetText[25];

	Format(notSetText, sizeof(notSetText), "%t", "NotSet");

	Panel menu = CreatePanel();

	Format(buffer, sizeof(buffer), "%t", "MainMenuInfectedTitle");
	menu.SetTitle(buffer);

	Format(buffer, sizeof(buffer), "%t", "MainMenuInfectedDescription");
	menu.DrawText(buffer);

	char st_perk[40];
	char st_display[90];

	InfectedSmokerPerkType smokerPerk = g_ipInf[iCid].smokerPerk;
	if (smokerPerk == InfectedSmokerPerk_TongueTwister && g_bTongue_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedSmokerTongueTwister");
	else if (smokerPerk == InfectedSmokerPerk_Squeezer && g_bSqueezer_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedSmokerSqueezer");
	else if (smokerPerk == InfectedSmokerPerk_DragAndDrop && g_bDrag_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedSmokerDragAndDrop");
	else if (smokerPerk == InfectedSmokerPerk_SmokeIt && g_bSmokeIt_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedSmokerSmokeIt");
	else
		st_perk = notSetText;

	Format(st_display, sizeof(st_display), "%t (%s)", "PerkMenuInfectedSmokerTitle", st_perk);
	if (g_bInfSmoker_enable)
		menu.DrawItem(st_display);
	else
		menu.DrawItem(st_display, ITEMDRAW_NOTEXT);
	
	//set name for Boomer perk
	InfectedBoomerPerkType boomerPerk = g_ipInf[iCid].boomerPerk;
	if (boomerPerk == InfectedBoomerPerk_BarfBagged && g_iBarf_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedBoomerBarfBagged");
	else if (boomerPerk == InfectedBoomerPerk_BlindLuck && g_iBlind_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedBoomerBlindLuck");
	else if (boomerPerk == InfectedBoomerPerk_DeadWreckening && g_bDead_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedBoomerDeadWreckening");
	else if (boomerPerk == InfectedBoomerPerk_MotionSickness && g_bMotion_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedBoomerMotionSickness");
	else
		st_perk = notSetText;

	Format(st_display, sizeof(st_display), "%t (%s)", "PerkMenuInfectedBoomerTitle", st_perk);
	if (g_bInfBoomer_enable)
		menu.DrawItem(st_display);
	else
		menu.DrawItem(st_display, ITEMDRAW_NOTEXT);	

	InfectedHunterPerkType hunterPerk = g_ipInf[iCid].hunterPerk;
	if (hunterPerk == InfectedHunterPerk_BodySlam && g_bBody_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedHunterBodySlam");
	else if (hunterPerk == InfectedHunterPerk_EfficientKiller && g_bEfficient_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedHunterEfficientKiller");
	else if (hunterPerk == InfectedHunterPerk_Grasshopper && g_bGrass_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedHunterGrasshopper");
	else if (hunterPerk == InfectedHunterPerk_SpeedDemon && g_bSpeedDemon_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedHunterSpeedDemon");
	else
		st_perk = notSetText;

	Format(st_display, sizeof(st_display), "%t (%s)", "PerkMenuInfectedHunterTitle", st_perk);
	if (g_bInfHunter_enable)
		menu.DrawItem(st_display);
	else
		menu.DrawItem(st_display, ITEMDRAW_NOTEXT);

	InfectedSpitterPerkType spitterPerk = g_ipInf[iCid].spitterPerk;
	if (spitterPerk == InfectedSpitterPerk_TwinSpitfire && g_bTwinSF_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedSpitterTwinSpitfire");
	else if (spitterPerk == InfectedSpitterPerk_MegaAdhesive && g_bMegaAd_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedSpitterMegaAdhesive");
	else
		st_perk = notSetText;

	Format(st_display, sizeof(st_display), "%t (%s)", "PerkMenuInfectedSpitterTitle", st_perk);
	if (g_bInfSpitter_enable && g_bIsL4D2)
		menu.DrawItem(st_display);
	else
		menu.DrawItem(st_display, ITEMDRAW_NOTEXT);

	//set name for Jockey perk
	InfectedJockeyPerkType jockeyPerk = g_ipInf[iCid].jockeyPerk;
	if (jockeyPerk == InfectedJockeyPerk_Wind && g_bWind_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedJockeyWind");
	else if (jockeyPerk == InfectedJockeyPerk_Cavalier && g_bCavalier_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedJockeyCavalier");
	else if (jockeyPerk == InfectedJockeyPerk_Frogger && g_bFrogger_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedJockeyFrogger");
	else if (jockeyPerk == InfectedJockeyPerk_Ghost && g_bGhost_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedJockeyGhost");
	else
		st_perk = notSetText;

	Format(st_display, sizeof(st_display), "%t (%s)", "PerkMenuInfectedJockeyTitle", st_perk);
	if (g_bInfJockey_enable && g_bIsL4D2)
		menu.DrawItem(st_display);
	else
		menu.DrawItem(st_display, ITEMDRAW_NOTEXT);

	//set name for Charger perk
	InfectedChargerPerkType chargerPerk = g_ipInf[iCid].chargerPerk;
	if (chargerPerk == InfectedChargerPerk_Scatter && g_bScatter_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedChargerScatter");
	else if (chargerPerk == InfectedChargerPerk_Bullet && g_bBullet_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedChargerBullet");
	else
		st_perk = notSetText;

	Format(st_display, sizeof(st_display), "%t (%s)", "PerkMenuInfectedChargerTitle", st_perk);
	if (g_bInfCharger_enable && g_bIsL4D2)
		menu.DrawItem(st_display);
	else
		menu.DrawItem(st_display, ITEMDRAW_NOTEXT);

	//set name for Tank perk
	InfectedTankPerkType tankPerk = g_ipInf[iCid].tankPerk;
	if (tankPerk == InfectedTankPerk_AdrenalGlands && g_bAdrenal_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedTankAdrenalGlands");
	else if (tankPerk == InfectedTankPerk_Juggernaut && g_bJuggernaut_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedTankJuggernaut");
	else if (tankPerk == InfectedTankPerk_MetabolicBoost && g_bMetabolic_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedTankMetabolicBoost");
	else if (tankPerk == InfectedTankPerk_Stormcaller && g_bStorm_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedTankStormcaller");
	else if (tankPerk == InfectedTankPerk_DoubleTrouble && g_iDouble_enable)
		Format(st_perk, sizeof(st_perk), "%t", "PerkMenuInfectedTankDoubleTrouble");
	else
		st_perk = notSetText;

	Format(st_display, sizeof(st_display), "%t (%s)", "PerkMenuInfectedTankTitle", st_perk);
	if (g_bInfTank_enable)
		menu.DrawItem(st_display);
	else
		menu.DrawItem(st_display, ITEMDRAW_NOTEXT);

	Format(st_display, sizeof(st_display), "%t", "DoneNagPanel1");
	menu.DrawText(st_display);
	Format(st_display, sizeof(st_display), "%t", "PerkMenuDoneText");
	menu.DrawItem(st_display);

	return menu;
}

//choose a submenu from top perk menu, infected
int Menu_ChooseSubMenu_Inf(Menu topmenu, MenuAction action, int client, int param2)
{
	if (topmenu != INVALID_HANDLE) CloseHandle(topmenu);

	if (action == MenuAction_Select)
	{
		switch(param2)
		{
			case 1: SendPanelToClient(Menu_InfSmokerPerk(client), client, Menu_ChooseInfSmokerPerk, MENU_TIME_FOREVER);
			case 2: SendPanelToClient(Menu_InfBoomerPerk(client), client, Menu_ChooseInfBoomerPerk, MENU_TIME_FOREVER);
			case 3: SendPanelToClient(Menu_InfHunterPerk(client), client, Menu_ChooseInfHunterPerk, MENU_TIME_FOREVER);
			case 4: SendPanelToClient(Menu_InfSpitterPerk(client), client, Menu_ChooseInfSpitterPerk, MENU_TIME_FOREVER);
			case 5: SendPanelToClient(Menu_InfJockeyPerk(client), client, Menu_ChooseInfJockeyPerk, MENU_TIME_FOREVER);
			case 6: SendPanelToClient(Menu_InfChargerPerk(client), client, Menu_ChooseInfChargerPerk, MENU_TIME_FOREVER);
			case 7: SendPanelToClient(Menu_InfTankPerk(client), client, Menu_ChooseInfTankPerk, MENU_TIME_FOREVER);
			case 8: SendPanelToClient(Menu_Confirm(client), client, Menu_ChooseConfirm_Inf, MENU_TIME_FOREVER);
			default:
				{
					if (IsClientInGame(client))
						SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);
				}
		}
	}

	else
	{
		if (IsClientInGame(client))
			SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);
	}

	return 0;
}

//menu for confirming perk choices
Panel Menu_Confirm(int iCid)
{
	char panel[75];
	Format(panel, sizeof(panel), "%t", "ConfirmNagPanel1");

	Panel menu = CreatePanel();
	menu.SetTitle(panel);
	menu.DrawText("");

	Format(panel, sizeof(panel), "%t", "ConfirmNagPanel2");
	menu.DrawText(panel);
	Format(panel, sizeof(panel), "%t", "ConfirmNagPanel3");
	menu.DrawText(panel);
	Format(panel, sizeof(panel), "%t", "PerkMenuConfirmText");
	menu.DrawItem(panel);
	Format(panel, sizeof(panel), "%t", "ConfirmNagPanel4");
	menu.DrawText(panel);
	Format(panel, sizeof(panel), "%t", "ConfirmNagPanel5");
	menu.DrawText(panel);
	Format(panel, sizeof(panel), "%t", "ConfirmNagPanel6");
	menu.DrawText(panel);
	Format(panel, sizeof(panel), "%t", "PerkMenuCancelText");
	menu.DrawItem(panel);

	return menu;
}

//confirm
int Menu_ChooseConfirm(Menu topmenu, MenuAction action, int client, int param2)
{
	if (topmenu != INVALID_HANDLE) CloseHandle(topmenu);

	if (action == MenuAction_Select)
	{
		switch(param2)
		{
			case 1:
			{
				g_bConfirm[client] = true;

				PrintToChat(client,"\x03[SM] %t", "ConfirmedMessage");
				Event_Confirm_Unbreakable(client);
				Event_Confirm_Grenadier(client);
				Event_Confirm_ChemReliant(client);
				Event_Confirm_DT(client);
				Event_Confirm_MA(client);
				Extreme_Rebuild();
				Event_Confirm_LittleLeaguer(client);
			}
			case 2:
				SendPanelToClient(Menu_Top(client), client, Menu_ChooseSubMenu, MENU_TIME_FOREVER);
			default:
			{
				if (IsClientInGame(client))
					SendPanelToClient(Menu_Top(client), client, Menu_ChooseSubMenu, MENU_TIME_FOREVER);
			}
		}
	}

	else
		SendPanelToClient(Menu_Top(client), client, Menu_ChooseSubMenu, MENU_TIME_FOREVER);

	return 0;
}

int Menu_ChooseConfirm_Inf(Menu topmenu, MenuAction action, int client, int param2)
{
	if (topmenu != INVALID_HANDLE) CloseHandle(topmenu);

	if (action==MenuAction_Select)
	{
		switch(param2)
		{
			case 1:
			{
				g_bConfirm[client] = true;
				PrintToChat(client,"\x03[SM] %t", "ConfirmedMessage");
			}
			case 2:
				SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);
			default:
			{
				if (IsClientInGame(client))
					SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);
			}
		}
	}
	else
		SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);

	return 0;
}

//do nothing
//for displaying perk choices after confirming
int Menu_DoNothing(Menu topmenu, MenuAction action, int param1, int param2)
{
	return 0;
}

//shows perk choices
Panel Menu_ShowChoices(int iCid)
{	
	char buffer[75];
	char stPerk[75];
	char stDesc[75];

	Panel menu = CreatePanel();
	menu.SetTitle("Perkmod");

	//"Your perks for this round:"
	Format(buffer, sizeof(buffer), "%t:", "MapPerksPanel");
	menu.DrawText(buffer);

	if (g_bSur1_enable)
	{
		SurvivorFirstPerkType firstPerk = g_spSur[iCid].firstPerk;
		if (firstPerk == SurvivorFirstPerk_StoppingPower && GameModeCheck(true, g_iStopping_enable))
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuSurvivorFirstPerkStoppingPower");
			Format(stDesc , sizeof(stDesc), "+%i%% %t", RoundToNearest(g_flStopping_dmgmult*100), "BonusDamageText");
		}
		else if (firstPerk == SurvivorFirstPerk_DoubleTap && GameModeCheck(true, g_iDT_enable))
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuSurvivorFirstPerkDoubleTap");
			Format(stDesc, sizeof(stDesc), "%t, %t, %t", "DoubleTapDescriptionPanel", "SleighOfHandDescriptionPanel", "DoubleTapRestrictionWarning" ) ;
		}
		else if (firstPerk == SurvivorFirstPerk_SleightOfHand && GameModeCheck(true, g_iSoH_enable))
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuSurvivorFirstPerkSleightOfHand");
			Format(stDesc, sizeof(stDesc), "%t +%i%%", "SleighOfHandDescriptionPanel", RoundToNearest(100 * ((1/g_flSoH_rate)-1) ) ) ;
		}
		else if (firstPerk == SurvivorFirstPerk_Pyrotechnician && GameModeCheck(true, g_iPyro_enable))
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuSurvivorFirstPerkPyrotechnician");
			Format(stDesc, sizeof(stDesc), "%t", "PyroDescriptionPanel");
		}
		else {
			Format(stPerk, sizeof(stPerk), "%t", "NotSet");
			stDesc = "";
		}

		Format(buffer, sizeof(buffer), "%t: %s", "PerkMenuSurvivorFirstPerkTitle", stPerk);
		menu.DrawItem(buffer);
		menu.DrawText(stDesc);
	}

	if (g_bSur2_enable)
	{
		SurvivorSecondPerkType secondPerk = g_spSur[iCid].secondPerk;
		if (secondPerk == SurvivorSecondPerk_Unbreakable && GameModeCheck(true, g_iUnbreak_enable))
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuSurvivorSecondPerkUnbreakable");
			Format(stDesc, sizeof(stDesc), "+%i %t", g_iUnbreak_hp, "UnbreakableHint");
		}
		else if (secondPerk == SurvivorSecondPerk_Spirit && GameModeCheck(true, g_iSpirit_enable))
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuSurvivorSecondPerkSpirit");

			int iTime = g_iSpirit_cd;
			if (g_L4D_GameMode == GameMode_Versus)
				iTime = g_iSpirit_cd_vs;
			else if (g_L4D_GameMode == GameMode_Survival)
				iTime=g_iSpirit_cd_sur;

			Format(stDesc, sizeof(stDesc), "%t: %i min", "SpiritDescriptionPanel", iTime/60);
		}
		else if (secondPerk == SurvivorSecondPerk_HelpingHand && GameModeCheck(true, g_iHelpHand_enable))
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuSurvivorSecondPerkHelpingHand");

			int iBuff = g_iHelpHand_buff;
			if (g_L4D_GameMode == GameMode_Versus)
				iBuff=g_iHelpHand_buff_vs;

			if (g_bHelpHand_convar)
				Format(stDesc, sizeof(stDesc), "%t +%i", "HelpingHandDescriptionPanel2", iBuff);
			else
				Format(stDesc, sizeof(stDesc), "%t +%i", "HelpingHandDescriptionPanel", iBuff);
		}
		else if (secondPerk == SurvivorSecondPerk_MartialArtist && GameModeCheck(true, g_iMA_enable))
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuSurvivorSecondPerkMartialArtist");
			Format(stDesc, sizeof(stDesc), "%t", (g_iMA_maxpenalty < 6 ? "MartialArtistDescriptionPanel" : "MartialArtistDescriptionPanel_noreduc"));
		}
		else
		{
			Format(stPerk, sizeof(stPerk), "%t", "NotSet");
			stDesc = "";
		}

		Format(buffer, sizeof(buffer), "%t: %s", "PerkMenuSurvivorSecondPerkTitle", stPerk);
		menu.DrawItem(buffer);
		menu.DrawText(stDesc);
	}

	if (g_bSur3_enable)
	{
		SurvivorThirdPerkType thirdPerk = g_spSur[iCid].thirdPerk;
		if (thirdPerk == SurvivorThirdPerk_PackRat && GameModeCheck(true, g_iPack_enable))
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuSurvivorThirdPerkPackRat");
			Format(stDesc, sizeof(stDesc), "%t +%i%%", "PackRatDescriptionPanel", RoundToNearest(g_flPack_ammomult*100));
		}
		else if (thirdPerk == SurvivorThirdPerk_ChemReliant && GameModeCheck(true, g_iChem_enable))
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuSurvivorThirdPerkChemReliant");
			Format(stDesc, sizeof(stDesc), "%t +%i", "ChemReliantDescriptionPanel", g_iChem_buff);
		}
		else if (thirdPerk == SurvivorThirdPerk_HardToKill && GameModeCheck(true, g_iHard_enable))
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuSurvivorThirdPerkHardToKill");
			Format(stDesc, sizeof(stDesc), "(+%i%% %t)", RoundToNearest(g_flHard_hpmult*100), "HardToKillDescriptionPanel");
		}
		else if (thirdPerk == SurvivorThirdPerk_ExtremeConditioning && GameModeCheck(true, g_iExtreme_enable))
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuSurvivorThirdPerkExtremeConditioning");
			Format(stDesc, sizeof(stDesc), "+%i%% %t", RoundToNearest(g_flExtreme_rate * 100 - 100), "MartialArtistDescriptionPanelCoop");
		}
		else if (thirdPerk == SurvivorThirdPerk_LittleLeaguer && GameModeCheck(true, g_iLittle_enable))
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuSurvivorThirdPerkLittleLeaguer");
			Format(stDesc, sizeof(stDesc), "%t", "LittleLeaguerDescriptionPanel");
		}
		else
		{
			Format(stPerk, sizeof(stPerk), "%t", "NotSet");
			stDesc = "";
		}

		Format(buffer, sizeof(buffer), "%t: %s", "PerkMenuSurvivorThirdPerkTitle", stPerk);
		menu.DrawItem(buffer);
		menu.DrawText(stDesc);
	}

	return menu;
}

//shows perk choices, infected
Panel Menu_ShowChoices_Inf(int iCid)
{
	char buffer[75];
	char stPerk[75];
	char stDesc[75];
	
	Panel menu = CreatePanel();

	Format(buffer, sizeof(buffer), "%t:", "MapPerksPanel");
	menu.SetTitle(buffer);

	if (g_bInfSmoker_enable)
	{
		InfectedSmokerPerkType smokerPerk = g_ipInf[iCid].smokerPerk;
		if (smokerPerk == InfectedSmokerPerk_TongueTwister && g_bTongue_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedSmokerTongueTwister");
			Format(stDesc, sizeof(stDesc), "%t", "TongueTwisterDescriptionPanel");
		}
		else if (smokerPerk == InfectedSmokerPerk_Squeezer && g_bSqueezer_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedSmokerSqueezer");
			Format(stDesc, sizeof(stDesc), "+%i%% %t", RoundToNearest(g_flSqueezer_dmgmult*100), "BonusDamageText");
		}
		else if (smokerPerk == InfectedSmokerPerk_DragAndDrop && g_bDrag_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedSmokerDragAndDrop");
			Format(stDesc, sizeof(stDesc), "%t", "DragAndDropDescriptionPanel");
		}
		else if (smokerPerk == InfectedSmokerPerk_SmokeIt && g_bSmokeIt_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedSmokerSmokeIt");
			Format(stDesc, sizeof(stDesc), "%t", "SmokeItDescriptionPanel");
		}
		else
		{
			Format(stPerk, sizeof(stPerk), "%t", "NotSet");
			stDesc = "";
		}

		Format(buffer, sizeof(buffer), "%t: %s", "PerkMenuInfectedSmokerTitle", stPerk);
		menu.DrawItem(buffer);
		menu.DrawText(stDesc);
	}
	
	if (g_bInfBoomer_enable)
	{
		InfectedBoomerPerkType boomerPerk = g_ipInf[iCid].boomerPerk;
		if (boomerPerk == InfectedBoomerPerk_BarfBagged && g_iBarf_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedBoomerBarfBagged");
			Format(stDesc, sizeof(stDesc), "%t", "BarfBaggedDescriptionPanel");
		}
		else if (boomerPerk == InfectedBoomerPerk_BlindLuck && g_iBlind_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedBoomerBlindLuck");
			Format(stDesc, sizeof(stDesc), "%t", "AcidVomitDescriptionPanel");
		}
		else if (boomerPerk == InfectedBoomerPerk_DeadWreckening && g_bDead_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedBoomerDeadWreckening");
			Format(stDesc, sizeof(stDesc), "%t: +%i%%", "DeadWreckeningDescriptionPanel", RoundToNearest(100*g_flDead_dmgmult));
		}
		else if (boomerPerk == InfectedBoomerPerk_MotionSickness && g_bMotion_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedBoomerMotionSickness");
			Format(stDesc, sizeof(stDesc), "%t", "MotionSicknessDescriptionPanel");
		}
		else
		{
			Format(stPerk, sizeof(stPerk), "%t", "NotSet");
			stDesc = "";
		}

		Format(buffer, sizeof(buffer), "%t: %s", "PerkMenuInfectedBoomerTitle", stPerk);
		menu.DrawItem(buffer);
		menu.DrawText(stDesc);
	}

	if (g_bInfHunter_enable)
	{
		InfectedHunterPerkType hunterPerk = g_ipInf[iCid].hunterPerk;
		if (hunterPerk == InfectedHunterPerk_BodySlam && g_bBody_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedHunterBodySlam");
			Format(stDesc, sizeof(stDesc), "%i %t", g_iBody_minbound, "BodySlamDescriptionPanel");
		}
		else if (hunterPerk == InfectedHunterPerk_EfficientKiller && g_bEfficient_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedHunterEfficientKiller");
			Format(stDesc, sizeof(stDesc),"+%i%% %t", RoundToNearest(g_flEfficient_dmgmult*100), "BonusDamageText");
		}
		else if (hunterPerk == InfectedHunterPerk_Grasshopper && g_bGrass_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedHunterGrasshopper");
			Format(stDesc, sizeof(stDesc), "%t: +%i%%", "GrasshopperDescriptionPanel", RoundToNearest( (g_flGrass_rate - 1) * 100 ) );
		}
		else if (hunterPerk == InfectedHunterPerk_SpeedDemon && g_bSpeedDemon_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedHunterSpeedDemon");
			Format(stDesc, sizeof(stDesc), "+%i%% %t +%i%% %t", RoundToNearest(g_flSpeedDemon_dmgmult*100), "OldSchoolDescriptionPanel", RoundToNearest( (g_flSpeedDemon_rate - 1) * 100 ), "SpeedDemonDescriptionPanel");
		}
		else
		{
			Format(stPerk, sizeof(stPerk), "%t", "NotSet");
			stDesc = "";
		}

		Format(buffer, sizeof(buffer), "%t: %s", "PerkMenuInfectedHunterTitle", stPerk);
		menu.DrawItem(buffer);
		menu.DrawText(stDesc);
	}

	if (g_bInfSpitter_enable && g_bIsL4D2)
	{
		InfectedSpitterPerkType spitterPerk = g_ipInf[iCid].spitterPerk;
		if (spitterPerk == InfectedSpitterPerk_TwinSpitfire && g_bTwinSF_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedSpitterTwinSpitfire");
			Format(stDesc, sizeof(stDesc), "%t", "TwinSpitfireDescriptionPanel");
		}
		else if (spitterPerk == InfectedSpitterPerk_MegaAdhesive && g_bMegaAd_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedSpitterMegaAdhesive");
			Format(stDesc, sizeof(stDesc), "%t: %i%%", "MegaAdhesiveDescriptionPanel", RoundToNearest( 100 - (g_flMegaAd_slow) * 100 ) );
		}
		else
		{
			Format(stPerk, sizeof(stPerk), "%t", "NotSet");
			stDesc = "";
		}

		Format(buffer, sizeof(buffer), "%t: %s", "PerkMenuInfectedSpitterTitle", stPerk);
		menu.DrawItem(buffer);
		menu.DrawText(stDesc);
	}

	if (g_bInfJockey_enable && g_bIsL4D2)
	{
		InfectedJockeyPerkType jockeyPerk = g_ipInf[iCid].jockeyPerk;
		if (jockeyPerk == InfectedJockeyPerk_Wind && g_bWind_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedJockeyWind");
			Format(stDesc, sizeof(stDesc), "%t: +%i%%", "RideLikeTheWindDescriptionPanel", RoundToNearest( (g_flWind_rate - 1) * 100 ) );
		}
		else if (jockeyPerk == InfectedJockeyPerk_Cavalier && g_bCavalier_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedJockeyCavalier");
			Format(stDesc, sizeof(stDesc), "+%i%% %t", RoundToNearest( g_flCavalier_hpmult * 100 ), "UnbreakableHint");
		}
		else if (jockeyPerk == InfectedJockeyPerk_Frogger && g_bFrogger_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedJockeyFrogger");
			Format(stDesc, sizeof(stDesc), "+%i%% %t +%i%% %t", RoundToNearest( (g_flFrogger_rate - 1) * 100 ), "FroggerDescriptionPanel", RoundToNearest(g_flFrogger_dmgmult*100), "BonusDamageText");
		}
		else if (jockeyPerk == InfectedJockeyPerk_Ghost && g_bGhost_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedJockeyGhost");
			Format(stDesc, sizeof(stDesc), "%i%% %t", RoundToNearest( (1 - (g_iGhost_alpha/255.0)) *100 ), "GhostRiderDescriptionPanel");
		}
		else
		{
			Format(stPerk, sizeof(stPerk), "%t", "NotSet");
			stDesc = "";
		}

		Format(buffer, sizeof(buffer), "%t: %s", "PerkMenuInfectedJockeyTitle", stPerk);
		menu.DrawItem(buffer);
		menu.DrawText(stDesc);
	}

	if (g_bInfCharger_enable && g_bIsL4D2)
	{
		InfectedChargerPerkType chargerPerk = g_ipInf[iCid].chargerPerk;
		if (chargerPerk == InfectedChargerPerk_Scatter && g_bScatter_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedChargerScatter");
			Format(stDesc, sizeof(stDesc), "%t", "ScatteringRamDescriptionPanel");
		}
		else if (chargerPerk == InfectedChargerPerk_Bullet && g_bBullet_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedChargerBullet");
			Format(stDesc, sizeof(stDesc), "%t: +%i%%", "SpeedingBulletDescriptionPanel", RoundToNearest(g_flBullet_rate*100 - 100) );
		}
		else
		{
			Format(stPerk, sizeof(stPerk), "%t", "NotSet");
			stDesc = "";
		}

		Format(buffer, sizeof(buffer), "%t: %s", "PerkMenuInfectedChargerTitle", stPerk);
		menu.DrawItem(buffer);
		menu.DrawText(stDesc);
	}

	if (g_bInfTank_enable)
	{
		InfectedTankPerkType tankPerk = g_ipInf[iCid].tankPerk;
		if (tankPerk == InfectedTankPerk_AdrenalGlands && g_bAdrenal_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedTankAdrenalGlands");
			Format(stDesc, sizeof(stDesc), "%t", "AdrenalGlandsDescriptionPanelShort");
		}
		else if (tankPerk == InfectedTankPerk_Juggernaut && g_bJuggernaut_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedTankJuggernaut");
			Format(stDesc, sizeof(stDesc), "+%i %t", g_iJuggernaut_hp, "UnbreakableHint");
		}
		else if (tankPerk == InfectedTankPerk_MetabolicBoost && g_bMetabolic_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedTankMetabolicBoost");
			Format(stDesc, sizeof(stDesc), "+%i%% %t", RoundToNearest((g_flMetabolic_speedmult-1)*100), "SpeedDemonDescriptionPanel");
		}
		else if (tankPerk == InfectedTankPerk_Stormcaller && g_bStorm_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedTankStormcaller");
			Format(stDesc, sizeof(stDesc), "%t", "StormCallerDescriptionPanel");
		}
		else if (tankPerk == InfectedTankPerk_DoubleTrouble && g_iDouble_enable)
		{
			Format(stPerk, sizeof(stPerk), "%t", "PerkMenuInfectedTankDoubleTrouble");
			Format(stDesc, sizeof(stDesc), "%t", "DoubleTroubleDescriptionPanel");
		}
		else
		{
			Format(stPerk, sizeof(stPerk), "%t", "NotSet");
			stDesc = "";
		}

		Format(buffer, sizeof(buffer), "%t: %s", "PerkMenuInfectedTankTitle", stPerk);
		menu.DrawItem(buffer);
		menu.DrawText(stDesc);
	}

	return menu;
}

//=============================
//	SUR1 PERK CHOICE
//=============================

//build menu for Sur1 Perks
Panel Menu_Sur1Perk(int client)
{
	char buffer[75];
	char st_current[10];

	Panel menu = CreatePanel();

	Format(buffer, sizeof(buffer), "Perkmod • %t", "PerkMenuSurvivorFirstPerkTitle");
	menu.SetTitle(buffer);

	SurvivorFirstPerkType perkType = g_spSur[client].firstPerk;

	//set name for perk 1
	if (GameModeCheck(true, g_iStopping_enable) == false)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorFirstPerk_StoppingPower ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuSurvivorFirstPerkStoppingPower", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "+%i%% %t", RoundToNearest(g_flStopping_dmgmult*100), "BonusDamageText");
		menu.DrawText(buffer);
	}

	//set name for perk 2
	if (GameModeCheck(true, g_iDT_enable) == false)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorFirstPerk_DoubleTap ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuSurvivorFirstPerkDoubleTap", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t +%i%%", "DoubleTapDescriptionPanel", RoundToNearest(100 * ((1/g_flDT_rate)-1) ) );
		menu.DrawText(buffer);

		if (g_flDT_rate_reload < 1.0)
		{
			Format(buffer, sizeof(buffer), "%t +%i%%", "SleighOfHandDescriptionPanel", RoundToNearest(100 * ((1/g_flDT_rate_reload)-1) ) );
			menu.DrawText(buffer);
		}

		Format(buffer, sizeof(buffer), "%t", "DoubleTapRestrictionWarning");
		menu.DrawText(buffer);
	}

	//set name for perk 3
	if (GameModeCheck(true, g_iSoH_enable) == false)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorFirstPerk_SleightOfHand ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuSurvivorFirstPerkSleightOfHand", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t +%i%%", "SleighOfHandDescriptionPanel", RoundToNearest(100 * ((1/g_flSoH_rate)-1) ) );
		menu.DrawText(buffer);
	}

	//set name for perk 4
	if (GameModeCheck(true, g_iPyro_enable) == false)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorFirstPerk_Pyrotechnician ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuSurvivorFirstPerkPyrotechnician", st_current);
		menu.DrawItem(buffer);
		Format(buffer, sizeof(buffer), "%t", "PyroDescriptionText1");
		menu.DrawText(buffer);
		Format(buffer, sizeof(buffer), "%t", "PyroDescriptionText2");
		menu.DrawText(buffer);
	}

	return menu;
}

//setting Sur1 perk and returning to top menu
int Menu_ChooseSur1Perk(Menu menu, MenuAction action, int client, int param2)
{
	if (menu != INVALID_HANDLE) CloseHandle(menu);

	if (action == MenuAction_Select)
	{
		if (1 <= param2 <= PM_SurvivorFirstPerkTypeToInt(SurvivorFirstPerk_Count)) {
			g_spSur[client].firstPerk = PM_IntToSurvivorFirstPerkType(param2);
		}
	}

	if (IsClientInGame(client))
		SendPanelToClient(Menu_Top(client), client, Menu_ChooseSubMenu, MENU_TIME_FOREVER);

	return 0;
}

//=============================
//	SUR2 CHOICE
//=============================

//build menu for Sur2 Perks
Panel Menu_Sur2Perk(int client)
{
	char buffer[75];
	char st_current[10];

	Panel menu = CreatePanel();
	Format(buffer, sizeof(buffer), "Perkmod • %t", "PerkMenuSurvivorSecondPerkTitle");
	menu.SetTitle(buffer);

	SurvivorSecondPerkType perkType = g_spSur[client].secondPerk;

	//set name for perk 1
	if (GameModeCheck(true, g_iUnbreak_enable) == false)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorSecondPerk_Unbreakable ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuSurvivorSecondPerkUnbreakable", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "+%i %t", g_iUnbreak_hp, "UnbreakableHint");
		menu.DrawText(buffer);
	}

	//set name for perk 2
	if (GameModeCheck(true, g_iSpirit_enable) == false)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorSecondPerk_Spirit ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuSurvivorSecondPerkSpirit", st_current);
		menu.DrawItem(buffer);

		int iTime = g_iSpirit_cd;
		if (g_L4D_GameMode == GameMode_Versus)
			iTime=g_iSpirit_cd_vs;
		else if (g_L4D_GameMode == GameMode_Survival)
			iTime=g_iSpirit_cd_sur;

		Format(buffer, sizeof(buffer), "%t", "SpiritDescriptionText", iTime / 60);
		menu.DrawText(buffer);

		Format(buffer, sizeof(buffer), "+%i %t", g_iSpirit_buff, "SpritDescriptionText2");
		menu.DrawText(buffer);
	}

	//set name for perk 3
	if (GameModeCheck(true, g_iHelpHand_enable) == false)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorSecondPerk_HelpingHand ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuSurvivorSecondPerkHelpingHand", st_current);
		menu.DrawItem(buffer);

		int iBuff = g_iHelpHand_buff;
		if (g_L4D_GameMode == GameMode_Versus)
			iBuff=g_iHelpHand_buff_vs;

		if (g_bHelpHand_convar)
		{
			Format(buffer, sizeof(buffer), "%t +%i", "HelpingHandDescriptionPanel2", iBuff);
			menu.DrawText(buffer);
		}
		else
		{
			Format(buffer, sizeof(buffer), "%t +%i", "HelpingHandDescriptionPanel", iBuff);
			menu.DrawText(buffer);
		}

		//set name for perk 4, Martial Artist
		if (g_bIsL4D2 == false || GameModeCheck(true, g_iMA_enable) == false)
		{
			menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
		}
		else
		{
			st_current = (perkType == SurvivorSecondPerk_MartialArtist ? "(*)" : "");

			Format(buffer, sizeof(buffer), "%t %s", "PerkMenuSurvivorSecondPerkMartialArtist", st_current);
			menu.DrawItem(buffer);

			Format(buffer, sizeof(buffer),"%t", "MartialArtistDescriptionPanel1");
			menu.DrawText(buffer);

			if (g_iMA_maxpenalty < 6)
			{
				Format(buffer, sizeof(buffer), "%t", "MartialArtistDescriptionPanel2");
				menu.DrawText(buffer);
			}
		}
	}

	return menu;
}

//setting Sur2 perk and returning to top menu
int Menu_ChooseSur2Perk(Menu menu, MenuAction action, int client, int param2)
{
	if (menu != INVALID_HANDLE) CloseHandle(menu);
	if (action == MenuAction_Select)
	{
		if (1 <= param2 <= PM_SurvivorSecondPerkTypeToInt(SurvivorSecondPerk_Count)) {
			g_spSur[client].secondPerk = PM_IntToSurvivorSecondPerkType(param2);
		}
	}

	if (IsClientInGame(client))
		SendPanelToClient(Menu_Top(client), client, Menu_ChooseSubMenu, MENU_TIME_FOREVER);

	return 0;
}

//=============================
//	SUR3 CHOICE
//=============================

//build menu for Sur3 Perks
Panel Menu_Sur3Perk(int client)
{
	char buffer[75];
	char st_current[10];

	Panel menu = CreatePanel();
	Format(buffer, sizeof(buffer), "Perkmod • %t", "PerkMenuSurvivorThirdPerkTitle");
	menu.SetTitle(buffer);

	SurvivorThirdPerkType perkType = g_spSur[client].thirdPerk;

	//set name for perk 1
	if (GameModeCheck(true, g_iPack_enable) == false)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorThirdPerk_PackRat ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuSurvivorThirdPerkPackRat", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t +%i%%", "PackRatDescriptionPanel", RoundToNearest(g_flPack_ammomult*100));
		menu.DrawText(buffer);
	}

	//set name for perk 2
	if (GameModeCheck(true, g_iChem_enable) == false)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorThirdPerk_ChemReliant ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuSurvivorThirdPerkChemReliant", st_current);
		menu.DrawItem(buffer);

		if (g_iChem_buff > 0)
		{
			Format(buffer, sizeof(buffer), "%t (+%i)", "ChemReliantDescriptionText", g_iChem_buff);
			menu.DrawText(buffer);
		}
		Format(buffer, sizeof(buffer), "%t", "ChemReliantDescriptionText2");
		menu.DrawText(buffer);
	}

	//set name for perk 3
	if (GameModeCheck(true, g_iHard_enable) == false)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorThirdPerk_HardToKill ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuSurvivorThirdPerkHardToKill", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t", "HardToKillDescriptionText", RoundToNearest(100*g_flHard_hpmult));
		menu.DrawText(buffer);
	}

	//set name for perk 4
	if (GameModeCheck(true, g_iExtreme_enable) == false)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorThirdPerk_ExtremeConditioning ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuSurvivorThirdPerkExtremeConditioning", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t: +%i%%", "MartialArtistDescriptionPanelCoop", RoundToNearest(100*g_flExtreme_rate-100) );
		menu.DrawText(buffer);
	}

	//set name for perk 5
	if (g_bIsL4D2 == false || GameModeCheck(true, g_iLittle_enable) == false)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorThirdPerk_LittleLeaguer ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuSurvivorThirdPerkLittleLeaguer", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t", "LittleLeaguerDescriptionPanel");
		menu.DrawText(buffer);
	}

	return menu;
}

//setting Sur3 perk and returning to top menu
int Menu_ChooseSur3Perk(Menu menu, MenuAction action, int client, int param2)
{
	if (menu != INVALID_HANDLE) CloseHandle(menu);

	if (action == MenuAction_Select)
	{
		if (1 <= param2 <= PM_SurvivorThirdPerkTypeToInt(SurvivorThirdPerk_Count)) {
			g_spSur[client].thirdPerk = PM_IntToSurvivorThirdPerkType(param2);
		}
	}

	if (IsClientInGame(client))
		SendPanelToClient(Menu_Top(client), client, Menu_ChooseSubMenu, MENU_TIME_FOREVER);

	return 0;
}

//=============================
//	MARK: - SMOKER Choice
//=============================

Panel Menu_InfSmokerPerk(int client)
{
	char buffer[75];
	char st_current[10];

	Panel menu = CreatePanel();
	Format(buffer, sizeof(buffer), "Perkmod • %t", "PerkMenuInfectedSmokerTitle");
	menu.SetTitle(buffer);

	InfectedSmokerPerkType perkType = g_ipInf[client].smokerPerk;

	//set name for perk 1
	if (!g_bTongue_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedSmokerPerk_TongueTwister ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedSmokerTongueTwister", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t", "TongueTwisterDescriptionPanel1", 
				RoundToNearest(100*(g_flTongue_speedmult-1)),
				RoundToNearest(100*(g_flTongue_rangemult-1))
			);
		menu.DrawText(buffer);

		Format(buffer, sizeof(buffer), "%t: +%i%%", "TongueTwisterDescriptionPanel2", RoundToNearest(100*(g_flTongue_pullmult-1)) );
		menu.DrawText(buffer);
	}

	//set name for perk 2
	if (!g_bSqueezer_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedSmokerPerk_Squeezer ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedSmokerSqueezer", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t: +%i%%", "SqueezerDescriptionText", RoundToNearest(g_flSqueezer_dmgmult*100) );
		menu.DrawText(buffer);
	}

	//set name for perk 3
	if (!g_bDrag_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedSmokerPerk_DragAndDrop ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedSmokerDragAndDrop", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t", "DragAndDropDescriptionPanel");
		menu.DrawText(buffer);
	}

	//set name for perk 4
	if (!g_bSmokeIt_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedSmokerPerk_SmokeIt ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedSmokerSmokeIt", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t", "SmokeItDescriptionPanel");
		menu.DrawText(buffer);
	}

	return menu;
}

int Menu_ChooseInfSmokerPerk(Menu menu, MenuAction action, int client, int param2)
{
	if (menu != INVALID_HANDLE) CloseHandle(menu);
	if (action == MenuAction_Select)
	{
		if (1 <= param2 <= PM_InfectedSmokerPerkTypeToInt(InfectedSmokerPerk_Count)) {
			g_ipInf[client].smokerPerk = PM_IntToInfectedSmokerPerkType(param2);
		}
	}

	if (IsClientInGame(client))
		SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);

	return 0;
}


//=============================
//	MARK: - BOOMER Choice
//=============================

Panel Menu_InfBoomerPerk(int client)
{
	char buffer[75];
	char st_current[10];

	Panel menu = CreatePanel();
	Format(buffer, sizeof(buffer), "Perkmod • %t", "PerkMenuInfectedBoomerTitle");
	menu.SetTitle(buffer);

	InfectedBoomerPerkType perkType = g_ipInf[client].boomerPerk;

	//set name for perk 1
	if (!g_iBarf_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedBoomerPerk_BarfBagged ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedBoomerBarfBagged", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t", "BarfBaggedDescriptionPanel");
		menu.DrawText(buffer);
	}

	//set name for perk 2
	if (!g_iBlind_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedBoomerPerk_BlindLuck ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedBoomerBlindLuck", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t: %i%%", "AcidVomitDescriptionPanel", RoundToNearest(100 - g_flBlind_cdmult*100));
		menu.DrawText(buffer);
	}

	//set name for perk 3
	if (!g_bDead_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedBoomerPerk_DeadWreckening ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedBoomerDeadWreckening", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t: +%i%%", "DeadWreckeningDescriptionPanel", RoundToNearest(100*g_flDead_dmgmult));
		menu.DrawText(buffer);
	}

	//set name for perk 4
	if (!g_bMotion_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedBoomerPerk_MotionSickness ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedBoomerMotionSickness", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t", "MotionSicknessDescriptionPanel");
		menu.DrawText(buffer);
	}

	return menu;
}

int Menu_ChooseInfBoomerPerk(Menu menu, MenuAction action, int client, int param2)
{
	if (menu != INVALID_HANDLE) CloseHandle(menu);
	if (action == MenuAction_Select)
	{
		if (1 <= param2 <= PM_InfectedBoomerPerkTypeToInt(InfectedBoomerPerk_Count)) {
			g_ipInf[client].boomerPerk = PM_IntToInfectedBoomerPerkType(param2);
		}
	}

	if (IsClientInGame(client))
		SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);

	return 0;
}

//=============================
//	MARK: - HUNTER Choice
//=============================

Panel Menu_InfHunterPerk(int client)
{
	char buffer[75];
	char st_current[10];

	Panel menu = CreatePanel();
	Format(buffer, sizeof(buffer), "Perkmod • %t", "PerkMenuInfectedHunterTitle");
	menu.SetTitle(buffer);

	InfectedHunterPerkType perkType = g_ipInf[client].hunterPerk;

	//set name for perk 1
	if (!g_bBody_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedHunterPerk_BodySlam ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedHunterBodySlam", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t %i", "BodySlamDescriptionPanel", g_iBody_minbound);
		menu.DrawText(buffer);
	}

	//set name for perk 2
	if (!g_bEfficient_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedHunterPerk_EfficientKiller ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedHunterEfficientKiller", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "+%i%% %t", RoundToNearest(g_flEfficient_dmgmult*100), "BonusDamageText");
		menu.DrawText(buffer);
	}

	//set name for perk 3
	if (!g_bGrass_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedHunterPerk_Grasshopper ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedHunterGrasshopper", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t: +%i%%", "GrasshopperDescriptionPanel", RoundToNearest( (g_flGrass_rate - 1) * 100 ) );
		menu.DrawText(buffer);
	}

	//set name for perk 4
	if (!g_bSpeedDemon_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedHunterPerk_SpeedDemon ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedHunterSpeedDemon", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "+%i%% %t +%i%% %t", RoundToNearest(g_flSpeedDemon_dmgmult*100), "OldSchoolDescriptionPanel", RoundToNearest( (g_flSpeedDemon_rate - 1) * 100 ), "SpeedDemonDescriptionPanel");
		menu.DrawText(buffer);
	}

	return menu;
}

int Menu_ChooseInfHunterPerk(Menu menu, MenuAction action, int client, int param2)
{
	if (menu != INVALID_HANDLE) CloseHandle(menu);

	if (action == MenuAction_Select)
	{
		if (1 <= param2 <= PM_InfectedHunterPerkTypeToInt(InfectedHunterPerk_Count)) {
			g_ipInf[client].hunterPerk = PM_IntToInfectedHunterPerkType(param2);
		}
	}

	if (IsClientInGame(client))
		SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);

	return 0;
}

//=============================
//	MARK: - SPITTER Choice
//=============================

Panel Menu_InfSpitterPerk(int client)
{
	char buffer[75];
	char st_current[10];

	Panel menu = CreatePanel();
	Format(buffer, sizeof(buffer), "Perkmod • %t", "PerkMenuInfectedSpitterTitle");
	menu.SetTitle(buffer);

	InfectedSpitterPerkType perkType = g_ipInf[client].spitterPerk;

	//set name for perk 1
	if (!g_bTwinSF_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedSpitterPerk_TwinSpitfire ? "(*)": "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedSpitterTwinSpitfire", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer),  "%t", "TwinSpitfireDescriptionPanel");
		menu.DrawText(buffer);
	}

	//set name for perk 2
	if (!g_bMegaAd_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedSpitterPerk_MegaAdhesive ? "(*)": "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedSpitterMegaAdhesive", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer),  "%t: %i%%", "MegaAdhesiveDescriptionPanel", RoundToNearest( 100 - (g_flMegaAd_slow) * 100 ) );
		menu.DrawText(buffer);
	}

	return menu;
}

int Menu_ChooseInfSpitterPerk(Menu menu, MenuAction action, int client, int param2)
{
	if (menu != INVALID_HANDLE) CloseHandle(menu);

	if (action == MenuAction_Select)
	{
		if (1 <= param2 <= PM_InfectedSpitterPerkTypeToInt(InfectedSpitterPerk_Count)) {
			g_ipInf[client].spitterPerk = PM_IntToInfectedSpitterPerkType(param2);
		}
	}

	if (IsClientInGame(client))
		SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);

	return 0;
}

//=============================
//	MARK: - JOCKEY Choice
//=============================

Panel Menu_InfJockeyPerk(int client)
{
	char buffer[75];
	char st_current[10];

	Panel menu = CreatePanel();
	Format(buffer, sizeof(buffer), "Perkmod • %t", "PerkMenuInfectedJockeyTitle");
	menu.SetTitle(buffer);

	InfectedJockeyPerkType perkType = g_ipInf[client].jockeyPerk;

	//set name for perk 1
	if (!g_bWind_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedJockeyPerk_Wind ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedJockeyWind", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t: +%i%%", "RideLikeTheWindDescriptionPanel", RoundToNearest( (g_flWind_rate - 1) * 100 ) );
		menu.DrawText(buffer);
	}

	//set name for perk 2
	if (!g_bCavalier_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedJockeyPerk_Cavalier ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedJockeyCavalier", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "+%i%% %t", RoundToNearest( g_flCavalier_hpmult * 100 ), "UnbreakableHint");
		menu.DrawText(buffer);
	}

	//set name for perk 3
	if (!g_bFrogger_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedJockeyPerk_Frogger ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedJockeyFrogger", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "+%i%% %t +%i%% %t", RoundToNearest( (g_flFrogger_rate - 1) * 100 ), "FroggerDescriptionPanel", RoundToNearest(g_flFrogger_dmgmult*100), "BonusDamageText");
		menu.DrawText(buffer);
	}

	//set name for perk 4
	if (!g_bGhost_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedJockeyPerk_Ghost ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedJockeyGhost", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%i%% %t", RoundToNearest( (1 - (g_iGhost_alpha/255.0)) *100 ), "GhostRiderDescriptionPanel");
		menu.DrawText(buffer);
	}

	return menu;
}

int Menu_ChooseInfJockeyPerk(Menu menu, MenuAction action, int client, int param2)
{
	if (menu != INVALID_HANDLE) CloseHandle(menu);

	if (action == MenuAction_Select)
	{
		if (1 <= param2 <= PM_InfectedJockeyPerkTypeToInt(InfectedJockeyPerk_Count)) {
			g_ipInf[client].jockeyPerk = PM_IntToInfectedJockeyPerkType(param2);
		}
	}

	if (IsClientInGame(client))
		SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);

	return 0;
}

//=============================
//	MARK: - CHARGER Choice
//=============================

Panel Menu_InfChargerPerk(int client)
{
	char buffer[75];
	char st_current[10];

	Panel menu = CreatePanel();
	Format(buffer, sizeof(buffer), "Perkmod • %t", "PerkMenuInfectedChargerTitle");
	menu.SetTitle(buffer);

	InfectedChargerPerkType perkType = g_ipInf[client].chargerPerk;

	//set name for perk 1
	if (!g_bScatter_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedChargerPerk_Scatter ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedChargerScatter", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "+%i%% %t", RoundToNearest(g_flScatter_hpmult*100), "ScatteringRamDescriptionPanel");
		menu.DrawText(buffer);
	}

	//set name for perk 2
	if (!g_bBullet_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedChargerPerk_Bullet ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedChargerBullet", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t: +%i%%", "SpeedingBulletDescriptionPanel", RoundToNearest(g_flBullet_rate*100 - 100) );
		menu.DrawText(buffer);
	}

	return menu;
}

int Menu_ChooseInfChargerPerk(Menu menu, MenuAction action, int client, int param2)
{
	if (menu != INVALID_HANDLE) CloseHandle(menu);

	if (action == MenuAction_Select)
	{
		if (1 <= param2 <= PM_InfectedChargerPerkTypeToInt(InfectedChargerPerk_Count)) {
			g_ipInf[client].chargerPerk = PM_IntToInfectedChargerPerkType(param2);
		}
	}

	if (IsClientInGame(client))
		SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);

	return 0;
}

//=============================
//	MARK: - TANK Choice
//=============================

Panel Menu_InfTankPerk(int client)
{
	char buffer[75];
	char st_current[10];

	Panel menu = CreatePanel();
	Format(buffer, sizeof(buffer), "Perkmod • %t", "PerkMenuInfectedTankTitle");
	menu.SetTitle(buffer);

	InfectedTankPerkType perkType = g_ipInf[client].tankPerk;

	//set name for perk 1
	if (!g_bAdrenal_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedTankPerk_AdrenalGlands ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedTankAdrenalGlands", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t", "AdrenalGlandsDescriptionPanel1", 
				RoundToNearest(100 * ((1/g_flAdrenal_punchcdmult)-1)),
				RoundToNearest(100 - 100*g_flAdrenal_throwcdmult)
				);
		menu.DrawText(buffer);

		Format(buffer, sizeof(buffer), "%t", "AdrenalGlandsDescriptionPanel2");
		menu.DrawText(buffer);
	}

	//set name for perk 2
	if (!g_bJuggernaut_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedTankPerk_Juggernaut ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedTankJuggernaut", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "+%i %t", g_iJuggernaut_hp, "UnbreakableHint");
		menu.DrawText(buffer);
	}

	//set name for perk 3
	if (!g_bMetabolic_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedTankPerk_MetabolicBoost ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedTankMetabolicBoost", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "+%i%% %t", RoundToNearest((g_flMetabolic_speedmult-1)*100), "SpeedDemonDescriptionPanel");
		menu.DrawText(buffer);
	}

	//set name for perk 4
	if (!g_bStorm_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedTankPerk_Stormcaller ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedTankStormcaller", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t", "StormCallerDescriptionPanel");
		menu.DrawText(buffer);
	}

	//set name for perk 5
	if (!g_iDouble_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedTankPerk_DoubleTrouble ? "(*)" : "");

		Format(buffer, sizeof(buffer), "%t %s", "PerkMenuInfectedTankDoubleTrouble", st_current);
		menu.DrawItem(buffer);

		Format(buffer, sizeof(buffer), "%t", "DoubleTroubleDescriptionPanel");
		menu.DrawText(buffer);

		Format(buffer, sizeof(buffer), "%t: -%i%%", "DoubleTroubleDescriptionPanel2", RoundToNearest(100 - g_flDouble_hpmult*100));
		menu.DrawText(buffer);
	}

	return menu;
}

int Menu_ChooseInfTankPerk(Menu menu, MenuAction action, int client, int param2)
{
	if (menu != INVALID_HANDLE) CloseHandle(menu);

	if (action == MenuAction_Select)
	{
		if (1 <= param2 <= PM_InfectedTankPerkTypeToInt(InfectedTankPerk_Count)) {
			g_ipInf[client].tankPerk = PM_IntToInfectedTankPerkType(param2);
		}
	}

	if (IsClientInGame(client))
		SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);

	return 0;
}

//=============================
//	DEBUG
//=============================

Action SS_SetPerks(int iCid, int args)
{
	ClientTeamType iT = SM_GetClientTeamType(iCid);

	//don't show the menu if all perks are disabled
	if ((!g_bSurAll_enable && iT == ClientTeam_Survivor) || (!g_bInfAll_enable && iT == ClientTeam_Infected))
	{
		g_bConfirm[iCid] = false;
		return Plugin_Continue;
	}

	g_spSur[iCid].firstPerk = SurvivorFirstPerk_StoppingPower;
	g_spSur[iCid].secondPerk = SurvivorSecondPerk_Unbreakable;
	g_spSur[iCid].thirdPerk = SurvivorThirdPerk_HardToKill;
	g_bConfirm[iCid] = true;

	if (iT == ClientTeam_Survivor)
		SendPanelToClient(Menu_ShowChoices(iCid), iCid, Menu_DoNothing, 15);

	return Plugin_Continue;
}

// MARK: - Helpers

bool StringInsensitiveContains(const char[] lhs, const char[] rhs)
{
	return StrContains(lhs, rhs, false) != -1;
}

bool GameModeCheck(bool main, kConVarEnableType enableType)
{
	return (main
		&& ((enableType & ConVarEnable_Campaign) && g_L4D_GameMode == GameMode_Campaign)
		|| ((enableType & ConVarEnable_Survival) && g_L4D_GameMode == GameMode_Survival)
		|| ((enableType & ConVarEnable_Versus)	&& g_L4D_GameMode == GameMode_Versus));
}

// MARK: - Debug

#if defined PM_DEBUG
Action Debug_OnSay(int iCid, int args)
{
	if (args < 1) return Plugin_Continue;
	char st_chat[32];
	GetCmdArg(1, st_chat, sizeof(st_chat));

	if (StrEqual(st_chat, "debug reset perks", false))
	{
		g_bConfirm[iCid] = false;
		PrintToChat(iCid,"\x03[SM] [DEBUG] g_iConfirm has been reset to 0");
		RebuildAll();

		return Plugin_Continue;
	}

	if (StrEqual(st_chat, "debug spirit reset", false))
	{
		PrintToChat(iCid,"\x03[SM] [DEBUG] spirit cooldown reset");
		g_iSpiritCooldown[iCid] = 0;
		return Plugin_Continue;
	}

	if (StrEqual(st_chat, "debug death", false))
	{
		int iDeathTimeO = FindSendPropInfo("CTerrorPlayer", "m_flDeathTime");
		PrintToChat(iCid,"\x03[SM] [DEBUG] m_fldeathtime offset \x01%i\x03", iDeathTimeO);
		PrintToChat(iCid,"\x03[SM] [DEBUG] -value at offset: \x01%f", GetEntDataFloat(iCid, iDeathTimeO));
		return Plugin_Continue;
	}

	if (StrEqual(st_chat, "debug client", false))
	{
		PrintToChat(iCid,"\x03[SM] [DEBUG] you are client: \x01%i", iCid);
		return Plugin_Continue;
	}

	if (StrEqual(st_chat, "debug anim", false))
	{
		PrintToChat(iCid,"\x03[SM] [DEBUG] creating timer, client \x01%i\x03, gunid \x01%i", iCid, GetEntDataEnt2(iCid, g_iActiveWO));
		CreateTimer(0.2, Debug_AnimTimer, iCid, TIMER_REPEAT);

		return Plugin_Continue;
	}

	if (StrEqual(st_chat, "debug frustration", false))
	{
		PrintToChat(iCid,"\x03[SM] [DEBUG] retrieving frustration values");
		int iOffs = FindSendPropInfo("Tank", "m_frustration");
		PrintToChat(iCid,"\x03- offset \x01%i", iOffs);
		PrintToChat(iCid,"\x03- value at offset \x01%i", GetEntData(iCid, iOffs) );

		return Plugin_Continue;
	}

	if (StrEqual(st_chat, "debug stamina", false))
	{
		PrintToChat(iCid,"\x03[SM] [DEBUG] creating timer, client \x01%i\x03", iCid);
		CreateTimer(0.2, Debug_StaminaTimer, iCid, TIMER_REPEAT);

		return Plugin_Continue;
	}

	if (StrEqual(st_chat, "debug maxclients", false))
	{
		PrintToChat(iCid,"\x03[SM] [DEBUG] maxclients = \x01%i", MaxClients);

		return Plugin_Continue;
	}

	if (StrEqual(st_chat, "debug ammo2", false))
	{
		//int iAmmoO = FindDataMapOffs(iCid,"m_iAmmo");
		int iEntid  =  GetEntDataEnt2(iCid, g_iActiveWO);
		int iPrimO  =  FindSendPropInfo("CTerrorGun", "m_iExtraPrimaryAmmo");
		PrintToChatAll("\x03[SM] [DEBUG] extra primary ammo, offset \x01%i\x03 value \x01%i", iPrimO, GetEntData(iEntid, iPrimO));
	}

	if (StrEqual(st_chat, "debug ammo", false))
	{
		int iAmmoO = FindDataMapInfo(iCid,"m_iAmmo");
		PrintToChatAll("\x03[SM] [DEBUG] Ammo Counts, offset \x01%i", iAmmoO);
		for (int i = 0; i <= 47; i++)
			PrintToChatAll("\x03%i: iCid\x01 %i\x03", i, GetEntData(iCid, iAmmoO + i));
	}

	if (StrEqual(st_chat, "debug shotgunanim", false))
	{
		PrintToChat(iCid,"\x03[SM] [DEBUG] retrieving shotgun reload anim values");
		int iEntid = GetEntDataEnt2(iCid, g_iActiveWO);
		int iOffs;

		iOffs = FindSendPropInfo("CBaseShotgun", "m_reloadStartDuration");
		PrintToChat(iCid,"\x03- start, offset \x01%i", iOffs);
		PrintToChat(iCid,"\x03-- value at offset \x01%f", GetEntDataFloat(iEntid, iOffs) );

		iOffs = FindSendPropInfo("CBaseShotgun", "m_reloadInsertDuration");
		PrintToChat(iCid,"\x03- insert, offset \x01%i", iOffs);
		PrintToChat(iCid,"\x03-- value at offset \x01%f", GetEntDataFloat(iEntid, iOffs) );

		iOffs = FindSendPropInfo("CBaseShotgun", "m_reloadEndDuration");
		PrintToChat(iCid,"\x03- end, offset \x01%i", iOffs);
		PrintToChat(iCid,"\x03-- value at offset \x01%f", GetEntDataFloat(iEntid, iOffs) );

		return Plugin_Continue;
	}

	if (StrEqual(st_chat, "debug fatigue", false))
	{
		PrintToChat(iCid,"\x03[SM] [DEBUG] shove penalty \x01%i\x03", GetEntData(iCid, g_iMeleeFatigueO));

		return Plugin_Continue;
	}

	if (StrEqual(st_chat, "debug nextact", false))
	{
		g_iNextActO	= FindSendPropInfo("CBaseAbility", "m_nextActivationTimer");
		PrintToChat(iCid,"\x03[SM] [DEBUG] g_iNextActO = \x01%i\x03", g_iNextActO);

		return Plugin_Continue;
	}

	return Plugin_Continue;
}

Action Debug_AnimTimer(Handle timer, int iCid)
{
	int iGun = GetEntDataEnt2(iCid, g_iActiveWO);

	int iAnimTimeO = FindSendPropInfo("CTerrorGun", "m_flAnimTime");
	PrintToChat(iCid,"\x03 m_flAnimTime \x01%i", iAnimTimeO);
	PrintToChat(iCid,"\x03 - value \x01%f", GetEntDataFloat(iGun, iAnimTimeO));

	int iSimTimeO = FindSendPropInfo("CTerrorGun","m_flSimulationTime");
	PrintToChat(iCid,"\x03 m_flSimulationTime \x01%i", iSimTimeO);
	PrintToChat(iCid,"\x03 - value \x01%f", GetEntDataFloat(iGun, iSimTimeO));

	int iSequenceO = FindSendPropInfo("CTerrorGun","m_nSequence");
	PrintToChat(iCid,"\x03 m_nSequence \x01%i", iSequenceO);
	PrintToChat(iCid,"\x03 - value \x01%i", GetEntData(iGun, iSequenceO));

	return Plugin_Continue;
}

Action Debug_StaminaTimer(Handle timer, int iCid)
{
	int iStaminaO = FindSendPropInfo("CTerrorPlayer", "m_flStamina");
	PrintToChat(iCid,"\x03 m_flStamina \x01%i", iStaminaO);
	PrintToChat(iCid,"\x03 - value \x01%f", GetEntDataFloat(iCid, iStaminaO));

	return Plugin_Continue;
}

#endif