PROC 0 UNIT(SYSALLDA)                                                           
CONTROL NOMSG NOLIST NOCONLIST NOFLUSH                                          
/*                           */                                                 
/* AUTHOR: MARK ZELDEN       */                                                 
/*                           */                                                 
/* LAST UPDATE: 06/20/2006   */                                                 
LOOP: +                                                                         
ISPEXEC DISPLAY PANEL(AMBPANEL)                                                 
                                                                                
  /*  IF "END" WAS ENTERED, EXIT */                                             
                                                                                
IF &LASTCC = 8 THEN DO                                                          
  EXIT CODE(0)                                                                  
END                                                                             
                                                                                
                                                                                
FREE FI(SYSLIB SYSIN SYSPRINT)                                                  
FREE ATTRLIST(DCB1 DCB2)                                                        
CONTROL MSG                                                                     
IF &O ^= 5 THEN DO                                                              
  IF &STR(&AMBVOL) = &STR() THEN +                                              
    ALLOC FI(SYSLIB) DA(&AMBDSN) SHR                                            
  ELSE +                                                                        
    ALLOC FI(SYSLIB) DA(&AMBDSN) VOLUME(&AMBVOL) SHR                            
END                                                                             
SET &CC = &LASTCC                                                               
CONTROL NOMSG                                                                   
IF &CC NE 0 THEN GOTO LOOP                                                      
ATTRIB DCB1 RECFM(F) LRECL(80) BLKSIZE(80)                                      
ATTRIB DCB2 RECFM(F B) LRECL(121) BLKSIZE(5687)                                 
ALLOC FILE(SYSIN) UNIT(&UNIT) SP(1,1) TRACK US(DCB1)                            
ALLOC FILE(SYSPRINT) UNIT(&UNIT) SP(1,10) CYL US(DCB2)                          
OPENFILE SYSIN OUTPUT                                                           
IF &O = 1 AND &STR(&AMBMEM) = &STR(*) THEN DO                                   
  SET &SYSIN=&STR( LISTIDR)                                                     
END                                                                             
ELSE IF &O = 1 THEN DO                                                          
  SET &SYSIN=&STR( LISTIDR MEMBER=&AMBMEM)                                      
END                                                                             
IF &O = 2 AND &STR(&AMBMEM) = &STR(*) THEN DO                                   
  SET &SYSIN=&STR( LISTLOAD OUTPUT=XREF)                                        
END                                                                             
ELSE IF &O = 2 THEN DO                                                          
  SET &SYSIN=&STR( LISTLOAD OUTPUT=XREF,MEMBER=&AMBMEM)                         
END                                                                             
IF &O = 3 AND &STR(&AMBMEM) = &STR(*) THEN DO                                   
  SET &SYSIN=&STR( LISTLOAD)                                                    
END                                                                             
ELSE IF &O = 3 THEN DO                                                          
  SET &SYSIN=&STR( LISTLOAD MEMBER=&AMBMEM)                                     
END                                                                             
IF &O = 4 AND &STR(&AMBMEM) = &STR(*) THEN DO                                   
  SET &SYSIN=&STR( LISTOBJ)                                                     
END                                                                             
ELSE IF &O = 4 THEN DO                                                          
  SET &SYSIN=&STR( LISTOBJ MEMBER=&AMBMEM)                                      
END                                                                             
IF &O = 5 THEN DO                                                               
  SET &SYSIN=&STR( LISTLPA)                                                     
END                                                                             
PUTFILE SYSIN                                                                   
CLOSFILE SYSIN                                                                  
CALL 'SYS1.LINKLIB(AMBLIST)'                                                    
ISPEXEC LMINIT DATAID(AMBROWSE) DDNAME(SYSPRINT)                                
ISPEXEC BROWSE DATAID(&AMBROWSE)                                                
ISPEXEC LMFREE DATAID(&AMBROWSE)                                                
FREE FI(SYSLIB SYSIN SYSPRINT)                                                  
FREE ATTRLIST(DCB1 DCB2)                                                        
ALLOC FI(SYSPRINT) DA(*)                                                        
                                                                                
GOTO LOOP                                                                       
