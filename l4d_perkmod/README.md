<div align="center">
  <h1><code>PerkMod</code></h1>
  <p><a href="https://forums.alliedmods.net/showthread.php?t=99305">AlliedMods thread</a></p>
</div>

## Requirements ##

- Sourcemod (1.7 or higher) and Metamod
- Dedicated server


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
