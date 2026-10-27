// Werewolf Regeneration Fix: on Hard and Death March, a werewolf's low-health special (its howl) adds the ability
// FullMoonOnSteroids, +60 health regeneration per second, and the game never takes it off again: each special adds
// one more, for good, and the save keeps them. The werewolf's AI tree (monster_werewolf_logic.w2behtree) was given
// this branch in the Remaster without the "not twice" setting its lower-difficulty twin has, and without a removal.
// This mod restores what that twin does: the ability at most once, removed when the game removes the lower-difficulty
// one (FullMoon), and a werewolf that comes out of a save with extra copies cut back to one. Annotations only:
// nothing overridden, nothing to merge.

// Never a second copy: added with "not twice", as the game adds FullMoon. Every other ability as the game asks.
@wrapMethod( CGameplayEntity ) function AddAbility( abilityName : name, optional allowMultiple : bool ) : bool
{
	var multiple : bool;

	multiple = allowMultiple && abilityName != 'FullMoonOnSteroids';
	return wrappedMethod( abilityName, multiple );
}

// Removed with FullMoon: the AI tree's one removal names only the lower-difficulty ability.
@wrapMethod( CGameplayEntity ) function RemoveAbility( abilityName : name )
{
	wrappedMethod( abilityName );
	if ( abilityName == 'FullMoon' && HasAbility( 'FullMoonOnSteroids' ) )
	{
		RemoveAbilityAll( 'FullMoonOnSteroids' );
	}
}

// A werewolf saved with extra copies, from a game played before this mod: cut back to one when it spawns, the saved
// state restored by then.
@wrapMethod( CNewNPC ) function OnSpawned( spawnData : SEntitySpawnData )
{
	var result : bool;

	result = wrappedMethod( spawnData );
	if ( HasAbility( 'FullMoonOnSteroids' ) )
	{
		WrfKeepOne( this );
	}
	return result;
}

function WrfKeepOne( npc : CNewNPC )
{
	var abilities : array< name >;
	var i, copies : int;

	npc.GetCharacterStats().GetAbilities( abilities, false );
	for ( i = 0; i < abilities.Size(); i += 1 )
	{
		if ( abilities[ i ] == 'FullMoonOnSteroids' )
		{
			copies += 1;
		}
	}
	if ( copies > 1 )
	{
		npc.RemoveAbilityMultiple( 'FullMoonOnSteroids', copies - 1 );
		LogChannel( 'WerewolfRegenerationFix', npc.GetReadableName() + ": " + copies + " copies of FullMoonOnSteroids, cut back to one" );
	}
}
