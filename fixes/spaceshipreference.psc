ScriptName SpaceshipReference Extends ObjectReference Native hidden

;-- Functions ---------------------------------------

Function AddPerk(Perk akPerk, Bool abNotify) Native

Bool Function CanLandAtMarker(ObjectReference akLandingMarker) Native

Int Function CheckContrabandStatus(Bool abCheckWholeShip) Native

Function DisableWithGravJump() Native

Function DisableWithGravJumpNoWait() Native

Function DisableWithTakeOffOrLanding() Native

Function DisableWithTakeOffOrLandingNoWait() Native

Function EnableAI(Bool abEnable, Bool abPauseVoice) Native

Function EnablePartRepair(ActorValue aSystemHealth, Bool abEnable) Native

Bool Function EnableWithGravJump() Native

Bool Function EnableWithGravJumpNoWait() Native

Bool Function EnableWithLanding() Native

Bool Function EnableWithLandingNoWait() Native

Function EvaluatePackage(Bool abResetAI) Native

Int Function GetActorFactionReaction(Actor akOtherActor) Native

spaceshipreference[] Function GetAllCombatTargets() Native

SpaceshipReference Function GetCombatTarget() Native

Float Function GetContrabandWeight(Bool abCheckWholeShip) Native

Faction Function GetCrimeFaction() Native

Package Function GetCurrentPackage() Native

spaceshipreference[] Function GetDockedShips() Native

ObjectReference[] Function GetExteriorLoadDoors() Native

ObjectReference[] Function GetExteriorRefs(Keyword apKeyword) Native

Int Function GetFactionRank(Faction akFaction) Native

Int Function GetFactionReaction(SpaceshipReference akOther) Native

SpaceshipReference Function GetFirstDockedShip() Native

Float Function GetGravJumpRange() Native

ObjectReference Function GetKiller() Native

ObjectReference[] Function GetLandingRamps() Native

Int Function GetLevel() Native

spaceshipbase Function GetLeveledSpaceshipBase() Native

Bool Function GetNoBleedoutRecovery() Native

Int Function GetPartCount(Int aiShipPartID) Native

Int Function GetPartPower(Int aiShipPartID, Int aiShipPartIndex) Native

Keyword Function GetReactorClassKeyword() Native

Float Function GetShipMaxCargoWeight() Native

Weapon Function GetWeaponGroupBaseObject(ActorValue aWeaponGroupSystemHealth) Native

Bool Function HasPerk(Perk akPerk) Native

Bool Function InstantDock(ObjectReference akTarget) Native

Function InstantUndock() Native

Bool Function IsAIEnabled() Native

Bool Function IsAlarmed() Native

Bool Function IsAlerted() Native

Bool Function IsDead() Native

Bool Function IsDetectedBy(SpaceshipReference akOther) Native

Bool Function IsDocked() Native

Bool Function IsDockedAsChild() Native

Bool Function IsDockedWith(SpaceshipReference akTarget) Native

Bool Function IsEssential(Bool abIncludeActors) Native

Bool Function IsGhost() Native

Bool Function IsHostileToSpaceship(SpaceshipReference akSpaceship) Native

Bool Function IsInCombat() Native

Bool Function IsInFaction(Faction akFaction) Native

Bool Function IsInScene() Native

Bool Function IsLanded() Native

Bool Function IsProtected(Bool abIncludeActors) Native

Bool Function IsRampDown() Native

Function Kill(SpaceshipReference akKiller) Native

Function KillEssential(SpaceshipReference akKiller) Native

Function KillSilent(SpaceshipReference akKiller) Native

Function LockPowerAllocation(Int aiShipPartID, Int aiShipPartIndex, Bool abLock) Native

Function ModFactionRank(Faction akFaction, Int aiAmount) Native

Function MoveToPackageLocation() Native

Event OnCombatListAdded(SpaceshipReference akTarget)
  ; Empty function
EndEvent

Event OnCombatListRemoved(SpaceshipReference akTarget)
  ; Empty function
EndEvent

Event OnCombatStateChanged(ObjectReference akTarget, Int aeCombatState)
  ; Empty function
EndEvent

Event OnDeath(ObjectReference akKiller)
  ; Empty function
EndEvent

Event OnDying(ObjectReference akKiller)
  ; Empty function
EndEvent

Event OnEnterBleedout()
  ; Empty function
EndEvent

Event OnEscortWaitStart()
  ; Empty function
EndEvent

Event OnEscortWaitStop()
  ; Empty function
EndEvent

Event OnKill(ObjectReference akVictim)
  ; Empty function
EndEvent

Event OnLocationChange(Location akOldLoc, Location akNewLoc)
  ; Empty function
EndEvent

Event OnRecoverFromBleedout()
  ; Empty function
EndEvent

Event OnShipBought()
  ; Empty function
EndEvent

Event OnShipDock(Bool abComplete, SpaceshipReference akDocking, SpaceshipReference akParent)
  ; Empty function
EndEvent

Event OnShipFarTravel(Location aDepartureLocation, Location aArrivalLocation, Int aState)
  ; Empty function
EndEvent

Event OnShipGravJump(Location aDestination, Int aState)
  ; Empty function
EndEvent

Event OnShipLanding(Bool abComplete)
  ; Empty function
EndEvent

Event OnShipRampDown()
  ; Empty function
EndEvent

Event OnShipRefueled(Int aFuelAdded)
  ; Empty function
EndEvent

Event OnShipScan(Location aPlanet, ObjectReference[] aMarkersArray)
  ; Empty function
EndEvent

Event OnShipSold()
  ; Empty function
EndEvent

Event OnShipSystemDamaged(ActorValue akSystem, Int aBlocksLost, Bool aElectromagneticDamage, Bool aFullyDamaged)
  ; Empty function
EndEvent

Event OnShipSystemPowerChange(ActorValue akSystem, Bool abAddPower, Bool abDamagedRelated)
  ; Empty function
EndEvent

Event OnShipSystemRepaired(ActorValue akSystem, Int aBlocksGained, Bool aElectromagneticDamage)
  ; Empty function
EndEvent

Event OnShipTakeOff(Bool abComplete)
  ; Empty function
EndEvent

Event OnShipUndock(Bool abComplete, SpaceshipReference akUndocking, SpaceshipReference akParent)
  ; Empty function
EndEvent

Function OpenInventory() Native

Int Function PathToReference(ObjectReference aTarget, Float afNormalizedSpeed, Float afNormalizedRotationSpeed, Float afTargetRadius, Bool abHardRadius) Native

Function RemoveFromAllFactions() Native

Function RemoveFromFaction(Faction akFaction) Native

Function RemovePerk(Perk akPerk) Native

Function SendAssaultAlarm() Native

Function SendPiracyAlarm() Native

Function SendSmugglingAlarm(Bool abCheckWholeShip) Native

Function SetAlert(Bool abAlerted) Native

Function SetAttackShipOnSight(Bool abAttackOnSight) Native

Function SetAvoidPlayer(Bool abAvoid) Native

Function SetCombatStyle(combatstyle akCombatStyle) Native

Function SetCrimeFaction(Faction akFaction) Native

Function SetEssential(Bool abEssential) Native

Function SetFactionRank(Faction akFaction, Int aiRank) Native

Function SetForwardVelocity(Float aVelocity) Native

Function SetGhost(Bool abIsGhost) Native

Function SetIgnoreFriendlyHits(Bool aIgnoreFriendlyHits) Native

Function SetNoBleedoutRecovery(Bool abBleedoutRecoveryNotAllowed) Native

Function SetNotShowOnStealthMeter(Bool abNotShow) Native

Function SetPartPower(Int aiShipPartID, Int aiShipPartIndex, Int aiPower) Native

Function SetPlayerResistingArrest() Native

Function SetProtected(Bool abProtected) Native

Function SetUnconscious(Bool aUnconscious) Native

Function ShowBarterMenu() Native

Function StartCombat(SpaceshipReference akTarget, Bool abPreferTarget) Native

Function StopCombat() Native

Function StopCombatAlarm() Native

Function TakeOff() Native

Function AddToFaction(Faction akFaction)
  If !Self.IsInFaction(akFaction)
    Self.SetFactionRank(akFaction, 0)
  EndIf
EndFunction

Bool Function IsExteriorLoadDoorInaccessible()
  ObjectReference[] exteriorLoadDoors = Self.GetExteriorLoadDoors()
  If exteriorLoadDoors.Length == 0
    Return False
  Else
    Return exteriorLoadDoors[0].IsDoorInaccessible()
  EndIf
EndFunction

Function SetExteriorLoadDoorInaccessible(Bool abInaccessible)
  ObjectReference[] exteriorLoadDoors = Self.GetExteriorLoadDoors()
  Int I = 0
  While I < exteriorLoadDoors.Length
    If abInaccessible == True
      exteriorLoadDoors[I].SetLockLevel(254)
      exteriorLoadDoors[I].Lock(True, False, True)
    Else
      exteriorLoadDoors[I].Unlock(False)
    EndIf
    I += 1
  EndWhile
EndFunction

Bool Function IsLandingDeckClear()
  ObjectReference[] exteriorLoadDoors = Self.GetExteriorLoadDoors()
  If exteriorLoadDoors.Length == 0
    Return True
  Else
    ObjectReference exteriorLandingDeckTrigger = exteriorLoadDoors[0].GetLinkedRef(None)
    If exteriorLandingDeckTrigger == None
      Return True
    Else
      Return exteriorLandingDeckTrigger.GetTriggerObjectCount() == 0
    EndIf
  EndIf
EndFunction
