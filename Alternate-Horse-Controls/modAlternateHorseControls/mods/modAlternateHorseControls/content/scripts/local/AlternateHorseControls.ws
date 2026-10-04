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

function AhcSetDefaults()
{
	var config : CInGameConfigWrapper;

	config = theGame.GetInGameConfigWrapper();
	if( StringToInt( config.GetVarValue( 'modAlternateHorseControls', 'ahc_InitVersion' ) ) >= 1 )
		return;

	config.SetVarValue( 'modAlternateHorseControls', 'ahc_ForwardActsAsSprint', "true" );
	config.SetVarValue( 'modAlternateHorseControls', 'ahc_HoldSprintToGallop', "true" );
	config.SetVarValue( 'modAlternateHorseControls', 'ahc_DoubleTapHoldSprintToCanter', "true" );
	config.SetVarValue( 'modAlternateHorseControls', 'ahc_DisableMouseSteering', "true" );
	config.SetVarValue( 'modAlternateHorseControls', 'ahc_RoadFollowingWalkTrot', "true" );
	config.SetVarValue( 'modAlternateHorseControls', 'ahc_FreeCameraLook', "true" );
	config.SetVarValue( 'modAlternateHorseControls', 'ahc_InitVersion', "1" );
	theGame.SaveUserSettings();
}
