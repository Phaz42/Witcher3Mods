/***********************************************************************/
/**		AhcRoadFollowing.ws
/**		by Phaz42
/***********************************************************************/

// Road following, toggled while riding with the track-quest button - V on the keyboard, R3 on a gamepad. A single
// press toggles it, with a short sound; a double press does what the button did before, switching the highlighted
// objective. Off by default, at every speed; kept across saves and restarts (a hidden setting of the mod's menu group),
// and switched off, silently, by dismounting - every ride starts without it. On foot nothing changes. Annotations only - no game script is replaced; the horse state (exploration.ws)
// asks AhcRoadFollowing() and calls AhcRoadTogglePoll() each tick.
//
// Menu option "Toggle Road Following with Track Quest button (V/R3)" (ahc_RoadFollowingToggle), on by default. Off,
// the mod behaves as before 5.1.0: the button is vanilla's, and the horse follows roads at every speed it supports,
// walk and trot included (5.0.2 with its walk-and-trot option on).
//
// The button's other uses come first: while a quest or book notice is on screen (track it), while the camera lock has
// a target (combat), and with L3 held (photo mode), the button does what vanilla does.
//
// Console (for testing): ahcsound("gui_global_submenu_whoosh") plays any sound event, to compare candidates.

// How long after a press a second one counts as a double press: vanilla's own window, for the whistle.
function AhcRoadDoubleTapWindow() : float
{
	return 0.4;
}

// The sound of a toggle: twice in quick succession when road following is switched on, once when it is switched off.
function AhcRoadToggleSound() : string
{
	return "gui_loot_popup_close";
}

// How long after the first sound of switching on the second one plays.
function AhcRoadSoundGap() : float
{
	return 0.15;
}

function AhcRoadFollowing() : bool
{
	if( !AhcOption( 'ahc_RoadFollowingToggle' ) )
		return true;
	return theGame.GetInGameConfigWrapper().GetVarValue( 'modAlternateHorseControls', 'ahc_RoadFollowing' ) == "true";
}

// The player's toggle, and only it: it plays the sound, so nothing else switches road following through here.
function AhcSetRoadFollowing( on : bool )
{
	var config : CInGameConfigWrapper;
	var input : CPlayerInput;

	config = theGame.GetInGameConfigWrapper();
	if( on )
		config.SetVarValue( 'modAlternateHorseControls', 'ahc_RoadFollowing', "true" );
	else
		config.SetVarValue( 'modAlternateHorseControls', 'ahc_RoadFollowing', "false" );
	theGame.SaveUserSettings();
	theSound.SoundEvent( AhcRoadToggleSound() );
	input = thePlayer.GetInputHandler();
	if( input )
	{
		if( on )
			input.ahcRoadSoundTime = theGame.GetEngineTimeAsSeconds() + AhcRoadSoundGap();
		else
			input.ahcRoadSoundTime = 0;
	}
}

// Dismounting switches road following off, silently: every ride starts without it. The player's dismount
// only - every horse has this component.
@wrapMethod( W3HorseComponent ) function OnDismountStarted( entity : CEntity )
{
	if( entity == thePlayer )
		AhcRoadFollowingOffOnDismount();
	wrappedMethod( entity );
}

function AhcRoadFollowingOffOnDismount()
{
	var config : CInGameConfigWrapper;
	var input : CPlayerInput;

	config = theGame.GetInGameConfigWrapper();
	if( config.GetVarValue( 'modAlternateHorseControls', 'ahc_RoadFollowing' ) == "true" )
	{
		config.SetVarValue( 'modAlternateHorseControls', 'ahc_RoadFollowing', "false" );
		theGame.SaveUserSettings();
	}
	input = thePlayer.GetInputHandler();
	if( input )
	{
		input.ahcRoadTapTime = 0;
		input.ahcRoadSoundTime = 0;
	}
}

// When a first press was released, waiting for a second; 0 when none waits. On the input handler: a press left over
// from before a dismount, a pause or a load is too old to act on, and AhcRoadTogglePoll drops it.
@addField( CPlayerInput )
var ahcRoadTapTime : float;

// When the second sound of switching on is due; 0 when none is. Dropped, not played late, once a second overdue.
@addField( CPlayerInput )
var ahcRoadSoundTime : float;

// The button belongs to road following only with the option on, while riding, and only when none of its other uses
// has something to act on: a notice to track (TrackQuest), a camera lock with a target (CameraLock - vanilla's own
// condition), photo mode.
function AhcRoadButtonFree() : bool
{
	var hud : CR4ScriptedHud;
	var journal : CR4HudModuleJournalUpdate;

	if( !AhcOption( 'ahc_RoadFollowingToggle' ) || !thePlayer.IsUsingHorse() )
		return false;
	if( thePlayer.IsThreatened() || thePlayer.IsActorLockedToTarget() )
		return false;
	if( theInput.GetActionValue( 'EnablePhotoMode_Step1' ) > 0.f )
		return false;
	hud = (CR4ScriptedHud)theGame.GetHud();
	if( hud )
	{
		journal = (CR4HudModuleJournalUpdate)hud.GetHudModule( "JournalUpdateModule" );
		if( journal && journal.AhcHasTrackTarget() )
			return false;
	}
	return true;
}

// What vanilla's OnTrackQuest acts on: a book notice, or a notice of an active quest on screen.
@addMethod( CR4HudModuleJournalUpdate ) function AhcHasTrackTarget() : bool
{
	if( thePlayer.inv.IsIdValid( m_bookItemId ) )
		return true;
	if( !_bDuringDisplay || journalUpdates.Size() == 0 )
		return false;
	if( (CJournalQuest)journalUpdates[0].journalEntry )
		return manager.GetEntryStatus( journalUpdates[0].journalEntry ) == JS_Active;
	return false;
}

// The button's objective switch (HighlightObjective, acted on at release). While riding, a first release waits for a
// second: a second within the window switches the objective as before; otherwise AhcRoadTogglePoll toggles road
// following once the window has passed. An event: its wrapper takes no explicit return type, as the compiler requires;
// and it calls wrappedMethod once only - the compiler refuses a second call.
@wrapMethod( CR4HudModuleQuests ) function OnHighlightNextObjective( action : SInputAction )
{
	if( AhcRoadButtonTakes( action ) )
		return true;
	return wrappedMethod( action );
}

// Whether a press of the button is road following's (true), or vanilla's (false): not riding, another use has a
// target, or the second press of a double press.
function AhcRoadButtonTakes( action : SInputAction ) : bool
{
	var input : CPlayerInput;
	var now : float;

	input = thePlayer.GetInputHandler();
	if( !input )
		return false;
	if( !AhcRoadButtonFree() )
	{
		input.ahcRoadTapTime = 0;
		return false;
	}
	if( !IsReleased( action ) )
		return true;

	now = theGame.GetEngineTimeAsSeconds();
	if( input.ahcRoadTapTime > 0 && now - input.ahcRoadTapTime <= AhcRoadDoubleTapWindow() )
	{
		input.ahcRoadTapTime = 0;
		return false;
	}
	input.ahcRoadTapTime = now;
	return true;
}

// Called by the horse state each tick: plays the second sound of switching on when it is due, and toggles road
// following on a single press once its double-press window has passed. A press older than a second - waiting through a
// dismount, a pause or a save - is dropped, not acted on late.
function AhcRoadTogglePoll()
{
	var input : CPlayerInput;
	var now : float;
	var waited : float;

	input = thePlayer.GetInputHandler();
	if( !input )
		return;
	now = theGame.GetEngineTimeAsSeconds();
	if( input.ahcRoadSoundTime > 0 && now >= input.ahcRoadSoundTime )
	{
		if( now - input.ahcRoadSoundTime < 1.0 )
			theSound.SoundEvent( AhcRoadToggleSound() );
		input.ahcRoadSoundTime = 0;
	}
	if( input.ahcRoadTapTime <= 0 )
		return;
	waited = now - input.ahcRoadTapTime;
	if( waited <= AhcRoadDoubleTapWindow() )
		return;
	input.ahcRoadTapTime = 0;
	if( waited < 1.0 )
		AhcSetRoadFollowing( !AhcRoadFollowing() );
}

exec function ahcsound( soundEvent : string )
{
	theSound.SoundEvent( soundEvent );
}
