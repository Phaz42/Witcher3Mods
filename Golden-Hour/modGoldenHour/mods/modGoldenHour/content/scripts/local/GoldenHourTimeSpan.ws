/***********************************************************************/
/**		GoldenHourTimeSpan.ws
/**		by Phaz42
/***********************************************************************/

class GoldenHourTimeSpan
{
	public var startHour, startMinute, endHour, endMinute : int;

	public function Init( sHour : int, sMinute : int, eHour : int, eMinute : int)
	{
		startHour = sHour;
		startMinute = sMinute;
		endHour = eHour;
		endMinute = eMinute;
	}
}
