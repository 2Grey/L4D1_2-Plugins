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

#include <baseenums>
#include <perkenums>
#include <perkstructs>

#define PLUGIN_NAME "PerkMod"
#define PLUGIN_VERSION "2.2.2"
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
Handle g_hTimerPerks = INVALID_HANDLE;

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
Handle g_iSpiritTimer[MAXPLAYERS+1] = {INVALID_HANDLE};

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
Handle g_hMegaAdTimer[MAXPLAYERS+1] = {INVALID_HANDLE};
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

//these offsets refuse to be searched for (these netprops
//have unique names, but the SENDTABLE names are not unique - 
//usually DT_CountdownTimer, making it impossible to search
//for AFAIK...), so we'll just declare them here and hope
//Valve doesn't change them...

//these offsets are for L4D2, Windows
//-----------------------------
//windows and linux offsets are checked
//during roundstart by comparing an offset
//to known offset numbers

// netprop: m_nextActivationTimer
//int g_iNextActO = 1084;
int g_iNextActO;
// netprop: m_attackTimer??
//int g_iAttackTimerO = 5452;
int g_iAttackTimerO;
//int g_iNextActO = 1068;
//int g_iAttackTimerO = 5436;

//these are for L4D2, Linux
//int g_iNextActO_linux = 1088;
//int g_iAttackTimerO_linux = 5444;



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

//=============================
// Declare Variables Related to
// the Plugin's Own ConVars
//=============================
//first line says the name of the perk
//second line describes how many types there are
//ie:
//"one-size-fits-all" = one variable across all game modes and difficulties
//"versus, non-versus" = one variable for versus games, one for non-versus games
//"normal, hard, expert" = separate variables for normal-versus-survival, advanced and expert


//SUR1 PERKS
//stopping power, damage multiplier
//one-size-fits-all
ConVar g_hStopping_enable;
ConVar g_hStopping_enable_sur;
ConVar g_hStopping_enable_vs;
ConVar g_hStopping_dmgmult;
//associated var
bool g_bStopping_enable;
bool g_bStopping_enable_sur;
bool g_bStopping_enable_vs;
float g_flStopping_dmgmult;

//spirit, bonus buffer and cooldown
//campaign, survival, versus
ConVar g_hSpirit_enable;
ConVar g_hSpirit_enable_sur;
ConVar g_hSpirit_enable_vs;
ConVar g_hSpirit_buff;
ConVar g_hSpirit_cd;
ConVar g_hSpirit_cd_sur;
ConVar g_hSpirit_cd_vs;
//associated vars
bool g_bSpirit_enable;
bool g_bSpirit_enable_sur;
bool g_bSpirit_enable_vs;
int g_iSpirit_buff;
int g_iSpirit_cd;
int g_iSpirit_cd_sur;
int g_iSpirit_cd_vs;

//unbreakable, bonus hp
//one-size-fits-all
ConVar g_hUnbreak_enable;
ConVar g_hUnbreak_enable_sur;
ConVar g_hUnbreak_enable_vs;
ConVar g_hUnbreak_hp;
//associated var
bool g_bUnbreak_enable;
bool g_bUnbreak_enable_sur;
bool g_bUnbreak_enable_vs;
int g_iUnbreak_hp;

//double tap, fire rate
//one-size-fits-all
ConVar g_hDT_enable;
ConVar g_hDT_enable_sur;
ConVar g_hDT_enable_vs;
ConVar g_hDT_rate;
ConVar g_hDT_rate_reload;
//associated var
bool g_bDT_enable;
bool g_bDT_enable_sur;
bool g_bDT_enable_vs;
float g_flDT_rate;
float g_flDT_rate_reload;

//sleight of hand, reload rate
//one-size-fits-all
ConVar g_hSoH_enable;
ConVar g_hSoH_enable_sur;
ConVar g_hSoH_enable_vs;
ConVar g_hSoH_rate;
//associated var
bool g_bSoH_enable;
bool g_bSoH_enable_sur;
bool g_bSoH_enable_vs;
float g_flSoH_rate;

//pyrotechnician
ConVar g_hPyro_enable;
ConVar g_hPyro_enable_sur;
ConVar g_hPyro_enable_vs;
ConVar g_hPyro_maxticks;
//associated vars
bool g_bPyro_enable;
bool g_bPyro_enable_sur;
bool g_bPyro_enable_vs;
int g_iPyro_maxticks;


//SUR2 PERKS
//chem reliant, bonus buffer
//one-size-fits-all
ConVar g_hChem_enable;
ConVar g_hChem_enable_sur;
ConVar g_hChem_enable_vs;
ConVar g_hChem_buff;
//associated var
bool g_bChem_enable;
bool g_bChem_enable_sur;
bool g_bChem_enable_vs;
int g_iChem_buff;

//helping hand, bonus buffer and time multiplier
//versus, non-versus
ConVar g_hHelpHand_enable;
ConVar g_hHelpHand_enable_sur;
ConVar g_hHelpHand_enable_vs;
ConVar g_hHelpHand_convar;
ConVar g_hHelpHand_timemult;
ConVar g_hHelpHand_buff;
ConVar g_hHelpHand_buff_vs;
//associated vars
bool g_bHelpHand_enable;
bool g_bHelpHand_enable_sur;
bool g_bHelpHand_enable_vs;
bool g_bHelpHand_convar;
float g_flHelpHand_timemult;
int g_iHelpHand_buff;
int g_iHelpHand_buff_vs;

//pack rat, bonus ammo multiplier
//one-size-fits-all
ConVar g_hPack_enable;
ConVar g_hPack_enable_sur;
ConVar g_hPack_enable_vs;
ConVar g_hPack_ammomult;
//associated var
bool g_bPack_enable;
bool g_bPack_enable_sur;
bool g_bPack_enable_vs;
float g_flPack_ammomult;

//hard to kill, hp multiplier
//one-size-fits-all
ConVar g_hHard_enable;
ConVar g_hHard_enable_sur;
ConVar g_hHard_enable_vs;
ConVar g_hHard_hpmult;
//associated var
bool g_bHard_enable;
bool g_bHard_enable_sur;
bool g_bHard_enable_vs;
float g_flHard_hpmult;

//martial artist, movement rate
//campaign, non-campaign
ConVar g_hMA_enable;
ConVar g_hMA_enable_sur;
ConVar g_hMA_enable_vs;
ConVar g_hMA_maxpenalty;
//associated var
bool g_bMA_enable;
bool g_bMA_enable_sur;
bool g_bMA_enable_vs;
int g_iMA_maxpenalty;

//extreme conditioning, movement rate
//campaign, non-campaign
ConVar g_hExtreme_enable;
ConVar g_hExtreme_enable_sur;
ConVar g_hExtreme_enable_vs;
ConVar g_hExtreme_rate;
//associated var
bool g_bExtreme_enable;
bool g_bExtreme_enable_sur;
bool g_bExtreme_enable_vs;
float g_flExtreme_rate;

//little leaguer
ConVar g_hLittle_enable;
ConVar g_hLittle_enable_sur;
ConVar g_hLittle_enable_vs;
//associated var
bool g_bLittle_enable;
bool g_bLittle_enable_sur;
bool g_bLittle_enable_vs;


//INF1 (BOOMER) PERKS
//blind luck, cooldown multiplier
//one-size-fits-all
ConVar g_hBlind_enable;
ConVar g_hBlind_cdmult;
//associated var
bool g_bBlind_enable;
float g_flBlind_cdmult;

//dead wreckening, damage multiplier
//one-size-fits-all
ConVar g_hDead_enable;
ConVar g_hDead_dmgmult;
//associated var
bool g_bDead_enable;
float g_flDead_dmgmult;

//barf bagged
ConVar g_hBarf_enable;
bool g_bBarf_enable;

//motion sickness
//one-size-fits-all
ConVar g_hMotion_rate;
ConVar g_hMotion_enable;
//associated vars
float g_flMotion_rate;
bool g_bMotion_enable;


//INF3 (SMOKER) PERKS
//tongue twister, multipliers for tongue speed, pull speed, range
//one-size-fits-all
ConVar g_hTongue_enable;
ConVar g_hTongue_speedmult;
ConVar g_hTongue_pullmult;
ConVar g_hTongue_rangemult;
//associated vars
bool g_bTongue_enable;
float g_flTongue_speedmult;
float g_flTongue_pullmult;
float g_flTongue_rangemult;

//squeezer, bonus damage
//normal, hard, expert
//*used by bots in all modes
ConVar g_hSqueezer_enable;
ConVar g_hSqueezer_dmgmult;
//associated var
bool g_bSqueezer_enable;
float g_flSqueezer_dmgmult;

//drag and drop, cooldown mult;
//one-size-fits-all
ConVar g_hDrag_enable;
ConVar g_hDrag_cdmult;
//associated var
bool g_bDrag_enable;
float g_flDrag_cdmult;

//smoke it
ConVar g_hSmokeItSpeed;
ConVar g_hSmokeItMaxRange;
ConVar g_hSmokeIt_enable;
Handle g_hSmokeItTimer[MAXPLAYERS+1] = {INVALID_HANDLE};
//associated vars
float g_flSmokeItSpeed;
bool g_bSmokeItGrabbed[MAXPLAYERS+1] = {false};
int g_iSmokeItMaxRange;
bool g_bSmokeIt_enable;



//INF4 (HUNTER) PERKS
//body slam, minbound
//one-size-fits-all
ConVar g_hBody_enable;
ConVar g_hBody_minbound;
//associated var
bool g_bBody_enable;
int g_iBody_minbound;

//efficient killer, bonus damage
//normal, hard, expert
//*used by bots in all modes
ConVar g_hEfficient_enable;
ConVar g_hEfficient_dmgmult;
//associated var
bool g_bEfficient_enable;
float g_flEfficient_dmgmult;

//grasshopper, speed multiplier
//one-size-fits-all
ConVar g_hGrass_enable;
ConVar g_hGrass_rate;
//associated var
bool g_bGrass_enable;
float g_flGrass_rate;

//speed demon, speed multiplier
//one-size-fits-all
ConVar g_hSpeedDemon_enable;
ConVar g_hSpeedDemon_rate;
ConVar g_hSpeedDemon_dmgmult;
//associated var
bool g_bSpeedDemon_enable;
float g_flSpeedDemon_rate;
float g_flSpeedDemon_dmgmult;


//INF2 (TANK) PERKS
//adrenal glands, multipliers for punch cooldown,
//throw rock cooldown, and rock travel speed
//one-size-fits-all
ConVar g_hAdrenal_enable;
ConVar g_hAdrenal_punchcdmult;
ConVar g_hAdrenal_throwcdmult;
//associated vars
bool g_bAdrenal_enable;
float g_flAdrenal_punchcdmult;
float g_flAdrenal_throwcdmult;

//juggernaut, bonus health
//one-size-fits-all
ConVar g_hJuggernaut_enable;
ConVar g_hJuggernaut_hp;
//associated var
bool g_bJuggernaut_enable;
int g_iJuggernaut_hp;

//metabolic boost, speed multiplier
//one-size-fits-all
ConVar g_hMetabolic_enable;
ConVar g_hMetabolic_speedmult;
//associated var
bool g_bMetabolic_enable;
float g_flMetabolic_speedmult;

//storm caller, mobs spawned
//one-size-fits-all
ConVar g_hStorm_enable;
ConVar g_hStorm_mobcount;
//associated var
bool g_bStorm_enable;
int g_iStorm_mobcount;

//double the trouble, health multiplier
//one-size-fits-all
ConVar g_hDouble_enable;
ConVar g_hDouble_hpmult;
//associated var
bool g_bDouble_enable;
float g_flDouble_hpmult;


//INF5 (JOCKEY) PERKS
//ride like the wind, runspeed multiplier
//one-size-fits-all
ConVar g_hWind_enable;
ConVar g_hWind_rate;
//associated var
bool g_bWind_enable;
float g_flWind_rate;

//cavalier, hp multiplier
ConVar g_hCavalier_enable;
ConVar g_hCavalier_hpmult;
//associated vars
bool g_bCavalier_enable;
float g_flCavalier_hpmult;

//frogger, dmg multiplier, leap multiplier
ConVar g_hFrogger_enable;
ConVar g_hFrogger_dmgmult;
ConVar g_hFrogger_rate;
//associated vars
bool g_bFrogger_enable;
float g_flFrogger_dmgmult;
float g_flFrogger_rate;

//ghost rider, invis amount
ConVar g_hGhost_enable;
ConVar g_hGhost_alpha;
//associated vars
bool g_bGhost_enable;
int g_iGhost_alpha;


//INF6 (SPITTER) PERKS
//twin spitfire, time delay between two shots
//one-size-fits-all
ConVar g_hTwinSF_enable;
ConVar g_hTwinSF_delay;
//associated var
bool g_bTwinSF_enable;
float g_flTwinSF_delay;

//mega adhesive, slow multiplier
//one-size-fits-all
ConVar g_hMegaAd_enable;
ConVar g_hMegaAd_slow;
//associated var
bool g_bMegaAd_enable;
float g_flMegaAd_slow;

//INF7 (CHARGER) PERKS
//scattering ram, charge force multiplier and maximum cooldown
//one-size-fits-all
ConVar g_hScatter_enable;
ConVar g_hScatter_force;
ConVar g_hScatter_hpmult;
//associated var
bool g_bScatter_enable;
float g_flScatter_force;
float g_flScatter_hpmult;

//speeding bullet, charge moverate
ConVar g_hBullet_enable;
ConVar g_hBullet_rate;
//associated vars
bool g_bBullet_enable;
float g_flBullet_rate;

//BOT CONTROLLER VARS
//these track the server's preference
//for what perks bots should use

//survivor
ConVar g_hBot_Sur1;
ConVar g_hBot_Sur2;
ConVar g_hBot_Sur3;

ConVar g_hBot_Inf1;
ConVar g_hBot_Inf2;
ConVar g_hBot_Inf3;
ConVar g_hBot_Inf4;
ConVar g_hBot_Inf5;
ConVar g_hBot_Inf6;
ConVar g_hBot_Inf7;

//DEFAULT PERKS
//These vars track the server's
//given default perks, to account
//for disabling perks

//sur1
ConVar g_hSur1_default;
int g_iSur1_default;
//sur2
ConVar g_hSur2_default;
int g_iSur2_default;
//sur3
ConVar g_hSur3_default;
int g_iSur3_default;

//inf1/boomer
ConVar g_hInf1_default;
int g_iInf1_default;
//inf3/smoker
ConVar g_hInf3_default;
int g_iInf3_default;
//inf4/hunter
ConVar g_hInf4_default;
int g_iInf4_default;
//inf2/tank
ConVar g_hInf2_default;
int g_iInf2_default;
//inf5/jockey
ConVar g_hInf5_default;
int g_iInf5_default;
//inf6/spitter
ConVar g_hInf6_default;
int g_iInf6_default;
//inf7/charger
ConVar g_hInf7_default;
int g_iInf7_default;

//FORCE RANDOM PERKS
//tracks server setting for
//whether to force random perks

ConVar g_hForceRandom;
bool g_bForceRandom;

//ENABLE RANDOM PERKS BY PLAYER CHOICE
//tracks whether player can
//randomize their perks

ConVar g_hRandomEnable;
int g_bRandomEnable;

//PERK TREES AVAILABILITY
//option for servers to completely
//disable entire perk trees

ConVar g_hSur1_enable;
ConVar g_hSur2_enable;
ConVar g_hSur3_enable;
ConVar g_hInf1_enable;
ConVar g_hInf2_enable;
ConVar g_hInf3_enable;
ConVar g_hInf4_enable;
ConVar g_hInf5_enable;
ConVar g_hInf6_enable;
ConVar g_hInf7_enable;
bool g_bSur1_enable;
bool g_bSur2_enable;
bool g_bSur3_enable;
bool g_bInf1_enable;
bool g_bInf2_enable;
bool g_bInf3_enable;
bool g_bInf4_enable;
bool g_bInf5_enable;
bool g_bInf6_enable;
bool g_bInf7_enable;

//PERK HIERARCHY AVAILABILITY
//option for servers to completely
//disable perks for infected or survivors
ConVar g_hSurAll_enable;
ConVar g_hInfAll_enable;
bool g_bSurAll_enable;
bool g_bInfAll_enable;

//this var keeps track of whether
//to enable DT and Stopping or not, so we don't
//have to do the checks every game frame, or
//every time someone gets hurt

bool g_bDT_meta_enable = true;
bool g_bStopping_meta_enable = true;
bool g_bMA_meta_enable = true;

//controls whether menu automatically shows
ConVar g_hMenuAutoShow_enable;

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
	//RegConsoleCmd("say", MenuOpen_OnSay);
	//RegConsoleCmd("say_team", MenuOpen_OnSay);
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
	//g_iClipO			=	FindSendPropInfo("CTerrorGun","m_iClip1");
	
	g_iNextActO			=	FindSendPropInfo("CBaseAbility","m_nextActivationTimer");
	LogMessage("Retrieved g_iNextActO = %i", g_iNextActO);
	g_iAttackTimerO		=	FindSendPropInfo("CClaw","m_attackTimer");
	LogMessage("Retrieved g_iAttackTimerO = %i", g_iAttackTimerO);

	//CREATE AND INITIALIZE CONVARS
	//everything related to the convars that adjust
	//certain values for the perks
	CreateConvars();

	//finally, run a command to exec the .cfg file
	//to load the server's preferences for these cvars
	AutoExecConfig(true , "perkmod");

	//and load translations
	LoadTranslations("plugin.perkmod");
}

//just to give me a bit less of a headache,
//all convar creation is called here
void CreateConvars()
{
	//SURVIVOR
	//stopping power
	g_hStopping_dmgmult = CreateConVar(
		"l4d_perkmod_stoppingpower_damagemultiplier" ,
		"0.2" ,
		"Stopping Power perk: Bonus damage multiplier, ADDED to base damage (clamped between 0.05 < 1.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hStopping_dmgmult.AddChangeHook(Convar_Stopping);
	g_flStopping_dmgmult = 0.2;

	g_hStopping_enable = CreateConVar(
		"l4d_perkmod_stoppingpower_enable" ,
		"1" ,
		"Stopping Power perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hStopping_enable.AddChangeHook(Convar_Stopping_en);
	g_bStopping_enable = true;

	g_hStopping_enable_sur = CreateConVar(
		"l4d_perkmod_stoppingpower_enable_survival" ,
		"1" ,
		"Stopping Power perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hStopping_enable_sur.AddChangeHook(Convar_Stopping_en_sur);
	g_bStopping_enable_sur = true;

	g_hStopping_enable_vs = CreateConVar(
		"l4d_perkmod_stoppingpower_enable_versus" ,
		"1" ,
		"Stopping Power perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hStopping_enable_vs.AddChangeHook(Convar_Stopping_en_vs);
	g_bStopping_enable_vs = true;

	//pyrotechnician
	g_hPyro_maxticks = CreateConVar(
		"l4d_perkmod_pyrotechnician_maxticks" ,
		"60" ,
		"Pyrotechnician perk: The number of ticks (a tick is 2s) before giving a survivor a pipe bomb, ie. 60 ticks = 120 seconds. Clamped between 0 < 300, where 0 disables this feature." ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hPyro_maxticks.AddChangeHook(Convar_Pyro);
	g_iPyro_maxticks = 60;

	g_hPyro_enable = CreateConVar(
		"l4d_perkmod_pyrotechnician_enable" ,
		"1" ,
		"Pyrotechnician perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hPyro_enable.AddChangeHook(Convar_Pyro_en);
	g_bPyro_enable = true;

	g_hPyro_enable_sur = CreateConVar(
		"l4d_perkmod_pyrotechnician_enable_survival" ,
		"1" ,
		"Pyrotechnician perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hPyro_enable_sur.AddChangeHook(Convar_Pyro_en_sur);
	g_bPyro_enable_sur = true;

	g_hPyro_enable_vs = CreateConVar(
		"l4d_perkmod_pyrotechnician_enable_versus" ,
		"1" ,
		"Pyrotechnician perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hPyro_enable_vs.AddChangeHook(Convar_Pyro_en_vs);
	g_bPyro_enable_vs = true;

	//spirit
	g_hSpirit_buff = CreateConVar(
		"l4d_perkmod_spirit_bonusbuffer" ,
		"10" ,
		"Spirit perk: Bonus health buffer on self-revive (clamped between 0 < 170)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSpirit_buff.AddChangeHook(Convar_SpiritBuff);
	g_iSpirit_buff=				30;

	g_hSpirit_cd = CreateConVar(
		"l4d_perkmod_spirit_cooldown" ,
		"60" ,
		"Spirit perk: Cooldown for self-reviving in seconds, campaign (clamped between 1 < 1800)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSpirit_cd.AddChangeHook(Convar_SpiritCD);
	g_iSpirit_cd=				60;

	g_hSpirit_cd_sur = CreateConVar(
		"l4d_perkmod_spirit_cooldown_sur" ,
		"60" ,
		"Spirit perk: Cooldown for self-reviving in seconds, survival (clamped between 1 < 1800)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSpirit_cd_sur.AddChangeHook(Convar_SpiritCDsur);
	g_iSpirit_cd_sur=			60;

	g_hSpirit_cd_vs = CreateConVar(
		"l4d_perkmod_spirit_cooldown_vs" ,
		"60" ,
		"Spirit perk: Cooldown for self-reviving in seconds, versus (clamped between 1 < 1800)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSpirit_cd_vs.AddChangeHook(Convar_SpiritCDvs);
	g_iSpirit_cd_vs = 60;

	g_hSpirit_enable = CreateConVar(
		"l4d_perkmod_spirit_enable" ,
		"1" ,
		"Spirit perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSpirit_enable.AddChangeHook(Convar_Spirit_en);
	g_bSpirit_enable = true;

	g_hSpirit_enable_sur = CreateConVar(
		"l4d_perkmod_spirit_enable_survival" ,
		"1" ,
		"Spirit perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSpirit_enable_sur.AddChangeHook(Convar_Spirit_en_sur);
	g_bSpirit_enable_sur = true;

	g_hSpirit_enable_vs = CreateConVar(
		"l4d_perkmod_spirit_enable_versus" ,
		"1" ,
		"Spirit perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSpirit_enable_vs.AddChangeHook(Convar_Spirit_en_vs);
	g_bSpirit_enable_vs = true;

	//double tap
	g_hDT_rate = CreateConVar(
		"l4d_perkmod_doubletap_rate" ,
		"0.6667" ,
		"Double Tap perk: The interval between bullets fired is multiplied by this value. NOTE: a short enough interval will make the gun fire at only normal speed! (clamped between 0.2 < 0.9)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hDT_rate.AddChangeHook(Convar_DT);
	g_flDT_rate = 0.6667;

	g_hDT_rate_reload = CreateConVar(
		"l4d_perkmod_doubletap_rate_reload" ,
		"1.0" ,
		"Double Tap perk: The interval incurred by reloading is multiplied by this value (clamped between 0.2 < 1.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hDT_rate_reload.AddChangeHook(Convar_DT_rate_reload);
	g_flDT_rate_reload = 0.8;

	g_hDT_enable = CreateConVar(
		"l4d_perkmod_doubletap_enable" ,
		"1" ,
		"Double Tap perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hDT_enable.AddChangeHook(Convar_DT_en);
	g_bDT_enable = true;

	g_hDT_enable_sur = CreateConVar(
		"l4d_perkmod_doubletap_enable_survival" ,
		"1" ,
		"Double Tap perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hDT_enable_sur.AddChangeHook(Convar_DT_en_sur);
	g_bDT_enable_sur = true;

	g_hDT_enable_vs = CreateConVar(
		"l4d_perkmod_doubletap_enable_versus" ,
		"1" ,
		"Double Tap perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hDT_enable_vs.AddChangeHook(Convar_DT_en_vs);
	g_bDT_enable_vs = true;

	//sleight of hand
	g_hSoH_rate = CreateConVar(
		"l4d_perkmod_sleightofhand_rate" ,
		"0.5714" ,
		"Sleight of Hand perk: The interval incurred by reloading is multiplied by this value (clamped between 0.2 < 0.9)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSoH_rate.AddChangeHook(Convar_SoH);
	g_flSoH_rate=			0.5714;

	g_hSoH_enable = CreateConVar(
		"l4d_perkmod_sleightofhand_enable" ,
		"1" ,
		"Sleight of Hand perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSoH_enable.AddChangeHook(Convar_SoH_en);
	g_bSoH_enable = true;

	g_hSoH_enable_sur = CreateConVar(
		"l4d_perkmod_sleightofhand_enable_survival" ,
		"1" ,
		"Sleight of Hand perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSoH_enable_sur.AddChangeHook(Convar_SoH_en_sur);
	g_bSoH_enable_sur = true;

	g_hSoH_enable_vs = CreateConVar(
		"l4d_perkmod_sleightofhand_enable_versus" ,
		"1" ,
		"Sleight of Hand perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSoH_enable_vs.AddChangeHook(Convar_SoH_en_vs);
	g_bSoH_enable_vs = true;

	//unbreakable
	g_hUnbreak_hp = CreateConVar(
		"l4d_perkmod_unbreakable_bonushealth" ,
		"20" ,
		"Unbreakable perk: Bonus health given for Unbreakable; this value is also given as bonus health buffer on being revived (clamped between 1 < 100)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hUnbreak_hp.AddChangeHook(Convar_Unbreak);
	g_iUnbreak_hp = 20;

	g_hUnbreak_enable = CreateConVar(
		"l4d_perkmod_unbreakable_enable" ,
		"1" ,
		"Unbreakable perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hUnbreak_enable.AddChangeHook(Convar_Unbreak_en);
	g_bUnbreak_enable = true;

	g_hUnbreak_enable_sur = CreateConVar(
		"l4d_perkmod_unbreakable_enable_survival" ,
		"1" ,
		"Unbreakable perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hUnbreak_enable_sur.AddChangeHook(Convar_Unbreak_en_sur);
	g_bUnbreak_enable_sur = true;

	g_hUnbreak_enable_vs = CreateConVar(
		"l4d_perkmod_unbreakable_enable_versus" ,
		"1" ,
		"Unbreakable perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hUnbreak_enable_vs.AddChangeHook(Convar_Unbreak_en_vs);
	g_bUnbreak_enable_vs = true;

	//chem reliant
	g_hChem_buff = CreateConVar(
		"l4d_perkmod_chemreliant_bonusbuffer" ,
		"0" ,
		"Chem Reliant perk: Bonus health buffer given when taking pills (clamped between 0 < 150)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hChem_buff.AddChangeHook(Convar_Chem);
	g_iChem_buff = 0;

	g_hChem_enable = CreateConVar(
		"l4d_perkmod_chemreliant_enable" ,
		"1" ,
		"Chem Reliant perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hChem_enable.AddChangeHook(Convar_Chem_en);
	g_bChem_enable = true;

	g_hChem_enable_sur = CreateConVar(
		"l4d_perkmod_chemreliant_enable_survival" ,
		"1" ,
		"Chem Reliant perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hChem_enable_sur.AddChangeHook(Convar_Chem_en_sur);
	g_bChem_enable_sur = true;

	g_hChem_enable_vs = CreateConVar(
		"l4d_perkmod_chemreliant_enable_versus" ,
		"1" ,
		"Chem Reliant perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hChem_enable_vs.AddChangeHook(Convar_Chem_en_vs);
	g_bChem_enable_vs = true;

	//helping hand
	g_hHelpHand_timemult = CreateConVar(
		"l4d_perkmod_helpinghand_timemultiplier" ,
		"0.6" ,
		"Helping Hand perk: Time multiplier to revive others with Helping Hand (clamped between 0.01 < 1.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hHelpHand_timemult.AddChangeHook(Convar_HelpTime);
	g_flHelpHand_timemult = 0.6;

	g_hHelpHand_buff = CreateConVar(
		"l4d_perkmod_helpinghand_bonusbuffer" ,
		"15" ,
		"Helping Hand perk: Bonus health buffer given to allies after reviving them, campaign/survival (clamped between 0 < 170)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hHelpHand_buff.AddChangeHook(Convar_HelpBuff);
	g_iHelpHand_buff = 15;

	g_hHelpHand_buff_vs = CreateConVar(
		"l4d_perkmod_helpinghand_bonusbuffer_vs" ,
		"10" ,
		"Helping Hand perk: Bonus health buffer given to allies after reviving them, versus (clamped between 0 < 170)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hHelpHand_buff_vs.AddChangeHook(Convar_HelpBuffvs);
	g_iHelpHand_buff_vs = 10;

	g_hHelpHand_enable = CreateConVar(
		"l4d_perkmod_helpinghand_enable" ,
		"1" ,
		"Helping Hand perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled (NOTE: This perk normally adjusts the survivor_revive_duration ConVar; disabling this perk will stop the plugin from adjusting this ConVar)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hHelpHand_enable.AddChangeHook(Convar_Help_en);
	g_bHelpHand_enable = true;

	g_hHelpHand_enable_sur = CreateConVar(
		"l4d_perkmod_helpinghand_enable_survival" ,
		"1" ,
		"Helping Hand perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled (NOTE: This perk normally adjusts the survivor_revive_duration ConVar; disabling this perk will stop the plugin from adjusting this ConVar)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hHelpHand_enable_sur.AddChangeHook(Convar_Help_en_sur);
	g_bHelpHand_enable_sur = true;

	g_hHelpHand_enable_vs = CreateConVar(
		"l4d_perkmod_helpinghand_enable_versus" ,
		"1" ,
		"Helping Hand perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled (NOTE: This perk normally adjusts the survivor_revive_duration ConVar; disabling this perk will stop the plugin from adjusting this ConVar)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hHelpHand_enable_vs.AddChangeHook(Convar_Help_en_vs);
	g_bHelpHand_enable_vs = true;

	g_hHelpHand_convar = CreateConVar(
		"l4d_perkmod_helpinghand_enable_convarchanges" ,
		"1" ,
		"Helping Hand perk: This perk normally adjusts the survivor_revive_duration ConVar; setting this to 0 will stop the plugin from adjusting this ConVar" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hHelpHand_convar.AddChangeHook(Convar_Help_convar);
	g_bHelpHand_convar = true;

	//pack rat
	g_hPack_ammomult = CreateConVar(
		"l4d_perkmod_packrat_ammomultiplier" ,
		"0.2" ,
		"Pack Rat perk: Bonus ammo capacity, ADDED to base capacity (clamped between 0.01 < 1.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hPack_ammomult.AddChangeHook(Convar_Pack);
	g_flPack_ammomult = 0.2;

	g_hPack_enable = CreateConVar(
		"l4d_perkmod_packrat_enable" ,
		"1" ,
		"Pack Rat perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hPack_enable.AddChangeHook(Convar_Pack_en);
	g_bPack_enable = true;

	g_hPack_enable_sur = CreateConVar(
		"l4d_perkmod_packrat_enable_survival" ,
		"1" ,
		"Pack Rat perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hPack_enable_sur.AddChangeHook(Convar_Pack_en_sur);
	g_bPack_enable_sur = true;

	g_hPack_enable_vs = CreateConVar(
		"l4d_perkmod_packrat_enable_versus" ,
		"1" ,
		"Pack Rat perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hPack_enable_vs.AddChangeHook(Convar_Pack_en_vs);
	g_bPack_enable_vs = true;

	//hard to kill
	g_hHard_hpmult = CreateConVar(
		"l4d_perkmod_hardtokill_healthmultiplier" ,
		"0.5" ,
		"Hard to Kill perk: Bonus incap health multiplier, product is ADDED to base incap health (clamped between 0.01 < 3.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hHard_hpmult.AddChangeHook(Convar_Hard);
	g_flHard_hpmult = 0.5;

	g_hHard_enable = CreateConVar(
		"l4d_perkmod_hardtokill_enable" ,
		"1" ,
		"Hard to Kill perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hHard_enable.AddChangeHook(Convar_Hard_en);
	g_bHard_enable = true;

	g_hHard_enable_sur = CreateConVar(
		"l4d_perkmod_hardtokill_enable_survival" ,
		"1" ,
		"Hard to Kill perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hHard_enable_sur.AddChangeHook(Convar_Hard_en_sur);
	g_bHard_enable_sur = true;

	g_hHard_enable_vs = CreateConVar(
		"l4d_perkmod_hardtokill_enable_versus" ,
		"1" ,
		"Hard to Kill perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hHard_enable_vs.AddChangeHook(Convar_Hard_en_vs);
	g_bHard_enable_vs = true;

	//martial artist
	g_hMA_maxpenalty = CreateConVar(
		"l4d_perkmod_martialartist_maximumpenalty" ,
		"4" ,
		"Martial Artist perk: The maximum shove penalty applied to survivors. It's Valve's coding, so I don't know what each value exactly translates to, but 6 is the maximum shove penalty (~1.5s)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hMA_maxpenalty.AddChangeHook(Convar_MA_maxpenalty);
	g_iMA_maxpenalty = 6;

	g_hMA_enable = CreateConVar(
		"l4d_perkmod_martialartist_enable" ,
		"1" ,
		"Martial Artist perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hMA_enable.AddChangeHook(Convar_MA_en);
	g_bMA_enable = true;

	g_hMA_enable_sur = CreateConVar(
		"l4d_perkmod_martialartist_enable_survival" ,
		"1" ,
		"Martial Artist perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hMA_enable_sur.AddChangeHook(Convar_MA_en_sur);
	g_bMA_enable_sur = true;

	g_hMA_enable_vs = CreateConVar(
		"l4d_perkmod_martialartist_enable_versus" ,
		"1" ,
		"Martial Artist perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hMA_enable_vs.AddChangeHook(Convar_MA_en_vs);
	g_bMA_enable_vs = true;

	//extreme conditioning
	g_hExtreme_rate = CreateConVar(
		"l4d_perkmod_extremeconditioning_rate" ,
		"1.1" ,
		"Extreme Conditioning perk: Survivor movement is multiplied by this value (clamped between 1.0 < 1.5)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hExtreme_rate.AddChangeHook(Convar_Extreme);
	g_flExtreme_rate = 1.1;

	g_hExtreme_enable = CreateConVar(
		"l4d_perkmod_extremeconditioning_enable" ,
		"1" ,
		"Extreme Conditioning perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hExtreme_enable.AddChangeHook(Convar_Extreme_en);
	g_bExtreme_enable = true;

	g_hExtreme_enable_sur = CreateConVar(
		"l4d_perkmod_extremeconditioning_enable_survival" ,
		"1" ,
		"Extreme Conditioning perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hExtreme_enable_sur.AddChangeHook(Convar_Extreme_en_sur);
	g_bExtreme_enable_sur = true;

	g_hExtreme_enable_vs = CreateConVar(
		"l4d_perkmod_extremeconditioning_enable_versus" ,
		"1" ,
		"Extreme Conditioning perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hExtreme_enable_vs.AddChangeHook(Convar_Extreme_en_vs);
	g_bExtreme_enable_vs = true;

	//little leaguer
	g_hLittle_enable = CreateConVar(
		"l4d_perkmod_littleleaguer_enable" ,
		"1" ,
		"Little Leaguer perk: Allows the perk to be chosen by players in campaign, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hLittle_enable.AddChangeHook(Convar_Little_en);
	g_bLittle_enable = true;

	g_hLittle_enable_sur = CreateConVar(
		"l4d_perkmod_littleleaguer_enable_survival" ,
		"1" ,
		"Little Leaguer perk: Allows the perk to be chosen by players in survival, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hLittle_enable_sur.AddChangeHook(Convar_Little_en_sur);
	g_bLittle_enable_sur = true;

	g_hLittle_enable_vs = CreateConVar(
		"l4d_perkmod_littleleaguer_enable_versus" ,
		"1" ,
		"Little Leaguer perk: Allows the perk to be chosen by players in versus, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hLittle_enable_vs.AddChangeHook(Convar_Little_en_vs);
	g_bLittle_enable_vs = true;

	//BOOMER
	//barf bagged
	g_hBarf_enable = CreateConVar(
		"l4d_perkmod_barfbagged_enable" ,
		"1" ,
		"Barf Bagged perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hBarf_enable.AddChangeHook(Convar_Barf_en);
	g_bBarf_enable = true;

	//blind luck
	g_hBlind_cdmult = CreateConVar(
		"l4d_perkmod_blindluck_timemultiplier" ,
		"0.5" ,
		"Blind Luck perk: Cooldown (default 30s) is multiplied by this value (clamped between 0.01 < 1.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hBlind_cdmult.AddChangeHook(Convar_Blind);
	g_flBlind_cdmult = 0.5;

	g_hBlind_enable = CreateConVar(
		"l4d_perkmod_blindluck_enable" ,
		"1" ,
		"Blind Luck perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled (NOTE: This perk normally adjusts the z_vomit_interval ConVar; disabling this perk will stop the plugin from adjusting this ConVar)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hBlind_enable.AddChangeHook(Convar_Blind_en);
	g_bBlind_enable = true;

	//dead wreckening
	g_hDead_dmgmult = CreateConVar(
		"l4d_perkmod_deadwreckening_damagemultiplier" ,
		"0.5" ,
		"Dead Wreckening perk: Common infected damage is multiplied by this value and ADDED to their base damage (clamped between 0.01 < 4.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hDead_dmgmult.AddChangeHook(Convar_Dead);
	g_flDead_dmgmult = 0.5;

	g_hDead_enable = CreateConVar(
		"l4d_perkmod_deadwreckening_enable" ,
		"1" ,
		"Dead Wreckening perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hDead_enable.AddChangeHook(Convar_Dead_en);
	g_bDead_enable = true;

	//motion sickness
	g_hMotion_rate = CreateConVar(
		"l4d_perkmod_motionsickness_rate" ,
		"1.25" ,
		"Motion Sickness perk: Boomer movement is multiplied by this value (clamped between 1.0 < 4.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hMotion_rate.AddChangeHook(Convar_Motion);
	g_flMotion_rate = 1.25;

	g_hMotion_enable = CreateConVar(
		"l4d_perkmod_motionsickness_enable" ,
		"1" ,
		"Motion Sickness perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled (NOTE: This perk normally adjusts the z_vomit_fatigue ConVar; disabling this perk will stop the plugin from adjusting this ConVar)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hMotion_enable.AddChangeHook(Convar_Motion_en);
	g_bMotion_enable = true;

	//SMOKER
	//tongue twister
	g_hTongue_speedmult = CreateConVar(
		"l4d_perkmod_tonguetwister_speedmultiplier" ,
		"1.5" ,
		"Tongue Twister perk: Tongue travel speed before grabbing a survivor; multiplied by this value (clamped between 1.0 < 5.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hTongue_speedmult.AddChangeHook(Convar_TongueSpeed);
	g_flTongue_speedmult = 1.5;

	g_hTongue_pullmult = CreateConVar(
		"l4d_perkmod_tonguetwister_pullmultiplier" ,
		"1.5" ,
		"Tongue Twister perk: Tongue pull speed after grabbing a survivor; multiplied by this value (clamped between 1.0 < 5.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hTongue_pullmult.AddChangeHook(Convar_TonguePull);
	g_flTongue_pullmult = 1.5;

	g_hTongue_rangemult = CreateConVar(
		"l4d_perkmod_tonguetwister_rangemultiplier" ,
		"1.75" ,
		"Tongue Twister perk: Tongue range; multiplied by this value (clamped between 1.0 < 5.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hTongue_rangemult.AddChangeHook(Convar_TongueRange);
	g_flTongue_rangemult = 1.75;

	g_hTongue_enable = CreateConVar(
		"l4d_perkmod_tonguetwister_enable" ,
		"1" ,
		"Tongue Twister perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled (NOTE: This perk normally adjusts the tongue_range, tongue_victim_max_speed and tongue_fly_speed ConVars; disabling this perk will stop the plugin from adjusting these ConVars)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hTongue_enable.AddChangeHook(Convar_Tongue_en);
	g_bTongue_enable = true;

	//squeezer
	g_hSqueezer_dmgmult = CreateConVar(
		"l4d_perkmod_squeezer_damagemultiplier" ,
		"0.5" ,
		"Squeezer perk: All base damage is multiplied by this value and then ADDED to base damage (clamped between 0.01 < 4.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSqueezer_dmgmult.AddChangeHook(Convar_Squeezer);
	g_flSqueezer_dmgmult = 0.5;

	g_hSqueezer_enable = CreateConVar(
		"l4d_perkmod_squeezer_enable" ,
		"1" ,
		"Squeezer perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSqueezer_enable.AddChangeHook(Convar_Squeezer_en);
	g_bSqueezer_enable = true;

	//drag and drop
	g_hDrag_cdmult = CreateConVar(
		"l4d_perkmod_draganddrop_timemultiplier" ,
		"0.2" ,
		"Drag and Drop perk: Cooldown is multiplied by this value (clamped between 0.01 < 1.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hDrag_cdmult.AddChangeHook(Convar_Drag);
	g_flDrag_cdmult = 0.2;

	g_hDrag_enable = CreateConVar(
		"l4d_perkmod_draganddrop_enable" ,
		"1" ,
		"Drag and Drop perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled (NOTE: This perk normally adjusts the tongue_hit_delay and tongue_player_dropping_to_ground_time ConVars; disabling this perk will stop the plugin from adjusting these ConVars)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hDrag_enable.AddChangeHook(Convar_Drag_en);
	g_bDrag_enable = true;

	//smoke it
	g_hSmokeItSpeed = CreateConVar(
		"l4d_perkmod_smokeit_speed" ,
		"0.21" ,
		"Smoke IT! perk: Smoker's speed modifier" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_flSmokeItSpeed = 0.21;
	g_hSmokeItSpeed.AddChangeHook(Convar_SmokeIt_speed);

	g_hSmokeItMaxRange = CreateConVar(
		"l4d_perkmod_smokeit_tonguestretch" ,
		"950" ,
		"Smoke IT! perk: Smoker's max tongue stretch, tongue will be released if beyond this" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_iSmokeItMaxRange = 950;
	g_hSmokeItMaxRange.AddChangeHook(Convar_SmokeIt_range);

	g_hSmokeIt_enable = CreateConVar(
		"l4d_perkmod_smokeit_enable" ,
		"1" ,
		"Smoke IT! perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSmokeIt_enable.AddChangeHook(Convar_SmokeIt_en);
	g_bSmokeIt_enable = true;

	//HUNTER
	//body slam
	g_hBody_minbound = CreateConVar(
		"l4d_perkmod_bodyslam_minbound" ,
		"10" ,
		"Body Slam perk: Defines the minimum initial damage dealt by a pounce (clamped between 2 < 100)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hBody_minbound.AddChangeHook(Convar_Body);
	g_iBody_minbound = 10;

	g_hBody_enable = CreateConVar(
		"l4d_perkmod_bodyslam_enable" ,
		"1" ,
		"Body Slam perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hBody_enable.AddChangeHook(Convar_Body_en);
	g_bBody_enable = true;

	//efficient killer
	g_hEfficient_dmgmult = CreateConVar(
		"l4d_perkmod_efficientkiller_damagemultiplier" ,
		"0.2" ,
		"Efficient Killer perk: All base damage is multiplied by this value and then ADDED to base damage (clamped between 0.01 < 4.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hEfficient_dmgmult.AddChangeHook(Convar_Eff);
	g_flEfficient_dmgmult = 0.2;

	g_hEfficient_enable = CreateConVar(
		"l4d_perkmod_efficientkiller_enable" ,
		"1" ,
		"Efficient Killer perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hEfficient_enable.AddChangeHook(Convar_Eff_en);
	g_bEfficient_enable = true;

	//grasshopper
	g_hGrass_rate = CreateConVar(
		"l4d_perkmod_grasshopper_rate" ,
		"1.2" ,
		"Grasshopper perk: Multiplier for pounce speed (clamped between 1.0 < 3.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hGrass_rate.AddChangeHook(Convar_Grass);
	g_flGrass_rate = 1.2;

	g_hGrass_enable = CreateConVar(
		"l4d_perkmod_grasshopper_enable" ,
		"1" ,
		"Grasshopper perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hGrass_enable.AddChangeHook(Convar_Grass_en);
	g_bGrass_enable = true;

	//speed demon
	g_hSpeedDemon_rate = CreateConVar(
		"l4d_perkmod_speeddemon_rate" ,
		"1.4" ,
		"Speed Demon perk: Multiplier for time rate (clamped between 1.0 < 3.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSpeedDemon_rate.AddChangeHook(Convar_Demon);
	g_flSpeedDemon_rate = 1.4;

	g_hSpeedDemon_dmgmult = CreateConVar(
		"l4d_perkmod_speeddemon_damagemultiplier" ,
		"0.5" ,
		"Efficient Killer perk: All base damage is multiplied by this value and then ADDED to base damage (clamped between 0.01 < 4.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSpeedDemon_dmgmult.AddChangeHook(Convar_Demon_dmg);
	g_flSpeedDemon_dmgmult = 0.5;

	g_hSpeedDemon_enable = CreateConVar(
		"l4d_perkmod_speeddemon_enable" ,
		"1" ,
		"Speed Demon perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSpeedDemon_enable.AddChangeHook(Convar_Demon_en);
	g_bSpeedDemon_enable = true;

	//TANK
	//adrenal glands
	g_hAdrenal_punchcdmult = CreateConVar(
		"l4d_perkmod_adrenalglands_punchcooldownmultiplier" ,
		"0.5" ,
		"Adrenal Glands perk: Cooldown for punching is multiplied by this value (clamped between 0.01 < 1.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hAdrenal_punchcdmult.AddChangeHook(Convar_Adrenalpunchcd);
	g_flAdrenal_punchcdmult = 0.5;

	g_hAdrenal_throwcdmult = CreateConVar(
		"l4d_perkmod_adrenalglands_throwcooldownmultiplier" ,
		"0.4" ,
		"Adrenal Glands perk: Cooldown for throwing rocks is multiplied by this value (clamped between 0.01 < 1.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hAdrenal_throwcdmult.AddChangeHook(Convar_Adrenalthrowcd);
	g_flAdrenal_throwcdmult = 0.4;

	g_hAdrenal_enable = CreateConVar(
		"l4d_perkmod_adrenalglands_enable" ,
		"1" ,
		"Adrenal Glands perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled (NOTE: This perk normally adjusts the tank_swing_interval, tank_swing_miss_interval, z_tank_attack_interval, z_tank_throw_interval, and z_tank_throw_force ConVars; disabling this perk will stop the plugin from adjusting these ConVars)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hAdrenal_enable.AddChangeHook(Convar_Adrenal_en);
	g_bAdrenal_enable = true;

	//juggernaut
	g_hJuggernaut_hp = CreateConVar(
		"l4d_perkmod_juggernaut_health" ,
		"3000" ,
		"Juggernaut perk: Bonus health given to tanks; absolute value (clamped between 1 < 99999)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hJuggernaut_hp.AddChangeHook(Convar_Jugg);
	g_iJuggernaut_hp = 3000;

	g_hJuggernaut_enable = CreateConVar(
		"l4d_perkmod_juggernaut_enable" ,
		"1" ,
		"Juggernaut perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hJuggernaut_enable.AddChangeHook(Convar_Jugg_en);
	g_bJuggernaut_enable = true;

	//metabolic boost
	g_hMetabolic_speedmult = CreateConVar(
		"l4d_perkmod_metabolicboost_speedmultiplier" ,
		"1.4" ,
		"Metabolic Boost perk: Run speed multiplier (clamped between 1.01 < 3.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hMetabolic_speedmult.AddChangeHook(Convar_Met);
	g_flMetabolic_speedmult = 1.4;

	g_hMetabolic_enable = CreateConVar(
		"l4d_perkmod_metabolicboost_enable" ,
		"1" ,
		"Metabolic Boost perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hMetabolic_enable.AddChangeHook(Convar_Met_en);
	g_bMetabolic_enable = true;

	//storm caller
	g_hStorm_mobcount = CreateConVar(
		"l4d_perkmod_stormcaller_mobcount" ,
		"3" ,
		"Storm Caller perk: How many groups of zombies are spawned (clamped between 1 < 10)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hStorm_mobcount.AddChangeHook(Convar_Storm);
	g_iStorm_mobcount = 3;

	g_hStorm_enable = CreateConVar(
		"l4d_perkmod_stormcaller_enable" ,
		"1" ,
		"Storm Caller perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hStorm_enable.AddChangeHook(Convar_Storm_en);
	g_bStorm_enable = true;

	//double the trouble
	g_hDouble_hpmult = CreateConVar(
		"l4d_perkmod_doublethetrouble_healthmultiplier" ,
		"0.35" ,
		"Double the Trouble: Health multiplier for all tanks spawned under the perk (clamped between 0.1 < 2.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hDouble_hpmult.AddChangeHook(Convar_Double);
	g_flDouble_hpmult = 0.35;

	g_hDouble_enable = CreateConVar(
		"l4d_perkmod_doublethetrouble_enable" ,
		"1" ,
		"Double the Trouble perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hDouble_enable.AddChangeHook(Convar_Double_en);
	g_bDouble_enable = true;

	//JOCKEY
	//ride like the wind
	g_hWind_rate = CreateConVar(
		"l4d_perkmod_ridelikethewind_rate" ,
		"1.4" ,
		"Ride Like the Wind perk: Multiplier for run speed rate (clamped between 1.0 < 3.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hWind_rate.AddChangeHook(Convar_Wind);
	g_flWind_rate = 1.4;

	g_hWind_enable = CreateConVar(
		"l4d_perkmod_ridelikethewind_enable" ,
		"1" ,
		"Ride Like the Wind perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hWind_enable.AddChangeHook(Convar_Wind_en);
	g_bWind_enable = true;

	//cavalier
	g_hCavalier_hpmult = CreateConVar(
		"l4d_perkmod_cavalier_healthmultiplier" ,
		"0.6" ,
		"Cavalier: Bonus health multiplier, product is ADDED to base health (clamped between 0.01 < 3.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hCavalier_hpmult.AddChangeHook(Convar_Cavalier);
	g_flCavalier_hpmult = 0.6;

	g_hCavalier_enable = CreateConVar(
		"l4d_perkmod_cavalier_enable" ,
		"1" ,
		"Cavalier perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hCavalier_enable.AddChangeHook(Convar_Cavalier_en);
	g_bCavalier_enable = true;

	//frogger
	g_hFrogger_dmgmult = CreateConVar(
		"l4d_perkmod_frogger_damagemultiplier" ,
		"0.35" ,
		"Frogger perk: All base damage is multiplied by this value and then ADDED to base damage (clamped between 0.01 < 4.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hFrogger_dmgmult.AddChangeHook(Convar_Frogger_dmgmult);
	g_flFrogger_dmgmult = 0.35;

	g_hFrogger_rate = CreateConVar(
		"l4d_perkmod_frogger_rate" ,
		"1.3" ,
		"Frogger perk: Multiplier for leap speed (clamped between 1.0 < 3.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hFrogger_rate.AddChangeHook(Convar_Frogger_rate);
	g_flFrogger_rate = 1.3;

	g_hFrogger_enable = CreateConVar(
		"l4d_perkmod_frogger_enable" ,
		"1" ,
		"Frogger perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hFrogger_enable.AddChangeHook(Convar_Frogger_en);
	g_bFrogger_enable = true;

	//ghost rider
	g_hGhost_alpha = CreateConVar(
		"l4d_perkmod_ghostrider_alpha" ,
		"25" ,
		"Ghost Rider perk: Sets the alpha level (clamped between 0 total invis < 255 opaque)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hGhost_alpha.AddChangeHook(Convar_Ghost);
	g_iGhost_alpha = 25;

	g_hGhost_enable = CreateConVar(
		"l4d_perkmod_ghostrider_enable" ,
		"1" ,
		"Ghost Rider perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hGhost_enable.AddChangeHook(Convar_Ghost_en);
	g_bGhost_enable = true;

	//SPITTER
	//twin spitfire
	g_hTwinSF_delay = CreateConVar(
		"l4d_perkmod_twinspitfire_delay" ,
		"6" ,
		"Twin Spitfire perk: Delay in-between double shots, in seconds (clamped between 0.5 < 20.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hTwinSF_delay.AddChangeHook(Convar_TwinSF);
	g_flTwinSF_delay = 6.0;

	g_hTwinSF_enable = CreateConVar(
		"l4d_perkmod_twinspitfire_enable" ,
		"1" ,
		"Twin Spitfire perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hTwinSF_enable.AddChangeHook(Convar_TwinSF_en);
	g_bTwinSF_enable = true;

	//mega adhesive
	g_hMegaAd_enable = CreateConVar(
		"l4d_perkmod_megaadhesive_enable" ,
		"1" ,
		"Mega Adhesive perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hMegaAd_enable.AddChangeHook(Convar_MegaAd_en);
	g_bMegaAd_enable = true;

	g_hMegaAd_slow = CreateConVar(
		"l4d_perkmod_megaadhesive_slowmultiplier" ,
		"0.6" ,
		"Mega Adhesive perk: Survivor run speed is MULTIPLIED DIRECTLY by this value - 0.6 means they run at 60% speed (clamped between 0 < 1.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hMegaAd_slow.AddChangeHook(Convar_MegaAd);
	g_flMegaAd_slow = 0.6;

	//CHARGER
	//scattering ram
	g_hScatter_force = CreateConVar(
		"l4d_perkmod_scatteringram_force" ,
		"1.6" ,
		"Scattering Ram perk: Direct multiplier to force applied to survivors on charge impact (clamped between 1.0 < 3.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hScatter_force.AddChangeHook(Convar_Scatter_force);
	g_flScatter_force = 1.6;

	g_hScatter_hpmult = CreateConVar(
		"l4d_perkmod_scatteringram_healthmultiplier" ,
		"0.3" ,
		"Scattering Ram perk: Bonus health multiplier, product is ADDED to base health (clamped between 0.01 < 3.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hScatter_hpmult.AddChangeHook(Convar_Scatter_hpmult);
	g_flScatter_hpmult = 0.3;

	g_hScatter_enable = CreateConVar(
		"l4d_perkmod_scatteringram_enable" ,
		"1" ,
		"Scattering Ram perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hScatter_enable.AddChangeHook(Convar_Scatter_en);
	g_bScatter_enable = true;

	//speeding bullet
	g_hBullet_rate = CreateConVar(
		"l4d_perkmod_speedingbullet_rate" ,
		"1.5" ,
		"Speeding Bullet perk: Time rate while charging (clamped between 1.0 < 10.0)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hBullet_rate.AddChangeHook(Convar_Bullet);
	g_flBullet_rate = 1.5;

	g_hBullet_enable = CreateConVar(
		"l4d_perkmod_speedingbullet_enable" ,
		"1" ,
		"Speeding Bullet perk: Allows the perk to be chosen by players, 0=disabled, 1=enabled" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hBullet_enable.AddChangeHook(Convar_Bullet_en);
	g_bBullet_enable = true;

	//MISC
	//bot preferences for perks
	g_hBot_Sur1 = CreateConVar(
		"l4d_perkmod_bot_survivor1" ,
		"1, 2, 3, 4" ,
		"Bot preferences for Survivor 1 perks: 1 = stopping power, 2 = double tap, 3 = sleight of hand, 4 = pyrotechnician" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);

	g_hBot_Sur2 = CreateConVar(
		"l4d_perkmod_bot_survivor2" ,
		"1, 2, 3, 4" ,
		"Bot preferences for Survivor 2 perks: 1 = unbreakable, 2 = spirit, 3 = helping hand, 4 = martial artist" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);

	g_hBot_Sur3 = CreateConVar(
		"l4d_perkmod_bot_survivor3" ,
		"1, 2" ,
		"Bot preferences for Survivor 2 perks: 1 = pack rat, 2 = chem reliant, 3 = hard to kill, 4 = extreme conditioning" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);

	g_hBot_Inf1 = CreateConVar(
		"l4d_perkmod_bot_boomer" ,
		"1, 2, 3" ,
		"Bot preferences for boomer perks: 1 = barf bagged, 2 = blind luck, 3 = dead wreckening, 4 = motion sickness (NOTE: You can select more than one using the format '1, 3, 4', and the game will randomize between your choices)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);

	g_hBot_Inf3 = CreateConVar(
		"l4d_perkmod_bot_smoker" ,
		"2, 3" ,
		"Bot preferences for smoker perks: 1 = tongue twister, 2 = squeezer, 3 = drag and drop (NOTE: You can select more than one using the format '1, 3, 4', and the game will randomize between your choices)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);

	g_hBot_Inf4 = CreateConVar(
		"l4d_perkmod_bot_hunter" ,
		"2" ,
		"Bot preferences for hunter perks: 1 = body slam, 2 = efficient killer, 3 = grasshopper, 4 = speed demon (NOTE: You can select more than one using the format '1, 3, 4', and the game will randomize between your choices)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);

	g_hBot_Inf2 = CreateConVar(
		"l4d_perkmod_bot_tank" ,
		"1, 2, 3, 4, 5" ,
		"Bot preferences for tank perks: 1 = adrenal glands, 2 = juggernaut, 3 = metabolic boost, 4 = storm caller, 5 = double the trouble (NOTE: You can select more than one using the format '1, 3, 4', and the game will randomize between your choices)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);

	g_hBot_Inf5 = CreateConVar(
		"l4d_perkmod_bot_jockey" ,
		"1, 2, 3, 4" ,
		"Bot preferences for jockey perks: 1 = ride like the wind, 2 = cavalier, 3 = frogger, 4 = ghost rider (NOTE: You can select more than one using the format '1, 3, 4', and the game will randomize between your choices)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);

	g_hBot_Inf6 = CreateConVar(
		"l4d_perkmod_bot_spitter" ,
		"1, 2" ,
		"Bot preferences for spitter perks: 1 = twin spitfire, 2 = mega adhesive (NOTE: You can select more than one using the format '1, 3, 4', and the game will randomize between your choices)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);

	g_hBot_Inf7 = CreateConVar(
		"l4d_perkmod_bot_charger" ,
		"1, 2" ,
		"Bot preferences for charger perks: 1 = scattering ram, 2 = speeding bullet (NOTE: You can select more than one using the format '1, 3, 4', and the game will randomize between your choices)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);

	//default perks
	g_hSur1_default = CreateConVar(
		"l4d_perkmod_default_survivor1" ,
		"1" ,
		"Default selected perk for Survivor, Primary: 1 = stopping power, 2 = double tap, 3 = sleight of hand, 4 = pyrotechnician" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSur1_default.AddChangeHook(Convar_Def_Sur1);
	g_iSur1_default = 1;

	g_hSur2_default = CreateConVar(
		"l4d_perkmod_default_survivor2" ,
		"1" ,
		"Default selected perk for Survivor, Secondary: 1 = unbreakable, 2 = spirit, 3 = helping hand, 4 = martial artist" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSur2_default.AddChangeHook(Convar_Def_Sur2);
	g_iSur2_default = 1;

	g_hSur3_default = CreateConVar(
		"l4d_perkmod_default_survivor3" ,
		"1" ,
		"Default selected perk for Survivor, Secondary: 1 = pack rat, 2 = chem reliant, 3 = hard to kill" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSur3_default.AddChangeHook(Convar_Def_Sur3);
	g_iSur3_default = 1;

	g_hInf1_default = CreateConVar(
		"l4d_perkmod_default_boomer" ,
		"1" ,
		"Default selected perk for Boomer: 1 = barf bagged, 2 = blind luck, 3 = dead wreckening" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hInf1_default.AddChangeHook(Convar_Def_Inf1);
	g_iInf1_default = 1;

	g_hInf2_default = CreateConVar(
		"l4d_perkmod_default_tank" ,
		"2" ,
		"Default selected perk for Tank: 1 = adrenal glands, 2 = juggernaut, 3 = metabolic boost, 4 = storm caller, 5 = double the trouble" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hInf2_default.AddChangeHook(Convar_Def_Inf2);
	g_iInf2_default = 2;

	g_hInf3_default = CreateConVar(
		"l4d_perkmod_default_smoker" ,
		"1" ,
		"Default selected perk for Smoker: 1 = tongue twister, 2 = squeezer, 3 = drag and drop" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hInf3_default.AddChangeHook(Convar_Def_Inf3);
	g_iInf3_default = 1;

	g_hInf4_default = CreateConVar(
		"l4d_perkmod_default_hunter" ,
		"1" ,
		"Default selected perk for Hunter: 1 = body slam, 2 = efficient killer, 3 = grasshopper, 4 = old school, 5 = speed demon" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hInf4_default.AddChangeHook(Convar_Def_Inf4);
	g_iInf4_default = 1;

	g_hInf5_default = CreateConVar(
		"l4d_perkmod_default_jockey" ,
		"1" ,
		"Default selected perk for Jockey: " ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hInf5_default.AddChangeHook(Convar_Def_Inf5);
	g_iInf5_default = 1;

	g_hInf6_default = CreateConVar(
		"l4d_perkmod_default_spitter" ,
		"1" ,
		"Default selected perk for Spitter: " ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hInf6_default.AddChangeHook(Convar_Def_Inf6);
	g_iInf6_default = 1;

	g_hInf7_default = CreateConVar(
		"l4d_perkmod_default_charger" ,
		"1" ,
		"Default selected perk for Charger: " ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hInf7_default.AddChangeHook(Convar_Def_Inf7);
	g_iInf7_default = 1;



	//enable perk trees
	//-----------------
	g_hSur1_enable = CreateConVar(
		"l4d_perkmod_perktree_survivor1_enable" ,
		"1" ,
		"If set to 1, players will be allowed to select perks from the primary Survivor tree." ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSur1_enable.AddChangeHook(Convar_Sur1_en);
	g_bSur1_enable = true;

	g_hSur2_enable = CreateConVar(
		"l4d_perkmod_perktree_survivor2_enable" ,
		"1" ,
		"If set to 1, players will be allowed to select perks from the secondary Survivor tree." ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSur2_enable.AddChangeHook(Convar_Sur2_en);
	g_bSur2_enable = true;

	g_hSur3_enable = CreateConVar(
		"l4d_perkmod_perktree_survivor3_enable" ,
		"1" ,
		"If set to 1, players will be allowed to select perks from the tertiary Survivor tree." ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSur3_enable.AddChangeHook(Convar_Sur3_en);
	g_bSur3_enable = true;

	g_hInf1_enable = CreateConVar(
		"l4d_perkmod_perktree_boomer_enable" ,
		"1" ,
		"If set to 1, players will be allowed to select perks from the Boomer tree." ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hInf1_enable.AddChangeHook(Convar_Inf1_en);
	g_bInf1_enable = true;

	g_hInf2_enable = CreateConVar(
		"l4d_perkmod_perktree_tank_enable" ,
		"1" ,
		"If set to 1, players will be allowed to select perks from the Tank tree." ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hInf2_enable.AddChangeHook(Convar_Inf2_en);
	g_bInf2_enable = true;

	g_hInf3_enable = CreateConVar(
		"l4d_perkmod_perktree_smoker_enable" ,
		"1" ,
		"If set to 1, players will be allowed to select perks from the Smoker tree." ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hInf3_enable.AddChangeHook(Convar_Inf3_en);
	g_bInf3_enable = true;

	g_hInf4_enable = CreateConVar(
		"l4d_perkmod_perktree_hunter_enable" ,
		"1" ,
		"If set to 1, players will be allowed to select perks from the Hunter tree." ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hInf4_enable.AddChangeHook(Convar_Inf4_en);
	g_bInf4_enable = true;

	g_hInf5_enable = CreateConVar(
		"l4d_perkmod_perktree_jockey_enable" ,
		"1" ,
		"If set to 1, players will be allowed to select perks from the Jockey tree." ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hInf5_enable.AddChangeHook(Convar_Inf5_en);
	g_bInf5_enable = true;

	g_hInf6_enable = CreateConVar(
		"l4d_perkmod_perktree_spitter_enable" ,
		"1" ,
		"If set to 1, players will be allowed to select perks from the Spitter tree." ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hInf6_enable.AddChangeHook(Convar_Inf6_en);
	g_bInf6_enable = true;

	g_hInf7_enable = CreateConVar(
		"l4d_perkmod_perktree_charger_enable" ,
		"1" ,
		"If set to 1, players will be allowed to select perks from the Charger tree." ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hInf7_enable.AddChangeHook(Convar_Inf7_en);
	g_bInf7_enable = true;


	//perk hierarchy
	//--------------
	g_hInfAll_enable = CreateConVar(
		"l4d_perkmod_perktree_infected_enable" ,
		"1" ,
		"If set to 1, players will be allowed to select perks as Special Infected (affects ALL perks for SI)." ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hInfAll_enable.AddChangeHook(Convar_InfAll);
	g_bInfAll_enable = true;

	g_hSurAll_enable = CreateConVar(
		"l4d_perkmod_perktree_survivor_enable" ,
		"1" ,
		"If set to 1, players will be allowed to select perks as Survivors (affects ALL perks for Survivors)." ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSurAll_enable.AddChangeHook(Convar_SurAll);
	g_bSurAll_enable = true;

	//force random perks
	g_hForceRandom = CreateConVar(
		"l4d_perkmod_forcerandomperks" ,
		"0" ,
		"If set to 1, players will be assigned random perks at roundstart, and they cannot edit their perks." ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hForceRandom.AddChangeHook(Convar_ForceRandom);
	g_bForceRandom = false;

	//enable random perk choice
	g_hRandomEnable = CreateConVar(
		"l4d_perkmod_randomperks_enable" ,
		"1" ,
		"If set to 1, players will be allowed to randomize their perks at roundstart. Otherwise, they can only customize their perks or use default perks." ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hRandomEnable.AddChangeHook(Convar_Random_en);
	g_bRandomEnable = true;

	//misc game convars
	g_hMenuAutoShow_enable = CreateConVar(
		"l4d_perkmod_autoshowmenu" ,
		"1" ,
		"If set to 1, the perks menu will automatically be shown at the start of every round." ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
}

//=============================
// MARK: - ConVar Changes
//=============================


//changes in base L4D convars
//---------------------------

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


//changes in perkmod convars
//---------------------------

//stopping power
//the enable/disable functions also call
//the checks-pre-calculate function
void Convar_Stopping(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flStopping_dmgmult = StringToFloatConstrainted(newValue, 0.05, 1.0);
}

void Convar_Stopping_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bStopping_enable = StringToBool(newValue);
	Stopping_RunChecks();
}

void Convar_Stopping_en_sur(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bStopping_enable_sur = StringToBool(newValue);
	Stopping_RunChecks();
}

void Convar_Stopping_en_vs(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bStopping_enable_vs = StringToBool(newValue);
	Stopping_RunChecks();
}

//spirit
void Convar_SpiritBuff(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSpirit_buff = StringToIntConstrainted(newValue, 0, 170);
}

void Convar_SpiritCD(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSpirit_cd = StringToIntConstrainted(newValue, 1, 1800);
}

void Convar_SpiritCDsur(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSpirit_cd_sur = StringToIntConstrainted(newValue, 1, 1800);
}

void Convar_SpiritCDvs(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSpirit_cd_vs = StringToIntConstrainted(newValue, 1, 1800);
}

void Convar_Spirit_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSpirit_enable = StringToBool(newValue);
}

void Convar_Spirit_en_sur(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSpirit_enable_sur = StringToBool(newValue);
}

void Convar_Spirit_en_vs(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSpirit_enable_vs = StringToBool(newValue);
}

//helping hand
void Convar_HelpTime(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flHelpHand_timemult = StringToFloatConstrainted(newValue, 0.01, 1.0);
}

void Convar_HelpBuff(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iHelpHand_buff = StringToIntConstrainted(newValue, 1, 170);
}

void Convar_HelpBuffvs(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iHelpHand_buff_vs = StringToIntConstrainted(newValue, 1, 170);
}

void Convar_Help_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bHelpHand_enable = StringToBool(newValue);
}

void Convar_Help_en_sur(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bHelpHand_enable_sur = StringToBool(newValue);
}

void Convar_Help_en_vs(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bHelpHand_enable_vs = StringToBool(newValue);
}

void Convar_Help_convar(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bHelpHand_convar = StringToBool(newValue);
}

//unbreakable
void Convar_Unbreak(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iUnbreak_hp = StringToIntConstrainted(newValue, 1, 100);
}

void Convar_Unbreak_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bUnbreak_enable = StringToBool(newValue);
}

void Convar_Unbreak_en_sur(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bUnbreak_enable_sur = StringToBool(newValue);
}

void Convar_Unbreak_en_vs(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bUnbreak_enable_vs = StringToBool(newValue);
}

//double tap
//the enable/disable functions also call
//for the run-on-game-frame-check function
void Convar_DT(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flDT_rate = StringToFloatConstrainted(newValue, 0.02, 0.9);
}

void Convar_DT_rate_reload(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flDT_rate_reload = StringToFloatConstrainted(newValue, 0.2, 1.0);
}

void Convar_DT_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bDT_enable = StringToBool(newValue);
	DT_RunChecks();
}

void Convar_DT_en_sur(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bDT_enable_sur = StringToBool(newValue);
	DT_RunChecks();
}

void Convar_DT_en_vs(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bDT_enable_vs = StringToBool(newValue);
	DT_RunChecks();
}

//sleight of hand
void Convar_SoH(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flSoH_rate = StringToFloatConstrainted(newValue, 0.02, 0.9);
}

void Convar_SoH_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSoH_enable = StringToBool(newValue);
}

void Convar_SoH_en_sur(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSoH_enable_sur = StringToBool(newValue);
}

void Convar_SoH_en_vs(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSoH_enable_vs = StringToBool(newValue);
}

//chem reliant
void Convar_Chem(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iChem_buff = StringToIntConstrainted(newValue, 0, 150);
}

void Convar_Chem_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bChem_enable = StringToBool(newValue);
}

void Convar_Chem_en_sur(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bChem_enable_sur = StringToBool(newValue);
}

void Convar_Chem_en_vs(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bChem_enable_vs = StringToBool(newValue);
}

//pyrotechnician
void Convar_Pyro(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iPyro_maxticks = StringToIntConstrainted(newValue, 0, 300);
}

void Convar_Pyro_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bPyro_enable = StringToBool(newValue);
}

void Convar_Pyro_en_sur(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bPyro_enable_sur = StringToBool(newValue);
}

void Convar_Pyro_en_vs(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bPyro_enable_vs = StringToBool(newValue);
}

//pack rat
void Convar_Pack(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flPack_ammomult = StringToFloatConstrainted(newValue, 0.01, 1.0);
}

void Convar_Pack_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bPack_enable = StringToBool(newValue);
}

void Convar_Pack_en_sur(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bPack_enable_sur = StringToBool(newValue);
}

void Convar_Pack_en_vs(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bPack_enable_vs = StringToBool(newValue);
}

//hard to kill
void Convar_Hard(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flHard_hpmult = StringToFloatConstrainted(newValue, 0.01, 3.0);
}

void Convar_Hard_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bHard_enable = StringToBool(newValue);
}

void Convar_Hard_en_sur(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bHard_enable_sur = StringToBool(newValue);
}

void Convar_Hard_en_vs(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bHard_enable_vs = StringToBool(newValue);
}

//martial artist
//also rebuilds MA registry in order to
//reassign new speed values
void Convar_MA_maxpenalty(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iMA_maxpenalty = StringToIntConstrainted(newValue, 0, 6);
	MA_Rebuild();
}

void Convar_MA_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bMA_enable = StringToBool(newValue);
}

void Convar_MA_en_sur(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bMA_enable_sur = StringToBool(newValue);
}

void Convar_MA_en_vs(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bMA_enable_vs = StringToBool(newValue);
}

//extreme conditioning
void Convar_Extreme(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flExtreme_rate = StringToFloatConstrainted(newValue, 1.0, 1.5);
	Extreme_Rebuild();
}

void Convar_Extreme_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bExtreme_enable = StringToBool(newValue);
}

void Convar_Extreme_en_sur(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bExtreme_enable_sur = StringToBool(newValue);
}

void Convar_Extreme_en_vs(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bExtreme_enable_vs = StringToBool(newValue);
}

//little leaguer
void Convar_Little_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bLittle_enable = StringToBool(newValue);
}

void Convar_Little_en_sur(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bLittle_enable_sur = StringToBool(newValue);
}

void Convar_Little_en_vs(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bLittle_enable_vs = StringToBool(newValue);
}

//barf bagged
void Convar_Barf_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bBarf_enable = StringToBool(newValue);
}

//blind luck
void Convar_Blind(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flBlind_cdmult = StringToFloatConstrainted(newValue, 0.01, 1.0);
}

void Convar_Blind_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bBlind_enable = StringToBool(newValue);
}

//dead wreckening
void Convar_Dead(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flDead_dmgmult = StringToFloatConstrainted(newValue, 0.01, 4.0);
}

void Convar_Dead_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bDead_enable = StringToBool(newValue);
}

//motion sickness
void Convar_Motion(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flMotion_rate = StringToFloatConstrainted(newValue, 1.0, 4.0);
}

void Convar_Motion_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bMotion_enable = StringToBool(newValue);
}

//tongue twister
void Convar_TongueSpeed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flTongue_speedmult = StringToFloatConstrainted(newValue, 1.0, 5.0);
}

void Convar_TonguePull(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flTongue_pullmult = StringToFloatConstrainted(newValue, 1.0, 5.0);
}

void Convar_TongueRange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flTongue_rangemult = StringToFloatConstrainted(newValue, 1.0, 5.0);
}

void Convar_Tongue_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bTongue_enable = StringToBool(newValue);
}

//squeezer
void Convar_Squeezer(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flSqueezer_dmgmult = StringToFloatConstrainted(newValue, 0.1, 4.0);
}

void Convar_Squeezer_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSqueezer_enable = StringToBool(newValue);
}

//drag and drop
void Convar_Drag(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flDrag_cdmult = StringToFloatConstrainted(newValue, 0.01, 1.0);
}

void Convar_Drag_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bDrag_enable = StringToBool(newValue);
}

//smoke it
void Convar_SmokeIt_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSmokeIt_enable = StringToBool(newValue);
}

void Convar_SmokeIt_range(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSmokeItMaxRange = StringToInt(newValue);
}

void Convar_SmokeIt_speed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flSmokeItSpeed = StringToFloat(newValue);
}

//efficient killer
void Convar_Eff(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flEfficient_dmgmult = StringToFloatConstrainted(newValue, 0.1, 4.0);
}

void Convar_Eff_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bEfficient_enable = StringToBool(newValue);
}

//body slam
void Convar_Body(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iBody_minbound = StringToIntConstrainted(newValue, 2, 100);
}

void Convar_Body_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bBody_enable = StringToBool(newValue);
}

//grasshopper
void Convar_Grass(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flGrass_rate = StringToFloatConstrainted(newValue, 1.0, 3.0);
}

void Convar_Grass_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bGrass_enable = StringToBool(newValue);
}

//speed demon
void Convar_Demon (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flSpeedDemon_rate = StringToFloatConstrainted(newValue, 1.0, 3.0);
}

void Convar_Demon_dmg (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flSpeedDemon_dmgmult = StringToFloatConstrainted(newValue, 0.1, 4.0);
}

void Convar_Demon_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSpeedDemon_enable = StringToBool(newValue);
}

//ride like the wind
void Convar_Wind (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flWind_rate = StringToFloatConstrainted(newValue, 1.0, 3.0);
}

void Convar_Wind_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bWind_enable = StringToBool(newValue);
}

//cavalier
void Convar_Cavalier (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flCavalier_hpmult = StringToFloatConstrainted(newValue, 0.0, 3.0);
}

void Convar_Cavalier_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bCavalier_enable = StringToBool(newValue);
}

//frogger
void Convar_Frogger_dmgmult (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flFrogger_dmgmult = StringToFloatConstrainted(newValue, 0.0, 3.0);
}

void Convar_Frogger_rate (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flFrogger_rate = StringToFloatConstrainted(newValue, 1.0, 3.0);
}

void Convar_Frogger_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bFrogger_enable = StringToBool(newValue);
}

//ghost rider
void Convar_Ghost (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iGhost_alpha = StringToIntConstrainted(newValue, 0, 255);
}

void Convar_Ghost_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bGhost_enable = StringToBool(newValue);
}

//twin spitfire
void Convar_TwinSF (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flTwinSF_delay = StringToFloatConstrainted(newValue, 0.5, 20.0);
}

void Convar_TwinSF_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bTwinSF_enable = StringToBool(newValue);
}

//mega adhesive
void Convar_MegaAd_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bMegaAd_enable = StringToBool(newValue);
}

void Convar_MegaAd (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flMegaAd_slow = StringToFloatConstrainted(newValue, 0.0, 3.0);
}

//scattering ram
void Convar_Scatter_force (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flScatter_force = StringToFloatConstrainted(newValue, 1.0, 3.0);
}

void Convar_Scatter_hpmult (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flScatter_hpmult = StringToFloatConstrainted(newValue, 0.0, 3.0);
}

void Convar_Scatter_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bScatter_enable = StringToBool(newValue);
}

//speeding bullet
void Convar_Bullet (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flBullet_rate = StringToFloatConstrainted(newValue, 1.0, 10.0);
}

void Convar_Bullet_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bBullet_enable = StringToBool(newValue);
}

//adrenal glands
void Convar_Adrenalpunchcd (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flAdrenal_punchcdmult = StringToFloatConstrainted(newValue, 0.01, 1.0);
}

void Convar_Adrenalthrowcd (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flAdrenal_throwcdmult = StringToFloatConstrainted(newValue, 0.01, 1.0);
}

void Convar_Adrenal_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bAdrenal_enable = StringToBool(newValue);
}

//juggernaut
void Convar_Jugg (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iJuggernaut_hp = StringToIntConstrainted(newValue, 1, 99999);
}

void Convar_Jugg_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bJuggernaut_enable = StringToBool(newValue);
}

//metabolic boost
void Convar_Met (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flMetabolic_speedmult = StringToFloatConstrainted(newValue, 1.01, 3.0);
}

void Convar_Met_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bMetabolic_enable = StringToBool(newValue);
}

//storm caller
void Convar_Storm (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iStorm_mobcount = StringToIntConstrainted(newValue, 1, 10);
}

void Convar_Storm_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bStorm_enable = StringToBool(newValue);
}

//double the trouble
void Convar_Double (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flDouble_hpmult = StringToFloatConstrainted(newValue, 0.1, 2.0);
}

void Convar_Double_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bDouble_enable = StringToBool(newValue);
}

//default perks
void Convar_Def_Sur1 (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSur1_default = StrinToIntWithOneConstrainted(newValue, 5);
}

void Convar_Def_Sur2 (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSur2_default = StrinToIntWithOneConstrainted(newValue, 3);
}

void Convar_Def_Sur3 (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSur3_default=StrinToIntWithOneConstrainted(newValue, 3);
}

void Convar_Def_Inf1 (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iInf1_default = StrinToIntWithOneConstrainted(newValue, 3);
}

void Convar_Def_Inf2 (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iInf2_default = StrinToIntWithOneConstrainted(newValue, 5);
}

void Convar_Def_Inf3 (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iInf3_default = StrinToIntWithOneConstrainted(newValue, 3);
}

void Convar_Def_Inf4 (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iInf4_default = StrinToIntWithOneConstrainted(newValue, 5);
}

void Convar_Def_Inf5 (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iInf5_default = StrinToIntWithOneConstrainted(newValue, 5);
}

void Convar_Def_Inf6 (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iInf6_default = StrinToIntWithOneConstrainted(newValue, 5);
}

void Convar_Def_Inf7 (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iInf7_default = StrinToIntWithOneConstrainted(newValue, 5);
}

//force random perks
void Convar_ForceRandom (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bForceRandom = StringToBool(newValue);
}

//enable random perk choice
void Convar_Random_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bRandomEnable = StringToBool(newValue);
}

//perk trees
void Convar_Sur1_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSur1_enable = StringToBool(newValue);
	RunChecksAll();
}

void Convar_Sur2_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSur2_enable = StringToBool(newValue);
	RunChecksAll();
}

void Convar_Sur3_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSur3_enable = StringToBool(newValue);
	RunChecksAll();
}

void Convar_Inf1_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bInf1_enable = StringToBool(newValue);
	RunChecksAll();
}

void Convar_Inf2_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bInf2_enable = StringToBool(newValue);
	RunChecksAll();
}

void Convar_Inf3_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bInf3_enable = StringToBool(newValue);
	RunChecksAll();
}

void Convar_Inf4_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bInf4_enable = StringToBool(newValue);
	RunChecksAll();
}

void Convar_Inf5_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bInf5_enable = StringToBool(newValue);
	RunChecksAll();
}

void Convar_Inf6_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bInf6_enable = StringToBool(newValue);
	RunChecksAll();
}

void Convar_Inf7_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bInf7_enable = StringToBool(newValue);
	RunChecksAll();
}

void Convar_InfAll (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bInfAll_enable = StringToBool(newValue);
	RunChecksAll();
}

void Convar_SurAll (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSurAll_enable = StringToBool(newValue);
	RunChecksAll();
}

//====================================================
//====================================================
//					P	E	R	K	S
//====================================================
//====================================================



//=============================
// Events Directly related to perks
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

	ClientTeamType iTA = SM_GetClientTeamType(iAtt);
	char stWpn[16];
	event.GetString("weapon", stWpn, sizeof(stWpn));

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

	if (g_ipInf[iCid].boomerPerk == InfectedBoomerPerk_Unknown) 	g_ipInf[iCid].boomerPerk = PM_IntToInfectedBoomerPerkType(g_iInf1_default);
	if (g_ipInf[iCid].tankPerk == InfectedTankPerk_Unknown)			g_ipInf[iCid].tankPerk = PM_IntToInfectedTankPerkType(g_iInf2_default);
	if (g_ipInf[iCid].smokerPerk == InfectedSmokerPerk_Unknown)		g_ipInf[iCid].smokerPerk = PM_IntToInfectedSmokerPerkType(g_iInf3_default);
	if (g_ipInf[iCid].hunterPerk == InfectedHunterPerk_Unknown)		g_ipInf[iCid].hunterPerk = PM_IntToInfectedHunterPerkType(g_iInf4_default);
	if (g_ipInf[iCid].jockeyPerk == InfectedJockeyPerk_Unknown)		g_ipInf[iCid].jockeyPerk = PM_IntToInfectedJockeyPerkType(g_iInf5_default);
	if (g_ipInf[iCid].spitterPerk == InfectedSpitterPerk_Unknown)	g_ipInf[iCid].spitterPerk = PM_IntToInfectedSpitterPerkType(g_iInf6_default);
	if (g_ipInf[iCid].chargerPerk == InfectedChargerPerk_Unknown)	g_ipInf[iCid].chargerPerk = PM_IntToInfectedChargerPerkType(g_iInf7_default);

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
	g_bConfirm[iCid] = true;

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
		g_iSpiritTimer[iCid] = INVALID_HANDLE;
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
		PrintHintText(iCid,"%t", "WelcomeMessageHint");
		PrintToChat(iCid,"\x03[SM] %t", "WelcomeMessageChat");
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
	else
		g_bIsRoundStart = true;

	#if defined PM_DEBUG
	PrintToChatAll("\x03round start detected");
	#endif
	//for l4d1, need to change some offsets
	/*if (g_iL4D_12 == 1)
	{
		//L4D1, Windows
		g_iNextActO = 888;
		g_iAttackTimerO = 1488;
	}
	else if (g_iL4D_12 == 2)
	{
		//check for Linux or Windows by checking
		//a base offset, NextPrimaryAttack for weapons
		//--------------------------------------------
		//numbers have changed since last valve update
		//usually +4 - next activation timer changed for
		//both windows and linux, attack timer changed
		//only for linux, next primary attack changed
		//for both windows and linux

		if (g_iNextPAttO == 5088)
		{
			//L4D2, Windows
			g_iNextActO = 1068;
			g_iAttackTimerO = 5436;
		}
		else if (g_iNextPAttO == 5104)
		{
			//L4D2, Linux
			g_iNextActO = 1092;
			g_iAttackTimerO = 5448;
		}
	}*/

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
			g_iSpiritTimer[iI] = INVALID_HANDLE;
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

	if (g_bInf1_enable && g_bMotion_enable)
	{
		hCvar = FindConVar("z_vomit_fatigue");
		hCvar.RestoreDefault(false, false);
		g_flVomitFatigue = GetConVarFloat(hCvar);
	}

	//reset tongue vars

	if (g_bInf3_enable && g_bTongue_enable)
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

	if (g_bInf3_enable && g_bDrag_enable)
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
		g_hTimerPerks = INVALID_HANDLE;
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
		g_iSpiritTimer[iCid] = INVALID_HANDLE;
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
	//reset their confirm perks var
	//and show the menu
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
		g_hTimerPerks = INVALID_HANDLE;
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
		g_hTimerPerks = INVALID_HANDLE;
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
		g_iSpiritTimer[iCid] = INVALID_HANDLE;
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
			g_iSpiritTimer[iI] = INVALID_HANDLE;
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
	if (g_bInf1_enable && g_bMotion_enable)
	{
		hCvar = FindConVar("z_vomit_fatigue");
		hCvar.RestoreDefault(false, false);
	}

	//reset tongue vars
	if (g_bInf3_enable && g_bTongue_enable)
	{
		hCvar = FindConVar("tongue_victim_max_speed");
		hCvar.RestoreDefault(false, false);

		hCvar = FindConVar("tongue_range");
		hCvar.RestoreDefault(false, false);

		hCvar = FindConVar("tongue_fly_speed");
		hCvar.RestoreDefault(false, false);
	}

	if (g_bInf3_enable && g_bDrag_enable)
	{
		FindConVar("tongue_allow_voluntary_release").RestoreDefault(false, false);

		hCvar = FindConVar("tongue_player_dropping_to_ground_time");
		hCvar.RestoreDefault(false, false);
	}

	//finally, clear DT and MA registry
	ClearAll();

	if (g_hTimerPerks != INVALID_HANDLE)
		KillTimer(g_hTimerPerks);
	g_hTimerPerks = INVALID_HANDLE;

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

	if (GetConVarInt(g_hMenuAutoShow_enable) == 0)
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

//assigns random perks
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
	if (GameModeCheck(true, g_bStopping_enable, g_bStopping_enable_sur, g_bStopping_enable_vs))
	{
		iPerkCount++;
		firstPerkType[iPerkCount] = SurvivorFirstPerk_StoppingPower;
	}

	//2 double tap
	if (GameModeCheck(true, g_bDT_enable, g_bDT_enable_sur, g_bDT_enable_vs))
	{
		iPerkCount++;
		firstPerkType[iPerkCount] = SurvivorFirstPerk_DoubleTap;
	}	

	//3 sleight of hand
	if (GameModeCheck(true, g_bSoH_enable, g_bSoH_enable_sur, g_bSoH_enable_vs))
	{
		iPerkCount++;
		firstPerkType[iPerkCount] = SurvivorFirstPerk_SleightOfHand;
	}

	//4 pyrotechnician
	if (GameModeCheck(true, g_bPyro_enable, g_bPyro_enable_sur, g_bPyro_enable_vs))
	{
		iPerkCount++;
		firstPerkType[iPerkCount] = SurvivorFirstPerk_Pyrotechnician;
	}

	//randomize a perk
	if (iPerkCount > 0)
		g_spSur[iCid].firstPerk = firstPerkType[GetRandomInt(1, iPerkCount)];

	//SUR2 PERK
	//---------
	SurvivorSecondPerkType secondPerkType[SurvivorSecondPerk_Count];
	iPerkCount = 0;

	//1 unbreakable
	if (GameModeCheck(true, g_bUnbreak_enable, g_bUnbreak_enable_sur, g_bUnbreak_enable_vs))
	{
		iPerkCount++;
		secondPerkType[iPerkCount] = SurvivorSecondPerk_Unbreakable;
	}

	//2 spirit
	if (GameModeCheck(true, g_bSpirit_enable, g_bSpirit_enable_sur, g_bSpirit_enable_vs))
	{
		iPerkCount++;
		secondPerkType[iPerkCount] = SurvivorSecondPerk_Spirit;
	}

	//3 helping hand
	if (GameModeCheck(true, g_bHelpHand_enable, g_bHelpHand_enable_sur, g_bHelpHand_enable_vs))
	{
		iPerkCount++;
		secondPerkType[iPerkCount] = SurvivorSecondPerk_HelpingHand;
	}

	//4 martial artist
	if (GameModeCheck(true, g_bMA_enable, g_bMA_enable_sur, g_bMA_enable_vs))
	{
		iPerkCount++;
		secondPerkType[iPerkCount] = SurvivorSecondPerk_MartialArtist;
	}

	//randomize a perk
	if (iPerkCount > 0)
		g_spSur[iCid].secondPerk = secondPerkType[GetRandomInt(1, iPerkCount)];

	//SUR3 PERK
	//------------------
	SurvivorThirdPerkType thirdPerkType[SurvivorThirdPerk_Count];
	iPerkCount = 0;

	//1 pack rat
	if (GameModeCheck(true, g_bPack_enable, g_bPack_enable_sur, g_bPack_enable_vs))
	{
		iPerkCount++;
		thirdPerkType[iPerkCount] = SurvivorThirdPerk_PackRat;
	}

	//2 chem reliant
	if (GameModeCheck(true, g_bChem_enable, g_bChem_enable_sur, g_bChem_enable_vs))
	{
		iPerkCount++;
		thirdPerkType[iPerkCount] = SurvivorThirdPerk_ChemReliant;
	}

	//3 hard to kill
	if (GameModeCheck(true, g_bHard_enable, g_bHard_enable_sur, g_bHard_enable_vs))
	{
		iPerkCount++;
		thirdPerkType[iPerkCount] = SurvivorThirdPerk_HardToKill;
	}

	//4 extreme conditioning
	if (GameModeCheck(true, g_bExtreme_enable, g_bExtreme_enable_sur, g_bExtreme_enable_vs))
	{
		iPerkCount++;
		thirdPerkType[iPerkCount] = SurvivorThirdPerk_ExtremeConditioning;
	}

	if (GameModeCheck(true, g_bLittle_enable, g_bLittle_enable_sur, g_bLittle_enable_vs))
	{
		iPerkCount++;
		thirdPerkType[iPerkCount] = SurvivorThirdPerk_LittleLeaguer;
	}

	//randomize a perk
	if (iPerkCount > 0)
		g_spSur[iCid].thirdPerk = thirdPerkType[ GetRandomInt(1, iPerkCount)];

	//INF1 (BOOMER) PERK
	//------------------
	InfectedBoomerPerkType boomerPerkType[InfectedBoomerPerk_Count];
	iPerkCount = 0;

	//1 barf bagged
	if (g_bBarf_enable)
	{
		iPerkCount++;
		boomerPerkType[iPerkCount] = InfectedBoomerPerk_BarfBagged;
	}

	//2 blind luck
	if (g_bBlind_enable)
	{
		iPerkCount++;
		boomerPerkType[iPerkCount] = InfectedBoomerPerk_BlindLuck;
	}

	//3 dead wreckening
	if (g_bDead_enable)
	{
		iPerkCount++;
		boomerPerkType[iPerkCount] = InfectedBoomerPerk_DeadWreckening;
	}

	//4 motion sickness
	if (g_bMotion_enable)
	{
		iPerkCount++;
		boomerPerkType[iPerkCount] = InfectedBoomerPerk_MotionSickness;
	}

	//randomize a perk
	if (iPerkCount > 0)
		g_ipInf[iCid].boomerPerk = boomerPerkType[GetRandomInt(1, iPerkCount)];

	//INF3 (SMOKER) PERK
	//------------------
	InfectedSmokerPerkType smokerPerkType[InfectedSmokerPerk_Count];
	iPerkCount = 0;

	//1 tongue twister
	if (g_bTongue_enable)
	{
		iPerkCount++;
		smokerPerkType[iPerkCount] = InfectedSmokerPerk_TongueTwister;
	}

	//2 squeezer
	if (g_bSqueezer_enable)
	{
		iPerkCount++;
		smokerPerkType[iPerkCount] = InfectedSmokerPerk_Squeezer;
	}

	//3 drag and drop
	if (g_bDrag_enable)
	{
		iPerkCount++;
		smokerPerkType[iPerkCount] = InfectedSmokerPerk_DragAndDrop;
	}

	if (g_bSmokeIt_enable)
	{
		iPerkCount++;
		smokerPerkType[iPerkCount] = InfectedSmokerPerk_SmokeIt;
	}

	//randomize a perk
	if (iPerkCount > 0)
		g_ipInf[iCid].smokerPerk = smokerPerkType[GetRandomInt(1, iPerkCount)];

	//INF4 (HUNTER) PERK
	//------------------
	InfectedHunterPerkType hunterPerkType[InfectedHunterPerk_Count];
	iPerkCount = 0;

	//1 body slam
	if (g_bBody_enable)
	{
		iPerkCount++;
		hunterPerkType[iPerkCount] = InfectedHunterPerk_BodySlam;
	}

	//2 efficient killer
	if (g_bEfficient_enable)
	{
		iPerkCount++;
		hunterPerkType[iPerkCount] = InfectedHunterPerk_EfficientKiller;
	}

	//3 grasshopper
	if (g_bGrass_enable)
	{
		iPerkCount++;
		hunterPerkType[iPerkCount] = InfectedHunterPerk_Grasshopper;
	}

	//4 speed demon
	if (g_bSpeedDemon_enable)
	{
		iPerkCount++;
		hunterPerkType[iPerkCount] = InfectedHunterPerk_SpeedDemon;
	}

	//randomize a perk
	if (iPerkCount > 0)
		g_ipInf[iCid].hunterPerk = hunterPerkType[GetRandomInt(1, iPerkCount)];

	//INF5 (JOCKEY) PERK
	//------------------
	InfectedJockeyPerkType jockeyPerkType[InfectedJockeyPerk_Count];
	iPerkCount = 0;

	//1 wind
	if (g_bWind_enable)
	{
		iPerkCount++;
		jockeyPerkType[iPerkCount] = InfectedJockeyPerk_Wind;
	}

	//2 cavalier
	if (g_bCavalier_enable)
	{
		iPerkCount++;
		jockeyPerkType[iPerkCount] = InfectedJockeyPerk_Cavalier;
	}

	//3 frogger
	if (g_bFrogger_enable)
	{
		iPerkCount++;
		jockeyPerkType[iPerkCount] = InfectedJockeyPerk_Frogger;
	}

	//4 ghost
	if (g_bGhost_enable)
	{
		iPerkCount++;
		jockeyPerkType[iPerkCount] = InfectedJockeyPerk_Ghost;
	}

	//randomize a perk
	if (iPerkCount > 0)
		g_ipInf[iCid].jockeyPerk = jockeyPerkType[GetRandomInt(1, iPerkCount)];

	//INF6 (SPITTER) PERK
	//------------------
	InfectedSpitterPerkType spitterPerkType[InfectedSpitterPerk_Count];
	iPerkCount = 0;

	//1 twin spitfire
	if (g_bTwinSF_enable)
	{
		iPerkCount++;
		spitterPerkType[iPerkCount] = InfectedSpitterPerk_TwinSpitfire;
	}

	//2 mega adhesive
	if (g_bMegaAd_enable)
	{
		iPerkCount++;
		spitterPerkType[iPerkCount] = InfectedSpitterPerk_MegaAdhesive;
	}

	//randomize a perk
	if (iPerkCount > 0)
		g_ipInf[iCid].spitterPerk = spitterPerkType[GetRandomInt(1, iPerkCount)];

	//INF7 (CHARGER) PERK
	//------------------
	InfectedChargerPerkType chargerPerkType[InfectedChargerPerk_Count];
	iPerkCount = 0;

	//1 scatter
	if (g_bScatter_enable)
	{
		iPerkCount++;
		chargerPerkType[iPerkCount] = InfectedChargerPerk_Scatter;
	}

	//2 bullet
	if (g_bBullet_enable)
	{
		iPerkCount++;
		chargerPerkType[iPerkCount] = InfectedChargerPerk_Bullet;
	}

	//randomize a perk
	if (iPerkCount > 0)
		g_ipInf[iCid].chargerPerk = chargerPerkType[GetRandomInt(1, iPerkCount)];

	//INF2 (TANK) PERK
	//----------------
	InfectedTankPerkType tankPerkType[InfectedTankPerk_Count];
	iPerkCount = 0;

	//1 adrenal glands
	if (g_bAdrenal_enable)
	{
		iPerkCount++;
		tankPerkType[iPerkCount] = InfectedTankPerk_AdrenalGlands;
	}

	//2 Juggernaut
	if (g_bJuggernaut_enable)
	{
		iPerkCount++;
		tankPerkType[iPerkCount] = InfectedTankPerk_Juggernaut;
	}

	//3 metabolic boost
	if (g_bMetabolic_enable)
	{
		iPerkCount++;
		tankPerkType[iPerkCount] = InfectedTankPerk_MetabolicBoost;
	}

	//4 stormcaller
	if (g_bStorm_enable)
	{
		iPerkCount++;
		tankPerkType[iPerkCount] = InfectedTankPerk_Stormcaller;
	}

	//5 double the trouble
	if (g_bDouble_enable)
	{
		iPerkCount++;
		tankPerkType[iPerkCount] = InfectedTankPerk_DoubleTrouble;
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
		stPerk = "1, 2, 3";

	if (StringInsensitiveContains(stPerk, "1") && g_bStopping_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = SurvivorFirstPerk_StoppingPower;
	}

	if (StringInsensitiveContains(stPerk, "2") && g_bDT_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = SurvivorFirstPerk_DoubleTap;
	}

	if (StringInsensitiveContains(stPerk, "3") && g_bSoH_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = SurvivorFirstPerk_SleightOfHand;
	}

	if (StringInsensitiveContains(stPerk, "4") && g_hPyro_enable) {
		iPerkCount++;
		iPerkType[iPerkCount] = SurvivorFirstPerk_Pyrotechnician;
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
		stPerk = "1, 2, 3";

	if (StringInsensitiveContains(stPerk, "1") && g_bUnbreak_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = SurvivorSecondPerk_Unbreakable;
	}

	if (StringInsensitiveContains(stPerk, "2") && g_bSpirit_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = SurvivorSecondPerk_Spirit;
	}

	//helping hand
	if (StringInsensitiveContains(stPerk, "3") && g_bHelpHand_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = SurvivorSecondPerk_HelpingHand;
	}

	//martial artist
	if (StringInsensitiveContains(stPerk, "4") && g_bMA_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = SurvivorSecondPerk_MartialArtist;
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
		stPerk = "1, 3";

	if (StringInsensitiveContains(stPerk, "1") && g_bPack_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = SurvivorThirdPerk_PackRat;
	}

	if (StringInsensitiveContains(stPerk, "2") && g_hChem_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = SurvivorThirdPerk_ChemReliant;
	}

	if (StringInsensitiveContains(stPerk, "3") && g_bHard_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = SurvivorThirdPerk_HardToKill;
	}

	if (StringInsensitiveContains(stPerk, "4") && g_hExtreme_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = SurvivorThirdPerk_ExtremeConditioning;
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
	if (g_bInf3_enable == false) return InfectedSmokerPerk_Unknown;

	InfectedSmokerPerkType iPerkType[InfectedSmokerPerk_Count];
	int iPerkCount = 0;

	char stPerk[24];
	if (g_hBot_Inf3 != INVALID_HANDLE)
		GetConVarString(g_hBot_Inf3, stPerk, sizeof(stPerk));
	else
		stPerk = "1, 2, 3";

	if (StringInsensitiveContains(stPerk, "1") && g_bTongue_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedSmokerPerk_TongueTwister;
	}

	if (StringInsensitiveContains(stPerk, "2") && g_bSqueezer_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedSmokerPerk_Squeezer;
	}

	if (StringInsensitiveContains(stPerk, "3") && g_bDrag_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedSmokerPerk_DragAndDrop;
	}

	if (StringInsensitiveContains(stPerk, "4") && g_hSmokeIt_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedSmokerPerk_SmokeIt;
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
	if (g_bInf1_enable == false) return InfectedBoomerPerk_Unknown;

	#if defined PM_DEBUG
	PrintToChatAll("\x03begin random perk for boomer");
	#endif
	
	InfectedBoomerPerkType iPerkType[InfectedBoomerPerk_Count];
	int iPerkCount = 0;

	char stPerk[24];
	if (g_hBot_Inf1 != INVALID_HANDLE)
		GetConVarString(g_hBot_Inf1, stPerk, sizeof(stPerk));
	else
		stPerk = "1, 2, 3";

	#if defined PM_DEBUG
	PrintToChatAll("\x03-stPerk: \x01%s", stPerk);
	#endif

	if (StringInsensitiveContains(stPerk, "1") && g_bBarf_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedBoomerPerk_BarfBagged;

		#if defined PM_DEBUG
		PrintToChatAll("\x03-count \x01%i\x03, type \x01%i", iPerkCount, iPerkType[iPerkCount]);
		#endif
	}

	if (StringInsensitiveContains(stPerk, "2") && g_bBlind_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedBoomerPerk_BlindLuck;

		#if defined PM_DEBUG
		PrintToChatAll("\x03-count \x01%i\x03, type \x01%i", iPerkCount, iPerkType[iPerkCount]);
		#endif
	}

	//dead wreckening
	if (StringInsensitiveContains(stPerk, "3") && g_bDead_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedBoomerPerk_DeadWreckening;

		#if defined PM_DEBUG
		PrintToChatAll("\x03-count \x01%i\x03, type \x01%i", iPerkCount, iPerkType[iPerkCount]);
		#endif
	}

	if (StringInsensitiveContains(stPerk, "4") && g_hMotion_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedBoomerPerk_MotionSickness;
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
	if (g_bInf4_enable == false) return InfectedHunterPerk_Unknown;

	InfectedHunterPerkType iPerkType[InfectedHunterPerk_Count];
	int iPerkCount = 0;

	char stPerk[24];
	if (g_hBot_Inf4 != INVALID_HANDLE)
		GetConVarString(g_hBot_Inf4, stPerk, sizeof(stPerk));
	else
		stPerk = "2, 4";

	if (StringInsensitiveContains(stPerk, "1") && g_hBody_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedHunterPerk_BodySlam;
	}

	if (StringInsensitiveContains(stPerk, "2") && g_bEfficient_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedHunterPerk_EfficientKiller;
	}

	if (StringInsensitiveContains(stPerk, "3") && g_hGrass_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedHunterPerk_Grasshopper;
	}

	if (StringInsensitiveContains(stPerk, "4") && g_bSpeedDemon_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedHunterPerk_SpeedDemon;
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
	if (g_bInf6_enable == false) return InfectedSpitterPerk_Unknown;

	InfectedSpitterPerkType iPerkType[InfectedSpitterPerk_Count];
	int iPerkCount = 0;

	char stPerk[24];
	if (g_hBot_Inf6 != INVALID_HANDLE)
		GetConVarString(g_hBot_Inf6, stPerk, sizeof(stPerk));
	else
		stPerk = "1";

	if (StringInsensitiveContains(stPerk, "1") && g_bTwinSF_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedSpitterPerk_TwinSpitfire;
	}

	if (StringInsensitiveContains(stPerk, "2") && g_bMegaAd_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedSpitterPerk_MegaAdhesive;
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
	if (g_bInf5_enable == false) return InfectedJockeyPerk_Unknown;

	InfectedJockeyPerkType iPerkType[InfectedJockeyPerk_Count];
	int iPerkCount = 0;

	char stPerk[24];
	if (g_hBot_Inf5 != INVALID_HANDLE)
		GetConVarString(g_hBot_Inf5, stPerk, sizeof(stPerk));
	else
		stPerk = "1, 2, 3, 4";

	if (StringInsensitiveContains(stPerk, "1") && g_bWind_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedJockeyPerk_Wind;
	}

	if (StringInsensitiveContains(stPerk, "2") && g_bCavalier_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedJockeyPerk_Cavalier;
	}

	if (StringInsensitiveContains(stPerk, "3") && g_bFrogger_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedJockeyPerk_Frogger;
	}

	if (StringInsensitiveContains(stPerk, "4") && g_bGhost_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedJockeyPerk_Ghost;
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
	if (g_bInf7_enable == false) return InfectedChargerPerk_Unknown;

	InfectedChargerPerkType iPerkType[InfectedChargerPerk_Count];
	int iPerkCount = 0;

	char stPerk[24];
	if (g_hBot_Inf7 != INVALID_HANDLE)
		GetConVarString(g_hBot_Inf7, stPerk, sizeof(stPerk));
	else
		stPerk = "1, 2";

	if (StringInsensitiveContains(stPerk, "1") && g_bScatter_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedChargerPerk_Scatter;
	}

	if (StringInsensitiveContains(stPerk, "2") && g_bBullet_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedChargerPerk_Bullet;
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
	if (g_bInf2_enable == false) return InfectedTankPerk_Unknown;

	InfectedTankPerkType iPerkType[InfectedTankPerk_Count];
	int iPerkCount = 0;

	char stPerk[24];
	if (g_hBot_Inf2 != INVALID_HANDLE)
		GetConVarString(g_hBot_Inf2, stPerk, sizeof(stPerk));
	else
		stPerk = "1, 2, 3, 4, 5";

	if (StringInsensitiveContains(stPerk, "1") && g_bAdrenal_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedTankPerk_AdrenalGlands;
	}

	if (StringInsensitiveContains(stPerk, "2") && g_bJuggernaut_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedTankPerk_Juggernaut;
	}

	if (StringInsensitiveContains(stPerk, "3") && g_bMetabolic_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedTankPerk_MetabolicBoost;
	}

	//storm caller
	if (StringInsensitiveContains(stPerk, "4") && g_bStorm_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedTankPerk_Stormcaller;
	}

	//double trouble
	if (StringInsensitiveContains(stPerk, "5") && g_bDouble_enable)
	{
		iPerkCount++;
		iPerkType[iPerkCount] = InfectedTankPerk_DoubleTrouble;
	}

	//randomize
	if (iPerkCount > 0)
		return iPerkType[GetRandomInt(1, iPerkCount)];
	else
		return InfectedTankPerk_Unknown;
}

//=============================
// Sur1: Stopping Power
//=============================

//pre-calculates whether stopping power should
//run, since damage events can occur pretty often
void Stopping_RunChecks()
{
	g_bStopping_meta_enable = GameModeCheck(g_bSur1_enable, g_bStopping_enable, g_bStopping_enable_sur, g_bStopping_enable_vs);
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
// Sur1: Double Tap
//=============================

//called on round starts and on convar changes
//does the checks to determine whether DT
//should be run every game frame
void DT_RunChecks()
{
	g_bDT_meta_enable = GameModeCheck(g_bSur1_enable, g_bDT_enable, g_bDT_enable_sur, g_bDT_enable_vs);
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
// Sur1: Sleight of Hand, Double Tap
//==================================

//on the start of a reload
void SoH_OnReload(int iCid)
{
	//check if perk is disabled
	if (g_bSur1_enable == false
		|| g_bSoH_enable == false		&&	g_L4D_GameMode == GameMode_Campaign
		|| g_bSoH_enable_sur == false	&&	g_L4D_GameMode == GameMode_Survival
		|| g_bSoH_enable_vs == false	&&	g_L4D_GameMode == GameMode_Versus)
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
// Sur1: Pyrotechnician
//=============================

//on pickup
void Pyro_Pickup(int iCid, const char[] stWpn)
{
	if (g_spSur[iCid].firstPerk == SurvivorFirstPerk_Pyrotechnician 
		&& GameModeCheck(g_bSur1_enable, g_bPyro_enable, g_bPyro_enable_sur, g_bPyro_enable_vs))
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
					PrintHintText(iCid, "Pyrotechnician: %t %i %s(s)", "GrenadierCarryHint", g_iGren[iCid], stWpn2);
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
	if (g_bSur1_enable == false
		|| g_bPyro_enable == false		&&	g_L4D_GameMode == GameMode_Campaign
		|| g_bPyro_enable_sur == false	&&	g_L4D_GameMode == GameMode_Survival
		|| g_bPyro_enable_vs == false	&&	g_L4D_GameMode == GameMode_Versus)
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

			PrintHintText(iCid,"Pyrotechnician: %t %i %s(s) %t", "GrenadierCounter_A", g_iGren[iCid], stWpn2, "GrenadierCounter_B");
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
	if (g_bSur1_enable == false
		|| g_bPyro_enable == false 		&&	g_L4D_GameMode == GameMode_Campaign
		|| g_bPyro_enable_sur == false 	&&	g_L4D_GameMode == GameMode_Survival
		|| g_bPyro_enable_vs == false	&&	g_L4D_GameMode == GameMode_Versus)
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
	if (g_bSur1_enable == false
		|| g_iPyro_maxticks == 0
		|| g_bPyro_enable == false		&&	g_L4D_GameMode == GameMode_Campaign
		|| g_bPyro_enable_sur == false	&&	g_L4D_GameMode == GameMode_Survival
		|| g_bPyro_enable_vs == false	&&	g_L4D_GameMode == GameMode_Versus)
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
// Sur2: Martial Artist
//=============================

void MA_RunChecks()
{
	g_bMA_meta_enable = GameModeCheck(g_bSur2_enable, g_bMA_enable, g_bMA_enable_sur, g_bMA_enable_vs);
}

//called on confirming perks
//adds player to registry of MA users
//and sets movement speed
void Event_Confirm_MA(int iCid)
{
	if (g_iMARegisterCount < 0)
		g_iMARegisterCount = 0;

	//check if perk is enabled
	if (g_bSur1_enable == false
		|| g_bMA_enable == false		&&	g_L4D_GameMode == GameMode_Campaign
		|| g_bMA_enable_sur == false	&&	g_L4D_GameMode == GameMode_Survival
		|| g_bMA_enable_vs == false		&&	g_L4D_GameMode == GameMode_Versus)
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
	if (g_bSur2_enable == false
		|| g_bMA_enable == false		&&	g_L4D_GameMode == GameMode_Campaign
		|| g_bMA_enable_sur == false	&&	g_L4D_GameMode == GameMode_Survival
		|| g_bMA_enable_vs == false		&&	g_L4D_GameMode == GameMode_Versus)
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
// Sur2: Unbreakable
//=============================

//on heal; gives 80% of bonus hp
void Unbreakable_OnHeal(int iCid)
{
	//check if perk is enabled
	if (!g_bSur2_enable
		|| !g_bUnbreak_enable			&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bUnbreak_enable_sur		&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bUnbreak_enable_vs		&&	g_L4D_GameMode == GameMode_Versus)
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

		PrintHintText(iCid,"Unbreakable: %t!", "UnbreakableHint");
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
	if (!g_bSur2_enable
		|| !g_bUnbreak_enable			&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bUnbreak_enable_sur		&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bUnbreak_enable_vs		&&	g_L4D_GameMode == GameMode_Versus)
	{
		//if not, check if hp is higher than it should be
		if (iHP>100 && TC == ClientTeam_Survivor)
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
		if (iHP>100 && iHP < (100+g_iUnbreak_hp) )
			CreateTimer(0.5, Unbreakable_Delayed_Max, iCid);
		else if (iHP<=100)
			CreateTimer(0.5, Unbreakable_Delayed_Normal, iCid);
		PrintHintText(iCid,"Unbreakable: %t!", "UnbreakableHint");

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
		if (!g_bSur2_enable
			|| !g_bUnbreak_enable			&&	g_L4D_GameMode == GameMode_Campaign
			|| !g_bUnbreak_enable_sur		&&	g_L4D_GameMode == GameMode_Survival
			|| !g_bUnbreak_enable_vs		&&	g_L4D_GameMode == GameMode_Versus)
			return;

		CreateTimer(0.5, Unbreakable_Delayed_Rescue, iCid);
		PrintHintText(iCid, "Unbreakable: %t!", "UnbreakableHint");

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
		if (GameModeCheck(g_bSur1_enable, g_bUnbreak_enable, g_bUnbreak_enable_sur, g_bUnbreak_enable_vs))
		{
			SetEntDataFloat(iSub, g_iHPBuffO, GetEntDataFloat(iSub, g_iHPBuffO)+(g_iUnbreak_hp/2), true);
			PrintHintText(iSub,"Unbreakable: %t!", "UnbreakableHint");
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
// Sur2: Spirit
//=============================

//called by global timer "TimerPerks"
//periodically runs checks to see if anyone should self-revive
//since sometimes self-revive won't fire if someone's being disabled
//by, say, a hunter
void Spirit_Timer()
{
	//check if perk is enabled
	if (!g_bSur2_enable
		|| !g_bSpirit_enable		&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bSpirit_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bSpirit_enable_vs		&&	g_L4D_GameMode == GameMode_Versus)
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
	g_iSpiritTimer[iCid] = INVALID_HANDLE;
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
		PrintHintText(iCid,"%t", "SpiritTimerFinishedMessage");

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
			PrintHintText(iCid,"Spirit: %t!", "SpritSuccessMessage");
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
// Sur2: Helping Hand
//=============================

//fired before reviving begins, reduces revive time
void HelpHand_OnReviveBegin(int iCid)
{
	//check if cvar changes are allowed
	//for this perk; if not, then stop
	if (g_bHelpHand_convar == false)
		return;

	//check if perk is enabled
	if (!g_bSur2_enable
		|| !g_bHelpHand_enable		&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bHelpHand_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bHelpHand_enable_vs	&&	g_L4D_GameMode == GameMode_Versus)
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
	if (g_spSur[iCid].secondPerk == SurvivorSecondPerk_HelpingHand 
		&& g_bConfirm[iCid] 
		&& GameModeCheck(g_bSur2_enable, g_bHelpHand_enable, g_bHelpHand_enable_sur, g_bHelpHand_enable_vs))
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
				PrintHintText(iCid,"Helping Hand: %t %s!", "HelpingHandDonorHint", st_name);
				GetClientName(iCid, st_name, sizeof(st_name));
				PrintHintText(iSub,"Helping Hand: %s %t", st_name, "HelpingHandReceiverHint");
			}
		}
	}

	#if defined PM_DEBUG
	PrintToChatAll("\x03-revive end, attempting to reset revive time to \x01%f", g_flReviveTime);
	#endif
	//only adjust the convar if
	//convar changes are allowed
	//for this perk
	if (g_bHelpHand_convar && GameModeCheck(g_bSur2_enable, g_bHelpHand_enable, g_bHelpHand_enable_sur, g_bHelpHand_enable_vs))
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
// Sur3: Pack Rat
//=============================

//on gun pickup
void PR_Pickup(int iCid, const char[] stWpn)
{
	if (g_spSur[iCid].thirdPerk == SurvivorThirdPerk_PackRat && GameModeCheck(g_bSur2_enable, g_bPack_enable, g_bPack_enable_sur, g_bPack_enable_vs))
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

	if (g_spSur[iCid].thirdPerk == SurvivorThirdPerk_PackRat && g_bConfirm[iCid] && GameModeCheck(g_bSur3_enable, g_bPack_enable, g_bPack_enable_sur, g_bPack_enable_vs))
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
// Sur3: Chem Reliant
//=============================

//on drug used
void Chem_OnDrugUsed(int iCid)
{
	//check if perk is enabled
	if (!g_bSur3_enable
		|| !g_bChem_enable		&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bChem_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bChem_enable_vs	&&	g_L4D_GameMode == GameMode_Versus)
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
		if (g_spSur[iCid].secondPerk == SurvivorSecondPerk_Unbreakable && GameModeCheck(g_bSur3_enable, g_bUnbreak_enable, g_bUnbreak_enable_sur, g_bUnbreak_enable_vs))
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
	if (!g_bSur3_enable
		|| !g_bChem_enable		&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bChem_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bChem_enable_vs	&&	g_L4D_GameMode == GameMode_Versus)
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
// Sur3: Hard to Kill
//=============================

void HardToKill_OnIncap(int iCid)
{
	if (SM_GetClientTeamType(iCid) != ClientTeam_Survivor || g_bConfirm[iCid] == false)
		return;

	if (!g_bSur3_enable
		|| !g_bHard_enable		&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bHard_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bHard_enable_vs	&&	g_L4D_GameMode == GameMode_Versus)
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
// Sur3: Little Leaguer
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
	if (!g_bSur3_enable
		|| !g_bChem_enable		&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bChem_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bChem_enable_vs	&&	g_L4D_GameMode == GameMode_Versus)
		return;

	int iflags = GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(iCid, "give baseball_bat");
	SetCommandFlags("give", iflags);

	return;
}

//=============================
// Sur3: Extreme Conditioning
//=============================

void Extreme_Rebuild()
{
	//if the server's not running or
	//is in the middle of loading, stop
	if (IsServerProcessing() == false) return;

	//check if perk is enabled
	if (!g_bSur3_enable
		|| !g_bExtreme_enable		&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bExtreme_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bExtreme_enable_vs	&&	g_L4D_GameMode == GameMode_Versus)
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
// Inf1: Blind Luck
//=============================

void BlindLuck_OnIt(int iAtt, int iVic)
{
	//don't blind bots as per grandwaziri's plugin, they suck enough anyways
	if (g_ipInf[iAtt].boomerPerk == InfectedBoomerPerk_BlindLuck
		&& g_bConfirm[iAtt] 
		&& IsFakeClient(iVic) == false)
	{
		//check if perk is enabled
		if (g_bInf1_enable == false || g_bBlind_enable == false) return;

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
	if (g_bBlind_enable == false || g_bInf1_enable == false) return;

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
// Inf1: Barf Bagged
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
		if (g_bInf1_enable == false || g_bBarf_enable == false) return;

		#if defined PM_DEBUG
		PrintToChatAll("\x03-attempting to spawn a mob, g_iSlimed=\x01%i", g_iSlimed);
		#endif
		int iflags = GetCommandFlags("z_spawn");
		SetCommandFlags("z_spawn", iflags & ~FCVAR_CHEAT);
		FakeClientCommand(iAtt,"z_spawn mob auto");
		SetCommandFlags("z_spawn", iflags);

		if (g_iSlimed == 4) PrintHintText(iAtt, "Barf Bagged! %t", "BarfBaggedMobHint");
	}
	return;
}

//=============================
// Inf1: Dead Wreckening
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
		if (!g_bInf1_enable || !g_bDead_enable) return true;

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
// Inf1: Motion Sickness
//=============================

void Motion_OnSpawn(int iCid)
{
	//stop here if the perk is disabled
	if (!g_bMotion_enable || !g_bInf1_enable) return;

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
// Inf3: Tongue Twister
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
	if (!g_bInf3_enable || !g_bTongue_enable) return;

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
	if (g_bInf3_enable && g_bTongue_enable)
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
	if (!g_bInf3_enable || !g_bTongue_enable) return;

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
// Inf3: Squeezer
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
		if (!g_bInf3_enable	|| !g_bSqueezer_enable) return true;

		int iDmgAdd = DamageAddRound(iDmgOrig, g_flSqueezer_dmgmult);
		if (iDmgAdd == 0) return false;

		InfToSurDamageAdd(iVic, iDmgAdd, iDmgOrig);
		return true;
	}
	return false;
}

//=============================
// Inf3: Drag and Drop
//=============================

//alters cooldown to be faster
void Drag_OnTongueGrab(int iCid)
{
	#if defined PM_DEBUG
	PrintToChatAll("\x03drag and drop running checks");
	#endif
	//stop if drag and drop is disabled
	if (!g_bInf3_enable || !g_bDrag_enable) return;

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
	if (!g_bInf3_enable || !g_bDrag_enable) return false;

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
// Inf3: Smoke IT!
//=============================

Action SmokeIt_OnTongueGrab(int smoker, int victim)
{
	if (!g_bInf3_enable || !g_bSmokeIt_enable || g_ipInf[smoker].smokerPerk != InfectedSmokerPerk_SmokeIt || !g_bConfirm[smoker]) 
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
		g_hSmokeItTimer[smoker] = INVALID_HANDLE;
		CloseHandle(pack);
		return Plugin_Stop;
	}
			
	int victim = pack.ReadCell();
	if (!IsValidClient(victim) || (SM_GetClientTeamType(victim) != ClientTeam_Survivor) || (g_bSmokeItGrabbed[smoker] = false))
	{
		g_hSmokeItTimer[smoker] = INVALID_HANDLE;
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
		g_hSmokeItTimer[smoker] = INVALID_HANDLE;
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
// Inf4: Body Slam
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
		if (!g_bInf4_enable || !g_bBody_enable) return true;

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
				PrintHintText(iAtt,"Body Slam: %i %t!", iMinBound-iDmgOrig, "BonusDamageText");

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
						PrintHintText(iAtt, "Body Slam: %i bonus damage!", iDmgCount+iDmgAdd);

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
					PrintHintText(iAtt, "Body Slam: %i bonus damage!", iDmgAdd);

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
// Inf4: Efficient Killer
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
		if (!g_bInf4_enable || g_bEfficient_enable) return true;

		int iDmgAdd = DamageAddRound(iDmgOrig, g_flEfficient_dmgmult);
		if (iDmgAdd == 0) return false;

		InfToSurDamageAdd(iVic, iDmgAdd , iDmgOrig);
		return true;
	}

	return false;
}

//=============================
// Inf4: Speed Demon
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
		if (!g_bInf4_enable || !g_bEfficient_enable) return true;

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
	if (!g_bSpeedDemon_enable || !g_bInf4_enable)
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
// Inf4: Grasshopper
//=============================

bool Grass_OnAbilityUse(int iCid, const char[] stAb)
{
	//stop if grasshopper is disabled
	if (!g_bInf4_enable || !g_bGrass_enable)
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
// Inf5: Ride Like the Wind
//=============================

//for wind to work, must change VICTIM's speed
void Wind_OnRideStart(int iAtt, int iVic)
{
	if (g_ipInf[iAtt].jockeyPerk == InfectedJockeyPerk_Wind
		&& g_bConfirm[iAtt] 
		&& g_bInf5_enable 
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
// Inf5: Cavalier
//=============================

//set hp after a small delay, to avoid stupid bugs
bool Cavalier_OnSpawn(int iCid)
{
	//stop here if the perk is disabled
	if (!g_bCavalier_enable || !g_bInf5_enable) return false;

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
// Inf5: Frogger
//=============================

bool Frogger_DamageAdd(int iAtt, int iVic, ClientTeamType iTA, const char[] stWpn, int iDmgOrig)
{
	if (iTA == ClientTeam_Infected 
		&& g_bConfirm[iAtt] 
		&& StrEqual(stWpn, "jockey_claw") 
		&& g_ipInf[iAtt].jockeyPerk == InfectedJockeyPerk_Frogger)
	{
		//stop if frogger is disabled
		if (!g_bInf5_enable || !g_bFrogger_enable) return true;

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
	if (!g_bInf5_enable || !g_bFrogger_enable || SM_IntToInfectedType(GetEntData(iCid, g_iClassO), g_bIsL4D2) != Infected_Jockey) return false;

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
// Inf5: Ghost Rider
//=============================

bool Ghost_OnSpawn(int iCid)
{
	//stop if frogger is disabled
	if (!g_bInf5_enable || !g_bGhost_enable) return false;

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
// Inf6: Twin Spitfire
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
	if (!g_bInf6_enable || !g_bTwinSF_enable) return false;

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
// Inf6: Mega Adhesive
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
		g_hMegaAdTimer[iVic] = INVALID_HANDLE;
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
		g_hMegaAdTimer[iVic] = INVALID_HANDLE;
		return Plugin_Stop;
	}
}

//=============================
// Inf7: Scattering Ram
//=============================

bool Scatter_OnImpact(int iAtt, int iVic)
{
	//stop if disabled
	if (!g_bInf7_enable || !g_bScatter_enable) return false;

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
	if (!g_bScatter_enable || !g_bInf7_enable) return false;

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
// Inf7: Speeding Bullet
//=============================

bool Bullet_OnAbilityUse(int iCid, const char[] stAb)
{
	//stop if frogger is disabled
	if (!g_bInf7_enable || !g_bBullet_enable) return false;

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
// Inf2: Tank Perks
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
	if (!g_bInf2_enable) 
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
					PrintHintText(iCid,"Adrenal Glands: %t", "AdrenalGlandsHint");
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
					PrintHintText(iCid, "Juggernaut: %t", "JuggernautHint");

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
					PrintHintText(iCid,"Storm Caller: %t", "StormCallerHint");

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
		if (!g_bDouble_enable) return;

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
			PrintHintText(iCid,"Double Trouble: %t", "DoubleTroubleHint1");
		return ;
	}

	//if double trouble is activated (g_iTank==3)
	//subsequent tanks will have reduced hp
	else if (g_iTank == 3)
	{
		//stop if double trouble is disabled
		if (!g_bDouble_enable) return;

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
			PrintHintText(iCid,"%t", "DoubleTroubleHint2");

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

	if (!g_bInf2_enable) return;

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
	if (IsClientInGame(iCid) == false
		|| IsFakeClient(iCid) == true
		|| IsPlayerAlive(iCid) == false
		|| SM_GetClientTeamType(iCid) != ClientTeam_Infected
		|| g_iTankCount <= 1
		|| g_bInf2_enable == false
		|| g_bDouble_enable == false)
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
		|| g_bInf2_enable == false)
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
//					M	E	N	U
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
	char stPanel[128];

	menu.SetTitle("tPoncho's Perkmod");

	//"This server is using Perkmod"
	Format(stPanel, sizeof(stPanel), "%t", "InitialMenuPanel1");
	menu.DrawText(stPanel);
	//"Select option 1 to customize your perks"
	Format(stPanel, sizeof(stPanel), "%t", "InitialMenuPanel2");
	menu.DrawText(stPanel);
	//"Customize Perks"
	Format(stPanel, sizeof(stPanel), "%t", "InitialMenuPanel3");
	menu.DrawItem(stPanel);

	//random perks, enable only if cvar is set
	if (!g_bRandomEnable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		//"You can opt to randomize your perks"
		Format(stPanel, sizeof(stPanel), "%t", "InitialMenuPanel4");
		menu.DrawText(stPanel);
		//"but you can't change them afterwards"
		Format(stPanel, sizeof(stPanel), "%t", "InitialMenuPanel5");
		menu.DrawText(stPanel);
		//"Randomize Perks"
		Format(stPanel, sizeof(stPanel), "%t", "InitialMenuPanel6");
		menu.DrawItem(stPanel);
	}

	//"Otherwise, you can use whatever"
	Format(stPanel, sizeof(stPanel), "%t", "InitialMenuPanel7");
	menu.DrawText(stPanel);
	//"perks you've selected already"
	Format(stPanel, sizeof(stPanel), "%t", "InitialMenuPanel8");
	menu.DrawText(stPanel);
	//"by using option 3"
	Format(stPanel, sizeof(stPanel), "%t", "InitialMenuPanel9");
	menu.DrawText(stPanel);
	//"PLAY NOW!"
	Format(stPanel, sizeof(stPanel), "%t", "InitialMenuPanel10");
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
					PrintHintText(client, "Perkmod: %t", "ThanksForChoosingMessage");
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
					PrintHintText(client, "Perkmod: %t", "ThanksForChoosingMessage");
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
					PrintHintText(client, "Perkmod: %t", "ThanksForChoosingMessage");
				}
			case 3:
				{
					g_bConfirm[client] = true;
					PrintHintText(client, "Perkmod: %t", "ThanksForChoosingMessage");
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
	Panel menu = CreatePanel();
	menu.SetTitle("tPoncho's Perkmod - Main Menu");
	menu.DrawText("Select a submenu to choose a perk");

	char st_perk[32];
	char st_display[MAXPLAYERS+1];

	//set name for sur1 perk
	if (g_spSur[iCid].firstPerk == SurvivorFirstPerk_StoppingPower && GameModeCheck(true, g_bStopping_enable, g_bStopping_enable_sur, g_bStopping_enable_vs))
		st_perk = "Stopping Power";
	else if (g_spSur[iCid].firstPerk == SurvivorFirstPerk_DoubleTap && GameModeCheck(true, g_bDT_enable, g_bDT_enable_sur, g_bDT_enable_vs))
		st_perk = "Double Tap";
	else if (g_spSur[iCid].firstPerk == SurvivorFirstPerk_SleightOfHand && GameModeCheck(true, g_bSoH_enable, g_bSoH_enable_sur, g_bSoH_enable_vs))
		st_perk = "Sleight of Hand";
	else if (g_spSur[iCid].firstPerk == SurvivorFirstPerk_Pyrotechnician && GameModeCheck(true, g_bPyro_enable, g_bPyro_enable_sur, g_bPyro_enable_vs))
		st_perk = "Pyrotechnician";
	else
		st_perk = "Not set";

	Format(st_display, sizeof(st_display), "Survivor - Primary (%s)", st_perk);
	if (g_bSur1_enable)
		menu.DrawItem(st_display);
	else
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);

	//set name for sur2 perk
	if (g_spSur[iCid].secondPerk == SurvivorSecondPerk_Unbreakable && GameModeCheck(true, g_bUnbreak_enable, g_bUnbreak_enable_sur, g_bUnbreak_enable_vs))
		st_perk = "Unbreakable";
	else if (g_spSur[iCid].secondPerk == SurvivorSecondPerk_Spirit && GameModeCheck(true, g_bSpirit_enable, g_bSpirit_enable_sur, g_bSpirit_enable_vs))
		st_perk = "Spirit";
	else if (g_spSur[iCid].secondPerk == SurvivorSecondPerk_HelpingHand && GameModeCheck(true, g_bHelpHand_enable, g_bHelpHand_enable_sur, g_bHelpHand_enable_vs))
		st_perk = "Helping Hand";
	else if (g_spSur[iCid].secondPerk == SurvivorSecondPerk_MartialArtist	&& g_bIsL4D2 && GameModeCheck(true, g_bMA_enable, g_bMA_enable_sur, g_bMA_enable_vs))
		st_perk = "Martial Artist";
	else
		st_perk = "Not set";

	Format(st_display, sizeof(st_display), "Survivor - Secondary (%s)", st_perk);
	if (g_bSur2_enable)
		menu.DrawItem(st_display);
	else
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);

	//set name for sur3 perk
	if (g_spSur[iCid].thirdPerk == SurvivorThirdPerk_PackRat && GameModeCheck(true, g_bPack_enable, g_bPack_enable_sur, g_bPack_enable_vs))
		st_perk = "Pack Rat";
	else if (g_spSur[iCid].thirdPerk == SurvivorThirdPerk_ChemReliant && GameModeCheck(true, g_bChem_enable, g_bChem_enable_sur, g_bChem_enable_vs))
		st_perk = "Chem Reliant";
	else if (g_spSur[iCid].thirdPerk == SurvivorThirdPerk_HardToKill && GameModeCheck(true, g_bHard_enable, g_bHard_enable_sur, g_bHard_enable_vs))
		st_perk = "Hard to Kill";
	else if (g_spSur[iCid].thirdPerk == SurvivorThirdPerk_ExtremeConditioning && GameModeCheck(true, g_bExtreme_enable, g_bExtreme_enable_sur, g_bExtreme_enable_vs))
		st_perk = "Extreme Conditioning";
	else if (g_spSur[iCid].thirdPerk == SurvivorThirdPerk_LittleLeaguer && GameModeCheck(true, g_bLittle_enable, g_bLittle_enable_sur, g_bLittle_enable_vs))
		st_perk = "Little Leaguer";
	else
		st_perk = "Not set";

	Format(st_display, sizeof(st_display), "Survivor - Tertiary (%s)", st_perk);
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
	Format(st_display, sizeof(st_display), "%t", "DoneNagPanel2");	
	menu.DrawText(st_display);
	Format(st_display, sizeof(st_display), "%t", "DoneNagPanel3");	
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
	Panel menu = CreatePanel();
	menu.SetTitle("tPoncho's Perkmod - Main Menu");
	menu.DrawText("Select a submenu to choose a perk");

	char st_perk[32];
	char st_display[MAXPLAYERS+1];

	//set name for inf1 perk
	InfectedBoomerPerkType boomerPerk = g_ipInf[iCid].boomerPerk;
	if (boomerPerk == InfectedBoomerPerk_BarfBagged && g_bBarf_enable)
		st_perk = "Barf Bagged";
	else if (boomerPerk == InfectedBoomerPerk_BlindLuck && g_bBlind_enable)
		st_perk = "Blind Luck";
	else if (boomerPerk == InfectedBoomerPerk_DeadWreckening && g_bDead_enable)
		st_perk = "Dead Wreckening";
	else if (boomerPerk == InfectedBoomerPerk_MotionSickness && g_bMotion_enable)
		st_perk = "Motion Sickness";
	else
		st_perk = "Not set";

	Format(st_display, sizeof(st_display), "Boomer (%s)", st_perk);
	if (g_bInf1_enable)
		menu.DrawItem(st_display);
	else
		menu.DrawItem(st_display, ITEMDRAW_NOTEXT);

	//set name for inf3 perk
	InfectedSmokerPerkType smokerPerk = g_ipInf[iCid].smokerPerk;
	if (smokerPerk == InfectedSmokerPerk_TongueTwister && g_bTongue_enable)
		st_perk = "Tongue Twister";
	else if (smokerPerk == InfectedSmokerPerk_Squeezer && g_bSqueezer_enable)
		st_perk = "Squeezer";
	else if (smokerPerk == InfectedSmokerPerk_DragAndDrop && g_bDrag_enable)
		st_perk = "Drag and Drop";
	else if (smokerPerk == InfectedSmokerPerk_SmokeIt && g_bSmokeIt_enable)
		st_perk = "Smoke IT!";
	else
		st_perk = "Not set";

	Format(st_display, sizeof(st_display), "Smoker (%s)", st_perk);
	if (g_bInf3_enable)
		menu.DrawItem(st_display);
	else
		menu.DrawItem(st_display, ITEMDRAW_NOTEXT);

	//set name for inf4 perk
	InfectedHunterPerkType hunterPerk = g_ipInf[iCid].hunterPerk;
	if (hunterPerk == InfectedHunterPerk_BodySlam && g_bBody_enable)
		st_perk = "Body Slam";
	else if (hunterPerk == InfectedHunterPerk_EfficientKiller && g_bEfficient_enable)
		st_perk = "Efficient Killer";
	else if (hunterPerk == InfectedHunterPerk_Grasshopper && g_bGrass_enable)
		st_perk = "Grasshopper";
	else if (hunterPerk == InfectedHunterPerk_SpeedDemon && g_bSpeedDemon_enable)
		st_perk = "Speed Demon";
	else
		st_perk = "Not set";

	Format(st_display, sizeof(st_display), "Hunter (%s)", st_perk);
	if (g_bInf4_enable)
		menu.DrawItem(st_display);
	else
		menu.DrawItem(st_display, ITEMDRAW_NOTEXT);

	//set name for inf5 perk
	InfectedJockeyPerkType jockeyPerk = g_ipInf[iCid].jockeyPerk;
	if (jockeyPerk == InfectedJockeyPerk_Wind && g_bWind_enable)
		st_perk = "Ride Like the Wind";
	else if (jockeyPerk == InfectedJockeyPerk_Cavalier && g_bCavalier_enable)
		st_perk = "Cavalier";
	else if (jockeyPerk == InfectedJockeyPerk_Frogger && g_bFrogger_enable)
		st_perk = "Frogger";
	else if (jockeyPerk == InfectedJockeyPerk_Ghost && g_bGhost_enable)
		st_perk = "Ghost Rider";
	else
		st_perk = "Not set";

	Format(st_display, sizeof(st_display), "Jockey (%s)", st_perk);
	if (g_bInf5_enable && g_bIsL4D2)
		menu.DrawItem(st_display);
	else
		menu.DrawItem(st_display, ITEMDRAW_NOTEXT);

	//set name for inf6 perk
	InfectedSpitterPerkType spitterPerk = g_ipInf[iCid].spitterPerk;
	if (spitterPerk == InfectedSpitterPerk_TwinSpitfire && g_bTwinSF_enable)
		st_perk = "Twin Spitfire";
	else if (spitterPerk == InfectedSpitterPerk_MegaAdhesive && g_bMegaAd_enable)
		st_perk = "Mega Adhesive";
	else
		st_perk = "Not set";

	Format(st_display, sizeof(st_display), "Spitter (%s)", st_perk);
	if (g_bInf6_enable && g_bIsL4D2)
		menu.DrawItem(st_display);
	else
		menu.DrawItem(st_display, ITEMDRAW_NOTEXT);

	//set name for inf7 perk
	InfectedChargerPerkType chargerPerk = g_ipInf[iCid].chargerPerk;
	if (chargerPerk == InfectedChargerPerk_Scatter && g_bScatter_enable)
		st_perk = "Scattering Ram";
	else if (chargerPerk == InfectedChargerPerk_Bullet && g_bBullet_enable)
		st_perk = "Speeding Bullet";
	else
		st_perk = "Not set";

	Format(st_display, sizeof(st_display), "Charger (%s)", st_perk);
	if (g_bInf7_enable && g_bIsL4D2)
		menu.DrawItem(st_display);
	else
		menu.DrawItem(st_display, ITEMDRAW_NOTEXT);

	//set name for inf2 perk
	InfectedTankPerkType tankPerk = g_ipInf[iCid].tankPerk;
	if (tankPerk == InfectedTankPerk_AdrenalGlands && g_bAdrenal_enable)
		st_perk = "Adrenal Glands";
	else if (tankPerk == InfectedTankPerk_Juggernaut && g_bJuggernaut_enable)
		st_perk = "Juggernaut";
	else if (tankPerk == InfectedTankPerk_MetabolicBoost && g_bMetabolic_enable)
		st_perk = "Metabolic";
	else if (tankPerk == InfectedTankPerk_Stormcaller && g_bStorm_enable)
		st_perk = "Storm Caller";
	else if (tankPerk == InfectedTankPerk_DoubleTrouble && g_bDouble_enable)
		st_perk = "Double the Trouble";
	else
		st_perk = "Not set";

	Format(st_display, sizeof(st_display), "Tank (%s)", st_perk);
	if (g_bInf2_enable)
		menu.DrawItem(st_display);
	else
		menu.DrawItem(st_display, ITEMDRAW_NOTEXT);

	menu.DrawText("In order for your perks to work");
	menu.DrawText("you MUST hit 'done'");
	menu.DrawText("DONE");

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
			case 1: SendPanelToClient(Menu_Inf1Perk(client), client, Menu_ChooseInf1Perk, MENU_TIME_FOREVER);
			case 2: SendPanelToClient(Menu_Inf3Perk(client), client, Menu_ChooseInf3Perk, MENU_TIME_FOREVER);
			case 3: SendPanelToClient(Menu_Inf4Perk(client), client, Menu_ChooseInf4Perk, MENU_TIME_FOREVER);
			case 4: SendPanelToClient(Menu_Inf5Perk(client), client, Menu_ChooseInf5Perk, MENU_TIME_FOREVER);
			case 5: SendPanelToClient(Menu_Inf6Perk(client), client, Menu_ChooseInf6Perk, MENU_TIME_FOREVER);
			case 6: SendPanelToClient(Menu_Inf7Perk(client), client, Menu_ChooseInf7Perk, MENU_TIME_FOREVER);
			case 7: SendPanelToClient(Menu_Inf2Perk(client), client, Menu_ChooseInf2Perk, MENU_TIME_FOREVER);
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
	char panel[128];
	Format(panel, sizeof(panel), "%t", "ConfirmNagPanel1");	

	Panel menu = CreatePanel();
	menu.SetTitle(panel);
	menu.DrawText("");
	
	Format(panel, sizeof(panel), "%t", "ConfirmNagPanel2");
	menu.DrawText(panel);
	Format(panel, sizeof(panel), "%t", "ConfirmNagPanel3");
	menu.DrawText(panel);
	Format(panel, sizeof(panel), "%t", "ConfirmNagPanel4");
	menu.DrawText(panel);
	Format(panel, sizeof(panel), "%t", "ConfirmNagPanel5");
	menu.DrawText(panel);
	Format(panel, sizeof(panel), "%t", "ConfirmNagPanel6");
	menu.DrawText(panel);
	Format(panel, sizeof(panel), "%t", "ConfirmNagPanel7");
	menu.DrawText(panel);
	Format(panel, sizeof(panel), "%t", "ConfirmNagPanel8");
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
	Panel menu=CreatePanel();
	menu.SetTitle("tPoncho's Perkmod");

	char st_perk[128];

	//"Your perks for this round:"
	Format(st_perk, sizeof(st_perk), "%t:", "MapPerksPanel");

	//show sur1 perk
	SurvivorFirstPerkType firstPerk = g_spSur[iCid].firstPerk;
	if (firstPerk == SurvivorFirstPerk_StoppingPower && GameModeCheck(true, g_bStopping_enable, g_bStopping_enable_sur, g_bStopping_enable_vs))
		Format(st_perk , sizeof(st_perk), "Stopping Power (+%i%% %t)", RoundToNearest(g_flStopping_dmgmult*100), "BonusDamageText" );
	else if (firstPerk == SurvivorFirstPerk_DoubleTap && GameModeCheck(true, g_bDT_enable, g_bDT_enable_sur, g_bDT_enable_vs))
		Format(st_perk, sizeof(st_perk), "Double Tap (%t, %t, %t)", "DoubleTapDescriptionPanel", "SleighOfHandDescriptionPanel", "DoubleTapRestrictionWarning" ) ;
	else if (firstPerk == SurvivorFirstPerk_SleightOfHand && GameModeCheck(true, g_bSoH_enable, g_bSoH_enable_sur, g_bSoH_enable_vs))
		Format(st_perk, sizeof(st_perk), "Sleight of Hand (%t +%i%%)", "SleighOfHandDescriptionPanel", RoundToNearest(100 * ((1/g_flSoH_rate)-1) ) ) ;
	else if (firstPerk == SurvivorFirstPerk_Pyrotechnician && GameModeCheck(true, g_bPyro_enable, g_bPyro_enable_sur, g_bPyro_enable_vs))
		Format(st_perk, sizeof(st_perk), "Pyrotechnician (%t)", "PyroDescriptionPanel");
	else
		Format(st_perk, sizeof(st_perk),"%t", "NotSet");

	if (g_bSur1_enable)
	{
		menu.DrawItem("Survivor, primary:");
		menu.DrawText(st_perk);
	}

	//show sur2 perk
	SurvivorSecondPerkType secondPerk = g_spSur[iCid].secondPerk;
	if (secondPerk == SurvivorSecondPerk_Unbreakable && GameModeCheck(true, g_bUnbreak_enable, g_bUnbreak_enable_sur, g_bUnbreak_enable_vs))
		Format(st_perk, sizeof(st_perk), "Unbreakable (+%i %t)", g_iUnbreak_hp, "UnbreakableHint");
	else if (secondPerk == SurvivorSecondPerk_Spirit && GameModeCheck(true, g_bSpirit_enable, g_bSpirit_enable_sur, g_bSpirit_enable_vs))
	{
		int iTime = g_iSpirit_cd;
		if (g_L4D_GameMode == GameMode_Versus)
			iTime = g_iSpirit_cd_vs;
		else if (g_L4D_GameMode == GameMode_Survival)
			iTime=g_iSpirit_cd_sur;
		
		Format(st_perk, sizeof(st_perk), "Spirit (%t: %i min)", "SpiritDescriptionPanel", iTime/60);
	}
	else if (secondPerk == SurvivorSecondPerk_HelpingHand && GameModeCheck(true, g_bHelpHand_enable, g_bHelpHand_enable_sur, g_bHelpHand_enable_vs))
	{
		int iBuff = g_iHelpHand_buff;
		if (g_L4D_GameMode == GameMode_Versus)
			iBuff=g_iHelpHand_buff_vs;

		if (g_bHelpHand_convar)
			Format(st_perk, sizeof(st_perk), "Helping Hand (%t +%i)", "HelpingHandDescriptionPanel2", iBuff);
		else
			Format(st_perk, sizeof(st_perk), "Helping Hand (%t +%i)", "HelpingHandDescriptionPanel", iBuff);
	}
	else if (secondPerk == SurvivorSecondPerk_MartialArtist && GameModeCheck(true, g_bMA_enable, g_bMA_enable_sur, g_bMA_enable_vs))
	{
		if (g_iMA_maxpenalty < 6)
			Format(st_perk, sizeof(st_perk), "Martial Artist (%t)", "MartialArtistDescriptionPanel");
		else
			Format(st_perk, sizeof(st_perk), "Martial Artist (%t)", "MartialArtistDescriptionPanel_noreduc");
	}
	else
		Format(st_perk, sizeof(st_perk), "%t", "NotSet");

	if (g_bSur2_enable)
	{
		menu.DrawItem("Survivor, secondary:");
		menu.DrawText(st_perk);
	}

	//show sur3 perk
	SurvivorThirdPerkType thirdPerk = g_spSur[iCid].thirdPerk;
	if (thirdPerk == SurvivorThirdPerk_PackRat && GameModeCheck(true, g_bPack_enable, g_bPack_enable_sur, g_bPack_enable_vs))
		Format(st_perk, sizeof(st_perk), "Pack Rat (%t +%i%%)", "PackRatDescriptionPanel", RoundToNearest(g_flPack_ammomult*100) );
	else if (thirdPerk == SurvivorThirdPerk_ChemReliant && GameModeCheck(true, g_bChem_enable, g_bChem_enable_sur, g_bChem_enable_vs))
		Format(st_perk, sizeof(st_perk), "Chem Reliant (%t +%i)", "ChemReliantDescriptionPanel", g_iChem_buff);
	else if (thirdPerk == SurvivorThirdPerk_HardToKill && GameModeCheck(true, g_bHard_enable, g_bHard_enable_sur, g_bHard_enable_vs))
		Format(st_perk, sizeof(st_perk), "Hard to Kill (+%i%% %t)", RoundToNearest(g_flHard_hpmult*100), "HardToKillDescriptionPanel");
	else if (thirdPerk == SurvivorThirdPerk_ExtremeConditioning && GameModeCheck(true, g_bExtreme_enable, g_bExtreme_enable_sur, g_bExtreme_enable_vs))
		Format(st_perk, sizeof(st_perk), "Extreme Conditioning (+%i%% %t)", RoundToNearest(g_flExtreme_rate * 100 - 100), "MartialArtistDescriptionPanelCoop" );
	else if (thirdPerk == SurvivorThirdPerk_LittleLeaguer && GameModeCheck(true, g_bLittle_enable, g_bLittle_enable_sur, g_bLittle_enable_vs))
		Format(st_perk, sizeof(st_perk),"Little Leaguer (%t)", "LittleLeaguerDescriptionPanel" );
	else
		Format(st_perk, sizeof(st_perk), "%t", "NotSet");

	if (g_bSur3_enable)
	{
		menu.DrawItem("Survivor, tertiary:");
		menu.DrawText(st_perk);
	}

	return menu;
}

//shows perk choices, infected
Panel Menu_ShowChoices_Inf(int iCid)
{
	char st_perk[128];
	char stDesc[128];

	Panel menu = CreatePanel();
	menu.SetTitle("tPoncho's Perkmod: Your perks for this round");

	//show inf1 perk
	InfectedBoomerPerkType boomerPerk = g_ipInf[iCid].boomerPerk;
	if (boomerPerk == InfectedBoomerPerk_BarfBagged && g_bBarf_enable)
	{
		st_perk = "Boomer: Barf Bagged";
		Format(stDesc, sizeof(st_perk), "%t", "BarfBaggedDescriptionPanel");
	}
	else if (boomerPerk == InfectedBoomerPerk_BlindLuck && g_bBlind_enable)
	{
		st_perk = "Boomer: Blind Luck";
		Format(stDesc, sizeof(st_perk), "%t", "AcidVomitDescriptionPanel");
	}
	else if (boomerPerk == InfectedBoomerPerk_DeadWreckening && g_bDead_enable)
	{
		st_perk = "Boomer: Dead Wreckening";
		Format(stDesc, sizeof(st_perk), "%t: +%i%%", "DeadWreckeningDescriptionPanel", RoundToNearest(100*g_flDead_dmgmult));
	}
	else if (boomerPerk == InfectedBoomerPerk_MotionSickness && g_bMotion_enable)
	{
		st_perk = "Boomer: Motion Sickness";
		Format(stDesc, sizeof(st_perk), "%t", "MotionSicknessDescriptionPanel");
	}
	else
	{
		Format(st_perk, sizeof(st_perk), "Boomer: %t", "NotSet");
		stDesc = "";
	}

	if (g_bInf1_enable)
	{
		menu.DrawItem(st_perk);
		menu.DrawText(stDesc);
	}

	//show inf3 perk
	InfectedSmokerPerkType smokerPerk = g_ipInf[iCid].smokerPerk;
	if (smokerPerk == InfectedSmokerPerk_TongueTwister && g_bTongue_enable)
	{
		st_perk = "Smoker: Tongue Twister";
		Format(stDesc, sizeof(st_perk), "%t", "TongueTwisterDescriptionPanel");
	}
	else if (smokerPerk == InfectedSmokerPerk_Squeezer && g_bSqueezer_enable)
	{
		st_perk = "Smoker: Squeezer";
		Format(stDesc, sizeof(st_perk), "+%i%% %t", RoundToNearest(g_flSqueezer_dmgmult*100), "BonusDamageText" );
	}
	else if (smokerPerk == InfectedSmokerPerk_DragAndDrop && g_bDrag_enable)
	{
		st_perk = "Smoker: Drag and Drop";
		Format(stDesc, sizeof(st_perk), "%t", "DragAndDropDescriptionPanel");
	}
	else if (smokerPerk == InfectedSmokerPerk_SmokeIt && g_bSmokeIt_enable)
	{
		st_perk = "Smoker: Smoke IT!";
		Format(stDesc, sizeof(st_perk), "%t", "SmokeItDescriptionPanel");
	}
	else
	{
		Format(st_perk, sizeof(st_perk), "Smoker: %t", "NotSet");
		stDesc = "";
	}

	if (g_bInf3_enable)
	{
		menu.DrawItem(st_perk);
		menu.DrawText(stDesc);
	}

	//show inf4 perk
	InfectedHunterPerkType hunterPerk = g_ipInf[iCid].hunterPerk;
	if (hunterPerk == InfectedHunterPerk_BodySlam && g_bBody_enable)
	{
		st_perk = "Hunter: Body Slam";
		Format(stDesc, sizeof(st_perk), "%i %t", g_iBody_minbound, "BodySlamDescriptionPanel");
	}
	else if (hunterPerk == InfectedHunterPerk_EfficientKiller && g_bEfficient_enable)
	{
		st_perk = "Hunter: Efficient Killer";
		Format(stDesc, sizeof(st_perk),"+%i%% %t", RoundToNearest(g_flEfficient_dmgmult*100), "BonusDamageText" );
	}
	else if (hunterPerk == InfectedHunterPerk_Grasshopper && g_bGrass_enable)
	{
		st_perk = "Hunter: Grasshopper";
		Format(stDesc, sizeof(st_perk), "%t: +%i%%", "GrasshopperDescriptionPanel", RoundToNearest( (g_flGrass_rate - 1) * 100 ) );
	}
	else if (hunterPerk == InfectedHunterPerk_SpeedDemon && g_bSpeedDemon_enable)
	{
		st_perk = "Hunter: Speed Demon";
		Format(stDesc, sizeof(st_perk), "+%i%% %t +%i%% %t", RoundToNearest(g_flSpeedDemon_dmgmult*100), "OldSchoolDescriptionPanel", RoundToNearest( (g_flSpeedDemon_rate - 1) * 100 ), "SpeedDemonDescriptionPanel");
	}
	else
	{
		Format(st_perk, sizeof(st_perk), "Hunter: %t", "NotSet");
		stDesc = "";
	}
	if (g_bInf4_enable)
	{
		menu.DrawItem(st_perk);
		menu.DrawText(stDesc);
	}

	//show inf5 perk
	InfectedJockeyPerkType jockeyPerk = g_ipInf[iCid].jockeyPerk;
	if (jockeyPerk == InfectedJockeyPerk_Wind && g_bWind_enable)
	{
		st_perk = "Jockey: Ride Like the Wind";
		Format(stDesc, sizeof(st_perk), "%t: +%i%%", "RideLikeTheWindDescriptionPanel", RoundToNearest( (g_flWind_rate - 1) * 100 ) );
	}
	else if (jockeyPerk == InfectedJockeyPerk_Cavalier && g_bCavalier_enable)
	{
		st_perk = "Jockey: Cavalier";
		Format(stDesc, sizeof(st_perk), "+%i%% %t", RoundToNearest( g_flCavalier_hpmult * 100 ), "UnbreakableHint" );
	}
	else if (jockeyPerk == InfectedJockeyPerk_Frogger && g_bFrogger_enable)
	{
		st_perk = "Jockey: Frogger";
		Format(stDesc, sizeof(st_perk), "+%i%% %t +%i%% %t", RoundToNearest( (g_flFrogger_rate - 1) * 100 ), "FroggerDescriptionPanel", RoundToNearest(g_flFrogger_dmgmult*100), "BonusDamageText" );
	}
	else if (jockeyPerk == InfectedJockeyPerk_Ghost && g_bGhost_enable)
	{
		st_perk = "Jockey: Ghost Rider";
		Format(stDesc, sizeof(st_perk), "%i%% %t", RoundToNearest( (1 - (g_iGhost_alpha/255.0)) *100 ), "GhostRiderDescriptionPanel" );
	}
	else
	{
		Format(st_perk, 128,"Jockey: %t", "NotSet");
		stDesc = "";
	}

	if (g_bInf5_enable && g_bIsL4D2)
	{
		menu.DrawItem(st_perk);
		menu.DrawText(stDesc);
	}

	//show inf6 perk
	InfectedSpitterPerkType spitterPerk = g_ipInf[iCid].spitterPerk;
	if (spitterPerk == InfectedSpitterPerk_TwinSpitfire && g_bTwinSF_enable)
	{
		st_perk = "Spitter: Twin Spitfire";
		Format(stDesc, sizeof(st_perk), "%t", "TwinSpitfireDescriptionPanel" );
	}
	else if (spitterPerk == InfectedSpitterPerk_MegaAdhesive && g_bMegaAd_enable)
	{
		st_perk = "Spitter: Mega Adhesive";
		Format(stDesc, sizeof(st_perk), "%t", "MegaAdhesiveDescriptionPanel" );
	}
	else
	{
		Format(st_perk, sizeof(st_perk), "Spitter: %t", "NotSet");
		stDesc = "";
	}

	if (g_bInf6_enable && g_bIsL4D2)
	{
		menu.DrawItem(st_perk);
		menu.DrawText(stDesc);
	}

	//show inf7 perk
	InfectedChargerPerkType chargerPerk = g_ipInf[iCid].chargerPerk;
	if (chargerPerk == InfectedChargerPerk_Scatter && g_bScatter_enable)
	{
		st_perk = "Charger: Scattering Ram";
		Format(stDesc, sizeof(st_perk), "%t", "ScatteringRamDescriptionPanel" );
	}
	else if (chargerPerk == InfectedChargerPerk_Bullet && g_bBullet_enable)
	{
		st_perk = "Charger: Speeding Bullet";
		Format(stDesc, sizeof(st_perk), "%t: +%i%%", "SpeedingBulletDescriptionPanel", RoundToNearest(g_flBullet_rate*100 - 100) );
	}
	else
	{
		Format(st_perk, sizeof(st_perk),"Charger: %t", "NotSet");
		stDesc = "";
	}
	if (g_bInf7_enable && g_bIsL4D2)
	{
		menu.DrawItem(st_perk);
		menu.DrawText(stDesc);
	}
	
	//show inf2 perk
	InfectedTankPerkType tankPerk = g_ipInf[iCid].tankPerk;
	if (tankPerk == InfectedTankPerk_AdrenalGlands && g_bAdrenal_enable)
	{
		st_perk = "Tank: Adrenal Glands";
		Format(stDesc, sizeof(st_perk), "%t", "AdrenalGlandsDescriptionPanelShort");
	}
	else if (tankPerk == InfectedTankPerk_Juggernaut && g_bJuggernaut_enable)
	{
		st_perk = "Tank: Juggernaut";
		Format(stDesc, sizeof(st_perk), "+%i %t", g_iJuggernaut_hp, "UnbreakableHint");
	}
	else if (tankPerk == InfectedTankPerk_MetabolicBoost && g_bMetabolic_enable)
	{
		st_perk = "Tank: Metabolic Boost";
		Format(stDesc, sizeof(st_perk), "+%i%% %t", RoundToNearest((g_flMetabolic_speedmult-1)*100), "SpeedDemonDescriptionPanel");
	}
	else if (tankPerk == InfectedTankPerk_Stormcaller && g_bStorm_enable)
	{
		st_perk = "Tank: Storm Caller";
		Format(stDesc, sizeof(st_perk), "%t", "StormCallerDescriptionPanel");
	}
	else if (tankPerk == InfectedTankPerk_DoubleTrouble && g_bDouble_enable)
	{
		st_perk = "Tank: Double the Trouble";
		Format(stDesc, sizeof(st_perk),"%t", "DoubleTroubleDescriptionPanel");
	}
	else
	{
		Format(st_perk, sizeof(st_perk), "Tank: %t", "NotSet");
		stDesc = "";
	}

	if (g_bInf2_enable)
	{
		menu.DrawItem(st_perk);
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
	char st_display[MAXPLAYERS+1];
	char st_current[10];

	Panel menu = CreatePanel();
	menu.SetTitle("tPoncho's Perkmod - Survivor: Primary");

	SurvivorFirstPerkType perkType = g_spSur[client].firstPerk;

	//set name for perk 1
	if (!g_bStopping_enable			&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bStopping_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bStopping_enable_vs	&&	g_L4D_GameMode == GameMode_Versus)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorFirstPerk_StoppingPower ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Stopping Power %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "+%i%% %t", RoundToNearest(g_flStopping_dmgmult*100), "BonusDamageText");
		menu.DrawText(st_display);
	}

	//set name for perk 2
	if (!g_bDT_enable	 		&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bDT_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bDT_enable_vs		&&	g_L4D_GameMode == GameMode_Versus)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorFirstPerk_DoubleTap ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Double Tap %s", st_current);
		menu.DrawItem(st_display);
		
		Format(st_display, sizeof(st_display), "%t +%i%%", "DoubleTapDescriptionPanel", RoundToNearest(100 * ((1/g_flDT_rate)-1) ) );
		menu.DrawText(st_display);

		if (g_flDT_rate_reload < 1.0)
		{
			Format(st_display, sizeof(st_display), "%t +%i%%", "SleighOfHandDescriptionPanel", RoundToNearest(100 * ((1/g_flDT_rate_reload)-1) ) );
			menu.DrawText(st_display);
		}

		Format(st_display, sizeof(st_display), "%t", "DoubleTapRestrictionWarning");
		menu.DrawText(st_display);
	}

	//set name for perk 3
	if (!g_bSoH_enable 			&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bSoH_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bSoH_enable_vs	&&	g_L4D_GameMode == GameMode_Versus)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorFirstPerk_SleightOfHand ? "(CURRENT)" : "");
		
		Format(st_display, sizeof(st_display), "Sleight of Hand %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t +%i%%", "SleighOfHandDescriptionPanel", RoundToNearest(100 * ((1/g_flSoH_rate)-1) ) );
		menu.DrawText(st_display);
	}

	//set name for perk 4
	if (!g_bPyro_enable			&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bPyro_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bPyro_enable_vs	&&	g_L4D_GameMode == GameMode_Versus)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorFirstPerk_Pyrotechnician ? "(CURRENT)" : "");
		
		Format(st_display, sizeof(st_display), "Pyrotechnician %s", st_current);
		menu.DrawItem(st_display);
		Format(st_display, sizeof(st_display), "%t", "PyroDescriptionText1");
		menu.DrawText(st_display);
		Format(st_display, sizeof(st_display), "%t", "PyroDescriptionText2");
		menu.DrawText(st_display);
	}

	return menu;
}

//setting Sur1 perk and returning to top menu
int Menu_ChooseSur1Perk(Menu menu, MenuAction action, int client, int param2)
{
	if (menu != INVALID_HANDLE) CloseHandle(menu);

	if (action == MenuAction_Select)
	{
		if (1 <= param2 <= SurvivorFirstPerk_Count) {
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
	char st_display[MAXPLAYERS+1];
	char st_current[10];

	Panel menu = CreatePanel();
	menu.SetTitle("tPoncho's Perkmod - Survivor: Secondary");

	SurvivorSecondPerkType perkType = g_spSur[client].secondPerk;

	//set name for perk 1
	if (!g_bUnbreak_enable	 		&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bUnbreak_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bUnbreak_enable_vs	&&	g_L4D_GameMode == GameMode_Versus)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorSecondPerk_Unbreakable ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Unbreakable %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "+%i %t", g_iUnbreak_hp, "UnbreakableHint" );
		menu.DrawText(st_display);
	}

	//set name for perk 2
	if (!g_bSpirit_enable	 		&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bSpirit_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bSpirit_enable_vs		&&	g_L4D_GameMode == GameMode_Versus)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorSecondPerk_Spirit ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Spirit %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t", "SpiritDescriptionText" );
		menu.DrawText(st_display);

		int iTime = g_iSpirit_cd;
		if (g_L4D_GameMode == GameMode_Versus)
			iTime=g_iSpirit_cd_vs;
		else if (g_L4D_GameMode == GameMode_Survival)
			iTime=g_iSpirit_cd_sur;

		Format(st_display, sizeof(st_display), "+%i %t: %i min", g_iSpirit_buff, "SpritDescriptionText2", iTime/60);
		menu.DrawText(st_display);
	}

	//set name for perk 3
	if (!g_bHelpHand_enable 		&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bHelpHand_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bHelpHand_enable_vs	&&	g_L4D_GameMode == GameMode_Versus)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorSecondPerk_HelpingHand ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Helping Hand %s", st_current);
		menu.DrawItem(st_display);

		int iBuff = g_iHelpHand_buff;
		if (g_L4D_GameMode == GameMode_Versus)
			iBuff=g_iHelpHand_buff_vs;

		if (g_bHelpHand_convar)
		{
			Format(st_display, sizeof(st_display), "%t +%i", "HelpingHandDescriptionPanel2", iBuff);
			menu.DrawText(st_display);
		}
		else
		{
			Format(st_display, sizeof(st_display), "%t +%i", "HelpingHandDescriptionPanel", iBuff);
			menu.DrawText(st_display);
		}
	
		//set name for perk 4, Martial Artist
		if (!g_bMA_enable	 		&&	g_L4D_GameMode == GameMode_Campaign
			|| !g_bMA_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
			|| !g_bMA_enable_vs		&&	g_L4D_GameMode == GameMode_Versus
			|| !g_bIsL4D2)
		{
			menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
		}
		else
		{
			st_current = (perkType == SurvivorSecondPerk_MartialArtist ? "(CURRENT)" : "");

			Format(st_display, sizeof(st_display), "Martial Artist %s", st_current);
			menu.DrawItem(st_display);

			Format(st_display, sizeof(st_display),"%t", "MartialArtistDescriptionPanel1");
			menu.DrawText(st_display);

			if (g_iMA_maxpenalty < 6)
			{
				Format(st_display, sizeof(st_display), "%t", "MartialArtistDescriptionPanel2");
				menu.DrawText(st_display);
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
		if (1 <= param2 <= SurvivorSecondPerk_Count) {
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
	char st_display[MAXPLAYERS+1];
	char st_current[10];

	Panel menu = CreatePanel();
	menu.SetTitle("tPoncho's Perkmod - Survivor: Tertiary");

	SurvivorThirdPerkType perkType = g_spSur[client].thirdPerk;

	//set name for perk 1
	if (!g_bPack_enable 		&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bPack_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bPack_enable_vs	&&	g_L4D_GameMode == GameMode_Versus)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorThirdPerk_PackRat ? "(CURRENT)" : "");
		
		Format(st_display, sizeof(st_display), "Pack Rat %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t +%i%%", "PackRatDescriptionPanel", RoundToNearest(g_flPack_ammomult*100));
		menu.DrawText(st_display);
	}

	//set name for perk 2
	if (!g_bChem_enable			&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bChem_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bChem_enable_vs	&&	g_L4D_GameMode == GameMode_Versus)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorThirdPerk_ChemReliant ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Chem Reliant %s", st_current);
		menu.DrawItem(st_display);

		if (g_iChem_buff > 0)
		{
			Format(st_display, sizeof(st_display), "%t (+%i)", "ChemReliantDescriptionText", g_iChem_buff);
			menu.DrawText(st_display);
		}
		Format(st_display, sizeof(st_display), "%t", "ChemReliantDescriptionText2");
		menu.DrawText(st_display);
	}

	//set name for perk 3
	if (!g_bHard_enable 		&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bHard_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bHard_enable_vs	&&	g_L4D_GameMode == GameMode_Versus)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorThirdPerk_HardToKill ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Hard to Kill %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t", "HardToKillDescriptionText");
		menu.DrawText(st_display);

		Format(st_display, sizeof(st_display), "+%i%% %t", RoundToNearest(100*g_flHard_hpmult), "HardToKillDescriptionText2" );
		menu.DrawText(st_display);
	}

	//set name for perk 4
	if (!g_bExtreme_enable	 		&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bExtreme_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bExtreme_enable_vs	&&	g_L4D_GameMode == GameMode_Versus)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorThirdPerk_ExtremeConditioning ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Extreme Conditioning %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t: +%i%%", "MartialArtistDescriptionPanelCoop", RoundToNearest(100*g_flExtreme_rate-100) );
		menu.DrawText(st_display);
	}

	//set name for perk 5
	if (!g_bLittle_enable 			&&	g_L4D_GameMode == GameMode_Campaign
		|| !g_bLittle_enable_sur	&&	g_L4D_GameMode == GameMode_Survival
		|| !g_bLittle_enable_vs		&&	g_L4D_GameMode == GameMode_Versus
		|| !g_bIsL4D2)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == SurvivorThirdPerk_LittleLeaguer ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Little Leaguer %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t", "LittleLeaguerDescriptionPanel");
		menu.DrawText(st_display);
	}

	return menu;
}

//setting Sur3 perk and returning to top menu
int Menu_ChooseSur3Perk(Menu menu, MenuAction action, int client, int param2)
{
	if (menu != INVALID_HANDLE) CloseHandle(menu);
	
	if (action == MenuAction_Select)
	{
		if (1 <= param2 <= SurvivorThirdPerk_Count) {
			g_spSur[client].thirdPerk = PM_IntToSurvivorThirdPerkType(param2);
		}
	}

	if (IsClientInGame(client))
		SendPanelToClient(Menu_Top(client), client, Menu_ChooseSubMenu, MENU_TIME_FOREVER);
	
	return 0;
}


//=============================
//	INF1 CHOICE (BOOMER)
//=============================

//build menu for Inf1 Perks
Panel Menu_Inf1Perk(int client)
{
	char st_display[128];
	char st_current[10];

	Panel menu = CreatePanel();
	menu.SetTitle("tPoncho's Perkmod - Boomer");

	InfectedBoomerPerkType perkType = g_ipInf[client].boomerPerk;

	//set name for perk 1
	if (!g_bBarf_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedBoomerPerk_BarfBagged ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Barf Bagged %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t", "BarfBaggedDescriptionPanel");
		menu.DrawText(st_display);
	}

	//set name for perk 2
	if (!g_bBlind_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedBoomerPerk_BlindLuck ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Blind Luck %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t: %i%%", "AcidVomitDescriptionPanel", RoundToNearest(100 - g_flBlind_cdmult*100));
		menu.DrawText(st_display);
	}

	//set name for perk 3
	if (!g_bDead_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedBoomerPerk_DeadWreckening ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Dead Wreckening %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t: +%i%%", "DeadWreckeningDescriptionPanel", RoundToNearest(100*g_flDead_dmgmult));
		menu.DrawText(st_display);
		menu.DrawText("survivors are vomited upon");
	}

	//set name for perk 4
	if (!g_bMotion_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedBoomerPerk_MotionSickness ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Motion Sickness %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t", "MotionSicknessDescriptionPanel");
		menu.DrawText(st_display);
	}

	return menu;
}

//setting Inf1 perk and returning to top menu
int Menu_ChooseInf1Perk(Menu menu, MenuAction action, int client, int param2)
{
	if (menu != INVALID_HANDLE) CloseHandle(menu);
	if (action == MenuAction_Select)
	{
		if (1 <= param2 <= InfectedBoomerPerk_Count) {
			g_ipInf[client].boomerPerk = PM_IntToInfectedBoomerPerkType(param2);
		}
	}

	if (IsClientInGame(client))
		SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);

	return 0;
}

//=============================
//	INF2 CHOICE (TANK)
//=============================

//build menu for Inf2 Perks
Panel Menu_Inf2Perk(int client)
{
	char st_display[MAXPLAYERS+1];
	char st_current[10];

	Panel menu = CreatePanel();
	menu.SetTitle("tPoncho's Perkmod - Tank");

	InfectedTankPerkType perkType = g_ipInf[client].tankPerk;

	//set name for perk 1
	if (!g_bAdrenal_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedTankPerk_AdrenalGlands ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Adrenal Glands %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t: +%i%%", "AdrenalGlandsDescriptionPanel1", RoundToNearest(100 * ((1/g_flAdrenal_punchcdmult)-1) ) );
		menu.DrawText(st_display);

		Format(st_display, sizeof(st_display), "%t: +%i%%", "AdrenalGlandsDescriptionPanel2", RoundToNearest(100 - 100*g_flAdrenal_throwcdmult ) );
		menu.DrawText(st_display);

		Format(st_display, sizeof(st_display), "%t", "AdrenalGlandsDescriptionPanel3" );
		menu.DrawText(st_display);
	}

	//set name for perk 2
	if (!g_bJuggernaut_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedTankPerk_Juggernaut ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Juggernaut %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "+%i %t", g_iJuggernaut_hp, "UnbreakableHint");
		menu.DrawText(st_display);
	}

	//set name for perk 3
	if (!g_bMetabolic_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedTankPerk_MetabolicBoost ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Metabolic Boost %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "+%i%% %t", RoundToNearest((g_flMetabolic_speedmult-1)*100), "SpeedDemonDescriptionPanel");
		menu.DrawText(st_display);
	}

	//set name for perk 4
	if (!g_bStorm_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedTankPerk_Stormcaller ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Storm Caller %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t", "StormCallerDescriptionPanel");
		menu.DrawText(st_display);
	}

	//set name for perk 5
	if (!g_bDouble_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedTankPerk_DoubleTrouble ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Double the Trouble %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t", "DoubleTroubleDescriptionPanel");
		menu.DrawText(st_display);

		Format(st_display, sizeof(st_display), "%t: -%i%%", "DoubleTroubleDescriptionPanel2", RoundToNearest(100 - g_flDouble_hpmult*100));
		menu.DrawText(st_display);
	}

	return menu;
}

//setting Inf2 perk and returning to top menu
int Menu_ChooseInf2Perk(Menu menu, MenuAction action, int client, int param2)
{
	if (menu != INVALID_HANDLE) CloseHandle(menu);
	
	if (action == MenuAction_Select)
	{
		if (1 <= param2 <= InfectedTankPerk_Count) {
			g_ipInf[client].tankPerk = PM_IntToInfectedTankPerkType(param2);
		}
	}

	if (IsClientInGame(client))
		SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);

	return 0;
}

//=============================
//	INF3 CHOICE (SMOKER)
//=============================

//build menu for Inf3 Perks
Panel Menu_Inf3Perk(int client)
{
	char st_display[MAXPLAYERS+1];
	char st_current[10];

	Panel menu = CreatePanel();
	SetPanelTitle(menu, "tPoncho's Perkmod - Smoker");

	InfectedSmokerPerkType perkType = g_ipInf[client].smokerPerk;

	//set name for perk 1
	if (!g_bTongue_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedSmokerPerk_TongueTwister ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Tongue Twister %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t: +%i%%", "TongueTwisterDescriptionPanel1", RoundToNearest(100*(g_flTongue_speedmult-1)) );
		menu.DrawText(st_display);

		Format(st_display, sizeof(st_display), "%t: +%i%%", "TongueTwisterDescriptionPanel2", RoundToNearest(100*(g_flTongue_rangemult-1)) );
		menu.DrawText(st_display);

		Format(st_display, sizeof(st_display), "%t: +%i%%", "TongueTwisterDescriptionPanel3", RoundToNearest(100*(g_flTongue_pullmult-1)) );
		menu.DrawText(st_display);
	}

	//set name for perk 2
	if (!g_bSqueezer_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedSmokerPerk_Squeezer ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Squeezer %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t: +%i%%", "SqueezerDescriptionText", RoundToNearest(g_flSqueezer_dmgmult*100) );
		menu.DrawText(st_display);
	}

	//set name for perk 3
	if (!g_bDrag_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedSmokerPerk_DragAndDrop ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Drag and Drop %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t", "DragAndDropDescriptionPanel" );
		menu.DrawText(st_display);
	}

	//set name for perk 4
	if (!g_bSmokeIt_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedSmokerPerk_SmokeIt ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Olj's Smoke IT! %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t", "SmokeItDescriptionPanel" );
		menu.DrawText(st_display);
	}

	return menu;
}

//setting Inf3 perk and returning to top menu
int Menu_ChooseInf3Perk(Menu menu, MenuAction action, int client, int param2)
{
	if (menu != INVALID_HANDLE) CloseHandle(menu);
	if (action == MenuAction_Select)
	{
		if (1 <= param2 <= InfectedSmokerPerk_Count) {
			g_ipInf[client].smokerPerk = PM_IntToInfectedSmokerPerkType(param2);
		}
	}

	if (IsClientInGame(client))
		SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);

	return 0;
}

//=============================
//	INF4 CHOICE (HUNTER)
//=============================

//build menu for Inf4 Perks
Panel Menu_Inf4Perk(int client)
{
	char st_display[MAXPLAYERS+1];
	char st_current[10];

	Panel menu = CreatePanel();
	menu.SetTitle("tPoncho's Perkmod - Hunter");

	InfectedHunterPerkType perkType = g_ipInf[client].hunterPerk;

	//set name for perk 1
	if (!g_bBody_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{	
		st_current = (perkType == InfectedHunterPerk_BodySlam ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Body Slam %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t %i", "BodySlamDescriptionPanel", g_iBody_minbound);
		menu.DrawText(st_display);
	}

	//set name for perk 2
	if (!g_bEfficient_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedHunterPerk_EfficientKiller ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Efficient Killer %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "+%i%% %t", RoundToNearest(g_flEfficient_dmgmult*100), "BonusDamageText" );
		menu.DrawText(st_display);
	}

	//set name for perk 3
	if (!g_bGrass_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedHunterPerk_Grasshopper ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Grasshopper %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t: +%i%%", "GrasshopperDescriptionPanel", RoundToNearest( (g_flGrass_rate - 1) * 100 ) );
		menu.DrawText(st_display);
	}

	//set name for perk 4
	if (!g_bSpeedDemon_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedHunterPerk_SpeedDemon ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Speed Demon %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "+%i%% %t +%i%% %t", RoundToNearest(g_flSpeedDemon_dmgmult*100), "OldSchoolDescriptionPanel", RoundToNearest( (g_flSpeedDemon_rate - 1) * 100 ), "SpeedDemonDescriptionPanel" );
		menu.DrawText(st_display);
	}

	return menu;
}

//setting Inf4 perk and returning to top menu
int Menu_ChooseInf4Perk(Menu menu, MenuAction action, int client, int param2)
{
	if (menu != INVALID_HANDLE) CloseHandle(menu);
	
	if (action == MenuAction_Select)
	{
		if (1 <= param2 <= InfectedHunterPerk_Count) {
			g_ipInf[client].hunterPerk = PM_IntToInfectedHunterPerkType(param2);
		}
	}

	if (IsClientInGame(client))
		SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);

	return 0;
}

//=============================
//	INF5 CHOICE (JOCKEY)
//=============================

//build menu for Inf5 Perks
Panel Menu_Inf5Perk(int client)
{
	char st_display[MAXPLAYERS+1];
	char st_current[10];

	Panel menu = CreatePanel();
	menu.SetTitle("tPoncho's Perkmod - Jockey");

	InfectedJockeyPerkType perkType = g_ipInf[client].jockeyPerk;

	//set name for perk 1
	if (!g_bWind_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedJockeyPerk_Wind ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Ride Like the Wind %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t: +%i%%", "RideLikeTheWindDescriptionPanel", RoundToNearest( (g_flWind_rate - 1) * 100 ) );
		menu.DrawText(st_display);
	}

	//set name for perk 2
	if (!g_bCavalier_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedJockeyPerk_Cavalier ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Cavalier %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "+%i%% %t", RoundToNearest( g_flCavalier_hpmult * 100 ), "UnbreakableHint" );
		menu.DrawText(st_display);
	}

	//set name for perk 3
	if (!g_bFrogger_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedJockeyPerk_Frogger ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Frogger %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "+%i%% %t +%i%% %t", RoundToNearest( (g_flFrogger_rate - 1) * 100 ), "FroggerDescriptionPanel", RoundToNearest(g_flFrogger_dmgmult*100), "BonusDamageText" );
		menu.DrawText(st_display);
	}

	//set name for perk 4
	if (!g_bGhost_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedJockeyPerk_Ghost ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Ghost Rider %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%i%% %t", RoundToNearest( (1 - (g_iGhost_alpha/255.0)) *100 ), "GhostRiderDescriptionPanel" );
		menu.DrawText(st_display);
	}

	return menu;
}

//setting Inf5 perk and returning to top menu
int Menu_ChooseInf5Perk(Menu menu, MenuAction action, int client, int param2)
{
	if (menu != INVALID_HANDLE) CloseHandle(menu);
	
	if (action == MenuAction_Select)
	{
		if (1 <= param2 <= InfectedJockeyPerk_Count) {
			g_ipInf[client].jockeyPerk = PM_IntToInfectedJockeyPerkType(param2);
		}
	}

	if (IsClientInGame(client))
		SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);

	return 0;
}

//=============================
//	INF6 CHOICE (SPITTER)
//=============================

//build menu for Inf6 Perks
Panel Menu_Inf6Perk(int client)
{
	char st_display[MAXPLAYERS+1];
	char st_current[10];

	Panel menu = CreatePanel();
	menu.SetTitle("tPoncho's Perkmod - Spitter");

	InfectedSpitterPerkType perkType = g_ipInf[client].spitterPerk;

	//set name for perk 1
	if (!g_bTwinSF_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedSpitterPerk_TwinSpitfire ? "(CURRENT)": "");

		Format(st_display, sizeof(st_display), "Twin Spitfire %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display),  "%t", "TwinSpitfireDescriptionPanel" );
		menu.DrawText(st_display);
	}

	//set name for perk 2
	if (!g_bMegaAd_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedSpitterPerk_MegaAdhesive ? "(CURRENT)": "");

		Format(st_display, sizeof(st_display), "Mega Adhesive %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display),  "%t: %i%%", "MegaAdhesiveDescriptionPanel", RoundToNearest( 100 - (g_flMegaAd_slow) * 100 ) );
		menu.DrawText(st_display);
	}

	return menu;
}

//setting Inf5 perk and returning to top menu
int Menu_ChooseInf6Perk(Menu menu, MenuAction action, int client, int param2)
{
	if (menu != INVALID_HANDLE) CloseHandle(menu);
	
	if (action == MenuAction_Select)
	{
		if (1 <= param2 <= InfectedSpitterPerk_Count) {
			g_ipInf[client].spitterPerk = PM_IntToInfectedSpitterPerkType(param2);
		}
	}

	if (IsClientInGame(client))
		SendPanelToClient(Menu_Top_Inf(client), client, Menu_ChooseSubMenu_Inf, MENU_TIME_FOREVER);

	return 0;
}

//=============================
//	INF7 CHOICE (CHARGER)
//=============================

//build menu for Inf7 Perks
Panel Menu_Inf7Perk(int client)
{
	char st_display[MAXPLAYERS+1];
	char st_current[10];

	Panel menu = CreatePanel();
	menu.SetTitle("tPoncho's Perkmod - Charger");

	InfectedChargerPerkType perkType = g_ipInf[client].chargerPerk;

	//set name for perk 1
	if (!g_bScatter_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedChargerPerk_Scatter ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Scattering Ram %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "+%i%% %t", RoundToNearest(g_flScatter_hpmult*100), "ScatteringRamDescriptionPanel" );
		menu.DrawText(st_display);
	}

	//set name for perk 2
	if (!g_bBullet_enable)
	{
		menu.DrawItem("disabled", ITEMDRAW_NOTEXT);
	}
	else
	{
		st_current = (perkType == InfectedChargerPerk_Bullet ? "(CURRENT)" : "");

		Format(st_display, sizeof(st_display), "Speeding Bullet %s", st_current);
		menu.DrawItem(st_display);

		Format(st_display, sizeof(st_display), "%t: +%i%%", "SpeedingBulletDescriptionPanel", RoundToNearest(g_flBullet_rate*100 - 100) );
		menu.DrawText(st_display);
	}

	return menu;
}

//setting Inf7 perk and returning to top menu
int Menu_ChooseInf7Perk(Menu menu, MenuAction action, int client, int param2)
{
	if (menu != INVALID_HANDLE) CloseHandle(menu);
	
	if (action == MenuAction_Select)
	{
		if (1 <= param2 <= InfectedChargerPerk_Count) {
			g_ipInf[client].chargerPerk = PM_IntToInfectedChargerPerkType(param2);
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

float constraintedFloat(float value, float min, float max)
{
	if (value < min) return min;
	if (value > max) return max;
	return value;
}

float StringToFloatConstrainted(const char[] strValue, float min, float max)
{
	float value = StringToFloat(strValue);
	return constraintedFloat(value, min, max);
}

int constraintedInt(int value, int min, int max)
{
	if (value < min) return min;
	if (value > max) return max;
	return value;
}

int StringToIntConstrainted(const char[] strValue, int min, int max)
{
	int value = StringToInt(strValue);
	return constraintedInt(value, min, max);
}

int StrinToIntWithOneConstrainted(const char[] strValue, int max) {
	int value = StringToInt(strValue);
	if (value <= 0) return 1;
	if (value > max) return max;
	return value;
}

bool StringToBool(const char[] strValue)
{
	int value = StringToInt(strValue);
	if (value == 0) return false;
	return true;
}

bool StringInsensitiveContains(const char[] lhs, const char[] rhs)
{
	return StrContains(lhs, rhs, false) != -1;
}

bool GameModeCheck(bool main, bool campaign, bool survival, bool versus)
{
	return (main
		&& (campaign 	&& g_L4D_GameMode == GameMode_Campaign)
		|| (survival 	&& g_L4D_GameMode == GameMode_Survival)
		|| (versus 		&& g_L4D_GameMode == GameMode_Versus));
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