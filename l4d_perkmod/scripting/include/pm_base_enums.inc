#if defined _l4d_perkmod_base_enums_
#endinput
#endif

#define _l4d_perkmod_base_enums_

#pragma semicolon 1
#pragma newdecls required

// #include <sourcemod>
// #include <sdktools>

// MARK: - Enums

enum ClientTeamType {
	ClientTeam_Unknown		= 0,
	ClientTeam_Spectator	= 1,
	ClientTeam_Survivor		= 2,
	ClientTeam_Infected		= 3,
}

enum InfectedType {
	Infected_Unknown	= 0,
	Infected_Smoker		= 1,
	Infected_Boomer		= 2,
	Infected_Hunter		= 3,
	Infected_Spitter	= 4,
	Infected_Jockey		= 5, // Tank in L4D1
	Infected_Charger	= 6,
	Infected_Witch		= 7,
	Infected_Tank		= 8,
}

enum GameModeType {
	GameMode_Campaign	= 0, // campaign, realism
	GameMode_Survival 	= 1, // survival
	GameMode_Versus 	= 2, // versus, scavenge, team variants
}

// MARK: - Enums funcitons

ClientTeamType PM_IntToClientTeam(int value)
{
	if (value == 1)	return ClientTeam_Spectator;
	if (value == 2)	return ClientTeam_Survivor;
	if (value == 3)	return ClientTeam_Infected;
	return ClientTeam_Unknown;
}

ClientTeamType SM_GetClientTeamType(int clientId)
{
	int clientTeam = GetClientTeam(clientId);
	return PM_IntToClientTeam(clientTeam);
}

InfectedType SM_IntToInfectedType(int value, bool isL4D2)
{
	if (value == 1) return Infected_Smoker;
	if (value == 2) return Infected_Boomer;
	if (value == 3)	return Infected_Hunter;
	if (value == 4)	return isL4D2 ? Infected_Spitter : Infected_Witch;
	if (value == 5) return isL4D2 ? Infected_Jockey	: Infected_Tank;
	if (value == 6)	return isL4D2 ? Infected_Charger : Infected_Unknown;
	if (value == 7)	return isL4D2 ? Infected_Witch : Infected_Unknown;
	if (value == 8)	return isL4D2 ? Infected_Tank : Infected_Unknown;

	return Infected_Unknown;
}
