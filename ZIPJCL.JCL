//ANDREWJA JOB CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//DELETE  EXEC PGM=IDCAMS
//SYSPRINT DD  SYSOUT=*
//SYSIN    DD  *
 DELETE ANDREWJ.TEMP.ZIP
/*
//ZIP      EXEC PGM=ZIP,PARM='-a dd:output -@'
//STEPLIB  DD   DSN=ANDREWJ.SOURCE.LMD,DISP=SHR
//SYSPRINT DD   SYSOUT=*
//CEESNAP  DD   SYSOUT=*
//OUTPUT   DD   DSN=ANDREWJ.TEMP.ZIP,DISP=(NEW,CATLG),UNIT=SYSDA,
// SPACE=(CYL,(50,30)),DCB=(DSORG=PS,RECFM=U,BLKSIZE=27998,LRECL=0)
//SYSIN    DD   *
'ANDREWJ.ZIP.L(CMSMVS)'
'ANDREWJ.ZIP.L(CRCTAB)'
'ANDREWJ.ZIP.L(CRC32)'
'ANDREWJ.ZIP.L(CRYPT)'
'ANDREWJ.ZIP.L(DEFLATE)'
'ANDREWJ.ZIP.L(FILEIO)'
'ANDREWJ.ZIP.L(GLOBALS)'
'ANDREWJ.ZIP.L(LINK)'
'ANDREWJ.ZIP.L(MVS)'
'ANDREWJ.ZIP.L(TREES)'
'ANDREWJ.ZIP.L(UTIL)'
'ANDREWJ.ZIP.L(ZIP)'
'ANDREWJ.ZIP.L(ZIPFILE)'
'ANDREWJ.ZIP.L(ZIPUP)'
