/***********************************************************************/
/**		AhcWhistleFollow.ws
/**		by Phaz42
/***********************************************************************/

// Option "Horse Whistling toggles following until mounted": the first whistle summons Roach as always and then has
// her follow Geralt at a respectable distance; the next whistle stops it (a "Prrrrrr." instead of the whistle), and
// mounting, combat or a horse lost stop it too. Annotations only - no game script is replaced.
//
// How it works, and why (measured in game):
// - Vanilla's follow action (CAIFollowAction, which an NPC rider's horse uses) is put on her with ForceAIBehavior.
//   Its speed is read once, when it starts: a speed change is a new action, and every new action brakes her almost to
//   a standstill first (at a gallop: front feet planted, a whinny). So her speed is changed as rarely as possible.
// - Her speed is an absolute speed (MT_AbsSpeed), chosen by Geralt's pace, measured from his position (the reported
//   speed spikes): walking - his speed plus a pull on the gap, at most 4 m/s (her trot); running and sprinting -
//   1.2 x his speed, 1.6 x to catch up. Faster at once; slower only once she is slow anyway; a catch-up only while she
//   is slow (corners); from standing only after 1.5 s of moving, when a run has its speed.
// - At gallop speeds (8 m/s and up) she follows at 7.5 m instead of 5: her braking takes about 2.5 m.
// - Standing still for 8 s, she is stopped (vanilla's horse_do_nothing) the next time she is within 2 m - she may
//   otherwise walk figure eights forever - until Geralt moves 1.5 m.
// - Stuck (not moving while behind): a new path; stuck again or far and slow, out of sight: respawned near him the
//   way a far whistle does; over 40 m: respawned at once.
// - The state lives on the player's input handler, which is saved with the game; it is reset when a game loads, so
//   a load never resumes a half-finished follow.
//
// Console (for testing): ahcfollowlog(true) adds a readout every half second to scriptslog.txt (channel AhcFollow).

// --------------------------------------------------------------------------------------------------------------------
// State

@addField( CPlayerInput )
var ahcFollowing : bool;

// the forced action's id - the follow, or the do-nothing while parked
@addField( CPlayerInput )
var ahcFollowId : int;

@addField( CPlayerInput )
var ahcFollowHorse : CNewNPC;

@addField( CPlayerInput )
var ahcWhistleTime : float;

@addField( CPlayerInput )
var ahcSpawnPending : bool;

// a respawn is under way: the start on the new horse continues the follow
@addField( CPlayerInput )
var ahcResuming : bool;

@addField( CPlayerInput )
var ahcRespawnTime : float;

@addField( CPlayerInput )
var ahcAbsApplied : float;

@addField( CPlayerInput )
var ahcLastForce : float;

@addField( CPlayerInput )
var ahcSampleTime : float;

@addField( CPlayerInput )
var ahcSamplePos : Vector;

@addField( CPlayerInput )
var ahcStuckTime : float;

@addField( CPlayerInput )
var ahcRepaths : int;

@addField( CPlayerInput )
var ahcParked : bool;

@addField( CPlayerInput )
var ahcStillTime : float;

@addField( CPlayerInput )
var ahcStillSampleTime : float;

@addField( CPlayerInput )
var ahcStillPos : Vector;

@addField( CPlayerInput )
var ahcParkPos : Vector;

// half-second measurements: Geralt's speed (last, and averaged over about a second), hers
@addField( CPlayerInput )
var ahcMeasureTime : float;

@addField( CPlayerInput )
var ahcMeasurePlayerPos : Vector;

@addField( CPlayerInput )
var ahcMeasureHorsePos : Vector;

@addField( CPlayerInput )
var ahcGLast : float;

@addField( CPlayerInput )
var ahcGSmooth : float;

@addField( CPlayerInput )
var ahcHMeasured : float;

// Geralt's pace the applied speed was chosen for: 0 still, 1 walk, 2 run, 3 sprint
@addField( CPlayerInput )
var ahcPace : int;

// when he started moving from standing (0 = standing)
@addField( CPlayerInput )
var ahcMoveStart : float;

// since when she has been far and slow (0 = not)
@addField( CPlayerInput )
var ahcSlowFarSince : float;

@addField( CPlayerInput )
var ahcFollowStart : float;

@addField( CPlayerInput )
var ahcFollowReadout : bool;

// --------------------------------------------------------------------------------------------------------------------
// Constants

function AhcFollowDistance() : float { return 5.f; }
function AhcFollowGallopDistance() : float { return 7.5f; }

// "Prrrrrr." - Geralt's line from the slow-down voiceset (geralt_vset.w2scene), the one that fits a "stay"
function AhcFollowStopLine() : int { return 1047203; }

// --------------------------------------------------------------------------------------------------------------------
// Helpers

function AhcFollowF( value : float ) : string
{
	return FloatToStringPrec( value, 2 );
}

function AhcFollowWriteLog( msg : string )
{
	var input : CPlayerInput;
	input = thePlayer.GetInputHandler();
	LogChannel( 'AhcFollow', "t" + AhcFollowF( theGame.GetEngineTimeAsSeconds() - input.ahcFollowStart ) + " " + msg );
}

function AhcFollowPaceName( pace : int ) : string
{
	switch( pace )
	{
		case 0: return "still";
		case 1: return "walk";
		case 2: return "run";
		case 3: return "sprint";
		default: return "?";
	}
}

// Geralt's pace from a measured speed, with margins around the current one so it does not flicker:
// walk ~1.85 m/s, run ~5.0, sprint ~6.8 measured.
function AhcFollowPaceOf( g : float, current : int ) : int
{
	var pace : int;
	if( g < 0.5f ) { pace = 0; }
	else if( g < 3.5f ) { pace = 1; }
	else if( g < 6.f ) { pace = 2; }
	else { pace = 3; }
	if( pace == current - 1 )
	{
		if( current == 1 && g > 0.3f ) { return current; }
		if( current == 2 && g > 3.f ) { return current; }
		if( current == 3 && g > 5.5f ) { return current; }
	}
	if( pace == current + 1 )
	{
		if( current == 0 && g < 0.8f ) { return current; }
	}
	return pace;
}

// Her speed for a pace. Walking: his speed plus 0.5 m/s for every metre behind, at most her trot (a pull on a big gap
// galloped her in and past him). Running and sprinting: 1.2 x his speed.
function AhcFollowPaceSpeed( pace : int, g : float, d : float ) : float
{
	if( pace >= 2 )
	{
		return ClampF( 1.2f * g, 1.f, 12.f );
	}
	return ClampF( g + 0.5f * ( d - AhcFollowDistance() ), 1.f, 4.f );
}

function AhcFollowForce( input : CPlayerInput, action : IAIActionTree ) : int
{
	return input.ahcFollowHorse.ForceAIBehavior( action, BTAP_Emergency );
}

// Puts a new follow action on her, replacing the forced action there.
function AhcFollowApply( input : CPlayerInput, speed : float, why : string )
{
	var horse : CNewNPC;
	var action : CAIFollowAction;

	horse = input.ahcFollowHorse;
	if( !horse )
	{
		return;
	}
	if( input.ahcFollowing )
	{
		horse.CancelAIBehavior( input.ahcFollowId );
	}

	action = new CAIFollowAction in horse;
	action.OnCreated();
	action.params.targetTag = 'PLAYER';
	action.params.moveType = MT_AbsSpeed;
	action.params.moveSpeed = speed;
	if( speed >= 8.f )
	{
		action.params.followDistance = AhcFollowGallopDistance();
	}
	else
	{
		action.params.followDistance = AhcFollowDistance();
	}
	action.params.keepDistance = true;
	action.params.teleportToCatchup = false;
	action.params.rotateToWhenAtTarget = true;
	// as vanilla does for a follow action built at runtime for a horse (btRider.ws, CBTTaskRiderSetFollowActionOnHorseDef)
	action.OnManualRuntimeCreation();

	input.ahcFollowId = AhcFollowForce( input, action );
	input.ahcFollowing = true;
	input.ahcParked = false;
	input.ahcAbsApplied = speed;
	input.ahcLastForce = theGame.GetEngineTimeAsSeconds();
	AhcFollowWriteLog( why + ": " + AhcFollowF( speed ) + " m/s" );
}

function AhcFollowPark( input : CPlayerInput, d : float )
{
	var action : CAIHorseDoNothingAction;

	input.ahcFollowHorse.CancelAIBehavior( input.ahcFollowId );
	action = new CAIHorseDoNothingAction in input.ahcFollowHorse;
	action.OnCreated();
	action.OnManualRuntimeCreation();
	input.ahcFollowId = AhcFollowForce( input, action );
	input.ahcParked = true;
	input.ahcParkPos = thePlayer.GetWorldPosition();
	AhcFollowWriteLog( "parked, d " + AhcFollowF( d ) );
}

// --------------------------------------------------------------------------------------------------------------------
// Start, stop, respawn

// origin: whistle, whistle far (a respawned horse), respawn (continues the follow)
function AhcFollowStart( horse : CNewNPC, origin : string )
{
	var input : CPlayerInput;
	var d, now : float;
	var resumed : bool;

	input = thePlayer.GetInputHandler();
	if( !horse )
	{
		return;
	}
	AhcFollowStop( false, "restart" );
	now = theGame.GetEngineTimeAsSeconds();
	resumed = input.ahcResuming;
	input.ahcResuming = false;
	if( !resumed )
	{
		input.ahcFollowStart = now;
		LogChannel( 'AhcFollow', "==== AHC whistle follow START (" + origin + ") ====" );
	}

	input.ahcFollowHorse = horse;
	input.ahcSampleTime = now;
	input.ahcSamplePos = horse.GetWorldPosition();
	input.ahcStuckTime = 0.f;
	input.ahcRepaths = 0;
	input.ahcStillTime = 0.f;
	input.ahcStillSampleTime = now;
	input.ahcStillPos = thePlayer.GetWorldPosition();
	input.ahcMeasureTime = now;
	input.ahcMeasurePlayerPos = thePlayer.GetWorldPosition();
	input.ahcMeasureHorsePos = horse.GetWorldPosition();
	input.ahcHMeasured = 0.f;
	input.ahcMoveStart = 0.f;
	input.ahcSlowFarSince = 0.f;
	d = VecDistance( thePlayer.GetWorldPosition(), horse.GetWorldPosition() );
	if( resumed )
	{
		// a respawn: straight to the speed for his current pace
		input.ahcPace = AhcFollowPaceOf( input.ahcGLast, 0 );
		AhcFollowApply( input, AhcFollowPaceSpeed( input.ahcPace, input.ahcGLast, d ), "respawned, " + AhcFollowPaceName( input.ahcPace ) + ", d " + AhcFollowF( d ) );
		return;
	}
	input.ahcGLast = 0.f;
	input.ahcGSmooth = 0.f;
	input.ahcPace = 0;
	AhcFollowApply( input, AhcFollowPaceSpeed( 0, 0.f, d ), "start, d " + AhcFollowF( d ) );
}

// reason: whistle, mount, combat, horse gone, option off - or restart (no end)
function AhcFollowStop( voice : bool, reason : string )
{
	var input : CPlayerInput;

	input = thePlayer.GetInputHandler();
	if( !input.ahcFollowing )
	{
		return;
	}
	if( input.ahcFollowHorse )
	{
		input.ahcFollowHorse.CancelAIBehavior( input.ahcFollowId );
	}
	input.ahcFollowing = false;
	input.ahcParked = false;
	input.ahcFollowHorse = NULL;
	if( voice )
	{
		thePlayer.PlayLine( AhcFollowStopLine(), true );
	}
	if( reason != "restart" )
	{
		LogChannel( 'AhcFollow', "==== AHC whistle follow END: " + reason + ", after "
			+ AhcFollowF( theGame.GetEngineTimeAsSeconds() - input.ahcFollowStart ) + " s ====" );
	}
}

// Respawns her near Geralt the way a far whistle does (r4Game.ws OnSpawnPlayerHorse); the follow resumes on the
// new horse in OnPlayerHorseSummoned.
function AhcFollowRespawn( why : string )
{
	var input : CPlayerInput;
	var helper : CR4CreateEntityHelper;

	input = thePlayer.GetInputHandler();
	if( input.ahcFollowHorse && input.ahcFollowing )
	{
		input.ahcFollowHorse.CancelAIBehavior( input.ahcFollowId );
	}
	input.ahcFollowing = false;
	input.ahcParked = false;
	input.ahcFollowHorse = NULL;
	input.ahcSpawnPending = true;
	input.ahcResuming = true;
	input.ahcRespawnTime = theGame.GetEngineTimeAsSeconds();

	helper = new CR4CreateEntityHelper in theGame;
	helper.SetPostAttachedCallback( theGame, 'OnPlayerHorseSummoned' );
	theGame.SummonPlayerHorse( true, helper );
	AhcFollowWriteLog( "respawn (" + why + ")" );
}

// --------------------------------------------------------------------------------------------------------------------
// Every frame while following

function AhcFollowTick()
{
	var input : CPlayerInput;
	var horse : CNewNPC;
	var now, d, span, measured, speed : float;
	var pace : int;

	input = thePlayer.GetInputHandler();
	if( !input || !input.ahcFollowing )
	{
		return;
	}
	horse = input.ahcFollowHorse;
	if( !horse || !horse.IsAlive() )
	{
		AhcFollowStop( false, "horse gone" );
		return;
	}
	if( !AhcOption( 'ahc_WhistleFollow' ) )
	{
		AhcFollowStop( false, "option off" );
		return;
	}

	now = theGame.GetEngineTimeAsSeconds();
	d = VecDistance( thePlayer.GetWorldPosition(), horse.GetWorldPosition() );

	// half-second measurements from positions (the speed the game reports for Geralt spikes; hers is the requested one)
	span = now - input.ahcMeasureTime;
	if( span >= 0.5f )
	{
		measured = VecDistance2D( thePlayer.GetWorldPosition(), input.ahcMeasurePlayerPos ) / span;
		input.ahcGLast = measured;
		input.ahcGSmooth = 0.5f * input.ahcGSmooth + 0.5f * measured;
		input.ahcHMeasured = VecDistance2D( horse.GetWorldPosition(), input.ahcMeasureHorsePos ) / span;
		input.ahcMeasureTime = now;
		input.ahcMeasurePlayerPos = thePlayer.GetWorldPosition();
		input.ahcMeasureHorsePos = horse.GetWorldPosition();
		if( input.ahcFollowReadout )
		{
			AhcFollowWriteLog( "G " + AhcFollowF( measured ) + " H " + AhcFollowF( input.ahcHMeasured ) + " d " + AhcFollowF( d )
				+ " " + AhcFollowF( input.ahcAbsApplied ) + " " + AhcFollowPaceName( input.ahcPace ) );
		}
	}

	// parked: until Geralt moves away from where he stood
	if( input.ahcParked )
	{
		if( VecDistance( thePlayer.GetWorldPosition(), input.ahcParkPos ) > 1.5f )
		{
			input.ahcStillTime = 0.f;
			input.ahcStillSampleTime = now;
			input.ahcStillPos = thePlayer.GetWorldPosition();
			input.ahcSampleTime = now;
			input.ahcSamplePos = horse.GetWorldPosition();
			input.ahcStuckTime = 0.f;
			input.ahcPace = AhcFollowPaceOf( input.ahcGLast, 0 );
			AhcFollowApply( input, AhcFollowPaceSpeed( input.ahcPace, input.ahcGLast, d ), "unparked" );
		}
		return;
	}

	// Geralt standing still for 8 s: park her the next time she is within 2 m
	if( now - input.ahcStillSampleTime >= 1.f )
	{
		if( VecDistance( thePlayer.GetWorldPosition(), input.ahcStillPos ) < 0.3f )
		{
			input.ahcStillTime += now - input.ahcStillSampleTime;
		}
		else
		{
			input.ahcStillTime = 0.f;
		}
		input.ahcStillSampleTime = now;
		input.ahcStillPos = thePlayer.GetWorldPosition();
	}
	if( input.ahcStillTime >= 8.f && d < 2.f )
	{
		AhcFollowPark( input, d );
		return;
	}

	// far: respawned at once over 40 m - not within 3 s of a respawn, when the new horse first reports the old position
	if( d > 40.f && now - input.ahcRespawnTime >= 3.f )
	{
		AhcFollowRespawn( "far, d " + AhcFollowF( d ) );
		return;
	}
	// far and slow - crawling behind an obstacle: over 25 m, under 2.5 m/s for 3 s, out of sight
	if( d > 25.f && input.ahcHMeasured < 2.5f && now - input.ahcRespawnTime >= 3.f && !thePlayer.WasVisibleInScaledFrame( horse, 1.5f, 1.5f ) )
	{
		if( input.ahcSlowFarSince <= 0.f )
		{
			input.ahcSlowFarSince = now;
		}
		else if( now - input.ahcSlowFarSince >= 3.f )
		{
			input.ahcSlowFarSince = 0.f;
			AhcFollowRespawn( "far and slow, d " + AhcFollowF( d ) );
			return;
		}
	}
	else
	{
		input.ahcSlowFarSince = 0.f;
	}

	// stuck: behind and not moving for 2 s - a new path; stuck again and out of sight - respawned
	if( now - input.ahcSampleTime >= 1.f )
	{
		measured = VecDistance( horse.GetWorldPosition(), input.ahcSamplePos );
		if( d > AhcFollowDistance() + 3.f && measured < 0.5f )
		{
			input.ahcStuckTime += now - input.ahcSampleTime;
		}
		else
		{
			input.ahcStuckTime = 0.f;
			if( measured >= 0.5f )
			{
				input.ahcRepaths = 0;
			}
		}
		input.ahcSampleTime = now;
		input.ahcSamplePos = horse.GetWorldPosition();
	}
	if( input.ahcStuckTime >= 2.f )
	{
		input.ahcStuckTime = 0.f;
		if( input.ahcRepaths >= 1 && !thePlayer.WasVisibleInScaledFrame( horse, 1.5f, 1.5f ) )
		{
			AhcFollowRespawn( "stuck, d " + AhcFollowF( d ) );
			return;
		}
		input.ahcRepaths += 1;
		AhcFollowApply( input, AhcFollowPaceSpeed( input.ahcPace, input.ahcGSmooth, d ), "stuck, new path, d " + AhcFollowF( d ) );
		return;
	}

	// her speed by his pace - at most one change a second
	if( now - input.ahcLastForce < 1.f )
	{
		return;
	}
	if( input.ahcGLast < 0.5f )
	{
		input.ahcMoveStart = 0.f;
	}
	else if( input.ahcMoveStart <= 0.f )
	{
		input.ahcMoveStart = now;
	}
	// up: on his latest speed, at once - from standing only after 1.5 s of moving
	pace = AhcFollowPaceOf( input.ahcGLast, input.ahcPace );
	if( pace > input.ahcPace )
	{
		if( input.ahcPace == 0 && now - input.ahcMoveStart < 1.5f )
		{
			return;
		}
		input.ahcPace = pace;
		AhcFollowApply( input, AhcFollowPaceSpeed( pace, input.ahcGLast, d ), "pace up " + AhcFollowPaceName( pace ) );
		return;
	}
	// down: only when his latest and averaged speeds both say so, and only once she is slow anyway
	pace = Max( AhcFollowPaceOf( input.ahcGLast, input.ahcPace ), AhcFollowPaceOf( input.ahcGSmooth, input.ahcPace ) );
	if( pace < input.ahcPace )
	{
		if( input.ahcHMeasured < 2.f )
		{
			input.ahcPace = pace;
			if( pace > 0 )
			{
				AhcFollowApply( input, AhcFollowPaceSpeed( pace, input.ahcGSmooth, d ), "pace down " + AhcFollowPaceName( pace ) );
			}
		}
		return;
	}
	// same pace: not within 3 s of a change - she needs that to get going
	if( input.ahcPace == 0 || now - input.ahcLastForce < 3.f )
	{
		return;
	}
	if( input.ahcPace == 1 )
	{
		speed = AhcFollowPaceSpeed( 1, input.ahcGSmooth, d );
		if( AbsF( speed - input.ahcAbsApplied ) > 1.f )
		{
			AhcFollowApply( input, speed, "adjust walk" );
		}
		return;
	}
	// running or sprinting, only while she is slow anyway: catch up when far, back to 1.2 x when close
	if( input.ahcHMeasured >= 2.f )
	{
		return;
	}
	if( d > 12.f )
	{
		speed = ClampF( 1.6f * input.ahcGSmooth, 1.f, 12.f );
	}
	else if( d < 8.f )
	{
		speed = AhcFollowPaceSpeed( input.ahcPace, input.ahcGSmooth, d );
	}
	else
	{
		return;
	}
	if( AbsF( speed - input.ahcAbsApplied ) > 1.f )
	{
		AhcFollowApply( input, speed, "adjust " + AhcFollowPaceName( input.ahcPace ) + ", d " + AhcFollowF( d ) );
	}
}

// --------------------------------------------------------------------------------------------------------------------
// Hooks

// The whistle. While she follows, a whistle stops it instead - no summon, no whistle animation, a "Prrrrrr.".
// Otherwise vanilla runs as always, and the follow starts from OnSpawnPlayerHorse below - which also covers the
// whistle that first puts away a torch or another left-hand item (vanilla calls OnSpawnPlayerHorse later then).
// An event: its wrapper takes no explicit return type (always bool), as the compiler requires.
@wrapMethod( CPlayerInput ) function OnCommSpawnHorse( action : SInputAction )
{
	var secondTap : bool;

	if( IsReleased( action ) && AhcOption( 'ahc_WhistleFollow' ) )
	{
		secondTap = pressTimestamp + DOUBLE_TAP_WINDOW >= theGame.GetEngineTimeAsSeconds();
		if( secondTap || theInput.LastUsedPCInput() )
		{
			if( ahcFollowing )
			{
				pressTimestamp = theGame.GetEngineTimeAsSeconds();
				AhcFollowStop( true, "whistle" );
				return true;
			}
			ahcWhistleTime = theGame.GetEngineTimeAsSeconds();
		}
	}
	return wrappedMethod( action );
}

@wrapMethod( CR4Game ) function OnSpawnPlayerHorse()
{
	var input : CPlayerInput;
	var horse : CNewNPC;
	var whistled, respawn : bool;

	input = thePlayer.GetInputHandler();
	whistled = input.ahcWhistleTime > 0.f && GetEngineTimeAsSeconds() - input.ahcWhistleTime < 10.f && AhcOption( 'ahc_WhistleFollow' );
	input.ahcWhistleTime = 0.f;
	horse = thePlayer.GetHorseWithInventory();

	// vanilla's own test (r4Game.ws OnSpawnPlayerHorse) for "spawn a new horse near the player"
	respawn = !horse || !horse.IsAlive()
		|| ( !thePlayer.WasVisibleInScaledFrame( horse, 1.5f, 1.5f ) && VecDistanceSquared( thePlayer.GetWorldPosition(), horse.GetWorldPosition() ) > 900 )
		|| VecDistanceSquared( thePlayer.GetWorldPosition(), horse.GetWorldPosition() ) > 1600;

	if( whistled && respawn )
	{
		input.ahcSpawnPending = true;
	}

	wrappedMethod();

	if( whistled && !respawn )
	{
		AhcFollowStart( horse, "whistle" );
	}
}

// A respawned horse exists only once this callback runs.
@wrapMethod( CR4Game ) function OnPlayerHorseSummoned( horseEntity : CEntity )
{
	var input : CPlayerInput;

	wrappedMethod( horseEntity );
	input = thePlayer.GetInputHandler();
	if( input.ahcSpawnPending )
	{
		input.ahcSpawnPending = false;
		if( input.ahcResuming )
		{
			AhcFollowStart( (CNewNPC)horseEntity, "respawn" );
		}
		else
		{
			AhcFollowStart( (CNewNPC)horseEntity, "whistle far" );
		}
	}
}

@wrapMethod( W3HorseComponent ) function OnMountStarted( entity : CEntity, vehicleSlot : EVehicleSlot )
{
	if( entity == thePlayer )
	{
		AhcFollowStop( false, "mount" );
	}
	wrappedMethod( entity, vehicleSlot );
}

@wrapMethod( W3PlayerWitcher ) function OnCombatStart()
{
	AhcFollowStop( false, "combat" );
	wrappedMethod();
}

// Every frame (CPlayer's PlayerTick timer); the player states that define this event call it on their parent.
@wrapMethod( W3PlayerWitcher ) function OnPlayerTickTimer( deltaTime : float )
{
	wrappedMethod( deltaTime );
	AhcFollowTick();
}

// The input handler is a saved var (player.ws): a loaded game brings these fields back. Reset them, so a load never
// resumes a follow - the horse it named is gone anyway.
@wrapMethod( CPlayerInput ) function Initialize( isFromLoad : bool, optional previousInput : CPlayerInput )
{
	wrappedMethod( isFromLoad, previousInput );
	ahcFollowing = false;
	ahcFollowHorse = NULL;
	ahcWhistleTime = 0.f;
	ahcSpawnPending = false;
	ahcResuming = false;
	ahcRespawnTime = 0.f;
	ahcParked = false;
	ahcPace = 0;
	ahcMoveStart = 0.f;
	ahcSlowFarSince = 0.f;
	ahcFollowReadout = false;
}

exec function ahcfollowlog( on : bool )
{
	var input : CPlayerInput;
	input = thePlayer.GetInputHandler();
	input.ahcFollowReadout = on;
}
