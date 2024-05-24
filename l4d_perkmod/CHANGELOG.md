# Release Notes

## [2.2.2]

- Another quick hotfix, this time the ability cooldown perks shouldn't be broken with every patch.

## [2.2.1]

- Quick hotfix for Extreme Conditioning not applying sometimes.

## [2.2.0]

- Added cvars to enable or disable all infected or survivor perks:
	- l4d_perkmod_perktree_infected_enable
    - l4d_perkmod_perktree_survivor_enable

- Double Tap:
	- Bonuses are now restricted to semi-automatics (ie. pistols, shotguns, snipers).
	- No longer grants a chance to recover bullets (there was no tooltip for this previously, see version 2.1.3).
	- Now has a cvar for increased reload speed (was experimenting around and realized this was overpowered, but I left the code in there for people to have fun with it :P l4d_perkmod_doubletap_rate_reload).
		
- Martial Artist:
	- Is now a secondary perk.
	- Shove penalty reduction is now removed by default (cvar is still there for adjustments).

- Pyrotechnician:
	- Now gives a pipe bomb if the player does not carry a grenade for a set period of time.\
By default this is set to 120 seconds (adjust with l4d_perkmod_pyrotechnician_maxticks, disable by setting it to 0).
		
- Updated offsets for cooldown-reducing infected perks, should be working now (Twin Spitfire, Drag and Drop).
		
- Reduced default value for Chem Reliant bonus health buffer from 10 -> 0.
- Reduced default value for Double the Trouble health multiplier from 0.45 -> 0.35.
- Tweaked Spirit, hopefully should be less buggy.
- Fixed major bug with Barf Bagged interacting with bile jars.
- Fixed minor bug with Spitter perks not displaying properly.
- ... Lukewarm, untested attempt at fixing rare (but highly game changing!) Smoke IT bug with tanks.

> KNOWN ISSUE: Adrenal glands doesn't work properly for punches.

## [2.1.5]

- Fixed an exploit with faster reloading for Double Tap.
- Rewrote some code, Mega Adhesive should no longer interfere with other movement-changing infected perks.
- Updated Pack Rat again to address more bugs.

## [2.1.4]

- Increased Twin Spitfire delay in-between spits from 2.5s -> 6s.
- Increased Mega-Adhesive slow from 50% -> 60%.
- Updated Pack Rat further, should be less buggy... with any luck.

## [2.1.3]

- Added a CVar "l4d_perkmod_autoshowmenu" to enable or disable automatically showing the perks menu on roundstart.
- Double Tap now has a 15% chance per shot that a bullet will not be consumed.
- Rewrote Pack Rat to address multiple bugs.
- Updated offsets for ability and attack timers, cooldown-reducing perks (ie. Twin Spitfire) and attack speed increase perks (ie. Adrenal Glands) should now work properly.

## [2.1.2]

- Helping Hand should now be properly granting the reviver half the bonus health buffer as well (was previously only granting it to the revivee).
- Updated Martial Artist to now give 3 swings instead of 2, and shoving or drawing the melee weapon no longer "counts" as a swing.

## [2.1.1]

- Added Little Leaguer perk to survivor-tertiary: gives a baseball bat.
- Added Mega Adhesive perk to spitters: slows survivor speed by 50% for up to two seconds after leaving spit.
- Added Smoke IT! perk to smokers: can walk while smoking (thanks to Olj for this perk!)
- Saying !perks should work more consistently (but perks may still not work properly on local servers!)

## [2.1.0]

- Added translations! (basically stole AtomicStryker's work =P)
- Being rescued from the closet now gives bonus items with the corresponding perks (grenades for Pyrotechnician, pills for Chem Reliant).
- Twin Spitfire, Adrenal Glands and other cooldown-reducing perks should now work properly on Linux servers (nobody told me the offsets were all weird between Linux and Windows servers =.=). Still don't have offset numbers for L4D1 Linux, so it won't work for L4D1 Linux until I can find those numbers...

## [2.0.12]

- Fixed a few minor errors.
- The plugin will no longer read from the cfg file on round start, was probably causing some buffer overflows...

## [2.0.11]

- Adrenal Glands now also makes the tank unfrustratable.
- Fixed bug/exploit with Chem Reliant/Pyrotechnician/Unbreakable on switching from AFK to non-AFK.
- Fixed Helping Hand bug that wasn't giving the reviver bonus health buffer.
- Fixed Pack Rat bug/exploit and updated some old code.
- Increased Frogger damage from 0.2 -> 0.35


## [2.0.10]

- Added Frogger perk for Jockeys: 20% more damage, 30% more leap distance.
- Added Ghost Rider perk for Jockeys: near invisibility.
- Added Speeding Bullet perk for Chargers: charges are 30% faster and longer.
- Modified Scattering Ram to also give 30% more health.
- Revised menu code again, shouldn't display disabled perks.

## [2.0.9]

- Added Cavalier perk for Jockeys: gives 60% more health.
- Changed Spirit so that a self-revive counts as a revive - meaning each self-revive moves you one step closer to black-and-white health.
- Fixed some bugs with Unbreakable, wasn't giving bonus health buffer on revive or after being rescued from the closet.
- Helping Hand now gives bonus health buffer to the reviver as well.
- Increased Spirit self-revive health bonus from 10 to 30
- Lowered Body Slam minimum pounce damage from 11 to 10
- Lowered Double the Trouble health modifier from 0.6 to 0.45
- Lowered Efficient Killer damage bonus from 0.3 to 0.2
- Lowered Grasshopper pounce speed multiplier from 1.3 to 1.2
- Reduced Helping Hand bonus buffer from 15 to 10 for versus.
- Reduced Unbreakable bonus health buffer on revive from 16 to 10 (0.8 -> 0.5 of Unbreakable health bonus value).

## [2.0.8]

- Fixed a bug with Hard to Kill.
- Revised menu code, should properly show a player that a perk is disabled.

## [2.0.7]

- Fixed error messages for Unbreakable and Sleight of Hand.
- Increased Helping Hand bonus health from 10 to 15.
- Increased Spirit bonus health from 0 to 10.
- Plugin will now attempt to load values from the .cfg file on round start, in addition to loading it on plugin load.
- Revised Twin Spitfire to be more consistent in giving two shots.

## [2.0.6]

- Another attempt at fixing stability.

## [2.0.5]

- Attempted fixes for stability.

## [2.0.4]

- Added backwards compatibility for L4D1.
- Added some extra checks for Unbreakable to fix some rare abuses.
- Double Trouble no longer stops tanks from becoming frustrated.
- Fixed Double Trouble not spawning the second tank.
- Fixed some major bugs with Spirit. Spirit will no longer attempt to revive a player immediately after being incapped, which should increase the reliability of the perk functioning, but it means that if the last survivor standing gets incapped, even if that survivor or another survivor has spirit, too bad.

## [2.0.3]

- Fixed Sleight of Hand bug that prevented being able to shoot after reloading.
- Reinstated Speed Demon perk for hunters.

## [2.0.2]

- After going AFK (in coop), the menu shouldn't reset perks for the player.
- Extreme Conditioning (new): gives a survivor +10% run speed.
- Fixed cooldown-reducing perks; most had stopped working with the last update.
- Martial Artist (remake): Now allows the player to swing melee weapons twice rapidly in succession, and reduces the maximum shove penalty for any weapon.
- The menu should appear somewhat more consistently.
- Twin Spitfire now activates properly for the first attack after spawning.

## [2.0.1]

- Added some code so some perks should recognize when a survivor is being disabled by a charger (ie., spirit).
- Adrenal Glands no longer increases rock travel speed.
- Changed Dead Wreckening to better handle rounding. If rounding error can occur (say it calculates 1.5 damage), then it will randomly choose either the higher or the lower (1 or 2).
- Converted a few perks that reduce cooldowns to not use CVars. Some perks still use CVars - namely, Helping Hand (revive time), Tongue Twister (everything about it), Drag and Drop (manual release, drop-to-ground/recovery time)
- Efficient Killer (remake): now deals a flat +50% damage bonus to all damage.
- Fixed an issue with Spirit firing on tank deaths - no, Valve, tank deaths do NOT count as being incapped! ^^
- Martial Artist (remake): now increases melee attack speed.
- Modified Pack Rat to also work with grenade launchers.
- Newer, shinier version for L4D2!
- Rebalanced Survivor perk values.
- Removed Old School and Speed Demon perks.
- Reorganized Survivor perks into three categories.
- Rewrote some class checks to check actual netprop values instead of checking model names.
- Spirit no longer allows crawling.
- Updated Chem Reliant to include adrenaline shots.
- Updated Pyrotechnician to include vomit jars.

## [2.0.0]

- Pack Rat works with L4D2 guns.
- Support for L4D2.

## [1.4.2]

- Fixed PKT errors showing up on clients' console.

## [1.4.1]

- Fixed problems with never-ending music.
- Merged Speed Demon with Old School. Reduced Speed Demon to 1.4x and Old School to 3/6/12. CVar names are unchanged.
- Seemed to be some problems with damage adds. Fixed

## [1.4.0]

- Added an OnPluginEnd function.
- Added CVar to disable the player's option to randomize their perks ("l4d_perkmod_randomperks_enable")
- Added CVars to disable entire perk trees, which will stop all perks under that tree from working, and also hide the perk tree from player menus.
- Added missing code to when a player selects "Play NOW!" on the initial perk menu, which wasn't applying some perk benefits (thanks again, AtomicStryker!)
- Bots now receive random perks. The pool of perks that bots can choose from can be adjusted with "l4d_perkmod_bot_<type> <range>". General format is "1, 2, 3, 4, 5", "3, 2, 5", etc.
- Fixed some code that was causing CVar-adjusting perks to adjust CVars even when disabled in game modes other than campaign.
- Reduced default Spirit cooldown values (versus and survival 210s -> 150s, campaign 540s -> 240s).
- Revised perk code so that non-CVar-adjusting perks will also cease functioning if disabled in general.
- Revised Spirit so that self-reviving doesn't reset black-and-white health (thanks to AtomicStryker!). Self-reviving through Spirit won't increase the revive count towards black-and-white health, however.

## [1.3.0]

- Added in a CVar to force random perks on players every roundstart.
- Added in an option for players to pick random perks.
- Added in ConVars to selectively disable ConVar modifying for the perks Helping Hand and Blind Luck.
- Double Trouble tanks can no longer be frustrated as long as both are alive (band-aid solution to the disappearing-tank-when-both-tanks-are-alive-and-one-gets-frustrated problem).
- Nerfed Dead Wreckening default value (damage multiplier 1.0 -> 0.5).
- Pack Rat now gives ammo based on max ammo values set by the server instead of absolute values.
- Renamed ConVar "l4d_perkmod_spirit_crawling" to "l4d_perkmod_spirit_enable_convarchanges" to keep the naming system consistent with the other new ConVar-change-permission ConVars.
- Revised some code so that disabling a perk that changes ConVars will make the plugin stop modifying those ConVars.
- Revised the show-menu code slightly to always show the initial "customize/playNOW!" menu on roundstarts.

## [1.2.0]

- Hopefully fixed problem with second tank not spawning with Double Trouble.
- Hopefully fixed problem with unbreakable not applying sometimes.
- Minor fixes for (mostly) harmless server errors
- Nerfed Metabolic Boost default value from 1.5 to 1.4.
- Nerfed Tongue Twister default values slightly (pull speed 1.75->1.5, shoot speed 1.75->1.5, range 1.75 unchanged).
- New perk for Boomers - Motion Sickness, boosts movement speed and lets you run while vomiting.
- Reinstated Speed Demon (for hunters).
- Unbreakable now gives bonus buffer on being revived.

## [1.1.1]

- Fixed Martial Artist not resetting fatigue.
- Removed debug messages (oops!)

## [1.1.0]

- Added in a CVar to disable plugin adjustments to survivor crawling.
- Added more info to perk CVars for min and max values allowed.
- Changing teams to survivors should grant perks.
- Fix for various tank perks either not applying or applying too many times (double the trouble health multiplier).
- Included CVars to disable perks.
- Replaced Speed Demon with Grasshopper.

## [1.0.2]

- Attempted fix for outrageous health values for survivors.
- Fix for Double Tap not working on team switches.

## [1.0.1]

- Changed code for Blind Luck with Doku's

## [1.0.0]

- Initial release
