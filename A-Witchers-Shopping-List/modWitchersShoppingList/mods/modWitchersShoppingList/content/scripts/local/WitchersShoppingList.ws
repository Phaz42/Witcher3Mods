// A Witcher's Shopping List: at a merchant, on every alchemy ingredient and crafting material Geralt has fewer of than
// the menu's threshold, Geralt's own count, small and red, before the merchant's; and when buying one of them, the
// amount offered first is the one that brings Geralt up to the threshold. Annotations only: nothing overridden, nothing
// to merge.

// ---------------------------------------------------------------------------------------------------------
// The menu: one setting, the threshold, 1 to 20, 5 by default; written when the options menu opens, so the menu shows
// it before a save is loaded. An out-of-range value reads as the default.

function WslThreshold() : int
{
	var threshold : int;

	threshold = StringToInt( theGame.GetInGameConfigWrapper().GetVarValue( 'modWitchersShoppingList', 'wslThreshold' ), 5 );
	if ( threshold < 1 || threshold > 20 )
	{
		return 5;
	}
	return threshold;
}

function WslSetDefaults()
{
	var config : CInGameConfigWrapper;
	var threshold : string;

	config = theGame.GetInGameConfigWrapper();
	threshold = config.GetVarValue( 'modWitchersShoppingList', 'wslThreshold' );
	if ( threshold == "" || StringToInt( threshold ) < 1 || StringToInt( threshold ) > 20 )
	{
		config.SetVarValue( 'modWitchersShoppingList', 'wslThreshold', "5" );
		theGame.SaveUserSettings();
	}
}

@wrapMethod( CR4IngameMenu ) function OnConfigUI()
{
	WslSetDefaults();
	wrappedMethod();
}

// The help note: while the threshold is selected, its help in the banner under the option list, the one the game's
// Accessibility page uses for its preset's description (the menu's updateBardsBalladText and showBardsBalladTooltip);
// never the notification popup, which other mods' menus clear on every selection. The banner's text field is two
// lines tall: it is grown to the text while the note shows, and given back afterwards.

@addField( CR4IngameMenu )
var wslHelpShown : bool;

@addField( CR4IngameMenu )
var wslHelpTextHeight : float;

@addMethod( CR4IngameMenu ) function WslHelpTextField() : CScriptedFlashObject
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

@addMethod( CR4IngameMenu ) function WslShowHelp( text : string )
{
	var textField : CScriptedFlashObject;

	m_fxUpdateBardsBalladText.InvokeSelfOneArg( FlashArgString( text ) );
	textField = WslHelpTextField();
	if ( textField )
	{
		if ( wslHelpTextHeight <= 0 )
		{
			wslHelpTextHeight = textField.GetMemberFlashNumber( "height" );
		}
		textField.SetMemberFlashNumber( "height", MaxF( wslHelpTextHeight, textField.GetMemberFlashNumber( "textHeight" ) + 8 ) );
	}
	m_flashModule.GetMemberFlashFunction( "showBardsBalladTooltip" ).InvokeSelfOneArg( FlashArgBool( true ) );
}

// The banner given back as the game has it: its own text, its height, hidden.
@addMethod( CR4IngameMenu ) function WslHideHelp()
{
	var textField : CScriptedFlashObject;

	if ( !wslHelpShown )
	{
		return;
	}
	wslHelpShown = false;
	textField = WslHelpTextField();
	if ( textField && wslHelpTextHeight > 0 )
	{
		textField.SetMemberFlashNumber( "height", wslHelpTextHeight );
	}
	UpdateBardsBalladTooltipText();
	m_flashModule.GetMemberFlashFunction( "showBardsBalladTooltip" ).InvokeSelfOneArg( FlashArgBool( false ) );
}

@wrapMethod( CR4IngameMenu ) function OnOptionSelectionChanged( optionName : name, value : bool )
{
	var result : bool;

	result = wrappedMethod( optionName, value );
	if ( value && optionName == 'wslThreshold' )
	{
		wslHelpShown = true;
		WslShowHelp( GetLocStringByKey( "wsl_threshold_help" ) );
	}
	else if ( value || optionName == 'wslThreshold' )
	{
		WslHideHelp();
	}
	return result;
}

@wrapMethod( CR4IngameMenu ) function OnOptionPanelNavigateBack()
{
	WslHideHelp();
	return wrappedMethod();
}

@wrapMethod( CR4IngameMenu ) function OnClosingMenu()
{
	WslHideHelp();
	return wrappedMethod();
}

// ---------------------------------------------------------------------------------------------------------
// The count. An item counts when the game's own ingredient test passes (its AlchemyIngredient or CraftingIngredient
// tag); Geralt's count is what Geralt's inventory holds, what the game's alchemy and crafting count too.

function WslOwnedBelowThreshold( inv : CInventoryComponent, item : SItemUniqueId, out owned : int ) : bool
{
	if ( !inv || !inv.IsItemIngredient( item ) )
	{
		return false;
	}
	owned = thePlayer.inv.GetItemQuantityByName( inv.GetItemName( item ) );
	return owned < WslThreshold();
}

// On a merchant's slot, the slot's count field (the one the game fills with a bomb's or potion's charges, drawn in place
// of the quantity) holds Geralt's count, small and red, then the merchant's.
@wrapMethod( W3GuiShopInventoryComponent ) function SetInventoryFlashObjectForItem( item : SItemUniqueId, out flashObject : CScriptedFlashObject ) : void
{
	var owned : int;

	wrappedMethod( item, flashObject );
	if ( WslOwnedBelowThreshold( _inv, item, owned ) )
	{
		flashObject.SetMemberFlashString( "charges", "<font color=\"#FF4040\" size=\"16\">" + owned + "</font> " + _inv.GetItemQuantity( item ) + " " );
	}
}

// ---------------------------------------------------------------------------------------------------------
// The buy popup: the game offers the most Geralt can afford (CR4InventoryMenu.OpenQuantityPopup); for an item below
// the threshold, the amount that brings Geralt up to it instead, never more than that offer. Set when the popup reads
// its data, so the game's own amounts are already in place.

@addMethod( CR4InventoryMenu ) function WslShopInventory() : CInventoryComponent
{
	if ( _shopInv )
	{
		return _shopInv.GetInventoryComponent();
	}
	return NULL;
}

@wrapMethod( QuantityPopupData ) function GetGFxData( parentFlashValueStorage : CScriptedFlashValueStorage ) : CScriptedFlashObject
{
	var owned : int;

	if ( actionType == QTF_Buy && inventoryRef && WslOwnedBelowThreshold( inventoryRef.WslShopInventory(), itemId, owned ) )
	{
		currentValue = Max( minValue, Min( WslThreshold() - owned, currentValue ) );
	}
	return wrappedMethod( parentFlashValueStorage );
}
