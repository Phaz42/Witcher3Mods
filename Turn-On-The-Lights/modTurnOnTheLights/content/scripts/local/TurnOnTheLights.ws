/***********************************************************************/
/** 	TurnOnTheLights.ws
/** 	by Phaz42
/***********************************************************************/

class TurnOnTheLights
{
	
	private var	manualMode : bool;
    private var maxRange : int;
    private var autoModeTarget : bool;
	private var	actionTimerRunning : bool;
		default	actionTimerRunning = false;
	private var	actionCount: int;
		default actionCount = 0;
    public var configWrapper: CInGameConfigWrapper;

    public function Init()
    {
        var tempRange : int;
        tempRange = -1;

        LogChannel( 'modTurnOnTheLights', "Init Start" );
        configWrapper = theGame.GetInGameConfigWrapper();
        LogConfig();

        if ( configWrapper.GetVarValue( 'modTurnOnTheLights', 'mode') == "0" )
        {
            LogChannel( 'modTurnOnTheLights', "Init: mode: manual" );
            manualMode = true;
        }
        else
        {
            LogChannel( 'modTurnOnTheLights', "Init: mode: auto" );
            manualMode = false;
            thePlayer.AddTimer('TurnOnTheLightsAutoTimer', 0.1 );
            configWrapper.SetVarValue( 'modTurnOnTheLights', 'mode', 1 );
        }

        if ( configWrapper.GetVarValue( 'modTurnOnTheLights', 'automodetarget' ) == "false" )
        {
            LogChannel( 'modTurnOnTheLights', "Init: automodetarget: false" );
            autoModeTarget = false;
        }
        else
        {
            LogChannel( 'modTurnOnTheLights', "Init: automodetarget: true" );
            autoModeTarget = true;
            configWrapper.SetVarValue( 'modTurnOnTheLights', 'automodetarget', true );
        }

        tempRange = StringToInt(configWrapper.GetVarValue( 'modTurnOnTheLights', 'range'));
        if ( tempRange >= 10 && tempRange <= 50 )
        {
            LogChannel( 'modTurnOnTheLights', "Init: range: defined" );
            maxRange = tempRange;
        }
        else
        {
            LogChannel( 'modTurnOnTheLights', "Init: range: undefined" );
            maxRange = 20;
            configWrapper.SetVarValue( 'modTurnOnTheLights', 'range', 20 );
        }

        theGame.SaveUserSettings();
        LogConfig();
        LogChannel( 'modTurnOnTheLights', "Init End" );
    }

    public function ReInit()
	{
        LogChannel( 'modTurnOnTheLights', "ReInit after closing Menu" );
        thePlayer.RemoveTimer('TurnOnTheLightsAutoTimer');
        Init();
    }

    private function LogConfig()
    {
        LogChannel( 'modTurnOnTheLights', "LogConfig: GetVarValue(mode): " + configWrapper.GetVarValue( 'modTurnOnTheLights', 'mode') );
        LogChannel( 'modTurnOnTheLights', "LogConfig: GetVarValue(automodetarget): " + configWrapper.GetVarValue( 'modTurnOnTheLights', 'automodetarget') );
        LogChannel( 'modTurnOnTheLights', "LogConfig: GetVarValue(range): " + configWrapper.GetVarValue( 'modTurnOnTheLights', 'range') );
    }
    
    public function GetEntities() : array<CGameplayEntity>
	{
		var entities	: array<CGameplayEntity>;
		var maxResults	: int;
		
		maxResults 	= 10000;

		LogChannel( 'modTurnOnTheLights', "GetEntities: maxRange: " + maxRange );
        FindGameplayEntitiesInRange( entities, thePlayer, (float)maxRange, maxResults );
        LogChannel( 'modTurnOnTheLights', "GetEntities: found " + IntToString(entities.Size()) + " entities" );

		return entities;
	}

	public function GetGameLightComps( entity : CGameplayEntity ) : CGameplayLightComponent
	{
		return (CGameplayLightComponent)entity.GetComponentByClassName('CGameplayLightComponent');
	}

    private function HudMsg ( msg : string )
    {
        LogChannel( 'modTurnOnTheLights', "HudMsg: " + msg );
        GetWitcherPlayer().DisplayHudMessage( msg );
    }

    private function ConsoleMsg ( msg : string )
    {
        LogChannel( 'modTurnOnTheLights', "ConsoleMsg: " + msg );
        ((CR4ScriptedHud)theGame.GetHud()).HudConsoleMsg( msg );
    }

    private function ShowNotification ( msg : string )
    {
        LogChannel( 'modTurnOnTheLights', "ShowNotification: " + msg );
        theGame.GetGuiManager().ShowNotification( msg );
    }
	
	public function ToggleMode()
	{
        if ( manualMode )
		{
			// goto auto
			LogChannel( 'modTurnOnTheLights', "ToggleMode: Auto" );
            ShowNotification( "Turn On The Lights: Automatic Mode" );
            manualMode = false;
            configWrapper.SetVarValue('modTurnOnTheLights', 'mode', 1);
            theGame.SaveUserSettings();
			thePlayer.AddTimer('TurnOnTheLightsAutoTimer', 0.1 );
		}
		else
		{
			// goto manual
			LogChannel( 'modTurnOnTheLights', "ToggleMode: Manual" );
            ShowNotification( "Turn On The Lights: Manual Mode" );
			thePlayer.RemoveTimer('TurnOnTheLightsAutoTimer');
			manualMode = true;
            configWrapper.SetVarValue('modTurnOnTheLights', 'mode', 0);
            theGame.SaveUserSettings();
		}
	}
	
	public function LightsSwitch( entities : array<CGameplayEntity>, switchOn : bool )
	{
		var i: int;
		var gameLightComp	: CGameplayLightComponent;

		LogChannel( 'modTurnOnTheLights', "LightsSwitch: " + switchOn );
		
		for ( i = 0; i < entities.Size(); i += 1 )
		{
			gameLightComp = GetGameLightComps( entities[i] );
			if ( gameLightComp && gameLightComp.IsInteractive() && ( gameLightComp.IsLightOn() != switchOn ) )
			{
				gameLightComp.SetLight(switchOn);
			}
		}
	}

	public function AutoTimer()
	{
		LogChannel( 'modTurnOnTheLights', 'TurnOnTheLightsAutoTimer' );
		LightsSwitch( GetEntities(), autoModeTarget );
		thePlayer.AddTimer('TurnOnTheLightsAutoTimer', 2.0);
	}

	public function StartActionTimer()
	{
		LogChannel( 'modTurnOnTheLights', 'StartActionTimer' );
		actionTimerRunning = true;
		actionCount = 1;
		thePlayer.AddTimer( 'TurnOnTheLightsActionTimer', 0.7, false );
	}
	
	public function StopActionTimer()
	{
		LogChannel( 'modTurnOnTheLights', 'StopActionTimer' );
		thePlayer.RemoveTimer( 'TurnOnTheLightsActionTimer' );
		actionCount = 0;
		actionTimerRunning = false;
	}
	
	public function IsActionTimerRunning() : bool
	{
		return actionTimerRunning;
	}

	public function ActionTimer()
	{
		var toggleLights : ToggleLights;

        LogChannel( 'modTurnOnTheLights', "TurnOnTheLightsActionTimer, actionCount: " + actionCount );
       
       if ( manualMode && actionCount == 2 )
		{ 
            toggleLights = new ToggleLights in theGame;
            toggleLights.Init();
		}

        if ( actionCount == 3 )
        {
            if( thePlayer.IsActionAllowed(EIAB_Signs) )
            {
                ToggleMode();
                StopActionTimer();
            }
            else
            {				
                thePlayer.DisplayActionDisallowedHudMessage(EIAB_Signs);
            }
        }

        if ( actionCount == 4 )
		{ 
            LogChannel( 'modTurnOnTheLights', "ActionTimer maxRange before: " + maxRange );
            switch( maxRange )
            {
                case 50 :
                {
                    LogChannel( 'modTurnOnTheLights', "ActionTimer case: 50" );
                    maxRange = 10;
                    configWrapper.SetVarValue( 'modTurnOnTheLights', 'range', 10 );
                    ShowNotification( "Turn On The Lights: Range 10m" );
                    break;
                }
                case 10 :
                {
                    LogChannel( 'modTurnOnTheLights', "ActionTimer case: 10" );
                    maxRange = 20;
                    configWrapper.SetVarValue( 'modTurnOnTheLights', 'range', 20 );
                    ShowNotification( "Turn On The Lights: Range 20m" );
                    break;
                }
                case 20 :
                {
                    LogChannel( 'modTurnOnTheLights', "ActionTimer case: 20" );
                    maxRange = 50;
                    configWrapper.SetVarValue( 'modTurnOnTheLights', 'range', 50 );
                    ShowNotification( "Turn On The Lights: Range 50m" );
                    break;
                }
                default :
                {
                    LogChannel( 'modTurnOnTheLights', "ActionTimer case: default" );
                    maxRange = 20;
                    configWrapper.SetVarValue( 'modTurnOnTheLights', 'range', 20 );
                    ShowNotification( "Turn On The Lights: Range 20m" );
                    break;
                }
                LogChannel( 'modTurnOnTheLights', "ActionTimer maxRange after: " + maxRange );
            }
            theGame.SaveUserSettings();
		}

		StopActionTimer();
	}

    public function ProcessInput()
    {
		LogChannel( 'modTurnOnTheLights', "ProcessInput: actionCount: " + actionCount );
        if ( IsActionTimerRunning() )
        {
            LogChannel( 'modTurnOnTheLights', "ProcessInput: actionCount++" );
            actionCount += 1;
            
        }
        else
        {
            StartActionTimer();
        }
    }
}

statemachine class ToggleLights
{
    function Init()
	{
		LogChannel( 'modTurnOnTheLights', 'ToggleLights Init' );
        this.PushState('Active');
	}
}

state Active in ToggleLights
{
    var entities		: array<CGameplayEntity>;
    var i				: int;
    var gameLightComp	: CGameplayLightComponent;
    var lightsOff		: bool;
    var turnOnTheLights : TurnOnTheLights;
    saved var restoreItemLAtEnd	: bool;

    event OnEnterState(prevStateName : name)
	{
		LogChannel( 'modTurnOnTheLights', 'ToggleLights EnterState' );
        turnOnTheLights = ((W3PlayerWitcher)thePlayer).turnOnTheLights;
        Toggle();
	}

    entry function Toggle()
    {
        LogChannel( 'modTurnOnTheLights', 'ToggleLights Toggle' );
    
        lightsOff	= false;
        entities	= turnOnTheLights.GetEntities();

        for ( i = 0; i < entities.Size(); i += 1 )
        {
            gameLightComp = turnOnTheLights.GetGameLightComps( entities[i] );
            if ( gameLightComp && gameLightComp.IsInteractive() && !gameLightComp.IsLightOn() )
            {
                lightsOff = true;
            }
        }

        if ( thePlayer.IsHoldingItemInLHand() )
        {
            thePlayer.OnUseSelectedItem( true );
            restoreItemLAtEnd = true;
        }

        if ( lightsOff )
        {
            LogChannel( 'modTurnOnTheLights', 'ToggleLights Toggle On' );
            thePlayer.PlayerStartAction( PEA_IgniLight );
            LogChannel( 'modTurnOnTheLights', 'ToggleLights Start Sleep' );
            Sleep( 0.9 );
            LogChannel( 'modTurnOnTheLights', 'ToggleLights Stop Sleep' );
            turnOnTheLights.LightsSwitch( entities, true );
        }
        else
        {
            LogChannel( 'modTurnOnTheLights', 'ToggleLights Toggle Off' );
            thePlayer.PlayerStartAction( PEA_AardLight );
            LogChannel( 'modTurnOnTheLights', 'ToggleLights Start Sleep' );
            Sleep( 0.9 );
            LogChannel( 'modTurnOnTheLights', 'ToggleLights Stop Sleep' );
            turnOnTheLights.LightsSwitch( entities, false );
        }

        if ( restoreItemLAtEnd )
        {
            thePlayer.OnUseSelectedItem( );
            restoreItemLAtEnd = false;
        }
    }
}