ScriptName BEScript Extends Quest
{ Standard script for Boarding Encounter quests. }

;-- Structs -----------------------------------------
Struct GenericCrewDatum
  ActorBase CrewActor
  { The Actor to spawn. }
  Float ActorLevelModChanceEasy = 0.5
  { Default=0.5. Chance the actor's aiLevelMod will be 0, Easy. }
  Float ActorLevelModChanceMedium = 0.5
  { Default=0.5. Chance the actor's aiLevelMod will be 1, Medium. If not Easy or Medium, the actor will be 2, Hard. }
  Int InstancesToSpawn = -1
  { Default=-1 (Unlimited). The maximum number of instances of this actor to spawn on this ship. }
EndStruct

Struct ModuleDatum
  ObjectReference moduleRef
  ObjectReference shipCrewSpawnMarkerRef01
  ObjectReference shipCrewSpawnMarkerRef02
  ObjectReference shipCrewSpawnMarkerRef03
  ObjectReference shipCrewSpawnMarkerRef04
  ObjectReference shipCrewSpawnMarkerRef05
  ObjectReference shipTurretSpawnMarkerRef01
  ObjectReference shipTurretSpawnMarkerRef02
  ObjectReference shipTurretSpawnMarkerRef03
  ObjectReference shipTurretSpawnMarkerRef04
  ObjectReference shipTurretSpawnMarkerRef05
  ObjectReference shipComputerRef
EndStruct


;-- Variables ---------------------------------------
Actor[] BEAliasCorpses
Int CONST_Aggression_VeryAggressive = 2 Const
Int CONST_BEObjective_KillEnemyCrewObj = 20 Const
Int CONST_BEObjective_LeaveShip = 255 Const
Int CONST_BEObjective_Startup = 10 Const
Int CONST_BEObjective_TakeOverEnemyShipObj = 30 Const
Float CONST_BoardingUpdateTimerDelay = 4.0 Const
Int CONST_BoardingUpdateTimerID = 1 Const
Int CONST_Confidence_Foolhardy = 4 Const
Int CONST_LockLevel_Inaccessible = 254 Const
Int CONST_Suspicious_DetectedActor = 2 Const
Float CONST_TakeoffUpdateTimerDelay = 2.0 Const
Int CONST_TakeoffUpdateTimerID = 2 Const
Int CONST_WaitUntilInitializedTimeoutDelay = 120 Const
Actor[] HeatLeeches
Bool ShouldLandingRampsBeOpenOnLoad
ObjectReference[] allCrewSpawnPoints
Float crewSizePercent
Int crewSuspiciousState
Bool disembarkersShouldHaveWeaponsUnequipped
Cell enemyShipCell
ObjectReference enemyShipCockpit
Faction enemyShipCrimeFaction
ObjectReference enemyShipHazard
Location enemyShipInteriorLoc
spaceshipreference enemyShipRef
Int genericCrewSize
Bool hasFinishedSetupDisembarking
Bool hasInitialized
Bool hasPlayerBoardedEnemyShip
Bool hasSetupDisembarking
Bool hasSpawnedCaptain
Bool hasStartedDisembarking
Bool isDropshipEncounter
Bool isReadyForTakeoff
Bool isSurfaceEncounter
Int maxSimultaneousBoarders
bescript:moduledatum[] moduleData
Actor player
ObjectReference playerShipCockpitRef
ObjectReference playerShipDockingDoorRef
Location playerShipInteriorLoc
ObjectReference[] playerShipModulesAllRefs
spaceshipreference playerShipRef
Actor[] potentialBoarders
Actor[] remainingBoarders
Actor[] robots
Bool shouldAbortBoarding
Bool shouldShutdownOnTakeoff
Actor[] turrets

;-- Guards ------------------------------------------
;*** WARNING: Guard declaration syntax is EXPERIMENTAL, subject to change
Guard BECrewGuard
Guard DisembarkingGuard
Guard SpaceshipCrewDecrementGuard

;-- Properties --------------------------------------
Group QuestProperties collapsedonbase
  Bool Property ShutDownOnUndock = False Auto
  { DEFAULT=False. Should this quest shut down when the target ship undocks?
	This should be FALSE for most Boarding Encounters-- you want the quest to continue to run until the target ship unloads. Otherwise, if you undock, then re-dock, a new and potentially different Boarding Encounter will start. }
  Bool Property ShutDownOnUnload = True Auto
  { DEFAULT=True. Should this quest shut down when the target ship unloads?
	This should be TRUE for most Boarding Encounters-- you want the quest to shut down when the target ship unloads so it and the target ship can be cleaned up. }
  Bool Property ShutDownOnTakeover = True Auto
  { DEFAULT=True. Should this quest shut down if the player takes over the enemy ship?
	This should be TRUE for most Boarding Encounters-- the encounter should not remain active once a player has taken over the ship. }
  Int Property StageToSetOnBoarding = -1 Auto Const
  { DEFAULT=-1. If >=0, stage to set when the player boards the enemy ship for the first time. }
  Int Property StageToSetWhenAllCrewDead = -1 Auto Const
  { Default=-1. If >=0, stage to set when all of the enemy ship's crew has been killed. }
EndGroup

Group CrewProperties
  Bool Property ShouldCrewStartInCombat = True Auto Const
  { DEFAULT=True. Is this a hostile boarding encounter?
	If True, the crew will start in the Suspicious state, and Companions will play a combat-oriented line when boarding the enemy ship. Does not apply to Surface Encounters. }
  Bool Property ShouldSpawnCrew = True Auto Const
  { DEFAULT=True. Should this BE spawn generic crew ? }
  Bool Property ShouldSpawnCaptain = True Auto Const
  { DEFAULT=True. Should this BE spawn a generic captain? }
  bescript:genericcrewdatum Property CaptainData Auto
  { When a BE spawns its generic crew, if at least one actor is alive (SpaceshipCrew actor value >= 1, adjusted by any mods below), and ShouldSpawnCaptain=True,
	the first actor to be spawned will be this Captain. One and only one Captain is spawned (InstancesToSpawn will be ignored).
	The Captain will be added to the AllCrew, GenericCrew, and Captain aliases. }
  bescript:genericcrewdatum[] Property CrewData Auto
  { When a BE spawns its generic crew, it determines how many slots it has to fill based on the SpaceshipCrew actor value (and any mods below), then cycles
	through CrewData until it's spawned the required number of actors, or until it runs out of actors it can spawn.
	Crew are added to the AllCrew and GenericCrew aliases. }
  Float Property CrewCountPercent = 1.0 Auto Const
  { DEFAULT=1.0. Multiply SpaceshipCrew by this value before spawning crew. Use 0.5 if you want half the normal crew, etc.
	NOTE: The SpaceshipCrew count is visible to players during space battles, so you should only modify this for surface encounters or very unusual space encounters,
	since players will be expecting a specific number of enemies. }
  Int Property CrewCountOverride = -1 Auto Const
  { OPTIONAL, DEFAULT=-1. If >=0, set the number of crew members to spawn to this value. If set, CrewCountMod and the SpaceshipCrew actor value are ignored.
	NOTE: The SpaceshipCrew count is visible to players during space battles, so you should only modify this for surface encounters or very unusual space encounters,
	since players will be expecting a specific number of enemies. }
  Int Property CrewSpawnPattern = 1 Auto Const
  { DEFAULT=1. When spawning generic crew, what pattern should we spawn them in?
	0=FILL. Select a module, fill all of its spawn points, move on to the next module, repeat.
	1=HALF FILL. Select a module, fill half of its spawn points, move on to the next module, repeat. Spawn excess crew randomly.
	2=SPREAD. Select a module, fill one spawn point in it, move on to the next module, repeat. Spawn excess crew randomly.
	3=RANDOM. Select spawn points completely at random. }
  Bool Property ShouldSpawnCorpses = True Auto Const
  { DEFAULT=True. Should this BE spawn generic corpses? }
  bescript:genericcrewdatum[] Property CorpseData Auto
  { OPTIONAL. When a BE spawns its generic crew corpses, it determines how many slots it has to fill based on the SpaceshipCrew actor value (Max-Current)(and any mods below),
	then cycles through CrewCorpseData (if any) until it's spawned the required number of actors, or runs out of actors it can spawn.
	If CrewCorpseData=None, it just continues using the remaining actors in CrewData. }
  Float Property CorpseCountPercent = 1.0 Auto Const
  { DEFAULT=1.0. Multiply the number of corpses to spawn CorpseCountPercent before spawning corpses.
	Use 0.5 if you want half the normal number of corpses, etc. }
  Int Property CorpseCountOverride = -1 Auto Const
  { OPTIONAL; DEFAULT=-1. If >=0, set the number of crew corpses to spawn to this value. If set, CorpseCountMod and the SpaceshipCrew actor value are ignored. }
  Int Property CorpseSpawnPattern = 0 Auto Const
  { DEFAULT=1. When spawning crew corpses, what pattern should we spawn them in?
	0=FILL. Select a module, fill all of its spawn points, move on to the next module, repeat.
	1=HALF FILL. Select a module, fill half of its spawn points, move on to the next module, repeat. Spawn excess crew randomly.
	2=SPREAD. Select a module, fill one spawn point in it, move on to the next module, repeat. Spawn excess crew randomly.
	3=RANDOM. Select spawn points completely at random. }
EndGroup

Group TurretProperties collapsedonbase
  Float Property TurretSpawnChance = 0.0 Auto Const
  { DEFAULT=0. Chance that this BE will spawn turrets at all; 0=Never, 1=Always, 0.5=Half the time. }
  Float Property TurretModulePercentChance = 0.5 Auto Const
  { Default=0.5. If this ship has turrets, what percentage of modules should have them?
	The actual number of turrets in each module will be randomly selected between the Min and Max values for that size of module. }
  bescript:genericcrewdatum Property TurretData Auto Const
  { If this ship has turrets, the data for the turrets to spawn. }
  Int Property TurretsToSpawnMin_Small = 1 Auto Const
  { DEFAULT=1. Min turrets to spawn in a Small module that we select to have turrets. }
  Int Property TurretsToSpawnMax_Small = 1 Auto Const
  { DEFAULT=1. Min turrets to spawn in a Small module that we select to have turrets. }
  Int Property TurretsToSpawnMin_Large = 2 Auto Const
  { DEFAULT=1. Min turrets to spawn in a Small module that we select to have turrets. }
  Int Property TurretsToSpawnMax_Large = 3 Auto Const
  { DEFAULT=1. Min turrets to spawn in a Small module that we select to have turrets. }
  Bool Property ShouldTurretsStartUnconscious = False Auto Const
  { DEFAULT=False. If True, spawned turrets will be set unconscious. }
  Bool Property ShouldTurretsStartFriendlyToPlayer = False Auto Const
  { DEFAULT=False. If True, spawned turrets will be set friendly to the player. }
EndGroup

Group ComputerProperties collapsedonbase
  Float Property GenericComputersEnableChance = 1.0 Auto Const
  { DEFAULT=0. Chance that this BE will enable generic computers if robots and/or turrets have spawned.
	0=Never, 1=Always, 0.5=Half the time. }
  Float Property GenericComputersModulePercentChance = 0.25 Auto Const
  { DEFAULT=0.5. If we're enabling generic computers, what percentage of modules should have them? }
  Int Property GenericComputersMax = -1 Auto Const
  { DEFAULT=-1. Maximum number of generic computers to enable. (-1 for no cap.) }
  Int Property GenericComputerRobotLinkStatus = 0 Auto Const
  { DEFAULT=0. Which Computers should get LinkTerminalRobot links to control their robots?
	0=All Computers
	1=Cockpit Computer Only
	2=No Computers }
  Int Property GenericComputerTurretLinkStatus = 0 Auto Const
  { DEFAULT=0. Which Computers should get LinkTerminalTurret links to control their robots?
	0=All Computers
	1=Cockpit Computer Only
	2=No Computers }
  Bool Property ForceEnableCockpitComputer = False Auto Const
  { DEFAULT=False. If True, absolutely always enable the computer in the cockpit. }
  Bool Property ForceEnableGenericComputers = False Auto Const
  { DEFAULT=False. If True, always enable generic computers, even if we don't have any robots or turrets
	to link them to. Any BE setting this to True is responsible for making sure they have content. }
  Bool Property ShouldEnableGenericComputerCockpit = True Auto Const
  { DEFAULT=True. If we're enabling Generic Computers, should we always enable the cockpit computer? }
  Bool Property ShouldPreferGenericComputerThematicModules = True Auto Const
  { DEFAULT=True. If we're enabling Generic Computers, should we always prefer computers in Computer Core
	and Engineering-themed modules, all other restrictions permitting? }
  Float Property GenericComputerLockPercentChance_Cockpit = 0.0 Auto Const
  { DEFAULT=0.0. Chance that the cockpit's generic computer is locked. }
  Float Property GenericComputerLockPercentChance_General = 0.5 Auto Const
  { DEFAULT=0.5. Chance that any other generic computer is locked. }
  Float Property GenericComputerLinkedContainerLockPercentChance = 1.0 Auto Const
  { DEFAULT=1.0. Additional chance that a generic computer's linked container will be locked.
	This is on top of the base chance of locking any given container, and uses the container min and max lock levels. }
  Int Property GenericComputerLockLevelMin = 1 Auto Const
  { DEFAULT=1. Minimum lock level for generic computers we decide to lock. (1=Novice, 2=Advanced, 3=Expert, 4=Master) }
  Int Property GenericComputerLockLevelMax = 2 Auto Const
  { DEFAULT=4. Maximum lock level for generic computers we decide to lock. (1=Novice, 2=Advanced, 3=Expert, 4=Master) }
EndGroup

Group ShipProperties collapsedonbase
  Bool Property ShouldSupportCrewCriticalHit = False Auto Const
  { DEFAULT=False. If True, if a Crew Critical Hit occurs, this ship will decompress and kill its crew. If False, nothing will happen. }
  Hazard Property ShipHazard Auto
  { DEFAULT=None. If set, this hazard will be active throughout the ship. SetShipHazard and ClearShipHazard can be used to change or remove it. }
  Hazard[] Property PotentialHazards Auto
  { Default=None. If set, if ShipHazard is None, a PotentialHazard will be selected at random to become the ShipHazard. }
  Float Property PotentialHazardChance = 1.0 Auto Const
  { Default=1.0. The chance that one of PotentialHazard's Hazards will be used. The default 1.0 means that if ShipHazard is None and PotentialHazards is filled, one will always be used. }
  Bool Property ShouldHaveOxygenAtmosphere = True Auto
  { DEFAULT=True. If True, this ship will have a normal atmosphere. If False, the ship will have no oxygen if it is in space or on a planet with no oxygen. }
  Float Property ShipGravity = -1.0 Auto
  { DEFAULT=-1. If >= 0, Overrides the ship's default gravity. SetShipGravity can be used to change it. }
  Float Property ShipGravityModPercentChance = 0.5 Auto
  { DEFAULT=1. The chance that ShipGravity's Gravity Override will be used. The default 1.0 means that ShipGravity will always be used, 0.5 would apply it half the time, etc. }
  Bool Property ShouldOverrideGravityOnlyInSpace = True Auto Const
  { DEFAULT=True. If True, ShipGravity's override will be used for docking encounters, and ignored for landing encounters, which is usually what you want.
	If False, it will be used for both. Use with caution. }
  Faction Property OwnerFaction Auto
  { DEFAULT=None. If set, this faction will be set as the owner faction of the ship's interior. Items in the cell will be owned, and taking them will be theft.
	Note that this faction must have the 'Can be owner' flag set on the Faction in order for ownership to work. If set, UseAutomaticOwnershipSystem is ignored.
	If this is initially none, but the automatic ownership system sets a faction as this ship's owner, that faction is forced into OwnerFaction. }
  Bool Property UseAutomaticOwnershipSystem = True Auto Const
  { DEFAULT=True. If True, if the ship is in one of the factions in BEAutomaticOwnershipFactionList, the ship's interior will be set owned by that faction. }
  Bool Property ShouldAutoOpenLandingRamp = True Auto Const
  { DEFAULT=True. If True, this ship will automatically open its landing ramp once it has finished landing and spawned disembarking actors (if any). }
  Bool Property PlayHostileAlarmUponBoarding = True Auto Const
  { DEFAULT=True. If True, this ship will play a hostile alarm sound on boarding. }
EndGroup

Group ShipLootAndLockProperties collapsedonbase
  Bool Property ShouldSpawnLoot = True Auto Const
  { DEFAULT=True. Should this BE spawn standard boarding encounter loot in the Captain's Locker on the cockpit/bridge? }
  Float Property ContainersEnabledPercent = 0.5 Auto Const
  { DEFAULT=True. Percent of generic containers on the ship to enable. }
  Bool Property ShouldLockDoors = True Auto Const
  { DEFAULT=True. If this ship has doors in its LockableDoors collection, should we lock some of them?
	LockableDoors should contain only optional internal doors on the ship-- doors to loot closets and side rooms that,
	if locked, won't obstruct the critical path to the cockpit-- so locking them should always be safe from that perspective. }
  Float Property LockPercentChance = 1.0 Auto Const
  { DEFAULT=0.5. If ShouldLockDoors, the percent chance any given door in LockableDoors will be locked (0-1.0). }
  Int Property LockLevelMin = 1 Auto Const
  { DEFAULT=1. Minimum lock level for doors we decide to lock. (1=Novice, 2=Advanced, 3=Expert, 4=Master) }
  Int Property LockLevelMax = 2 Auto Const
  { DEFAULT=4. Maximum lock level for doors we decide to lock. (1=Novice, 2=Advanced, 3=Expert, 4=Master) }
  Bool Property ShouldSpawnContraband = True Auto Const
  { DEFAULT=True. If the ship is part of a qualifying faction, should this BE spawn contraband at small item markers? }
  Float Property ContrabandChancePercent = 0.5 Auto Const
  { DEFAULT=0.5. Chance that the ship will have any contraband at all, if it's in a qualifying faction. }
  Int Property ContrabandMin = 1 Auto Const
  { DEFAULT=1. Minimum amount of contraband to be found on the boarded ship. Contraband will not exceed the number of spawn markers or ContrabandMax. }
  Int Property ContrabandMax = 3 Auto Const
  { DEFAULT=3. Maximum amount of contraband to be found on boarded ship }
EndGroup

Group DisembarkingProperties collapsedonbase
  Bool Property ShouldSetupDisembarkingOnLanding = True Auto Const
  { Default=True. If we have disembarking actors, spawned or placed, should they disembark as soon as the ship lands? If False, you will need to manually trigger disembarking by calling SetupDisembarking. }
  Bool Property ShouldAddDisembarkersToAllCrew = False Auto Const
  { Default=False. Should we add our disembarking actors, spawned or placed, to the AllCrew RefCollectionAlias? }
  Bool Property ShouldSpawnDisembarkers = False Auto Const
  { Default=False. Should this BE spawn generic disembarking actors? Only works for Surface BEs; will be ignored for Docking BEs. }
  Bool Property ShouldForceDisembarkersWeaponsEquipped = False Auto Const
  { Default=False. Should we force disembarkers to wait with weapons equipped?
	 By default, actors in non-civilian factions will have their weapons equipped.
	 This property overrides all other properties and keywords and will be respected. }
  Bool Property ShouldForceDisembarkersWeaponsUnequipped = False Auto Const
  { Default=False. Should we force disembarkers to wait with weapons unequipped?
	 By default, actors in civilian factions will have their weapons unequipped.
	 This property overrides all other properties and keywords (except Equipped). }
  Int Property DisembarkersToSpawn = 0 Auto Const
  { If we do want to spawn generic disembarking actors, how many? }
  bescript:genericcrewdatum[] Property DisembarkerData Auto
  { OPTIONAL. When a BE spawns its disembarkers, it cycles through DisembarkerData (if any) until it's spawned the required number of actors, or runs out of actors it can spawn.
	If DisembarkerData=None, it just continues using the remaining actors in CrewData. }
EndGroup

Group BoardingProperties collapsedonbase
  Bool Property ShouldBoardPlayersShip = True Auto Const
  { DEFAULT=False. If true, the enemy ship's crew will attempt to board the player's ship. }
  RefCollectionAlias Property GenericBoarders Auto Const
  { Mandatory if ShouldBoardPlayersShip; Optional otherwise.
	RefCollectionAlias to push boarders into. Responsible for packaging them to attack the player's ship. }
  ReferenceAlias Property PlayerShipDockingDoor Auto Const
  { Mandatory if ShouldBoardPlayerShip; Optional otherwise.
	The load door in the player's ship leading to the enemy ship. }
  ReferenceAlias Property PlayerShipCockpit Auto Const
  { Mandatory if ShouldBoardPlayersShip; Optional otherwise.
	The player's cockpit module. }
  RefCollectionAlias Property PlayerShipModulesAll Auto Const
  { Mandatory if ShouldBoardPlayersShip; Optional otherwise.
	RefCollection of all of the modules on the player's ship. }
  Float Property MaxPercentOfCrewToBoard = 0.5 Auto Const
  { DEFAULT=0.5. If ShouldBoardPlayersShip, the maximum percentage of the enemy ship's crew that will board the player's ship.
	After MaxPercentOfCrewToBoard have tried to board, the player will have to board the enemy ship to take out the rest-- we don't want
	to completely depopulate it. }
  Float Property MaxSimultaneousBoardersPercent = 0.5 Auto Const
  { DEFAULT=0.5. If ShouldBoardPlayersShip, a cap on the number of enemies that can board the player's ship simultaneously, expressed as a percentage
	of the player's ship's SpaceshipCrewRating value. This prevents, say 25 pirates from piling into the Frontier. }
  Int Property MinBoardingWaveSize = 2 Auto Const
  { DEFAULT=2. The minimum wave size for a wave of enemies boarding the player's ship. }
  Int Property MaxBoardingWaveSize = 6 Auto Const
  { DEFAULT=6. The maximum wave size for a wave of enemies boarding the player's ship. }
EndGroup

Group HeatLeachProperties collapsedonbase
  Float Property HeatLeechChance = 1 Auto Const
  { Default=0. Percent chance that random Heat Leeches will spawn on this ship, 0.0-1.0. }
  Int Property MinHeatLeaches = 1 Auto Const
  { Default=1. If HeatLeechChance > 0 and we do want to spawn Heat Leeches, the minimum number to spawn. }
  Int Property MaxHeatLeaches = 3 Auto Const
  { Default=3. If HeatLeechChance > 0 and we do want to spawn Heat Leeches, the maximum number to spawn. }
EndGroup

Group BEObjectiveProperties collapsedonbase
  Bool Property ShouldUseBEObjective = True Auto
  { Default=True. Should BE_Objective run for this ship, provided all of the aliases below are filled? }
  Quest Property BE_Objective Auto Const mandatory
  { Autofill: The BE_Objective quest. }
  GlobalVariable Property BEObjective_OnceOnly_Global Auto Const mandatory
  { Autofill: The BEObjective_OnceOnly_Global. }
  GlobalVariable Property BEObjective_OnceOnly_DoneGlobal Auto Const mandatory
  { Autofill: The BEObjective_OnceOnly_DoneGlobal. }
  ReferenceAlias Property BEObjective_EnemyShip Auto Const
  { BEObjective's EnemyShip alias. If not filled, BE_Objective will not start. }
  ReferenceAlias Property BEObjective_EnemyShipPilotSeat Auto Const
  { BEObjective's EnemyShipPilotSeat alias. If not filled, BE_Objective will not start. }
  ReferenceAlias Property BEObjective_EnemyShipLoadDoor Auto Const
  { BEObjective's EnemyShipLoadDoor alias. If not filled, BE_Objective will not start. }
  RefCollectionAlias Property BEObjective_AllCrew Auto Const
  { BEObjective's AllCrew alias. }
EndGroup

Group AutofillProperties collapsedonbase
  sq_parentscript Property SQ_Parent Auto Const mandatory
  reparentscript Property RE_Parent Auto Const mandatory
  ReferenceAlias Property PlayerShip Auto Const mandatory
  ReferenceAlias Property EnemyShip Auto Const mandatory
  ReferenceAlias Property ModuleCockpit Auto Const
  ReferenceAlias Property Captain Auto Const
  ReferenceAlias Property CaptainSpawnMarker Auto Const
  ReferenceAlias Property CaptainsLocker Auto Const mandatory
  ReferenceAlias Property LandingDeckControlMarker Auto Const mandatory
  ReferenceAlias Property PlayerShipLoadDoor Auto Const mandatory
  RefCollectionAlias Property AllCrew Auto Const mandatory
  RefCollectionAlias Property AllModules Auto Const mandatory
  RefCollectionAlias Property GenericCrew Auto Const mandatory
  RefCollectionAlias Property GenericCorpses Auto Const mandatory
  RefCollectionAlias Property GenericRobots Auto Const mandatory
  RefCollectionAlias Property GenericTurrets Auto Const mandatory
  RefCollectionAlias Property DisembarkingCrew Auto Const mandatory
  RefCollectionAlias Property EmbarkingCrew Auto Const mandatory
  RefCollectionAlias Property Computers Auto Const mandatory
  RefCollectionAlias Property Containers Auto Const mandatory
  RefCollectionAlias Property LockableDoors Auto Const mandatory
  RefCollectionAlias Property SmallItemSpawnMarkers Auto Const mandatory
  RefCollectionAlias Property Contraband Auto Const mandatory
  RefCollectionAlias Property CrewSpawnMarkers Auto Const mandatory
  RefCollectionAlias Property CombatTargets Auto Const
  LocationAlias Property PlayerShipInteriorLocation Auto Const mandatory
  LocationAlias Property EnemyShipInteriorLocation Auto Const mandatory
  LocationAlias Property EnemyShipExteriorLocation Auto Const mandatory
  GlobalVariable Property BE_ShipCrewSizeSmall Auto Const mandatory
  GlobalVariable Property BE_ShipCrewSizeMedium Auto Const mandatory
  GlobalVariable Property BE_ForceNextGravityOverride Auto Const mandatory
  Keyword Property LinkShipModule Auto Const mandatory
  Keyword Property LinkShipModuleCrewSpawn Auto Const mandatory
  Keyword Property LinkShipModuleTurretSpawn Auto Const mandatory
  Keyword Property LinkShipModuleComputer Auto Const mandatory
  Keyword Property LinkShipLoadDoor Auto Const mandatory
  Keyword Property LinkHazardVolume Auto Const mandatory
  Keyword Property LinkCombatTravelTarget Auto Const mandatory
  Keyword Property LinkTerminalRobot Auto Const mandatory
  Keyword Property LinkTerminalTurret Auto Const mandatory
  Keyword Property LinkTerminalContainer Auto Const mandatory
  Keyword Property BEEncounterTypeDocking Auto Const mandatory
  Keyword Property BEEncounterTypeSurface Auto Const mandatory
  Keyword Property BEMarkerInUseKeyword Auto Const mandatory
  Keyword Property BEBoarderPlayerShipCockpitLink Auto Const mandatory
  Keyword Property BEBoarderPlayerShipModuleLink Auto Const mandatory
  Keyword Property BEDropship Auto Const mandatory
  Keyword Property BEDisembarkerLink Auto Const mandatory
  Keyword Property BEDisembarkerForceWeaponsEquipped Auto Const mandatory
  Keyword Property BEDisembarkerForceWeaponsUnequipped Auto Const mandatory
  Keyword Property BECrewAttackerKeyword Auto Const mandatory
  Keyword Property BECrewDefenderKeyword Auto Const mandatory
  Keyword Property BENoCrewKeyword Auto Const mandatory
  Keyword Property BESurfaceCrewSize_NoCrew Auto Const mandatory
  Keyword Property BENoTakeoverObjectiveKeyword Auto Const mandatory
  Keyword Property BENoAutomaticOwnershipKeyword Auto Const mandatory
  Keyword Property BEHostileBoardingEncounterKeyword Auto Const mandatory
  Keyword Property ActorTypeTurret Auto Const mandatory
  Keyword Property ActorTypeRobot Auto Const mandatory
  Keyword Property ENV_Loc_NotSealedEnvironment Auto Const mandatory
  Keyword Property DynamicallyLinkedDoorTeleportMarkerKeyword Auto Const mandatory
  Keyword Property LootSafeKeyword Auto Const mandatory
  Keyword Property SpaceshipPreventRampOpenOnLanding Auto Const
  ; added keywords
  Keyword Property BE_Hazard_Keyword04_CorrosiveGas Auto Const mandatory
  Keyword Property BE_Hazard_Keyword16_ElectricalField Auto Const mandatory
  Keyword Property BE_Hazard_Keyword21_RadiationNuclearMaterial Auto Const mandatory
  Keyword Property BE_Hazard_Keyword23_ToxicGasLeak Auto Const mandatory
  ; end
  Faction Property REPlayerFriend Auto Const mandatory
  FormList Property BEAutomaticOwnershipFactionList Auto Const mandatory
  FormList Property BECivilianShipFactionList Auto Const mandatory
  FormList Property BEContrabandShipFactionList Auto Const mandatory
  FormList Property BEHazardKeywordList Auto Const
  FormList Property BEHazardFormList Auto Const
  ActorBase Property ParasiteA_HeatLeech Auto Const mandatory
  ActorValue Property Aggression Auto Const mandatory
  ActorValue Property Confidence Auto Const mandatory
  ActorValue Property Suspicious Auto Const mandatory
  ActorValue Property SpaceshipCrew Auto Const mandatory
  ActorValue Property SpaceshipCrewRating Auto Const mandatory
  ActorValue Property SpaceshipCriticalHitCrew Auto Const mandatory
  ActorValue Property BEBoarderCapturedModule Auto Const mandatory
  ActorValue Property BEWaitingForLandingRampValue Auto Const mandatory
  ActorValue Property BEDisembarkWithWeaponsDrawnValue Auto Const mandatory
  LocationRefType Property Ship_CrewSpawn_RefType Auto Const mandatory
  LocationRefType Property Ship_TurretSpawn_RefType Auto Const mandatory
  LocationRefType Property Ship_Computer_RefType Auto Const mandatory
  LocationRefType Property Ship_Module_Computer_RefType Auto Const mandatory
  LocationRefType Property Ship_Module_Engineering_RefType Auto Const mandatory
  LocationRefType Property Ship_Module_Small_RefType Auto Const mandatory
  LocationRefType Property Ship_Module_Large_RefType Auto Const mandatory
  LeveledItem Property LL_BE_ShipCaptainsLockerLoot_Small Auto Const mandatory
  LeveledItem Property LL_BE_ShipCaptainsLockerLoot_Medium Auto Const mandatory
  LeveledItem Property LL_BE_ShipCaptainsLockerLoot_Large Auto Const mandatory
  LeveledItem Property Loot_LPI_Contraband_Any Auto Const mandatory
  sq_playershipscript Property SQ_PlayerShip Auto Const
  wwiseevent Property OBJ_Alarm_BoardingAlert Auto Const
EndGroup

Group DebugProperties
  Bool Property UseSecondLinkedRefAsCombatTravelTarget = False Auto Const
  Bool Property ShowTraces = True Auto Const
EndGroup

Int Property CONST_SpawnPattern_Fill = 0 Auto Const hidden
Int Property CONST_SpawnPattern_Half = 1 Auto Const hidden
Int Property CONST_SpawnPattern_Spread = 2 Auto Const hidden
Int Property CONST_SpawnPattern_Random = 3 Auto Const hidden
Int Property CONST_SpawnPrioritization_None = 0 Auto Const hidden
Int Property CONST_SpawnPrioritization_CockpitLargeSmall = 1 Auto Const hidden
Int Property CONST_GenericComputerLinkStatus_All = 0 Auto Const hidden
Int Property CONST_GenericComputerLinkStatus_CockpitOnly = 1 Auto Const hidden
Int Property CONST_GenericComputerLinkStatus_None = 2 Auto Const hidden

;-- Functions ---------------------------------------

Event OnQuestStarted()
  player = Game.GetPlayer() ; #DEBUG_LINE_NO:566
  playerShipInteriorLoc = PlayerShipInteriorLocation.GetLocation() ; #DEBUG_LINE_NO:567
  enemyShipInteriorLoc = EnemyShipInteriorLocation.GetLocation() ; #DEBUG_LINE_NO:568
  enemyShipRef = EnemyShip.GetRef() as spaceshipreference ; #DEBUG_LINE_NO:569
  enemyShipCockpit = ModuleCockpit.GetRef() ; #DEBUG_LINE_NO:570
  enemyShipCell = enemyShipCockpit.GetParentCell() ; #DEBUG_LINE_NO:571
  enemyShipCrimeFaction = enemyShipRef.GetCrimeFaction() ; #DEBUG_LINE_NO:572
  isSurfaceEncounter = enemyShipRef.GetWorldspace() == None ; #DEBUG_LINE_NO:573
  isSurfaceEncounter = !isSurfaceEncounter ; #DEBUG_LINE_NO:573
  isDropshipEncounter = enemyShipRef.HasKeyword(BEDropship) ; #DEBUG_LINE_NO:574
  allCrewSpawnPoints = new ObjectReference[0] ; #DEBUG_LINE_NO:575
  robots = new Actor[0] ; #DEBUG_LINE_NO:576
  turrets = new Actor[0] ; #DEBUG_LINE_NO:577
  BEAliasCorpses = new Actor[0] ; #DEBUG_LINE_NO:578
  If isDropshipEncounter ; #DEBUG_LINE_NO:581
    ShutDownOnUnload = False ; #DEBUG_LINE_NO:583
  Else ; #DEBUG_LINE_NO:
    If isSurfaceEncounter ; #DEBUG_LINE_NO:589
      If ShowTraces ; #DEBUG_LINE_NO:
         ; #DEBUG_LINE_NO:
      EndIf ; #DEBUG_LINE_NO:
      enemyShipRef.SetExteriorLoadDoorInaccessible(False) ; #DEBUG_LINE_NO:592
    EndIf ; #DEBUG_LINE_NO:
    If ShouldCrewStartInCombat && !isSurfaceEncounter ; #DEBUG_LINE_NO:595
      crewSuspiciousState = CONST_Suspicious_DetectedActor ; #DEBUG_LINE_NO:596
      enemyShipRef.AddKeyword(BEHostileBoardingEncounterKeyword) ; #DEBUG_LINE_NO:597
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  Self.RegisterForRemoteEvent(player as ScriptObject, "OnLocationChange") ; #DEBUG_LINE_NO:602
  Self.RegisterForRemoteEvent(enemyShipCockpit as ScriptObject, "OnCellLoad") ; #DEBUG_LINE_NO:603
  Self.RegisterForRemoteEvent(enemyShipRef as ScriptObject, "OnLoad") ; #DEBUG_LINE_NO:604
  Self.RegisterForCustomEvent(SQ_PlayerShip as ScriptObject, "sq_playershipscript_SQ_PlayerShipChanged") ; #DEBUG_LINE_NO:605
  If ShouldSupportCrewCriticalHit && !isSurfaceEncounter && !Self.CheckForCrewCriticalHit() ; #DEBUG_LINE_NO:606
    Self.RegisterForActorValueChangedEvent(enemyShipRef as ObjectReference, SpaceshipCriticalHitCrew) ; #DEBUG_LINE_NO:607
  EndIf ; #DEBUG_LINE_NO:
  If ShutDownOnUndock ; #DEBUG_LINE_NO:609
    Self.RegisterForRemoteEvent(enemyShipRef as ScriptObject, "OnShipUndock") ; #DEBUG_LINE_NO:610
  EndIf ; #DEBUG_LINE_NO:
  If ShutDownOnUnload ; #DEBUG_LINE_NO:612
    Self.RegisterForRemoteEvent(enemyShipRef as ScriptObject, "OnUnload") ; #DEBUG_LINE_NO:613
  EndIf ; #DEBUG_LINE_NO:
  If isSurfaceEncounter ; #DEBUG_LINE_NO:617
    SQ_PlayerShip.ClearLandingZone(enemyShipRef) ; #DEBUG_LINE_NO:618
  EndIf ; #DEBUG_LINE_NO:
  If !isDropshipEncounter ; #DEBUG_LINE_NO:621
    Self.BuildModuleData() ; #DEBUG_LINE_NO:623
    If OwnerFaction != None ; #DEBUG_LINE_NO:626
      enemyShipCell.SetFactionOwner(OwnerFaction) ; #DEBUG_LINE_NO:627
    ElseIf UseAutomaticOwnershipSystem && !enemyShipRef.HasKeyword(BENoAutomaticOwnershipKeyword) ; #DEBUG_LINE_NO:628
      Faction[] ownerFactions = BEAutomaticOwnershipFactionList.GetArray(False) as Faction[] ; #DEBUG_LINE_NO:629
      Bool ownerFound = False ; #DEBUG_LINE_NO:630
      Int i = 0 ; #DEBUG_LINE_NO:631
      While !ownerFound && i < ownerFactions.Length ; #DEBUG_LINE_NO:632
        If enemyShipRef.IsInFaction(ownerFactions[i]) ; #DEBUG_LINE_NO:633
          enemyShipCell.SetFactionOwner(ownerFactions[i]) ; #DEBUG_LINE_NO:634
          OwnerFaction = ownerFactions[i] ; #DEBUG_LINE_NO:635
          ownerFound = True ; #DEBUG_LINE_NO:636
        EndIf ; #DEBUG_LINE_NO:
        i += 1 ; #DEBUG_LINE_NO:638
      EndWhile ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    If OwnerFaction != None ; #DEBUG_LINE_NO:641
      enemyShipCell.SetOffLimits(True) ; #DEBUG_LINE_NO:642
    EndIf ; #DEBUG_LINE_NO:
    crewSizePercent = enemyShipRef.GetValue(SpaceshipCrew) / enemyShipRef.GetBaseValue(SpaceshipCrew) ; #DEBUG_LINE_NO:646
    If ShouldSpawnCrew && CrewData != None ; #DEBUG_LINE_NO:647
      genericCrewSize = Self.SetupGenericCrew(CrewData, CrewCountPercent, CrewCountOverride, CrewSpawnPattern, CONST_SpawnPrioritization_CockpitLargeSmall, False) ; #DEBUG_LINE_NO:648
      Int spaceshipCrewValue = enemyShipRef.GetValue(SpaceshipCrew) as Int ; #DEBUG_LINE_NO:650
      If genericCrewSize < spaceshipCrewValue ; #DEBUG_LINE_NO:651
        If ShowTraces ; #DEBUG_LINE_NO:
           ; #DEBUG_LINE_NO:
        EndIf ; #DEBUG_LINE_NO:
        enemyShipRef.SetValue(SpaceshipCrew, genericCrewSize as Float) ; #DEBUG_LINE_NO:655
      EndIf ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    If ShouldSpawnCorpses ; #DEBUG_LINE_NO:658
      If CorpseData == None ; #DEBUG_LINE_NO:659
        CorpseData = CrewData ; #DEBUG_LINE_NO:660
      EndIf ; #DEBUG_LINE_NO:
      If CorpseData != None ; #DEBUG_LINE_NO:662
        Self.SetupGenericCrew(CorpseData, CorpseCountPercent, CorpseCountOverride, CorpseSpawnPattern, CONST_SpawnPrioritization_None, True) ; #DEBUG_LINE_NO:663
      EndIf ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    If TurretData != None && TurretSpawnChance > 0.0 && TurretModulePercentChance > 0.0 && Utility.RandomFloat(0.0, 1.0) < TurretSpawnChance ; #DEBUG_LINE_NO:666
      Int turretsSpawned = Self.SetupTurrets() ; #DEBUG_LINE_NO:667
      enemyShipRef.SetValue(SpaceshipCrew, enemyShipRef.GetValue(SpaceshipCrew) + turretsSpawned as Float) ; #DEBUG_LINE_NO:668
    EndIf ; #DEBUG_LINE_NO:
    If HeatLeechChance > 0.0 && Utility.RandomFloat(0.0, 1.0) < HeatLeechChance ; #DEBUG_LINE_NO:670
    ;   Debug.Notification("Spawning heat leeches")
      Self.SetupHeatLeeches() ; #DEBUG_LINE_NO:671
    EndIf ; #DEBUG_LINE_NO:
    Keyword[] hazardKeywords = BEHazardKeywordList.GetArray(False) as Keyword[] ; #DEBUG_LINE_NO:675
    Hazard[] hazardType = BEHazardFormList.GetArray(False) as Hazard[] ; #DEBUG_LINE_NO:676
    Int I = 0 ; #DEBUG_LINE_NO:677
    Bool hazardChosen = False ; #DEBUG_LINE_NO:678

    ; ===== WORK IN PROGRESS ===== 


    If ShouldCrewStartInCombat  
      PotentialHazards = new Hazard[0]

      ; acceptable space hazards from the array
      ; BE_Hazard_Keyword04_CorrosiveGas
      PotentialHazards.add(hazardType[3],1) 
      ; BE_Hazard_Keyword16_ElectricalField
      PotentialHazards.add(hazardType[15],1) 
      ; BE_Hazard_Keyword21_RadiationNuclearMaterial
      PotentialHazards.add(hazardType[20],1) 
      ; BE_Hazard_Keyword23_ToxicGasLeak
      PotentialHazards.add(hazardType[22],1) 
    EndIf

    ; redfine the hazard list to only include the ones we want



    ; Debug.Notification("PotentialHazards.Length: " + PotentialHazards.Length)
    ; Int J = 0 ;

    ; While J < PotentialHazards.Length ; 
    ;   Debug.Trace(J+" - PotentialHazards: " + PotentialHazards[J],0)
    ;   J += 1 ;
    ; EndWhile
    


    ; debug notify for each in the list of BEHazardKeywordList
    ; Debug.Notification("Hazard keywords: " + hazardKeywords.Length + ". Hazard types: " + hazardType.Length)

    ; Int J = 0 ; 
    ; While J < hazardKeywords.Length ; 
    ;   Debug.Trace(J+" - setting hazard to: " + hazardType[J] + "keyword:" + hazardKeywords[J],0)
    ;   J += 1 ; 
    ; EndWhile
    ; Debug.Notification("setting hazard to: " + hazardType[0] + "keyword:" + hazardKeywords[0])
    ; 1=gas
    ; 2=spores
    ; 3=

    ; ShipHazard = hazardType[1]
    ; hazardChosen = True

    ; enemyShipRef.AddKeyword(hazardKeywords[0]) ; #DEBUG_LINE_NO:678

    While I < hazardKeywords.Length && hazardChosen == False ; #DEBUG_LINE_NO:679
      If enemyShipRef.HasKeyword(hazardKeywords[I]) ; #DEBUG_LINE_NO:680
        Debug.Notification("Hazard pick off keyword selection: " + hazardType[I] + "keyword:" + hazardKeywords[I])
        ShipHazard = hazardType[I] ; #DEBUG_LINE_NO:681
        hazardChosen = True ; #DEBUG_LINE_NO:682
      EndIf ; #DEBUG_LINE_NO:
      I += 1 ; #DEBUG_LINE_NO:684
    EndWhile ; #DEBUG_LINE_NO:

    If ShipHazard == None && PotentialHazards != None && PotentialHazards.Length > 0 && Utility.RandomFloat(0.0, 1.0) < PotentialHazardChance ; #DEBUG_LINE_NO:686
      Int R = Utility.RandomInt(0, PotentialHazards.Length - 1)
      Debug.Notification("ALERT. HAZARD: " + PotentialHazards[R])
      ShipHazard = PotentialHazards[R] ; #DEBUG_LINE_NO:687
      ShouldHaveOxygenAtmosphere = False ; #DEBUG_LINE_NO:688
    EndIf ; #DEBUG_LINE_NO:
    If ShipHazard != None ; #DEBUG_LINE_NO:689
      Self.SetShipHazard(ShipHazard) ; #DEBUG_LINE_NO:690
    EndIf ; #DEBUG_LINE_NO:
    If !ShouldHaveOxygenAtmosphere ; #DEBUG_LINE_NO:694
      Debug.Notification("airless enviroment")
      enemyShipInteriorLoc.AddKeyword(ENV_Loc_NotSealedEnvironment) ; #DEBUG_LINE_NO:695
    EndIf ; #DEBUG_LINE_NO:
    If ShipGravity >= 0.0 && ShipHazard == None ; #DEBUG_LINE_NO:699
      If ShipGravityModPercentChance < 0.0 || ShipGravityModPercentChance >= 1.0 || Utility.RandomFloat(0.0, 1.0) < ShipGravityModPercentChance ; #DEBUG_LINE_NO:700
        Self.SetShipGravity(ShipGravity) ; #DEBUG_LINE_NO:702
      ElseIf BE_ForceNextGravityOverride != None && BE_ForceNextGravityOverride.GetValue() >= 0.0 ; #DEBUG_LINE_NO:703
        Self.SetShipGravity(BE_ForceNextGravityOverride.GetValue()) ; #DEBUG_LINE_NO:705
        BE_ForceNextGravityOverride.SetValue(-1.0) ; #DEBUG_LINE_NO:706
      Else ; #DEBUG_LINE_NO:
        Self.SetShipGravity(1.0) ; #DEBUG_LINE_NO:708
      EndIf ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    If Self.CheckForCrewCriticalHit() ; #DEBUG_LINE_NO:713
      Self.DecompressShipAndKillCrew() ; #DEBUG_LINE_NO:714
    EndIf ; #DEBUG_LINE_NO:
    ObjectReference[] containerRefs = commonarrayfunctions.CopyAndRandomizeObjArray(Containers.GetArray()) ; #DEBUG_LINE_NO:718
    Int containerDisableCount = (containerRefs.Length as Float * (1.0 - ContainersEnabledPercent)) as Int ; #DEBUG_LINE_NO:719
    I = 0 ; #DEBUG_LINE_NO:720
    While I < containerRefs.Length ; #DEBUG_LINE_NO:721
      If I < containerDisableCount ; #DEBUG_LINE_NO:722
        containerRefs[I].DisableNoWait(False) ; #DEBUG_LINE_NO:723
      ElseIf containerRefs[I].HasKeyword(LootSafeKeyword) ; #DEBUG_LINE_NO:724
        containerRefs[I].Lock(True, False, True) ; #DEBUG_LINE_NO:725
        containerRefs[I].SetLockLevel(Utility.RandomInt(LockLevelMin, LockLevelMax) * 25) ; #DEBUG_LINE_NO:726
      EndIf ; #DEBUG_LINE_NO:
      I += 1 ; #DEBUG_LINE_NO:728
    EndWhile ; #DEBUG_LINE_NO:
    If ShouldSpawnContraband ; #DEBUG_LINE_NO:732
      Float RandomFloat = Utility.RandomFloat(0.0, 1.0) ; #DEBUG_LINE_NO:733
      If RandomFloat <= ContrabandChancePercent ; #DEBUG_LINE_NO:734
        Faction[] contrabandShipFactions = BEContrabandShipFactionList.GetArray(False) as Faction[] ; #DEBUG_LINE_NO:736
        I = 0 ; #DEBUG_LINE_NO:737
        Bool contrabandFactionFound = False ; #DEBUG_LINE_NO:738
        While I < contrabandShipFactions.Length && contrabandFactionFound == False ; #DEBUG_LINE_NO:739
          If enemyShipRef.IsInFaction(contrabandShipFactions[I]) ; #DEBUG_LINE_NO:740
            Self.SpawnContraband() ; #DEBUG_LINE_NO:741
            contrabandFactionFound = True ; #DEBUG_LINE_NO:742
          EndIf ; #DEBUG_LINE_NO:
          I += 1 ; #DEBUG_LINE_NO:744
        EndWhile ; #DEBUG_LINE_NO:
      EndIf ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    If ShouldLockDoors ; #DEBUG_LINE_NO:750
      I = 0 ; #DEBUG_LINE_NO:751
      While I < LockableDoors.GetCount() ; #DEBUG_LINE_NO:752
        If Utility.RandomFloat(0.0, 1.0) < LockPercentChance ; #DEBUG_LINE_NO:753
          ObjectReference currentDoor = LockableDoors.GetAt(I) ; #DEBUG_LINE_NO:754
          currentDoor.Lock(True, False, True) ; #DEBUG_LINE_NO:755
          currentDoor.SetLockLevel(Utility.RandomInt(LockLevelMin, LockLevelMax) * 25) ; #DEBUG_LINE_NO:756
        EndIf ; #DEBUG_LINE_NO:
        I += 1 ; #DEBUG_LINE_NO:758
      EndWhile ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    Self.SetupComputers() ; #DEBUG_LINE_NO:763
  EndIf ; #DEBUG_LINE_NO:
  If isSurfaceEncounter ; #DEBUG_LINE_NO:767
    ObjectReference[] myDisembarkers = enemyShipRef.GetRefsLinkedToMe(BEDisembarkerLink, None) ; #DEBUG_LINE_NO:769
    If ShowTraces ; #DEBUG_LINE_NO:
       ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    DisembarkingCrew.AddArray(myDisembarkers) ; #DEBUG_LINE_NO:773
    If ShouldSpawnDisembarkers ; #DEBUG_LINE_NO:776
      If DisembarkerData == None ; #DEBUG_LINE_NO:777
        DisembarkerData = CrewData ; #DEBUG_LINE_NO:778
      EndIf ; #DEBUG_LINE_NO:
      Self.SpawnGenericActors(DisembarkerData, DisembarkersToSpawn, None, False, True) ; #DEBUG_LINE_NO:780
    EndIf ; #DEBUG_LINE_NO:
    If ShouldForceDisembarkersWeaponsEquipped ; #DEBUG_LINE_NO:784
      disembarkersShouldHaveWeaponsUnequipped = False ; #DEBUG_LINE_NO:785
    ElseIf ShouldForceDisembarkersWeaponsUnequipped ; #DEBUG_LINE_NO:
      disembarkersShouldHaveWeaponsUnequipped = True ; #DEBUG_LINE_NO:787
    ElseIf enemyShipRef.HasKeyword(BEDisembarkerForceWeaponsUnequipped) ; #DEBUG_LINE_NO:788
      disembarkersShouldHaveWeaponsUnequipped = False ; #DEBUG_LINE_NO:789
    ElseIf enemyShipRef.HasKeyword(BEDisembarkerForceWeaponsEquipped) ; #DEBUG_LINE_NO:790
      disembarkersShouldHaveWeaponsUnequipped = True ; #DEBUG_LINE_NO:791
    ElseIf OwnerFaction != None ; #DEBUG_LINE_NO:794
      disembarkersShouldHaveWeaponsUnequipped = BECivilianShipFactionList.Find(OwnerFaction as Form) >= 0 ; #DEBUG_LINE_NO:795
    Else ; #DEBUG_LINE_NO:
      Faction[] civilianShipFactions = BECivilianShipFactionList.GetArray(False) as Faction[] ; #DEBUG_LINE_NO:797
      Int i = 0 ; #DEBUG_LINE_NO:798
      While !disembarkersShouldHaveWeaponsUnequipped && i < civilianShipFactions.Length ; #DEBUG_LINE_NO:799
        If enemyShipRef.IsInFaction(civilianShipFactions[i]) ; #DEBUG_LINE_NO:800
          disembarkersShouldHaveWeaponsUnequipped = True ; #DEBUG_LINE_NO:801
        EndIf ; #DEBUG_LINE_NO:
        i += 1 ; #DEBUG_LINE_NO:803
      EndWhile ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    If ShouldSetupDisembarkingOnLanding ; #DEBUG_LINE_NO:808
      Self.RegisterForRemoteEvent(enemyShipRef as ScriptObject, "OnShipLanding") ; #DEBUG_LINE_NO:809
      Self.RegisterForRemoteEvent(enemyShipRef as ScriptObject, "OnShipRampDown") ; #DEBUG_LINE_NO:810
      Self.SetupDisembarking() ; #DEBUG_LINE_NO:811
    Else ; #DEBUG_LINE_NO:
      Self.RegisterForRemoteEvent(enemyShipRef as ScriptObject, "OnShipLanding") ; #DEBUG_LINE_NO:813
      If ShouldAutoOpenLandingRamp && enemyShipRef.IsLanded() ; #DEBUG_LINE_NO:814
        Self.SetEnemyShipLandingRampsOpenState(ShouldAutoOpenLandingRamp) ; #DEBUG_LINE_NO:815
      EndIf ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  If ShouldBoardPlayersShip ; #DEBUG_LINE_NO:821
    playerShipRef = PlayerShip.GetRef() as spaceshipreference ; #DEBUG_LINE_NO:823
    playerShipDockingDoorRef = PlayerShipDockingDoor.GetRef() ; #DEBUG_LINE_NO:824
    playerShipCockpitRef = PlayerShipCockpit.GetRef() ; #DEBUG_LINE_NO:825
    playerShipModulesAllRefs = PlayerShipModulesAll.GetArray() ; #DEBUG_LINE_NO:826
    maxSimultaneousBoarders = Math.Max(Math.Round(playerShipRef.GetValue(SpaceshipCrewRating) * MaxSimultaneousBoardersPercent) as Float, MinBoardingWaveSize as Float) as Int ; #DEBUG_LINE_NO:827
    Int remainingBoardersCount = Math.Round(GenericCrew.GetCount() as Float * MaxPercentOfCrewToBoard) ; #DEBUG_LINE_NO:833
    Int potentialBoardersCount = GenericCrew.GetCount() - remainingBoardersCount ; #DEBUG_LINE_NO:834
    remainingBoarders = new Actor[remainingBoardersCount] ; #DEBUG_LINE_NO:835
    potentialBoarders = new Actor[potentialBoardersCount] ; #DEBUG_LINE_NO:836
    Int i = GenericCrew.GetCount() - 1 ; #DEBUG_LINE_NO:837
    While i >= 0 && remainingBoardersCount > 0 ; #DEBUG_LINE_NO:838
      remainingBoarders[remainingBoardersCount - 1] = GenericCrew.GetAt(i) as Actor ; #DEBUG_LINE_NO:839
      remainingBoardersCount -= 1 ; #DEBUG_LINE_NO:840
      i -= 1 ; #DEBUG_LINE_NO:841
    EndWhile ; #DEBUG_LINE_NO:
    While i >= 0 && potentialBoardersCount > 0 ; #DEBUG_LINE_NO:843
      potentialBoarders[potentialBoardersCount - 1] = GenericCrew.GetAt(i) as Actor ; #DEBUG_LINE_NO:844
      potentialBoardersCount -= 1 ; #DEBUG_LINE_NO:845
      i -= 1 ; #DEBUG_LINE_NO:846
    EndWhile ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  hasInitialized = True ; #DEBUG_LINE_NO:851
  If ShouldBoardPlayersShip ; #DEBUG_LINE_NO:854
    Self.RegisterForRemoteEvent(enemyShipRef as ScriptObject, "OnShipDock") ; #DEBUG_LINE_NO:855
    If enemyShipRef.IsDocked() ; #DEBUG_LINE_NO:856
      Self.UnregisterForRemoteEvent(enemyShipRef as ScriptObject, "OnShipDock") ; #DEBUG_LINE_NO:857
      Self.UpdateBoarding() ; #DEBUG_LINE_NO:858
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  Self.RegisterForCustomEvent(SQ_Parent as ScriptObject, "sq_parentscript_SQ_BEForceStop") ; #DEBUG_LINE_NO:863
  SQ_Parent.SendBEStartedEvent(enemyShipRef as ObjectReference, Self) ; #DEBUG_LINE_NO:866
  If ShowTraces ; #DEBUG_LINE_NO:
     ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
EndEvent

Function BuildModuleData()
  ObjectReference[] modulesWithCrew = AllModules.GetArray() ; #DEBUG_LINE_NO:875
  Float startTime = Utility.GetCurrentRealTime() ; #DEBUG_LINE_NO:876
  Int I = 0 ; #DEBUG_LINE_NO:877
  While I < modulesWithCrew.Length ; #DEBUG_LINE_NO:878
    If modulesWithCrew[I].HasKeyword(BENoCrewKeyword) || !modulesWithCrew[I].HasLocRefType(Ship_Module_Small_RefType) && modulesWithCrew[I] != enemyShipCockpit ; #DEBUG_LINE_NO:879
      modulesWithCrew.remove(I, 1) ; #DEBUG_LINE_NO:880
      I -= 1 ; #DEBUG_LINE_NO:881
    EndIf ; #DEBUG_LINE_NO:
    I += 1 ; #DEBUG_LINE_NO:883
  EndWhile ; #DEBUG_LINE_NO:
  moduleData = new bescript:moduledatum[modulesWithCrew.Length] ; #DEBUG_LINE_NO:885
  I = 0 ; #DEBUG_LINE_NO:886
  While I < moduleData.Length ; #DEBUG_LINE_NO:887
    ObjectReference currentModuleRef = modulesWithCrew[I] ; #DEBUG_LINE_NO:888
    ObjectReference[] crewSpawnRefs = currentModuleRef.GetRefsLinkedToMe(LinkShipModuleCrewSpawn, None) ; #DEBUG_LINE_NO:889
    ObjectReference[] turretSpawnRefs = currentModuleRef.GetRefsLinkedToMe(LinkShipModuleTurretSpawn, None) ; #DEBUG_LINE_NO:890
    ObjectReference[] computerRefs = currentModuleRef.GetRefsLinkedToMe(LinkShipModuleComputer, None) ; #DEBUG_LINE_NO:891
    bescript:moduledatum currentModuleData = new bescript:moduledatum ; #DEBUG_LINE_NO:892
    currentModuleData.moduleRef = currentModuleRef ; #DEBUG_LINE_NO:893
    If crewSpawnRefs.Length >= 1 ; #DEBUG_LINE_NO:894
      currentModuleData.shipCrewSpawnMarkerRef01 = crewSpawnRefs[0] ; #DEBUG_LINE_NO:895
      If crewSpawnRefs.Length >= 2 ; #DEBUG_LINE_NO:896
        currentModuleData.shipCrewSpawnMarkerRef02 = crewSpawnRefs[1] ; #DEBUG_LINE_NO:897
        If crewSpawnRefs.Length >= 3 ; #DEBUG_LINE_NO:898
          currentModuleData.shipCrewSpawnMarkerRef03 = crewSpawnRefs[2] ; #DEBUG_LINE_NO:899
          If crewSpawnRefs.Length >= 4 ; #DEBUG_LINE_NO:900
            currentModuleData.shipCrewSpawnMarkerRef04 = crewSpawnRefs[3] ; #DEBUG_LINE_NO:901
            If crewSpawnRefs.Length >= 5 ; #DEBUG_LINE_NO:902
              currentModuleData.shipCrewSpawnMarkerRef05 = crewSpawnRefs[4] ; #DEBUG_LINE_NO:903
            EndIf ; #DEBUG_LINE_NO:
          EndIf ; #DEBUG_LINE_NO:
        EndIf ; #DEBUG_LINE_NO:
      EndIf ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    Int j = 0 ; #DEBUG_LINE_NO:909
    While j < crewSpawnRefs.Length ; #DEBUG_LINE_NO:910
      allCrewSpawnPoints.add(crewSpawnRefs[j], 1) ; #DEBUG_LINE_NO:911
      j += 1 ; #DEBUG_LINE_NO:912
    EndWhile ; #DEBUG_LINE_NO:
    If turretSpawnRefs.Length >= 1 ; #DEBUG_LINE_NO:914
      currentModuleData.shipTurretSpawnMarkerRef01 = turretSpawnRefs[0] ; #DEBUG_LINE_NO:915
      If turretSpawnRefs.Length >= 2 ; #DEBUG_LINE_NO:916
        currentModuleData.shipTurretSpawnMarkerRef02 = turretSpawnRefs[1] ; #DEBUG_LINE_NO:917
        If turretSpawnRefs.Length >= 3 ; #DEBUG_LINE_NO:918
          currentModuleData.shipTurretSpawnMarkerRef03 = turretSpawnRefs[2] ; #DEBUG_LINE_NO:919
          If turretSpawnRefs.Length >= 4 ; #DEBUG_LINE_NO:920
            currentModuleData.shipTurretSpawnMarkerRef04 = turretSpawnRefs[3] ; #DEBUG_LINE_NO:921
            If turretSpawnRefs.Length >= 5 ; #DEBUG_LINE_NO:922
              currentModuleData.shipTurretSpawnMarkerRef05 = turretSpawnRefs[4] ; #DEBUG_LINE_NO:923
            EndIf ; #DEBUG_LINE_NO:
          EndIf ; #DEBUG_LINE_NO:
        EndIf ; #DEBUG_LINE_NO:
      EndIf ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    If computerRefs.Length >= 1 ; #DEBUG_LINE_NO:929
      currentModuleData.shipComputerRef = computerRefs[0] ; #DEBUG_LINE_NO:930
    EndIf ; #DEBUG_LINE_NO:
    moduleData[I] = currentModuleData ; #DEBUG_LINE_NO:932
    I += 1 ; #DEBUG_LINE_NO:933
  EndWhile ; #DEBUG_LINE_NO:
  If allCrewSpawnPoints.Length == 0 ; #DEBUG_LINE_NO:935
    allCrewSpawnPoints = CrewSpawnMarkers.GetArray() ; #DEBUG_LINE_NO:937
  EndIf ; #DEBUG_LINE_NO:
  modulesWithCrew = AllModules.GetArray() ; #DEBUG_LINE_NO:941
EndFunction

Event Actor.OnLocationChange(Actor akSource, Location akOldLoc, Location akNewLoc)
  If akSource == Game.GetPlayer() ; #DEBUG_LINE_NO:948
    If akNewLoc == enemyShipInteriorLoc ; #DEBUG_LINE_NO:949
      If ShouldUseBEObjective ; #DEBUG_LINE_NO:951
        If enemyShipRef.HasKeyword(BENoTakeoverObjectiveKeyword) ; #DEBUG_LINE_NO:955
          ShouldUseBEObjective = False ; #DEBUG_LINE_NO:957
        ElseIf enemyShipRef.HasKeyword(BESurfaceCrewSize_NoCrew) ; #DEBUG_LINE_NO:958
          ShouldUseBEObjective = False ; #DEBUG_LINE_NO:960
        ElseIf BEObjective_OnceOnly_Global.GetValue() == 1.0 && BEObjective_OnceOnly_DoneGlobal.GetValue() == 1.0 ; #DEBUG_LINE_NO:961
          ShouldUseBEObjective = False ; #DEBUG_LINE_NO:963
        ElseIf BEObjective_EnemyShip == None || BEObjective_EnemyShipPilotSeat == None || BEObjective_EnemyShipLoadDoor == None || BEObjective_AllCrew == None ; #DEBUG_LINE_NO:964
          ShouldUseBEObjective = False ; #DEBUG_LINE_NO:966
        Else ; #DEBUG_LINE_NO:
          BE_Objective.SetStage(CONST_BEObjective_Startup) ; #DEBUG_LINE_NO:969
          BEObjective_EnemyShip.ForceRefTo(enemyShipRef as ObjectReference) ; #DEBUG_LINE_NO:970
          BEObjective_EnemyShip.RefillDependentAliases() ; #DEBUG_LINE_NO:971
          If BEObjective_EnemyShipPilotSeat.GetRef() == None || BEObjective_EnemyShipLoadDoor.GetRef() == None ; #DEBUG_LINE_NO:974
            ShouldUseBEObjective = False ; #DEBUG_LINE_NO:975
          Else ; #DEBUG_LINE_NO:
            If enemyShipRef.GetValue(SpaceshipCrew) > 0.0 ; #DEBUG_LINE_NO:977
              Int I = 0 ; #DEBUG_LINE_NO:979
              While I < AllCrew.GetCount() ; #DEBUG_LINE_NO:980
                Actor current = AllCrew.GetAt(I) as Actor ; #DEBUG_LINE_NO:981
                If !current.IsDead() ; #DEBUG_LINE_NO:982
                  BEObjective_AllCrew.AddRef(current as ObjectReference) ; #DEBUG_LINE_NO:983
                EndIf ; #DEBUG_LINE_NO:
                I += 1 ; #DEBUG_LINE_NO:985
              EndWhile ; #DEBUG_LINE_NO:
              If BEObjective_AllCrew.GetCount() == 0 ; #DEBUG_LINE_NO:987
                
                 ; #DEBUG_LINE_NO:
              EndIf ; #DEBUG_LINE_NO:
            EndIf ; #DEBUG_LINE_NO:
            If BEObjective_AllCrew.GetCount() > 0 ; #DEBUG_LINE_NO:991
              (BEObjective_EnemyShipPilotSeat as beobjectiveblockpilotseatscript).BlockTakeover(Self) ; #DEBUG_LINE_NO:992
              BE_Objective.SetStage(CONST_BEObjective_KillEnemyCrewObj) ; #DEBUG_LINE_NO:993
            Else ; #DEBUG_LINE_NO:
              If ShipGravity < 1.0 ; #DEBUG_LINE_NO:996
                (BEObjective_EnemyShipPilotSeat as beobjectiveblockpilotseatscript).BlockTakeover(Self) ; #DEBUG_LINE_NO:997
              EndIf ; #DEBUG_LINE_NO:
              BE_Objective.SetStage(CONST_BEObjective_TakeOverEnemyShipObj) ; #DEBUG_LINE_NO:999
            EndIf ; #DEBUG_LINE_NO:
          EndIf ; #DEBUG_LINE_NO:
        EndIf ; #DEBUG_LINE_NO:
      EndIf ; #DEBUG_LINE_NO:
    ElseIf akOldLoc == enemyShipInteriorLoc ; #DEBUG_LINE_NO:1005
      If ShouldUseBEObjective ; #DEBUG_LINE_NO:1007
        BE_Objective.SetStage(CONST_BEObjective_LeaveShip) ; #DEBUG_LINE_NO:1008
      EndIf ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
EndEvent

Function RegisterBEAliasActor(Actor BEAliasActor, Bool startsDead, Bool shouldIncludeInCrew, Bool shouldIncludeAtFrontOfBoardingParty, Bool shouldIncludeAtBackOfBoardingParty)
  Self.WaitUntilInitialized() ; #DEBUG_LINE_NO:1018
  Guard BECrewGuard ;*** WARNING: Experimental syntax, may be incorrect: Guard  ; #DEBUG_LINE_NO:1019
    If startsDead ; #DEBUG_LINE_NO:1020
      BEAliasCorpses.add(BEAliasActor, 1) ; #DEBUG_LINE_NO:1022
      If BEAliasActor.Is3DLoaded() ; #DEBUG_LINE_NO:1023
        RE_Parent.KillWithForceNoWait(BEAliasActor, None, True) ; #DEBUG_LINE_NO:1024
      EndIf ; #DEBUG_LINE_NO:
    Else ; #DEBUG_LINE_NO:
      Self.RegisterForRemoteEvent(BEAliasActor as ScriptObject, "OnDying") ; #DEBUG_LINE_NO:1028
    EndIf ; #DEBUG_LINE_NO:
    If AllCrew.Find(BEAliasActor as ObjectReference) < 0 ; #DEBUG_LINE_NO:1030
      If shouldIncludeInCrew ; #DEBUG_LINE_NO:1033
        If !startsDead && !BEAliasActor.IsDead() ; #DEBUG_LINE_NO:1035
          AllCrew.AddRef(BEAliasActor as ObjectReference) ; #DEBUG_LINE_NO:1036
          If ShouldUseBEObjective && (BEObjective_EnemyShip.GetRef() == enemyShipRef as ObjectReference) ; #DEBUG_LINE_NO:1037
            BEObjective_AllCrew.AddRef(BEAliasActor as ObjectReference) ; #DEBUG_LINE_NO:1038
          EndIf ; #DEBUG_LINE_NO:
          BEAliasActor.AddKeyword(BECrewDefenderKeyword) ; #DEBUG_LINE_NO:1040
        EndIf ; #DEBUG_LINE_NO:
        BEAliasActor.SetValue(Suspicious, crewSuspiciousState as Float) ; #DEBUG_LINE_NO:1043
        If BEAliasActor.HasKeyword(ActorTypeRobot) ; #DEBUG_LINE_NO:1045
          If robots.Length > 0 ; #DEBUG_LINE_NO:1046
            robots[robots.Length - 1].SetLinkedRef(BEAliasActor as ObjectReference, LinkTerminalRobot, True) ; #DEBUG_LINE_NO:1047
          EndIf ; #DEBUG_LINE_NO:
          robots.add(BEAliasActor, 1) ; #DEBUG_LINE_NO:1049
        EndIf ; #DEBUG_LINE_NO:
        If AllCrew.GetCount() > genericCrewSize ; #DEBUG_LINE_NO:1053
          Actor crewToReplace = None ; #DEBUG_LINE_NO:1054
          If !ShouldBoardPlayersShip ; #DEBUG_LINE_NO:1055
            If GenericCrew.GetCount() > 0 ; #DEBUG_LINE_NO:1056
              crewToReplace = GenericCrew.GetAt(GenericCrew.GetCount() - 1) as Actor ; #DEBUG_LINE_NO:1057
            EndIf ; #DEBUG_LINE_NO:
          ElseIf ShouldBoardPlayersShip && potentialBoarders.Length > 0 ; #DEBUG_LINE_NO:1059
            crewToReplace = potentialBoarders[potentialBoarders.Length - 1] ; #DEBUG_LINE_NO:1060
            potentialBoarders.remove(potentialBoarders.Length - 1, 1) ; #DEBUG_LINE_NO:1061
          ElseIf ShouldBoardPlayersShip && remainingBoarders.Length > 0 ; #DEBUG_LINE_NO:1062
            crewToReplace = remainingBoarders[remainingBoarders.Length - 1] ; #DEBUG_LINE_NO:1063
            remainingBoarders.remove(remainingBoarders.Length - 1, 1) ; #DEBUG_LINE_NO:1064
          EndIf ; #DEBUG_LINE_NO:
          If crewToReplace != None ; #DEBUG_LINE_NO:1067
            GenericCrew.RemoveRef(crewToReplace as ObjectReference) ; #DEBUG_LINE_NO:1068
            AllCrew.RemoveRef(crewToReplace as ObjectReference) ; #DEBUG_LINE_NO:1069
            If ShouldUseBEObjective && (BEObjective_EnemyShip.GetRef() == enemyShipRef as ObjectReference) ; #DEBUG_LINE_NO:1070
              BEObjective_AllCrew.RemoveRef(crewToReplace as ObjectReference) ; #DEBUG_LINE_NO:1071
            EndIf ; #DEBUG_LINE_NO:
            crewToReplace.DisableNoWait(False) ; #DEBUG_LINE_NO:1073
          EndIf ; #DEBUG_LINE_NO:
        EndIf ; #DEBUG_LINE_NO:
      EndIf ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    If ShouldBoardPlayersShip && remainingBoarders != None ; #DEBUG_LINE_NO:1079
      If shouldIncludeAtFrontOfBoardingParty ; #DEBUG_LINE_NO:1080
        remainingBoarders.insert(BEAliasActor, 0) ; #DEBUG_LINE_NO:1081
      ElseIf shouldIncludeAtBackOfBoardingParty ; #DEBUG_LINE_NO:
        remainingBoarders.add(BEAliasActor, 1) ; #DEBUG_LINE_NO:1083
      EndIf ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
  EndGuard ;*** WARNING: Experimental syntax, may be incorrect: EndGuard  ; #DEBUG_LINE_NO:
EndFunction

Event OnTimer(Int timerID)
  If timerID == CONST_BoardingUpdateTimerID ; #DEBUG_LINE_NO:1090
    Self.UpdateBoarding() ; #DEBUG_LINE_NO:1091
  ElseIf timerID == CONST_TakeoffUpdateTimerID ; #DEBUG_LINE_NO:1092
    Self.UpdateTakeoff() ; #DEBUG_LINE_NO:1093
  EndIf ; #DEBUG_LINE_NO:
EndEvent

Event Actor.OnDying(Actor akSender, ObjectReference akKiller)
  Self.TryToDecrementSpaceshipCrew(akSender, False) ; #DEBUG_LINE_NO:1100
  If GenericBoarders != None ; #DEBUG_LINE_NO:1102
    If GenericBoarders.Find(akSender as ObjectReference) >= 0 ; #DEBUG_LINE_NO:1103
      GenericBoarders.RemoveRef(akSender as ObjectReference) ; #DEBUG_LINE_NO:1104
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  If ShowTraces ; #DEBUG_LINE_NO:
     ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
EndEvent

Function RemoveHackedActors(Actor[] actorsToRemove)
  Int I = 0 ; #DEBUG_LINE_NO:1114
  While I < actorsToRemove.Length ; #DEBUG_LINE_NO:1115
    Actor currentActor = actorsToRemove[I] ; #DEBUG_LINE_NO:1116
    Self.TryToDecrementSpaceshipCrew(currentActor, True) ; #DEBUG_LINE_NO:1117
    If ShowTraces ; #DEBUG_LINE_NO:
       ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    I += 1 ; #DEBUG_LINE_NO:1122
  EndWhile ; #DEBUG_LINE_NO:
EndFunction

Function TryToDecrementSpaceshipCrew(Actor actorToProcess, Bool omitIfDead)
  Guard SpaceshipCrewDecrementGuard ;*** WARNING: Experimental syntax, may be incorrect: Guard  ; #DEBUG_LINE_NO:1127
    If AllCrew.Find(actorToProcess as ObjectReference) >= 0 && (!omitIfDead || !actorToProcess.IsDead()) ; #DEBUG_LINE_NO:1128
      enemyShipRef.ModValue(SpaceshipCrew, -1.0) ; #DEBUG_LINE_NO:1129
      If enemyShipRef.GetValue(SpaceshipCrew) <= 0.0 ; #DEBUG_LINE_NO:1130
        If StageToSetWhenAllCrewDead >= 0 ; #DEBUG_LINE_NO:1131
          Self.SetStage(StageToSetWhenAllCrewDead) ; #DEBUG_LINE_NO:1132
        EndIf ; #DEBUG_LINE_NO:
        Self.SendCustomEvent("bescript_BEAllCrewDead", None) ; #DEBUG_LINE_NO:1134
      EndIf ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
  EndGuard ;*** WARNING: Experimental syntax, may be incorrect: EndGuard  ; #DEBUG_LINE_NO:
EndFunction

Event SQ_ParentScript.SQ_NativeTerminalActor_Unconscious(sq_parentscript source, Var[] akArgs)
  Actor targetActor = akArgs[1] as Actor ; #DEBUG_LINE_NO:1144
  If robots.find(targetActor, 0) >= 0 ; #DEBUG_LINE_NO:1145
    Self.RemoveHackedActors(robots) ; #DEBUG_LINE_NO:1146
  ElseIf turrets.find(targetActor, 0) >= 0 ; #DEBUG_LINE_NO:1147
    Self.RemoveHackedActors(turrets) ; #DEBUG_LINE_NO:1148
  EndIf ; #DEBUG_LINE_NO:
EndEvent

Event SQ_ParentScript.SQ_NativeTerminalActor_Ally(sq_parentscript source, Var[] akArgs)
  Actor targetActor = akArgs[1] as Actor ; #DEBUG_LINE_NO:1153
  If robots.find(targetActor, 0) >= 0 ; #DEBUG_LINE_NO:1154
    Self.RemoveHackedActors(robots) ; #DEBUG_LINE_NO:1155
  ElseIf turrets.find(targetActor, 0) >= 0 ; #DEBUG_LINE_NO:1156
    Self.RemoveHackedActors(turrets) ; #DEBUG_LINE_NO:1157
  EndIf ; #DEBUG_LINE_NO:
EndEvent

Event SQ_ParentScript.SQ_NativeTerminalActor_Frenzy(sq_parentscript source, Var[] akArgs)
  Actor targetActor = akArgs[1] as Actor ; #DEBUG_LINE_NO:1162
  If robots.find(targetActor, 0) >= 0 ; #DEBUG_LINE_NO:1163
    Self.RemoveHackedActors(robots) ; #DEBUG_LINE_NO:1164
  ElseIf turrets.find(targetActor, 0) >= 0 ; #DEBUG_LINE_NO:1165
    Self.RemoveHackedActors(turrets) ; #DEBUG_LINE_NO:1166
  EndIf ; #DEBUG_LINE_NO:
EndEvent

Event OnActorValueChanged(ObjectReference source, ActorValue akActorValue)
  If (source == enemyShipRef as ObjectReference) && akActorValue == SpaceshipCriticalHitCrew && Self.CheckForCrewCriticalHit() ; #DEBUG_LINE_NO:1171
    Self.UnregisterForActorValueChangedEvent(enemyShipRef as ObjectReference, SpaceshipCriticalHitCrew) ; #DEBUG_LINE_NO:1172
    Self.DecompressShipAndKillCrew() ; #DEBUG_LINE_NO:1173
  EndIf ; #DEBUG_LINE_NO:
EndEvent

Event SpaceshipReference.OnShipDock(spaceshipreference source, Bool abComplete, spaceshipreference akDocking, spaceshipreference akParent)
  If abComplete && ShouldBoardPlayersShip ; #DEBUG_LINE_NO:1178
    Self.UnregisterForRemoteEvent(enemyShipRef as ScriptObject, "OnShipDock") ; #DEBUG_LINE_NO:1179
    Self.UpdateBoarding() ; #DEBUG_LINE_NO:1180
  EndIf ; #DEBUG_LINE_NO:
EndEvent

Event SpaceshipReference.OnShipLanding(spaceshipreference source, Bool abComplete)
  If abComplete ; #DEBUG_LINE_NO:1185
    If ShouldSetupDisembarkingOnLanding ; #DEBUG_LINE_NO:1186
      Self.SetupDisembarking() ; #DEBUG_LINE_NO:1187
    ElseIf ShouldAutoOpenLandingRamp ; #DEBUG_LINE_NO:
      Self.SetEnemyShipLandingRampsOpenState(True) ; #DEBUG_LINE_NO:1189
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
EndEvent

Event SpaceshipReference.OnShipRampDown(spaceshipreference source)
  Self.SetupDisembarking() ; #DEBUG_LINE_NO:1195
EndEvent

Event SpaceshipReference.OnShipUndock(spaceshipreference source, Bool abComplete, spaceshipreference akUndocking, spaceshipreference akParent)
  shouldAbortBoarding = True ; #DEBUG_LINE_NO:1200
  If abComplete && ShutDownOnUndock ; #DEBUG_LINE_NO:1202
    If ShowTraces ; #DEBUG_LINE_NO:
       ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    Self.CleanupAndStop() ; #DEBUG_LINE_NO:1206
  EndIf ; #DEBUG_LINE_NO:
EndEvent

Event ObjectReference.OnUnload(ObjectReference source)
  If ShutDownOnUnload ; #DEBUG_LINE_NO:1212
    If ShowTraces ; #DEBUG_LINE_NO:
       ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    Self.CleanupAndStop() ; #DEBUG_LINE_NO:1215
  EndIf ; #DEBUG_LINE_NO:
EndEvent

Event SQ_PlayerShipScript.SQ_PlayerShipChanged(sq_playershipscript source, Var[] akArgs)
  If akArgs[0] as spaceshipreference == enemyShipRef ; #DEBUG_LINE_NO:1220
    Self.SetShipGravity(1.0) ; #DEBUG_LINE_NO:1222
    Self.SetShipHasOxygen(True) ; #DEBUG_LINE_NO:1223
    enemyShipCell.SetFactionOwner(None) ; #DEBUG_LINE_NO:1224
    enemyShipCell.SetOffLimits(False) ; #DEBUG_LINE_NO:1225
    enemyShipRef.RemoveKeyword(BEHostileBoardingEncounterKeyword) ; #DEBUG_LINE_NO:1226
    If ShutDownOnTakeover ; #DEBUG_LINE_NO:1230
      If ShowTraces ; #DEBUG_LINE_NO:
         ; #DEBUG_LINE_NO:
      EndIf ; #DEBUG_LINE_NO:
      Self.CleanupAndStop() ; #DEBUG_LINE_NO:1233
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
EndEvent

Event SQ_ParentScript.SQ_BEForceStop(sq_parentscript akSource, Var[] akArgs)
  If ShowTraces ; #DEBUG_LINE_NO:
     ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  Self.CleanupAndStop() ; #DEBUG_LINE_NO:1242
EndEvent

Function CleanupAndStop()
  playerShipInteriorLoc = None ; #DEBUG_LINE_NO:1247
  enemyShipInteriorLoc = None ; #DEBUG_LINE_NO:1248
  enemyShipRef = None ; #DEBUG_LINE_NO:1249
  enemyShipCockpit = None ; #DEBUG_LINE_NO:1250
  enemyShipCell = None ; #DEBUG_LINE_NO:1251
  enemyShipHazard = None ; #DEBUG_LINE_NO:1252
  moduleData = None ; #DEBUG_LINE_NO:1253
  robots = None ; #DEBUG_LINE_NO:1254
  turrets = None ; #DEBUG_LINE_NO:1255
  BEAliasCorpses = None ; #DEBUG_LINE_NO:1256
  HeatLeeches = None ; #DEBUG_LINE_NO:1257
  playerShipRef = None ; #DEBUG_LINE_NO:1258
  playerShipDockingDoorRef = None ; #DEBUG_LINE_NO:1259
  playerShipCockpitRef = None ; #DEBUG_LINE_NO:1260
  playerShipModulesAllRefs = None ; #DEBUG_LINE_NO:1261
  remainingBoarders = None ; #DEBUG_LINE_NO:1262
  potentialBoarders = None ; #DEBUG_LINE_NO:1263
  Self.Stop() ; #DEBUG_LINE_NO:1266
EndFunction

Int Function SetupGenericCrew(bescript:genericcrewdatum[] actorData, Float countPercent, Int countOverride, Int spawnPattern, Int spawnPrioritization, Bool isSpawningCorpses)
  Int actorsToSpawn = 0 ; #DEBUG_LINE_NO:1277
  If countOverride >= 0 ; #DEBUG_LINE_NO:1278
    actorsToSpawn = countOverride ; #DEBUG_LINE_NO:1279
  ElseIf !isSpawningCorpses ; #DEBUG_LINE_NO:1280
    actorsToSpawn = Math.Max(0.0, enemyShipRef.GetValue(SpaceshipCrew) * countPercent * crewSizePercent) as Int ; #DEBUG_LINE_NO:1281
    If actorsToSpawn == 0 ; #DEBUG_LINE_NO:1283
      If enemyShipRef.GetValue(SpaceshipCrew) == 0.0 ; #DEBUG_LINE_NO:1284
        If ShowTraces ; #DEBUG_LINE_NO:
           ; #DEBUG_LINE_NO:
        EndIf ; #DEBUG_LINE_NO:
      ElseIf countPercent == 0.0 ; #DEBUG_LINE_NO:1288
        If ShowTraces ; #DEBUG_LINE_NO:
           ; #DEBUG_LINE_NO:
        EndIf ; #DEBUG_LINE_NO:
      ElseIf crewSizePercent == 0.0 ; #DEBUG_LINE_NO:1292
        If ShowTraces ; #DEBUG_LINE_NO:
           ; #DEBUG_LINE_NO:
        EndIf ; #DEBUG_LINE_NO:
      Else ; #DEBUG_LINE_NO:
        actorsToSpawn = 1 ; #DEBUG_LINE_NO:1298
        If ShowTraces ; #DEBUG_LINE_NO:
           ; #DEBUG_LINE_NO:
        EndIf ; #DEBUG_LINE_NO:
      EndIf ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
  Else ; #DEBUG_LINE_NO:
    actorsToSpawn = Math.Max(0.0, (enemyShipRef.GetBaseValue(SpaceshipCrew) - enemyShipRef.GetValue(SpaceshipCrew)) * countPercent) as Int ; #DEBUG_LINE_NO:1305
  EndIf ; #DEBUG_LINE_NO:
  ObjectReference[] spawnPoints = Self.SelectSpawnPoints(actorsToSpawn, spawnPattern, spawnPrioritization) ; #DEBUG_LINE_NO:1309
  If spawnPoints.Length < actorsToSpawn ; #DEBUG_LINE_NO:1311
    If ShowTraces ; #DEBUG_LINE_NO:
       ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    actorsToSpawn = spawnPoints.Length ; #DEBUG_LINE_NO:1316
    If ShouldSpawnCaptain && !hasSpawnedCaptain && Captain.GetRef() == None ; #DEBUG_LINE_NO:1318
      actorsToSpawn += 1 ; #DEBUG_LINE_NO:1319
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  Int genericCrewSpawned = Self.SpawnGenericActors(actorData, actorsToSpawn, spawnPoints, isSpawningCorpses, False) ; #DEBUG_LINE_NO:1324
  Return genericCrewSpawned ; #DEBUG_LINE_NO:1325
EndFunction

Int Function SetupTurrets()
  Int turretsSpawned = 0 ; #DEBUG_LINE_NO:1330
  Int modulesWithTurretsTarget = (moduleData.Length as Float * TurretModulePercentChance) as Int ; #DEBUG_LINE_NO:1331
  If modulesWithTurretsTarget > 0 ; #DEBUG_LINE_NO:1332
    Int modulesWithTurrets = 0 ; #DEBUG_LINE_NO:1333
    bescript:moduledatum[] randomizedModuleData = Self.CopyAndRandomizeModuleDataArray(moduleData) ; #DEBUG_LINE_NO:1334
    Int I = 0 ; #DEBUG_LINE_NO:1335
    While modulesWithTurrets < modulesWithTurretsTarget && I < randomizedModuleData.Length ; #DEBUG_LINE_NO:1336
      bescript:moduledatum currentModule = randomizedModuleData[I] ; #DEBUG_LINE_NO:1337
      If currentModule.shipTurretSpawnMarkerRef01 != None ; #DEBUG_LINE_NO:1338
        modulesWithTurrets += 1 ; #DEBUG_LINE_NO:1339
        Int turretsToSpawnInCurrentModule = 0 ; #DEBUG_LINE_NO:1341
        If currentModule.moduleRef.HasLocRefType(Ship_Module_Large_RefType) ; #DEBUG_LINE_NO:1342
          turretsToSpawnInCurrentModule = Utility.RandomInt(TurretsToSpawnMin_Large, TurretsToSpawnMax_Large) ; #DEBUG_LINE_NO:1343
        Else ; #DEBUG_LINE_NO:
          turretsToSpawnInCurrentModule = Utility.RandomInt(TurretsToSpawnMin_Small, TurretsToSpawnMax_Small) ; #DEBUG_LINE_NO:1345
        EndIf ; #DEBUG_LINE_NO:
        ObjectReference[] turretSpawnMarkers = new ObjectReference[0] ; #DEBUG_LINE_NO:1347
        If turretsToSpawnInCurrentModule >= 1 ; #DEBUG_LINE_NO:1348
          turretSpawnMarkers.add(currentModule.shipTurretSpawnMarkerRef01, 1) ; #DEBUG_LINE_NO:1349
        EndIf ; #DEBUG_LINE_NO:
        If turretsToSpawnInCurrentModule >= 2 && currentModule.shipTurretSpawnMarkerRef02 != None ; #DEBUG_LINE_NO:1351
          turretSpawnMarkers.add(currentModule.shipTurretSpawnMarkerRef02, 1) ; #DEBUG_LINE_NO:1352
        EndIf ; #DEBUG_LINE_NO:
        If turretsToSpawnInCurrentModule >= 3 && currentModule.shipTurretSpawnMarkerRef03 != None ; #DEBUG_LINE_NO:1354
          turretSpawnMarkers.add(currentModule.shipTurretSpawnMarkerRef03, 1) ; #DEBUG_LINE_NO:1355
        EndIf ; #DEBUG_LINE_NO:
        If turretsToSpawnInCurrentModule >= 4 && currentModule.shipTurretSpawnMarkerRef04 != None ; #DEBUG_LINE_NO:1357
          turretSpawnMarkers.add(currentModule.shipTurretSpawnMarkerRef04, 1) ; #DEBUG_LINE_NO:1358
        EndIf ; #DEBUG_LINE_NO:
        If turretsToSpawnInCurrentModule >= 5 && currentModule.shipTurretSpawnMarkerRef05 != None ; #DEBUG_LINE_NO:1360
          turretSpawnMarkers.add(currentModule.shipTurretSpawnMarkerRef05, 1) ; #DEBUG_LINE_NO:1361
        EndIf ; #DEBUG_LINE_NO:
        Int j = 0 ; #DEBUG_LINE_NO:1364
        While j < turretSpawnMarkers.Length ; #DEBUG_LINE_NO:1365
          Actor newTurret = Self.SpawnGenericActor(turretSpawnMarkers[j], TurretData, False, False) ; #DEBUG_LINE_NO:1366
          If ShouldTurretsStartUnconscious ; #DEBUG_LINE_NO:1367
            newTurret.SetUnconscious(True) ; #DEBUG_LINE_NO:1368
          EndIf ; #DEBUG_LINE_NO:
          If ShouldTurretsStartFriendlyToPlayer ; #DEBUG_LINE_NO:1370
            newTurret.AddToFaction(REPlayerFriend) ; #DEBUG_LINE_NO:1371
          EndIf ; #DEBUG_LINE_NO:
          turretsSpawned += 1 ; #DEBUG_LINE_NO:1373
          j += 1 ; #DEBUG_LINE_NO:1374
        EndWhile ; #DEBUG_LINE_NO:
      EndIf ; #DEBUG_LINE_NO:
      I += 1 ; #DEBUG_LINE_NO:1377
    EndWhile ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  Return turretsSpawned ; #DEBUG_LINE_NO:1380
EndFunction

Int Function SetupHeatLeeches()
  Int leechesToSpawn = Utility.RandomInt(MinHeatLeaches, MaxHeatLeaches) ; #DEBUG_LINE_NO:1386
  If ShowTraces ; #DEBUG_LINE_NO:
     ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  ObjectReference[] spawnPoints = Self.SelectSpawnPoints(leechesToSpawn, CONST_SpawnPattern_Fill, CONST_SpawnPrioritization_None) ; #DEBUG_LINE_NO:1392
  If spawnPoints.Length < leechesToSpawn ; #DEBUG_LINE_NO:1393
    If ShowTraces ; #DEBUG_LINE_NO:
       ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    leechesToSpawn = spawnPoints.Length ; #DEBUG_LINE_NO:1397
  EndIf ; #DEBUG_LINE_NO:
  HeatLeeches = new Actor[leechesToSpawn] ; #DEBUG_LINE_NO:1401
  Int I = 0 ; #DEBUG_LINE_NO:1402
  While I < leechesToSpawn ; #DEBUG_LINE_NO:1403
    HeatLeeches[I] = spawnPoints[I].PlaceActorAtMe(ParasiteA_HeatLeech, 4, None, False, False, True, None, True) ; #DEBUG_LINE_NO:1404
    HeatLeeches[I].SetLinkedRef(spawnPoints[I].GetLinkedRef(LinkShipModule), LinkShipModule, True) ; #DEBUG_LINE_NO:1405
    I += 1 ; #DEBUG_LINE_NO:1406
  EndWhile ; #DEBUG_LINE_NO:
  Return leechesToSpawn ; #DEBUG_LINE_NO:1408
EndFunction

ObjectReference[] Function SelectSpawnPoints(Int actorsToSpawn, Int spawnPattern, Int spawnPrioritization)
  ObjectReference[] selectedSpawnPoints = new ObjectReference[0] ; #DEBUG_LINE_NO:1414
  bescript:moduledatum[] randomizedModuleData = Self.CopyAndRandomizeModuleDataArray(moduleData) ; #DEBUG_LINE_NO:1415
  bescript:moduledatum[] prioritizedModuleData = None ; #DEBUG_LINE_NO:1416
  If randomizedModuleData.Length == 0 ; #DEBUG_LINE_NO:1419
    Return selectedSpawnPoints ; #DEBUG_LINE_NO:1421
  EndIf ; #DEBUG_LINE_NO:
  If ShowTraces ; #DEBUG_LINE_NO:
     ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  If spawnPattern != CONST_SpawnPattern_Random ; #DEBUG_LINE_NO:1428
    If spawnPrioritization == CONST_SpawnPrioritization_None ; #DEBUG_LINE_NO:1430
      prioritizedModuleData = randomizedModuleData ; #DEBUG_LINE_NO:1431
    ElseIf spawnPrioritization == CONST_SpawnPrioritization_CockpitLargeSmall ; #DEBUG_LINE_NO:1432
      prioritizedModuleData = new bescript:moduledatum[randomizedModuleData.Length] ; #DEBUG_LINE_NO:1433
      Int pIndex = 0 ; #DEBUG_LINE_NO:1434
      Int cockpitIndex = randomizedModuleData.findstruct("moduleRef", enemyShipCockpit, 0) ; #DEBUG_LINE_NO:1437
      If cockpitIndex >= 0 ; #DEBUG_LINE_NO:1438
        prioritizedModuleData[pIndex] = randomizedModuleData[cockpitIndex] ; #DEBUG_LINE_NO:1439
        pIndex += 1 ; #DEBUG_LINE_NO:1440
        randomizedModuleData.remove(cockpitIndex, 1) ; #DEBUG_LINE_NO:1441
      EndIf ; #DEBUG_LINE_NO:
      Int i = randomizedModuleData.Length - 1 ; #DEBUG_LINE_NO:1444
      While i >= 0 ; #DEBUG_LINE_NO:1445
        If i < randomizedModuleData.Length && randomizedModuleData[i].moduleRef.HasLocRefType(Ship_Module_Large_RefType) ; #DEBUG_LINE_NO:1446
          prioritizedModuleData[pIndex] = randomizedModuleData[i] ; #DEBUG_LINE_NO:1447
          pIndex += 1 ; #DEBUG_LINE_NO:1448
          randomizedModuleData.remove(i, 1) ; #DEBUG_LINE_NO:1449
        EndIf ; #DEBUG_LINE_NO:
        i -= 1 ; #DEBUG_LINE_NO:1451
      EndWhile ; #DEBUG_LINE_NO:
      i = 0 ; #DEBUG_LINE_NO:1454
      While i < randomizedModuleData.Length ; #DEBUG_LINE_NO:1455
        prioritizedModuleData[pIndex] = randomizedModuleData[i] ; #DEBUG_LINE_NO:1456
        pIndex += 1 ; #DEBUG_LINE_NO:1457
        i += 1 ; #DEBUG_LINE_NO:1458
      EndWhile ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    Int I = 0 ; #DEBUG_LINE_NO:1462
    While selectedSpawnPoints.Length < actorsToSpawn && I < prioritizedModuleData.Length ; #DEBUG_LINE_NO:1463
      bescript:moduledatum currentModule = prioritizedModuleData[I] ; #DEBUG_LINE_NO:1464
      ObjectReference[] moduleSpawnPoints = Self.GetUnusedSpawnPointsInModule(currentModule) ; #DEBUG_LINE_NO:1465
      Int moduleSpawnPointsToAdd = 0 ; #DEBUG_LINE_NO:1467
      If spawnPattern == CONST_SpawnPattern_Fill ; #DEBUG_LINE_NO:1468
        moduleSpawnPointsToAdd = moduleSpawnPoints.Length ; #DEBUG_LINE_NO:1469
      ElseIf spawnPattern == CONST_SpawnPattern_Half ; #DEBUG_LINE_NO:1470
        moduleSpawnPointsToAdd = Math.Round(moduleSpawnPoints.Length as Float / 2.0) ; #DEBUG_LINE_NO:1471
      Else ; #DEBUG_LINE_NO:
        moduleSpawnPointsToAdd = Math.Min(moduleSpawnPoints.Length as Float, 1.0) as Int ; #DEBUG_LINE_NO:1473
      EndIf ; #DEBUG_LINE_NO:
      Int j = 0 ; #DEBUG_LINE_NO:1476
      While j < moduleSpawnPoints.Length && j < moduleSpawnPointsToAdd && selectedSpawnPoints.Length < actorsToSpawn ; #DEBUG_LINE_NO:1477
        selectedSpawnPoints.add(moduleSpawnPoints[j], 1) ; #DEBUG_LINE_NO:1478
        moduleSpawnPoints[j].AddKeyword(BEMarkerInUseKeyword) ; #DEBUG_LINE_NO:1479
        j += 1 ; #DEBUG_LINE_NO:1480
      EndWhile ; #DEBUG_LINE_NO:
      I += 1 ; #DEBUG_LINE_NO:1482
    EndWhile ; #DEBUG_LINE_NO:
    If ShowTraces ; #DEBUG_LINE_NO:
       ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  If selectedSpawnPoints.Length < actorsToSpawn ; #DEBUG_LINE_NO:1491
    ObjectReference[] randomizedSpawnPoints = commonarrayfunctions.CopyAndRandomizeObjArray(allCrewSpawnPoints) ; #DEBUG_LINE_NO:1492
    Int i = 0 ; #DEBUG_LINE_NO:1493
    While selectedSpawnPoints.Length < actorsToSpawn && i < randomizedSpawnPoints.Length ; #DEBUG_LINE_NO:1494
      ObjectReference nextSpawnPoint = randomizedSpawnPoints[i] ; #DEBUG_LINE_NO:1495
      If !nextSpawnPoint.HasKeyword(BEMarkerInUseKeyword) ; #DEBUG_LINE_NO:1496
        selectedSpawnPoints.add(nextSpawnPoint, 1) ; #DEBUG_LINE_NO:1497
        nextSpawnPoint.AddKeyword(BEMarkerInUseKeyword) ; #DEBUG_LINE_NO:1498
      EndIf ; #DEBUG_LINE_NO:
      i += 1 ; #DEBUG_LINE_NO:1500
    EndWhile ; #DEBUG_LINE_NO:
    If ShowTraces ; #DEBUG_LINE_NO:
       ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  If ShowTraces ; #DEBUG_LINE_NO:
     ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  Return selectedSpawnPoints ; #DEBUG_LINE_NO:1512
EndFunction

ObjectReference[] Function GetUnusedSpawnPointsInModule(bescript:moduledatum moduleDataRef)
  ObjectReference[] unusedSpawnPoints = new ObjectReference[0] ; #DEBUG_LINE_NO:1517
  If moduleDataRef.shipCrewSpawnMarkerRef01 != None && !moduleDataRef.shipCrewSpawnMarkerRef01.HasKeyword(BEMarkerInUseKeyword) ; #DEBUG_LINE_NO:1518
    unusedSpawnPoints.add(moduleDataRef.shipCrewSpawnMarkerRef01, 1) ; #DEBUG_LINE_NO:1519
  EndIf ; #DEBUG_LINE_NO:
  If moduleDataRef.shipCrewSpawnMarkerRef02 != None && !moduleDataRef.shipCrewSpawnMarkerRef02.HasKeyword(BEMarkerInUseKeyword) ; #DEBUG_LINE_NO:1521
    unusedSpawnPoints.add(moduleDataRef.shipCrewSpawnMarkerRef02, 1) ; #DEBUG_LINE_NO:1522
  EndIf ; #DEBUG_LINE_NO:
  If moduleDataRef.shipCrewSpawnMarkerRef03 != None && !moduleDataRef.shipCrewSpawnMarkerRef03.HasKeyword(BEMarkerInUseKeyword) ; #DEBUG_LINE_NO:1524
    unusedSpawnPoints.add(moduleDataRef.shipCrewSpawnMarkerRef03, 1) ; #DEBUG_LINE_NO:1525
  EndIf ; #DEBUG_LINE_NO:
  If moduleDataRef.shipCrewSpawnMarkerRef04 != None && !moduleDataRef.shipCrewSpawnMarkerRef04.HasKeyword(BEMarkerInUseKeyword) ; #DEBUG_LINE_NO:1527
    unusedSpawnPoints.add(moduleDataRef.shipCrewSpawnMarkerRef04, 1) ; #DEBUG_LINE_NO:1528
  EndIf ; #DEBUG_LINE_NO:
  If moduleDataRef.shipCrewSpawnMarkerRef05 != None && !moduleDataRef.shipCrewSpawnMarkerRef05.HasKeyword(BEMarkerInUseKeyword) ; #DEBUG_LINE_NO:1530
    unusedSpawnPoints.add(moduleDataRef.shipCrewSpawnMarkerRef05, 1) ; #DEBUG_LINE_NO:1531
  EndIf ; #DEBUG_LINE_NO:
  Return unusedSpawnPoints ; #DEBUG_LINE_NO:1533
EndFunction

Int Function SpawnGenericActors(bescript:genericcrewdatum[] actorData, Int actorsToSpawn, ObjectReference[] spawnPoints, Bool isSpawningCorpses, Bool isSpawningDisembarkers)
  Int spawnedCount = 0 ; #DEBUG_LINE_NO:1538
  Int currentActorDataIndex = 0 ; #DEBUG_LINE_NO:1539
  While spawnedCount < actorsToSpawn && actorData.Length > 0 ; #DEBUG_LINE_NO:1540
    If ShouldSpawnCaptain && !hasSpawnedCaptain && !isSpawningDisembarkers ; #DEBUG_LINE_NO:1541
      If Captain.GetRef() != None ; #DEBUG_LINE_NO:1542
        hasSpawnedCaptain = True ; #DEBUG_LINE_NO:1544
      Else ; #DEBUG_LINE_NO:
        hasSpawnedCaptain = True ; #DEBUG_LINE_NO:1547
        ObjectReference captainSpawnMarkerRef = CaptainSpawnMarker.GetRef() ; #DEBUG_LINE_NO:1548
        Actor newCaptain = Self.SpawnGenericActor(captainSpawnMarkerRef, CaptainData, isSpawningCorpses, False) ; #DEBUG_LINE_NO:1549
        Captain.ForceRefTo(newCaptain as ObjectReference) ; #DEBUG_LINE_NO:1550
        spawnedCount += 1 ; #DEBUG_LINE_NO:1551
        spawnPoints.insert(captainSpawnMarkerRef, 0) ; #DEBUG_LINE_NO:1554
      EndIf ; #DEBUG_LINE_NO:
    ElseIf currentActorDataIndex >= actorData.Length ; #DEBUG_LINE_NO:1556
      currentActorDataIndex = 0 ; #DEBUG_LINE_NO:1557
    ElseIf actorData[currentActorDataIndex].InstancesToSpawn == 0 ; #DEBUG_LINE_NO:1558
      actorData.remove(currentActorDataIndex, 1) ; #DEBUG_LINE_NO:1559
    ElseIf actorData[currentActorDataIndex].CrewActor == None ; #DEBUG_LINE_NO:1560
      actorData.remove(currentActorDataIndex, 1) ; #DEBUG_LINE_NO:1562
    Else ; #DEBUG_LINE_NO:
      If !isSpawningDisembarkers ; #DEBUG_LINE_NO:1564
        Self.SpawnGenericActor(spawnPoints[spawnedCount], actorData[currentActorDataIndex], isSpawningCorpses, isSpawningDisembarkers) ; #DEBUG_LINE_NO:1565
      Else ; #DEBUG_LINE_NO:
        Self.SpawnGenericActor(enemyShipRef as ObjectReference, actorData[currentActorDataIndex], isSpawningCorpses, isSpawningDisembarkers) ; #DEBUG_LINE_NO:1567
      EndIf ; #DEBUG_LINE_NO:
      spawnedCount += 1 ; #DEBUG_LINE_NO:1569
      currentActorDataIndex += 1 ; #DEBUG_LINE_NO:1570
    EndIf ; #DEBUG_LINE_NO:
  EndWhile ; #DEBUG_LINE_NO:
  If ShowTraces ; #DEBUG_LINE_NO:
    If isSpawningDisembarkers ; #DEBUG_LINE_NO:
       ; #DEBUG_LINE_NO:
    ElseIf !isSpawningCorpses ; #DEBUG_LINE_NO:1576
       ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  Return spawnedCount ; #DEBUG_LINE_NO:1582
EndFunction

Actor Function SpawnGenericActor(ObjectReference spawnPoint, bescript:genericcrewdatum spawnData, Bool isSpawningCorpses, Bool isSpawningDisembarkers)
  ActorBase actorBaseToSpawn = spawnData.CrewActor ; #DEBUG_LINE_NO:1587
  Int actorLevelMod = 0 ; #DEBUG_LINE_NO:1588
  Float actorLevelModChance = Utility.RandomFloat(0.0, 1.0) ; #DEBUG_LINE_NO:1589
  If actorLevelModChance < spawnData.ActorLevelModChanceEasy ; #DEBUG_LINE_NO:1590
    actorLevelMod = 0 ; #DEBUG_LINE_NO:1591
  ElseIf actorLevelModChance < spawnData.ActorLevelModChanceMedium ; #DEBUG_LINE_NO:1592
    actorLevelMod = 1 ; #DEBUG_LINE_NO:1593
  Else ; #DEBUG_LINE_NO:
    actorLevelMod = 2 ; #DEBUG_LINE_NO:1595
  EndIf ; #DEBUG_LINE_NO:
  If ShowTraces ; #DEBUG_LINE_NO:
     ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  Actor newActor = spawnPoint.PlaceActorAtMe(actorBaseToSpawn, actorLevelMod, enemyShipInteriorLoc, False, False, True, None, True) ; #DEBUG_LINE_NO:1602
  If ShowTraces ; #DEBUG_LINE_NO:
     ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  If isSpawningDisembarkers ; #DEBUG_LINE_NO:1608
    DisembarkingCrew.AddRef(newActor as ObjectReference) ; #DEBUG_LINE_NO:1609
  ElseIf !isSpawningCorpses ; #DEBUG_LINE_NO:1610
    Self.RegisterForRemoteEvent(newActor as ScriptObject, "OnDying") ; #DEBUG_LINE_NO:1611
    AllCrew.AddRef(newActor as ObjectReference) ; #DEBUG_LINE_NO:1612
    If ShouldUseBEObjective && BEObjective_EnemyShip != None && (BEObjective_EnemyShip.GetRef() == enemyShipRef as ObjectReference) ; #DEBUG_LINE_NO:1613
      BEObjective_AllCrew.AddRef(newActor as ObjectReference) ; #DEBUG_LINE_NO:1614
    EndIf ; #DEBUG_LINE_NO:
    GenericCrew.AddRef(newActor as ObjectReference) ; #DEBUG_LINE_NO:1616
    newActor.AddKeyword(BECrewDefenderKeyword) ; #DEBUG_LINE_NO:1617
    newActor.SetValue(Suspicious, crewSuspiciousState as Float) ; #DEBUG_LINE_NO:1618
    If ShouldCrewStartInCombat && OwnerFaction == None && !isSurfaceEncounter ; #DEBUG_LINE_NO:1619
      newActor.SetValue(Aggression, CONST_Aggression_VeryAggressive as Float) ; #DEBUG_LINE_NO:1621
    EndIf ; #DEBUG_LINE_NO:
    If enemyShipCrimeFaction != None ; #DEBUG_LINE_NO:1623
      newActor.SetCrimeFaction(enemyShipCrimeFaction) ; #DEBUG_LINE_NO:1624
    EndIf ; #DEBUG_LINE_NO:
    ObjectReference spawnLink = spawnPoint.GetLinkedRef(None) ; #DEBUG_LINE_NO:1627
    If spawnLink != None ; #DEBUG_LINE_NO:1628
      newActor.SetLinkedRef(spawnLink, None, True) ; #DEBUG_LINE_NO:1629
    EndIf ; #DEBUG_LINE_NO:
    ObjectReference moduleTrigger = spawnPoint.GetLinkedRef(LinkShipModule) ; #DEBUG_LINE_NO:1632
    ObjectReference[] combatTargetRef = CombatTargets.GetArray() ; #DEBUG_LINE_NO:1633
    newActor.SetLinkedRef(moduleTrigger, LinkShipModule, True) ; #DEBUG_LINE_NO:1634
    Int I = 0 ; #DEBUG_LINE_NO:1635
    Bool combatTargetFound = False ; #DEBUG_LINE_NO:1636
    While I < combatTargetRef.Length && combatTargetFound == False ; #DEBUG_LINE_NO:1638
      If moduleTrigger == combatTargetRef[I].GetLinkedRef(LinkShipModule) ; #DEBUG_LINE_NO:1639
        newActor.SetLinkedRef(combatTargetRef[I], LinkCombatTravelTarget, True) ; #DEBUG_LINE_NO:1640
        combatTargetFound = True ; #DEBUG_LINE_NO:1641
      EndIf ; #DEBUG_LINE_NO:
      I += 1 ; #DEBUG_LINE_NO:1643
    EndWhile ; #DEBUG_LINE_NO:
    If newActor.HasKeyword(LinkTerminalTurret) ; #DEBUG_LINE_NO:1647
      If turrets.Length > 0 ; #DEBUG_LINE_NO:1648
        turrets[turrets.Length - 1].SetLinkedRef(newActor as ObjectReference, LinkTerminalTurret, True) ; #DEBUG_LINE_NO:1649
      EndIf ; #DEBUG_LINE_NO:
      turrets.add(newActor, 1) ; #DEBUG_LINE_NO:1651
      GenericTurrets.AddRef(newActor as ObjectReference) ; #DEBUG_LINE_NO:1652
    ElseIf newActor.HasKeyword(ActorTypeRobot) ; #DEBUG_LINE_NO:1653
      If robots.Length > 0 ; #DEBUG_LINE_NO:1654
        robots[robots.Length - 1].SetLinkedRef(newActor as ObjectReference, LinkTerminalRobot, True) ; #DEBUG_LINE_NO:1655
      EndIf ; #DEBUG_LINE_NO:
      robots.add(newActor, 1) ; #DEBUG_LINE_NO:1657
      GenericRobots.AddRef(newActor as ObjectReference) ; #DEBUG_LINE_NO:1658
    EndIf ; #DEBUG_LINE_NO:
  Else ; #DEBUG_LINE_NO:
    GenericCorpses.AddRef(newActor as ObjectReference) ; #DEBUG_LINE_NO:1661
  EndIf ; #DEBUG_LINE_NO:
  Return newActor ; #DEBUG_LINE_NO:1666
EndFunction

Function SetupComputers()
  ObjectReference[] computersToEnable = new ObjectReference[0] ; #DEBUG_LINE_NO:1671
  ObjectReference cockpitComputer = None ; #DEBUG_LINE_NO:1672
  If ForceEnableCockpitComputer ; #DEBUG_LINE_NO:1675
    cockpitComputer = moduleData[moduleData.findstruct("moduleRef", enemyShipCockpit, 0)].shipComputerRef ; #DEBUG_LINE_NO:1676
    computersToEnable.add(cockpitComputer, 1) ; #DEBUG_LINE_NO:1677
  EndIf ; #DEBUG_LINE_NO:
  Bool shouldEnableGenericComputers = False ; #DEBUG_LINE_NO:1681
  If ForceEnableGenericComputers ; #DEBUG_LINE_NO:1682
    shouldEnableGenericComputers = True ; #DEBUG_LINE_NO:1683
  ElseIf robots.Length > 0 || turrets.Length > 0 ; #DEBUG_LINE_NO:1684
    If GenericComputersEnableChance > 0.0 && Utility.RandomFloat(0.0, 1.0) < GenericComputersEnableChance ; #DEBUG_LINE_NO:1685
      shouldEnableGenericComputers = True ; #DEBUG_LINE_NO:1686
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  If shouldEnableGenericComputers ; #DEBUG_LINE_NO:1689
    If ShouldEnableGenericComputerCockpit && !ForceEnableCockpitComputer ; #DEBUG_LINE_NO:1693
      cockpitComputer = moduleData[moduleData.findstruct("moduleRef", enemyShipCockpit, 0)].shipComputerRef ; #DEBUG_LINE_NO:1694
      computersToEnable.add(cockpitComputer, 1) ; #DEBUG_LINE_NO:1695
    EndIf ; #DEBUG_LINE_NO:
    Int genericComputersToEnableCount = 0 ; #DEBUG_LINE_NO:1699
    If GenericComputersMax >= 0 ; #DEBUG_LINE_NO:1700
      genericComputersToEnableCount = Math.Min(moduleData.Length as Float * GenericComputersModulePercentChance, GenericComputersMax as Float) as Int ; #DEBUG_LINE_NO:1701
    Else ; #DEBUG_LINE_NO:
      genericComputersToEnableCount = moduleData.Length * GenericComputersModulePercentChance as Int ; #DEBUG_LINE_NO:1703
    EndIf ; #DEBUG_LINE_NO:
    If genericComputersToEnableCount > computersToEnable.Length ; #DEBUG_LINE_NO:1705
      bescript:moduledatum[] randomizedModuleData = Self.CopyAndRandomizeModuleDataArray(moduleData) ; #DEBUG_LINE_NO:1706
      If ShouldPreferGenericComputerThematicModules ; #DEBUG_LINE_NO:1708
        ObjectReference[] nonPreferredComputers = new ObjectReference[0] ; #DEBUG_LINE_NO:1709
        Int i = 0 ; #DEBUG_LINE_NO:1710
        While i < moduleData.Length && computersToEnable.Length < genericComputersToEnableCount ; #DEBUG_LINE_NO:1711
          bescript:moduledatum currentModule = moduleData[i] ; #DEBUG_LINE_NO:1712
          ObjectReference currentModuleRef = currentModule.moduleRef ; #DEBUG_LINE_NO:1713
          If currentModule.shipComputerRef != None ; #DEBUG_LINE_NO:1714
            If currentModuleRef.HasLocRefType(Ship_Module_Computer_RefType) || currentModuleRef.HasLocRefType(Ship_Module_Engineering_RefType) ; #DEBUG_LINE_NO:1715
              computersToEnable.add(currentModule.shipComputerRef, 1) ; #DEBUG_LINE_NO:1716
            ElseIf currentModuleRef != enemyShipCockpit ; #DEBUG_LINE_NO:1717
              nonPreferredComputers.add(currentModule.shipComputerRef, 1) ; #DEBUG_LINE_NO:1718
            EndIf ; #DEBUG_LINE_NO:
          EndIf ; #DEBUG_LINE_NO:
          i += 1 ; #DEBUG_LINE_NO:1721
        EndWhile ; #DEBUG_LINE_NO:
        If computersToEnable.Length < genericComputersToEnableCount ; #DEBUG_LINE_NO:1723
          i = 0 ; #DEBUG_LINE_NO:1724
          While i < nonPreferredComputers.Length ; #DEBUG_LINE_NO:1725
            computersToEnable.add(nonPreferredComputers[i], 1) ; #DEBUG_LINE_NO:1726
            i += 1 ; #DEBUG_LINE_NO:1727
          EndWhile ; #DEBUG_LINE_NO:
        EndIf ; #DEBUG_LINE_NO:
      Else ; #DEBUG_LINE_NO:
        Int i = 0 ; #DEBUG_LINE_NO:1731
        While i < moduleData.Length && computersToEnable.Length < genericComputersToEnableCount ; #DEBUG_LINE_NO:1732
          bescript:moduledatum currentmodule = moduleData[i] ; #DEBUG_LINE_NO:1733
          If currentmodule.shipComputerRef != None && currentmodule.moduleRef != enemyShipCockpit ; #DEBUG_LINE_NO:1734
            computersToEnable.add(currentmodule.shipComputerRef, 1) ; #DEBUG_LINE_NO:1735
          EndIf ; #DEBUG_LINE_NO:
          i += 1 ; #DEBUG_LINE_NO:1737
        EndWhile ; #DEBUG_LINE_NO:
      EndIf ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  Bool enabledAnyComputers = False ; #DEBUG_LINE_NO:1744
  If cockpitComputer != None ; #DEBUG_LINE_NO:1745
    enabledAnyComputers = True ; #DEBUG_LINE_NO:1746
    Computers.AddRef(cockpitComputer) ; #DEBUG_LINE_NO:1747
    cockpitComputer.EnableNoWait(False) ; #DEBUG_LINE_NO:1748
    If GenericComputerRobotLinkStatus < CONST_GenericComputerLinkStatus_None && robots.Length > 0 ; #DEBUG_LINE_NO:1749
      cockpitComputer.SetLinkedRef(robots[0] as ObjectReference, LinkTerminalRobot, True) ; #DEBUG_LINE_NO:1750
    EndIf ; #DEBUG_LINE_NO:
    If GenericComputerTurretLinkStatus < CONST_GenericComputerLinkStatus_None && turrets.Length > 0 ; #DEBUG_LINE_NO:1752
      cockpitComputer.SetLinkedRef(turrets[0] as ObjectReference, LinkTerminalTurret, True) ; #DEBUG_LINE_NO:1753
    EndIf ; #DEBUG_LINE_NO:
    ObjectReference linkedContainer = cockpitComputer.GetLinkedRef(LinkTerminalContainer) ; #DEBUG_LINE_NO:1755
    If linkedContainer != None && Utility.RandomFloat(0.0, 1.0) < GenericComputerLinkedContainerLockPercentChance ; #DEBUG_LINE_NO:1756
      linkedContainer.Lock(True, False, True) ; #DEBUG_LINE_NO:1757
      linkedContainer.SetLockLevel(Utility.RandomInt(LockLevelMin, LockLevelMax) * 25) ; #DEBUG_LINE_NO:1758
    EndIf ; #DEBUG_LINE_NO:
    If GenericComputerLockPercentChance_Cockpit > 0.0 && Utility.RandomFloat(0.0, 1.0) < GenericComputerLockPercentChance_Cockpit ; #DEBUG_LINE_NO:1760
      cockpitComputer.Lock(True, False, True) ; #DEBUG_LINE_NO:1761
      cockpitComputer.SetLockLevel(Utility.RandomInt(GenericComputerLockLevelMin, GenericComputerLockLevelMax) * 25) ; #DEBUG_LINE_NO:1762
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  Int I = 0 ; #DEBUG_LINE_NO:1766
  While I < computersToEnable.Length ; #DEBUG_LINE_NO:1767
    enabledAnyComputers = True ; #DEBUG_LINE_NO:1768
    ObjectReference currentComputer = computersToEnable[I] ; #DEBUG_LINE_NO:1769
    If currentComputer != cockpitComputer ; #DEBUG_LINE_NO:1770
      currentComputer.EnableNoWait(False) ; #DEBUG_LINE_NO:1771
      Computers.AddRef(currentComputer) ; #DEBUG_LINE_NO:1772
      If GenericComputerRobotLinkStatus == CONST_GenericComputerLinkStatus_All && robots.Length > 0 ; #DEBUG_LINE_NO:1773
        currentComputer.SetLinkedRef(robots[0] as ObjectReference, LinkTerminalRobot, True) ; #DEBUG_LINE_NO:1774
      EndIf ; #DEBUG_LINE_NO:
      If GenericComputerTurretLinkStatus == CONST_GenericComputerLinkStatus_All && turrets.Length > 0 ; #DEBUG_LINE_NO:1776
        currentComputer.SetLinkedRef(turrets[0] as ObjectReference, LinkTerminalTurret, True) ; #DEBUG_LINE_NO:1777
      EndIf ; #DEBUG_LINE_NO:
      ObjectReference linkedcontainer = cockpitComputer.GetLinkedRef(LinkTerminalContainer) ; #DEBUG_LINE_NO:1779
      If linkedcontainer != None && Utility.RandomFloat(0.0, 1.0) < GenericComputerLinkedContainerLockPercentChance ; #DEBUG_LINE_NO:1780
        linkedcontainer.Lock(True, False, True) ; #DEBUG_LINE_NO:1781
        linkedcontainer.SetLockLevel(Utility.RandomInt(LockLevelMin, LockLevelMax) * 25) ; #DEBUG_LINE_NO:1782
      EndIf ; #DEBUG_LINE_NO:
      If GenericComputerLockPercentChance_General > 0.0 && Utility.RandomFloat(0.0, 1.0) < GenericComputerLockPercentChance_General ; #DEBUG_LINE_NO:1784
        currentComputer.Lock(True, False, True) ; #DEBUG_LINE_NO:1785
        currentComputer.SetLockLevel(Utility.RandomInt(GenericComputerLockLevelMin, GenericComputerLockLevelMax) * 25) ; #DEBUG_LINE_NO:1786
      EndIf ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    I += 1 ; #DEBUG_LINE_NO:1789
  EndWhile ; #DEBUG_LINE_NO:
  If enabledAnyComputers ; #DEBUG_LINE_NO:1793
    Self.RegisterForCustomEvent(SQ_Parent as ScriptObject, "sq_parentscript_SQ_NativeTerminalActor_Unconscious") ; #DEBUG_LINE_NO:1794
    Self.RegisterForCustomEvent(SQ_Parent as ScriptObject, "sq_parentscript_SQ_NativeTerminalActor_Frenzy") ; #DEBUG_LINE_NO:1795
    Self.RegisterForCustomEvent(SQ_Parent as ScriptObject, "sq_parentscript_SQ_NativeTerminalActor_Ally") ; #DEBUG_LINE_NO:1796
  EndIf ; #DEBUG_LINE_NO:
EndFunction

Event ObjectReference.OnCellLoad(ObjectReference akSource)
  Self.UnregisterForRemoteEvent(akSource as ScriptObject, "OnCellLoad") ; #DEBUG_LINE_NO:1805
  Guard BECrewGuard ;*** WARNING: Experimental syntax, may be incorrect: Guard  ; #DEBUG_LINE_NO:1808
    Actor[] genericCorpseRefs = GenericCorpses.GetArray() as Actor[] ; #DEBUG_LINE_NO:1809
    Int I = 0 ; #DEBUG_LINE_NO:1810
    While I < genericCorpseRefs.Length ; #DEBUG_LINE_NO:1811
      RE_Parent.KillWithForceNoWait(genericCorpseRefs[I], None, True) ; #DEBUG_LINE_NO:1812
      I += 1 ; #DEBUG_LINE_NO:1813
    EndWhile ; #DEBUG_LINE_NO:
    I = 0 ; #DEBUG_LINE_NO:1815
    While I < BEAliasCorpses.Length ; #DEBUG_LINE_NO:1816
      RE_Parent.KillWithForceNoWait(BEAliasCorpses[I], None, True) ; #DEBUG_LINE_NO:1817
      I += 1 ; #DEBUG_LINE_NO:1818
    EndWhile ; #DEBUG_LINE_NO:
  EndGuard ;*** WARNING: Experimental syntax, may be incorrect: EndGuard  ; #DEBUG_LINE_NO:
  If ShouldSpawnLoot ; #DEBUG_LINE_NO:1823
    ObjectReference captainsLockerRef = CaptainsLocker.GetRef() ; #DEBUG_LINE_NO:1824
    Int maxCrew = (enemyShipRef.GetBaseValue(SpaceshipCrew) * crewSizePercent) as Int ; #DEBUG_LINE_NO:1825
    If maxCrew == 0 ; #DEBUG_LINE_NO:1826
       ; #DEBUG_LINE_NO:
    ElseIf maxCrew <= BE_ShipCrewSizeSmall.GetValueInt() ; #DEBUG_LINE_NO:1828
      captainsLockerRef.AddItem(LL_BE_ShipCaptainsLockerLoot_Small as Form, 1, False) ; #DEBUG_LINE_NO:1829
    ElseIf maxCrew <= BE_ShipCrewSizeMedium.GetValueInt() ; #DEBUG_LINE_NO:1830
      captainsLockerRef.AddItem(LL_BE_ShipCaptainsLockerLoot_Medium as Form, 1, False) ; #DEBUG_LINE_NO:1831
    Else ; #DEBUG_LINE_NO:
      captainsLockerRef.AddItem(LL_BE_ShipCaptainsLockerLoot_Large as Form, 1, False) ; #DEBUG_LINE_NO:1833
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  If StageToSetOnBoarding >= 0 ; #DEBUG_LINE_NO:1838
    Self.SetStage(StageToSetOnBoarding) ; #DEBUG_LINE_NO:1839
  EndIf ; #DEBUG_LINE_NO:
  If PlayHostileAlarmUponBoarding ; #DEBUG_LINE_NO:1843
    OBJ_Alarm_BoardingAlert.Play(player as ObjectReference, None, None) ; #DEBUG_LINE_NO:1844
  EndIf ; #DEBUG_LINE_NO:
  If ShouldCrewStartInCombat && !isSurfaceEncounter && OwnerFaction != None && AllCrew != None && AllCrew.GetCount() > 0 ; #DEBUG_LINE_NO:1848
    Actor[] allCrewRefs = AllCrew.GetArray() as Actor[] ; #DEBUG_LINE_NO:1849
    Int i = 0 ; #DEBUG_LINE_NO:1850
    While i < allCrewRefs.Length ; #DEBUG_LINE_NO:1851
      Actor current = allCrewRefs[i] ; #DEBUG_LINE_NO:1852
      If current != None ; #DEBUG_LINE_NO:1853
        current.SendAssaultAlarm() ; #DEBUG_LINE_NO:1854
      EndIf ; #DEBUG_LINE_NO:
      i += 1 ; #DEBUG_LINE_NO:1856
    EndWhile ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
EndEvent

Function UpdateBoarding()
  If ShowTraces ; #DEBUG_LINE_NO:
     ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  Int I = 0 ; #DEBUG_LINE_NO:1872
  While I < GenericBoarders.GetCount() ; #DEBUG_LINE_NO:1873
    Actor currentBoarder = GenericBoarders.GetAt(I) as Actor ; #DEBUG_LINE_NO:1874
    If currentBoarder != None ; #DEBUG_LINE_NO:1875
      Location currentBoarderLocation = currentBoarder.GetCurrentLocation() ; #DEBUG_LINE_NO:1878
      Bool isAttacking = currentBoarder.HasKeyword(BECrewAttackerKeyword) ; #DEBUG_LINE_NO:1879
      If !isAttacking && currentBoarderLocation == playerShipInteriorLoc ; #DEBUG_LINE_NO:1880
        currentBoarder.RemoveKeyword(BECrewDefenderKeyword) ; #DEBUG_LINE_NO:1881
        currentBoarder.AddKeyword(BECrewAttackerKeyword) ; #DEBUG_LINE_NO:1882
      ElseIf isAttacking && currentBoarderLocation != playerShipInteriorLoc ; #DEBUG_LINE_NO:1883
        currentBoarder.RemoveKeyword(BECrewAttackerKeyword) ; #DEBUG_LINE_NO:1884
        currentBoarder.AddKeyword(BECrewDefenderKeyword) ; #DEBUG_LINE_NO:1885
      EndIf ; #DEBUG_LINE_NO:
      If playerShipCockpitRef.GetValue(BEBoarderCapturedModule) == 0.0 && playerShipCockpitRef.IsInTrigger(currentBoarder as ObjectReference) ; #DEBUG_LINE_NO:1890
        playerShipCockpitRef.SetValue(BEBoarderCapturedModule, 1.0) ; #DEBUG_LINE_NO:1891
      EndIf ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    I += 1 ; #DEBUG_LINE_NO:1895
  EndWhile ; #DEBUG_LINE_NO:
  If player.IsInLocation(enemyShipInteriorLoc) ; #DEBUG_LINE_NO:1898
    If ShowTraces ; #DEBUG_LINE_NO:
       ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
  Else ; #DEBUG_LINE_NO:
    Bool startedWave = False ; #DEBUG_LINE_NO:1905
    Int slotsForMoreBoarders = maxSimultaneousBoarders - GenericBoarders.GetCount() ; #DEBUG_LINE_NO:1906
    If remainingBoarders.Length > 0 && slotsForMoreBoarders >= MinBoardingWaveSize ; #DEBUG_LINE_NO:1907
      Guard BECrewGuard ;*** WARNING: Experimental syntax, may be incorrect: Guard  ; #DEBUG_LINE_NO:1908
        Int boardersToAdd = Math.Min(remainingBoarders.Length as Float, Math.Min(slotsForMoreBoarders as Float, MaxBoardingWaveSize as Float)) as Int ; #DEBUG_LINE_NO:1911
        If boardersToAdd > 0 ; #DEBUG_LINE_NO:1912
          If ShowTraces ; #DEBUG_LINE_NO:
             ; #DEBUG_LINE_NO:
          EndIf ; #DEBUG_LINE_NO:
          startedWave = True ; #DEBUG_LINE_NO:1916
          I = 0 ; #DEBUG_LINE_NO:1917
          While I < boardersToAdd ; #DEBUG_LINE_NO:1918
            Actor nextBoarder = remainingBoarders[0] ; #DEBUG_LINE_NO:1919
            ObjectReference randomModule = playerShipModulesAllRefs[Utility.RandomInt(0, playerShipModulesAllRefs.Length - 1)] ; #DEBUG_LINE_NO:1920
            nextBoarder.SetLinkedRef(playerShipCockpitRef, BEBoarderPlayerShipCockpitLink, True) ; #DEBUG_LINE_NO:1921
            nextBoarder.SetLinkedRef(randomModule, BEBoarderPlayerShipModuleLink, True) ; #DEBUG_LINE_NO:1922
            nextBoarder.SetValue(Confidence, CONST_Confidence_Foolhardy as Float) ; #DEBUG_LINE_NO:1924
            If ShouldCrewStartInCombat ; #DEBUG_LINE_NO:1925
              nextBoarder.SetValue(Aggression, CONST_Aggression_VeryAggressive as Float) ; #DEBUG_LINE_NO:1927
            EndIf ; #DEBUG_LINE_NO:
            GenericBoarders.AddRef(nextBoarder as ObjectReference) ; #DEBUG_LINE_NO:1929
            If !player.IsInLocation(enemyShipInteriorLoc) ; #DEBUG_LINE_NO:1930
              nextBoarder.Disable(False) ; #DEBUG_LINE_NO:1931
              nextBoarder.RemoveKeyword(BECrewDefenderKeyword) ; #DEBUG_LINE_NO:1932
              nextBoarder.AddKeyword(BECrewAttackerKeyword) ; #DEBUG_LINE_NO:1933
              nextBoarder.MoveTo(playerShipDockingDoorRef, 0.0, 0.0, 0.0, True, False) ; #DEBUG_LINE_NO:1934
              nextBoarder.Enable(True) ; #DEBUG_LINE_NO:1935
            EndIf ; #DEBUG_LINE_NO:
            nextBoarder.EvaluatePackage(False) ; #DEBUG_LINE_NO:1937
            If ShowTraces ; #DEBUG_LINE_NO:
               ; #DEBUG_LINE_NO:
            EndIf ; #DEBUG_LINE_NO:
            remainingBoarders.remove(0, 1) ; #DEBUG_LINE_NO:1941
            I += 1 ; #DEBUG_LINE_NO:1942
          EndWhile ; #DEBUG_LINE_NO:
        EndIf ; #DEBUG_LINE_NO:
      EndGuard ;*** WARNING: Experimental syntax, may be incorrect: EndGuard  ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  If GenericBoarders.GetCount() > 0 ; #DEBUG_LINE_NO:1950
    Self.StartTimer(CONST_BoardingUpdateTimerDelay, CONST_BoardingUpdateTimerID) ; #DEBUG_LINE_NO:1951
  ElseIf ShowTraces ; #DEBUG_LINE_NO:
     ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
EndFunction

Function SetupDisembarking()
  Guard DisembarkingGuard ;*** WARNING: Experimental syntax, may be incorrect: Guard  ; #DEBUG_LINE_NO:1965
    If !hasSetupDisembarking && enemyShipRef.IsLanded() ; #DEBUG_LINE_NO:1966
      hasSetupDisembarking = True ; #DEBUG_LINE_NO:1967
      If DisembarkingCrew.GetCount() > 0 ; #DEBUG_LINE_NO:1968
        If ShowTraces ; #DEBUG_LINE_NO:
           ; #DEBUG_LINE_NO:
        EndIf ; #DEBUG_LINE_NO:
        Actor[] disembarkingCrewRefs = DisembarkingCrew.GetArray() as Actor[] ; #DEBUG_LINE_NO:1972
        If ShouldAddDisembarkersToAllCrew ; #DEBUG_LINE_NO:1974
          AllCrew.AddArray(disembarkingCrewRefs as ObjectReference[]) ; #DEBUG_LINE_NO:1975
          If ShouldUseBEObjective && (BEObjective_EnemyShip.GetRef() == enemyShipRef as ObjectReference) ; #DEBUG_LINE_NO:1976
            BEObjective_AllCrew.AddArray(disembarkingCrewRefs as ObjectReference[]) ; #DEBUG_LINE_NO:1977
          EndIf ; #DEBUG_LINE_NO:
          enemyShipRef.ModValue(SpaceshipCrew, disembarkingCrewRefs.Length as Float) ; #DEBUG_LINE_NO:1979
          Int i = 0 ; #DEBUG_LINE_NO:1980
          While i < disembarkingCrewRefs.Length ; #DEBUG_LINE_NO:1981
            Self.RegisterForRemoteEvent(disembarkingCrewRefs[i] as ScriptObject, "OnDying") ; #DEBUG_LINE_NO:1982
            i += 1 ; #DEBUG_LINE_NO:1983
          EndWhile ; #DEBUG_LINE_NO:
        EndIf ; #DEBUG_LINE_NO:
        ObjectReference LandingDeckControlMarkerRef = LandingDeckControlMarker.GetRef() ; #DEBUG_LINE_NO:1987
        ObjectReference[] landingDeckMarkerRefs = LandingDeckControlMarkerRef.GetLinkedRefChain(None, 100) ; #DEBUG_LINE_NO:1988
        Int I = 0 ; #DEBUG_LINE_NO:1989
        While I < disembarkingCrewRefs.Length && I < landingDeckMarkerRefs.Length ; #DEBUG_LINE_NO:1990
          If ShowTraces ; #DEBUG_LINE_NO:
             ; #DEBUG_LINE_NO:
          EndIf ; #DEBUG_LINE_NO:
          disembarkingCrewRefs[I].MoveTo(landingDeckMarkerRefs[I], 0.0, 0.0, 0.0, True, False) ; #DEBUG_LINE_NO:1994
          I += 1 ; #DEBUG_LINE_NO:1995
        EndWhile ; #DEBUG_LINE_NO:
        While I < disembarkingCrewRefs.Length ; #DEBUG_LINE_NO:1997
          If ShowTraces ; #DEBUG_LINE_NO:
             ; #DEBUG_LINE_NO:
          EndIf ; #DEBUG_LINE_NO:
          disembarkingCrewRefs[I].MoveTo(LandingDeckControlMarkerRef, 0.0, 0.0, 0.0, True, False) ; #DEBUG_LINE_NO:2001
          I += 1 ; #DEBUG_LINE_NO:2002
        EndWhile ; #DEBUG_LINE_NO:
        I = 0 ; #DEBUG_LINE_NO:2004
        While I < disembarkingCrewRefs.Length ; #DEBUG_LINE_NO:2005
          disembarkingCrewRefs[I].SetValue(BEWaitingForLandingRampValue, 1.0) ; #DEBUG_LINE_NO:2006
          If disembarkersShouldHaveWeaponsUnequipped ; #DEBUG_LINE_NO:2007
            disembarkingCrewRefs[I].SetValue(BEDisembarkWithWeaponsDrawnValue, 1.0) ; #DEBUG_LINE_NO:2008
          EndIf ; #DEBUG_LINE_NO:
          disembarkingCrewRefs[I].SetLinkedRef(landingDeckMarkerRefs[landingDeckMarkerRefs.Length - 1], LinkCombatTravelTarget, True) ; #DEBUG_LINE_NO:2010
          disembarkingCrewRefs[I].EnableNoWait(False) ; #DEBUG_LINE_NO:2011
          disembarkingCrewRefs[I].EvaluatePackage(False) ; #DEBUG_LINE_NO:2012
          I += 1 ; #DEBUG_LINE_NO:2013
        EndWhile ; #DEBUG_LINE_NO:
      EndIf ; #DEBUG_LINE_NO:
      Self.SetEnemyShipLandingRampsOpenState(True) ; #DEBUG_LINE_NO:2017
    EndIf ; #DEBUG_LINE_NO:
    If !hasStartedDisembarking && (!enemyShipRef.Is3DLoaded() || enemyShipRef.IsRampDown()) ; #DEBUG_LINE_NO:2019
      hasStartedDisembarking = True ; #DEBUG_LINE_NO:2020
      Actor[] disembarkingcrewrefs = DisembarkingCrew.GetArray() as Actor[] ; #DEBUG_LINE_NO:2021
      Int i = 0 ; #DEBUG_LINE_NO:2022
      While i < disembarkingcrewrefs.Length ; #DEBUG_LINE_NO:2023
        disembarkingcrewrefs[i].SetValue(BEWaitingForLandingRampValue, 0.0) ; #DEBUG_LINE_NO:2024
        disembarkingcrewrefs[i].EvaluatePackage(False) ; #DEBUG_LINE_NO:2025
        i += 1 ; #DEBUG_LINE_NO:2026
      EndWhile ; #DEBUG_LINE_NO:
      If isDropshipEncounter ; #DEBUG_LINE_NO:2028
        Self.TakeOffWhenAble(True) ; #DEBUG_LINE_NO:2030
      EndIf ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
  EndGuard ;*** WARNING: Experimental syntax, may be incorrect: EndGuard  ; #DEBUG_LINE_NO:
EndFunction

Event ObjectReference.OnLoad(ObjectReference akSource)
  Self.SetEnemyShipLandingRampsOpenState(ShouldLandingRampsBeOpenOnLoad) ; #DEBUG_LINE_NO:2037
EndEvent

Function EmbarkAllCrewAndTakeoffWhenAble(Bool shouldQuestShutDownOnTakeoff)
  Self.EmbarkAllCrew() ; #DEBUG_LINE_NO:2046
  Self.TakeOffWhenAble(True) ; #DEBUG_LINE_NO:2047
EndFunction

Function EmbarkAllCrew()
  Self.EmbarkActorsRefCol(AllCrew) ; #DEBUG_LINE_NO:2051
EndFunction

Function EmbarkActorsRefCol(RefCollectionAlias actorsToEmbark)
  Self.EmbarkActors(actorsToEmbark.GetArray() as Actor[]) ; #DEBUG_LINE_NO:2055
EndFunction

Function EmbarkActors(Actor[] actorsToEmbark)
  Int I = 0 ; #DEBUG_LINE_NO:2059
  While I < actorsToEmbark.Length ; #DEBUG_LINE_NO:2060
    Actor current = actorsToEmbark[I] ; #DEBUG_LINE_NO:2061
    If current != None ; #DEBUG_LINE_NO:2062
      Self.EmbarkActor(current) ; #DEBUG_LINE_NO:2063
    EndIf ; #DEBUG_LINE_NO:
    I += 1 ; #DEBUG_LINE_NO:2065
  EndWhile ; #DEBUG_LINE_NO:
EndFunction

Function EmbarkActor(Actor actorToEmbark)
  If actorToEmbark.GetLinkedRef(LinkShipModule) == None ; #DEBUG_LINE_NO:2071
    actorToEmbark.SetLinkedRef(enemyShipCockpit, LinkShipModule, True) ; #DEBUG_LINE_NO:2072
  EndIf ; #DEBUG_LINE_NO:
  DisembarkingCrew.RemoveRef(actorToEmbark as ObjectReference) ; #DEBUG_LINE_NO:2075
  EmbarkingCrew.AddRef(actorToEmbark as ObjectReference) ; #DEBUG_LINE_NO:2076
  actorToEmbark.EvaluatePackage(False) ; #DEBUG_LINE_NO:2077
EndFunction

Function TakeOffWhenAble(Bool shouldQuestShutDownOnTakeoff)
  shouldShutdownOnTakeoff = shouldQuestShutDownOnTakeoff ; #DEBUG_LINE_NO:2086
  Self.StartTimer(CONST_TakeoffUpdateTimerDelay, CONST_TakeoffUpdateTimerID) ; #DEBUG_LINE_NO:2087
EndFunction

Function UpdateTakeoff()
  Bool hasFinishedEmbarking = True ; #DEBUG_LINE_NO:2092
  If EmbarkingCrew == None ; #DEBUG_LINE_NO:2093
     ; #DEBUG_LINE_NO:
  ElseIf EmbarkingCrew.GetCount() > 0 ; #DEBUG_LINE_NO:2095
    Actor[] embarkingCrewActors = EmbarkingCrew.GetArray() as Actor[] ; #DEBUG_LINE_NO:2096
    Int I = 0 ; #DEBUG_LINE_NO:2097
    While I < embarkingCrewActors.Length && hasFinishedEmbarking ; #DEBUG_LINE_NO:2098
      Actor current = embarkingCrewActors[I] ; #DEBUG_LINE_NO:2099
      If current == None || current.IsDead() || current.IsDisabled() ; #DEBUG_LINE_NO:2100
        EmbarkingCrew.RemoveRef(current as ObjectReference) ; #DEBUG_LINE_NO:2102
      ElseIf current.IsInLocation(enemyShipInteriorLoc) ; #DEBUG_LINE_NO:2103
         ; #DEBUG_LINE_NO:
      ElseIf !current.Is3DLoaded() ; #DEBUG_LINE_NO:2105
        current.MoveToPackageLocation() ; #DEBUG_LINE_NO:2107
      Else ; #DEBUG_LINE_NO:
        hasFinishedEmbarking = False ; #DEBUG_LINE_NO:2110
      EndIf ; #DEBUG_LINE_NO:
      I += 1 ; #DEBUG_LINE_NO:2112
    EndWhile ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  If hasFinishedEmbarking ; #DEBUG_LINE_NO:2116
    If !enemyShipRef.IsExteriorLoadDoorInaccessible() ; #DEBUG_LINE_NO:2118
      If !player.IsInLocation(enemyShipInteriorLoc) ; #DEBUG_LINE_NO:2119
        enemyShipRef.SetExteriorLoadDoorInaccessible(True) ; #DEBUG_LINE_NO:2121
        If player.IsInLocation(enemyShipInteriorLoc) ; #DEBUG_LINE_NO:2123
          enemyShipRef.SetExteriorLoadDoorInaccessible(False) ; #DEBUG_LINE_NO:2124
        EndIf ; #DEBUG_LINE_NO:
      EndIf ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    If enemyShipRef.IsLandingDeckClear() ; #DEBUG_LINE_NO:2132
      isReadyForTakeoff = True ; #DEBUG_LINE_NO:2134
      If shouldShutdownOnTakeoff ; #DEBUG_LINE_NO:2137
        ShutDownOnUnload = True ; #DEBUG_LINE_NO:2138
        Self.RegisterForRemoteEvent(enemyShipRef as ScriptObject, "OnUnload") ; #DEBUG_LINE_NO:2139
      EndIf ; #DEBUG_LINE_NO:
      ObjectReference[] landingRamps = enemyShipRef.GetLandingRamps() ; #DEBUG_LINE_NO:2143
      Int i = 0 ; #DEBUG_LINE_NO:2144
      While i < landingRamps.Length ; #DEBUG_LINE_NO:2145
        Self.RegisterForRemoteEvent(landingRamps[i] as ScriptObject, "OnClose") ; #DEBUG_LINE_NO:2146
        landingRamps[i].SetOpen(False) ; #DEBUG_LINE_NO:2147
        i += 1 ; #DEBUG_LINE_NO:2148
      EndWhile ; #DEBUG_LINE_NO:
      Return  ; #DEBUG_LINE_NO:2152
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  Self.StartTimer(CONST_TakeoffUpdateTimerDelay, CONST_TakeoffUpdateTimerID) ; #DEBUG_LINE_NO:2158
EndFunction

Event ObjectReference.OnClose(ObjectReference akSource, ObjectReference akActionRef)
  If isReadyForTakeoff ; #DEBUG_LINE_NO:2163
    Self.FinishTakeoff() ; #DEBUG_LINE_NO:2164
  EndIf ; #DEBUG_LINE_NO:
EndEvent

Function FinishTakeoff()
  ObjectReference exteriorLandingDeckTrigger = enemyShipRef.GetExteriorLoadDoors()[0].GetLinkedRef(None) ; #DEBUG_LINE_NO:2169
  If exteriorLandingDeckTrigger != None ; #DEBUG_LINE_NO:2170
    Actor[] actorsOnLandingDeck = exteriorLandingDeckTrigger.GetAllRefsInTrigger() as Actor[] ; #DEBUG_LINE_NO:2171
    Int I = 0 ; #DEBUG_LINE_NO:2172
    While I < actorsOnLandingDeck.Length ; #DEBUG_LINE_NO:2173
      Actor current = actorsOnLandingDeck[I] ; #DEBUG_LINE_NO:2174
      If current != None && current != Game.GetPlayer() && !current.IsEssential() ; #DEBUG_LINE_NO:2175
        actorsOnLandingDeck[I].Kill(None) ; #DEBUG_LINE_NO:2176
      EndIf ; #DEBUG_LINE_NO:
      I += 1 ; #DEBUG_LINE_NO:2178
    EndWhile ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  enemyShipRef.DisableWithTakeoffOrLanding() ; #DEBUG_LINE_NO:2183
EndFunction

Function SetCrewPlayerFriend(Bool shouldBeFriends, Bool shouldStartOrStopCombat)
  Guard BECrewGuard ;*** WARNING: Experimental syntax, may be incorrect: Guard  ; #DEBUG_LINE_NO:2194
    Int I = 0 ; #DEBUG_LINE_NO:2195
    While I < AllCrew.GetCount() ; #DEBUG_LINE_NO:2196
      Self.SetPlayerFriend(AllCrew.GetAt(I), shouldBeFriends, shouldStartOrStopCombat) ; #DEBUG_LINE_NO:2197
      I += 1 ; #DEBUG_LINE_NO:2198
    EndWhile ; #DEBUG_LINE_NO:
  EndGuard ;*** WARNING: Experimental syntax, may be incorrect: EndGuard  ; #DEBUG_LINE_NO:
  Self.SetPlayerFriend(EnemyShip.GetRef(), shouldBeFriends, shouldStartOrStopCombat) ; #DEBUG_LINE_NO:2202
  If shouldBeFriends ; #DEBUG_LINE_NO:2204
    shouldAbortBoarding = True ; #DEBUG_LINE_NO:2205
  EndIf ; #DEBUG_LINE_NO:
EndFunction

Function SetPlayerFriend(ObjectReference target, Bool shouldBeFriends, Bool shouldStartOrStopCombat)
  If shouldBeFriends ; #DEBUG_LINE_NO:2211
    target.TryToAddToFaction(REPlayerFriend) ; #DEBUG_LINE_NO:2212
    If shouldStartOrStopCombat ; #DEBUG_LINE_NO:2213
      target.TryToStopCombat() ; #DEBUG_LINE_NO:2214
    EndIf ; #DEBUG_LINE_NO:
  Else ; #DEBUG_LINE_NO:
    target.TryToRemoveFromFaction(REPlayerFriend) ; #DEBUG_LINE_NO:2217
    If shouldStartOrStopCombat ; #DEBUG_LINE_NO:2218
      target.TryToStartCombat(player as ObjectReference, False) ; #DEBUG_LINE_NO:2219
      target.TryToStartCombat(PlayerShip.GetRef(), False) ; #DEBUG_LINE_NO:2220
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  target.TryToEvaluatePackage() ; #DEBUG_LINE_NO:2223
EndFunction

Function RemoveCrewKeywords(Actor target)
  target.RemoveKeyword(BECrewAttackerKeyword) ; #DEBUG_LINE_NO:2228
  target.RemoveKeyword(BECrewDefenderKeyword) ; #DEBUG_LINE_NO:2229
EndFunction

Bool Function CheckForCrewCriticalHit()
  Return ShouldSupportCrewCriticalHit && !isSurfaceEncounter && enemyShipRef.GetValue(SpaceshipCriticalHitCrew) == 1.0 ; #DEBUG_LINE_NO:2234
EndFunction

Function DecompressShipAndKillCrew()
  Bool isPlayerInEnemyShip = Game.GetPlayer().GetParentCell() == enemyShipCell ; #DEBUG_LINE_NO:2240
  Bool blockZeroG = GenericRobots != None && GenericRobots.GetCount() > 0 ; #DEBUG_LINE_NO:2243
  Actor[] allCrewRefs = AllCrew.GetArray() as Actor[] ; #DEBUG_LINE_NO:2245
  Int I = 0 ; #DEBUG_LINE_NO:2246
  While I < allCrewRefs.Length ; #DEBUG_LINE_NO:2247
    Actor current = allCrewRefs[I] ; #DEBUG_LINE_NO:2248
    If current != None ; #DEBUG_LINE_NO:2249
      If current.HasKeyword(ActorTypeRobot) ; #DEBUG_LINE_NO:2250
        blockZeroG = True ; #DEBUG_LINE_NO:2251
      ElseIf current.HasKeyword(ActorTypeTurret) ; #DEBUG_LINE_NO:2252
         ; #DEBUG_LINE_NO:
      Else ; #DEBUG_LINE_NO:
        current.Kill(None) ; #DEBUG_LINE_NO:2255
      EndIf ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
    I += 1 ; #DEBUG_LINE_NO:2258
  EndWhile ; #DEBUG_LINE_NO:
  If HeatLeeches != None ; #DEBUG_LINE_NO:2260
    If !isPlayerInEnemyShip ; #DEBUG_LINE_NO:2261
      I = 0 ; #DEBUG_LINE_NO:2262
      While I < HeatLeeches.Length ; #DEBUG_LINE_NO:2263
        HeatLeeches[I].DisableNoWait(False) ; #DEBUG_LINE_NO:2264
        I += 1 ; #DEBUG_LINE_NO:2265
      EndWhile ; #DEBUG_LINE_NO:
    Else ; #DEBUG_LINE_NO:
      blockZeroG = True ; #DEBUG_LINE_NO:2268
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  Self.SetShipHasOxygen(False) ; #DEBUG_LINE_NO:2273
  If blockZeroG ; #DEBUG_LINE_NO:
     ; #DEBUG_LINE_NO:
  Else ; #DEBUG_LINE_NO:
    Self.SetShipGravity(0.0) ; #DEBUG_LINE_NO:2278
  EndIf ; #DEBUG_LINE_NO:
EndFunction

Function SetShipGravity(Float newGravity)
  If newGravity < 0.0 ; #DEBUG_LINE_NO:2285
     ; #DEBUG_LINE_NO:
  ElseIf ShouldOverrideGravityOnlyInSpace && isSurfaceEncounter ; #DEBUG_LINE_NO:2287
     ; #DEBUG_LINE_NO:
  Else ; #DEBUG_LINE_NO:
    ShipGravity = newGravity ; #DEBUG_LINE_NO:2290
    enemyShipCell.SetGravityScale(ShipGravity) ; #DEBUG_LINE_NO:2291
  EndIf ; #DEBUG_LINE_NO:
EndFunction

Function SetShipHasOxygen(Bool hasOxygen)
  If hasOxygen ; #DEBUG_LINE_NO:2297
    enemyShipRef.RemoveKeyword(ENV_Loc_NotSealedEnvironment) ; #DEBUG_LINE_NO:2298
  Else ; #DEBUG_LINE_NO:
    enemyShipRef.AddKeyword(ENV_Loc_NotSealedEnvironment) ; #DEBUG_LINE_NO:2300
  EndIf ; #DEBUG_LINE_NO:
EndFunction

Function SetShipHazard(Hazard newHazard)
  If enemyShipHazard != None ; #DEBUG_LINE_NO:2306
    enemyShipHazard.Disable(False) ; #DEBUG_LINE_NO:2307
    enemyShipHazard.Delete() ; #DEBUG_LINE_NO:2308
  EndIf ; #DEBUG_LINE_NO:
  If newHazard == None ; #DEBUG_LINE_NO:2310
    enemyShipHazard = None ; #DEBUG_LINE_NO:2311
  Else ; #DEBUG_LINE_NO:
    enemyShipHazard = enemyShipCockpit.PlaceAtMe(newHazard as Form, 1, False, False, True, None, None, True) ; #DEBUG_LINE_NO:2313
    ObjectReference[] allModuleRefs = AllModules.GetArray() ; #DEBUG_LINE_NO:2314
    Int I = 0 ; #DEBUG_LINE_NO:2315
    While I < allModuleRefs.Length ; #DEBUG_LINE_NO:2316
      allModuleRefs[I].SetLinkedRef(enemyShipHazard, LinkHazardVolume, True) ; #DEBUG_LINE_NO:2317
      If allModuleRefs[I].IsInTrigger(player as ObjectReference) ; #DEBUG_LINE_NO:2318
        allModuleRefs[I].Disable(False) ; #DEBUG_LINE_NO:2319
        allModuleRefs[I].Enable(False) ; #DEBUG_LINE_NO:2320
      EndIf ; #DEBUG_LINE_NO:
      I += 1 ; #DEBUG_LINE_NO:2322
    EndWhile ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
EndFunction

Function SetModuleHazard(ObjectReference module, Hazard newHazard)
  ObjectReference currentHazardRef = module.GetLinkedRef(LinkHazardVolume) ; #DEBUG_LINE_NO:2328
  If currentHazardRef != None && currentHazardRef != enemyShipHazard ; #DEBUG_LINE_NO:2329
    currentHazardRef.Disable(False) ; #DEBUG_LINE_NO:2330
    currentHazardRef.Delete() ; #DEBUG_LINE_NO:2331
  EndIf ; #DEBUG_LINE_NO:
  If newHazard == None ; #DEBUG_LINE_NO:2333
    module.SetLinkedRef(None, LinkHazardVolume, True) ; #DEBUG_LINE_NO:2334
  Else ; #DEBUG_LINE_NO:
    ObjectReference newHazardRef = module.PlaceAtMe(newHazard as Form, 1, False, False, True, None, None, True) ; #DEBUG_LINE_NO:2336
    module.SetLinkedRef(newHazardRef, LinkHazardVolume, True) ; #DEBUG_LINE_NO:2337
    If module.IsInTrigger(player as ObjectReference) ; #DEBUG_LINE_NO:2338
      module.Disable(False) ; #DEBUG_LINE_NO:2339
      module.Enable(False) ; #DEBUG_LINE_NO:2340
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
EndFunction

Function SpawnContraband()
  ObjectReference[] PotentialContrabandSpawnPoints = SmallItemSpawnMarkers.GetArray() ; #DEBUG_LINE_NO:2346
  Int contrabandToSpawn = Utility.RandomInt(ContrabandMin, Math.Min(ContrabandMax as Float, PotentialContrabandSpawnPoints.Length as Float) as Int) ; #DEBUG_LINE_NO:2347
  Int I = 0 ; #DEBUG_LINE_NO:2348
  While I < contrabandToSpawn ; #DEBUG_LINE_NO:2349
    Contraband.AddRef(PotentialContrabandSpawnPoints[I].PlaceAtMe(Loot_LPI_Contraband_Any as Form, 1, False, False, True, None, None, True)) ; #DEBUG_LINE_NO:2350
    PotentialContrabandSpawnPoints[I].AddKeyword(BEMarkerInUseKeyword) ; #DEBUG_LINE_NO:2351
    I += 1 ; #DEBUG_LINE_NO:2352
  EndWhile ; #DEBUG_LINE_NO:
EndFunction

ObjectReference Function GetEnemyShipLoadDoorMarker()
  If isSurfaceEncounter ; #DEBUG_LINE_NO:
     ; #DEBUG_LINE_NO:
  Else ; #DEBUG_LINE_NO:
    ObjectReference playerShipDoorRef = PlayerShipLoadDoor.GetRef() ; #DEBUG_LINE_NO:2361
    If playerShipDoorRef != None ; #DEBUG_LINE_NO:2362
      ObjectReference enemyShipDoorRef = playerShipDoorRef.GetLinkedRef(LinkShipLoadDoor) ; #DEBUG_LINE_NO:2363
      ObjectReference enemyShipTeleportMarker = enemyShipDoorRef.GetLinkedRef(DynamicallyLinkedDoorTeleportMarkerKeyword) ; #DEBUG_LINE_NO:2364
      If enemyShipTeleportMarker != None ; #DEBUG_LINE_NO:2365
        Return enemyShipTeleportMarker ; #DEBUG_LINE_NO:2366
      ElseIf enemyShipDoorRef != None ; #DEBUG_LINE_NO:2367
        Return enemyShipDoorRef ; #DEBUG_LINE_NO:2368
      EndIf ; #DEBUG_LINE_NO:
    EndIf ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  Return None ; #DEBUG_LINE_NO:2372
EndFunction

Bool Function hasInitialized()
  Return hasInitialized ; #DEBUG_LINE_NO:2377
EndFunction

Function WaitUntilInitialized()
  Int failsafe = 0 ; #DEBUG_LINE_NO:2382
  While !hasInitialized && failsafe < CONST_WaitUntilInitializedTimeoutDelay ; #DEBUG_LINE_NO:2383
    failsafe += 1 ; #DEBUG_LINE_NO:2384
    Utility.Wait(1.0) ; #DEBUG_LINE_NO:2385
  EndWhile ; #DEBUG_LINE_NO:
  If failsafe == CONST_WaitUntilInitializedTimeoutDelay ; #DEBUG_LINE_NO:2387
     ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
EndFunction

Int Function GetLandingRampsOpenState()
  ObjectReference[] landingRamps = enemyShipRef.GetLandingRamps() ; #DEBUG_LINE_NO:2393
  If landingRamps == None ; #DEBUG_LINE_NO:2394
    Return 0 ; #DEBUG_LINE_NO:2396
  EndIf ; #DEBUG_LINE_NO:
  If landingRamps.Length == 0 ; #DEBUG_LINE_NO:2398
    Return 0 ; #DEBUG_LINE_NO:2399
  EndIf ; #DEBUG_LINE_NO:
  Return landingRamps[0].GetOpenState() ; #DEBUG_LINE_NO:2401
EndFunction

Function SetEnemyShipLandingRampsOpenState(Bool abOpen)
  ShouldLandingRampsBeOpenOnLoad = abOpen ; #DEBUG_LINE_NO:2406
  ObjectReference[] landingRamps = enemyShipRef.GetLandingRamps() ; #DEBUG_LINE_NO:2407
  Bool loaded = enemyShipRef.WaitFor3DLoad() ; #DEBUG_LINE_NO:2408
  If loaded && enemyShipRef.IsLanded() && landingRamps != None ; #DEBUG_LINE_NO:2409
    Int I = 0 ; #DEBUG_LINE_NO:2410
    While I < landingRamps.Length ; #DEBUG_LINE_NO:2411
      landingRamps[I].SetOpen(abOpen) ; #DEBUG_LINE_NO:2412
      I += 1 ; #DEBUG_LINE_NO:2413
    EndWhile ; #DEBUG_LINE_NO:
  EndIf ; #DEBUG_LINE_NO:
  If abOpen && SpaceshipPreventRampOpenOnLanding as Bool ; #DEBUG_LINE_NO:2418
    enemyShipRef.RemoveKeyword(SpaceshipPreventRampOpenOnLanding) ; #DEBUG_LINE_NO:2420
  EndIf ; #DEBUG_LINE_NO:
EndFunction

bescript:moduledatum[] Function CopyModuleDataArray(bescript:moduledatum[] input)
  bescript:moduledatum[] output = new bescript:moduledatum[input.Length] ; #DEBUG_LINE_NO:2431
  Int I = 0 ; #DEBUG_LINE_NO:2432
  While I < input.Length ; #DEBUG_LINE_NO:2433
    output[I] = input[I] ; #DEBUG_LINE_NO:2434
    I += 1 ; #DEBUG_LINE_NO:2435
  EndWhile ; #DEBUG_LINE_NO:
  Return output ; #DEBUG_LINE_NO:2437
EndFunction

bescript:moduledatum[] Function CopyAndRandomizeModuleDataArray(bescript:moduledatum[] input)
  bescript:moduledatum[] output = Self.CopyModuleDataArray(input) ; #DEBUG_LINE_NO:2441
  Float[] random = Utility.RandomFloatsFromSeed(Utility.RandomInt(0, 100000), output.Length, 0.0, 1.0) ; #DEBUG_LINE_NO:2442
  Int I = output.Length - 1 ; #DEBUG_LINE_NO:2443
  While I >= 0 ; #DEBUG_LINE_NO:2444
    Int currentRandomIndex = (random[I] * I as Float) as Int ; #DEBUG_LINE_NO:2445
    bescript:moduledatum temp = output[I] ; #DEBUG_LINE_NO:2446
    output[I] = output[currentRandomIndex] ; #DEBUG_LINE_NO:2447
    output[currentRandomIndex] = temp ; #DEBUG_LINE_NO:2448
    I -= 1 ; #DEBUG_LINE_NO:2449
  EndWhile ; #DEBUG_LINE_NO:
  Return output ; #DEBUG_LINE_NO:2451
EndFunction

Function DEBUG_ForceUpdateAllCrew()
  Int I = 0 ; #DEBUG_LINE_NO:2461
  Actor[] allCrewActors = AllCrew.GetArray() as Actor[] ; #DEBUG_LINE_NO:2462
  While I < allCrewActors.Length ; #DEBUG_LINE_NO:2463
    allCrewActors[I].MoveToPackageLocation() ; #DEBUG_LINE_NO:2464
    I += 1 ; #DEBUG_LINE_NO:2465
  EndWhile ; #DEBUG_LINE_NO:
EndFunction

Function DEBUG_SetLandingRampOpen(Bool shouldBeOpen)
  Self.SetEnemyShipLandingRampsOpenState(shouldBeOpen) ; #DEBUG_LINE_NO:2470
EndFunction

Function DEBUG_SetDoorInaccessible(Bool shouldBeInaccessible)
  enemyShipRef.SetExteriorLoadDoorInaccessible(shouldBeInaccessible) ; #DEBUG_LINE_NO:2474
EndFunction
