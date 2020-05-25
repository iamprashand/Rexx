/*    ReXX       */

/* Main program */
say SSI2TS('5E207636')

/* ------------------------------------------------
   Routine to convert HexaDecimal SSI to TimeStamp.
   Assumption: SSI value is the number of seconds
      since 1st January 1970
   ------------------------------------------------
*/
SSI2TS:
 Arg InputSeconds
 Numeric digits 18
 DecSeconds = X2D(InputSeconds)
 Leap = 366*24*60*60
 NonLeap = 365*24*60*60
 TheYear = 1970
 Do While DecSeconds >= NonLeap
    If TheYear // 4 = 0 Then
        DecSeconds = DecSeconds - Leap
    Else
        DecSeconds = DecSeconds - NonLeap
    TheYear = TheYear + 1
 End

 Month.     = 31
 Month.2    = 28
 Month.4    = 30
 Month.6    = 30
 Month.9    = 30
 Month.11   = 30

 If (TheYear // 4 = 0) Then
    Month.2 = 29

 Do i = 1 to 12
    If DecSeconds < ((Month.i)*24*60*60) Then
      Do
        TheMonth = i
        i = 99
    End
    Else
        DecSeconds = DecSeconds - ((Month.i)*24*60*60)
 End

 TheMonth = RIGHT(TheMonth,2,'0')
 TheDay = DecSeconds % (24*60*60)
 DecSeconds = DecSeconds - (TheDay*24*60*60)
 TheDay = TheDay + 1
 TheDay = RIGHT(TheDay,2,'0')
 TheHour = RIGHT(DecSeconds % (60*60),2,'0')
 DecSeconds = DecSeconds - (TheHour*60*60)
 TheMinute = RIGHT(DecSeconds % 60,2,'0')
 DecSeconds = DecSeconds - (TheMinute*60)
 TheSeconds = RIGHT(DecSeconds,2,'0')

 compDate = TheYear||'/'||TheMonth||'/'||TheDay||' '||,
            TheHour||':'||TheMinute||':'||TheSeconds;
Return compDate 