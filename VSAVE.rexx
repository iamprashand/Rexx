/* REXX */                                          
"ISREDIT MACRO (iMEMBER)"                           
ADDRESS ISREDIT                                     
"(zlast) = LINENUM .ZLAST"                          
"(zfirst) = LINENUM .ZFIRST"                        
"(sSESS,sJUNK) = SESSION"                           
if sSESS ¬= 'VIEW' then                             
   do                                               
   msg = 'VREP does not work within 'sSESS          
   x = setmsg(msg)                                  
   exit                                             
   end                                              
                                                    
if zLast = 0 | zFirst = 0 then                      
   do                                               
   msg = 'VREP does not Cater for empty files'      
   x = setmsg(msg)                                  
   exit                                             
   end                                              
                                                    
"(sLIB,sJUNK,sJUNK1) = DATASET"
sFILE = "'"||sLIB||"'"                  
x = listdsi(sFILE)                      
select                                  
  when sysdsorg = 'PO' then call pdsfile
  when sysdsorg = 'PS' then call seqfile
  otherwise                             
    msg = 'invalid DSORG ' sysdsorg     
    x = setmsg(msg)                     
    exit                                
  end                                   
exit                                    
/*******/                               
SEQFILE:                                
/*******/                                                  
"REPLACE " sFILE " .ZFIRST .ZLAST"                      
if rc = 0 then                                          
   do                                                   
   msg = 'Dataset 'sfile' replaced'                     
   x = setmsg(msg)                                      
   end                                                  
else do                                                 
   Address ispexec "GETMSG MSG("ZERRMSG") SHORTMSG(msg)"
   x = setmsg(msg)                                      
   end                                                  
return                                                  
/*******/                
PDSFILE:                 
/*******/                
if iMEMBER = '' then     
   do                    
   "(iMEMBER) = MEMBER"  
   sSetStats = 'YES'     
   call GetStats         
   end                   
else do                  
   upper iMEMBER         
   "(sLIB,sJUNK,sJUNK1) = DATASET"  
   sSetStats = 'NO' 
   if SYSDSN("'"sLIB"("iMEMBER")'") = "OK" then
     do                                       
     msg = 'Member 'iMEMBER' already exists - not REPLACEd'
       x = setmsg(msg) 
       exit            
     end              
   end                 
"REPLACE " iMEMBER ".ZFIRST .ZLAST"       
if rc = 0 then                            
   do                                     
   msg = 'Member 'iMEMBER' replaced'      
   x = setmsg(msg)                        
   if sSetStats = 'YES' then call SetStats
   end                                    
else do 
   Address ispexec "GETMSG MSG("ZERRMSG") SHORTMSG(msg)"
   x = setmsg(msg)                                      
   end                                                  
return                                                  
/**************************/                            
GetStats:                                               
/**************************/    
                           address ispexec "lminit dataid(s1) dataset("sFile") enq(shr)"      
address ispexec "lmopen  dataid("s1") OPTION(INPUT)"                
address ispexec "lmmfind dataid("s1") MEMBER("iMember") STATS(YES)" 
address ispexec "lmclose dataid("s1")"                                                     kVERS = ZLVERS                     
 kMOD  = ZLMOD                      
 if DATATYPE(kMOD) ¬= 'NUM' then    
    do                              
    sSetStats = 'NO'                
    return                          
    end                             
 if kMOD < 99 THEN kMOD  = kMOD + 1 
 kCDATE = ZLCDATE                   
 kINORC = ZLINORC                   
return                              
/********/                          
SetStats:                           
/********/                                   
address ispexec "lmmstats dataid("s1") MEMBER("iMember") ,             
version("kVERS") MODLEVEL("kMOD") CREATED("kCDATE") INITSIZE("kINORC")"
address ispexec "lmfree  dataid("s1")"                                 
exit
