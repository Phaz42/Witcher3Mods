/***********************************************************************/
/**		MinimalistCamera.ws
/**		by Phaz42
/***********************************************************************/

class MinimalistCamera
{
	// Global System Vars
	private var modName : name;
		default modName = 'modMinimalistCamera';
	private var config: CInGameConfigWrapper;
	private var debug : bool;
		default debug = false;

	public var Responsiveness,       Zoom,       Height,       Offset		: float;
	public var CombatResponsiveness, CombatZoom, CombatHeight, CombatOffset	: float;
	public var DodgeResponsiveness,  DodgeZoom,  DodgeHeight,  DodgeOffset	: float;
	public var SignsResponsiveness,  SignsZoom,  SignsHeight,  SignsOffset	: float;
	public var 						 SenseZoom,  SenseHeight,  SenseOffset	: float;
	public var CurrResponsiveness,   CurrZoom,   CurrHeight,   CurrOffset	: float;

	private var EnemyRange, ZoomPerEnemy, CurrZoomPerEnemy, DynamicZoom : float;
	private var DodgeFx, SignFx : bool;

	private var cameraDistanceResetInProgress : bool;
		default cameraDistanceResetInProgress = false;
	private var cameraDistanceResetProgressCounter : int;
		default cameraDistanceResetProgressCounter = 0;


	// Initialization

	public function Init()
	{
		McSetDefaults();
		GetConfig();
	}

    public function ReInit()
	{
        Init();
    }


	// Main

	public function SetExplorationCam()
	{
		CurrResponsiveness = Responsiveness;
		CurrZoom = Zoom;
		CurrHeight = Height;
		CurrOffset = Offset;
	}

	private var oldActualEnemiesInRange : int;
		default oldActualEnemiesInRange = 0;
	public function SetCombatCam()
	{
		var hostilesInRangeArray, enemiesInRangeArray, visibleEnemiesInRangeArray : array<CActor>;
		var hostilesInRange, enemiesInRange, visibleEnemiesInRange, actualEnemiesInRange : int;

		ResetCameraDistance(false);

		CurrResponsiveness = CombatResponsiveness;
		CurrZoom = CombatZoom;
		CurrHeight = CombatHeight;
		CurrOffset = CombatOffset;
		CurrZoomPerEnemy = ZoomPerEnemy * DynamicZoom;

		hostilesInRangeArray = ((CActor)thePlayer).GetNPCsAndPlayersInRange( EnemyRange, 20, '', FLAG_Attitude_Hostile );
		hostilesInRange = hostilesInRangeArray.Size();

		thePlayer.GetEnemiesInRange( enemiesInRangeArray );
		enemiesInRange = enemiesInRangeArray.Size();

		thePlayer.GetVisibleEnemies( visibleEnemiesInRangeArray );
		visibleEnemiesInRange = visibleEnemiesInRangeArray.Size();

		actualEnemiesInRange = Min( hostilesInRange, enemiesInRange );
		actualEnemiesInRange = Min( actualEnemiesInRange, visibleEnemiesInRange );

		if ( debug ) LogIfChanged( "actualEnemiesInRange", oldActualEnemiesInRange, actualEnemiesInRange );
		oldActualEnemiesInRange = actualEnemiesInRange;

		switch ( actualEnemiesInRange )
		{
			case 0:
			case 1:
				break;
			case 2:
			case 3:
			case 4:
			case 5:
			case 6:
			case 7:
				CurrZoom = CombatZoom - ( ( actualEnemiesInRange - 2 ) * CurrZoomPerEnemy );
				break;
			default:
				CurrZoom = CombatZoom - ( ( 8					 - 2 ) * CurrZoomPerEnemy );
				break;
		}
	}

	public function SetDodgeCamIfNeeded()
	{
		if ( !DodgeFx ) return;
		if ( !thePlayer.IsCurrentlyDodging() ) return;

		if ( DodgeZoom < CurrZoom ) CurrZoom = DodgeZoom;
		CurrResponsiveness = DodgeResponsiveness;
		CurrHeight = DodgeHeight;
		CurrOffset = DodgeOffset;
	}

	public function SetSignsCamIfNeeded()
	{
		if ( !SignFx ) return;
		if ( !thePlayer.IsCastingSign() ) return;
		if ( thePlayer.GetCurrentlyCastSign() == ST_Quen ) return;

		CurrZoom = SignsZoom;
		CurrResponsiveness = SignsResponsiveness;
		CurrHeight = SignsHeight;
		CurrOffset = SignsOffset;

		if ( thePlayer.GetCurrentlyCastSign() == ST_Yrden && !thePlayer.IsCurrentSignChanneled() )
			CurrZoom = SignsZoom + 1;

		if ( thePlayer.GetCurrentlyCastSign() == ST_Axii )
			CurrZoom = SignsZoom + 2;
	}

	public function ResetCameraDistance( startReset : bool )
	{
		if ( cameraDistanceResetInProgress) cameraDistanceResetProgressCounter += 1;
		if ( startReset && !cameraDistanceResetInProgress)
		{
			// Start Reset
			cameraDistanceResetInProgress = true;
			cameraDistanceResetProgressCounter = 0;
			thePlayer.HardLockToTarget( true );
		}
		else if ( !startReset && cameraDistanceResetInProgress && cameraDistanceResetProgressCounter > 1 )
		{
			// Stop Reset
			cameraDistanceResetInProgress = false;
			cameraDistanceResetProgressCounter = 0;
			thePlayer.HardLockToTarget( false );
		}
	}

	public function LogIfChanged( description : string, oldVal : string, newVal : string )
	{
		if ( oldVal != newVal )
		{
			Log( "Time: " + theGame.GetEngineTimeAsSeconds() / 60 + ", New " + description + ": " + newVal );
			ShowNotification( description + ": " + newVal );
		}
	}


	// Utility Functions & Menu handling

	public function Log( msg : string )
	{
		LogChannel( modName, msg );
	}

	public function HudMsg ( msg : string )
	{
		Log( "HudMsg: " + msg );
		GetWitcherPlayer().DisplayHudMessage( msg );
	}

	public function ConsoleMsg ( msg : string )
	{
		Log( "ConsoleMsg: " + msg );
		((CR4ScriptedHud)theGame.GetHud()).HudConsoleMsg( msg );
	}

	public function ShowNotification ( msg : string )
	{
		Log( "ShowNotification: " + msg );
		theGame.GetGuiManager().ShowNotification( msg );
	}

	private function GetConfigItem( configItem : name ) : string
	{
		config = theGame.GetInGameConfigWrapper();
		return config.GetVarValue( modName, configItem );
	}

	private function GetIntConfigItem( configItem : name ) : int
	{
		return StringToInt(GetConfigItem(configItem));
	}

	private function GetFloatConfigItem( configItem : name ) : float
	{
		return StringToFloat(GetConfigItem(configItem));
	}

	private function GetConfig()
	{
		Responsiveness			= GetFloatConfigItem( 'mc_Responsiveness') / 10;
		DynamicZoom				= GetIntConfigItem(   'mc_DynamicZoom') * 0.5;
		DodgeFx					= (bool)GetConfigItem('mc_DodgeFx');
		SignFx					= (bool)GetConfigItem('mc_SignFx');

		Zoom					= GetFloatConfigItem( 'mc_Zoom') / 2;
		Height					= GetFloatConfigItem( 'mc_Height') / 10;
		Offset					= GetFloatConfigItem( 'mc_Offset') / 4;

		CombatResponsiveness	= GetFloatConfigItem( 'mc_CombatResponsiveness') / 10;
		CombatZoom				= GetFloatConfigItem( 'mc_CombatZoom') / 2;
		CombatHeight			= GetFloatConfigItem( 'mc_CombatHeight') / 10;
		CombatOffset			= GetFloatConfigItem( 'mc_CombatOffset') / 4;

		DodgeResponsiveness		= GetFloatConfigItem( 'mc_DodgeResponsiveness') / 10;
		DodgeZoom				= GetFloatConfigItem( 'mc_DodgeZoom') / 2;
		DodgeHeight				= GetFloatConfigItem( 'mc_DodgeHeight') / 10;
		DodgeOffset				= GetFloatConfigItem( 'mc_DodgeOffset') / 4;

		SignsResponsiveness		= GetFloatConfigItem( 'mc_SignsResponsiveness') / 10;
		SignsZoom				= GetFloatConfigItem( 'mc_SignsZoom') / 2;
		SignsHeight				= GetFloatConfigItem( 'mc_SignsHeight') / 10;
		SignsOffset				= GetFloatConfigItem( 'mc_SignsOffset') / 4;

		SenseZoom				= GetFloatConfigItem( 'mc_SenseZoom') / 2;
		SenseHeight				= GetFloatConfigItem( 'mc_SenseHeight') / 10;
		SenseOffset				= GetFloatConfigItem( 'mc_SenseOffset') / 4 ;

		EnemyRange				= GetFloatConfigItem( 'mc_EnemyRange');
		ZoomPerEnemy			= GetFloatConfigItem( 'mc_ZoomPerEnemy') / 2;
	}
}


// ---------------------------------------------------------------------------------------------------------
// The menu: the defaults, the Medium preset's, written when the options menu opens (so it shows them before a save
// is loaded) and at spawn, in one save; versioned by mc_InitVersion, so the player's choices stay until a version
// sets them again. Version 2 (5.1.1, with Camera Range) puts every player back on the defaults.

function McSetDefaults()
{
	var config : CInGameConfigWrapper;
	var group : name;

	group = 'modMinimalistCamera';
	config = theGame.GetInGameConfigWrapper();
	if ( StringToInt( config.GetVarValue( group, 'mc_InitVersion' ) ) >= 2 )
	{
		return;
	}
	config.SetVarValue( group, 'mc_CameraRange', "1" );
	config.SetVarValue( group, 'mc_Responsiveness', "4" );
	config.SetVarValue( group, 'mc_DynamicZoom', "2" );
	config.SetVarValue( group, 'mc_DodgeFx', "true" );
	config.SetVarValue( group, 'mc_SignFx', "true" );
	config.SetVarValue( group, 'mc_Zoom', "3" );
	config.SetVarValue( group, 'mc_Height', "2" );
	config.SetVarValue( group, 'mc_Offset', "3" );

	config.SetVarValue( group, 'mc_CombatResponsiveness', "7" );
	config.SetVarValue( group, 'mc_CombatZoom', "3" );
	config.SetVarValue( group, 'mc_CombatHeight', "2" );
	config.SetVarValue( group, 'mc_CombatOffset', "0" );

	config.SetVarValue( group, 'mc_DodgeResponsiveness', "3" );
	config.SetVarValue( group, 'mc_DodgeZoom', "0" );
	config.SetVarValue( group, 'mc_DodgeHeight', "2" );
	config.SetVarValue( group, 'mc_DodgeOffset', "0" );

	config.SetVarValue( group, 'mc_SignsResponsiveness', "10" );
	config.SetVarValue( group, 'mc_SignsZoom', "-3" );
	config.SetVarValue( group, 'mc_SignsHeight', "3" );
	config.SetVarValue( group, 'mc_SignsOffset', "-3" );

	config.SetVarValue( group, 'mc_SenseZoom', "3" );
	config.SetVarValue( group, 'mc_SenseHeight', "2" );
	config.SetVarValue( group, 'mc_SenseOffset', "3" );

	config.SetVarValue( group, 'mc_EnemyRange', "12" );
	config.SetVarValue( group, 'mc_ZoomPerEnemy', "0.8" );

	config.SetVarValue( group, 'mc_InitVersion', "2" );
	theGame.SaveUserSettings();
}

// The game's two camera rotation settings (Gameplay), shown in this menu too: copied in when the options menu opens,
// and either one copied to the other when it changes. A change here is applied at once, through the functions the
// game itself uses (it applies its own on leaving its page, or on the change). In neither preset.
function McCopySetting( fromGroup : name, fromVar : name, toGroup : name, toVar : name )
{
	var config : CInGameConfigWrapper;

	config = theGame.GetInGameConfigWrapper();
	config.SetVarValue( toGroup, toVar, config.GetVarValue( fromGroup, fromVar ) );
}

@wrapMethod( CR4IngameMenu ) function OnConfigUI()
{
	McSetDefaults();
	McCopySetting( 'Gameplay', 'AutoCameraCenter', 'modMinimalistCamera', 'mc_AutoCameraCenter' );
	McCopySetting( 'Gameplay', 'SoftLockCameraAssist', 'modMinimalistCamera', 'mc_SoftLockCameraAssist' );
	wrappedMethod();
}

@wrapMethod( CR4IngameMenu ) function OnOptionValueChanged( groupId : int, optionName : name, optionValue : string )
{
	var result : bool;

	result = wrappedMethod( groupId, optionName, optionValue );
	switch ( optionName )
	{
		case 'mc_AutoCameraCenter':
			McCopySetting( 'modMinimalistCamera', 'mc_AutoCameraCenter', 'Gameplay', 'AutoCameraCenter' );
			if ( thePlayer )
			{
				thePlayer.SetAutoCameraCenter( optionValue == "true" );
			}
			break;
		case 'mc_SoftLockCameraAssist':
			McCopySetting( 'modMinimalistCamera', 'mc_SoftLockCameraAssist', 'Gameplay', 'SoftLockCameraAssist' );
			if ( thePlayer )
			{
				thePlayer.SetSoftLockCameraAssist( optionValue == "true" );
			}
			break;
		case 'AutoCameraCenter':
			McCopySetting( 'Gameplay', 'AutoCameraCenter', 'modMinimalistCamera', 'mc_AutoCameraCenter' );
			break;
		case 'SoftLockCameraAssist':
			McCopySetting( 'Gameplay', 'SoftLockCameraAssist', 'modMinimalistCamera', 'mc_SoftLockCameraAssist' );
			break;
	}
	return result;
}

// Leaving the in-game menu reads the settings again.
@wrapMethod( CR4CommonIngameMenu ) function OnClosingMenu()
{
	if ( thePlayer && thePlayer.mc )
	{
		thePlayer.mc.ReInit();
	}
	return wrappedMethod();
}

// The help notes: while one of the mod's options is selected, its help in the banner under the option list, the one
// the game's Accessibility page uses for its preset's description (the menu's updateBardsBalladText and
// showBardsBalladTooltip); never the notification popup, which other mods' menus clear on every selection. The
// banner's text field is two lines tall: it is grown to the text while a note shows, and given back afterwards.

@addField( CR4IngameMenu ) var mcHelpShown : name;
@addField( CR4IngameMenu ) var mcHelpTextHeight : float;

function McHelpKey( option : name ) : string
{
	switch ( option )
	{
		case 'mc_Responsiveness':
			return "mc_Responsiveness_help";
		case 'mc_DynamicZoom':
			return "mc_DynamicZoom_help";
		case 'mc_DodgeFx':
			return "mc_DodgeFx_help";
		case 'mc_SignFx':
			return "mc_SignFx_help";
		case 'mc_CameraRange':
			return "mc_CameraRange_help";
		case 'mc_AutoCameraCenter':
			return "mc_AutoCameraCenter_help";
		case 'mc_SoftLockCameraAssist':
			return "mc_SoftLockCameraAssist_help";
	}
	return "";
}

@addMethod( CR4IngameMenu ) function McHelpTextField() : CScriptedFlashObject
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

@addMethod( CR4IngameMenu ) function McShowHelp( text : string )
{
	var textField : CScriptedFlashObject;

	m_fxUpdateBardsBalladText.InvokeSelfOneArg( FlashArgString( text ) );
	textField = McHelpTextField();
	if ( textField )
	{
		if ( mcHelpTextHeight <= 0 )
		{
			mcHelpTextHeight = textField.GetMemberFlashNumber( "height" );
		}
		textField.SetMemberFlashNumber( "height", MaxF( mcHelpTextHeight, textField.GetMemberFlashNumber( "textHeight" ) + 8 ) );
	}
	m_flashModule.GetMemberFlashFunction( "showBardsBalladTooltip" ).InvokeSelfOneArg( FlashArgBool( true ) );
}

// The banner given back as the game has it: its own text, its height, hidden.
@addMethod( CR4IngameMenu ) function McHideHelp()
{
	var textField : CScriptedFlashObject;

	if ( mcHelpShown == '' )
	{
		return;
	}
	mcHelpShown = '';
	textField = McHelpTextField();
	if ( textField && mcHelpTextHeight > 0 )
	{
		textField.SetMemberFlashNumber( "height", mcHelpTextHeight );
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
		key = McHelpKey( optionName );
		if ( key != "" )
		{
			mcHelpShown = optionName;
			McShowHelp( GetLocStringByKey( key ) );
		}
		else
		{
			McHideHelp();
		}
	}
	else if ( optionName == mcHelpShown )
	{
		McHideHelp();
	}
	return result;
}

@wrapMethod( CR4IngameMenu ) function OnOptionPanelNavigateBack()
{
	McHideHelp();
	return wrappedMethod();
}

@wrapMethod( CR4IngameMenu ) function OnClosingMenu()
{
	McHideHelp();
	return wrappedMethod();
}


// ---------------------------------------------------------------------------------------------------------
// The camera, on Geralt and Ciri.

@addField( CR4Player ) var mc : MinimalistCamera;
@addField( CR4Player ) var mcLastUsedPCInput : bool;

@wrapMethod( W3PlayerWitcher ) function OnSpawned( spawnData : SEntitySpawnData )
{
	wrappedMethod( spawnData );
	mc = new MinimalistCamera in this;
	mc.Init();
}

@wrapMethod( W3ReplacerCiri ) function OnSpawned( spawnData : SEntitySpawnData )
{
	wrappedMethod( spawnData );
	mc = new MinimalistCamera in this;
	mc.Init();
}

// The camera tick taken over: on foot, outside the horse and aiming, the mod positions the camera and the game's own
// camera code, its exploration substates' included, does not run. In Witcher Senses the game's Senses camera with the
// mod's offsets. Exploration (indoors as outdoors), swimming and combat get the mod's camera; other states keep the
// camera where it is, as the mod always did.
@wrapMethod( CR4Player ) function OnGameCameraTick( out moveData : SCameraMovementData, dt : float )
{
	var targetRotation : EulerAngles;
	var forcedHeading : bool;
	var stateName : name;

	if ( !mc )
	{
		return wrappedMethod( moveData, dt );
	}

	moveData.pivotRotationController.maxPitch = 80.0;
	moveData.pivotRotationController.minPitch = -80.0;
	moveData.pivotPositionController.offsetZ = 1.5f;

	if( thePlayer.IsUsingHorse() || thePlayer.GetCurrentStateName() == 'Aiming' ) return false;

	if( substateManager.m_SharedDataO.IsForceHeading( targetRotation ) )
	{
		moveData.pivotRotationController.SetDesiredHeading( targetRotation.Yaw );
		moveData.pivotRotationController.SetDesiredPitch( targetRotation.Pitch );
		moveData.pivotRotationValue.Yaw		= LerpAngleF( 2.1f * dt, moveData.pivotRotationValue.Yaw, targetRotation.Yaw );
		moveData.pivotRotationValue.Pitch	= LerpAngleF( 1.0f * dt, moveData.pivotRotationValue.Pitch, targetRotation.Pitch );
		forcedHeading = true;
	}

	McCameraRotationOptions();

	if ( theGame.IsFocusModeActive() )
	{
		if( GetExplCamera() || IsModernExplorationCamera() )
		{
			return true;
		}

		theGame.GetGameCamera().ChangePivotRotationController( 'Exploration' );
		theGame.GetGameCamera().ChangePivotDistanceController( 'Default' );
		theGame.GetGameCamera().ChangePivotPositionController( 'Default' );

		moveData.pivotRotationController = theGame.GetGameCamera().GetActivePivotRotationController();
		moveData.pivotDistanceController = theGame.GetGameCamera().GetActivePivotDistanceController();
		moveData.pivotPositionController = theGame.GetGameCamera().GetActivePivotPositionController();

		moveData.pivotPositionController.SetDesiredPosition( thePlayer.GetWorldPosition() );
		moveData.pivotRotationController.SetDesiredPitch( -10.0f );
		moveData.pivotPositionController.offsetZ = 1.5f;
		DampVectorSpring( moveData.cameraLocalSpaceOffset, moveData.cameraLocalSpaceOffsetVel, Vector( mc.SenseOffset, mc.SenseZoom, mc.SenseHeight ), 0.5f, dt );
		moveData.pivotRotationController.maxPitch = 50.0;
		moveData.pivotDistanceController.SetDesiredDistance( 3.5f );
		return true;
	}

	stateName = GetCurrentStateName();
	if( stateName == 'Exploration' || stateName == 'Swimming' || thePlayer.IsInCombat() )
	{
		if ( thePlayer.IsInCombat() ) mc.SetCombatCam();
		else mc.SetExplorationCam();

		mc.SetDodgeCamIfNeeded();
		mc.SetSignsCamIfNeeded();

		moveData.pivotPositionController.SetDesiredPosition( thePlayer.GetWorldPosition(), mc.CurrResponsiveness );
		moveData.pivotDistanceController.SetDesiredDistance( 3.5f );
		DampVectorSpring( moveData.cameraLocalSpaceOffset, moveData.cameraLocalSpaceOffsetVel, Vector( mc.CurrOffset, mc.CurrZoom, mc.CurrHeight ), 0.5f, dt );

		if ( !forcedHeading )
		{
			McCenterCamera( moveData, dt );
		}
	}
	return true;
}

// The game's two camera rotation options, each for its own case. The engine turns the camera by itself (its
// auto-rotation) only after a camera tick the scripts leave to it, which this mod never does, so outside combat the
// game's centering is done here; in combat the game's assisted rotation toward the enemies (the combat state's camera)
// is taken only while auto-rotation is allowed, which the game ties to Automatic Camera Centering: here it follows the
// assist option alone, on a controller only, as the option says.
@addMethod( CR4Player ) function McCameraRotationOptions()
{
	var camera : CCustomCamera;

	camera = theGame.GetGameCamera();
	if ( !camera )
	{
		return;
	}
	if ( thePlayer.IsInCombat() )
	{
		camera.SetAllowAutoRotation( theInput.LastUsedGamepad() && GetSoftLockCameraAssist() );
	}
	// how long the player's own camera turn holds off the centering, as the game's exploration camera sets it
	if ( mcLastUsedPCInput != theInput.LastUsedPCInput() )
	{
		mcLastUsedPCInput = theInput.LastUsedPCInput();
		if ( mcLastUsedPCInput )
		{
			camera.SetManualRotationHorTimeout( 5 );
		}
		else
		{
			camera.SetManualRotationHorTimeout( 1.5 );
		}
	}
}

// Automatic Camera Centering, outside combat, on foot and swimming, on both devices: while Geralt moves and the
// player has not just turned the camera, the camera turns toward Geralt's heading; not while Geralt moves toward it.
@addMethod( CR4Player ) function McCenterCamera( out moveData : SCameraMovementData, dt : float )
{
	var camera : CCustomCamera;
	var heading : float;

	if ( thePlayer.IsInCombat() || !GetAutoCameraCenter() )
	{
		return;
	}
	camera = theGame.GetGameCamera();
	if ( !camera || camera.IsManualControledHor() )
	{
		return;
	}
	if ( VecLength( GetMovingAgentComponent().GetVelocity() ) < 0.5f )
	{
		return;
	}
	heading = GetHeading();
	if ( AbsF( AngleDistance( heading, moveData.pivotRotationValue.Yaw ) ) > 135.0f )
	{
		return;
	}
	heading = LerpAngleF( MinF( 1.0f, 1.0f * dt ), moveData.pivotRotationValue.Yaw, heading );
	moveData.pivotRotationController.SetDesiredHeading( heading );
	moveData.pivotRotationValue.Yaw = heading;
}

// The game's close exploration camera never engages and its combat camera is always on; the menu's modern
// exploration and dynamic combat cameras are not taken.
@wrapMethod( CR4Player ) function GetExplCamera() : bool
{
	wrappedMethod();
	return false;
}

@wrapMethod( CR4Player ) function GetCmbtCamera() : bool
{
	wrappedMethod();
	return true;
}

@wrapMethod( CR4Player ) function SetCombatCameraDistanceIdConfig( id : int )
{
	if ( id == 2 )
	{
		return;
	}
	wrappedMethod( id );
}

@wrapMethod( CR4Player ) function SetExplorationCameraIdConfig( id : int )
{
	if ( id == 2 )
	{
		return;
	}
	wrappedMethod( id );
}

// No camera shake while running and sprinting: the game's shake stopped as soon as it has started it.
@wrapMethod( CPlayer ) function EnableSprintingCamera( flag : bool )
{
	wrappedMethod( flag );
	if ( flag )
	{
		theGame.GetGameCamera().StopAnimation( 'camera_shake_loop_lvl1_1' );
	}
}

@wrapMethod( CPlayer ) function EnableRunCamera( flag : bool )
{
	wrappedMethod( flag );
	if ( flag )
	{
		theGame.GetGameCamera().StopAnimation( 'camera_shake_loop_lvl1_5' );
	}
}

// After aiming, the camera distance reset (a brief hard lock).
@wrapMethod( CR4PlayerStateAimThrow ) function OnLeaveState( nextStateName : name )
{
	if ( thePlayer.mc )
	{
		thePlayer.mc.ResetCameraDistance( true );
	}
	return wrappedMethod( nextStateName );
}
