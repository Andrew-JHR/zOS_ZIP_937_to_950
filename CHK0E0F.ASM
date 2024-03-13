//ANDREWJX JOB  CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//STEP1    EXEC ASMACLG
//SYSIN    DD   *
         PRINT NOGEN
*------------------------------------------------*
*
         PRINT OFF
         LCLA  &REG
.LOOP    ANOP                              GENERATE REGS.
R&REG    EQU   &REG
&REG     SETA  &REG+1
         AIF   (&REG LE 15).LOOP
         PRINT ON
*
*------------------------------------------------*
*

         DCBD  DSORG=PS             GEN. PS-DCB DSECT

CHK0E0F  CSECT
         USING *,R15              setup addressibility
         STM   R14,R12,12(R13)    save caller's reg values
         LR    R2,R13
         B     CMNTTAIL           skip over the remarks
*
CMNTHEAD EQU   *
         PRINT GEN                print out remarks
         DC    CL8'&SYSDATE'      compiling date
         DC    C' '
         DC    CL5'&SYSTIME'      compiling time
         DC    C'ANDREW JAN'      author
         CNOP  2,4                ensure half word boundary
         PRINT NOGEN              disable macro expansion
CMNTTAIL EQU   *
*
         BALR  R12,0
         BAL   R13,76(R12)
SAVREG   DS    18F
         DROP  R15
         USING SAVREG,R13,R12
         LA    R12,4095             setup 2nd base
         LA    R12,1(R13,R12)       now R12 is R13+X'1000'
         ST    R2,4(R13)
         ST    R13,8(R2)
*
         USING S99RBP,RBPTR         req blk ptr dsect
         USING S99RB,REQBLK         req blk dsect
D        USING IHADCB,INFILE        input dcb
*
*---MAINSTREAM------------------------------------*
*
        BAL    R6,OPEN_OUT          open output
*
        B      FILE_BATCH           go process
*
FINISH  EQU    *
        BAL    R6,CLOSE_OUT         close files
*
        B      RETURN               return to system
*
*-------------------------------------------------------*
*
OPEN_OUT   EQU  *
         OPEN  (PRINT,OUTPUT,REF,INPUT)  open output and file list
         BR    R6
*
*-------------------------------------------------------*
*
FILE_BATCH  EQU  *
*
        GET   REF                  read the file list
        LR    R10,R1               addressibiliy
        LA    R11,1(,R10)          bypass the "'"
        XR    R9,R9                char counter
        LA    R8,45                max allowed
LPINNAME  EQU   *
        CLI   0(R11),C''''         end of string?
        BE    EOFNAME              yes,branch
        LA    R9,1(,R9)            increase the char count
        LA    R11,1(,R11)          next byte
        BCT   R8,LPINNAME             check next
        B     FILE_BATCH           invalid format
EOFNAME EQU   *

        LTR   R9,R9                 chk length
        BZ    FILE_BATCH            invalid name

        STH   R9,NAMELEN            length of the file name
        BCTR  R9,0                  -1 for ex
EXMVC   MVC   DYNNAME(0),1(R10)     template
        EX    R9,EXMVC              move the name

        MVC   BUFFER,BLANKS         clean output area
EXMVC1  MVC   BUFFER(0),1(R10)      template
        EX    R9,EXMVC1             move the name
*
        BAL   R7,OPEN_SEQ           open this file
*
        B     GO_PROCESS            GO process
*
ENDFILE EQU   *
        BAL   R7,CLOSE_SEQ          close this file
*
        B     FILE_BATCH            get next file name
*
*-------------------------------------------------------*
*
*
*-------------------------------------------------------*
*
OPEN_SEQ  EQU  *
** set up SVC99 request-blk
        XC      REQBLK,REQBLK       clear RB
        MVI     S99RBLN,REQBLKLN    set RB len
        MVI     S99VERB,S99VRBAL    set as allocation
        LA      R2,TUPTR001        ld adr of bg of text-unit-ptr lst
        ST      R2,S99TXTPP        sotre that adr into RB

** set up SVC99 request-blk-ptr
        LA      R2,REQBLK          load addr of RB
        ST      R2,S99RBPTR        store RB adr into RB ptr
        OI      S99RBPTR,S99RBPND   turn on high order bit

** issue SVC99
        LA     R1,RBPTR             ld adr of RB ptr for svc99
        DYNALLOC                    svc 99

        LTR    R15,R15             test if ok
        BNZ    Alloc_error         error

        PUT    PRINT,BUFFER        print the file name

        OPEN   (INFILE,UPDAT)      open it
        BR     R7

Alloc_error    EQU   *
        C      R15,=F'4'           chk return code
        BE     unfounded           file not found
        ST     R15,RTNCD           save return code
        B      FINISH              halt

unfounded      EQU   *
        MVC    BUFFER+45(9),=C'Not found' ###########
        PUT    PRINT,BUFFER        print the file name
        B      FILE_BATCH          chk next file

*
*-------------------------------------------------------*
*
GO_PROCESS  EQU   *
         GET   INFILE              GET 1ST RECORD
         LR    R8,R1               ADSBLTY
         TM    D.DCBRECFM,DCBRECV  IS IT VARIABLE RECORD LEN ?
         BNO   PROCESS_FIX         NO, PROCESS FIXED LEN RECORDS

PROCESS_VAR    EQU  *
         LH    R9,0(,R8)           LOAD REC LEN.
         SH    R9,=H'4'            MINUS 4 BYTES(2 FOR LEN,2 RSRVD)
         LA    R8,4(,R8)           STEP OVER THE 4-BYTE FIELD
         B     PROCESS_COMM        GO ON THE COMMON CODE

PROCESS_FIX    EQU  *
         LH    R9,D.DCBLRECL       LOAD REC LEN.

PROCESS_COMM   EQU  *
         NI    F_UPRT,X'FF'-L'F_UPRT  reset the ind.
         NI    F_DBCS,X'FF'-L'F_DBCS  reset the ind.

* save the 1st 80 byte of the record in case we have to print it
         LR    R4,R8             copy move-from address
         LR    R5,R9             copy record length

         MVC   BUFFER,BLANKS     clean output area
         CH    R5,=H'80'         more than 80 ?
         BNH   CHAR_COPY         no branch
         LA    R5,80             maximum length is 80
CHAR_COPY EQU   *
         LR    R3,R5             set the length for mvcl
         LA    R2,BUFFER         set move-to address
         MVCL  R2,R4             copy data to output

*------------------------------------------------*
* loop to check inside the same record *
LOOP_IN_REC    EQU  *

*****    CLI   0(R8),X'20'         put here if also other codes
*****    BNL   CHAR_OK             that cause a xlation problem
*****    CLI   0(R8),X'15'         (EBCDIC -> ASCII or DBCS -> BIG5)
*****    BE    CHAR_OK

         CLI   0(R8),X'0E'         shift-out ?
         BNE   CHK_SHTIN           ok, branch

         TM    F_DBCS,L'F_DBCS     already an open SI ?
         BNO   CHK_SHTOU           no, must be invalid go replace it

         MVI   0(R10),X'40'        the previous SO was a wrong one
         OI    F_UPRT,L'F_UPRT     ind. an update is needed

CHK_SHTOU EQU   *
         OI    F_DBCS,L'F_DBCS     set dbcs ind.
         XR    R11,R11             reset byte count(within SO/SI)
         LR    R10,R8              save this shift-out address
         B     CHAR_OK             branch

CHK_SHTIN EQU   *
         CLI   0(R8),X'0F'         shift-in  ?
         BNE   CHAR_OK             no, branch

         TM    F_DBCS,L'F_DBCS     is there an open SO already ?
         BNO   CHAR_BAD            no, must be invalid SI,go replace it

CHK_DBCS  EQU   *
         NI    F_DBCS,X'FF'-L'F_DBCS reset the ind.(a complete pair)

         N     R11,=A(X'00000001') left only rigthmost bit
         LTR   R11,R11             even or odd ?
         BNZ   CHAR_OK             even, not correct

* both SO & SI are wrong (this pair contains an odd number of bytes)
         MVI   0(R10),X'40'        replace the wrong SO

CHAR_BAD EQU   *
         MVI   0(R8),X'40'         replace the wrong char (or SI)
         OI    F_UPRT,L'F_UPRT     data updated

* next byte ***
CHAR_OK  EQU   *
         LA    R8,1(,R8)           next byte
         LA    R11,1(,R11)         increase the char counter
         BCT   R9,LOOP_IN_REC      go chk each byte thru the entire rec

         TM    F_DBCS,L'F_DBCS     any SO left open ?
         BNO   CHK_UPDAT           no, correct, branch

         MVI   0(R10),X'40'        replace the wrong SO
         OI    F_UPRT,L'F_UPRT     ind. data updated

CHK_UPDAT EQU   *
         TM    F_UPRT,L'F_UPRT     anything updated?
         BNO   GO_PROCESS          no, go check next record

CHAR_NOK  EQU   *
         PUT   PRINT,BUFFER        print it
         PUTX  INFILE   #########  write back the updated one

         B     GO_PROCESS        loop
*
*--------------------------------------------------------*
CLOSE_SEQ  EQU   *
*
        CLOSE  INFILE             close this file
        BR     R7

*
*--------------------------------------------------------*
*
CLOSE_OUT  EQU  *
         CLOSE (PRINT,,REF)          close files
         BR    R6
*
*--------------------------------------------------------*
*
RETURN   EQU   *
         L     R15,RTNCD
         L     R13,4(R13)
         RETURN (14,12),RC=(15)     back to caller
*
*--------------------------------------------------------*
*
         LTORG
*
*--------------------------------------------------------*
*

RTNCD     DC        F'0'        init return code as 0


RBPTR     DS        F
REQBLK    DS        CL(S99RBEND-S99RB)
REQBLKLN  EQU       L'REQBLK

TUPTR001  DS        0F
          DC        A(TUDDNA1)   adr of tu for ddname
          DC        A(TUDSNA1)   adr of tu for dsname
          DC        A(TUDSSA1)   adr of tu for ds status
          DC        X'80'        ind. the last tu adr
          DC        AL3(TUCLSA1)   adr of tu to request unallocation   X
                                   when close file
TUDDNA1   DC        AL2(DALDDNAM)  tu key for ddname
          DC        AL2(1)         number of entries
          DC        AL2(8)         length of ddname
          DC        CL8'SYSUT1'    ddname

TUDSNA1 DC AL2(DALDSNAM),AL2(1)
NAMELEN DS AL2
DYNNAME DS CL44
TUDSSA1 DC AL2(DALSTATS),AL2(1),AL2(1),X'08'   shr
**                                     x'01'   old
**                                     x'02'   mod
**                                     x'04'   new
TUCLSA1 DC AL2(DALCLOSE),AL2(0)



*
BLANKS   DS   0CL80
         DC   80C' '
BUFFER   DS   CL80

FLAG     DS    X
         ORG   FLAG
F_UPRT   DS    0XL(B'10000000')  IND. ANY UNPRINTABLE CHAR FOUND.
F_DBCS   DS    0XL(B'01000000')  IND. there is a shift-out
         ORG

*
*--------------------------------------------------------*
*
*--------------------------------------------------------*
*
INFILE DCB DSORG=PS,DDNAME=SYSUT1,MACRF=GL,EODAD=ENDFILE
PRINT  DCB DSORG=PS,DDNAME=SYSPRINT,MACRF=PM,LRECL=80
REF    DCB DSORG=PS,DDNAME=SYSUT2,MACRF=GL,EODAD=FINISH
*
        IEFZB4D0         gen. dect for req. blk, text unit et.
        IEFZB4D2         gen. table of quates for tu keys.
*
        END
/*
//L.SYSLMOD  DD  DISP=SHR,DSN=ANDREWJ.SOURCE.LMD(CHK0E0F)
//G.SYSUT2   DD  DISP=SHR,DSN=ANDREWJ.SOURCE.JCL(A)
//G.SYSPRINT DD  SYSOUT=*
//
