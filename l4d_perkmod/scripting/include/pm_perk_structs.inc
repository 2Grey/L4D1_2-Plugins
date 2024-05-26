#if defined _l4d_perkmod_perk_structs_
#endinput
#endif

#define _l4d_perkmod_perk_structs_

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <pm_perk_enums>

enum struct SurvivorPerks {

    SurvivorFirstPerkType firstPerk;
    SurvivorSecondPerkType secondPerk;
    SurvivorThirdPerkType thirdPerk;

    void ResetState() {
        this.firstPerk = SurvivorFirstPerk_Unknown;
        this.secondPerk = SurvivorSecondPerk_Unknown;
        this.thirdPerk = SurvivorThirdPerk_Unknown;
    }
}

enum struct InfectedPerks {

    InfectedSmokerPerkType smokerPerk;
    InfectedBoomerPerkType boomerPerk;
    InfectedHunterPerkType hunterPerk;
    InfectedSpitterPerkType spitterPerk;
    InfectedJockeyPerkType jockeyPerk;
    InfectedChargerPerkType chargerPerk;
    InfectedTankPerkType tankPerk;

    void ResetState() {
        this.smokerPerk = InfectedSmokerPerk_Unknown;
        this.boomerPerk = InfectedBoomerPerk_Unknown;
        this.hunterPerk = InfectedHunterPerk_Unknown;
        this.spitterPerk = InfectedSpitterPerk_Unknown;
        this.jockeyPerk = InfectedJockeyPerk_Unknown;
        this.chargerPerk = InfectedChargerPerk_Unknown;
        this.tankPerk = InfectedTankPerk_Unknown;
    }
}
