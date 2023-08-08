/***********************************************************************/
/**		GoldenHour.ws
/**		by Phaz42
/***********************************************************************/

class GoldenHour extends CEntity
{
	// Global System Vars
	private var initComplete : bool;
		default initComplete = false;
	private var modName : name;
		default modName = 'modGoldenHour';
	private var config: CInGameConfigWrapper;
	private var requiredInitVersion : int;
		default requiredInitVersion = 4;

	// Global Config Vars
	private var morningMultiplier, eveningMultiplier, dayMultiplier, nightMultiplier : EGhMultiplier;
	private var goldenHourWeatherType, dayWeatherType, nightWeatherType : EGhWeatherType;
	private var skelligeGoldenHourWeatherType, skelligeDayWeatherType, skelligeNightWeatherType : EGhSwwsWeatherType;
	private var startStopNotifications, enablePhotomodeInCutscenes : bool;
	private var endMeditation : int;

	private var modEnabled : bool;
	private var modWasEnabled : bool;
		default modWasEnabled = false;

	// Global Game logic Vars
	private var isGoldenHourActive : bool;
		default isGoldenHourActive = false;
	private var doReset : bool;
		default doReset = false;
	private var lastWeatherChange : float;
	private var ghMeditationRunning : bool;
		default ghMeditationRunning = false;
	private var ghMeditationStartHour, ghMeditationStartMinute : int;


	// Initialization
	private function Init( optional reInit : bool )
	{
		Log( "Init: Start" );
		if ( GetIntConfigItem( 'gh_InitVersion' ) < requiredInitVersion ) SetDefaults();
		GetConfig();
		if ( modEnabled && !modWasEnabled ) EnableMod(reInit);
		if ( !modEnabled && modWasEnabled )	DisableMod();
		initComplete = true;
		Log( "Init: End" );
	}

	public function ReInit()
	{
		Log( "ReInit: Start" );
		Init( true );
	}

	private function SetDefaults()
	{
		Log( "SetDefaults: Start" );
		SetConfigItem( 'gh_InitVersion',					requiredInitVersion );
		SetConfigItem( 'gh_mod_enabled',					"true" );
		SetConfigItem( 'gh_startstop_notifications',		"false" );
		SetConfigItem( 'gh_enable_photomode_cutscenes',		"true" );
		SetIntConfigItem( 'gh_end_meditation',				0 );

		SetConfigItem( 'gh_morning_multiplier',				IntToString( GH_Multiplier30 ) );
		SetConfigItem( 'gh_evening_multiplier',				IntToString( GH_Multiplier20 ) );
		SetConfigItem( 'gh_goldenhour_weather_type',		IntToString( GH_WeatherTypeClear ) );
		SetConfigItem( 'gh_swws_goldenhour_weather_type',	IntToString( GH_SwwsWeatherTypeUnchanged ) );

		SetConfigItem( 'gh_day_multiplier',					IntToString( GH_Multiplier07 ) );
		SetConfigItem( 'gh_day_weather_type',				IntToString( GH_WeatherTypeUnchanged ) );
		SetConfigItem( 'gh_swws_day_weather_type',			IntToString( GH_SwwsWeatherTypeUnchanged ) );

		SetConfigItem( 'gh_night_multiplier',				IntToString( GH_Multiplier05 ) );
		SetConfigItem( 'gh_night_weather_type',				IntToString( GH_WeatherTypeUnchanged ) );
		SetConfigItem( 'gh_swws_night_weather_type',		IntToString( GH_SwwsWeatherTypeUnchanged ) );
	}


	// Golden Hour Main
	public function GoldenHourUpdate()
	{
		var justStarted, justEnded : bool;
		var area : EAreaName;

		if (!initComplete) Init();

		Log( "GoldenHourUpdate: Started" );

		if ( doReset )
		{
			ResetTimeScale();
			return;
		}

		area = theGame.GetCommonMapManager().GetCurrentArea();
		if ( !IsInValidArea( area ) )
		{
			Log( "GoldenHourUpdate: Outside of valid area, mod not active" );
			return;
		}

		if ( GetIsGoldenHourInArea( area, justStarted, justEnded ) )
		{
			if ( startStopNotifications && justStarted ) ShowNotification( "It's Golden Hour!" );
			UpdateTimeScale( GetCurrentTimeMultiplier( true ) );
			UpdateWeatherForArea( area, true );
		}
		else
		{
			if ( theGame.envMgr.IsNight() ) Log ( "GoldenHourUpdate: It's night" ); else Log ( "GoldenHourUpdate: It's day" );
			if ( justEnded && startStopNotifications ) ShowNotification( "Golden Hour ended :(" );
			UpdateTimeScale( GetCurrentTimeMultiplier( false ) );
			if ( !UpdateWeatherForArea( area, false ) && justEnded ) ResetWeather( area, 4 );
		}

		//LogCameraInfo();
		thePlayer.AddTimer( 'GoldenHourTimer', 15.0 );
	}

	private function IsInValidArea( area : EAreaName ) : bool
	{
		switch ( area )
		{
			case AN_Kaer_Morhen:
			case AN_Prologue_Village:
			case AN_Velen:
			case AN_NMLandNovigrad:
			case AN_Skellige_ArdSkellig:
			case (EAreaName)AN_Dlc_Bob:
				return true;
			default:
				return false;
		}
	}

	private function GetGoldenHourArea( area : EAreaName ) : GoldenHourArea
	{
		var position : Vector;
		var X, Y : float;
		var ghArea : GoldenHourArea;

		// Location
		position = thePlayer.GetWorldPosition();
		X = position.X;
		Y = position.Y;
		if ( area == AN_NMLandNovigrad && Y < 516 )
			area = AN_Velen;

		Log( "GetGoldenHourArea: area: " + AreaTypeToName(area) + ", position X: " + X + " Y: " + Y );
		
		ghArea = new GoldenHourArea in this;
		ghArea.area = area;
		switch ( area )
		{
			case AN_Kaer_Morhen:
				ghArea.Init( 4, 30, 6, 30, 16, 30, 17, 0 );
				break;

			case AN_Prologue_Village:
				ghArea.Init( 4, 0, 5, 30, 18, 0, 20, 30 );
				break;

			case AN_Velen:
				ghArea.Init( 4, 30, 6, 0, 18, 30, 20, 0 );
				break;

			case AN_NMLandNovigrad:
				ghArea.Init( 4, 0, 5, 30, 19, 0, 20, 30 );
				break;

			case AN_Skellige_ArdSkellig:
				ghArea.Init( 5, 0, 6, 30, 17, 0, 19, 0 );
				break;

			case (EAreaName)AN_Dlc_Bob:
				ghArea.Init( 5, 0, 6, 0, 18, 30, 20, 0 );
				break;
		}

		return ghArea;
	}

	private function GetIsGoldenHourInArea( area : EAreaName, optional out justStarted : bool, optional out justEnded : bool ) : bool
	{
		var ghArea : GoldenHourArea;

		ghArea = GetGoldenHourArea( area );

		if	( IsMorning() && GetIsInGhTimeSpan( ghArea.morning ) ||
			  !IsMorning() && GetIsInGhTimeSpan( ghArea.evening ) )
		{
			// In Golden Hour window

			if (!isGoldenHourActive)
			{
				// Golden Hour Starting
				Log( "GetIsGoldenHourInArea: Golden Hour starting now" );
				isGoldenHourActive = true;
				justStarted = true;
				return true;
			}
			else
			{
				// Golden Hour continuing
				Log( "GetIsGoldenHourInArea: Golden Hour continuing" );
				justStarted = false;
				return true;
			}
		}
		else
		{
			// Outside Golden Hour window

			if (isGoldenHourActive)
			{
				// Golden Hour Ending
				Log( "GetIsGoldenHourInArea: Golden Hour ending now" );
				isGoldenHourActive = false;
				justEnded = true;
				return false;
			}
			else
			{
				Log( "GetIsGoldenHourInArea: It's not Golden Hour" );
				justEnded = false;
				return false;
			}
		}
	}

	private function GetCurrentTimeMultiplier( isGoldenHour : bool ) : float
	{
		if (isGoldenHour)
		{
			if ( IsMorning() ) return GetMultiplier( morningMultiplier );
			else return GetMultiplier( eveningMultiplier );
		}
		else if (theGame.envMgr.IsNight()) return GetMultiplier( nightMultiplier );
		else return GetMultiplier( dayMultiplier );
	}

	private function GetIsInGhTimeSpan(ts: GoldenHourTimeSpan) : bool
	{
		var currentHour, currentMinute : int;

		currentHour = GameTimeHours(theGame.GetGameTime());
		currentMinute = GameTimeMinutes(theGame.GetGameTime());

		Log("GetIsInGhTimeSpan: Current Time: " + currentHour + ":" + currentMinute);
		Log("GetIsInGhTimeSpan: Start Time: " + ts.startHour + ":" + ts.startMinute);
		Log("GetIsInGhTimeSpan: End Time: " + ts.endHour + ":" + ts.endMinute);

		return IsTimeWithinRange(ts.startHour, ts.startMinute, ts.endHour, ts.endMinute, currentHour, currentMinute);
	}

	// Photo Mode
	public function GetIsPhotoModeEnabledInCutscenes() : bool
	{
		if (!initComplete) Init();

		if ( !modEnabled )
		{
			Log( "GetIsPhotoModeEnabledInCutscenes: Mod is disabled, return false." );
			return false;
		}

		Log( "GetIsPhotoModeEnabledInCutscenes: " + enablePhotomodeInCutscenes );

		return enablePhotomodeInCutscenes;
	}

	public function ResetPhotoModeCam()
	{
		var prevCam : CCustomCamera;

		Log( "ResetPhotoModeCam: Start" );
		prevCam = theGame.GetWorld().GetCameraDirector().GetTopmostCamera();
		theGame.GetPhotomodeCamera().Activate();
		prevCam.Activate( 0.0f, false );
		Log( "ResetPhotoModeCam: End" );

		//ResetCollisionOffset();
		//SetCollisionOffset( Vector( 0.0f, 0.0f, 1.5f ) );
		//EnableScreenSpaceCorrection( enable : bool );
		//SetAllowAutoRotation( allow : bool );
		//GetActivePivotPositionController() : ICustomCameraPivotPositionController;
		//ICustomCameraPivotPositionController.Reset();
		//ICustomCameraPivotPositionController.SetDesiredPosition( position : Vector, optional mult : float );
		//ICustomCameraScriptedPivotPositionController.ControllerSetDesiredPosition( position : Vector, mult : float ); assign this controller first?
		//ICustomCameraScriptedPositionController.ControllerSetPosition( position : Vector );
		//ICustomCameraScriptedPositionController.ControllerGetPosition() : Vector;
		//customCameraControllers.ws
		//theGame.GetGameCamera().ChangePivotPositionController( 'Default' );
		//theGame.GetGameCamera().ChangePivotPositionController('NGE_Climb');
		//theGame.GetGameCamera().ChangePivotPositionController( 'Diving' );
		//ChangePivotPositionController( 'KeepRelativePositionController' );
		//CCameraDirector.GetCameraPosition() : Vector;
		//r4Game.GetPhotomodeCamera() : CCustomCamera;
		//CCustomCamera.Activate( optional blendTime : float, optional resetPosition : bool );
		//UpdateDebugInfo

		// import struct SCameraMovementData
		// {
		// 	import var pivotPositionController	: ICustomCameraPivotPositionController;
		// 	import var pivotRotationController	: ICustomCameraPivotRotationController;
		// 	import var pivotDistanceController	: ICustomCameraPivotDistanceController;
		// 	import var pivotPositionValue		: Vector;
		// 	import var pivotPositionVelocity	: Vector;
		// 	import var pivotRotationValue		: EulerAngles;
		// 	import var pivotRotationVelocity	: EulerAngles;
		// 	import var pivotDistanceValue		: float;
		// 	import var pivotDistanceVelocity	: float;
		// 	import var cameraLocalSpaceOffset	: Vector;
		// 	import var cameraLocalSpaceOffsetVel: Vector;
		// }

		//r4Player.OnGameCameraTick( out moveData : SCameraMovementData, dt : float )
	}

	private var camMoveData : SCameraMovementData;
	public function SetCameraMoveData( moveData : SCameraMovementData )
	{
		camMoveData = moveData;
	}

	public function LogCameraInfo( optional tag : string )
	{
		var playerPos, cameraPos : Vector;
		playerPos = thePlayer.GetWorldPosition();
		cameraPos = camMoveData.pivotPositionValue;
		if ( tag == "" ) tag = "base";
		Log( "LogCameraInfo: " + tag + " GetCurrentStateName: " + thePlayer.GetCurrentStateName() );
		Log( "LogCameraInfo: " + tag + " GetGameCamera controllerName: " + NameToString(theGame.GetGameCamera().GetActivePivotPositionController().controllerName) );
		Log( "LogCameraInfo: " + tag + " GetPhotomodeCamera controllerName: " + NameToString(theGame.GetPhotomodeCamera().GetActivePivotPositionController().controllerName) );
		Log( "LogCameraInfo: " + tag + " player position: X: " + playerPos.X + " Y: " + playerPos.Y + " Z: " + playerPos.Z );
		Log( "LogCameraInfo: " + tag + " camera position: X: " + cameraPos.X + " Y: " + cameraPos.Y + " Z: " + cameraPos.Z );
	}


	// Weather
	private function UpdateWeatherForArea( area : EAreaName, isGoldenHour : bool ) : bool
	{
		var targetWeatherName : name;

		Log ( "UpdateWeatherForArea: Start, isGoldenHour: " + isGoldenHour );

		// Check if weather change is enabled
		if	( ( isGoldenHour &&
				( ( area == AN_Skellige_ArdSkellig && goldenHourWeatherType == GH_WeatherTypeUnchanged && skelligeGoldenHourWeatherType == GH_SwwsWeatherTypeUnchanged) ||
				( area != AN_Skellige_ArdSkellig && goldenHourWeatherType == GH_WeatherTypeUnchanged ) ) ) ||
			( !isGoldenHour && theGame.envMgr.IsNight() &&
				( ( area == AN_Skellige_ArdSkellig && nightWeatherType == GH_WeatherTypeUnchanged && skelligeNightWeatherType == GH_SwwsWeatherTypeUnchanged) ||
				( area != AN_Skellige_ArdSkellig && nightWeatherType == GH_WeatherTypeUnchanged ) ) ) ||
			( !isGoldenHour && !theGame.envMgr.IsNight() &&
				( ( area == AN_Skellige_ArdSkellig && dayWeatherType == GH_WeatherTypeUnchanged && skelligeDayWeatherType == GH_SwwsWeatherTypeUnchanged) ||
				( area != AN_Skellige_ArdSkellig && dayWeatherType == GH_WeatherTypeUnchanged ) ) ) )
		{
			Log ( "UpdateWeatherForArea: Weather change disabled in options" );
			return false;
		}

		// Determine target weather
		if ( isGoldenHour )
		{
			if ( area == AN_Skellige_ArdSkellig && skelligeGoldenHourWeatherType != GH_SwwsWeatherTypeUnchanged )
				targetWeatherName = GetSwwsWeatherType( skelligeGoldenHourWeatherType );
			else
				targetWeatherName = GetWeatherType( goldenHourWeatherType );
		}
		else if ( theGame.envMgr.IsNight() )
		{
			if ( area == AN_Skellige_ArdSkellig && skelligeNightWeatherType != GH_SwwsWeatherTypeUnchanged )
				targetWeatherName = GetSwwsWeatherType( skelligeNightWeatherType );
			else
				targetWeatherName = GetWeatherType( nightWeatherType );
		}
		else
		{
			if ( area == AN_Skellige_ArdSkellig && skelligeDayWeatherType != GH_SwwsWeatherTypeUnchanged )
				targetWeatherName = GetSwwsWeatherType( skelligeDayWeatherType );
			else
				targetWeatherName = GetWeatherType( dayWeatherType );
		}

		// Replace unavailable weathers per region
		switch ( area )
		{
			case AN_Kaer_Morhen:
				switch ( targetWeatherName )
				{
					case 'WT_Mid_Clouds_Dark':		targetWeatherName = 'WT_Mid_Clouds'; break;
					case 'WT_Rain_Storm':			targetWeatherName = 'WT_Heavy_Clouds_Dark'; break;
					case 'WT_Snow':					targetWeatherName = 'WT_Blizzard'; break;
				}
				break;

			case AN_Prologue_Village:
				switch ( targetWeatherName )
				{
					case 'WT_Mid_Clouds_Dark':		targetWeatherName = 'WT_Mid_Clouds'; break;
					case 'WT_Heavy_Clouds_Dark':	targetWeatherName = 'WT_Light_Rain'; break;
					case 'WT_Snow':					targetWeatherName = 'WT_Rain_Storm'; break;
				}
				break;

			case AN_Velen:
			case AN_NMLandNovigrad:
				break;

			case AN_Skellige_ArdSkellig:
				switch ( targetWeatherName )
				{
					case 'WT_Light_Clouds': 		targetWeatherName = 'WT_Clear'; break;
					case 'WT_Snow':					targetWeatherName = 'WT_Blizzard'; break;
				}
				break;

			case (EAreaName)AN_Dlc_Bob:
				switch ( targetWeatherName )
				{
					case 'WT_Mid_Clouds_Dark':		targetWeatherName = 'WT_Mid_Clouds'; break;
					case 'WT_Heavy_Clouds':			targetWeatherName = 'WT_Mid_Clouds'; break;
					case 'WT_Heavy_Clouds_Dark':	targetWeatherName = 'WT_Rain_Storm'; break;
				}
				break;
		}

		if ( GetWeatherConditionName() != targetWeatherName )
		{
			if ( theGame.GetEngineTimeAsSeconds() - lastWeatherChange > 30 )
			{
				lastWeatherChange = theGame.GetEngineTimeAsSeconds();
				RequestWeatherChangeTo( targetWeatherName, 4, false );
				Log ( "UpdateWeatherForArea: Weather was changed to: " + NameToString( targetWeatherName ) );
			}
			else
				Log ( "UpdateWeatherForArea: Weather change not possible, last change was too recent." );
		}
		else
			Log ( "UpdateWeatherForArea: Weather change not needed. Current weather: " + NameToString( GetWeatherConditionName() ) );

		return true;
	}

	private function GetRandomWeatherForArea( area : EAreaName ) : name
	{
		var targetVanillaWeather : EGhWeatherType;
		var targetSwwsWeather : EGhSwwsWeatherType;

		if ( area == AN_Skellige_ArdSkellig && skelligeGoldenHourWeatherType != GH_SwwsWeatherTypeUnchanged )
		{
			targetSwwsWeather = RandRange( 5, 1 );
			if ( RandRange( 3, 1 ) == 1 ) targetSwwsWeather = 1; // Prefer Clear
			return GetSwwsWeatherType( targetSwwsWeather );
		}
		else
		{
			targetVanillaWeather = RandRange( 5, 1 );
			return GetWeatherType( targetVanillaWeather );
		}
	}

	private function ResetWeather( area : EAreaName, blendTime : int )
	{
		var targetWeatherName : name;

		targetWeatherName = GetRandomWeatherForArea( area );
		RequestWeatherChangeTo( targetWeatherName , blendTime, false );
		Log ( "ResetWeather: Weather was reset to: " + NameToString( targetWeatherName ) );
	}


	// Meditation
	private function IsMorningGhFirst( ghArea : GoldenHourArea ) : bool
	{
		var currentHour, currentMinute : int;
		var result, isMorningGhAfterCurrent, isEveningGhAfterCurrent : bool;

		Log( "ghMeditation: IsMorningGhFirst" );

		currentHour = GameTimeHours( theGame.GetGameTime() );
		currentMinute = GameTimeMinutes( theGame.GetGameTime() );

		isMorningGhAfterCurrent = IsTimeAfterOnCurrentDay(ghArea.morning.startHour, ghArea.morning.startMinute, currentHour, currentMinute);
		isEveningGhAfterCurrent = IsTimeAfterOnCurrentDay(ghArea.evening.startHour, ghArea.evening.startMinute, currentHour, currentMinute);

		if ( isMorningGhAfterCurrent ) result = true;
		else if (isEveningGhAfterCurrent) result = false;
		else result = true;

		Log( "ghMeditation: IsMorningGhFirst: result: " + result );
		return result;
	}

	public function UpdateMeditationTargetTimeIfNeeded( requestedTargetHour : int, out targetMinute : int ) : int
	{
		var area : EAreaName;
		var ghArea : GoldenHourArea;
		var isMorningGhDuringMeditation, isEveningGhDuringMeditation : bool;
		var wakeMorning, wakeEvening : bool;
		var currentHour, currentMinute : int;

		Log( "ghMeditation: UpdateMeditationTargetTimeIfNeeded Start" );

		ghMeditationRunning = false;
		targetMinute = 0;

		if ( !modEnabled )
			{
			Log( "ghMeditation: UpdateMeditationTargetTimeIfNeeded: Mod is disabled, no changed needed." );
			return requestedTargetHour;
		}

		if ( endMeditation == 3 )
		{
			Log( "ghMeditation: UpdateMeditationTargetTimeIfNeeded: End meditation is disabled in settings, no changed needed." );
			return requestedTargetHour;
		}

		currentHour = GameTimeHours( theGame.GetGameTime() );
		currentMinute = GameTimeMinutes( theGame.GetGameTime() );

		Log( "ghMeditation: UpdateMeditationTargetTimeIfNeeded: currentTime: " + currentHour + ":" + currentMinute );
		Log( "ghMeditation: UpdateMeditationTargetTimeIfNeeded: requestedTargetHour: " + requestedTargetHour );
		Log( "ghMeditation: UpdateMeditationTargetTimeIfNeeded: endMeditation: " + endMeditation );

		wakeMorning = false;
		wakeEvening = false;

		area = theGame.GetCommonMapManager().GetCurrentArea();
		ghArea = GetGoldenHourArea( area );

		isMorningGhDuringMeditation = IsTimeWithinRange(currentHour, currentMinute, requestedTargetHour, targetMinute, ghArea.morning.startHour, ghArea.morning.startMinute);
		isEveningGhDuringMeditation = IsTimeWithinRange(currentHour, currentMinute, requestedTargetHour, targetMinute, ghArea.evening.startHour, ghArea.evening.startMinute);
		Log( "ghMeditation: UpdateMeditationTargetTimeIfNeeded: isMorningGhDuringMeditation: " + isMorningGhDuringMeditation );
		Log( "ghMeditation: UpdateMeditationTargetTimeIfNeeded: isEveningGhDuringMeditation: " + isEveningGhDuringMeditation );

		if ( IsMorningGhFirst( ghArea ) )
		{
			// Morning is next
			Log( "ghMeditation: UpdateMeditationTargetTimeIfNeeded: Morning is next." );

			if ( isMorningGhDuringMeditation && endMeditation != 1 )
			{
				wakeMorning = true;
			}
			else if ( isMorningGhDuringMeditation && isEveningGhDuringMeditation && endMeditation != 0)
			{
				wakeEvening = true;
			}
		}
		else
		{
			// Evening is next
			Log( "ghMeditation: UpdateMeditationTargetTimeIfNeeded: Evening is next." );

			if ( isEveningGhDuringMeditation && endMeditation != 0 )
			{
				wakeEvening = true;
			}
			else if ( isEveningGhDuringMeditation && isMorningGhDuringMeditation && endMeditation != 1 )
			{
				wakeMorning = true;
			}
		}

		if (wakeMorning)
		{
			ghMeditationRunning = true;
			ghMeditationStartHour = ghArea.morning.startHour;
			ghMeditationStartMinute = ghArea.morning.startMinute;
			Log( "ghMeditation: UpdateMeditationTargetTimeIfNeeded: Wake Morning: " + ghMeditationStartHour + ":" + ghMeditationStartMinute );
			targetMinute = ghArea.morning.startMinute;
			return ghArea.morning.startHour;
		}

		if (wakeEvening)
		{
			ghMeditationRunning = true;
			ghMeditationStartHour = ghArea.evening.startHour;
			ghMeditationStartMinute = ghArea.evening.startMinute;
			Log( "ghMeditation: UpdateMeditationTargetTimeIfNeeded: Wake Evening: " + ghMeditationStartHour + ":" + ghMeditationStartMinute );
			targetMinute = ghArea.evening.startMinute;
			return ghArea.evening.startHour;
		}

		Log( "ghMeditation: UpdateMeditationTargetTimeIfNeeded: Update Meditation target time not needed, using defaults" );
		targetMinute = 0;
		return requestedTargetHour;
	}

	public function ShouldStopMeditation() : bool
	{
		var currentHour, currentMinute : int;
		var result : bool;

		result = false;
		currentHour = GameTimeHours( theGame.GetGameTime() );
		currentMinute = GameTimeMinutes( theGame.GetGameTime() );

		if ( ghMeditationRunning && currentHour == ghMeditationStartHour && currentMinute == ghMeditationStartMinute )
		{
			ghMeditationRunning = false;
			result = true;
		}

		Log( "ghMeditation: ShouldStopMeditation: Result: " + result );
		return result;
	}


	// Time Scale
	private function ResetTimeScale()
	{
		Log( "ResetTimeScale: Trying to reset timescale");
		if ( UpdateTimeScale( 1.0f ) )
		{
			doReset = false;
			Log( "ResetTimeScale: Timescale was reset");
		}
		else
		{
			Log( "ResetTimeScale: Timescale reset failed, trying again soon");
			doReset = true;
			thePlayer.AddTimer( 'GoldenHourTimer', 10.0 );
		}
	}

	private function UpdateTimeScale( timeMultiplier : float ) : bool
	{
		var baseHoursPerMinute, currentHoursPerMinute, targetHoursPerMinute : float;

		if( thePlayer.GetCurrentStateName() == 'Meditation' || thePlayer.GetCurrentStateName() == 'MeditationWaiting' )
		{
			Log( "UpdateTimeScale: Unable to change timescale, player is medidating");
			return false;
		}

		baseHoursPerMinute = 0.25f;		
		currentHoursPerMinute = theGame.GetHoursPerMinute();
		targetHoursPerMinute = baseHoursPerMinute / timeMultiplier;
		Log( "UpdateTimeScale: currentHoursPerMinute: " + currentHoursPerMinute );
		Log( "UpdateTimeScale: targetHoursPerMinute: " + targetHoursPerMinute );
		if ( currentHoursPerMinute != (float)targetHoursPerMinute )
		{
			theGame.SetHoursPerMinute( targetHoursPerMinute );
			Log( "UpdateTimeScale: Set timescale to " + targetHoursPerMinute + " hours per minute");
		}
		else
		{
			Log( "UpdateTimeScale: No timescale change needed");
		}

		return true;
	}


	// Time Utility Functions
	private function IsTimeAfterOnCurrentDay( checkHour, checkMinute, baseHour, baseMinute: int ) : bool
	{
		return (checkHour > baseHour) || (checkHour == baseHour && checkMinute > baseMinute);
	}

	private function IsTimeBeforeOnCurrentDay(checkHour, checkMinute, baseHour, baseMinute: int) : bool
	{
		return (checkHour < baseHour) || (checkHour == baseHour && checkMinute < baseMinute);
	}

	private function IsTimeWithinRange(startHour, startMinute, endHour, endMinute, checkHour, checkMinute: int) : bool
	{
		var startMinutes, endMinutes, checkMinutes : int;
		// Convert the hours and minutes to minutes from midnight
		startMinutes = startHour * 60 + startMinute;
		endMinutes = endHour * 60 + endMinute;
		checkMinutes = checkHour * 60 + checkMinute;

		// If start time is less than or equal to end time, it is within the same day
		if (startMinutes <= endMinutes)
		{
			// Check time is within range if it's greater or equal to the start time and less than or equal to the end time
			return checkMinutes >= startMinutes && checkMinutes <= endMinutes;
		}
		else
		{
			// For spans across two days, the check time is within range if it's greater or equal to start time OR less than or equal to the end time
			return checkMinutes >= startMinutes || checkMinutes <= endMinutes;
		}
	}

	private function IsMorning() : bool
	{
		var currentHour, currentMinute : int;
		var isMorning : bool;

		currentHour = GameTimeHours( theGame.GetGameTime() );
		currentMinute = GameTimeMinutes( theGame.GetGameTime() );
		isMorning = currentHour < 12;

		if (isMorning)
			Log( "GetIsMorning: It's morning. Current time: " + currentHour + ":" + currentMinute );
		else
			Log( "GetIsMorning: It's evening. Current time: " + currentHour + ":" + currentMinute );

		return isMorning;
	}

	private function AddTime( startHour : int, startMinute : int, addHours : int, addMinutes : int, out endHour : int, out endMinute : int )
	{
		endHour = startHour + addHours + ( (startMinute + addMinutes) / 60 );
		endMinute = (startMinute + addMinutes) % 60;
	}


	// General Utility Functions & Menu handling

	private function Log( msg : string )
	{
		LogChannel( modName, msg );
	}

	private function HudMsg ( msg : string )
	{
		Log( "HudMsg: " + msg );
		GetWitcherPlayer().DisplayHudMessage( msg );
	}

	private function ConsoleMsg ( msg : string )
	{
		Log( "ConsoleMsg: " + msg );
		((CR4ScriptedHud)theGame.GetHud()).HudConsoleMsg( msg );
	}

	private function ShowNotification ( msg : string )
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
		Log("PHAZ1 " + StringToInt(GetConfigItem(configItem)));
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

	private function SetIntConfigItem( configItem : name, configValue : int )
	{
		SetConfigItem( configItem, (int)configValue );
	}

	private function GetConfig()
	{
		var tempMultiplier : int;
		modEnabled 					= (bool)GetConfigItem( 'gh_mod_enabled' );
		startStopNotifications		= (bool)GetConfigItem( 'gh_startstop_notifications' );
		enablePhotomodeInCutscenes	= (bool)GetConfigItem( 'gh_enable_photomode_cutscenes' );
		endMeditation				= GetIntConfigItem( 'gh_end_meditation' );
		Log("UpdateMeditationTargetTimeIfNeeded endMeditation getconfig: " + endMeditation);

		if ( GetIntVar( 'gh_morning_multiplier'				, 0, 11, tempMultiplier ) ) morningMultiplier				= tempMultiplier;
		if ( GetIntVar( 'gh_evening_multiplier'				, 0, 11, tempMultiplier ) ) eveningMultiplier				= tempMultiplier;
		if ( GetIntVar( 'gh_goldenhour_weather_type'		, 0, 8,  tempMultiplier ) ) goldenHourWeatherType			= tempMultiplier;
		if ( GetIntVar( 'gh_swws_goldenhour_weather_type'	, 0, 15, tempMultiplier ) ) skelligeGoldenHourWeatherType	= tempMultiplier;

		if ( GetIntVar( 'gh_day_multiplier'					, 0, 11, tempMultiplier ) ) dayMultiplier					= tempMultiplier;
		if ( GetIntVar( 'gh_day_weather_type'				, 0, 8,  tempMultiplier ) ) dayWeatherType					= tempMultiplier;
		if ( GetIntVar( 'gh_swws_day_weather_type'			, 0, 15, tempMultiplier ) ) skelligeDayWeatherType			= tempMultiplier;

		if ( GetIntVar( 'gh_night_multiplier'				, 0, 11, tempMultiplier ) ) nightMultiplier					= tempMultiplier;
		if ( GetIntVar( 'gh_night_weather_type'				, 0, 8,  tempMultiplier ) ) nightWeatherType				= tempMultiplier;
		if ( GetIntVar( 'gh_swws_night_weather_type'		, 0, 15, tempMultiplier ) ) skelligeNightWeatherType		= tempMultiplier;

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

	private function DisableMod()
	{
		Log( "DisableMod" );
		thePlayer.RemoveTimer( 'GoldenHourTimer' );
		ResetWeather( theGame.GetCommonMapManager().GetCurrentArea(), 1 );
		ResetTimeScale();
		modWasEnabled = false;
		ShowNotification( "Golden Hour mod Disabled" );
		Log( "DisableMod: Mod now disabled, default settings restored" );
	}

	private function EnableMod( reInit : bool )
	{
		Log( "EnableMod" );
		thePlayer.AddTimer( 'GoldenHourTimer', 1.0 );
		modWasEnabled = true;
		if (reInit) ShowNotification( "Golden Hour mod Enabled" );
		Log( "EnableMod: Mod now enabled" );
	}
}