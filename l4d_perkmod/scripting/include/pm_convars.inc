#if defined _l4d_perkmod_perk_convars_
#endinput
#endif

#define _l4d_perkmod_perk_convars_

#pragma semicolon 1
#pragma newdecls required

// MARK: - Constants

#define PM_CV_FLAGS (FCVAR_SPONLY | FCVAR_NOTIFY)

enum kConVarEnableType {
	ConVarEnable_None		= 0,
	ConVarEnable_Campaign	= (1 << 0),
	ConVarEnable_Survival	= (1 << 1),
	ConVarEnable_Versus		= (1 << 2),
	ConVarEnable_All		= (ConVarEnable_Campaign | ConVarEnable_Survival | ConVarEnable_Versus),
}

// MARK: - Variables

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

// MARK: * SUR First persk
//stopping power, damage multiplier
//one-size-fits-all
ConVar g_hStopping_enable;
ConVar g_hStopping_dmgmult;
kConVarEnableType g_iStopping_enable;
float g_flStopping_dmgmult;

//double tap, fire rate
//one-size-fits-all
ConVar g_hDT_enable;
ConVar g_hDT_rate;
ConVar g_hDT_rate_reload;
kConVarEnableType g_iDT_enable;
float g_flDT_rate;
float g_flDT_rate_reload;

//sleight of hand, reload rate
//one-size-fits-all
ConVar g_hSoH_enable;
ConVar g_hSoH_rate;
kConVarEnableType g_iSoH_enable;
float g_flSoH_rate;

//pyrotechnician
ConVar g_hPyro_enable;
ConVar g_hPyro_maxticks;
kConVarEnableType g_iPyro_enable;
int g_iPyro_maxticks;

// MARK: * SUR Second perks
//unbreakable, bonus hp
//one-size-fits-all
ConVar g_hUnbreak_enable;
ConVar g_hUnbreak_hp;
kConVarEnableType g_iUnbreak_enable;
int g_iUnbreak_hp;

//spirit, bonus buffer and cooldown
//campaign, survival, versus
ConVar g_hSpirit_enable;
ConVar g_hSpirit_buff;
ConVar g_hSpirit_cd;
ConVar g_hSpirit_cd_sur;
ConVar g_hSpirit_cd_vs;
kConVarEnableType g_iSpirit_enable;
int g_iSpirit_buff;
int g_iSpirit_cd;
int g_iSpirit_cd_sur;
int g_iSpirit_cd_vs;

//helping hand, bonus buffer and time multiplier
//versus, non-versus
ConVar g_hHelpHand_enable;
ConVar g_hHelpHand_convar;
ConVar g_hHelpHand_timemult;
ConVar g_hHelpHand_buff;
ConVar g_hHelpHand_buff_vs;
kConVarEnableType g_iHelpHand_enable;
bool g_bHelpHand_convar;
float g_flHelpHand_timemult;
int g_iHelpHand_buff;
int g_iHelpHand_buff_vs;

//martial artist, movement rate
//campaign, non-campaign
ConVar g_hMA_enable;
ConVar g_hMA_maxpenalty;
kConVarEnableType g_iMA_enable;
int g_iMA_maxpenalty;

// MARK: * SUR Third perks
//pack rat, bonus ammo multiplier
//one-size-fits-all
ConVar g_hPack_enable;
ConVar g_hPack_ammomult;
kConVarEnableType g_iPack_enable;
float g_flPack_ammomult;

//chem reliant, bonus buffer
//one-size-fits-all
ConVar g_hChem_enable;
ConVar g_hChem_buff;
kConVarEnableType g_iChem_enable;
int g_iChem_buff;

//hard to kill, hp multiplier
//one-size-fits-all
ConVar g_hHard_enable;
ConVar g_hHard_hpmult;
kConVarEnableType g_iHard_enable;
float g_flHard_hpmult;

//extreme conditioning, movement rate
//campaign, non-campaign
ConVar g_hExtreme_enable;
ConVar g_hExtreme_rate;
kConVarEnableType g_iExtreme_enable;
float g_flExtreme_rate;

//little leaguer
ConVar g_hLittle_enable;
kConVarEnableType g_iLittle_enable;

// MARK: * INF Smoker perks
//tongue twister, multipliers for tongue speed, pull speed, range
//one-size-fits-all
ConVar g_hTongue_enable;
ConVar g_hTongue_speedmult;
ConVar g_hTongue_pullmult;
ConVar g_hTongue_rangemult;
kConVarEnableType g_bTongue_enable;
float g_flTongue_speedmult;
float g_flTongue_pullmult;
float g_flTongue_rangemult;

//squeezer, bonus damage
//normal, hard, expert
//*used by bots in all modes
ConVar g_hSqueezer_enable;
ConVar g_hSqueezer_dmgmult;
kConVarEnableType g_bSqueezer_enable;
float g_flSqueezer_dmgmult;

//drag and drop, cooldown mult;
//one-size-fits-all
ConVar g_hDrag_enable;
ConVar g_hDrag_cdmult;
kConVarEnableType g_bDrag_enable;
float g_flDrag_cdmult;

//smoke it
ConVar g_hSmokeIt_enable;
ConVar g_hSmokeItSpeed;
ConVar g_hSmokeItMaxRange;
Handle g_hSmokeItTimer[MAXPLAYERS+1] = {null};
kConVarEnableType g_bSmokeIt_enable;
float g_flSmokeItSpeed;
bool g_bSmokeItGrabbed[MAXPLAYERS+1] = {false};
int g_iSmokeItMaxRange;

// MARK: * INF Boomer perks
//barf bagged
ConVar g_hBarf_enable;
kConVarEnableType g_iBarf_enable;

//blind luck, cooldown multiplier
//one-size-fits-all
ConVar g_hBlind_enable;
ConVar g_hBlind_cdmult;
kConVarEnableType g_iBlind_enable;
float g_flBlind_cdmult;

//dead wreckening, damage multiplier
//one-size-fits-all
ConVar g_hDead_enable;
ConVar g_hDead_dmgmult;
kConVarEnableType g_bDead_enable;
float g_flDead_dmgmult;

//motion sickness
//one-size-fits-all
ConVar g_hMotion_enable;
ConVar g_hMotion_rate;
kConVarEnableType g_bMotion_enable;
float g_flMotion_rate;

// MARK: * INF Hunter perks
//body slam, minbound
//one-size-fits-all
ConVar g_hBody_enable;
ConVar g_hBody_minbound;
kConVarEnableType g_bBody_enable;
int g_iBody_minbound;

//efficient killer, bonus damage
//normal, hard, expert
//*used by bots in all modes
ConVar g_hEfficient_enable;
ConVar g_hEfficient_dmgmult;
kConVarEnableType g_bEfficient_enable;
float g_flEfficient_dmgmult;

//grasshopper, speed multiplier
//one-size-fits-all
ConVar g_hGrass_enable;
ConVar g_hGrass_rate;
kConVarEnableType g_bGrass_enable;
float g_flGrass_rate;

//speed demon, speed multiplier
//one-size-fits-all
ConVar g_hSpeedDemon_enable;
ConVar g_hSpeedDemon_rate;
ConVar g_hSpeedDemon_dmgmult;
kConVarEnableType g_bSpeedDemon_enable;
float g_flSpeedDemon_rate;
float g_flSpeedDemon_dmgmult;

// MARK: * INF Spitter perks
//twin spitfire, time delay between two shots
//one-size-fits-all
ConVar g_hTwinSF_enable;
ConVar g_hTwinSF_delay;
kConVarEnableType g_bTwinSF_enable;
float g_flTwinSF_delay;

//mega adhesive, slow multiplier
//one-size-fits-all
ConVar g_hMegaAd_enable;
ConVar g_hMegaAd_slow;
kConVarEnableType g_bMegaAd_enable;
float g_flMegaAd_slow;

// MARK: * INF Jockey perks
//ride like the wind, runspeed multiplier
//one-size-fits-all
ConVar g_hWind_enable;
ConVar g_hWind_rate;
kConVarEnableType g_bWind_enable;
float g_flWind_rate;

//cavalier, hp multiplier
ConVar g_hCavalier_enable;
ConVar g_hCavalier_hpmult;
kConVarEnableType g_bCavalier_enable;
float g_flCavalier_hpmult;

//frogger, dmg multiplier, leap multiplier
ConVar g_hFrogger_enable;
ConVar g_hFrogger_dmgmult;
ConVar g_hFrogger_rate;
kConVarEnableType g_bFrogger_enable;
float g_flFrogger_dmgmult;
float g_flFrogger_rate;

//ghost rider, invis amount
ConVar g_hGhost_enable;
ConVar g_hGhost_alpha;
kConVarEnableType g_bGhost_enable;
int g_iGhost_alpha;

// MARK: * INF Charger perks
//scattering ram, charge force multiplier and maximum cooldown
//one-size-fits-all
ConVar g_hScatter_enable;
ConVar g_hScatter_force;
ConVar g_hScatter_hpmult;
kConVarEnableType g_bScatter_enable;
float g_flScatter_force;
float g_flScatter_hpmult;

//speeding bullet, charge moverate
ConVar g_hBullet_enable;
ConVar g_hBullet_rate;
kConVarEnableType g_bBullet_enable;
float g_flBullet_rate;

// MARK: * INF Tank perks
//adrenal glands, multipliers for punch cooldown,
//throw rock cooldown, and rock travel speed
//one-size-fits-all
ConVar g_hAdrenal_enable;
ConVar g_hAdrenal_punchcdmult;
ConVar g_hAdrenal_throwcdmult;
kConVarEnableType g_bAdrenal_enable;
float g_flAdrenal_punchcdmult;
float g_flAdrenal_throwcdmult;

//juggernaut, bonus health
//one-size-fits-all
ConVar g_hJuggernaut_enable;
ConVar g_hJuggernaut_hp;
kConVarEnableType g_bJuggernaut_enable;
int g_iJuggernaut_hp;

//metabolic boost, speed multiplier
//one-size-fits-all
ConVar g_hMetabolic_enable;
ConVar g_hMetabolic_speedmult;
kConVarEnableType g_bMetabolic_enable;
float g_flMetabolic_speedmult;

//storm caller, mobs spawned
//one-size-fits-all
ConVar g_hStorm_enable;
ConVar g_hStorm_mobcount;
kConVarEnableType g_bStorm_enable;
int g_iStorm_mobcount;

//double the trouble, health multiplier
//one-size-fits-all
ConVar g_hDouble_enable;
ConVar g_hDouble_hpmult;
kConVarEnableType g_iDouble_enable;
float g_flDouble_hpmult;

//BOT CONTROLLER VARS
//these track the server's preference
//for what perks bots should use
ConVar g_hBot_Sur1;
ConVar g_hBot_Sur2;
ConVar g_hBot_Sur3;
ConVar g_hBot_inf_smoker;
ConVar g_hBot_inf_boomer;
ConVar g_hBot_inf_hunter;
ConVar g_hBot_inf_spitter;
ConVar g_hBot_inf_jockey;
ConVar g_hBot_inf_charger;
ConVar g_hBot_inf_tank;

//DEFAULT PERKS
//These vars track the server's
//given default perks, to account
//for disabling perks

//sur1
ConVar g_hSur1_default;
int g_iSur1_default;
ConVar g_hSur2_default;
int g_iSur2_default;
ConVar g_hSur3_default;
int g_iSur3_default;

// Infected
ConVar g_hInfSmoker_default;
int g_iInfSmoker_default;
ConVar g_hInfBoomer_default;
int g_iInfBoomer_default;
ConVar g_hInfHunter_default;
int g_iInfHunter_default;
ConVar g_hInfSpitter_default;
int g_iInfSpitter_default;
ConVar g_hInfJockey_default;
int g_iInfJockey_default;
ConVar g_hInfCharger_default;
int g_iInfCharger_default;
ConVar g_hInfTank_default;
int g_iInfTank_default;

//PERK TREES AVAILABILITY
//option for servers to completely
//disable entire perk trees
ConVar g_hSur1_enable;
ConVar g_hSur2_enable;
ConVar g_hSur3_enable;
bool g_bSur1_enable;
bool g_bSur2_enable;
bool g_bSur3_enable;

ConVar g_hInfSmoker_enable;
ConVar g_hInfBoomer_enable;
ConVar g_hInfHunter_enable;
ConVar g_hInfSpitter_enable;
ConVar g_hInfJockey_enable;
ConVar g_hInfCharger_enable;
ConVar g_hInfTank_enable;
bool g_bInfSmoker_enable;
bool g_bInfBoomer_enable;
bool g_bInfHunter_enable;
bool g_bInfSpitter_enable;
bool g_bInfJockey_enable;
bool g_bInfCharger_enable;
bool g_bInfTank_enable;

//PERK HIERARCHY AVAILABILITY
//option for servers to completely
//disable perks for infected or survivors
ConVar g_hSurAll_enable;
ConVar g_hInfAll_enable;
bool g_bSurAll_enable;
bool g_bInfAll_enable;

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

//controls whether menu automatically shows
ConVar g_hMenuAutoShow_enable;

// MARK: - Main method

void CreateConvars()
{
    // Sur: First Perks
    CreateConvarsSurStopingPower();
    CreateConvarsSurDoubleTap();
    CreateConvarsSurSleightOfHand();
    CreateConvarsSurPyrotechnician();

    // Sur: Second Perks
    CreateConvarsSurUnbreakable();
    CreateConvarsSurSpirit();
    CreateConvarsSurHelpingHand();
    CreateConvarsSurMartialArtist();

    // Sur: Third Perks
    CreateConvarsSurPackRat();
    CreateConvarsSurChemReliant();
    CreateConvarsSurHardToKill();
    CreateConvarsSurExtremeConditioning();
    CreateConvarsSurLittleLeaguer();

	// Inf: Smoker
	CreateConvarsInfSmokerTongueTwister();
	CreateConvarsInfSmokerSqueezer();
	CreateConvarsInfSmokerDragAndDrop();
	CreateConvarsInfSmokerSmokeIt();

	// Inf: Boomer
	CreateConvarsInfBoomerBarfBagged();
	CreateConvarsInfBoomerBlindLuck();
	CreateConvarsInfBoomerDeadWreckening();
	CreateConvarsInfBoomerMotionSickness();

	// Inf: Hunter
	CreateConvarsInfHunterBodySlam();
	CreateConvarsInfHunterEfficientKiller();
	CreateConvarsInfHunterGrasshopper();
	CreateConvarsInfHunterSpeedDemon();

	// Inf: Spitter
	CreateConvarsInfSpitterTwinSpitfire();
	CreateConvarsInfSpitterMegaAdhesive();

	// Inf: Jockey
	CreateConvardInfJockeyWind();
	CreateConvardInfJockeyCavalier();
	CreateConvardInfJockeyFrogger();
	CreateConvardInfJockeyGhost();

	// Inf: Charger
	CreateConvardInfChargerScatter();
	CreateConvardInfChargerBullet();

	// Inf: Tank
	CreateConvarsInfTankAdrenalGlands();
	CreateConvarsInfTankJuggernaut();
	CreateConvarsInfTankMetabolicBoost();
	CreateConvarsInfTankStormcaller();
	CreateConvarsInfTankDoubleTrouble();

	// Bot preferences for perks
	CreateConvarsBotPreferences();

	// Default perks
	CreateConvarsDefaultPerks();

	// Perk tree
	CreateConvarsPerkTree();

	// Perk Hierarchy
	CreateConvarsPerkHierarchy();

	// Random perks
	CreateConvarsRandomPerks();

	// Misc 
	CreateConvarsMisc();
}

// #region - Sur: First Perks

static void CreateConvarsSurStopingPower()
{
	g_hStopping_dmgmult = CreateConVar(
		"l4d_perkmod_stoppingpower_damagemultiplier",
		"0.2",
		"Stopping Power perk: Bonus damage multiplier, ADDED to base damage (clamped between 0.05 < 1.0)",
		PM_CV_FLAGS);
	g_hStopping_dmgmult.AddChangeHook(Convar_Stopping);
	g_flStopping_dmgmult = 0.2;

	g_hStopping_enable = CreateConVar(
		"l4d_perkmod_stoppingpower_enable",
		"7",
		"Stopping Power perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hStopping_enable.AddChangeHook(Convar_Stopping_en);
	g_iStopping_enable = ConVarEnable_All;
}

static void CreateConvarsSurDoubleTap()
{
	g_hDT_rate = CreateConVar(
		"l4d_perkmod_doubletap_rate",
		"0.6667",
		"Double Tap perk: The interval between bullets fired is multiplied by this value. NOTE: a short enough interval will make the gun fire at only normal speed! (clamped between 0.2 < 0.9)",
		PM_CV_FLAGS);
	g_hDT_rate.AddChangeHook(Convar_DT);
	g_flDT_rate = 0.6667;

	g_hDT_rate_reload = CreateConVar(
		"l4d_perkmod_doubletap_rate_reload",
		"1.0",
		"Double Tap perk: The interval incurred by reloading is multiplied by this value (clamped between 0.2 < 1.0)",
		PM_CV_FLAGS);
	g_hDT_rate_reload.AddChangeHook(Convar_DT_rate_reload);
	g_flDT_rate_reload = 0.8;

	g_hDT_enable = CreateConVar(
		"l4d_perkmod_doubletap_enable",
		"7",
		"Double Tap perk: Allows the perk to be chosen by players in campaign. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hDT_enable.AddChangeHook(Convar_DT_en);
	g_iDT_enable = ConVarEnable_All;
}

static void CreateConvarsSurSleightOfHand()
{
	g_hSoH_rate = CreateConVar(
		"l4d_perkmod_sleightofhand_rate",
		"0.5714",
		"Sleight of Hand perk: The interval incurred by reloading is multiplied by this value (clamped between 0.2 < 0.9)",
		PM_CV_FLAGS);
	g_hSoH_rate.AddChangeHook(Convar_SoH);
	g_flSoH_rate = 0.5714;

	g_hSoH_enable = CreateConVar(
		"l4d_perkmod_sleightofhand_enable",
		"7",
		"Sleight of Hand perk: Allows the perk to be chosen by players in campaign. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hSoH_enable.AddChangeHook(Convar_SoH_en);
	g_iSoH_enable = ConVarEnable_All;
}

static void CreateConvarsSurPyrotechnician()
{
	g_hPyro_maxticks = CreateConVar(
		"l4d_perkmod_pyrotechnician_maxticks",
		"60",
		"Pyrotechnician perk: The number of ticks (a tick is 2s) before giving a survivor a pipe bomb, ie. 60 ticks = 120 seconds. Clamped between 0 < 300, where 0 disables this feature.",
		PM_CV_FLAGS);
	g_hPyro_maxticks.AddChangeHook(Convar_Pyro);
	g_iPyro_maxticks = 60;

	g_hPyro_enable = CreateConVar(
		"l4d_perkmod_pyrotechnician_enable",
		"7",
		"Pyrotechnician perk: Allows the perk to be chosen by players in campaign. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hPyro_enable.AddChangeHook(Convar_Pyro_en);
	g_iPyro_enable = ConVarEnable_All;
}
// #endregion

// #region - Sur: Second Perks

static void CreateConvarsSurUnbreakable()
{
	g_hUnbreak_hp = CreateConVar(
		"l4d_perkmod_unbreakable_bonushealth",
		"20",
		"Unbreakable perk: Bonus health given for Unbreakable; this value is also given as bonus health buffer on being revived (clamped between 1 < 100)",
		PM_CV_FLAGS);
	g_hUnbreak_hp.AddChangeHook(Convar_Unbreak);
	g_iUnbreak_hp = 20;

	g_hUnbreak_enable = CreateConVar(
		"l4d_perkmod_unbreakable_enable",
		"7",
		"Unbreakable perk: Allows the perk to be chosen by players in campaign. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hUnbreak_enable.AddChangeHook(Convar_Unbreak_en);
	g_iUnbreak_enable = ConVarEnable_All;
}

static void CreateConvarsSurSpirit()
{
	g_hSpirit_buff = CreateConVar(
		"l4d_perkmod_spirit_bonusbuffer",
		"30",
		"Spirit perk: Bonus health buffer on self-revive (clamped between 0 < 170)",
		PM_CV_FLAGS);
	g_hSpirit_buff.AddChangeHook(Convar_SpiritBuff);
	g_iSpirit_buff = 30;

	g_hSpirit_cd = CreateConVar(
		"l4d_perkmod_spirit_cooldown",
		"60",
		"Spirit perk: Cooldown for self-reviving in seconds, campaign (clamped between 1 < 1800)",
		PM_CV_FLAGS);
	g_hSpirit_cd.AddChangeHook(Convar_SpiritCD);
	g_iSpirit_cd = 60;

	g_hSpirit_cd_sur = CreateConVar(
		"l4d_perkmod_spirit_cooldown_sur",
		"60",
		"Spirit perk: Cooldown for self-reviving in seconds, survival (clamped between 1 < 1800)",
		PM_CV_FLAGS);
	g_hSpirit_cd_sur.AddChangeHook(Convar_SpiritCDsur);
	g_iSpirit_cd_sur = 60;

	g_hSpirit_cd_vs = CreateConVar(
		"l4d_perkmod_spirit_cooldown_vs",
		"60",
		"Spirit perk: Cooldown for self-reviving in seconds, versus (clamped between 1 < 1800)",
		PM_CV_FLAGS);
	g_hSpirit_cd_vs.AddChangeHook(Convar_SpiritCDvs);
	g_iSpirit_cd_vs = 60;

	g_hSpirit_enable = CreateConVar(
		"l4d_perkmod_spirit_enable",
		"7",
		"Spirit perk: Allows the perk to be chosen by players in campaign. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hSpirit_enable.AddChangeHook(Convar_Spirit_en);
	g_iSpirit_enable = ConVarEnable_All;
}

static void CreateConvarsSurHelpingHand()
{
	g_hHelpHand_timemult = CreateConVar(
		"l4d_perkmod_helpinghand_timemultiplier",
		"0.6",
		"Helping Hand perk: Time multiplier to revive others with Helping Hand (clamped between 0.01 < 1.0)",
		PM_CV_FLAGS);
	g_hHelpHand_timemult.AddChangeHook(Convar_HelpTime);
	g_flHelpHand_timemult = 0.6;

	g_hHelpHand_buff = CreateConVar(
		"l4d_perkmod_helpinghand_bonusbuffer",
		"15",
		"Helping Hand perk: Bonus health buffer given to allies after reviving them, campaign/survival (clamped between 0 < 170)",
		PM_CV_FLAGS);
	g_hHelpHand_buff.AddChangeHook(Convar_HelpBuff);
	g_iHelpHand_buff = 15;

	g_hHelpHand_buff_vs = CreateConVar(
		"l4d_perkmod_helpinghand_bonusbuffer_vs",
		"10",
		"Helping Hand perk: Bonus health buffer given to allies after reviving them, versus (clamped between 0 < 170)",
		PM_CV_FLAGS);
	g_hHelpHand_buff_vs.AddChangeHook(Convar_HelpBuffvs);
	g_iHelpHand_buff_vs = 10;

	g_hHelpHand_enable = CreateConVar(
		"l4d_perkmod_helpinghand_enable",
		"7",
		"Helping Hand perk: Allows the perk to be chosen by players in campaign. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes (NOTE: This perk normally adjusts the survivor_revive_duration ConVar; disabling this perk will stop the plugin from adjusting this ConVar)",
		PM_CV_FLAGS);
	g_hHelpHand_enable.AddChangeHook(Convar_Help_en);
	g_iHelpHand_enable = ConVarEnable_All;

	g_hHelpHand_convar = CreateConVar(
		"l4d_perkmod_helpinghand_enable_convarchanges",
		"1",
		"Helping Hand perk: This perk normally adjusts the survivor_revive_duration ConVar; setting this to 0 will stop the plugin from adjusting this ConVar",
		PM_CV_FLAGS);
	g_hHelpHand_convar.AddChangeHook(Convar_Help_convar);
	g_bHelpHand_convar = true;
}

static void CreateConvarsSurMartialArtist()
{
	g_hMA_maxpenalty = CreateConVar(
		"l4d_perkmod_martialartist_maximumpenalty",
		"6",
		"Martial Artist perk: The maximum shove penalty applied to survivors. It's Valve's coding, so I don't know what each value exactly translates to, but 6 is the maximum shove penalty (~1.5s)",
		PM_CV_FLAGS);
	g_hMA_maxpenalty.AddChangeHook(Convar_MA_maxpenalty);
	g_iMA_maxpenalty = 6;

	g_hMA_enable = CreateConVar(
		"l4d_perkmod_martialartist_enable",
		"7",
		"Martial Artist perk: Allows the perk to be chosen by players in campaign. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hMA_enable.AddChangeHook(Convar_MA_en);
	g_iMA_enable = ConVarEnable_All;
}
// #endregion

// #region - Sur: Third Perks

static void CreateConvarsSurPackRat()
{
	g_hPack_ammomult = CreateConVar(
		"l4d_perkmod_packrat_ammomultiplier",
		"0.2",
		"Pack Rat perk: Bonus ammo capacity, ADDED to base capacity (clamped between 0.01 < 1.0)",
		PM_CV_FLAGS);
	g_hPack_ammomult.AddChangeHook(Convar_Pack);
	g_flPack_ammomult = 0.2;

	g_hPack_enable = CreateConVar(
		"l4d_perkmod_packrat_enable",
		"7",
		"Pack Rat perk: Allows the perk to be chosen by players in campaign. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hPack_enable.AddChangeHook(Convar_Pack_en);
	g_iPack_enable = ConVarEnable_All;
}

static void CreateConvarsSurChemReliant()
{
	g_hChem_buff = CreateConVar(
		"l4d_perkmod_chemreliant_bonusbuffer",
		"0",
		"Chem Reliant perk: Bonus health buffer given when taking pills (clamped between 0 < 150)",
		PM_CV_FLAGS);
	g_hChem_buff.AddChangeHook(Convar_Chem);
	g_iChem_buff = 0;

	g_hChem_enable = CreateConVar(
		"l4d_perkmod_chemreliant_enable",
		"7",
		"Chem Reliant perk: Allows the perk to be chosen by players in campaign. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hChem_enable.AddChangeHook(Convar_Chem_en);
	g_iChem_enable = ConVarEnable_All;
}

static void CreateConvarsSurHardToKill()
{
	g_hHard_hpmult = CreateConVar(
		"l4d_perkmod_hardtokill_healthmultiplier",
		"0.5",
		"Hard to Kill perk: Bonus incap health multiplier, product is ADDED to base incap health (clamped between 0.01 < 3.0)",
		PM_CV_FLAGS);
	g_hHard_hpmult.AddChangeHook(Convar_Hard);
	g_flHard_hpmult = 0.5;

	g_hHard_enable = CreateConVar(
		"l4d_perkmod_hardtokill_enable",
		"7",
		"Hard to Kill perk: Allows the perk to be chosen by players in campaign. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hHard_enable.AddChangeHook(Convar_Hard_en);
	g_iHard_enable = ConVarEnable_All;
}

static void CreateConvarsSurExtremeConditioning()
{
	g_hExtreme_rate = CreateConVar(
		"l4d_perkmod_extremeconditioning_rate",
		"1.1",
		"Extreme Conditioning perk: Survivor movement is multiplied by this value (clamped between 1.0 < 1.5)",
		PM_CV_FLAGS);
	g_hExtreme_rate.AddChangeHook(Convar_Extreme);
	g_flExtreme_rate = 1.1;

	g_hExtreme_enable = CreateConVar(
		"l4d_perkmod_extremeconditioning_enable",
		"7",
		"Extreme Conditioning perk: Allows the perk to be chosen by players in campaign. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hExtreme_enable.AddChangeHook(Convar_Extreme_en);
	g_iExtreme_enable = ConVarEnable_All;
}

static void CreateConvarsSurLittleLeaguer()
{
	g_hLittle_enable = CreateConVar(
		"l4d_perkmod_littleleaguer_enable",
		"7",
		"Little Leaguer perk: Allows the perk to be chosen by players in campaign. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hLittle_enable.AddChangeHook(Convar_Little_en);
	g_iLittle_enable = ConVarEnable_All;
}
// #endregion

// #region - Inf: Smoker

static void CreateConvarsInfSmokerTongueTwister()
{
	g_hTongue_speedmult = CreateConVar(
		"l4d_perkmod_tonguetwister_speedmultiplier",
		"1.5",
		"Tongue Twister perk: Tongue travel speed before grabbing a survivor; multiplied by this value (clamped between 1.0 < 5.0)",
		PM_CV_FLAGS);
	g_hTongue_speedmult.AddChangeHook(Convar_TongueSpeed);
	g_flTongue_speedmult = 1.5;

	g_hTongue_pullmult = CreateConVar(
		"l4d_perkmod_tonguetwister_pullmultiplier",
		"1.5",
		"Tongue Twister perk: Tongue pull speed after grabbing a survivor; multiplied by this value (clamped between 1.0 < 5.0)",
		PM_CV_FLAGS);
	g_hTongue_pullmult.AddChangeHook(Convar_TonguePull);
	g_flTongue_pullmult = 1.5;

	g_hTongue_rangemult = CreateConVar(
		"l4d_perkmod_tonguetwister_rangemultiplier",
		"1.75",
		"Tongue Twister perk: Tongue range; multiplied by this value (clamped between 1.0 < 5.0)",
		PM_CV_FLAGS);
	g_hTongue_rangemult.AddChangeHook(Convar_TongueRange);
	g_flTongue_rangemult = 1.75;

	g_hTongue_enable = CreateConVar(
		"l4d_perkmod_tonguetwister_enable",
		"7",
		"Tongue Twister perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes (NOTE: This perk normally adjusts the tongue_range, tongue_victim_max_speed and tongue_fly_speed ConVars; disabling this perk will stop the plugin from adjusting these ConVars)",
		PM_CV_FLAGS);
	g_hTongue_enable.AddChangeHook(Convar_Tongue_en);
	g_bTongue_enable = ConVarEnable_All;
}

static void CreateConvarsInfSmokerSqueezer()
{
	g_hSqueezer_dmgmult = CreateConVar(
		"l4d_perkmod_squeezer_damagemultiplier",
		"0.5",
		"Squeezer perk: All base damage is multiplied by this value and then ADDED to base damage (clamped between 0.01 < 4.0)",
		PM_CV_FLAGS);
	g_hSqueezer_dmgmult.AddChangeHook(Convar_Squeezer);
	g_flSqueezer_dmgmult = 0.5;

	g_hSqueezer_enable = CreateConVar(
		"l4d_perkmod_squeezer_enable",
		"7",
		"Squeezer perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hSqueezer_enable.AddChangeHook(Convar_Squeezer_en);
	g_bSqueezer_enable = ConVarEnable_All;
}

static void CreateConvarsInfSmokerDragAndDrop()
{
	g_hDrag_cdmult = CreateConVar(
		"l4d_perkmod_draganddrop_timemultiplier",
		"0.2",
		"Drag and Drop perk: Cooldown is multiplied by this value (clamped between 0.01 < 1.0)",
		PM_CV_FLAGS);
	g_hDrag_cdmult.AddChangeHook(Convar_Drag);
	g_flDrag_cdmult = 0.2;

	g_hDrag_enable = CreateConVar(
		"l4d_perkmod_draganddrop_enable",
		"7",
		"Drag and Drop perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes (NOTE: This perk normally adjusts the tongue_hit_delay and tongue_player_dropping_to_ground_time ConVars; disabling this perk will stop the plugin from adjusting these ConVars)",
		PM_CV_FLAGS);
	g_hDrag_enable.AddChangeHook(Convar_Drag_en);
	g_bDrag_enable = ConVarEnable_All;
}

static void CreateConvarsInfSmokerSmokeIt()
{
	g_hSmokeItSpeed = CreateConVar(
		"l4d_perkmod_smokeit_speed",
		"0.21",
		"Smoke IT! perk: Smoker's speed modifier",
		PM_CV_FLAGS);
	g_hSmokeItSpeed.AddChangeHook(Convar_SmokeIt_speed);
	g_flSmokeItSpeed = 0.21;

	g_hSmokeItMaxRange = CreateConVar(
		"l4d_perkmod_smokeit_tonguestretch",
		"950",
		"Smoke IT! perk: Smoker's max tongue stretch, tongue will be released if beyond this",
		PM_CV_FLAGS);
	g_iSmokeItMaxRange = 950;
	g_hSmokeItMaxRange.AddChangeHook(Convar_SmokeIt_range);

	g_hSmokeIt_enable = CreateConVar(
		"l4d_perkmod_smokeit_enable",
		"7",
		"Smoke IT! perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hSmokeIt_enable.AddChangeHook(Convar_SmokeIt_en);
	g_bSmokeIt_enable = ConVarEnable_All;
}
// #endregion

// #region Inf: Boomer

static void CreateConvarsInfBoomerBarfBagged()
{
	g_hBarf_enable = CreateConVar(
		"l4d_perkmod_barfbagged_enable",
		"7",
		"Barf Bagged perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hBarf_enable.AddChangeHook(Convar_Barf_en);
	g_iBarf_enable = ConVarEnable_All;
}

static void CreateConvarsInfBoomerBlindLuck()
{
	g_hBlind_cdmult = CreateConVar(
		"l4d_perkmod_blindluck_timemultiplier",
		"0.5",
		"Blind Luck perk: Cooldown (default 30s) is multiplied by this value (clamped between 0.01 < 1.0)",
		PM_CV_FLAGS);
	g_hBlind_cdmult.AddChangeHook(Convar_Blind);
	g_flBlind_cdmult = 0.5;

	g_hBlind_enable = CreateConVar(
		"l4d_perkmod_blindluck_enable",
		"7",
		"Blind Luck perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes (NOTE: This perk normally adjusts the z_vomit_interval ConVar; disabling this perk will stop the plugin from adjusting this ConVar)",
		PM_CV_FLAGS);
	g_hBlind_enable.AddChangeHook(Convar_Blind_en);
	g_iBlind_enable = ConVarEnable_All;
}

static void CreateConvarsInfBoomerDeadWreckening()
{
	g_hDead_dmgmult = CreateConVar(
		"l4d_perkmod_deadwreckening_damagemultiplier",
		"0.5",
		"Dead Wreckening perk: Common infected damage is multiplied by this value and ADDED to their base damage (clamped between 0.01 < 4.0)",
		PM_CV_FLAGS);
	g_hDead_dmgmult.AddChangeHook(Convar_Dead);
	g_flDead_dmgmult = 0.5;

	g_hDead_enable = CreateConVar(
		"l4d_perkmod_deadwreckening_enable",
		"7",
		"Dead Wreckening perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hDead_enable.AddChangeHook(Convar_Dead_en);
	g_bDead_enable = ConVarEnable_All;
}

static void CreateConvarsInfBoomerMotionSickness()
{
	g_hMotion_rate = CreateConVar(
		"l4d_perkmod_motionsickness_rate",
		"1.25",
		"Motion Sickness perk: Boomer movement is multiplied by this value (clamped between 1.0 < 4.0)",
		PM_CV_FLAGS);
	g_hMotion_rate.AddChangeHook(Convar_Motion);
	g_flMotion_rate = 1.25;

	g_hMotion_enable = CreateConVar(
		"l4d_perkmod_motionsickness_enable",
		"7",
		"Motion Sickness perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes (NOTE: This perk normally adjusts the z_vomit_fatigue ConVar; disabling this perk will stop the plugin from adjusting this ConVar)",
		PM_CV_FLAGS);
	g_hMotion_enable.AddChangeHook(Convar_Motion_en);
	g_bMotion_enable = ConVarEnable_All;	
}
// #endregion

// #region Inf: Hunter

static void CreateConvarsInfHunterBodySlam()
{
	g_hBody_minbound = CreateConVar(
		"l4d_perkmod_bodyslam_minbound",
		"10",
		"Body Slam perk: Defines the minimum initial damage dealt by a pounce (clamped between 2 < 100)",
		PM_CV_FLAGS);
	g_hBody_minbound.AddChangeHook(Convar_Body);
	g_iBody_minbound = 10;

	g_hBody_enable = CreateConVar(
		"l4d_perkmod_bodyslam_enable",
		"7",
		"Body Slam perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hBody_enable.AddChangeHook(Convar_Body_en);
	g_bBody_enable = ConVarEnable_All;	
}

static void CreateConvarsInfHunterEfficientKiller()
{
	g_hEfficient_dmgmult = CreateConVar(
		"l4d_perkmod_efficientkiller_damagemultiplier",
		"0.2",
		"Efficient Killer perk: All base damage is multiplied by this value and then ADDED to base damage (clamped between 0.01 < 4.0)",
		PM_CV_FLAGS);
	g_hEfficient_dmgmult.AddChangeHook(Convar_Eff);
	g_flEfficient_dmgmult = 0.2;

	g_hEfficient_enable = CreateConVar(
		"l4d_perkmod_efficientkiller_enable",
		"7",
		"Efficient Killer perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hEfficient_enable.AddChangeHook(Convar_Eff_en);
	g_bEfficient_enable = ConVarEnable_All;
}

static void CreateConvarsInfHunterGrasshopper()
{
	g_hGrass_rate = CreateConVar(
		"l4d_perkmod_grasshopper_rate",
		"1.2",
		"Grasshopper perk: Multiplier for pounce speed (clamped between 1.0 < 3.0)",
		PM_CV_FLAGS);
	g_hGrass_rate.AddChangeHook(Convar_Grass);
	g_flGrass_rate = 1.2;

	g_hGrass_enable = CreateConVar(
		"l4d_perkmod_grasshopper_enable",
		"7",
		"Grasshopper perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hGrass_enable.AddChangeHook(Convar_Grass_en);
	g_bGrass_enable = ConVarEnable_All;
}

static void CreateConvarsInfHunterSpeedDemon()
{
	g_hSpeedDemon_rate = CreateConVar(
		"l4d_perkmod_speeddemon_rate",
		"1.4",
		"Speed Demon perk: Multiplier for time rate (clamped between 1.0 < 3.0)",
		PM_CV_FLAGS);
	g_hSpeedDemon_rate.AddChangeHook(Convar_Demon);
	g_flSpeedDemon_rate = 1.4;

	g_hSpeedDemon_dmgmult = CreateConVar(
		"l4d_perkmod_speeddemon_damagemultiplier",
		"0.5",
		"Efficient Killer perk: All base damage is multiplied by this value and then ADDED to base damage (clamped between 0.01 < 4.0)",
		PM_CV_FLAGS);
	g_hSpeedDemon_dmgmult.AddChangeHook(Convar_Demon_dmg);
	g_flSpeedDemon_dmgmult = 0.5;

	g_hSpeedDemon_enable = CreateConVar(
		"l4d_perkmod_speeddemon_enable",
		"7",
		"Speed Demon perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hSpeedDemon_enable.AddChangeHook(Convar_Demon_en);
	g_bSpeedDemon_enable = ConVarEnable_All;
}
// #endregion

// #region Inf: Spitter

static void CreateConvarsInfSpitterTwinSpitfire()
{
	g_hTwinSF_delay = CreateConVar(
		"l4d_perkmod_twinspitfire_delay",
		"6",
		"Twin Spitfire perk: Delay in-between double shots, in seconds (clamped between 0.5 < 20.0)",
		PM_CV_FLAGS);
	g_hTwinSF_delay.AddChangeHook(Convar_TwinSF);
	g_flTwinSF_delay = 6.0;

	g_hTwinSF_enable = CreateConVar(
		"l4d_perkmod_twinspitfire_enable",
		"7",
		"Twin Spitfire perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hTwinSF_enable.AddChangeHook(Convar_TwinSF_en);
	g_bTwinSF_enable = ConVarEnable_All;
}

static void CreateConvarsInfSpitterMegaAdhesive()
{
	g_hMegaAd_enable = CreateConVar(
		"l4d_perkmod_megaadhesive_enable",
		"7",
		"Mega Adhesive perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hMegaAd_enable.AddChangeHook(Convar_MegaAd_en);
	g_bMegaAd_enable = ConVarEnable_All;

	g_hMegaAd_slow = CreateConVar(
		"l4d_perkmod_megaadhesive_slowmultiplier",
		"0.6",
		"Mega Adhesive perk: Survivor run speed is MULTIPLIED DIRECTLY by this value - 0.6 means they run at 60% speed (clamped between 0 < 1.0)",
		PM_CV_FLAGS);
	g_hMegaAd_slow.AddChangeHook(Convar_MegaAd);
	g_flMegaAd_slow = 0.6;
}
// #endregion

// #region Inf: Jockey

static void CreateConvardInfJockeyWind()
{
	g_hWind_rate = CreateConVar(
		"l4d_perkmod_ridelikethewind_rate",
		"1.4",
		"Ride Like the Wind perk: Multiplier for run speed rate (clamped between 1.0 < 3.0)",
		PM_CV_FLAGS);
	g_hWind_rate.AddChangeHook(Convar_Wind);
	g_flWind_rate = 1.4;

	g_hWind_enable = CreateConVar(
		"l4d_perkmod_ridelikethewind_enable",
		"7",
		"Ride Like the Wind perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hWind_enable.AddChangeHook(Convar_Wind_en);
	g_bWind_enable = ConVarEnable_All;
}

static void CreateConvardInfJockeyCavalier()
{
	g_hCavalier_hpmult = CreateConVar(
		"l4d_perkmod_cavalier_healthmultiplier",
		"0.6",
		"Cavalier: Bonus health multiplier, product is ADDED to base health (clamped between 0.01 < 3.0)",
		PM_CV_FLAGS);
	g_hCavalier_hpmult.AddChangeHook(Convar_Cavalier);
	g_flCavalier_hpmult = 0.6;

	g_hCavalier_enable = CreateConVar(
		"l4d_perkmod_cavalier_enable",
		"7",
		"Cavalier perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hCavalier_enable.AddChangeHook(Convar_Cavalier_en);
	g_bCavalier_enable = ConVarEnable_All;
}

static void CreateConvardInfJockeyFrogger()
{
	g_hFrogger_dmgmult = CreateConVar(
		"l4d_perkmod_frogger_damagemultiplier",
		"0.35",
		"Frogger perk: All base damage is multiplied by this value and then ADDED to base damage (clamped between 0.01 < 4.0)",
		PM_CV_FLAGS);
	g_hFrogger_dmgmult.AddChangeHook(Convar_Frogger_dmgmult);
	g_flFrogger_dmgmult = 0.35;

	g_hFrogger_rate = CreateConVar(
		"l4d_perkmod_frogger_rate",
		"1.3",
		"Frogger perk: Multiplier for leap speed (clamped between 1.0 < 3.0)",
		PM_CV_FLAGS);
	g_hFrogger_rate.AddChangeHook(Convar_Frogger_rate);
	g_flFrogger_rate = 1.3;

	g_hFrogger_enable = CreateConVar(
		"l4d_perkmod_frogger_enable",
		"7",
		"Frogger perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hFrogger_enable.AddChangeHook(Convar_Frogger_en);
	g_bFrogger_enable = ConVarEnable_All;
}

static void CreateConvardInfJockeyGhost()
{
	g_hGhost_alpha = CreateConVar(
		"l4d_perkmod_ghostrider_alpha",
		"25",
		"Ghost Rider perk: Sets the alpha level (clamped between 0 total invis < 255 opaque)",
		PM_CV_FLAGS);
	g_hGhost_alpha.AddChangeHook(Convar_Ghost);
	g_iGhost_alpha = 25;

	g_hGhost_enable = CreateConVar(
		"l4d_perkmod_ghostrider_enable",
		"7",
		"Ghost Rider perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hGhost_enable.AddChangeHook(Convar_Ghost_en);
	g_bGhost_enable = ConVarEnable_All;
}
// #endregion

// #region Inf: Charger

static void CreateConvardInfChargerScatter()
{
	g_hScatter_force = CreateConVar(
		"l4d_perkmod_scatteringram_force",
		"1.6",
		"Scattering Ram perk: Direct multiplier to force applied to survivors on charge impact (clamped between 1.0 < 3.0)",
		PM_CV_FLAGS);
	g_hScatter_force.AddChangeHook(Convar_Scatter_force);
	g_flScatter_force = 1.6;

	g_hScatter_hpmult = CreateConVar(
		"l4d_perkmod_scatteringram_healthmultiplier",
		"0.3",
		"Scattering Ram perk: Bonus health multiplier, product is ADDED to base health (clamped between 0.01 < 3.0)",
		PM_CV_FLAGS);
	g_hScatter_hpmult.AddChangeHook(Convar_Scatter_hpmult);
	g_flScatter_hpmult = 0.3;

	g_hScatter_enable = CreateConVar(
		"l4d_perkmod_scatteringram_enable",
		"7",
		"Scattering Ram perk: Allows the perk to be chosen by players. 0=disabled, 1=enabled",
		PM_CV_FLAGS);
	g_hScatter_enable.AddChangeHook(Convar_Scatter_en);
	g_bScatter_enable = ConVarEnable_All;
}

static void CreateConvardInfChargerBullet()
{
	g_hBullet_rate = CreateConVar(
		"l4d_perkmod_speedingbullet_rate",
		"1.5",
		"Speeding Bullet perk: Time rate while charging (clamped between 1.0 < 10.0)",
		PM_CV_FLAGS);
	g_hBullet_rate.AddChangeHook(Convar_Bullet);
	g_flBullet_rate = 1.5;

	g_hBullet_enable = CreateConVar(
		"l4d_perkmod_speedingbullet_enable",
		"7",
		"Speeding Bullet perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hBullet_enable.AddChangeHook(Convar_Bullet_en);
	g_bBullet_enable = ConVarEnable_All;
}
// #endregion

// #region Inf: Tank

static void CreateConvarsInfTankAdrenalGlands()
{
	g_hAdrenal_punchcdmult = CreateConVar(
		"l4d_perkmod_adrenalglands_punchcooldownmultiplier",
		"0.5",
		"Adrenal Glands perk: Cooldown for punching is multiplied by this value (clamped between 0.01 < 1.0)",
		PM_CV_FLAGS);
	g_hAdrenal_punchcdmult.AddChangeHook(Convar_Adrenalpunchcd);
	g_flAdrenal_punchcdmult = 0.5;

	g_hAdrenal_throwcdmult = CreateConVar(
		"l4d_perkmod_adrenalglands_throwcooldownmultiplier",
		"0.4",
		"Adrenal Glands perk: Cooldown for throwing rocks is multiplied by this value (clamped between 0.01 < 1.0)",
		PM_CV_FLAGS);
	g_hAdrenal_throwcdmult.AddChangeHook(Convar_Adrenalthrowcd);
	g_flAdrenal_throwcdmult = 0.4;

	g_hAdrenal_enable = CreateConVar(
		"l4d_perkmod_adrenalglands_enable",
		"7",
		"Adrenal Glands perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes (NOTE: This perk normally adjusts the tank_swing_interval, tank_swing_miss_interval, z_tank_attack_interval, z_tank_throw_interval, and z_tank_throw_force ConVars; disabling this perk will stop the plugin from adjusting these ConVars)",
		PM_CV_FLAGS);
	g_hAdrenal_enable.AddChangeHook(Convar_Adrenal_en);
	g_bAdrenal_enable = ConVarEnable_All;
}

static void CreateConvarsInfTankJuggernaut()
{
	g_hJuggernaut_hp = CreateConVar(
		"l4d_perkmod_juggernaut_health",
		"3000",
		"Juggernaut perk: Bonus health given to tanks; absolute value (clamped between 1 < 99999)",
		PM_CV_FLAGS);
	g_hJuggernaut_hp.AddChangeHook(Convar_Jugg);
	g_iJuggernaut_hp = 3000;

	g_hJuggernaut_enable = CreateConVar(
		"l4d_perkmod_juggernaut_enable",
		"7",
		"Juggernaut perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hJuggernaut_enable.AddChangeHook(Convar_Jugg_en);
	g_bJuggernaut_enable = ConVarEnable_All;
}

static void CreateConvarsInfTankMetabolicBoost()
{
	g_hMetabolic_speedmult = CreateConVar(
		"l4d_perkmod_metabolicboost_speedmultiplier",
		"1.4",
		"Metabolic Boost perk: Run speed multiplier (clamped between 1.01 < 3.0)",
		PM_CV_FLAGS);
	g_hMetabolic_speedmult.AddChangeHook(Convar_Met);
	g_flMetabolic_speedmult = 1.4;

	g_hMetabolic_enable = CreateConVar(
		"l4d_perkmod_metabolicboost_enable",
		"7",
		"Metabolic Boost perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hMetabolic_enable.AddChangeHook(Convar_Met_en);
	g_bMetabolic_enable = ConVarEnable_All;
}

static void CreateConvarsInfTankStormcaller()
{
	g_hStorm_mobcount = CreateConVar(
		"l4d_perkmod_stormcaller_mobcount",
		"3",
		"Storm Caller perk: How many groups of zombies are spawned (clamped between 1 < 10)",
		PM_CV_FLAGS);
	g_hStorm_mobcount.AddChangeHook(Convar_Storm);
	g_iStorm_mobcount = 3;

	g_hStorm_enable = CreateConVar(
		"l4d_perkmod_stormcaller_enable",
		"7",
		"Storm Caller perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hStorm_enable.AddChangeHook(Convar_Storm_en);
	g_bStorm_enable = ConVarEnable_All;
}

static void CreateConvarsInfTankDoubleTrouble()
{
	g_hDouble_hpmult = CreateConVar(
		"l4d_perkmod_doublethetrouble_healthmultiplier",
		"0.35",
		"Double the Trouble: Health multiplier for all tanks spawned under the perk (clamped between 0.1 < 2.0)",
		PM_CV_FLAGS);
	g_hDouble_hpmult.AddChangeHook(Convar_Double);
	g_flDouble_hpmult = 0.35;

	g_hDouble_enable = CreateConVar(
		"l4d_perkmod_doublethetrouble_enable",
		"7",
		"Double the Trouble perk: Allows the perk to be chosen by players. 0=disabled, 1=campaign only, 2=survival only, 4=versus only, 3=campaign+survival, 5=campaign+versus, 6=survival+versus, 7=all modes",
		PM_CV_FLAGS);
	g_hDouble_enable.AddChangeHook(Convar_Double_en);
	g_iDouble_enable = ConVarEnable_All;
}
// #endregion

// #region Bot Preferences

static void CreateConvarsBotPreferences()
{
	g_hBot_Sur1 = CreateConVar(
		"l4d_perkmod_bot_survivor1",
		"1, 2, 3, 4",
		"Bot preferences for Survivor 1 perks: 1 = stopping power, 2 = double tap, 3 = sleight of hand, 4 = pyrotechnician",
		PM_CV_FLAGS);

	g_hBot_Sur2 = CreateConVar(
		"l4d_perkmod_bot_survivor2",
		"1, 2, 3, 4",
		"Bot preferences for Survivor 2 perks: 1 = unbreakable, 2 = spirit, 3 = helping hand, 4 = martial artist",
		PM_CV_FLAGS);

	g_hBot_Sur3 = CreateConVar(
		"l4d_perkmod_bot_survivor3",
		"1, 2, 3",
		"Bot preferences for Survivor 2 perks: 1 = pack rat, 2 = chem reliant, 3 = hard to kill, 4 = extreme conditioning",
		PM_CV_FLAGS);

	g_hBot_inf_smoker = CreateConVar(
		"l4d_perkmod_bot_smoker",
		"1, 2, 3",
		"Bot preferences for smoker perks: 1 = tongue twister, 2 = squeezer, 3 = drag and drop, 3 = smoke it (NOTE: You can select more than one using the format '1, 3, 4', and the game will randomize between your choices)",
		PM_CV_FLAGS);

	g_hBot_inf_boomer = CreateConVar(
		"l4d_perkmod_bot_boomer",
		"1, 2, 3",
		"Bot preferences for boomer perks: 1 = barf bagged, 2 = blind luck, 3 = dead wreckening, 4 = motion sickness (NOTE: You can select more than one using the format '1, 3, 4', and the game will randomize between your choices)",
		PM_CV_FLAGS);

	g_hBot_inf_hunter = CreateConVar(
		"l4d_perkmod_bot_hunter",
		"2, 4",
		"Bot preferences for hunter perks: 1 = body slam, 2 = efficient killer, 3 = grasshopper, 4 = speed demon (NOTE: You can select more than one using the format '1, 3, 4', and the game will randomize between your choices)",
		PM_CV_FLAGS);

	g_hBot_inf_spitter = CreateConVar(
		"l4d_perkmod_bot_spitter",
		"1, 2",
		"Bot preferences for spitter perks: 1 = twin spitfire, 2 = mega adhesive (NOTE: You can select more than one using the format '1, 3, 4', and the game will randomize between your choices)",
		PM_CV_FLAGS);

	g_hBot_inf_jockey = CreateConVar(
		"l4d_perkmod_bot_jockey",
		"1, 2, 3, 4",
		"Bot preferences for jockey perks: 1 = ride like the wind, 2 = cavalier, 3 = frogger, 4 = ghost rider (NOTE: You can select more than one using the format '1, 3, 4', and the game will randomize between your choices)",
		PM_CV_FLAGS);

	g_hBot_inf_charger = CreateConVar(
		"l4d_perkmod_bot_charger",
		"1, 2",
		"Bot preferences for charger perks: 1 = scattering ram, 2 = speeding bullet (NOTE: You can select more than one using the format '1, 3, 4', and the game will randomize between your choices)",
		PM_CV_FLAGS);

	g_hBot_inf_tank = CreateConVar(
		"l4d_perkmod_bot_tank",
		"1, 2, 3, 4, 5",
		"Bot preferences for tank perks: 1 = adrenal glands, 2 = juggernaut, 3 = metabolic boost, 4 = storm caller, 5 = double the trouble (NOTE: You can select more than one using the format '1, 3, 4', and the game will randomize between your choices)",
		PM_CV_FLAGS);
}
// #endregion

// #region Default perks

static void CreateConvarsDefaultPerks()
{
	g_hSur1_default = CreateConVar(
		"l4d_perkmod_default_survivor1",
		"1",
		"Default selected perk for Survivor, Primary: 1 = stopping power, 2 = double tap, 3 = sleight of hand, 4 = pyrotechnician",
		PM_CV_FLAGS);
	g_hSur1_default.AddChangeHook(Convar_Def_Sur1);
	g_iSur1_default = 1;

	g_hSur2_default = CreateConVar(
		"l4d_perkmod_default_survivor2",
		"1",
		"Default selected perk for Survivor, Secondary: 1 = unbreakable, 2 = spirit, 3 = helping hand, 4 = martial artist",
		PM_CV_FLAGS);
	g_hSur2_default.AddChangeHook(Convar_Def_Sur2);
	g_iSur2_default = 1;

	g_hSur3_default = CreateConVar(
		"l4d_perkmod_default_survivor3",
		"1",
		"Default selected perk for Survivor, Secondary: 1 = pack rat, 2 = chem reliant, 3 = hard to kill, 4 = extreme conditioning",
		PM_CV_FLAGS);
	g_hSur3_default.AddChangeHook(Convar_Def_Sur3);
	g_iSur3_default = 1;

	g_hInfSmoker_default = CreateConVar(
		"l4d_perkmod_default_smoker",
		"1",
		"Default selected perk for Smoker: 1 = tongue twister, 2 = squeezer, 3 = drag and drop, 4 = smoke it",
		PM_CV_FLAGS);
	g_hInfSmoker_default.AddChangeHook(Convar_Def_Inf_Smoker);
	g_iInfSmoker_default = 1;

	g_hInfBoomer_default = CreateConVar(
		"l4d_perkmod_default_boomer",
		"1",
		"Default selected perk for Boomer: 1 = barf bagged, 2 = blind luck, 3 = dead wreckening, 4 = motion sickness",
		PM_CV_FLAGS);
	g_hInfBoomer_default.AddChangeHook(Convar_Def_Inf_Boomer);
	g_iInfBoomer_default = 1;

	g_hInfHunter_default = CreateConVar(
		"l4d_perkmod_default_hunter",
		"1",
		"Default selected perk for Hunter: 1 = body slam, 2 = efficient killer, 3 = grasshopper, 4 = speed demon",
		PM_CV_FLAGS);
	g_hInfHunter_default.AddChangeHook(Convar_Def_Inf_Hunter);
	g_iInfHunter_default = 1;

	g_hInfSpitter_default = CreateConVar(
		"l4d_perkmod_default_spitter",
		"1",
		"Default selected perk for Spitter: 1 = twin spitfire, 2 = mega adhesive",
		PM_CV_FLAGS);
	g_hInfSpitter_default.AddChangeHook(Convar_Def_Inf_Spitter);
	g_iInfSpitter_default = 1;

	g_hInfJockey_default = CreateConVar(
		"l4d_perkmod_default_jockey",
		"1",
		"Default selected perk for Jockey: 1 = ride like the wind, 2 = cavalier, 3 = frogger, 4 = ghost rider",
		PM_CV_FLAGS);
	g_hInfJockey_default.AddChangeHook(Convar_Def_Inf_Jockey);
	g_iInfJockey_default = 1;

	g_hInfCharger_default = CreateConVar(
		"l4d_perkmod_default_charger",
		"1",
		"Default selected perk for Charger: 1 = scattering ram, 2 = speeding bullet",
		PM_CV_FLAGS);
	g_hInfCharger_default.AddChangeHook(Convar_Def_Inf_Charger);
	g_iInfCharger_default = 1;

	g_hInfTank_default = CreateConVar(
		"l4d_perkmod_default_tank",
		"2",
		"Default selected perk for Tank: 1 = adrenal glands, 2 = juggernaut, 3 = metabolic boost, 4 = storm caller, 5 = double the trouble",
		PM_CV_FLAGS);
	g_hInfTank_default.AddChangeHook(Convar_Def_Inf_Tank);
	g_iInfTank_default = 2;
}
// #endregion

// #region Perk Tree

static void CreateConvarsPerkTree()
{
	g_hSur1_enable = CreateConVar(
		"l4d_perkmod_perktree_survivor1_enable",
		"1",
		"If set to 1, players will be allowed to select perks from the primary Survivor tree.",
		PM_CV_FLAGS);
	g_hSur1_enable.AddChangeHook(Convar_Sur1_en);
	g_bSur1_enable = true;

	g_hSur2_enable = CreateConVar(
		"l4d_perkmod_perktree_survivor2_enable",
		"1",
		"If set to 1, players will be allowed to select perks from the secondary Survivor tree.",
		PM_CV_FLAGS);
	g_hSur2_enable.AddChangeHook(Convar_Sur2_en);
	g_bSur2_enable = true;

	g_hSur3_enable = CreateConVar(
		"l4d_perkmod_perktree_survivor3_enable",
		"1",
		"If set to 1, players will be allowed to select perks from the tertiary Survivor tree.",
		PM_CV_FLAGS);
	g_hSur3_enable.AddChangeHook(Convar_Sur3_en);
	g_bSur3_enable = true;

	g_hInfSmoker_enable = CreateConVar(
		"l4d_perkmod_perktree_smoker_enable",
		"1",
		"If set to 1, players will be allowed to select perks from the Smoker tree.",
		PM_CV_FLAGS);
	g_hInfSmoker_enable.AddChangeHook(Convar_Inf_Smoker_en);
	g_bInfSmoker_enable = true;

	g_hInfBoomer_enable = CreateConVar(
		"l4d_perkmod_perktree_boomer_enable",
		"1",
		"If set to 1, players will be allowed to select perks from the Boomer tree.",
		PM_CV_FLAGS);
	g_hInfBoomer_enable.AddChangeHook(Convar_Inf_Boomer_en);
	g_bInfBoomer_enable = true;

	g_hInfHunter_enable = CreateConVar(
		"l4d_perkmod_perktree_hunter_enable",
		"1",
		"If set to 1, players will be allowed to select perks from the Hunter tree.",
		PM_CV_FLAGS);
	g_hInfHunter_enable.AddChangeHook(Convar_Inf_Hunter_en);
	g_bInfHunter_enable = true;

	g_hInfSpitter_enable = CreateConVar(
		"l4d_perkmod_perktree_spitter_enable",
		"1",
		"If set to 1, players will be allowed to select perks from the Spitter tree.",
		PM_CV_FLAGS);
	g_hInfSpitter_enable.AddChangeHook(Convar_Inf_Spitter_en);
	g_bInfSpitter_enable = true;

	g_hInfJockey_enable = CreateConVar(
		"l4d_perkmod_perktree_jockey_enable",
		"1",
		"If set to 1, players will be allowed to select perks from the Jockey tree.",
		PM_CV_FLAGS);
	g_hInfJockey_enable.AddChangeHook(Convar_Inf_Jockey_en);
	g_bInfJockey_enable = true;

	g_hInfCharger_enable = CreateConVar(
		"l4d_perkmod_perktree_charger_enable",
		"1",
		"If set to 1, players will be allowed to select perks from the Charger tree.",
		PM_CV_FLAGS);
	g_hInfCharger_enable.AddChangeHook(Convar_Inf_Charger_en);
	g_bInfCharger_enable = true;

	g_hInfTank_enable = CreateConVar(
		"l4d_perkmod_perktree_tank_enable",
		"1",
		"If set to 1, players will be allowed to select perks from the Tank tree.",
		PM_CV_FLAGS);
	g_hInfTank_enable.AddChangeHook(Convar_Inf_Tank_en);
	g_bInfTank_enable = true;
}
// #endregion

// #region Perk Hierarchy

static void CreateConvarsPerkHierarchy()
{
	g_hInfAll_enable = CreateConVar(
		"l4d_perkmod_perktree_infected_enable",
		"1",
		"If set to 1, players will be allowed to select perks as Special Infected (affects ALL perks for SI).",
		PM_CV_FLAGS);
	g_hInfAll_enable.AddChangeHook(Convar_InfAll);
	g_bInfAll_enable = true;

	g_hSurAll_enable = CreateConVar(
		"l4d_perkmod_perktree_survivor_enable",
		"1",
		"If set to 1, players will be allowed to select perks as Survivors (affects ALL perks for Survivors).",
		PM_CV_FLAGS);
	g_hSurAll_enable.AddChangeHook(Convar_SurAll);
	g_bSurAll_enable = true;
}
// #endregion

// #region Random Perks

static void CreateConvarsRandomPerks()
{
	g_hForceRandom = CreateConVar(
		"l4d_perkmod_forcerandomperks",
		"0",
		"If set to 1, players will be assigned random perks at roundstart, and they cannot edit their perks.",
		PM_CV_FLAGS);
	g_hForceRandom.AddChangeHook(Convar_ForceRandom);
	g_bForceRandom = false;

	//enable random perk choice
	g_hRandomEnable = CreateConVar(
		"l4d_perkmod_randomperks_enable",
		"1",
		"If set to 1, players will be allowed to randomize their perks at roundstart. Otherwise, they can only customize their perks or use default perks.",
		PM_CV_FLAGS);
	g_hRandomEnable.AddChangeHook(Convar_Random_en);
	g_bRandomEnable = true;
}
// #endregion

// #region Misk Convars

static void CreateConvarsMisc()
{
	g_hMenuAutoShow_enable = CreateConVar(
		"l4d_perkmod_autoshowmenu",
		"1",
		"If set to 1, the perks menu will automatically be shown at the start of every round.",
		FCVAR_SPONLY|FCVAR_NOTIFY);
}
// #endregion

// MARK: - Handle methods

// stopping power
static void Convar_Stopping(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flStopping_dmgmult = StringToFloatConstrainted(newValue, 0.05, 1.0);
}

static void Convar_Stopping_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iStopping_enable = StringToConVarEnable(newValue);
	Stopping_RunChecks();
}

// double tap
static void Convar_DT(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flDT_rate = StringToFloatConstrainted(newValue, 0.02, 0.9);
}

static void Convar_DT_rate_reload(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flDT_rate_reload = StringToFloatConstrainted(newValue, 0.2, 1.0);
}

static void Convar_DT_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iDT_enable = StringToConVarEnable(newValue);
	DT_RunChecks();
}

// sleight of hand
static void Convar_SoH(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flSoH_rate = StringToFloatConstrainted(newValue, 0.02, 0.9);
}

static void Convar_SoH_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSoH_enable = StringToConVarEnable(newValue);
}

//pyrotechnician
static void Convar_Pyro(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iPyro_maxticks = StringToIntConstrainted(newValue, 0, 300);
}

static void Convar_Pyro_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iPyro_enable = StringToConVarEnable(newValue);
}

//unbreakable
static void Convar_Unbreak(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iUnbreak_hp = StringToIntConstrainted(newValue, 1, 100);
}

static void Convar_Unbreak_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iUnbreak_enable = StringToConVarEnable(newValue);
}

//spirit
static void Convar_SpiritBuff(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSpirit_buff = StringToIntConstrainted(newValue, 0, 170);
}

static void Convar_SpiritCD(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSpirit_cd = StringToIntConstrainted(newValue, 1, 1800);
}

static void Convar_SpiritCDsur(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSpirit_cd_sur = StringToIntConstrainted(newValue, 1, 1800);
}

static void Convar_SpiritCDvs(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSpirit_cd_vs = StringToIntConstrainted(newValue, 1, 1800);
}

static void Convar_Spirit_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSpirit_enable = StringToConVarEnable(newValue);
}

//helping hand
static void Convar_HelpTime(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flHelpHand_timemult = StringToFloatConstrainted(newValue, 0.01, 1.0);
}

static void Convar_HelpBuff(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iHelpHand_buff = StringToIntConstrainted(newValue, 1, 170);
}

static void Convar_HelpBuffvs(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iHelpHand_buff_vs = StringToIntConstrainted(newValue, 1, 170);
}

static void Convar_Help_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iHelpHand_enable = StringToConVarEnable(newValue);
}

static void Convar_Help_convar(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bHelpHand_convar = StringToBool(newValue);
}

//martial artist
static void Convar_MA_maxpenalty(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iMA_maxpenalty = StringToIntConstrainted(newValue, 0, 6);
	MA_Rebuild();
}

static void Convar_MA_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iMA_enable = StringToConVarEnable(newValue);
}

//pack rat
static void Convar_Pack(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flPack_ammomult = StringToFloatConstrainted(newValue, 0.01, 1.0);
}

static void Convar_Pack_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iPack_enable = StringToConVarEnable(newValue);
}

//chem reliant
static void Convar_Chem(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iChem_buff = StringToIntConstrainted(newValue, 0, 150);
}

static void Convar_Chem_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iChem_enable = StringToConVarEnable(newValue);
}

//hard to kill
static void Convar_Hard(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flHard_hpmult = StringToFloatConstrainted(newValue, 0.01, 3.0);
}

static void Convar_Hard_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iHard_enable = StringToConVarEnable(newValue);
}

//extreme conditioning
static void Convar_Extreme(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flExtreme_rate = StringToFloatConstrainted(newValue, 1.0, 1.5);
	Extreme_Rebuild();
}

static void Convar_Extreme_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iExtreme_enable = StringToConVarEnable(newValue);
}

//little leaguer
static void Convar_Little_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iLittle_enable = StringToConVarEnable(newValue);
}

//tongue twister
static void Convar_TongueSpeed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flTongue_speedmult = StringToFloatConstrainted(newValue, 1.0, 5.0);
}

static void Convar_TonguePull(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flTongue_pullmult = StringToFloatConstrainted(newValue, 1.0, 5.0);
}

static void Convar_TongueRange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flTongue_rangemult = StringToFloatConstrainted(newValue, 1.0, 5.0);
}

static void Convar_Tongue_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bTongue_enable = StringToConVarEnable(newValue);
}

//squeezer
static void Convar_Squeezer(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flSqueezer_dmgmult = StringToFloatConstrainted(newValue, 0.1, 4.0);
}

static void Convar_Squeezer_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSqueezer_enable = StringToConVarEnable(newValue);
}

//drag and drop
static void Convar_Drag(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flDrag_cdmult = StringToFloatConstrainted(newValue, 0.01, 1.0);
}

static void Convar_Drag_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bDrag_enable = StringToConVarEnable(newValue);
}

//smoke it
static void Convar_SmokeIt_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSmokeIt_enable = StringToConVarEnable(newValue);
}

static void Convar_SmokeIt_range(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSmokeItMaxRange = StringToInt(newValue);
}

static void Convar_SmokeIt_speed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flSmokeItSpeed = StringToFloat(newValue);
}

//barf bagged
static void Convar_Barf_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iBarf_enable = StringToConVarEnable(newValue);
}

//blind luck
static void Convar_Blind(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flBlind_cdmult = StringToFloatConstrainted(newValue, 0.01, 1.0);
}

static void Convar_Blind_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iBlind_enable = StringToConVarEnable(newValue);
}

//dead wreckening
static void Convar_Dead(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flDead_dmgmult = StringToFloatConstrainted(newValue, 0.01, 4.0);
}

static void Convar_Dead_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bDead_enable = StringToConVarEnable(newValue);
}

//motion sickness
static void Convar_Motion(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flMotion_rate = StringToFloatConstrainted(newValue, 1.0, 4.0);
}

static void Convar_Motion_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bMotion_enable = StringToConVarEnable(newValue);
}

//body slam
static void Convar_Body(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iBody_minbound = StringToIntConstrainted(newValue, 2, 100);
}

static void Convar_Body_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bBody_enable = StringToConVarEnable(newValue);
}

//efficient killer
static void Convar_Eff(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flEfficient_dmgmult = StringToFloatConstrainted(newValue, 0.1, 4.0);
}

static void Convar_Eff_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bEfficient_enable = StringToConVarEnable(newValue);
}

//grasshopper
static void Convar_Grass(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flGrass_rate = StringToFloatConstrainted(newValue, 1.0, 3.0);
}

static void Convar_Grass_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bGrass_enable = StringToConVarEnable(newValue);
}

//speed demon
static void Convar_Demon (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flSpeedDemon_rate = StringToFloatConstrainted(newValue, 1.0, 3.0);
}

static void Convar_Demon_dmg (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flSpeedDemon_dmgmult = StringToFloatConstrainted(newValue, 0.1, 4.0);
}

static void Convar_Demon_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSpeedDemon_enable = StringToConVarEnable(newValue);
}

//twin spitfire
static void Convar_TwinSF (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flTwinSF_delay = StringToFloatConstrainted(newValue, 0.5, 20.0);
}

static void Convar_TwinSF_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bTwinSF_enable = StringToConVarEnable(newValue);
}

//mega adhesive
static void Convar_MegaAd_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bMegaAd_enable = StringToConVarEnable(newValue);
}

static void Convar_MegaAd (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flMegaAd_slow = StringToFloatConstrainted(newValue, 0.0, 3.0);
}

//ride like the wind
static void Convar_Wind (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flWind_rate = StringToFloatConstrainted(newValue, 1.0, 3.0);
}

static void Convar_Wind_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bWind_enable = StringToConVarEnable(newValue);
}

//cavalier
static void Convar_Cavalier (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flCavalier_hpmult = StringToFloatConstrainted(newValue, 0.0, 3.0);
}

static void Convar_Cavalier_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bCavalier_enable = StringToConVarEnable(newValue);
}

//frogger
static void Convar_Frogger_dmgmult (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flFrogger_dmgmult = StringToFloatConstrainted(newValue, 0.0, 3.0);
}

static void Convar_Frogger_rate (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flFrogger_rate = StringToFloatConstrainted(newValue, 1.0, 3.0);
}

static void Convar_Frogger_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bFrogger_enable = StringToConVarEnable(newValue);
}

//ghost rider
static void Convar_Ghost (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iGhost_alpha = StringToIntConstrainted(newValue, 0, 255);
}

static void Convar_Ghost_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bGhost_enable = StringToConVarEnable(newValue);
}

//scattering ram
static void Convar_Scatter_force (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flScatter_force = StringToFloatConstrainted(newValue, 1.0, 3.0);
}

static void Convar_Scatter_hpmult (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flScatter_hpmult = StringToFloatConstrainted(newValue, 0.0, 3.0);
}

static void Convar_Scatter_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bScatter_enable = StringToConVarEnable(newValue);
}

//speeding bullet
static void Convar_Bullet (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flBullet_rate = StringToFloatConstrainted(newValue, 1.0, 10.0);
}

static void Convar_Bullet_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bBullet_enable = StringToConVarEnable(newValue);
}

//adrenal glands
static void Convar_Adrenalpunchcd (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flAdrenal_punchcdmult = StringToFloatConstrainted(newValue, 0.01, 1.0);
}

static void Convar_Adrenalthrowcd (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flAdrenal_throwcdmult = StringToFloatConstrainted(newValue, 0.01, 1.0);
}

static void Convar_Adrenal_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bAdrenal_enable = StringToConVarEnable(newValue);
}

//juggernaut
static void Convar_Jugg (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iJuggernaut_hp = StringToIntConstrainted(newValue, 1, 99999);
}

static void Convar_Jugg_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bJuggernaut_enable = StringToConVarEnable(newValue);
}

//metabolic boost
static void Convar_Met (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flMetabolic_speedmult = StringToFloatConstrainted(newValue, 1.01, 3.0);
}

static void Convar_Met_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bMetabolic_enable = StringToConVarEnable(newValue);
}

//storm caller
static void Convar_Storm (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iStorm_mobcount = StringToIntConstrainted(newValue, 1, 10);
}

static void Convar_Storm_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bStorm_enable = StringToConVarEnable(newValue);
}

//double the trouble
static void Convar_Double (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flDouble_hpmult = StringToFloatConstrainted(newValue, 0.1, 2.0);
}

static void Convar_Double_en (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iDouble_enable = StringToConVarEnable(newValue);
}

//default perks
static void Convar_Def_Sur1 (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSur1_default = StrinToIntWithOneConstrainted(newValue, 5);
}

static void Convar_Def_Sur2 (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSur2_default = StrinToIntWithOneConstrainted(newValue, 3);
}

static void Convar_Def_Sur3 (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSur3_default=StrinToIntWithOneConstrainted(newValue, 3);
}

static void Convar_Def_Inf_Boomer(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iInfBoomer_default = StrinToIntWithOneConstrainted(newValue, 3);
}

static void Convar_Def_Inf_Tank (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iInfTank_default = StrinToIntWithOneConstrainted(newValue, 5);
}

static void Convar_Def_Inf_Smoker (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iInfSmoker_default = StrinToIntWithOneConstrainted(newValue, 3);
}

static void Convar_Def_Inf_Hunter (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iInfHunter_default = StrinToIntWithOneConstrainted(newValue, 5);
}

static void Convar_Def_Inf_Jockey (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iInfJockey_default = StrinToIntWithOneConstrainted(newValue, 5);
}

static void Convar_Def_Inf_Spitter (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iInfSpitter_default = StrinToIntWithOneConstrainted(newValue, 5);
}

static void Convar_Def_Inf_Charger (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iInfCharger_default = StrinToIntWithOneConstrainted(newValue, 5);
}

//perk trees
static void Convar_Sur1_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSur1_enable = StringToBool(newValue);
	RunChecksAll();
}

static void Convar_Sur2_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSur2_enable = StringToBool(newValue);
	RunChecksAll();
}

static void Convar_Sur3_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSur3_enable = StringToBool(newValue);
	RunChecksAll();
}

static void Convar_Inf_Smoker_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bInfSmoker_enable = StringToBool(newValue);
	RunChecksAll();
}

static void Convar_Inf_Boomer_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bInfBoomer_enable = StringToBool(newValue);
	RunChecksAll();
}

static void Convar_Inf_Hunter_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bInfHunter_enable = StringToBool(newValue);
	RunChecksAll();
}

static void Convar_Inf_Spitter_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bInfSpitter_enable = StringToBool(newValue);
	RunChecksAll();
}

static void Convar_Inf_Jockey_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bInfJockey_enable = StringToBool(newValue);
	RunChecksAll();
}

static void Convar_Inf_Charger_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bInfCharger_enable = StringToBool(newValue);
	RunChecksAll();
}

static void Convar_Inf_Tank_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bInfTank_enable = StringToBool(newValue);
	RunChecksAll();
}

// perk hierarchy
static void Convar_InfAll(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bInfAll_enable = StringToBool(newValue);
	RunChecksAll();
}

static void Convar_SurAll(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bSurAll_enable = StringToBool(newValue);
	RunChecksAll();
}

// random perks
static void Convar_ForceRandom(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bForceRandom = StringToBool(newValue);
}

static void Convar_Random_en(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bRandomEnable = StringToBool(newValue);
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

kConVarEnableType StringToConVarEnable(const char[] strValue)
{
	return view_as<kConVarEnableType>(StringToIntConstrainted(strValue, ConVarEnable_None, ConVarEnable_All));
}