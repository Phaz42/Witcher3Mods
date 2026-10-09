/***********************************************************************/
/**		AlternateHorseControls.ws
/**		by Phaz42
/***********************************************************************/

// The settings menu, Options > Mods > Alternate Horse Controls. Every option is on by default, which is how the
// mod behaves without a menu.

// True unless the player turned the option off. A setting nobody has saved reads as empty, and empty means on.
function AhcOption( varId : name ) : bool
{
	return theGame.GetInGameConfigWrapper().GetVarValue( 'modAlternateHorseControls', varId ) != "false";
}

// The menu shows an empty toggle as off, so the defaults are written once, as the options menu is set up and before
// it reads them - in the main menu too, before any save is loaded, where no player exists yet to do it at spawn.
// A wrapper rather than an override of ingameMenu.ws, so there is nothing for a script merger to merge.
@wrapMethod( CR4IngameMenu ) function OnConfigUI()
{
	AhcSetDefaults();
	wrappedMethod();
}

// Each version of the defaults is written once: 1 - the six options of 5.0.1; 2 - horse whistling (5.0.2); 3 - road
// following, now toggled while riding (AhcRoadFollowing.ws): the option on, the toggle off - its walk-and-trot option
// is gone (5.1.0). A player coming from an earlier version keeps his choices and gets each new default.
function AhcSetDefaults()
{
	var config : CInGameConfigWrapper;
	var initVersion : int;

	config = theGame.GetInGameConfigWrapper();
	initVersion = StringToInt( config.GetVarValue( 'modAlternateHorseControls', 'ahc_InitVersion' ) );
	if( initVersion >= 3 )
		return;

	if( initVersion < 1 )
	{
		config.SetVarValue( 'modAlternateHorseControls', 'ahc_ForwardActsAsSprint', "true" );
		config.SetVarValue( 'modAlternateHorseControls', 'ahc_HoldSprintToGallop', "true" );
		config.SetVarValue( 'modAlternateHorseControls', 'ahc_DoubleTapHoldSprintToCanter', "true" );
		config.SetVarValue( 'modAlternateHorseControls', 'ahc_DisableMouseSteering', "true" );
		config.SetVarValue( 'modAlternateHorseControls', 'ahc_FreeCameraLook', "true" );
	}
	if( initVersion < 2 )
		config.SetVarValue( 'modAlternateHorseControls', 'ahc_WhistleFollow', "true" );
	config.SetVarValue( 'modAlternateHorseControls', 'ahc_RoadFollowingToggle', "true" );
	config.SetVarValue( 'modAlternateHorseControls', 'ahc_RoadFollowing', "false" );
	config.SetVarValue( 'modAlternateHorseControls', 'ahc_InitVersion', "3" );
	theGame.SaveUserSettings();
}
