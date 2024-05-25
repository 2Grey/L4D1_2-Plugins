#if defined _l4d_perkmod_convars_
#endinput
#endif

#define _l4d_perkmod_convars_

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
}

// MARK: - Sur: First Perks

static void CreateConvarsSurStopingPower()
{
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
}

static void CreateConvarsSurDoubleTap()
{
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
}

static void CreateConvarsSurSleightOfHand()
{
    g_hSoH_rate = CreateConVar(
		"l4d_perkmod_sleightofhand_rate" ,
		"0.5714" ,
		"Sleight of Hand perk: The interval incurred by reloading is multiplied by this value (clamped between 0.2 < 0.9)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSoH_rate.AddChangeHook(Convar_SoH);
	g_flSoH_rate = 0.5714;

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
}

static void CreateConvarsSurPyrotechnician()
{
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
}

// MARK: - Sur: Second Perks

static void CreateConvarsSurUnbreakable()
{
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
}

static void CreateConvarsSurSpirit()
{
    g_hSpirit_buff = CreateConVar(
		"l4d_perkmod_spirit_bonusbuffer" ,
		"30" ,
		"Spirit perk: Bonus health buffer on self-revive (clamped between 0 < 170)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSpirit_buff.AddChangeHook(Convar_SpiritBuff);
	g_iSpirit_buff = 30;

	g_hSpirit_cd = CreateConVar(
		"l4d_perkmod_spirit_cooldown" ,
		"60" ,
		"Spirit perk: Cooldown for self-reviving in seconds, campaign (clamped between 1 < 1800)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSpirit_cd.AddChangeHook(Convar_SpiritCD);
	g_iSpirit_cd = 60;

	g_hSpirit_cd_sur = CreateConVar(
		"l4d_perkmod_spirit_cooldown_sur" ,
		"60" ,
		"Spirit perk: Cooldown for self-reviving in seconds, survival (clamped between 1 < 1800)" ,
		FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hSpirit_cd_sur.AddChangeHook(Convar_SpiritCDsur);
	g_iSpirit_cd_sur = 60;

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
}

static void CreateConvarsSurHelpingHand()
{
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
}

static void CreateConvarsSurMartialArtist()
{
    g_hMA_maxpenalty = CreateConVar(
		"l4d_perkmod_martialartist_maximumpenalty" ,
		"6" ,
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
}

// MARK: - Sur: Third Perks

static void CreateConvarsSurPackRat()
{
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
}

static void CreateConvarsSurChemReliant()
{
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
}

static void CreateConvarsSurHardToKill()
{
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
}

static void CreateConvarsSurExtremeConditioning()
{
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
}

static void CreateConvarsSurLittleLeaguer()
{
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
}

