ScriptName ScaredOfShootingAliasScript Extends ReferenceAlias

Spell Property ScaredOfShootingSpell Auto
Actor Property PlayerRef Auto
Keyword Property LocTypeSettlement Auto

Event OnPlayerFireWeapon(Form akBaseObject)
	If PlayerRef.GetCurrentLocation().HasKeyword(LocTypeSettlement)
		ScaredOfShootingSpell.Cast(PlayerRef, PlayerRef)
	EndIf
EndEvent