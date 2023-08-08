/***********************************************************************/
/**		GoldenHourArea.ws
/**		by Phaz42
/***********************************************************************/

class GoldenHourArea
{
	public var area : EAreaName;
	public var morning, evening : GoldenHourTimeSpan;

	public function Init(
		mStartHour : int, mStartMinute : int, mEndHour : int, mEndMinute : int,
		eStartHour : int, eStartMinute : int, eEndHour : int, eEndMinute : int )
	{
		morning = new GoldenHourTimeSpan in this;
		morning.Init( mStartHour, mStartMinute, mEndHour, mEndMinute );

		evening = new GoldenHourTimeSpan in this;
		evening.Init( eStartHour, eStartMinute, eEndHour, eEndMinute );
	}
}
