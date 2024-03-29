/* REXX  */                                                                     
/*                           */                                                 
/* AUTHOR: MARK ZELDEN       */                                                 
/*                           */                                                 
/***********************************************************/                   
/*  Quickly find the location of a module (or modules).    */                   
/*                                                         */                   
/*  The specified module name may be fully qualified or    */                   
/*  any valid ISPF member pattern. The output will show    */                   
/*  the module name(s) found, the library or libraries it  */                   
/*  was found in and the "last updated" (changed) ISPF     */                   
/*  statistic if it exits for the member(s).               */                   
/*                                                         */                   
/*  By default, the LPA and LNKLST concatenation are       */                   
/*  searched. Alternatively, a "search list member" may    */                   
/*  be specified. In order to use the search list, the     */                   
/*  libraries to search must be manually added to a        */                   
/*  PDS member (or members).                               */                   
/*                                                         */                   
/*  The library that the optional search member list must  */                   
/*  reside in is defined by the MBRLIB variable below.     */                   
/*  A suggested member list name is FINDxxxx where xxxx is */                   
/*  the SMFID of the system, or a descriptive name such    */                   
/*  as FINDPROC or FINDCICS. The search list should        */                   
/*  specify only one library per line. An "*" in column    */                   
/*  one indicates the line is a comment.                   */                   
/*                                                         */                   
/*  SAMPLE SEARCH LIST:                                    */                   
/*  *---+----1----+----2----+----3----+----4----+----5     */                   
/*  ******************************                         */                   
/*  * PROC LIBS                                            */                   
/*  ******************************                         */                   
/*  SYS1.PROCLIB                                           */                   
/*  SYS1.IBM.PROCLIB                                       */                   
/*  USER.PROCLIB                                           */                   
/*  ******************************                         */                   
/*  * CLIST LIBS                                           */                   
/*  ******************************                         */                   
/*  SYS1.CLIST                                             */                   
/*  USER.CLIST1                                            */                   
/*  USER.CLIST2                                            */                   
/*                                                         */                   
/***********************************************************/                   
/* EXECUTION SYNTAX:                                       */                   
/*                                                         */                   
/* TSO %FINDMOD <mbr pattern> (search list name) (BOTH)    */                   
/*                                                         */                   
/* If a search list name is specified, only the libraries  */                   
/* in the search list will be searched, unless the "BOTH"  */                   
/* option is used. The "BOTH" option will search the       */                   
/* libraries in the search list first, then the LPA and    */                   
/* LNKLST.                                                 */                   
/*                                                         */                   
/* EXAMPLES:                                               */                   
/* TSO %FINDMOD         (will prompt for module name)      */                   
/* TSO %FINDMOD IEFBR14 (search LPA & LNKLST for IEFBR14)  */                   
/* TSO %FINDMOD LLA FINDPROC (find LLA using FINDPROC list)*/                   
/* TSO %FINDMOD A%R*  (use mask to search LPA & LNKLST)    */                   
/* TSO %FINDMOD MYPROG BOTH (use list, LPA, & LNKLST)      */                   
/*                                                         */                   
/* NOTE: This exec can be executed as an ISPF EDIT MACRO   */                   
/*   from ISPF EDIT or VIEW from the command line without  */                   
/*   using the "TSO" prefix.  Example: FINDMOD IEFBR14     */                   
/***********************************************************/                   
/*                                                         */                   
/* You can easily turn "FINDMOD" into "FINDPROC" by        */                   
/* uncommenting out one of the "MEMBER =" lines below      */                   
/* just after "call CHECK_MODNAME"   (in other words, hard */                   
/* coding a search member name). Then code the PROCLIBs    */                   
/* to search in that PDS member and execute as follows:    */                   
/*                                                         */                   
/* TSO %FINDPROC LLA                                       */                   
/*                                                         */                   
/***********************************************************/                   
arg NAME MEMBER OPT DEBUG                                                       
/***********************************************************/                   
LASTUPD = '07/22/2008'     /* date of last update          */                   
/***********************************************************/                   
parse upper arg                                                                 
If Sysvar(SYSISPF) <> 'ACTIVE' then do                                          
  Say 'FINDMOD must be invoked from ISPF, terminating!'                         
  Exit 12                                                                       
End                                                                             
address ISREDIT "MACRO (NAME MEMBER OPT DEBUG)"                                 
NAME   = translate(NAME)    /* chg to upper case for edit macro */              
MEMBER = translate(MEMBER)  /* chg to upper case for edit macro */              
OPT    = translate(OPT)     /* chg to upper case for edit macro */              
DEBUG  = translate(DEBUG)   /* chg to upper case for edit macro */              
If OPT <> '' & OPT <> 'BOTH' then do                                            
  Say '"BOTH" is the only valid option'                                         
  Exit 8                                                                        
End                                                                             
If debug = 'DEBUG' then trace ?i                                                
/*********************************************************/                     
/* MBRLIB  = 'SYS2.PARMLIB'  */                                                 
MBRLIB  = 'MPSYS3.USZCZT0.CNTL'                                                 
/*********************************************************/                     
NUMLIBS = 0  /* total number of libraries to be searched */                     
call CHECK_MODNAME           /* check module name syntax */                     
/*********************************************************/                     
/* Uncomment one of the following for "FINDPROC" or      */                     
/* specify your own "MEMBER =" member name.              */                     
/*********************************************************/                     
 /* MEMBER = 'FIND' || MVSVAR(SYSSMFID)  */                                     
 /* MEMBER = 'FINDPROC' */                                                      
If MEMBER = '' then call GET_LPALNK  /* use LPA/LNKLST   */                     
Else do                                                                         
  Call GET_LIBNAMES          /* use optional search list */                     
  If OPT = 'BOTH' then call GET_LPALNK /* use LPA/LNKLST */                     
End                                                                             
/*********************************************************/                     
/*   BEGIN MODULE SEARCH                                 */                     
/*********************************************************/                     
FOUND = 'NO' /* found flag */                                                   
If member = '' then do                                                          
  Say   '...Searching for 'name' in 'numlibs' libraries'                        
  Say   '   (Using LPA & LNKLST' || setname || ')'                              
  Queue '...Searching for 'name' in 'numlibs' libraries'                        
  Queue '   (Using LPA & LNKLST' || setname || ')'                              
End                                                                             
Else do                                                                         
  If OPT = 'BOTH' then do                                                       
    Say   '...Searching for 'name' in 'numlibs' libraries'                      
    Say   '   (Using list 'member || ', LPA,' ,                                 
          '& LNKLST' || setname || ')'                                          
    Queue '...Searching for 'name' in 'numlibs' libraries'                      
    Queue '   (Using list 'member || ', LPA,' ,                                 
          '& LNKLST' || setname || ')'                                          
  End                                                                           
  Else Do                                                                       
    Say   '...Searching for 'name' in 'numlibs' libraries'                      
    Say   '   (Using search list 'member || ')'                                 
    Queue '...Searching for 'name' in 'numlibs' libraries'                      
    Queue '   (Using search list 'member || ')'                                 
  End                                                                           
End                                                                             
Say   '   '                                                                     
Queue '   '                                                                     
Do SEARCH = 1 to LIB.0                                                          
  LIB.SEARCH = word(LIB.SEARCH,1)                                               
  /* Say   'Searching' lib.search  */                                           
  /* Queue 'Searching' lib.search  */                                           
  Address ISPEXEC "LMINIT DATAID(FINDMOD1) DATASET('"lib.search"')"             
  If RC <> 0 then do                                                            
    Say   'Error processing' lib.search':'                                      
    Queue 'Error processing' lib.search':'                                      
    Say   Strip(ZERRLM)                                                         
    Queue Strip(ZERRLM)                                                         
    Say   '  '                                                                  
    Queue '  '                                                                  
    Iterate  /* go get next library to search on error */                       
  End /* if RC <> 0 */                                                          
  Address ISPEXEC "LMOPEN DATAID("FINDMOD1") RECFM(RFVAR)"                      
  If RC <> 0 then do                                                            
    Say   'Error processing' lib.search':'                                      
    Queue 'Error processing' lib.search':'                                      
    Say   Strip(ZERRLM)                                                         
    Queue Strip(ZERRLM)                                                         
    Say   '  '                                                                  
    Queue '  '                                                                  
    Address ISPEXEC "LMFREE DATAID("FINDMOD1")"                                 
    Iterate  /* go get next library to search on error */                       
  End /* if RC <> 0 */                                                          
  MEMVAR = ' '                                                                  
  ZLM4DATE = '' /* reset each new library because of stats yes/no */            
  Do forever                                                                    
    If RFVAR = 'FB' then ,                                                      
      Address ISPEXEC "LMMLIST DATAID("FINDMOD1") OPTION(LIST) ",               
              "MEMBER(MEMVAR) PATTERN("NAME") STATS(YES)"                       
    Else ,                                                                      
      Address ISPEXEC "LMMLIST DATAID("FINDMOD1") OPTION(LIST) ",               
              "MEMBER(MEMVAR) PATTERN("NAME") STATS(NO)"                        
    If RC = 0 then do  /* match found */                                        
      FOUND = 'YES'                                                             
      If ZLM4DATE = 'ZLM4DATE' | ZLM4DATE = '' then do /* no stats */           
        Say   memvar 'found in' lib.search                                      
        Queue memvar 'found in' lib.search                                      
      End                                                                       
      Else do /* stats */                                                       
        Say   memvar 'found in' lib.search "(Lastupd "ZLM4DATE")"               
        Queue memvar 'found in' lib.search "(Lastupd "ZLM4DATE")"               
      End                                                                       
    End                                                                         
    Else do  /* no match found, or no more in list */                           
      Address ISPEXEC "LMCLOSE DATAID("FINDMOD1")"                              
      Address ISPEXEC "LMFREE DATAID("FINDMOD1")"                               
      Leave /* leave loop, go search next library if any */                     
    End /* else do */                                                           
  End  /* do forever */                                                         
End /* do SEARCH */                                                             
If FOUND = 'NO' then do                                                         
  Say   NAME 'was not found in any library'                                     
  Queue NAME 'was not found in any library'                                     
End                                                                             
/*********************************************************************/         
/* Browse results                                                    */         
/*********************************************************************/         
/* BROWSE_ISPF:  Browse output if ISPF is active  */                            
Queue ''  /* null queue to end stack   */                                       
Address ISPEXEC "CONTROL ERRORS RETURN"                                         
Address ISPEXEC "VGET ZENVIR"                                                   
Address TSO                                                                     
prefix = sysvar('SYSPREF')        /* tso profile prefix            */           
uid    = sysvar('SYSUID')         /* tso userid                    */           
If prefix = '' then prefix = uid  /* use uid if null prefix        */           
If prefix <> '' & prefix <> uid then /* different prefix than uid  */           
   prefix = prefix || '.' || uid /* use  prefix.uid                */           
ddnm1 = 'DDO'||random(1,99999)   /* choose random ddname           */           
ddnm2 = 'DDP'||random(1,99999)   /* choose random ddname           */           
junk = msg('off')                                                               
"ALLOC FILE("||ddnm1||") UNIT(SYSALLDA) NEW TRACKS SPACE(2,1) DELETE",          
      " REUSE LRECL(80) RECFM(F B) BLKSIZE(3120)"                               
"ALLOC FILE("||ddnm2||") UNIT(SYSALLDA) NEW TRACKS SPACE(1,1) DELETE",          
      " REUSE LRECL(80) RECFM(F B) BLKSIZE(3120) DIR(1)"                        
junk = msg('on')                                                                
"Newstack"                                                                      
/*************************/                                                     
/* FINDMODP Panel source */                                                     
/*************************/                                                     
If Substr(ZENVIR,6,1) >= 4 then                                                 
  Queue ")PANEL KEYLIST(ISRSPBC,ISR)"                                           
Queue ")ATTR"                                                                   
Queue "  _ TYPE(INPUT)   INTENS(HIGH) COLOR(TURQ) CAPS(OFF)" ,                  
      "FORMAT(&MIXED)"                                                          
Queue "  | AREA(DYNAMIC) EXTEND(ON)   SCROLL(ON)"                               
Queue "  + TYPE(TEXT)    INTENS(LOW)  COLOR(BLUE)"                              
Queue "  @ TYPE(TEXT)    INTENS(LOW)  COLOR(TURQ)"                              
Queue "  % TYPE(TEXT)    INTENS(HIGH) COLOR(GREEN)"                             
Queue "  ! TYPE(OUTPUT)  INTENS(HIGH) COLOR(TURQ) PAD(-)"                       
Queue " 01 TYPE(DATAOUT) INTENS(LOW)"                                           
Queue " 02 TYPE(DATAOUT) INTENS(HIGH)"                                          
Queue " 0B TYPE(DATAOUT) INTENS(HIGH) FORMAT(DBCS)"                             
Queue " 0C TYPE(DATAOUT) INTENS(HIGH) FORMAT(EBCDIC)"                           
Queue " 0D TYPE(DATAOUT) INTENS(HIGH) FORMAT(&MIXED)"                           
Queue " 10 TYPE(DATAOUT) INTENS(LOW)  FORMAT(DBCS)"                             
Queue " 11 TYPE(DATAOUT) INTENS(LOW)  FORMAT(EBCDIC)"                           
Queue " 12 TYPE(DATAOUT) INTENS(LOW)  FORMAT(&MIXED)"                           
Queue ")BODY EXPAND(//)"                                                        
Queue "%BROWSE  @&ZTITLE  / /  %Line!ZLINES  %Col!ZCOLUMS+"                     
Queue "%Command ===>_ZCMD / /           %Scroll ===>_Z   +"                     
Queue "|ZDATA ---------------/ /-------------------------|"                     
Queue "|                     / /                         |"                     
Queue "| --------------------/-/-------------------------|"                     
Queue ")INIT"                                                                   
Queue "  .HELP = ISR10000"                                                      
Queue "  .ZVARS = 'ZSCBR'"                                                      
Queue "  &ZTITLE = 'Mark''s MVS Utilities - FINDMOD'"                           
Queue "  &MIXED = MIX"                                                          
Queue "  IF (&ZPDMIX = N)"                                                      
Queue "   &MIXED = EBCDIC"                                                      
Queue "  VGET (ZSCBR) PROFILE"                                                  
Queue "  IF (&ZSCBR = ' ')"                                                     
Queue "   &ZSCBR = 'CSR'"                                                       
Queue ")REINIT"                                                                 
Queue "  REFRESH(ZCMD,ZSCBR,ZDATA,ZLINES,ZCOLUMS)"                              
Queue ")PROC"                                                                   
Queue "  &ZCURSOR = .CURSOR"                                                    
Queue "  &ZCSROFF = .CSRPOS"                                                    
Queue "  &ZLVLINE = LVLINE(ZDATA)"                                              
Queue "  VPUT (ZSCBR) PROFILE"                                                  
Queue ")END"                                                                    
Queue ""                                                                        
/*                                    */                                        
Address ISPEXEC "LMINIT DATAID(PAN) DDNAME("ddnm2")"                            
Address ISPEXEC "LMOPEN DATAID("pan") OPTION(OUTPUT)"                           
Do queued()                                                                     
   Parse pull panline                                                           
   Address ISPEXEC "LMPUT DATAID("pan") MODE(INVAR)" ,                          
           "DATALOC(PANLINE) DATALEN(80)"                                       
End                                                                             
Address ISPEXEC "LMMADD DATAID("pan") MEMBER(FINDMODP)"                         
Address ISPEXEC "LMFREE DATAID("pan")"                                          
"Delstack"                                                                      
"EXECIO * DISKW" ddnm1 "(FINIS"                                                 
If FOUND = 'NO' then zedsmsg = NAME 'NOT FOUND'                                 
                else zedsmsg = NAME 'WAS FOUND'                                 
zedlmsg = 'FINDMOD - Last updated  on' ,                                        
           LASTUPD ||'. Written by' ,                                           
          'Mark Zelden. Mark''s MVS Utilities -' ,                              
          'http://www.mzelden.com/mvsutil.html'                                 
Address ISPEXEC "LIBDEF ISPPLIB LIBRARY ID("ddnm2") STACK"                      
If FOUND = 'NO' then ,                                                          
  Address ISPEXEC "SETMSG MSG(ISRZ001)"  /* msg - with alarm  */                
Else ,                                                                          
  Address ISPEXEC "SETMSG MSG(ISRZ000)"  /* msg - no alarm    */                
Address ISPEXEC "LMINIT DATAID(TEMP) DDNAME("ddnm1")"                           
Address ISPEXEC "BROWSE DATAID("temp") PANEL(FINDMODP)"                         
Address ISPEXEC "LMFREE DATAID("temp")"                                         
Address ISPEXEC "LIBDEF ISPPLIB"                                                
junk = msg('off')                                                               
"FREE FI("ddnm1")"                                                              
"FREE FI("ddnm2")"                                                              
Exit                                                                            
                                                                                
/*******************************************/                                   
/*  SUB ROUTINES                           */                                   
/*******************************************/                                   
                                                                                
CHECK_MODNAME:                                                                  
If NAME = '' then do                                                            
  Say 'Please enter module name or pattern to find:'                            
  Parse upper pull name                                                         
  Call CHECK_MODNAME                                                            
End                                                                             
If length(NAME) >8  then do                                                     
  Say 'Module name' NAME 'invalid - must be less that 8 chars.'                 
  Say 'Please re-enter module name or pattern to find:'                         
  Parse upper pull name                                                         
  Call CHECK_MODNAME                                                            
End                                                                             
Return                                                                          
                                                                                
GET_LIBNAMES:                                                                   
CHKMBR = sysdsn("'"mbrlib"("member")'")                                         
If  CHKMBR <> 'OK' then do                                                      
  Say ''                                                                        
  Say 'Search list member 'member' does not exist in 'mbrlib                    
  Say ''                                                                        
  Exit 8                                                                        
End                                                                             
junk = msg('off')                                                               
"ALLOC DA('"||mbrlib||"("||member||")') F(LIBLIST) SHR REUSE"                   
"EXECIO * DISKR LIBLIST (STEM LIST. FINIS"                                      
"FREE F(LIBLIST)"                                                               
junk = msg('on')                                                                
Do COUNT = 1 to LIST.0                                                          
  LIBNAME = word(LIST.COUNT,1)                                                  
  If substr(LIBNAME,1,1) = '*' then iterate                                     
  NUMLIBS = NUMLIBS + 1                                                         
  LIB.NUMLIBS = LIBNAME                                                         
End /* do count */                                                              
LIB.0 = NUMLIBS   /* tot libs to search*/                                       
Return                                                                          
                                                                                
GET_LPALNK:                                                                     
CVT      = C2d(Storage(10,4))                /* point to CVT        */          
FMIDNUM  = Storage(D2x(CVT - 32),7)          /* point to fmid       */          
/*                                                                  */          
/* GET LPA LIST                                                     */          
/*                                                                  */          
CVTSMEXT = C2d(Storage(D2x(CVT + 1196),4))  /* point to stg map ext.*/          
CVTEPLPS = C2d(Storage(D2x(CVTSMEXT+56),4)) /* point to stg map ext.*/          
NUMLPA   = C2d(Storage(D2x(CVTEPLPS+4),4))  /* # LPA libs in table  */          
LPAOFF   = 8                                /* first ent in LPA tbl */          
Do I = 1 to NUMLPA                                                              
  LEN = C2d(Storage(D2x(CVTEPLPS+LPAOFF),1)) /* length of entry     */          
  DSN = Storage(D2x(CVTEPLPS+LPAOFF+1),LEN)  /* DSN of LPA library  */          
  LPAOFF = LPAOFF + 44 + 1                   /* next entry in table */          
  NUMLIBS = NUMLIBS + 1                      /* add 1 to tot libs   */          
  LIB.NUMLIBS = DSN                          /* add dsn to stem     */          
End                                                                             
/*                                                                  */          
/* GET LNKLST                                                       */          
/*                                                                  */          
If Substr(FMIDNUM,4,4) < 6602 then do   /* pre os/390 1.2 system?   */          
  CVTLLTA  = C2d(Storage(D2x(CVT + 1244),4))  /* point to lnklst tbl*/          
  NUMLNK   = C2d(Storage(D2x(CVTLLTA+4),4))   /* # LNK libs in table*/          
  LNKOFF   = 8                                /*first ent in LBK tbl*/          
  SETNAME  = ''   /* no LNKLST set for pre OS/390 1.2 systems       */          
  Do I = 1 to NUMLNK                                                            
     LEN = C2d(Storage(D2x(CVTLLTA+LNKOFF),1)) /* length of entry   */          
     DSN = Storage(D2x(CVTLLTA+LNKOFF+1),LEN)  /* DSN of LNK lib    */          
     LNKOFF = LNKOFF + 44 + 1                  /* next entry in tbl */          
     NUMLIBS = NUMLIBS + 1                     /* add 1 to tot libs */          
     LIB.NUMLIBS = DSN                         /* add dsn to stem   */          
  End                                                                           
End                                                                             
Else do  /* OS/390 1.2 and above - PROGxx capable LNKLST            */          
  ASCB     = C2d(Storage(224,4))             /* point to ASCB       */          
  ASSB     = C2d(Storage(D2x(ASCB+336),4))   /* point to ASSB       */          
  DLCB     = C2d(Storage(D2x(ASSB+236),4))   /* point to CSVDLCB    */          
  SETNAME  = Storage(D2x(DLCB + 36),16)      /* LNKLST set name     */          
  SETNAME  = Strip(SETNAME,'T')              /* del trailing blanks */          
  CVTLLTA  = C2d(Storage(D2x(DLCB + 16),4))  /* point to lnklst tbl */          
  LLTX     = C2d(Storage(D2x(DLCB + 20),4))  /* point to LLTX       */          
  NUMLNK   = C2d(Storage(D2x(CVTLLTA+4),4))  /* # LNK libs in table */          
  LNKOFF   = 8                               /*first ent in LLT tbl */          
  Do I = 1 to NUMLNK                                                            
    LEN = C2d(Storage(D2x(CVTLLTA+LNKOFF),1))  /* length of entry   */          
    LKDSN = Storage(D2x(CVTLLTA+LNKOFF+1),LEN) /* DSN of LNK lib    */          
    LNKOFF = LNKOFF + 44 + 1                   /* next entry in LLT */          
    NUMLIBS = NUMLIBS + 1                      /* add 1 to tot libs */          
    LIB.NUMLIBS = LKDSN                        /* add dsn to stem   */          
  End                                                                           
  SETNAME  = ' Set 'SETNAME                                                     
End                                                                             
LIB.0 = NUMLIBS                                /* tot libs to search*/          
Return                                                                          
