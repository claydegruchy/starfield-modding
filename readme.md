# starfield modding stuff

Note that the below are raw notes from me during the modding process.

If you're just here for the mod, then use `bsscript.psc`

Versions of Caprica may be outdated, this is litterally my working folder for modding, but may help new modders understand what can be changed or common gotchas.

# how to get these working

https://www.nexusmods.com/starfield/mods/3921
extract at bottom in case that 404s

# bsscript

you can take a script that controls part of the game and modify it, leaving it in the data/scripts folder and the game will load it

in this case we use the boarding script that defines the boarding a ship "mission" that starts when you dock an enemy ship.

# shit you should know

- scripts must be compiled from their native `.psc` format into `.pex` to be loaded by the engine
- you can view all scripts that the game runs off by extracting `misc.bs2` then decompiling with `Champollion` (below)
- scripts that overwrite part of the games base fucntions (such as bescript for BoardingEvents) will be automatically loaded
- new scripts must be loaded either with `cfg "name.function"` for solo scripts or attached to an entity (such as the player) via `player.aps scriptname`
- updated scripts can be reloaded during runtime using `ReloadScript "name"`
-

# handy functions and tools

- list of known events and hazards https://gist.github.com/claydegruchy/f8ef9624015ab8f728a96410922022db
- keywords bind many things together, these can be found in the game via console > `help <query> 4 KWYD`
-
-
-

# running

in git bash

- cd `C:\Program Files (x86)\Steam\steamapps\common\Starfield\Data\Scripts\Source\User`
- ` ./create_permutations.sh  -d Hazardous_ship_boarding.mod/config/ -t Hazardous_ship_boarding.mod/bescript.psc -b Hazardous_ship_boarding.mod/defaults.yaml -o Hazardous_ship_boarding.mod/permutations/`
- `./create_all_mods.sh`
- `nodemon -w Hazardous_ship_boarding.mod/bescript.psc  --exec "bash ./create_permutations.sh  -d Hazardous_ship_boarding.mod/config/ -t Hazardous_ship_boarding.mod/bescript.psc -b Hazardous_ship_boarding.mod/defaults.yaml -o Hazardous_ship_boarding.mod/permutations/"`
-

# todos

- modify `SetModuleHazard` to allow locational hazards on a ship
- allow multiple hazards
- make number of hazards and their type affect chances of enemy boarding parties (a more fucked ship causes more people to flee the enmy ship)
-
-

## extract in case https://www.nexusmods.com/starfield/mods/3921 404s

Quick workflow wrapper files to decompile the Starfield base game Papyrus scripts with CHAMPOLLION and compile your own scripts with CAPRICA.

DECOMPILE

(1) Extract ChampollionDecompile.cmd from the download archive into your SOURCE working folder. It is best to NOT put the loose base game source PEX files in your Starfield folders for performance and compatibility.

(2) Edit ChampollionDecompile.cmd SOURCE to your working folder.

(3) Use Hexabit B.A.E. to extract PEX scripts from [ Starfield - Misc.ba2 ] to SOURCE.

(4) Put Champollion.exe >= 1.3.0 in the same folder as ChampollionDecompile.cmd

(5) Edit ChampollionDecompile.cmd DESTINATION to your starfield path. Best to maintain the standard Fallout4 paths unless we hear different.

(6) Run ChampollionDecompile.cmd to decompile the whole PEX SOURCE tree to PSC DESTINATION. As path recursion is not consistent its hand coded in the .cmd file.

COMPILE

(1) Extract CapricaCompile.cmd from the download archive to your scripts working folder SCRIPTPATH. Best to maintain the standard Fallout4 paths unless we hear different.

(2) Edit CapricaCompile.cmd path settings to match your environment.

(3) Put Caprica.exe >= 6269714887 in SCRIPTPATH folder.

(4) Put Starfield_Papyrus_Flags in SCRIPTPATH folder.

(5) Create your new PSC scripts in SCRIPTPATH folder (best not mess with name spaces at this stage).

(6) To run a compile either:

(a) set the value of SCRIPTNAME in CapricaCompile.cmd (v002 with .psc), or

(b) pass the SCRIPTNAME on the command line (v002 with .psc) to override the hardcoded value, or

(c) fill in the prompt when CapricaCompile.cmd is run with no SCRIPTNAME set.

NOTEPAD++ INTEGRATION

To compile direct from Notepad++ [ Run ] menu, use version 002 of the these CMD files and enter [ Program to Run ] "YourSCRIPTPATH\CapricaCompile.cmd" $(FILE_NAME)

Example:
"C:\Program Files (x86)\Steam\steamapps\common\Starfield\Data\Scripts\Source\User\CapricaCompile.cmd" $(FILE_NAME)

Then [ Save ] a name.

OTHER OBSERVATIONS

You will of course need to enable loose files to see your new compiled PEX scripts in game.

You will undoubtably be wanting to enable the Papyrus Debug.Trace log.

Creating stateless Global function scripts is fairly safe until we get a create/save enabled xEdit for new forms to hang stateful event driven scripts on.

If you find this useful, payback by never distributing hacked base game scripts. There really is no need unless you are teh Unofficial Patch.

Been using this workflow to produce SKK Global Console Script and of course a stack of 'poke it with a stick' GCU class research scripts with zero issues, but avoiding the experemental functions.

KNOWN ISSUES

(1) If you are not a Papyrus script developer this is not for you.

#
