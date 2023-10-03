ScriptName StealthRun extends Actor

Event OnEnterSneaking()
  speedUp()
EndEvent

Function speedUp()
	Debug.Notification("This message is displayed on the HUD menu.")
	Actor player = Game.GetPlayer()
	ActorValue speedMult = Game.GetForm(0x0002DA) as ActorValue
	ActorValue animSpeed = Game.GetForm(0x0002D2) as ActorValue
	player.SetValue(speedMult, 200.0)
	While player.IsSneaking()
		If player.GetAnimationVariableBool("IsFirstPerson")
			If player.GetValue(animSpeed) != 100.0
				player.SetValue(animSpeed, 100.0)
			EndIf
		Else
			If player.GetValue(animSpeed) != 130.0
				player.SetValue(animSpeed, 130.0)
			EndIf
		EndIf
		Utility.Wait(0.1)
	EndWhile
	player.SetValue(animSpeed, 100.0)
	player.SetValue(speedMult, 100.0)
EndFunction