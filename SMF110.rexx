/* Rexx */
Numeric digits 31
eofflag = 2      /* End of File  */

call Initialize

eof = 'false'

/* Open SMF Dump file, do not read any records yet */
/* All records will be read and processed with main loop*/

"EXECIO 0 DISKR WORKSMF (OPEN"    /* Open SMF Dump*/

Do While (fileStatus ^= eofflag)
    "EXECIO 1 DISKR WORKSMF"
    fileStatus = rc
    If fileStatus = 0 then
      Do
        parse pull line
        call Process_SMF_Record line
      End
End

"EXECIO 0 DISKR WORKSMF (FINIS" /* Close SFM Dump File*/

call terminate
exit 0
/* End of processing*/


Initialize: proc expose __. dict.
  call ReadDictionary
  return

ReadDictionary: proc expose __. dict.
  dict. = ''
  dict.0 = 0
  /*-------------------------------------------
  dictFile = 'E640963.LBN.CNTL(SMFDICT)'
  "ALLOC FILE(SMFDICT) DSN('"dictFile"') SHR"
  -------------------------------------------*/
  "EXECIO * DISKR SMFDICT (FINIS STEM dictRecords. "

  Do i=1 to dictRecords.0
    parse var dictRecords.i fieldName fldType fldLen fldConnect,
       fldOffset fldTitle . ;
    dict.nickName.length = fldLen
    parse var fldOffset 3 fldOffset +4 .
    dict.nickName.offset = X2D(fldOffset)
  End
  dict.0 = dictRecords.0
  drop dictRecords.

  return

Process_SMF_Record: proc
  parse arg smfRecord

  recType = binary_d(smfRecord,Offset(5),1)  /* Determine record type*/

  If recType = 110 then
    Do
      subType = binary_d(smfRecord,Offset(22),2) /* Record Subtype*/

      If subtype = 1 then
        Do
          offsetToProductSect = binary_d(smfRecord,Offset(28),4) /* SMF110APS*/
          base = Offset(offsetToProductSect)

          classOfData = binary_d(smfRecord,base+22,2) 
                                      /* SMF110S1_MNCL
                                          1 = DICTIONARY
                                          3 = PERFORMANCE
                                          4 = EXCEPTION
                                          5 = TRANSACTION RESOURCE */
          If (classOfData = 3) then
            Do
              offsetToDataRec = offset(binary_d(smfRecod,base+32,4))
                            /* OFFSET TO FIRST CICS DATA RECORD. 
                              For dictionary class records, offset to the first dictionary entry. For performance and exception class records, offset to the first performance or exception class record. For transaction resource monitoring records, offset to the first transaction resource monitoring record. 
                            */
              lengthOfDataRec = binary_d(smfRecord,base+36,2)
              noOfDataRecords = binary_d(smfRecord,base+38,2)
              Do i=1 to noOfDataRecords
                call Read_Perf_DataSecion offsetToDataRec smfRecord
                offsetToDataRec = offsetToDataRec + lengthOfDataRec
                smfData. = ''
              End
            End                                                    

        End
    End
  return


Read_Perf_DataSecion: procedure expose smfData.
  parse arg base smfRecord
  
  smfData.Tran = EBCDIC(smfRecord,base+dict.TRAN.offset,dict.TRAN.length)
  smfData.UserId = EBCDIC(smfRecord,base+dict.USERID.offset,dict.USERID.length)
  smfData.tranType = EBCDIC(smfRecord,base+dict.TTYPE.offset,dict.TTYPE.length)
  return

/*---------------------------------------------------------------------
 Functions:
 ---------------------------------------------------------------------*/
/*---------------------------------------------------------------------
 Function: OFFSET
 Input: Field offset (decimal) per SMF Reference (SA22-7630, Chapter 14)
 Output: Input offset minus three
   To get the correct offset into the SMF input line, subtract three
   bytes. These three bytes consist of:
   2 bytes, to account for RDW not being present
   1 byte, because in Rexx, indices begin at position 1, not zero
 ---------------------------------------------------------------------*/
Offset: procedure
  arg this_offset
  return (this_offset-3)
/*---------------------------------------------------------------------
 Function: Binary_d
 Returns : Decimal
 ---------------------------------------------------------------------*/
binary_d: procedure expose __.
  parse arg $dumpline,$offset,$field_length
  this_field = substr($dumpline,$offset,$field_length)
  translated_field = x2d(c2x(this_field))
  return (translated_field)
/*---------------------------------------------------------------------
 Function: Binary4_d  --> for negative Values in 4 Byte binary fields
 Returns : Decimal
 ---------------------------------------------------------------------*/
binary4_d: procedure expose __.
  parse arg $dumpline,$offset,$field_length
  this_field = substr($dumpline,$offset,$field_length)
  translated_field = x2d(c2x(this_field),8)
  return (translated_field)
/*---------------------------------------------------------------------
 Function: Binary_h
 Returns : Decimal
 ---------------------------------------------------------------------*/
binary_h: procedure expose __.
  parse arg $dumpline,$offset,$field_length
  this_field = substr($dumpline,$offset,$field_length)
  translated_field = x2d(c2x(this_field))
  return (translated_field)
/*---------------------------------------------------------------------
 Function: Binary_x
 Returns : Hexadecimal
 ---------------------------------------------------------------------*/
binary_x: procedure expose __.
  parse arg $dumpline,$offset,$field_length
  this_field = substr($dumpline,$offset,$field_length)
  translated_field = c2x(this_field)
  return (translated_field)
/*---------------------------------------------------------------------
 Function: Binary_b
 Returns : Binary
 ---------------------------------------------------------------------*/
binary_b: procedure expose __.
  parse arg $dumpline,$offset,$field_length
  this_field = substr($dumpline,$offset,$field_length)
  translated_field = x2b(c2x(this_field))
  return (translated_field)
/*---------------------------------------------------------------------
 Function: Packed
 ---------------------------------------------------------------------*/
packed: procedure expose __.
  parse arg $dumpline,$offset,$field_length
  translated_field = binary_x($dumpline,$offset,$field_length)
  return (translated_field)
/*---------------------------------------------------------------------
 Function: EBCDIC
 Returns:  EBCDIC
 ---------------------------------------------------------------------*/
ebcdic: procedure expose __.
  parse arg $dumpline,$offset,$field_length
  this_field = substr($dumpline,$offset,$field_length)
  return (this_field)
/*---------------------------------------------------------------------
 Function: Smftime
 Returns: hh:mm:ss
 ---------------------------------------------------------------------*/
smftime: procedure
  parse arg $dumpline,$offset,$field_length
  _time     = binary_d($dumpline,$offset,$field_length)
  hundreths = _time % 100
  hh        = hundreths % 3600
  hh        = RIGHT("0"||hh,2)
  mm        = (hundreths % 60) - (hh * 60)
  mm        = RIGHT("0"||mm,2)
  ss        = hundreths - (hh * 3600) - (mm * 60)
  ss        = RIGHT("0"||ss,2)
  this_time = hh||":"||mm||":"||ss
  return (this_time)
/*---------------------------------------------------------------------
 Function: Smfjdate
 Returns: Julian date yyyy.ddd
 Per SMF documentation, SMFxDTE is the date when the record was moved
 into the SMF buffer, in the form 0cyydddF where
   c   is 0 for 19xx and 1 for 20xx
   yy  is the current year (0-99)
   ddd is the current day (1-366)
   F   is the sign)
 ---------------------------------------------------------------------*/
smfjdate: procedure
  parse arg $dumpline,$offset,$field_length
  this_field = c2x(substr($dumpline,$offset,$field_length))
  parse value this_field with 1 . 2 c 3 yy 5 ddd 8 .
  if (c = 0) then
    yyyy = '19'||yy
  else
    yyyy = '20'||yy
  julian_date = yyyy||'.'||ddd
  return (julian_date)