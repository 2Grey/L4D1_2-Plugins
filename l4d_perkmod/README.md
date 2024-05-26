<div align="center">
  <h1><code>PerkMod</code></h1>
    <p style="margin-bottom: 0.5ex;">
    <img src="https://img.shields.io/github/downloads/2Grey/L4D1_2-Plugins/total"/>
    <img src="https://img.shields.io/github/last-commit/2Grey/L4D1_2-Plugins"/>
    <img src="https://img.shields.io/github/repo-size/2Grey/L4D1_2-Plugins"/>
  </p>
  <p><a href="https://forums.alliedmods.net/showthread.php?t=99305">AlliedMods thread</a></p>
</div>

## Requirements ##

- Sourcemod (1.7 or higher) and Metamod

## Installation ##

1. Grab the latest release from the release page and unzip it in your sourcemod folder.
2. Copy _.smx_ file into '...\left4dead\addons\sourcemod\plugins\'
3. Copy the contents of _translations.zip_ into '...\left4dead\addons\sourcemod\translations\'
4. Restart the server or type `sm plugins load PerkMod` in the console to load the plugin.
5. The config file will be automatically generated in cfg\sourcemod\

## Configuration ##
- A cfg file should automatically be generated in 'steamapps\common\left 4 dead\left4dead\cfg\sourcemod', named 'perkmod.cfg'. \
It will have all the cvars that can be used to tweak most of the perks' numbers.\
They're all named in the following manner: 'l4d_perkmod_<perkname>_<property> <variable>'.\
They are all clamped between certain numbers, but unless you're trying to use seriously crazy numbers like 5x damage for Stopping Power, it shouldn't be an issue.
- To disable perks, the CVars are in this sort of format: 'l4d_perkmod_<perkname>_enable 0/1'.\
 Survivor perks have two others by similar names, but with '_versus' and '_survival' at the end.
- To make the plugin stop messing with certain ConVars, find the CVar 'l4d_perkmod_<perkname>_enableconvarchanges' and set it to 0.\
Alternatively, just disable the perk


## Usage ##

A menu will show up when a player joins in the game, and every time a new round starts, perks will be reset, and the menu will show up again.\
To access this menu in case it disappears (ie. an invalid menu choice), say **!perks** to show the menu - or if you've already chosen your perks, that will instead show you the perks you've chosen.

For perks to work at all, you must choose "confirm perks" when you are done. ("7. DONE" on the main menu, then "1. Confirm").\
This is to avoid opportunistic abuses (using perks when they're convenient, then switching back).

## Posible conflicts ##

This plugin runs a lot of cheat commands to accomplish its ends, and I hear some anti-cheat plugins block cheat commands... so yeah.

Also, any plugin that uses a menu display may interfere with the one used in this plugin to display which perks to use.

This plugin also constantly adjusts some cvars, mostly for those concerning smoker tongues (shoot speed, drag speed, range) and survivors (revive times).\
Any custom cfg files that adjust these values will likely be reset after the first map, if not earlier.

To circumvent this, you can either disable the perk using those CVars, or in the case of Helping Hand, Spirit and Blind Luck you can just disable CVar changes.\
Use 'l4d_perkmod_<perkname>_enable 0' to disable the perk, or 'l4d_perkmod_<perkname>_enable_convarchanges 0' for the above 3 special cases.