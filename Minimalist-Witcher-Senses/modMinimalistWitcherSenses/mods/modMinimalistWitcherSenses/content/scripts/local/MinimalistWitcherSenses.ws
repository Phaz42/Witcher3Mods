// Minimalist Witcher Senses: the settings and their menu, the parts of Witcher Senses changed by wrappers, and the
// markers that can take the place of the game's highlight. The override of focus.ws keeps four simple lines (the
// sounds and the muffled ambience, out of a wrapper's reach) and asks the functions below.

// ---------------------------------------------------------------------------------------------------------
// The settings: read once, again whenever a menu closes, and kept on the game object.

@addField( CR4Game ) var mwsLoaded : bool;
@addField( CR4Game ) var mwsKeepCameraStill : bool;
@addField( CR4Game ) var mwsRemoveEdgeDimming : bool;
@addField( CR4Game ) var mwsRemoveSounds : bool;
@addField( CR4Game ) var mwsKeepAmbientSound : bool;
@addField( CR4Game ) var mwsInstantHighlights : bool;
@addField( CR4Game ) var mwsHighlightStyle : EMwsHighlights;
@addField( CR4Game ) var mwsRemoveRemainsHighlight : bool;
@addField( CR4Game ) var mwsAllowJumpSprint : bool;
@addField( CR4Game ) var mwsRemoveSoundCircles : bool;
@addField( CR4Game ) var mwsRedContainers : EMwsRedContainers;
@addField( CR4Game ) var mwsMarkerScale : float;
@addField( CR4Game ) var mwsTrailScale : float;

// An option's value, or its default when it is not set yet.
function MwsReadToggle( config : CInGameConfigWrapper, id : name, defaultValue : bool ) : bool
{
	var value : string;

	value = config.GetVarValue( 'modMinimalistWitcherSenses', id );
	if ( value == "true" )
	{
		return true;
	}
	if ( value == "false" )
	{
		return false;
	}
	return defaultValue;
}

@addMethod( CR4Game ) function MwsLoad()
{
	var config : CInGameConfigWrapper;
	var style : string;

	config = GetInGameConfigWrapper();
	mwsKeepCameraStill = MwsReadToggle( config, 'mws_KeepCameraStill', true );
	mwsRemoveEdgeDimming = MwsReadToggle( config, 'mws_RemoveEdgeDimming', true );
	mwsRemoveSounds = MwsReadToggle( config, 'mws_RemoveSounds', true );
	mwsKeepAmbientSound = MwsReadToggle( config, 'mws_KeepAmbientSound', true );
	mwsInstantHighlights = MwsReadToggle( config, 'mws_InstantHighlights', true );
	mwsRemoveRemainsHighlight = MwsReadToggle( config, 'mws_RemoveRemainsHighlight', true );
	mwsAllowJumpSprint = MwsReadToggle( config, 'mws_AllowJumpSprint', true );
	mwsRemoveSoundCircles = MwsReadToggle( config, 'mws_RemoveSoundCircles', false );
	if ( config.GetVarValue( 'modMinimalistWitcherSenses', 'mws_RedContainers' ) == "1" )
	{
		mwsRedContainers = MWS_RED_ALL_OWNED;
	}
	else
	{
		mwsRedContainers = MWS_RED_GUARD_IN_REACH;
	}
	// Marker Size: Very Small, Small, Normal (also when not set), Large; Trail Dot Size: Normal, Large, Very Large
	switch ( config.GetVarValue( 'modMinimalistWitcherSenses', 'mws_MarkerSize' ) )
	{
		case "0":	mwsMarkerScale = 0.70f;	break;
		case "1":	mwsMarkerScale = 0.85f;	break;
		case "3":	mwsMarkerScale = 1.25f;	break;
		default:	mwsMarkerScale = 1.0f;
	}
	switch ( config.GetVarValue( 'modMinimalistWitcherSenses', 'mws_TrailDotSize' ) )
	{
		case "1":	mwsTrailScale = 1.4f;	break;
		case "2":	mwsTrailScale = 1.8f;	break;
		default:	mwsTrailScale = 1.0f;
	}
	style = config.GetVarValue( 'modMinimalistWitcherSenses', 'mws_HighlightStyle' );
	if ( style == "0" || style == "1" || style == "2" )
	{
		mwsHighlightStyle = (EMwsHighlights)StringToInt( style );
	}
	else
	{
		mwsHighlightStyle = MWS_HIGHLIGHTS_MARKERS;
	}
	mwsLoaded = true;
}

@addMethod( CR4Game ) function MwsEnsureLoaded()
{
	if ( !mwsLoaded )
	{
		MwsLoad();
	}
}

@addMethod( CR4Game ) function MwsReload()
{
	mwsLoaded = false;
}

// The menu's order: Markers (the default), Glow (the game's own highlights), None.
enum EMwsHighlights
{
	MWS_HIGHLIGHTS_MARKERS = 0,
	MWS_HIGHLIGHTS_GLOW = 1,
	MWS_HIGHLIGHTS_NONE = 2,
}

function MwsKeepCameraStill() : bool
{
	theGame.MwsEnsureLoaded();
	return theGame.mwsKeepCameraStill;
}

function MwsRemoveEdgeDimming() : bool
{
	theGame.MwsEnsureLoaded();
	return theGame.mwsRemoveEdgeDimming;
}

function MwsRemoveSounds() : bool
{
	theGame.MwsEnsureLoaded();
	return theGame.mwsRemoveSounds;
}

function MwsKeepAmbientSound() : bool
{
	theGame.MwsEnsureLoaded();
	return theGame.mwsKeepAmbientSound;
}

function MwsAllowJumpSprint() : bool
{
	theGame.MwsEnsureLoaded();
	return theGame.mwsAllowJumpSprint;
}

function MwsRemoveRemainsHighlight() : bool
{
	theGame.MwsEnsureLoaded();
	return theGame.mwsRemoveRemainsHighlight;
}

function MwsRemoveSoundCircles() : bool
{
	theGame.MwsEnsureLoaded();
	return theGame.mwsRemoveSoundCircles;
}

// Which owned containers the markers show in red: only one a guard could notice being looted (the default), or every
// one.
enum EMwsRedContainers
{
	MWS_RED_GUARD_IN_REACH = 0,
	MWS_RED_ALL_OWNED = 1,
}

// The markers' size, and the trail dots' on top of it, as factors on their drawn sizes.
function MwsMarkerScale() : float
{
	theGame.MwsEnsureLoaded();
	return theGame.mwsMarkerScale;
}

function MwsTrailScale() : float
{
	theGame.MwsEnsureLoaded();
	return theGame.mwsTrailScale;
}

function MwsRedContainers() : EMwsRedContainers
{
	theGame.MwsEnsureLoaded();
	return theGame.mwsRedContainers;
}

function MwsHighlightStyle() : EMwsHighlights
{
	theGame.MwsEnsureLoaded();
	return theGame.mwsHighlightStyle;
}

// The game's highlight drawn in Senses only when the menu says Glow.
function MwsShowGameHighlights() : bool
{
	return MwsHighlightStyle() == MWS_HIGHLIGHTS_GLOW;
}

// The highlights' fade: 0 is instant, a tap a quick flash; 40 is the game's, slow and spreading out from Geralt.
function MwsFadeSpeed() : float
{
	theGame.MwsEnsureLoaded();
	if ( theGame.mwsInstantHighlights )
	{
		return 0.0f;
	}
	return 40.0f;
}

// ---------------------------------------------------------------------------------------------------------
// The menu: the defaults, written when the options menu opens (so it shows them before a save is loaded), the Mod
// Default preset's; versioned, so a later version adds its own and keeps the player's choices. Version 1 existed only
// in test builds, which numbered Highlight Style and Red Containers the other way round: version 2 sets those two again.

function MwsSetDefaults()
{
	var config : CInGameConfigWrapper;
	var version : int;

	config = theGame.GetInGameConfigWrapper();
	version = StringToInt( config.GetVarValue( 'modMinimalistWitcherSenses', 'mws_InitVersion' ) );
	if ( version >= 2 )
	{
		return;
	}
	if ( version < 1 )
	{
		config.SetVarValue( 'modMinimalistWitcherSenses', 'mws_KeepCameraStill', "true" );
		config.SetVarValue( 'modMinimalistWitcherSenses', 'mws_RemoveEdgeDimming', "true" );
		config.SetVarValue( 'modMinimalistWitcherSenses', 'mws_RemoveSounds', "true" );
		config.SetVarValue( 'modMinimalistWitcherSenses', 'mws_KeepAmbientSound', "true" );
		config.SetVarValue( 'modMinimalistWitcherSenses', 'mws_InstantHighlights', "true" );
		config.SetVarValue( 'modMinimalistWitcherSenses', 'mws_RemoveRemainsHighlight', "true" );
		config.SetVarValue( 'modMinimalistWitcherSenses', 'mws_AllowJumpSprint', "true" );
		config.SetVarValue( 'modMinimalistWitcherSenses', 'mws_RemoveSoundCircles', "false" );
	}
	config.SetVarValue( 'modMinimalistWitcherSenses', 'mws_HighlightStyle', "0" );
	config.SetVarValue( 'modMinimalistWitcherSenses', 'mws_RedContainers', "0" );
	config.SetVarValue( 'modMinimalistWitcherSenses', 'mws_MarkerSize', "2" );
	config.SetVarValue( 'modMinimalistWitcherSenses', 'mws_TrailDotSize', "0" );
	config.SetVarValue( 'modMinimalistWitcherSenses', 'mws_InitVersion', "2" );
	theGame.SaveUserSettings();
	theGame.MwsReload();
}

// Toggle Witcher Senses (Instead of Hold) is the game's own accessibility setting, shown in this menu too: copied in
// when the options menu opens, and either one copied to the other when it changes (the game reads its own on every
// press, playerInput.ws). In neither preset.
function MwsCopyFocusToggle( fromGroup : name, fromVar : name, toGroup : name, toVar : name )
{
	var config : CInGameConfigWrapper;

	config = theGame.GetInGameConfigWrapper();
	config.SetVarValue( toGroup, toVar, config.GetVarValue( fromGroup, fromVar ) );
}

@wrapMethod( CR4IngameMenu ) function OnConfigUI()
{
	MwsSetDefaults();
	MwsCopyFocusToggle( 'Accessibility', 'FocusToggle', 'modMinimalistWitcherSenses', 'mws_FocusToggle' );
	wrappedMethod();
}

@wrapMethod( CR4IngameMenu ) function OnOptionValueChanged( groupId : int, optionName : name, optionValue : string )
{
	var result : bool;

	result = wrappedMethod( groupId, optionName, optionValue );
	if ( optionName == 'mws_FocusToggle' )
	{
		MwsCopyFocusToggle( 'modMinimalistWitcherSenses', 'mws_FocusToggle', 'Accessibility', 'FocusToggle' );
	}
	else if ( optionName == 'FocusToggle' )
	{
		MwsCopyFocusToggle( 'Accessibility', 'FocusToggle', 'modMinimalistWitcherSenses', 'mws_FocusToggle' );
	}
	return result;
}

// The help notes: while one of the mod's options is selected, its help in the banner under the option list, the one
// the game's Accessibility page uses for its preset's description (the menu's updateBardsBalladText and
// showBardsBalladTooltip); never the notification popup, which other mods' menus clear on every selection. The
// banner's text field is two lines tall: it is grown to the text while a note shows, and given back afterwards. The
// game names only the option, so the options' ids are the mod's own.

@addField( CR4IngameMenu ) var mwsHelpShown : name;
@addField( CR4IngameMenu ) var mwsHelpTextHeight : float;

function MwsHelpKey( option : name ) : string
{
	switch ( option )
	{
		case 'mws_KeepCameraStill':
			return "mws_KeepCameraStill_help";
		case 'mws_RemoveEdgeDimming':
			return "mws_RemoveEdgeDimming_help";
		case 'mws_RemoveSounds':
			return "mws_RemoveSounds_help";
		case 'mws_KeepAmbientSound':
			return "mws_KeepAmbientSound_help";
		case 'mws_InstantHighlights':
			return "mws_InstantHighlights_help";
		case 'mws_HighlightStyle':
			return "mws_HighlightStyle_help";
		case 'mws_RemoveRemainsHighlight':
			return "mws_RemoveRemainsHighlight_help";
		case 'mws_AllowJumpSprint':
			return "mws_AllowJumpSprint_help";
		case 'mws_RemoveSoundCircles':
			return "mws_RemoveSoundCircles_help";
		case 'mws_RedContainers':
			return "mws_RedContainers_help";
		case 'mws_FocusToggle':
			return "mws_FocusToggle_help";
		case 'mws_MarkerSize':
			return "mws_MarkerSize_help";
		case 'mws_TrailDotSize':
			return "mws_TrailDotSize_help";
	}
	return "";
}

@addMethod( CR4IngameMenu ) function MwsHelpTextField() : CScriptedFlashObject
{
	var list, tooltip : CScriptedFlashSprite;

	list = m_flashModule.GetChildFlashSprite( "mcOptionListModule" );
	if ( !list )
	{
		return NULL;
	}
	tooltip = list.GetChildFlashSprite( "tooltip" );
	if ( !tooltip )
	{
		return NULL;
	}
	return tooltip.GetMemberFlashObject( "textField" );
}

@addMethod( CR4IngameMenu ) function MwsShowHelp( text : string )
{
	var textField : CScriptedFlashObject;

	m_fxUpdateBardsBalladText.InvokeSelfOneArg( FlashArgString( text ) );
	textField = MwsHelpTextField();
	if ( textField )
	{
		if ( mwsHelpTextHeight <= 0 )
		{
			mwsHelpTextHeight = textField.GetMemberFlashNumber( "height" );
		}
		textField.SetMemberFlashNumber( "height", MaxF( mwsHelpTextHeight, textField.GetMemberFlashNumber( "textHeight" ) + 8 ) );
	}
	m_flashModule.GetMemberFlashFunction( "showBardsBalladTooltip" ).InvokeSelfOneArg( FlashArgBool( true ) );
}

// The banner given back as the game has it: its own text, its height, hidden.
@addMethod( CR4IngameMenu ) function MwsHideHelp()
{
	var textField : CScriptedFlashObject;

	if ( mwsHelpShown == '' )
	{
		return;
	}
	mwsHelpShown = '';
	textField = MwsHelpTextField();
	if ( textField && mwsHelpTextHeight > 0 )
	{
		textField.SetMemberFlashNumber( "height", mwsHelpTextHeight );
	}
	UpdateBardsBalladTooltipText();
	m_flashModule.GetMemberFlashFunction( "showBardsBalladTooltip" ).InvokeSelfOneArg( FlashArgBool( false ) );
}

@wrapMethod( CR4IngameMenu ) function OnOptionSelectionChanged( optionName : name, value : bool )
{
	var result : bool;
	var key : string;

	result = wrappedMethod( optionName, value );
	if ( value )
	{
		key = MwsHelpKey( optionName );
		if ( key != "" )
		{
			mwsHelpShown = optionName;
			MwsShowHelp( GetLocStringByKey( key ) );
		}
		else
		{
			MwsHideHelp();
		}
	}
	else if ( optionName == mwsHelpShown )
	{
		MwsHideHelp();
	}
	return result;
}

@wrapMethod( CR4IngameMenu ) function OnOptionPanelNavigateBack()
{
	MwsHideHelp();
	return wrappedMethod();
}

// Leaving the menu hides the note, and the settings are read again.
@wrapMethod( CR4IngameMenu ) function OnClosingMenu()
{
	MwsHideHelp();
	theGame.MwsReload();
	return wrappedMethod();
}

// ---------------------------------------------------------------------------------------------------------
// The parts changed by wrappers.

// Senses switched on: the fade, the game's highlight, the edge dimming and the jump block, as the menu says. The
// fade's last value is set before the game's code (vanilla sets 40 once, at game start); the rest is undone after it.
@wrapMethod( CFocusModeController ) function ActivateInternal()
{
	SetFadeParameters( 10.0f, 30.0f, 16.0f, MwsFadeSpeed() );
	wrappedMethod();
	if ( IsActive() )
	{
		if ( !MwsShowGameHighlights() )
		{
			EnableVisuals( false );
		}
		if ( MwsRemoveEdgeDimming() )
		{
			EnableExtendedVisuals( false, 0.0f );
		}
		if ( MwsAllowJumpSprint() )
		{
			thePlayer.UnblockAction( EIAB_Jump, 'focus' );
		}
	}
}

@wrapMethod( CFocusModeController ) function Deactivate()
{
	SetFadeParameters( 10.0f, 30.0f, 16.0f, MwsFadeSpeed() );
	wrappedMethod();
}

@wrapMethod( CFocusModeController ) function OnGameStarted()
{
	var result : bool;

	result = wrappedMethod();
	SetFadeParameters( 10.0f, 30.0f, 16.0f, MwsFadeSpeed() );
	return result;
}

// The camera and sprinting, without overriding their code: theGame.IsFocusModeActive() is a script function, and
// while the mod's flag is set it answers false. The flag is set around the camera code with Keep Camera Still, so
// every Senses branch in it sees no Senses (the game's Senses camera, the modern camera's shift, the camera reset
// behind MWS-4, the close camera's own Senses offsets, the swimming Senses camera, the padding), and around
// CanSprint with Allow Jump and Sprint. Each wrapper restores the flag as it found it: the states' events call the
// player's through super.

@addField( CR4Game ) var mwsHideFocus : bool;

// theGame is const to other classes: its field is set through a method of its own.
@addMethod( CR4Game ) function MwsSetHideFocus( hide : bool )
{
	mwsHideFocus = hide;
}

@wrapMethod( CR4Game ) function IsFocusModeActive() : bool
{
	if ( mwsHideFocus )
	{
		return false;
	}
	return wrappedMethod();
}

// Hides Senses from the code that follows when hide is true; returns the flag as it was, for MwsHideFocusEnd.
function MwsHideFocusBegin( hide : bool ) : bool
{
	var previous : bool;

	previous = theGame.mwsHideFocus;
	if ( hide )
	{
		theGame.MwsSetHideFocus( true );
	}
	return previous;
}

function MwsHideFocusEnd( previous : bool )
{
	theGame.MwsSetHideFocus( previous );
}

@wrapMethod( CR4Player ) function OnGameCameraTick( out moveData : SCameraMovementData, dt : float )
{
	var result, previous : bool;

	previous = MwsHideFocusBegin( MwsKeepCameraStill() );
	result = wrappedMethod( moveData, dt );
	MwsHideFocusEnd( previous );
	return result;
}

@wrapMethod( CR4Player ) function OnGameCameraPostTick( out moveData : SCameraMovementData, dt : float )
{
	var result, previous : bool;

	previous = MwsHideFocusBegin( MwsKeepCameraStill() );
	result = wrappedMethod( moveData, dt );
	MwsHideFocusEnd( previous );
	return result;
}

@wrapMethod( CR4PlayerStateExploration ) function OnGameCameraTick( out moveData : SCameraMovementData, dt : float )
{
	var result, previous : bool;

	previous = MwsHideFocusBegin( MwsKeepCameraStill() );
	result = wrappedMethod( moveData, dt );
	MwsHideFocusEnd( previous );
	return result;
}

@wrapMethod( CR4PlayerStateExploration ) function OnGameCameraPostTick( out moveData : SCameraMovementData, dt : float )
{
	var result, previous : bool;

	previous = MwsHideFocusBegin( MwsKeepCameraStill() );
	result = wrappedMethod( moveData, dt );
	MwsHideFocusEnd( previous );
	return result;
}

@wrapMethod( CR4PlayerStateSwimming ) function OnGameCameraTick( out moveData : SCameraMovementData, dt : float )
{
	var result, previous : bool;

	previous = MwsHideFocusBegin( MwsKeepCameraStill() );
	result = wrappedMethod( moveData, dt );
	MwsHideFocusEnd( previous );
	return result;
}

@wrapMethod( CR4PlayerStateSwimming ) function OnGameCameraPostTick( out moveData : SCameraMovementData, dt : float )
{
	var result, previous : bool;

	previous = MwsHideFocusBegin( MwsKeepCameraStill() );
	result = wrappedMethod( moveData, dt );
	MwsHideFocusEnd( previous );
	return result;
}

@wrapMethod( CR4Player ) function GetCameraPadding() : float
{
	var result : float;
	var previous : bool;

	previous = MwsHideFocusBegin( MwsKeepCameraStill() );
	result = wrappedMethod();
	MwsHideFocusEnd( previous );
	return result;
}

@wrapMethod( CR4Player ) function CanSprint( speed : float ) : bool
{
	var result, previous : bool;

	previous = MwsHideFocusBegin( MwsAllowJumpSprint() );
	result = wrappedMethod( speed );
	MwsHideFocusEnd( previous );
	return result;
}

// No sparkle on lootable corpses: the game's code not run when Senses start, so the effect never starts (stopped
// after it started, it showed for a moment).
@wrapMethod( W3ActorRemains ) function OnFocusModeEnabled( enabled : bool )
{
	if ( enabled && MwsRemoveRemainsHighlight() )
	{
		StopEffect( 'remains_highlight' );
		return true;
	}
	return wrappedMethod( enabled );
}

// No sound circles on the creatures the engine counts as heard: the effect not started.
@wrapMethod( CGameplayEntity ) function OnFocusModeSound( enabled : bool, colorBlind : bool )
{
	if ( enabled && MwsRemoveSoundCircles() )
	{
		return false;
	}
	return wrappedMethod( enabled, colorBlind );
}

// ---------------------------------------------------------------------------------------------------------
// The markers: with the menu's Highlights at Markers, the game's highlight off and a small glyph of the mod's own over
// each object the game would highlight and each hostile creature, on the game's oneliners HUD layer. The layer's
// Flash functions are called from outside; no game script is overridden for it.

enum EMwsMarkerKind
{
	MWS_PLANT = 0,
	MWS_CONTAINER = 1,
	MWS_DOOR = 2,
	MWS_OTHER = 3,
	MWS_CLUE = 4,
	MWS_HOSTILE = 5,
	MWS_REMAINS = 6,
	MWS_TRAIL = 7,
	MWS_NO_MARKER = 8,
	MWS_CONTAINER_OWNED = 9,
	MWS_DOOR_LOCKED = 10,
}

struct SMwsMarker
{
	var entity : CGameplayEntity;
	var id : int;
	var kind : EMwsMarkerKind;
	var offset : Vector;
	var hasBox : bool;
	var boxMin : Vector;
	var boxMax : Vector;
	var hidden : bool;
}

class CMwsMarkers
{
	private var markers : array< SMwsMarker >;
	// each marker's object, in the same order: looked up by the engine's own Contains, not a script loop
	private var markerEntities : array< CGameplayEntity >;
	private var ready : bool;
	private var hud : CR4ScriptedHud;
	private var flash : CScriptedFlashSprite;
	private var createFunction : CScriptedFlashFunction;
	private var removeFunction : CScriptedFlashFunction;
	private var traceGroups : array< name >;
	private var refreshIn : float;
	private var nextId : int;
	private var spotContainers : array< W3Container >;
	private var spotPositions : array< Vector >;
	private var guardPositions : array< Vector >;

	// Each marker is two sprites on the same spot: the layer is capped at the game's UI opacity, 0.8, and two copies
	// reach about 0.85 (the top one's outline darkens the one beneath). Their ids are the mod's own, apart from the
	// game's and Friendly HUD's (100500 to 100909).
	private const var FIRST_ID : int;					default FIRST_ID = 835800000;
	private const var RANGE : float;					default RANGE = 30;
	private const var PLANT_RANGE : float;				default PLANT_RANGE = 65;
	private const var DOOR_RANGE : float;				default DOOR_RANGE = 50;
	private const var REFRESH_INTERVAL : float;			default REFRESH_INTERVAL = 0.2;
	// The game's looting and stealing signals reach NPCs within 10 m of Geralt (hudModuleLootPopup.ws, LootPopup.ws).
	private const var SIGNAL_REACH : float;				default SIGNAL_REACH = 10;

	// The layer's two Flash functions; false when the HUD is not there yet.
	private function Init() : bool
	{
		var module : CR4HudModuleOneliners;

		hud = (CR4ScriptedHud)theGame.GetHud();
		if ( !hud )
		{
			return false;
		}
		module = (CR4HudModuleOneliners)hud.GetHudModule( "OnelinersModule" );
		if ( !module )
		{
			return false;
		}
		flash = module.GetModuleFlash();
		createFunction = flash.GetMemberFlashFunction( "CreateOneliner" );
		removeFunction = flash.GetMemberFlashFunction( "RemoveOneliner" );
		// what hides a marker: walls, terrain, trees and anything else solid; what Geralt walks through has no collision
		traceGroups.Clear();
		traceGroups.PushBack( 'Static' );
		traceGroups.PushBack( 'Terrain' );
		traceGroups.PushBack( 'Foliage' );
		traceGroups.PushBack( 'Destructible' );
		traceGroups.PushBack( 'Door' );
		traceGroups.PushBack( 'Platforms' );
		traceGroups.PushBack( 'Fence' );
		if ( nextId < FIRST_ID )
		{
			nextId = FIRST_ID;
		}
		return true;
	}

	public function Clear()
	{
		var i : int;

		if ( removeFunction )
		{
			for ( i = 0; i < markers.Size(); i += 1 )
			{
				removeFunction.InvokeSelfOneArg( FlashArgInt( markers[ i ].id ) );
				removeFunction.InvokeSelfOneArg( FlashArgInt( markers[ i ].id + 1 ) );
			}
		}
		markers.Clear();
		markerEntities.Clear();
		ready = false;
	}

	// Called on the oneliners module's own tick, which runs after the camera has moved, so the markers do not lag.
	public function Tick( timeDelta : float )
	{
		if ( MwsHighlightStyle() != MWS_HIGHLIGHTS_MARKERS || !theGame.GetFocusModeController().IsActive() )
		{
			if ( ready || markers.Size() > 0 )
			{
				Clear();
			}
			return;
		}
		if ( !ready )
		{
			if ( !Init() )
			{
				return;
			}
			ready = true;
			refreshIn = 0;
		}
		refreshIn -= timeDelta;
		if ( refreshIn <= 0 )
		{
			refreshIn = REFRESH_INTERVAL;
			Refresh();
		}
		Draw();
	}

	// The objects in range, every REFRESH_INTERVAL: markers made and dropped, and each one's line of sight.
	private function Refresh()
	{
		var entities : array< CGameplayEntity >;
		var marker : SMwsMarker;
		var e : CGameplayEntity;
		var box : Box;
		var i : int;
		var kind : EMwsMarkerKind;
		var camera : Vector;

		// Everything within RANGE, and the plants and doors farther out by the engine's class filter, which applies
		// before its cap: a search returns at most 1024 objects, an arbitrary part of a busy place, whatever it asks for
		// (measured 2026-10-26: 1024 within 65 m on Hierarch Square, 380 within 30 m; 325 doors within 500 m filtered).
		FindGameplayEntitiesInRange( entities, thePlayer, RANGE, 10000 );
		AddFound( entities, PLANT_RANGE, 'W3Herb' );
		AddFound( entities, DOOR_RANGE, 'W3NewDoor' );
		AddFound( entities, DOOR_RANGE, 'W3Door' );
		CollectSpots( entities );
		for ( i = markers.Size() - 1; i >= 0; i -= 1 )
		{
			e = markers[ i ].entity;
			if ( !e || !entities.Contains( e ) || Kind( e ) != markers[ i ].kind || !InRange( e, markers[ i ].kind ) )
			{
				removeFunction.InvokeSelfOneArg( FlashArgInt( markers[ i ].id ) );
				removeFunction.InvokeSelfOneArg( FlashArgInt( markers[ i ].id + 1 ) );
				markers.Erase( i );
				markerEntities.Erase( i );
			}
		}
		for ( i = 0; i < entities.Size(); i += 1 )
		{
			e = entities[ i ];
			if ( markerEntities.Contains( e ) )
			{
				continue;
			}
			kind = Kind( e );
			if ( kind == MWS_NO_MARKER || !InRange( e, kind ) )
			{
				continue;
			}
			marker.entity = e;
			marker.id = nextId;
			marker.kind = kind;
			marker.hasBox = PartsBox( e, box );
			marker.boxMin = box.Min;
			marker.boxMax = box.Max;
			marker.offset = Offset( e, kind, marker.hasBox, box );
			marker.hidden = false;
			nextId += 2;
			createFunction.InvokeSelfTwoArgs( FlashArgInt( marker.id ), FlashArgString( Text( kind ) ) );
			createFunction.InvokeSelfTwoArgs( FlashArgInt( marker.id + 1 ), FlashArgString( Text( kind ) ) );
			markers.PushBack( marker );
			markerEntities.PushBack( e );
		}
		camera = theCamera.GetCameraPosition();
		for ( i = 0; i < markers.Size(); i += 1 )
		{
			markers[ i ].hidden = !InSight( markers[ i ], camera );
		}
	}

	// The objects of one class within a range, added to those already found.
	private function AddFound( out entities : array< CGameplayEntity >, range : float, className : name )
	{
		var found : array< CGameplayEntity >;
		var i : int;

		FindGameplayEntitiesInRange( found, thePlayer, range, 10000, '', 0, NULL, className );
		for ( i = 0; i < found.Size(); i += 1 )
		{
			if ( !entities.Contains( found[ i ] ) )
			{
				entities.PushBack( found[ i ] );
			}
		}
	}

	private function HasMarker( e : CGameplayEntity ) : bool
	{
		return markerEntities.Contains( e );
	}

	// Each marker moved to its object's place on screen, with its opacity.
	private function Draw()
	{
		var interactions : CR4HudModuleInteractions;
		var sprite : CScriptedFlashSprite;
		var screen : Vector;
		var x, y, alpha : float;
		var i, j : int;
		var shown : bool;

		interactions = (CR4HudModuleInteractions)hud.GetHudModule( "InteractionsModule" );
		for ( i = 0; i < markers.Size(); i += 1 )
		{
			shown = false;
			alpha = 0;
			if ( markers[ i ].entity && !markers[ i ].hidden )
			{
				alpha = Opacity( markers[ i ] );
				// the hand-off: while the game shows its own Senses icon on the object (a sign, a door), no marker
				if ( alpha > 0 && interactions && interactions.MwsShowsFocusIcon( markers[ i ].entity ) )
				{
					alpha = 0;
				}
				if ( alpha > 0 && theCamera.WorldVectorToViewRatio( markers[ i ].entity.GetWorldPosition() + markers[ i ].offset, x, y ) )
				{
					shown = true;
					screen = hud.GetScaleformPoint( ( x + 1 ) / 2, ( y + 1 ) / 2 );
				}
			}
			for ( j = 0; j < 2; j += 1 )
			{
				sprite = flash.GetChildFlashSprite( "mcOneliner" + ( markers[ i ].id + j ) );
				if ( !sprite )
				{
					continue;
				}
				if ( shown )
				{
					sprite.SetPosition( screen.X, screen.Y );
					sprite.SetAlpha( alpha );
					sprite.SetVisible( true );
				}
				else
				{
					sprite.SetVisible( false );
				}
			}
		}
	}

	// The kind of marker an entity gets, or none: objects the game would highlight in Senses (an empty container's
	// highlight is none) and living creatures hostile to Geralt; never a clue that is no longer available.
	private function Kind( e : CGameplayEntity ) : EMwsMarkerKind
	{
		var actor : CActor;
		var clue : W3MonsterClue;
		var herb : W3Herb;
		var remains : W3ActorRemains;
		var container : W3Container;
		var door : W3Door;
		var newDoor : W3NewDoor;
		var lockable : W3LockableEntity;
		var visibility : EFocusModeVisibility;

		if ( !e || e == thePlayer )
		{
			return MWS_NO_MARKER;
		}
		actor = (CActor)e;
		if ( actor )
		{
			if ( actor.IsAlive() && GetAttitudeBetween( thePlayer, actor ) == AIA_Hostile )
			{
				return MWS_HOSTILE;
			}
			return MWS_NO_MARKER;
		}
		// destroyed crates, a clue the quest has used: the game stops detecting it, though it keeps its highlight
		clue = (W3MonsterClue)e;
		if ( clue && !clue.isAvailable )
		{
			return MWS_NO_MARKER;
		}
		visibility = e.GetFocusModeVisibility();
		door = (W3Door)e;
		newDoor = (W3NewDoor)e;
		if ( visibility == FMV_None && ( door || newDoor ) )
		{
			return DoorKind( (W3LockableEntity)e );
		}
		// a fake door: a door's look and a "Locked" prompt, no door, never opened, hidden from Senses by the game
		lockable = (W3LockableEntity)e;
		if ( !lockable && IsFakeDoor( e ) )
		{
			if ( HasOwnTag( e ) )
			{
				return MWS_DOOR;
			}
			return MWS_DOOR_LOCKED;
		}
		if ( visibility == FMV_None )
		{
			return MWS_NO_MARKER;
		}
		if ( visibility == FMV_Clue )
		{
			// a trail piece is a decal on the ground and nothing else
			if ( e.GetComponentsCountByClassName( 'CDecalComponent' ) > 0 && e.GetComponentsCountByClassName( 'CMeshComponent' ) == 0
				&& e.GetComponentsCountByClassName( 'CRigidMeshComponent' ) == 0 && e.GetComponentsCountByClassName( 'CStaticMeshComponent' ) == 0 )
			{
				return MWS_TRAIL;
			}
			return MWS_CLUE;
		}
		herb = (W3Herb)e;
		if ( herb )
		{
			return MWS_PLANT;
		}
		remains = (W3ActorRemains)e;
		if ( remains )
		{
			return MWS_REMAINS;
		}
		container = (W3Container)e;
		if ( container )
		{
			return ContainerKind( container );
		}
		if ( door || newDoor )
		{
			return DoorKind( (W3LockableEntity)e );
		}
		return MWS_OTHER;
	}

	// A door's marker. The game hides a locked door from Senses (its focus visibility is none, measured 2026-10-26), so
	// a door is marked here whatever its visibility: red when it is locked and can never be unlocked, so that nobody
	// walks up to it; brown otherwise, a locked one too while it can be unlocked, the key in Geralt's pocket or not.
	// None for a door the game hides without a lock.
	private function DoorKind( door : W3LockableEntity ) : EMwsMarkerKind
	{
		var locked : CComponent;

		// locked: its interaction "Locked" enabled, the one the game prompts with
		locked = door.GetComponent( "Locked" );
		if ( !locked || !locked.IsEnabled() )
		{
			if ( door.GetFocusModeVisibility() == FMV_None )
			{
				return MWS_NO_MARKER;
			}
			return MWS_DOOR;
		}
		if ( NeverUnlocks( door ) )
		{
			return MWS_DOOR_LOCKED;
		}
		return MWS_DOOR;
	}

	// A fake door: no door class, only an object from the game's doors with its interaction "Locked" enabled, such as
	// gameplay\interactive_objects\doors\fake_door\fake_door_very_rich_nov_door_c.w2ent in Novigrad (measured
	// 2026-10-26). Other objects prompt "Locked" too (some citizens, a brazier), so the template's folder decides; its
	// name is a string split, asked only of an object whose "Locked" is on. Matched without backslashes in the pattern.
	private function IsFakeDoor( e : CGameplayEntity ) : bool
	{
		var locked : CComponent;
		var template : string;

		locked = e.GetComponent( "Locked" );
		if ( !locked || !locked.IsEnabled() )
		{
			return false;
		}
		template = e.GetReadableName();
		return StrFindFirst( template, "interactive_objects" ) >= 0 && StrFindFirst( template, "doors" ) >= 0;
	}

	// A door unlocks by its key, on interaction, when the key is an item Geralt can carry (lockableEntity.ws), or by a
	// quest or a scene, which reach a door by its tag (quest_function.ws, scene_functions.ws,
	// switchEvent_ManageNewDoor.ws). So it never unlocks with no key that is an item and no tag but the two the game
	// gives doors in general. A tag of its own does not prove that a quest uses it: such a door stays brown, the safe
	// side.
	private function NeverUnlocks( door : W3LockableEntity ) : bool
	{
		var key : name;

		key = door.MwsKeyName();
		if ( IsNameValid( key ) && IsNameValid( theGame.GetDefinitionsManager().GetItemCategory( key ) ) )
		{
			return false;
		}
		return !HasOwnTag( door );
	}

	// A tag other than the two the game gives doors in general, by which a quest or a scene could reach the object.
	private function HasOwnTag( e : CGameplayEntity ) : bool
	{
		var tags : array< name >;
		var i : int;

		tags = e.GetTags();
		for ( i = 0; i < tags.Size(); i += 1 )
		{
			if ( tags[ i ] != 'navigation_correction' && tags[ i ] != 'InteractiveEntity' )
			{
				return true;
			}
		}
		return false;
	}

	// What a container's marker needs from the whole refresh: every container in range, for the copies of one placed
	// twice; and, for Red Containers: Guard in Reach, where the living guards stand (the game's own NPC type), within
	// RANGE plus the farthest a guard can count from a container; whether one can see it is ContainerKind's.
	private function CollectSpots( entities : array< CGameplayEntity > )
	{
		var guards : array< CGameplayEntity >;
		var container : W3Container;
		var herb : W3Herb;
		var remains : W3ActorRemains;
		var npc : CNewNPC;
		var i : int;

		spotContainers.Clear();
		spotPositions.Clear();
		for ( i = 0; i < entities.Size(); i += 1 )
		{
			container = (W3Container)entities[ i ];
			herb = (W3Herb)entities[ i ];
			remains = (W3ActorRemains)entities[ i ];
			if ( container && !herb && !remains && VecDistanceSquared( container.GetWorldPosition(), thePlayer.GetWorldPosition() ) <= RANGE * RANGE )
			{
				spotContainers.PushBack( container );
				spotPositions.PushBack( container.GetWorldPosition() );
			}
		}
		guardPositions.Clear();
		if ( MwsRedContainers() != MWS_RED_GUARD_IN_REACH )
		{
			return;
		}
		FindGameplayEntitiesInRange( guards, thePlayer, RANGE + 15, 500, '', 0, NULL, 'CNewNPC' );
		for ( i = 0; i < guards.Size(); i += 1 )
		{
			npc = (CNewNPC)guards[ i ];
			if ( npc && npc.IsAlive() && npc.GetNPCType() == ENGT_Guard )
			{
				guardPositions.PushBack( npc.GetWorldPosition() );
			}
		}
	}

	// A container's marker. Some are placed twice, the same template on the same spot (measured 2026-10-23): one copy
	// gets the prompt and is looted, the other keeps its items and is never lootable. So the copies are one spot, with
	// one marker, and none once any copy is empty. Owned is the game's stealing test, on any copy.
	private function ContainerKind( container : W3Container ) : EMwsMarkerKind
	{
		var copies : array< W3Container >;
		var position : Vector;
		var owned : bool;
		var reach, range : float;
		var loot : CInteractionComponent;
		var i : int;

		position = container.GetWorldPosition();
		for ( i = 0; i < spotContainers.Size(); i += 1 )
		{
			if ( spotContainers[ i ] == container )
			{
				copies.PushBack( spotContainers[ i ] );
			}
			// the distance first: the template's name is a string split, asked only of a copy on the same spot
			else if ( VecDistanceSquared( spotPositions[ i ], position ) < 0.0025 )
			{
				if ( spotContainers[ i ].GetReadableName() == container.GetReadableName() )
				{
					copies.PushBack( spotContainers[ i ] );
				}
			}
		}
		if ( copies.Size() == 0 )
		{
			copies.PushBack( container );
		}
		reach = SIGNAL_REACH;
		for ( i = 0; i < copies.Size(); i += 1 )
		{
			if ( copies[ i ].IsEmpty() )
			{
				return MWS_NO_MARKER;
			}
			// one marker per spot: the copy that has it keeps it
			if ( copies[ i ] != container && HasMarker( copies[ i ] ) )
			{
				return MWS_NO_MARKER;
			}
			owned = owned || ( !copies[ i ].disableStealing && !copies[ i ].HasQuestItem() );
			// how far Geralt can stand from it and still loot it, so that the color does not change with where Geralt stands
			loot = (CInteractionComponent)copies[ i ].GetComponent( "Loot" );
			if ( loot )
			{
				range = SIGNAL_REACH + loot.GetRangeMax();
				if ( range > reach )
				{
					reach = range;
				}
			}
		}
		if ( !owned )
		{
			return MWS_CONTAINER;
		}
		if ( MwsRedContainers() == MWS_RED_ALL_OWNED )
		{
			return MWS_CONTAINER_OWNED;
		}
		for ( i = 0; i < guardPositions.Size(); i += 1 )
		{
			if ( VecDistanceSquared( guardPositions[ i ], container.GetWorldPosition() ) <= reach * reach
				&& GuardSees( guardPositions[ i ], container ) )
			{
				return MWS_CONTAINER_OWNED;
			}
		}
		return MWS_CONTAINER;
	}

	// Whether a guard standing there can see the container: a line from the guard's eyes, 1.7 m above the feet, to the middle
	// of its box (without one, 0.3 m above its base). Seen when nothing is in between, or when the first thing the
	// line meets is the container itself or lies within its box and a 5 cm margin, as for the markers' own lines of
	// sight. Without it, guards in a house next door made a village's containers red through the walls (2026-10-28).
	private function GuardSees( guard : Vector, container : W3Container ) : bool
	{
		var eyes, target, hitPosition, hitNormal : Vector;
		var hitMaterial : name;
		var hitComponent : CComponent;
		var box : Box;
		var hasBox : bool;

		eyes = guard;
		eyes.Z += 1.7;
		hasBox = PartsBox( container, box );
		if ( hasBox )
		{
			target = ( box.Min + box.Max ) * 0.5;
		}
		else
		{
			target = container.GetWorldPosition();
			target.Z += 0.3;
		}
		if ( !theGame.GetWorld().StaticTraceWithAdditionalInfo( eyes, target, hitPosition, hitNormal, hitMaterial, hitComponent, traceGroups ) )
		{
			return true;
		}
		if ( hitComponent && hitComponent.GetEntity() == container )
		{
			return true;
		}
		return hasBox && MwsInBox( hitPosition, box.Min, box.Max, 0.05 );
	}

	private function InRange( e : CGameplayEntity, kind : EMwsMarkerKind ) : bool
	{
		var range : float;

		range = RANGE;
		if ( kind == MWS_PLANT )
		{
			range = PLANT_RANGE;
		}
		else if ( kind == MWS_DOOR || kind == MWS_DOOR_LOCKED )
		{
			range = DOOR_RANGE;
		}
		return VecDistanceSquared( e.GetWorldPosition(), thePlayer.GetWorldPosition() ) <= range * range;
	}

	// The glyphs, from the few the HUD's font has; the colors as drawn, worked back so that two copies under the layer's
	// cap show the colors chosen (on screen about 0.845 times the drawn color, plus the outline's 1, 4, 7).
	private function Text( kind : EMwsMarkerKind ) : string
	{
		var glyph, color : string;
		var size : float;

		// the mod's own icons, from its texture cache (img:// paths start below gameplay\gui_new\)
		switch ( kind )
		{
			case MWS_CONTAINER:
				return Icon( "container", 28.0f );
			case MWS_CONTAINER_OWNED:
				return Icon( "container_owned", 28.0f );
			case MWS_DOOR:
				return Icon( "door", 34.0f );
			case MWS_DOOR_LOCKED:
				return Icon( "door_locked", 34.0f );
		}
		switch ( kind )
		{
			case MWS_PLANT:
				glyph = "&#176;";	color = "#78ED70";	size = 35.0f;	break;	// a fresh green, #66CC66 on screen
			case MWS_OTHER:
				glyph = "&#8226;";	color = "#FFB169";	size = 25.0f;	break;	// toward the game's orange, about #D99A5F on screen
			case MWS_CLUE:
				glyph = "?";		color = "#FF5A4A";	size = 40.0f;	break;
			case MWS_TRAIL:
				glyph = "&#8226;";	color = "#FF5A4A";	size = 20.0f * MwsTrailScale();	break;
			case MWS_HOSTILE:
				glyph = "&#176;";	color = "#EE4B3F";	size = 40.0f;	break;
			case MWS_REMAINS:
				glyph = "&#215;";	color = "#EE4B3F";	size = 25.0f;	break;
		}
		return "<font size='" + RoundF( size * MwsMarkerScale() ) + "' color='" + color + "'>" + glyph + "</font>";
	}

	// The icons are 64 x 64: drawn at no more than that (Large at 125 % is 43 for the door), they stay sharp.
	private function Icon( iconName : string, size : float ) : string
	{
		var drawn : int;

		drawn = RoundF( size * MwsMarkerScale() );
		return "<img src=\"img://icons/mws/" + iconName + ".xbm\" width=\"" + drawn + "\" height=\"" + drawn + "\">";
	}

	// The opacity, 0 to 100, by the distance from Geralt: plants fade from 40 to 65 m, clues reach at most 50 % at 1 m
	// and none at 25 m, trail pieces fade from 1.5 to 10 m; the rest at full.
	private function Opacity( marker : SMwsMarker ) : float
	{
		var distance, maximum, full, none : float;

		switch ( marker.kind )
		{
			case MWS_PLANT:
				maximum = 100;	full = 40;	none = 65;	break;
			case MWS_CLUE:
				maximum = 50;	full = 1;	none = 25;	break;
			case MWS_TRAIL:
				maximum = 100;	full = 1.5;	none = 10;	break;
			default:
				return 100;
		}
		distance = VecDistance( marker.entity.GetWorldPosition(), thePlayer.GetWorldPosition() );
		if ( distance >= none )
		{
			return 0;
		}
		if ( distance <= full )
		{
			return maximum;
		}
		return maximum * ( none - distance ) / ( none - full );
	}

	// Where the marker sits, from the object's base: for doors, clues and containers the middle of their visible parts
	// (a door's base is its hinge, a clue's can be a corner, a container's interaction prompt sits at its top); else,
	// and for a container without them, a height.
	private function Offset( e : CGameplayEntity, kind : EMwsMarkerKind, hasBox : bool, box : Box ) : Vector
	{
		var offset : Vector;
		var height : float;

		offset = Vector( 0, 0, 0 );
		if ( hasBox && ( kind == MWS_DOOR || kind == MWS_DOOR_LOCKED || kind == MWS_CLUE || kind == MWS_CONTAINER
			|| kind == MWS_CONTAINER_OWNED ) )
		{
			offset = ( box.Min + box.Max ) * 0.5 - e.GetWorldPosition();
		}
		switch ( kind )
		{
			case MWS_PLANT:		height = -0.2;	break;
			case MWS_CONTAINER:
			case MWS_CONTAINER_OWNED:
				if ( !hasBox )
				{
					height = 0.4;
				}
				break;
			case MWS_OTHER:		height = 0.5;	break;
			case MWS_HOSTILE:	height = 1;		break;
			default:			height = 0;
		}
		offset.Z += height;
		offset.W = 0;
		return offset;
	}

	// The box around an object's visible parts (meshes of each kind, destruction parts and systems), if its middle lies
	// within 5 m of the object's base; false when it has none.
	private function PartsBox( e : CGameplayEntity, out all : Box ) : bool
	{
		var classes : array< name >;
		var components : array< CComponent >;
		var bounded : CBoundedComponent;
		var box : Box;
		var i, j, found : int;

		classes.PushBack( 'CMeshComponent' );
		classes.PushBack( 'CRigidMeshComponent' );
		classes.PushBack( 'CStaticMeshComponent' );
		classes.PushBack( 'CDestructionComponent' );
		classes.PushBack( 'CDestructionSystemComponent' );
		found = 0;
		for ( i = 0; i < classes.Size(); i += 1 )
		{
			components.Clear();		// the call adds to the array rather than replacing it
			components = e.GetComponentsByClassName( classes[ i ] );
			for ( j = 0; j < components.Size(); j += 1 )
			{
				bounded = (CBoundedComponent)components[ j ];
				if ( !bounded )
				{
					continue;
				}
				box = bounded.GetBoundingBox();
				if ( found == 0 )
				{
					all = box;
				}
				else
				{
					all.Min = Vector( MinF( all.Min.X, box.Min.X ), MinF( all.Min.Y, box.Min.Y ), MinF( all.Min.Z, box.Min.Z ) );
					all.Max = Vector( MaxF( all.Max.X, box.Max.X ), MaxF( all.Max.Y, box.Max.Y ), MaxF( all.Max.Z, box.Max.Z ) );
				}
				found += 1;
			}
		}
		if ( found == 0 )
		{
			return false;
		}
		return VecDistance( ( all.Min + all.Max ) * 0.5, e.GetWorldPosition() ) < 5;
	}

	// The line of sight from the camera.
	private function InSight( marker : SMwsMarker, camera : Vector ) : bool
	{
		var world : CWorld;
		var target, hitPosition, hitNormal : Vector;
		var i : int;
		var corner, middle : Vector;

		if ( !marker.entity )
		{
			return false;
		}
		world = theGame.GetWorld();
		if ( marker.kind == MWS_PLANT )
		{
			// a plant's marker sits in the ground: the line aims 0.3 m above its base, and a hit farther than 0.6 m from
			// that point hides it
			target = marker.entity.GetWorldPosition();
			target.Z += 0.3;
			if ( !world.StaticTrace( camera, target, hitPosition, hitNormal, traceGroups ) )
			{
				return true;
			}
			return VecDistance( hitPosition, target ) <= 0.6;
		}
		target = marker.entity.GetWorldPosition() + marker.offset;
		if ( marker.hasBox )
		{
			if ( marker.kind != MWS_CONTAINER && marker.kind != MWS_CONTAINER_OWNED )
			{
				return SeesPoint( camera, target, marker, 0.3 );
			}
			// a container: its middle, then eight points toward the corners of its box, a quarter of the way in; seen
			// when any of them is, so that a post in front of its middle does not hide one mostly in view (2026-10-23),
			// each with a 5 cm margin, so that a wall it leans on from inside stays a wall
			if ( SeesPoint( camera, target, marker, 0.05 ) )
			{
				return true;
			}
			for ( i = 0; i < 8; i += 1 )
			{
				corner = marker.boxMin;
				if ( i % 2 == 1 )
				{
					corner.X = marker.boxMax.X;
				}
				if ( ( i / 2 ) % 2 == 1 )
				{
					corner.Y = marker.boxMax.Y;
				}
				if ( i / 4 == 1 )
				{
					corner.Z = marker.boxMax.Z;
				}
				middle = ( marker.boxMin + marker.boxMax ) * 0.5;
				if ( SeesPoint( camera, middle + ( corner - middle ) * 0.75, marker, 0.05 ) )
				{
					return true;
				}
			}
			return false;
		}
		// no box (a trail piece): the line stops 0.6 m short, so the object's own collision does not count
		target = target - VecNormalize( target - camera ) * 0.6;
		return !world.StaticTrace( camera, target, hitPosition, hitNormal, traceGroups );
	}

	// One line of sight to a point inside an object with a box: the first thing the line meets decides. The object
	// itself (a part of it, or anything within its box and the margin) means its surface is in view, as the game's
	// outline is from any side; anything else stands in front.
	private function SeesPoint( camera, target : Vector, marker : SMwsMarker, margin : float ) : bool
	{
		var hitPosition, hitNormal : Vector;
		var hitMaterial : name;
		var hitComponent : CComponent;

		if ( !theGame.GetWorld().StaticTraceWithAdditionalInfo( camera, target, hitPosition, hitNormal, hitMaterial, hitComponent, traceGroups ) )
		{
			return true;
		}
		if ( hitComponent && hitComponent.GetEntity() == marker.entity )
		{
			return true;
		}
		return MwsInBox( hitPosition, marker.boxMin, marker.boxMax, margin );
	}
}

function MwsInBox( p, boxMin, boxMax : Vector, margin : float ) : bool
{
	return p.X >= boxMin.X - margin && p.X <= boxMax.X + margin && p.Y >= boxMin.Y - margin && p.Y <= boxMax.Y + margin
		&& p.Z >= boxMin.Z - margin && p.Z <= boxMax.Z + margin;
}

@addField( CFocusModeController ) var mwsMarkers : CMwsMarkers;

// A lockable entity's key, which the game keeps protected: whether a locked door can ever be unlocked by one.
@addMethod( W3LockableEntity ) function MwsKeyName() : name
{
	return keyItemName;
}

@addMethod( CFocusModeController ) function MwsMarkersTick( timeDelta : float )
{
	if ( !mwsMarkers )
	{
		if ( MwsHighlightStyle() != MWS_HIGHLIGHTS_MARKERS )
		{
			return;
		}
		mwsMarkers = new CMwsMarkers in theGame;
	}
	mwsMarkers.Tick( timeDelta );
}

@wrapMethod( CR4HudModuleOneliners ) function OnTick( timeDelta : float )
{
	var result : bool;

	result = wrappedMethod( timeDelta );
	theGame.GetFocusModeController().MwsMarkersTick( timeDelta );
	return result;
}

// With Highlights at Markers the door and container markers do the whole job: the game's own Senses icon on a door,
// and on a container (its stealing hand), is never added (2026-10-23). Every other Senses icon of the game
// stays (a sign's), and the hand-off below with it.
@wrapMethod( CR4HudModuleInteractions ) function AddFocusInteractionIcon( entity : CEntity, actionName : name )
{
	var door : W3Door;
	var newDoor : W3NewDoor;
	var container : W3Container;

	door = (W3Door)entity;
	newDoor = (W3NewDoor)entity;
	container = (W3Container)entity;
	if ( ( door || newDoor || container ) && MwsHighlightStyle() == MWS_HIGHLIGHTS_MARKERS )
	{
		return;
	}
	wrappedMethod( entity, actionName );
}

// Whether the game shows its Senses icon on this entity now (a sign, a door): its own list, on screen.
@addMethod( CR4HudModuleInteractions ) function MwsShowsFocusIcon( entity : CEntity ) : bool
{
	var i : int;

	for ( i = 0; i < m_focusInteractionIcons.Size(); i += 1 )
	{
		if ( m_focusInteractionIcons[ i ].m_entity == entity && m_focusInteractionIcons[ i ].m_isSeen )
		{
			return true;
		}
	}
	return false;
}
