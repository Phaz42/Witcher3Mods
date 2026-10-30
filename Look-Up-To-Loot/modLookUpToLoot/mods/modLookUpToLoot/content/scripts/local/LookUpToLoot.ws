// Look Up to Loot: a container out of reach above the player, such as a shelf high on a wall, gets its prompt when the
// player looks up at it. The game offers a container's prompt only up to a height above the player that the container's
// data sets, and the engine tests against its own copy of that limit, which a script cannot change; what the engine does
// follow is where the interaction sits. So while the camera looks up at such a container, its interaction is moved down,
// just under that limit, and put back when the camera looks away; the prompt is drawn where the container really is
// throughout. Never through a ceiling or a floor, and nothing higher than 2.5 m above the feet. Annotations only:
// nothing overridden, nothing to merge.

@addField( CR4Player ) var lutlComp : CInteractionComponent;		// the interaction moved down, or NULL
@addField( CR4Player ) var lutlLocal : Vector;				// its own local position
@addField( CR4Player ) var lutlDrop : float;				// how far it is moved down
@addField( CR4Player ) var lutlIconComp : CInteractionComponent;	// the prompt held where the container is, until the engine has the interaction back
@addField( CR4Player ) var lutlIconOffset : Vector;			// its own icon offset
@addField( CR4Player ) var lutlRealZ : float;				// its own height in the world

@wrapMethod( W3PlayerWitcher ) function OnSpawned( spawnData : SEntitySpawnData )
{
	wrappedMethod( spawnData );
	AddTimer( 'LutlTick', 0.25, true );
}

@wrapMethod( W3ReplacerCiri ) function OnSpawned( spawnData : SEntitySpawnData )
{
	wrappedMethod( spawnData );
	AddTimer( 'LutlTick', 0.25, true );
}

// Four times a second: while the camera looks up, the container looked at moved down; otherwise put back.
@addMethod( CR4Player ) timer function LutlTick( dt : float, id : int )
{
	var direction, me, moved : Vector;
	var ic : CInteractionComponent;
	var realZ, drop : float;

	LutlReleasePrompt( false );
	direction = theCamera.GetCameraDirection();
	if ( direction.Z <= -0.10 )		// looking up: above about 6 degrees below the horizon
	{
		LutlPutBack();
		return;
	}
	ic = LutlChoose( realZ );
	if ( !ic )
	{
		LutlPutBack();
		return;
	}
	if ( ic != lutlComp )
	{
		LutlPutBack();
		LutlReleasePrompt( true );		// before its offset is read: it may be this one's, still held
		lutlComp = ic;
		lutlLocal = ic.GetLocalPosition();
		lutlDrop = 0;
		lutlRealZ = realZ;
		lutlIconComp = ic;
		lutlIconOffset = ic.iconOffset;
	}
	// just under its limit, 20 cm to spare: moved no further than it needs
	me = GetWorldPosition();
	drop = ( realZ - me.Z ) - ( ic.height - 0.20 );
	if ( AbsF( drop - lutlDrop ) < 0.05 )
	{
		return;
	}
	lutlDrop = drop;
	moved = lutlLocal;
	moved.Z -= drop;
	ic.SetPosition( moved );
}

// The container the camera looks at most closely, within 30 degrees: its interaction enabled, a loot prompt, above its
// own height limit but at most 2.5 m above the feet, within its range across, and in sight. Its real height in realZ.
@addMethod( CR4Player ) function LutlChoose( out realZ : float ) : CInteractionComponent
{
	var entities : array< CGameplayEntity >;
	var comps : array< CComponent >;
	var ic, best : CInteractionComponent;
	var direction, camera, me, pos : Vector;
	var i, j : int;
	var above, aim, bestAim : float;

	FindGameplayEntitiesInRange( entities, this, 4, 200 );
	direction = VecNormalize( theCamera.GetCameraDirection() );
	camera = theCamera.GetCameraPosition();
	me = GetWorldPosition();
	bestAim = 0.866;		// cos 30 degrees
	for ( i = 0; i < entities.Size(); i += 1 )
	{
		comps.Clear();		// the call adds to the array rather than replacing it
		comps = entities[ i ].GetComponentsByClassName( 'CInteractionComponent' );
		for ( j = 0; j < comps.Size(); j += 1 )
		{
			ic = (CInteractionComponent)comps[ j ];
			if ( !ic || !ic.IsEnabled() || ic.GetActionName() != "Container" )
			{
				continue;
			}
			pos = ic.GetWorldPosition();
			if ( ic == lutlComp )
			{
				pos.Z = lutlRealZ;		// judged where it really is
			}
			above = pos.Z - me.Z;
			if ( above <= ic.height || above > 2.50 || VecDistance2D( pos, me ) > ic.rangeMax )
			{
				continue;
			}
			aim = VecDot( direction, VecNormalize( pos - camera ) );
			if ( aim <= bestAim )
			{
				continue;
			}
			if ( !LutlInSight( ic, pos ) )
			{
				continue;
			}
			bestAim = aim;
			best = ic;
			realZ = pos.Z;
		}
	}
	return best;
}

// In sight unless a ceiling or a floor is in between: a trace from the eyes that stops on a surface facing down, not
// the container's own. A wall needs no test of the mod's: the interaction moves straight down, so a wall between stays
// between, for the game's own line of sight test. (At a wall shelf the trace stops on the wall behind it, or on its own
// jar, 0.18 to 0.37 m short.)
function LutlInSight( ic : CInteractionComponent, target : Vector ) : bool
{
	var groups : array< name >;
	var eyes, hit, normal : Vector;
	var material : name;
	var comp : CComponent;

	eyes = thePlayer.GetWorldPosition();
	eyes.Z += 1.70;
	groups.PushBack( 'Terrain' );
	groups.PushBack( 'Static' );
	if ( !theGame.GetWorld().StaticTraceWithAdditionalInfo( eyes, target, hit, normal, material, comp, groups ) )
	{
		return true;
	}
	if ( comp && comp.GetEntity() == ic.GetEntity() )
	{
		return true;
	}
	return normal.Z >= -0.5;
}

@addMethod( CR4Player ) function LutlPutBack()
{
	if ( lutlComp )
	{
		lutlComp.SetPosition( lutlLocal );
	}
	lutlComp = NULL;
	lutlDrop = 0;
}

// The prompt's own offset given back once the engine has the interaction where it belongs, by both of its readings,
// or at once.
@addMethod( CR4Player ) function LutlReleasePrompt( now : bool )
{
	var pos, matrixPos : Vector;

	if ( !lutlIconComp || lutlIconComp == lutlComp )
	{
		return;
	}
	pos = lutlIconComp.GetWorldPosition();
	matrixPos = MatrixGetTranslation( lutlIconComp.GetLocalToWorld() );
	if ( now || ( AbsF( pos.Z - lutlRealZ ) < 0.01 && AbsF( matrixPos.Z - lutlRealZ ) < 0.01 ) )
	{
		lutlIconComp.iconOffset = lutlIconOffset;
		lutlIconComp = NULL;
	}
}

// The prompt drawn where the container really is, every frame. The HUD places it at the interaction, or at its icon
// offset from it when one is set, through the interaction's matrix; the engine takes a moved position a frame late, so
// the offset is worked out each frame from that same matrix, and never left at zero while held (with no offset the HUD
// reads the position another way). Assumes the interaction's own up is the world's.
@wrapMethod( CR4HudModuleInteractions ) function GetInteractionScreenPosition( interactionEntity : CEntity, interactionComponent : CInteractionComponent, out screenPos : Vector, optional normalized : bool ) : bool
{
	var player : CR4Player;
	var offset, now : Vector;

	player = (CR4Player)thePlayer;
	if ( player && interactionComponent && interactionComponent == player.lutlIconComp )
	{
		now = MatrixGetTranslation( interactionComponent.GetLocalToWorld() );
		offset = player.lutlIconOffset;
		offset.Z += player.lutlRealZ - now.Z;
		if ( offset.X == 0 && offset.Y == 0 && offset.Z == 0 )
		{
			offset.Z = 0.001;
		}
		interactionComponent.iconOffset = offset;
	}
	return wrappedMethod( interactionEntity, interactionComponent, screenPos, normalized );
}
