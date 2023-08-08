/***********************************************************************/
/** 	GoldenHourEnum.ws
/** 	by Phaz42
/***********************************************************************/

enum EGhMultiplier
{
	GH_Multiplier02 = 0,
	GH_Multiplier05 = 1,
	GH_Multiplier07 = 2,
	GH_Multiplier10 = 3,
    GH_Multiplier15 = 4,
    GH_Multiplier20 = 5,
    GH_Multiplier25 = 6,
    GH_Multiplier30 = 7,
    GH_Multiplier35 = 8,
    GH_Multiplier40 = 9,
    GH_Multiplier45 = 10,
    GH_Multiplier50 = 11
}

function GetMultiplier( multiplier : EGhMultiplier ) : float
{
	switch(multiplier)
	{
	    case GH_Multiplier02:	return 0.2f;
		case GH_Multiplier05:	return 0.5f;
		case GH_Multiplier07:	return 0.7f;
		case GH_Multiplier10:	return 1.0f;
        case GH_Multiplier15:	return 1.5f;
        case GH_Multiplier20:	return 2.0f;
        case GH_Multiplier25:	return 2.5f;
        case GH_Multiplier30:	return 3.0f;
        case GH_Multiplier35:	return 3.5f;
        case GH_Multiplier40:	return 4.0f;
        case GH_Multiplier45:	return 4.5f;
        case GH_Multiplier50:	return 5.0f;
	}
}

enum EGhWeatherType
{
    GH_WeatherTypeUnchanged = 0,
    GH_WeatherTypeClear = 1,
    GH_WeatherTypeLightClouds = 2,
    GH_WeatherTypeMidClouds = 3,
    GH_WeatherTypeMidCloudsDark = 4,
    GH_WeatherTypeHeavyClouds = 5,
    GH_WeatherTypeHeavyCloudsDark = 6,
    GH_WeatherTypeRain_Storm = 7,
    GH_WeatherTypeSnow = 8
}

function GetWeatherType( weatherType : EGhWeatherType ) : name
{
	switch(weatherType)
	{
	    case GH_WeatherTypeUnchanged:       return 'Unchanged';
        case GH_WeatherTypeClear:	        return 'WT_Clear';
        case GH_WeatherTypeLightClouds:	    return 'WT_Light_Clouds';
        case GH_WeatherTypeMidClouds:	    return 'WT_Mid_Clouds';
        case GH_WeatherTypeMidCloudsDark:	return 'WT_Mid_Clouds_Dark';
        case GH_WeatherTypeHeavyClouds:	    return 'WT_Heavy_Clouds';
        case GH_WeatherTypeHeavyCloudsDark: return 'WT_Heavy_Clouds_Dark';
        case GH_WeatherTypeRain_Storm:	    return 'WT_Rain_Storm';
        case GH_WeatherTypeSnow:	        return 'WT_Snow';
	}
}

enum EGhSwwsWeatherType
{
	GH_SwwsWeatherTypeUnchanged = 0,
	GH_SwwsWeatherTypeClear = 1,
	GH_SwwsWeatherTypeFog1 = 2,
	GH_SwwsWeatherTypeFog2 = 3,
	GH_SwwsWeatherTypeFlurry1 = 4,
	GH_SwwsWeatherTypeFlurry2 = 5,
	GH_SwwsWeatherTypeFlurry3 = 6,
	GH_SwwsWeatherTypeFlurry4 = 7,
	GH_SwwsWeatherTypeFlurry5 = 8,
	GH_SwwsWeatherTypeSnow1 = 9,
	GH_SwwsWeatherTypeSnow2 = 10,
	GH_SwwsWeatherTypeSnow3 = 11,
	GH_SwwsWeatherTypeSnow4 = 12,
	GH_SwwsWeatherTypeSnow5 = 13,
	GH_SwwsWeatherTypeSnow6 = 14,
	GH_SwwsWeatherTypeBlizzard = 15
}

function GetSwwsWeatherType( weatherType : EGhSwwsWeatherType ) : name
{
	switch(weatherType)
	{
		case GH_SwwsWeatherTypeUnchanged:	return 'Unchanged';
		case GH_SwwsWeatherTypeClear:		return 'clear';
		case GH_SwwsWeatherTypeFog1:		return 'fog1';
		case GH_SwwsWeatherTypeFog2:		return 'fog2';
		case GH_SwwsWeatherTypeFlurry1:		return 'flurry1';
		case GH_SwwsWeatherTypeFlurry2:		return 'flurry2';
		case GH_SwwsWeatherTypeFlurry3:		return 'flurry3';
		case GH_SwwsWeatherTypeFlurry4:		return 'flurry4';
		case GH_SwwsWeatherTypeFlurry5:		return 'flurry5';
		case GH_SwwsWeatherTypeSnow1:		return 'snow1';
		case GH_SwwsWeatherTypeSnow2:		return 'snow2';
		case GH_SwwsWeatherTypeSnow3:		return 'snow3';
		case GH_SwwsWeatherTypeSnow4:		return 'snow4';
		case GH_SwwsWeatherTypeSnow5:		return 'snow5';
		case GH_SwwsWeatherTypeSnow6:		return 'snow6';
		case GH_SwwsWeatherTypeBlizzard:	return 'blizzard';
	}
}
