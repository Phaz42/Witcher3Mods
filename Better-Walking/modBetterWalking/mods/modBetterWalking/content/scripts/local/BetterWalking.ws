/***********************************************************************/
/**		BetterWalking.ws
/**		by Phaz42
/***********************************************************************/

class BetterWalking extends CEntity
{
	// Global System Vars
	private var initComplete : bool;
		default initComplete = false;
	private var modName : name;
		default modName = 'modBetterWalking';
	private var config: CInGameConfigWrapper;

	private var isSprintTimerRunning : bool;
		default isSprintTimerRunning = false;
	private var sprintHeld : bool;
		default sprintHeld = false;
	private var walkToggleHeld : bool;
		default walkToggleHeld = false;


	public function Init()
	{
		Log( "Init Start" );

		if ( GetConfigItem( 'bw_hold_to_run' ) != "true" )					SetConfigItem( 'bw_hold_to_run', false );
		if ( GetConfigItem( 'bw_hold_to_sprint' ) != "true" )				SetConfigItem( 'bw_hold_to_sprint', false );
		if ( GetConfigItem( 'bw_l3_to_sprint' ) != "false" )				SetConfigItem( 'bw_l3_to_sprint', true );
		if ( GetConfigItem( 'bw_double_tap_to_sprint' ) != "false" )		SetConfigItem( 'bw_double_tap_to_sprint', true );
		if ( GetConfigItem( 'bw_double_tap_to_sprint_combat' ) != "false" )	SetConfigItem( 'bw_double_tap_to_sprint_combat', true );
		initComplete = true;

		Log( "Init End" );
	}

	public function SprintPressed( action : SInputAction )
	{
		var currState : name;

		Log( "SprintPressed" );
		if ( !initComplete ) Init();
		if ( walkToggleHeld ) return;
		if ( HasLootInteraction() ) return;
		if ( IsPressed  ( action ) ) sprintHeld = true;
		if ( IsReleased ( action ) ) sprintHeld = false;

		// Walk/Run Toggle/Hold + double tap sprint for controller
		if( IsPressed( action ) && theInput.LastUsedGamepad() && IsInValidState() )
		{
			Log( "SprintPressed: IsPressed" );
			if ( GetConfigItem( 'bw_double_tap_to_sprint' ) == "true" )
			{
				if ( GetIsSprintTimerRunning() )
				{
					// Double tap sprint toggle
					Log( "SprintPressed: Double tap 2nd tap: Sprint toggle" );
					CancelSprintTimer();
					thePlayer.interiorTracker.LockRun( false );
					thePlayer.SetSprintToggle( !thePlayer.GetIsSprintToggled() );
					return;
				}
				else
				{
					Log( "SprintPressed: Double tap 1st tap: Start Timer" );
					StartSprintTimer();
					// Don't proceed after 1st tap while in combat
					if ( IsInCombatState() ) return;
				}
			}

			if ( GetConfigItem( 'bw_hold_to_run' ) == "true" )
			{
				Log( "SprintPressed: Hold to Run" );
				if ( thePlayer.interiorTracker.IsRunLocked() )
				{
					// Start Run hold from walk for controller
					Log( "SprintPressed: Start Hold, enabling Run from Walk" );
					thePlayer.interiorTracker.LockRun( false );
				}

				if ( thePlayer.GetIsSprintToggled() )
				{
					// Start Run Hold from Sprint for controller
					Log( "SprintPressed: Start Hold, enabling Run from Sprint" );
					thePlayer.SetSprintToggle( false );
				}
			}
			else
			{
				// Walk toggle for Controller
				Log( "SprintPressed: Toggling lock" );
				thePlayer.interiorTracker.LockRun( !thePlayer.interiorTracker.IsRunLocked() );
				Log( "SprintPressed: New state: " + thePlayer.interiorTracker.IsRunLocked() );
			}
		}

		// End Run/Sprint hold for controller
		if( IsReleased( action ) && theInput.LastUsedGamepad() && !thePlayer.interiorTracker.IsRunLocked() &&
			( GetConfigItem( 'bw_hold_to_run') == "true" || GetConfigItem( 'bw_hold_to_sprint') == "true" ) )
		{
			Log( "SprintPressed: IsReleased" );
			
			if ( thePlayer.GetIsSprintToggled() && GetConfigItem( 'bw_hold_to_sprint') == "false" )
			{
				Log( "SprintPressed: Ignore Release, currently sprinting and Hold To Sprint is disabled" );
				return;
			}

			if ( !thePlayer.GetIsSprintToggled() && GetConfigItem( 'bw_hold_to_run') == "false" )
			{
				Log( "SprintPressed: Ignore Release, currently running and Hold to Run is disabled" );
				return;
			}

			// End Run/Sprint hold for controller
			Log( "SprintPressed: End Hold, enabling Walk" );
			thePlayer.interiorTracker.LockRun( true );
			if ( IsInCombatState() ) thePlayer.SetSprintToggle( false );
		}

		// Sprint for Keyboard
		if( theInput.LastUsedPCInput() && IsInValidState() )
		{
			if ( GetConfigItem( 'bw_hold_to_sprint' ) == "true" )
			{
				Log( "SprintPressed: Hold to Sprint mode" );
				if ( IsPressed( action ) )
				{
					Log( "SprintPressed: Pressed: Enabling sprint" );
					thePlayer.interiorTracker.LockRun( false );
					thePlayer.SetSprintToggle( true );
				}
				if ( IsReleased( action ) )
				{
					Log( "SprintPressed: Released: Disabling sprint" );
					thePlayer.interiorTracker.LockRun( true );
					thePlayer.SetSprintToggle( false );
				}
			}
			else if ( IsPressed( action ) )
			{
				Log( "SprintPressed: Toggle Sprint mode" );
				thePlayer.interiorTracker.LockRun( false );
				thePlayer.SetSprintToggle( !thePlayer.GetIsSprintToggled() );
				Log( "SprintPressed: New state: " + thePlayer.GetIsSprintToggled() );
			}
		}
	}

	public function SprintTogglePressed( action : SInputAction )
	{
		if ( !initComplete ) Init();

		// L3 Sprint toggle for Controller
		Log( "SprintTogglePressed" );
		if ( GetConfigItem( 'bw_l3_to_sprint' ) != "false" )
		{	
			if( IsPressed( action ) && IsInValidState() )
			{
				Log( "SprintTogglePressed: Toggle Sprint" );
				thePlayer.interiorTracker.LockRun( false );
				thePlayer.SetSprintToggle( !thePlayer.GetIsSprintToggled() );
			}
		}
		else
		{
			Log( "SprintTogglePressed: Ignored, L3 disabled" );
		}
	}

	public function WalkTogglePressed( action : SInputAction )
	{
		if ( !initComplete ) Init();
		if ( sprintHeld ) return;
		if ( IsPressed  ( action ) ) walkToggleHeld = true;
		if ( IsReleased ( action ) ) walkToggleHeld = false;

		// Walk/Run button for Keyboard
		Log( "WalkTogglePressed" );
		thePlayer.SetWalkToggle( false );
		
		if ( IsInValidState() )
		{
			if ( GetConfigItem( 'bw_hold_to_run' ) == "true" )
			{
				Log( "WalkTogglePressed: Hold to Run mode" );
				if ( IsPressed( action ) )
				{
					Log( "WalkTogglePressed: Pressed: Disabling lock" );
					thePlayer.interiorTracker.LockRun( false );
				}
				if ( IsReleased( action ) )
				{
					Log( "WalkTogglePressed: Release: Enabling lock" );
					thePlayer.interiorTracker.LockRun( true );
				}
			}
			else
			{
				Log( "WalkTogglePressed: Toggle Run mode" );
				if( IsPressed( action ) && thePlayer.GetCurrentStateName() == 'Exploration' )
				{
					Log( "WalkTogglePressed: Toggling lock" );
					thePlayer.interiorTracker.LockRun( !thePlayer.interiorTracker.IsRunLocked() );
					Log( "WalkTogglePressed: New state: " + thePlayer.interiorTracker.IsRunLocked() );
				}
			}
		}
	}

	public function ResetOnIdle()
	{
		if ( !thePlayer.interiorTracker.IsRunLocked() )
		{
			Log( "ResetOnIdle: Locking now because of idle" );
			thePlayer.interiorTracker.LockRun( true );
		}
	}

	public function StartSprintTimer()
	{
		Log( "StartSprintTimer" );
		isSprintTimerRunning = true;
		thePlayer.AddTimer( 'BwEndSprintTimer', 0.2 );
	}

	public function EndSprintTimer()
	{
		Log( "EndSprintTimer" );
		isSprintTimerRunning = false;
		if ( IsInCombatState() ) DoCombatRoll();
	}

	public function CancelSprintTimer()
	{
		Log( "CancelSprintTimer" );
		thePlayer.RemoveTimer( 'BwEndSprintTimer' );
		isSprintTimerRunning = false;
	}

	public function GetIsSprintTimerRunning() : bool
	{
		return isSprintTimerRunning;
	}

	public function HasLootInteraction() : bool
	{
		var interactionTarget 	: CInteractionComponent;
		var isInteractionALoot 	: bool;

		Log( "HasLootInteraction" );
		interactionTarget = theGame.GetInteractionsManager().GetActiveInteraction();
		Log( "HasLootInteraction: Current interaction: " + interactionTarget.GetName() );
		isInteractionALoot = interactionTarget && ( interactionTarget.GetName() == "Loot" || interactionTarget.GetName() == "Container" || interactionTarget.GetName() == "Take" || interactionTarget.GetName() == "GatherHerbs" );

		Log( "HasLootInteraction: Return: " + isInteractionALoot );
		return isInteractionALoot;
	}

	public function Log( msg : string )
	{
		LogChannel( modName, msg );
	}

	public function GetConfigItem( configItem : name ) : string
	{
		var configValue : string;

		config = theGame.GetInGameConfigWrapper();
		configValue = config.GetVarValue( modName, configItem );
		Log( "GetConfigItem: configItem: " + NameToString( configItem ) + ", value: " + configValue );
		return configValue;
	}

	private function SetConfigItem( configItem : name, configValue : string )
	{
		config = theGame.GetInGameConfigWrapper();
		config.SetVarValue( modName, configItem, configValue );
		theGame.SaveUserSettings();
		Log( "SetConfigItem: Saved config item: " + NameToString(configItem) + ", to value: " + configValue );
	}

	public function IsInCombatState() : bool
	{
		var stateName : name;
		var result: bool;

		stateName = thePlayer.GetCurrentStateName();
		result = ( stateName == 'Combat' || stateName == 'CombatSteel' || stateName == 'CombatSilver' );
		Log( "IsInCombatState: Current state: " + NameToString( stateName ) + ", return: " + result );
		return result;	
	}

	public function IsInValidState() : bool
	{
		var stateName : name;
		var result: bool;

		stateName = thePlayer.GetCurrentStateName();
		result = ( stateName == 'Combat'      || stateName == 'CombatSteel' || stateName == 'CombatSilver' ||
				   stateName == 'Exploration' || stateName == 'Swimming'    || stateName == 'Diving' );
		Log( "IsInValidState: Current state: " + NameToString( stateName ) + ", return: " + result );
		return result;
	}

	public function IsAllowedToRoll() : bool
	{
		var result : bool;

		result = ( GetConfigItem( 'bw_double_tap_to_sprint_combat' ) == "false" ||
				( !GetIsSprintTimerRunning() && !thePlayer.GetIsSprintToggled() ) );
		Log( "IsAllowedToRoll: Return: " + result );
		return result;
	}

	public function DoCombatRoll()
	{
		Log( "DoCombatRoll" );
		if ( !thePlayer.IsInsideInteraction() ) thePlayer.EvadePressed(EBAT_Roll);
	}
}



