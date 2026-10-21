// Geralt Level Scales - Difficulty Add-on
//
// Extra difficulty for Geralt Level Scales (GLS), which scales Geralt's gear and level stats to the level of the
// encounter: the add-on lowers that level by the level penalty set in the menu, never below level 1.
//
// Where level 1 cuts the gap short (low-level encounters), the full penalty option makes up the cut-off part
// as damage: for each such fight, GLS's own functions measure Geralt at the encounter's level and at the lowest
// encounter level where the whole gap fits, and Geralt's damage dealt and taken are scaled so the fight feels
// as the gap feels there. Only what GLS's levels scale: weapons by their damage, signs and their burning by sign
// intensity, the damage Geralt takes by Geralt's health and armor; bombs and other damage over time are untouched.
//
// Also starts health regeneration after GLS removes its scaling, so health returns to its maximum; and shows a help
// note in the options menu while one of the add-on's options is selected.
//
// All are wrappers of GLS's own functions or of the game's; GLS must be installed.
// The 5.x compiler allows one wrappedMethod call per wrapper, and reads a struct's field only from a variable.

// ---------------------------------------------------------------------------------------------------------
// Settings

// The level penalty as a number of levels, 0 to 30; the menu shows it negative, -30 to 0. An out-of-range value is
// reset to 0 and saved.
function GlsDifficultyAddonPenaltyLevels() : int
{
	var config : CInGameConfigWrapper;
	var penalty : int;

	config = theGame.GetInGameConfigWrapper();
	penalty = StringToInt( config.GetVarValue( 'modGLSDifficultyAddon', 'glsLevelPenalty' ) );
	if ( penalty < -30 || penalty > 0 )
	{
		penalty = 0;
		config.SetVarValue( 'modGLSDifficultyAddon', 'glsLevelPenalty', "0" );
		theGame.SaveUserSettings();
	}
	return -penalty;
}

// Full penalty against low-level enemies; on unless set off.
function GlsDifficultyAddonFullPenalty() : bool
{
	return theGame.GetInGameConfigWrapper().GetVarValue( 'modGLSDifficultyAddon', 'glsFullPenalty' ) != "false";
}

// The defaults, written when the options menu opens, so the menu shows them before a save is loaded.
function GlsDifficultyAddonSetDefaults()
{
	var config : CInGameConfigWrapper;
	var penalty, full : string;
	var changed : bool;

	config = theGame.GetInGameConfigWrapper();
	penalty = config.GetVarValue( 'modGLSDifficultyAddon', 'glsLevelPenalty' );
	if ( penalty == "" || StringToInt( penalty ) < -30 || StringToInt( penalty ) > 0 )
	{
		config.SetVarValue( 'modGLSDifficultyAddon', 'glsLevelPenalty', "0" );
		changed = true;
	}
	full = config.GetVarValue( 'modGLSDifficultyAddon', 'glsFullPenalty' );
	if ( full != "true" && full != "false" )
	{
		config.SetVarValue( 'modGLSDifficultyAddon', 'glsFullPenalty', "true" );
		changed = true;
	}
	if ( changed )
	{
		theGame.SaveUserSettings();
	}
}

@wrapMethod( CR4IngameMenu ) function OnConfigUI()
{
	GlsDifficultyAddonSetDefaults();
	wrappedMethod();
}

// ---------------------------------------------------------------------------------------------------------
// The help notes: while one of the add-on's options is selected, its help in the game's notification popup, which
// stays until it is replaced (-1) and is cleared with an empty message (0), the way sharedutils' menu descriptions
// use it. The game names only the option when the selection changes, so the options' ids are the add-on's own.

// The option whose note is shown, or none.
@addField( CR4IngameMenu )
var glsdaHelpShown : name;

// The help's string key for an option of the add-on's, or "" for any other.
function GlsDifficultyAddonHelpKey( option : name ) : string
{
	if ( option == 'glsLevelPenalty' )
	{
		return "gls_level_penalty_help";
	}
	if ( option == 'glsFullPenalty' )
	{
		return "gls_full_penalty_help";
	}
	return "";
}

@addMethod( CR4IngameMenu ) function GlsDifficultyAddonHideHelp()
{
	if ( glsdaHelpShown != '' )
	{
		glsdaHelpShown = '';
		theGame.GetGuiManager().ShowNotification( "", 0 );
	}
}

// Selecting an option of the add-on's shows its note; selecting any other, or leaving the one shown, hides it.
@wrapMethod( CR4IngameMenu ) function OnOptionSelectionChanged( optionName : name, value : bool )
{
	var result : bool;
	var key : string;

	result = wrappedMethod( optionName, value );
	if ( value )
	{
		key = GlsDifficultyAddonHelpKey( optionName );
		if ( key != "" )
		{
			glsdaHelpShown = optionName;
			theGame.GetGuiManager().ShowNotification( GetLocStringByKey( key ), -1 );
		}
		else
		{
			GlsDifficultyAddonHideHelp();
		}
	}
	else if ( optionName == glsdaHelpShown )
	{
		GlsDifficultyAddonHideHelp();
	}
	return result;
}

// Leaving the add-on's page, or the menu, hides the note.
@wrapMethod( CR4IngameMenu ) function OnOptionPanelNavigateBack()
{
	GlsDifficultyAddonHideHelp();
	return wrappedMethod();
}

@wrapMethod( CR4IngameMenu ) function OnClosingMenu()
{
	GlsDifficultyAddonHideHelp();
	return wrappedMethod();
}

// ---------------------------------------------------------------------------------------------------------
// The level gap

// What a fight needs from the full penalty option, kept on Geralt for the fight.
@addField( W3PlayerWitcher )
public var glsdaPendingEncounter : int;
@addField( W3PlayerWitcher )
public var glsdaPendingBoundary : int;
@addField( W3PlayerWitcher )
public var glsdaActive : bool;
@addField( W3PlayerWitcher )
public var glsdaSteel : float;
@addField( W3PlayerWitcher )
public var glsdaSilver : float;
@addField( W3PlayerWitcher )
public var glsdaCrossbow : float;
@addField( W3PlayerWitcher )
public var glsdaSign : float;
@addField( W3PlayerWitcher )
public var glsdaHealth : float;
@addField( W3PlayerWitcher )
public var glsdaArmorEncounter : float;
@addField( W3PlayerWitcher )
public var glsdaArmorBoundary : float;

// The encounter level GLS scales Geralt's gear to, lowered by the level penalty, never below 1. Only where GLS scales
// to the enemies' displayed level: not in a fistfight, and in New Game+ only when GLS buffs Geralt for it; the same
// conditions GLS itself checks. Where level 1 cuts the gap short, the fight's measurement is requested here and
// made when GLS scales Geralt (below).
@wrapMethod
function ModGeraltLevelScalesGetEncounterLevel() : int
{
	var level, levels, lowered : int;
	var w : W3PlayerWitcher;
	var applies : bool;

	level = wrappedMethod();
	lowered = level;
	w = GetWitcherPlayer();

	applies = false;
	if ( w )
	{
		w.glsdaPendingEncounter = 0;
		if ( level != -1 && !w.IsInFistFightMiniGame() )
		{
			applies = true;
		}
	}
	if ( applies && FactsQuerySum( "NewGamePlus" ) > 0 && !ModGeraltLevelScalesShouldBuffNGP() )
	{
		applies = false;
	}
	if ( applies )
	{
		// A new scaling is about to start: the previous fight's factors end here too.
		w.glsdaActive = false;
		levels = GlsDifficultyAddonPenaltyLevels();
		lowered = Max( 1, level - levels );
		LogChannel( 'modGLSDifficultyAddon', "Encounter level " + level + ", level penalty -" + levels + ", scaled to " + lowered );
		if ( levels > level - 1 && GlsDifficultyAddonFullPenalty() )
		{
			w.glsdaPendingEncounter = level;
			w.glsdaPendingBoundary = levels + 1;
		}
	}
	return lowered;
}

// Removing GLS's scaling abilities changes Geralt's maximum health, which the game follows by rescaling the
// current health, and that can leave it a fraction below the maximum. Health regeneration only runs once
// something starts it, so without a hit it stays there, and the HUD keeps the medallion and the stat bars shown.
@wrapMethod
function ModGeraltLevelScalesRemoveGeraltScalingAbilities()
{
	wrappedMethod();
	( (CActor)GetWitcherPlayer() ).StartVitalityRegen();
}

// ---------------------------------------------------------------------------------------------------------
// Full penalty against low-level enemies

// GLS's own cleanup of its scaling of Geralt and the gear, so Geralt and the items are as before.
function GlsDifficultyAddonUnscale( w : W3PlayerWitcher )
{
	ModGeraltLevelScalesRemoveGeraltScalingAbilities();
	ModGeraltLevelScalesRemoveInventoryScaling( w.GetInventory() );
}

// a / b, or 1 where b is not positive.
function GlsDifficultyAddonRatio( a : float, b : float ) : float
{
	if ( b <= 0 )
	{
		return 1;
	}
	return a / b;
}

// Geralt measured as GLS scales Geralt at the encounter level and at the boundary, the lowest encounter level where the
// whole gap fits, and the fight's factors set from the two. GLS's own functions throughout, its cleanup after each.
function GlsDifficultyAddonMeasure( w : W3PlayerWitcher, encounter : int, boundary : int )
{
	var atEncounter, atBoundary : SPlayerOffenseStats;
	var signEncounter, signBoundary, armor : SAbilityAttributeValue;
	var healthEncounter, healthBoundary : float;

	GlsDifficultyAddonUnscale( w );
	ModGeraltLevelScalesScaleGeralt( encounter );
	atEncounter = w.GetOffenseStatsList();
	signEncounter = w.GetPowerStatValue( CPS_SpellPower );
	healthEncounter = w.GetStatMax( BCS_Vitality );
	armor = w.GetTotalArmor();
	w.glsdaArmorEncounter = armor.valueBase;

	GlsDifficultyAddonUnscale( w );
	ModGeraltLevelScalesScaleGeralt( boundary );
	atBoundary = w.GetOffenseStatsList();
	signBoundary = w.GetPowerStatValue( CPS_SpellPower );
	healthBoundary = w.GetStatMax( BCS_Vitality );
	armor = w.GetTotalArmor();
	w.glsdaArmorBoundary = armor.valueBase;

	GlsDifficultyAddonUnscale( w );

	w.glsdaSteel = GlsDifficultyAddonRatio( atEncounter.steelFastDmg, atBoundary.steelFastDmg );
	w.glsdaSilver = GlsDifficultyAddonRatio( atEncounter.silverFastDmg, atBoundary.silverFastDmg );
	w.glsdaCrossbow = GlsDifficultyAddonRatio( atEncounter.crossbowSteelDmg, atBoundary.crossbowSteelDmg );
	w.glsdaSign = GlsDifficultyAddonRatio( signEncounter.valueMultiplicative, signBoundary.valueMultiplicative );
	w.glsdaHealth = GlsDifficultyAddonRatio( healthBoundary, healthEncounter );
	w.glsdaActive = true;

	LogChannel( 'modGLSDifficultyAddon', "Full penalty: encounter " + encounter + ", as at " + boundary
		+ "; damage dealt x" + FloatToStringPrec( w.glsdaSteel, 3 ) + " steel, x" + FloatToStringPrec( w.glsdaSilver, 3 )
		+ " silver, x" + FloatToStringPrec( w.glsdaCrossbow, 3 ) + " crossbow, x" + FloatToStringPrec( w.glsdaSign, 3 )
		+ " signs; health ratio " + FloatToStringPrec( w.glsdaHealth, 3 ) + ", armor " + FloatToStringPrec( w.glsdaArmorEncounter, 1 )
		+ " and " + FloatToStringPrec( w.glsdaArmorBoundary, 1 ) );
}

// Before GLS scales Geralt for a fight that needs it, the measurement. Its own calls to this function come back
// through this wrapper, which then passes them straight on, the request being taken.
@wrapMethod
function ModGeraltLevelScalesScaleGeralt( targetLevel : int )
{
	var w : W3PlayerWitcher;
	var encounter : int;

	w = GetWitcherPlayer();
	if ( w && w.glsdaPendingEncounter > 0 )
	{
		encounter = w.glsdaPendingEncounter;
		w.glsdaPendingEncounter = 0;
		GlsDifficultyAddonMeasure( w, encounter, w.glsdaPendingBoundary );
	}
	wrappedMethod( targetLevel );
}

// The fight's factors end with GLS's own end of the fight.
@wrapMethod
function ModGeraltLevelScalesOnCombatFinished()
{
	var w : W3PlayerWitcher;

	wrappedMethod();
	w = GetWitcherPlayer();
	if ( w )
	{
		w.glsdaActive = false;
	}
}

// The factor for a hit Geralt deals: weapons by their damage, signs and their burning by sign intensity, the rest 1.
function GlsDifficultyAddonDealtFactor( w : W3PlayerWitcher, action : W3DamageAction ) : float
{
	var burning : W3Effect_Burning;

	if ( action.IsDoTDamage() )
	{
		burning = (W3Effect_Burning)action.causer;
		if ( burning && burning.IsSignEffect() )
		{
			return w.glsdaSign;
		}
		return 1;
	}
	if ( action.IsActionWitcherSign() )
	{
		return w.glsdaSign;
	}
	if ( action.IsActionMelee() )
	{
		if ( w.IsWeaponHeld( 'silversword' ) )
		{
			return w.glsdaSilver;
		}
		if ( w.IsWeaponHeld( 'steelsword' ) )
		{
			return w.glsdaSteel;
		}
		return 1;
	}
	if ( action.IsActionRanged() && (W3BoltProjectile)action.causer )
	{
		return w.glsdaCrossbow;
	}
	return 1;
}

// The factor for a hit Geralt takes: the hits to die as at the boundary instead of at the encounter level, from Geralt's
// health and armor at the two levels and this hit's own value. Damage over time on Geralt, a share of Geralt's own
// health, is not changed by levels: 1.
function GlsDifficultyAddonTakenFactor( w : W3PlayerWitcher, action : W3DamageAction ) : float
{
	var dmgInfos : array< SRawDamage >;
	var armor : SAbilityAttributeValue;
	var points, percents, beforeResist, atEncounter, atBoundary, armorPart : float;

	if ( action.IsDoTDamage() )
	{
		return 1;
	}
	armorPart = 1;
	action.GetDTs( dmgInfos );
	if ( dmgInfos.Size() > 0 && IsDamageTypeAnyPhysicalType( dmgInfos[0].dmgType ) && !action.GetIgnoreArmor() )
	{
		w.GetResistValue( GetResistForDamage( dmgInfos[0].dmgType, false ), points, percents );
		beforeResist = action.GetDamageDealt() / MaxF( 0.01, 1 - MinF( percents, 0.99 ) );
		armor = w.GetTotalArmor();
		// The hit before armor, less the armor Geralt would have at the encounter level and at the boundary.
		atEncounter = beforeResist + armor.valueBase - w.glsdaArmorEncounter;
		atBoundary = MaxF( beforeResist + armor.valueBase - w.glsdaArmorBoundary, 0.25 * atEncounter );
		if ( atEncounter > 0 && atBoundary > 0 )
		{
			armorPart = atEncounter / atBoundary;
		}
	}
	return w.glsdaHealth * armorPart;
}

// After the game's own reductions (block, parry, Quen and the like), the hit's final damage scaled by the fight's
// factor, for hits Geralt deals and takes; nothing in any other fight.
@wrapMethod( CActor ) function ReduceDamage( out damageData : W3DamageAction )
{
	var w : W3PlayerWitcher;
	var attacker : CActor;
	var factor : float;

	wrappedMethod( damageData );

	w = GetWitcherPlayer();
	attacker = (CActor)damageData.attacker;
	factor = 1;
	if ( !w || !attacker )
	{
		return;
	}
	if ( w.glsdaActive && damageData.GetDamageDealt() > 0 )
	{
		if ( attacker == w && this != w )
		{
			factor = GlsDifficultyAddonDealtFactor( w, damageData );
		}
		else if ( this == w && attacker != w )
		{
			factor = GlsDifficultyAddonTakenFactor( w, damageData );
		}
	}
	if ( factor != 1 )
	{
		damageData.MultiplyAllDamageBy( factor );
	}
}
