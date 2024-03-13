//ANDREWJZ JOB  CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID                       00010000
//STEP1    EXEC PGM=IEBGENER                                            00020000
//SYSPRINT DD  SYSOUT=*                                                 00030000
//SYSUT1   DD  *                                                        00040000
 /* rexx */                                                             00050000
 arg argu                                                               00060000
                                                                        00070000
 /* write job card  */                                                  00080000
 queue "//" || sysvar(sysuid) || "Z  JOB IBM,SP,CLASS=A,MSGCLASS=X,",   00090000
       || "NOTIFY=" || sysvar(sysuid)                                   00100000
 queue "//*"                                                            00110000
 "execio 2 diskw jcllst"                                                00120000
                                                                        00130000
  dsn = word(argu,1) || '.' || word(argu,2)                             00140000
                                                                        00150000
 "del '" || sysvar(sysuid) || ".$$ZZZ' "                                00160000
                                                                        00170000
 dsname  =  sysvar(sysuid) || '.$$ZZZ'                                  00180000
 "alloc fi(fileout) dsn('"dsname"') new dsorg(ps) recfm(f,b) ",         00190000
 || "lrecl(80) space(5,5) tracks release unit(SYSDA)"                   00200000
                                                                        00210000
 queue "//DELZIP   EXEC PGM=IDCAMS"                                     00220000
 queue "//SYSPRINT DD  SYSOUT=*"                                        00230000
 queue "//SYSIN    DD  *"                                               00240000
 queue "  DELETE " || sysvar(sysuid) || ".TEMP.ZIP"                     00250000
 queue "/*"                                                             00260000
 queue "//ZZZ      EXEC PGM=ZIP,PARM='-a DD:OUTPUT -@'"                 00270013
 queue "//STEPLIB  DD   DSN=ANDREWJ.SOURCE.LMD,DISP=SHR"                00275000
 queue "//SYSPRINT DD   SYSOUT=*"                                       00280000
 queue "//OUTPUT   DD   DSN=" || sysvar(sysuid) || ".TEMP.ZIP",         00290000
       || ",DISP=(NEW,CATLG),UNIT=SYSDA,"                               00300000
 queue "// SPACE=(CYL,(150,50),RLSE),"                                  00310000
 queue "// DCB=(DSORG=PS,RECFM=U,BLKSIZE=27998,LRECL=0)"                00320005
 queue "//SYSIN    DD   DSN=" || sysvar(sysuid) || ".$$ZZZ",            00330000
       || ",DISP=SHR"                                                   00340000
 queue "//*"                                                            00350000
  "execio 13 diskw jcllst"                                              00360000
 queue "d:\" || sysvar(sysuid) || "_" || date('S') || "_",              00370000
       || left(time(),2) || substr(time(),4,2) || right(time(),2),      00380000
       || ".zip binary~" || sysvar(sysuid) || ".TEMP.ZIP"               00390000
  "execio 1 diskw srllst"                                               00400000
                                                                        00410000
 call call_rtn;                                                         00420000
                                                                        00430000
 do n = 3 to 15                                                         00440000
    if word(argu,n) = '' then leave                                     00450000
    dsn = word(argu,1) || '.' || word(argu,n)                           00460000
    call call_rtn;                                                      00470000
 end                                                                    00480000
                                                                        00490000
 " execio  0  diskw srllst  (finis "                                    00500000
 " execio  0  diskw jcllst  (finis "                                    00510000
 " execio  0  diskw fileout (finis "                                    00520000
 " free fi(fileout)"                                                    00530000
                                                                        00540000
 exit 0                                                                 00550000
                                                                        00560000
                                                                        00570000
 call_rtn:                                                              00580000
 "alloc fi(pds) dsn('"dsn"') dsorg(ps) lrecl(256) blk(256)" ||,         00590000
 " recfm(f) shr "                                                       00600000
 if rc \= 0  then                                                       00610000
  do                                                                    00620000
     say '### Allocation error ! ###'                                   00630000
     exit 1                                                             00640000
  end                                                                   00650000
                                                                        00660000
 "execio * diskr pds (stem dir. finis"  /* read pds dir */              00670000
 do i = 1 to dir.0                                                      00680000
   usedbytes = c2d(substr(dir.i,1,2))                                   00690000
   index = 3                        /* skip past used bytes*/           00700000
   do while index < usedbytes                                           00710000
     if substr(dir.i,index,8) = 'ffffffffffffffff'x then                00720000
       leave                                                            00730000
     member = substr(dir.i,index,8) /* member name */                   00740000
     index = index + 11            /* skip past name and ttr */         00750000
     indc  = substr(dir.i,index,1)                                      00760000
     len = bitand(indc,'1f'x)      /* isolate user data length */       00770000
     userdata = c2d(len) * 2       /* halfwords to bytes */             00780000
     index = index + userdata + 1  /* skip past user data */            00790000
                                                                        00800000
     queue "'" || dsn || "(" || word(member,1) || ")'"                  00810000
     " execio  1 diskw fileout "                                        00820000
                                                                        00830000
   end /* end of do while */                                            00840000
 end /* end of dir blk loop */                                          00850000
                                                                        00860000
 " free fi(pds) "    /* deallocate file */                              00870000
                                                                        00880000
 return                                                                 00890000
                                                                        00900000
                                                                        00910000
/*                                                                      00920000
//SYSUT2   DD  UNIT=SYSDA,DISP=(NEW,CATLG),                             00930000
//         DSN=&&REXX(XX),                                              00940000
//         DCB=(RECFM=FB,LRECL=80,BLKSIZE=8000),SPACE=(TRK,(1,1,1))     00950000
//SYSIN    DD  DUMMY                                                    00960000
//*                                                                     00970000
//STEP2    EXEC PGM=IKJEFT01                                            00980000
//SYSEXEC  DD  DSN=&&REXX,DISP=(OLD,DELETE)                             00990000
//SRLLST   DD  SYSOUT=*                                                 01000000
//JCLLST   DD  SYSOUT=(A,INTRDR)                                        01010000
//SYSPRINT DD  SYSOUT=*                                                 01020000
//SYSTSPRT DD  SYSOUT=*                                                 01030000
//SYSTSIN  DD  *                                                        01040000
  %XX ANDREWJ.SOURCE ASM EXEC JCL COB MAC PLI C                         01041022
/*                                                                      01060000
//                                                                      01070000

