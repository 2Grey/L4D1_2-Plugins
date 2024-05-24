#if defined _l4d_perkmod_perks_enums_
#endinput
#endif

#define _l4d_perkmod_perks_enums_

// MARK: - Enum Survivor

enum SurvivorFirstPerkType {
    SurvivorFirstPerk_Unknown           = 0,
    SurvivorFirstPerk_StoppingPower     = 1,
    SurvivorFirstPerk_DoubleTap         = 2,
    SurvivorFirstPerk_SleightOfHand     = 3,
    SurvivorFirstPerk_Pyrotechnician    = 4,
    
    SurvivorFirstPerk_Count             = 4,
}

enum SurvivorSecondPerkType {
    SurvivorSecondPerk_Unknown          = 0,
    SurvivorSecondPerk_Unbreakable      = 1,
    SurvivorSecondPerk_Spirit           = 2,
    SurvivorSecondPerk_HelpingHand      = 3,
    SurvivorSecondPerk_MartialArtist    = 4,

    SurvivorSecondPerk_Count            = 4,
}

enum SurvivorThirdPerkType {
    SurvivorThirdPerk_Unknown               = 0,
    SurvivorThirdPerk_PackRat               = 1,
    SurvivorThirdPerk_ChemReliant           = 2,
    SurvivorThirdPerk_HardToKill            = 3,
    SurvivorThirdPerk_ExtremeConditioning   = 4,
    SurvivorThirdPerk_LittleLeaguer         = 5,

    SurvivorThirdPerk_Count                 = 5,
}

// MARK: - Enum Infected

enum InfectedSmokerPerkType {
    InfectedSmokerPerk_Unknown          = 0,
    InfectedSmokerPerk_TongueTwister    = 1,
    InfectedSmokerPerk_Squeezer         = 2,
    InfectedSmokerPerk_DragAndDrop      = 3,
    InfectedSmokerPerk_SmokeIt          = 4,

    InfectedSmokerPerk_Count            = 4,
}

enum InfectedBoomerPerkType {
    InfectedBoomerPerk_Unknown          = 0,
    InfectedBoomerPerk_BarfBagged       = 1,
    InfectedBoomerPerk_BlindLuck        = 2,
    InfectedBoomerPerk_DeadWreckening   = 3,
    InfectedBoomerPerk_MotionSickness   = 4,

    InfectedBoomerPerk_Count            = 4,
}

enum InfectedHunterPerkType {
    InfectedHunterPerk_Unknown          = 0,
    InfectedHunterPerk_BodySlam         = 1,
    InfectedHunterPerk_EfficientKiller  = 2,
    InfectedHunterPerk_Grasshopper      = 3,
    InfectedHunterPerk_SpeedDemon       = 4,

    InfectedHunterPerk_Count            = 4,
}

enum InfectedSpitterPerkType {
    InfectedSpitterPerk_Unknown         = 0,
    InfectedSpitterPerk_TwinSpitfire    = 1,
    InfectedSpitterPerk_MegaAdhesive    = 2,

    InfectedSpitterPerk_Count           = 2,
}

enum InfectedJockeyPerkType {
    InfectedJockeyPerk_Unknown  = 0,
    InfectedJockeyPerk_Wind     = 1,
    InfectedJockeyPerk_Cavalier = 2,
    InfectedJockeyPerk_Frogger  = 3,
    InfectedJockeyPerk_Ghost    = 4,

    InfectedJockeyPerk_Count    = 4, 
}

enum InfectedChargerPerkType {
    InfectedChargerPerk_Unknown = 0,
    InfectedChargerPerk_Scatter = 1,
    InfectedChargerPerk_Bullet  = 2,

    InfectedChargerPerk_Count   = 2,
}

enum InfectedTankPerkType {
    InfectedTankPerk_Unknown        = 0,
    InfectedTankPerk_AdrenalGlands  = 1,
    InfectedTankPerk_Juggernaut     = 2,
    InfectedTankPerk_MetabolicBoost = 3,
    InfectedTankPerk_Stormcaller    = 4,
    InfectedTankPerk_DoubleTrouble  = 5,

    InfectedTankPerk_Count          = 5,
}

// MARK: - Enum functions

InfectedSmokerPerkType PM_IntToInfectedSmokerPerkType(int val)
{
    switch (val) {
        case 1: return InfectedSmokerPerk_TongueTwister;
        case 2: return InfectedSmokerPerk_Squeezer;
        case 3: return InfectedSmokerPerk_DragAndDrop;
        case 4: return InfectedSmokerPerk_SmokeIt;
        default: return InfectedSmokerPerk_Unknown;
    }
}

SurvivorFirstPerkType PM_IntToSurvivorFirstPerkType(int val)
{
    switch (val) {
        case 1: return SurvivorFirstPerk_StoppingPower;
        case 2: return SurvivorFirstPerk_DoubleTap;
        case 3: return SurvivorFirstPerk_SleightOfHand;
        case 4: return SurvivorFirstPerk_Pyrotechnician;
        default: return SurvivorFirstPerk_Unknown;
    }
}

SurvivorSecondPerkType PM_IntToSurvivorSecondPerkType(int val)
{
    switch (val) {
        case 1: return SurvivorSecondPerk_Unbreakable;
        case 2: return SurvivorSecondPerk_Spirit;
        case 3: return SurvivorSecondPerk_HelpingHand;
        case 4: return SurvivorSecondPerk_MartialArtist;
        default: return SurvivorSecondPerk_Unknown;
    }
}

SurvivorThirdPerkType PM_IntToSurvivorThirdPerkType(int val)
{
    switch (val) {
        case 1: return SurvivorThirdPerk_PackRat;
        case 2: return SurvivorThirdPerk_ChemReliant;
        case 3: return SurvivorThirdPerk_HardToKill;
        case 4: return SurvivorThirdPerk_ExtremeConditioning;
        case 5: return SurvivorThirdPerk_LittleLeaguer;
        default: return SurvivorThirdPerk_Unknown;
    }
}

InfectedBoomerPerkType PM_IntToInfectedBoomerPerkType(int val)
{
    switch (val) {
        case 1: return InfectedBoomerPerk_BarfBagged;
        case 2: return InfectedBoomerPerk_BlindLuck;
        case 3: return InfectedBoomerPerk_DeadWreckening;
        case 4: return InfectedBoomerPerk_MotionSickness;
        default: return InfectedBoomerPerk_Unknown;
    }
}

InfectedHunterPerkType PM_IntToInfectedHunterPerkType(int val)
{
    switch (val) {
        case 1: return InfectedHunterPerk_BodySlam;
        case 2: return InfectedHunterPerk_EfficientKiller;
        case 3: return InfectedHunterPerk_Grasshopper;
        case 4: return InfectedHunterPerk_SpeedDemon;
        default: return InfectedHunterPerk_Unknown;
    }
}

InfectedSpitterPerkType PM_IntToInfectedSpitterPerkType(int val)
{
    switch (val) {
        case 1: return InfectedSpitterPerk_TwinSpitfire;
        case 2: return InfectedSpitterPerk_MegaAdhesive;
        default: return InfectedSpitterPerk_Unknown;
    }
}

InfectedJockeyPerkType PM_IntToInfectedJockeyPerkType(int val)
{
    switch (val) {
        case 1: return InfectedJockeyPerk_Wind;
        case 2: return InfectedJockeyPerk_Cavalier;
        case 3: return InfectedJockeyPerk_Frogger;
        case 4: return InfectedJockeyPerk_Ghost;
        default: return InfectedJockeyPerk_Unknown;
    }
}

InfectedChargerPerkType PM_IntToInfectedChargerPerkType(int val)
{
    switch (val) {
        case 1: return InfectedChargerPerk_Scatter;
        case 2: return InfectedChargerPerk_Bullet;
        default: return InfectedChargerPerk_Unknown;
    }
}

InfectedTankPerkType PM_IntToInfectedTankPerkType(int val)
{
    switch (val) {
        case 1: return InfectedTankPerk_AdrenalGlands;
        case 2: return InfectedTankPerk_Juggernaut;
        case 3: return InfectedTankPerk_MetabolicBoost;
        case 4: return InfectedTankPerk_Stormcaller;
        case 5: return InfectedTankPerk_DoubleTrouble;
        default: return InfectedTankPerk_Unknown;
    }
}
