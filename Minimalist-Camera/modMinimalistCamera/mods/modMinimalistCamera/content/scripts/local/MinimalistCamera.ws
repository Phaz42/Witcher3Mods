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
	private var requiredInitVersion : int;
		default requiredInitVersion = 1;

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
		Log( "Init Start" );
		if ( GetIntConfigItem( 'mc_InitVersion' ) < requiredInitVersion ) SetDefaults();
		GetConfig();
		Log( "Init End" );
	}

    public function ReInit()
	{
        Log( "ReInit after closing Menu" );
        Init();
    }

	private function SetDefaults()
	{
		SetConfigItem( 'mc_InitVersion', requiredInitVersion );

		SetConfigItem( 'mc_Responsiveness', "4" );
		SetConfigItem( 'mc_DynamicZoom', "2" );
		SetConfigItem( 'mc_DodgeFx', "true" );
		SetConfigItem( 'mc_SignFx', "true" );
		SetConfigItem( 'mc_Zoom', "3" );
		SetConfigItem( 'mc_Height', "2" );
		SetConfigItem( 'mc_Offset', "3" );

		SetConfigItem( 'mc_CombatResponsiveness', "7" );
		SetConfigItem( 'mc_CombatZoom', "3" );
		SetConfigItem( 'mc_CombatHeight', "2" );
		SetConfigItem( 'mc_CombatOffset', "0" );

		SetConfigItem( 'mc_DodgeZoom', "3" );
		SetConfigItem( 'mc_DodgeHeight', "0" );
		SetConfigItem( 'mc_DodgeResponsiveness', "2" );
		SetConfigItem( 'mc_DodgeOffset', "0" );

		SetConfigItem( 'mc_SignsResponsiveness', "10" );
		SetConfigItem( 'mc_SignsZoom', "-3" );
		SetConfigItem( 'mc_SignsHeight', "3" );
		SetConfigItem( 'mc_SignsOffset', "-3" );

		SetConfigItem( 'mc_SenseZoom', "3" );
		SetConfigItem( 'mc_SenseHeight', "2" );
		SetConfigItem( 'mc_SenseOffset', "3" );

		SetConfigItem( 'mc_EnemyRange', "12" );
		SetConfigItem( 'mc_ZoomPerEnemy', "0.8" );
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

		//Log( "hostiles: " + hostilesInRange + ", enemies: " + enemiesInRange + ", visible enemies: " + visibleEnemiesInRange );

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
			Log( "ResetCameraDistance: Start Reset" );
			cameraDistanceResetInProgress = true;
			cameraDistanceResetProgressCounter = 0;
			thePlayer.HardLockToTarget( true );
		}
		else if ( !startReset && cameraDistanceResetInProgress && cameraDistanceResetProgressCounter > 1 )
		{
			// Stop Reset
			Log( "ResetCameraDistance: Stop Reset" );
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
		var configValue : string;

		config = theGame.GetInGameConfigWrapper();
		configValue = config.GetVarValue( modName, configItem );
		Log( "GetConfigItem: " + NameToString(configItem) + ": " + configValue );
		return configValue;
	}

	private function GetIntConfigItem( configItem : name ) : int
	{
		return StringToInt(GetConfigItem(configItem));
	}

	private function GetFloatConfigItem( configItem : name ) : float
	{
		return StringToFloat(GetConfigItem(configItem));
	}

	private function SetConfigItem( configItem : name, configValue : string )
	{
		config = theGame.GetInGameConfigWrapper();
		config.SetVarValue( modName, configItem, configValue );
		theGame.SaveUserSettings();
		Log( "SetConfigItem: Saved config item: " + NameToString(configItem) + ", to value: " + configValue );
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

	private function SaveConfig()
	{
		Log( "SaveConfig: Saving all configuration" );
	}

	private function GetIntVar( configItem : name, validStart : int, validEnd : int, out intVariable: int ) : bool
	{
		var configValue: int;

		configValue = GetIntConfigItem(configItem);
		if ( configValue >= validStart && configValue <= validEnd )
		{
			intVariable = configValue;
			return true;
		}
		else
		{
			Log( "GetIntVar: Config item: " + NameToString(configItem) + " not in valid range. Use default." );
			return false;
		}
	}
}