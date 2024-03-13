//ANDREWJC JOB  CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//STEP1    EXEC ASMACLG
//SYSIN    DD   *
         PRINT NOGEN
*---------------------------------------------------------------------*
* Search for invalid 0E in a PDS                                      *
* Andrew Jan  20/Jun/2012                                             *
*---------------------------------------------------------------------*
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

PDSUKEYW CSECT
         STM   R14,R12,12(R13)      USE R13 AS BASE AS WELL AS
         LR    R2,R13               REG-SAVE AREA
         BALR  R12,0
         BAL   R13,76(R12)
SAVREG   DS    18F
         USING SAVREG,R13
         ST    R2,4(R13)
         ST    R13,8(R2)
*
D        USING IHADCB,INFILE        input dcb
I        USING INFMJFCB,JFCBI       JFCB DSECT FOR INPUT
*
*---MAINSTREAM------------------------------------*
*
        BAL    R6,RDJFCB            READ JFCB INTO PROG AREA
*
        BAL    R6,OPEN_DIR          OPEN DIRECTORY
*
        B      GET_MEMBER_NAME   GO GET MEMBER NAME TO TEMP STOR.
*
FINISH  EQU    *
        BAL    R6,CLOSE_DIR         CLOSE FILES
*
        B      RETURN               RETURN TO SYSTEM
*
*-------------------------------------------------------*
*
RDJFCB  EQU    *
*
        RDJFCB  INFILE             READ IN THE JFCB
        LTR   R15,R15              CHK DD STMT IN JCL
        BNZ   NODD                 DD STMT MISSING
*
        BR    R6
*
NODD    EQU    *
        ABEND  901                 ABNORMAL
*
*-------------------------------------------------------*
*
OPEN_DIR   EQU  *
         OPEN  (DIR,INPUT,PRINT,OUTPUT)
         BR    R6
*
*-------------------------------------------------------*
*
GET_MEMBER_NAME  EQU  *
*
*
ONE_MORE_BLOCK  EQU  *
*
         READ  DECB,SF,DIR,DIRAREA,256   READ A DIR. BLK.
         CHECK DECB                         CHECK
*
         LA    R3,DIRAREA            R3 LOCATE AT DIRAREA
         LH    R5,0(0,R3)            PUT LEN. COUNT TO R5
         AR    R5,R3                 GET THE LAST USED -
         BCTR  R5,0                  - ADDR. FOR BXLE
         LA    R3,2(0,R3)            SKIP THE COUNT
*
NEXT_ITEM  EQU  *
*
        CLC   0(8,R3),BINONES       END OF DIR. ?
        BE    FINISH                OK, GO BACK.
*
        MVC   MEMBER,0(R3)          MOV 8 BYTE MEMBER NAME
*
        BAL   R7,MDFYJFCB           MODIFY JFCB WIZ NEXT DSN
*
        MVC   BUFFER,BLANKS         print the member name
        MVC   BUFFER(8),MEMBER      print the member name
        PUT   PRINT,BUFFER          print the member name
*
        BAL   R7,OPEN_MEM           OPEN FILES
*
        STM   R3,R5,SREG345         save registers 3 4 5
        B     GO_PROCESS            GO GET MEMBER THEN PRCOESS

ENDFILE EQU   *
        LM    R3,R5,SREG345         load registers 3 4 5
        BAL   R7,CLOSE_MEM          CLOSE MEMBER
*
        XR    R4,R4                 CLEAR R4 FOR IC
        IC    R4,11(0,R3)           GET USERDATA-
        N     R4,=X'0000001F'       - LENG. IN HALFWORD (5 BITS)
        AR    R4,R4                 TRANS. TO BYTE
        LA    R4,12(0,R4)           PLUS LEN. OF NAME(8)+TTR(3)+C(1)
*                                   R4 : STEP LEN. R5 : END-ADDR.
        BXLE  R3,R4,NEXT_ITEM       LOOP UNTIL REACH END-ADDR.
        B     ONE_MORE_BLOCK        GET ANOTHER DIR BLOCK
*
*-------------------------------------------------------*
*
MDFYJFCB EQU   *
        MVC   I.JFCBELNM,MEMBER      MOVE IN MEMBER NAME
        OI    I.JFCBIND1,JFCPDS      IND AS A PDS

        BR    R7
*
*-------------------------------------------------------*
*
OPEN_MEM  EQU  *
         OPEN  (INFILE,UPDAT),TYPE=J   OPEN AS A JFCB SPCFIED

         BR    R7
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
CLOSE_MEM  EQU   *
         CLOSE INFILE              CLOSE FILES
         BR    R7
*
*--------------------------------------------------------*
*
CLOSE_DIR  EQU  *
         CLOSE DIR                 CLOSE FILES
         CLOSE PRINT               CLOSE OUTPUT
         BR    R6
*
*--------------------------------------------------------*
*
RETURN   EQU   *
         L     R13,4(R13)
         RETURN (14,12),RC=0        BACK TO CALLER
*
*--------------------------------------------------------*
*
         LTORG
*
SREG345  DS    3F             save area for reg3
*
*--------------------------------------------------------*
*
JFCBI    DS    44F
JFCBPTRI DC    X'87'
         DC    AL3(JFCBI)

*
*--------------------------------------------------------*
*
DIRAREA  DS    CL256           WORK AREA FOR A 256-BYTE BLOCK OF DIR
*
BINONES  DC    8XL1'FF'        INDICATE THE END OF DIR.
*
MEMBER   DS    CL8
*
BUFFER   DS    CL80
         ORG


BLANKS   DS    0CL90
         DC    90C' '

FLAG     DS    X
         ORG   FLAG
F_UPRT   DS    0XL(B'10000000')  IND. ANY UNPRINTABLE CHAR FOUND.
F_DBCS   DS    0XL(B'01000000')  IND. there is a shift-out
         ORG


*
*
*--------------------------------------------------------*
*
DIR    DCB DSORG=PS,DDNAME=SYSUT1,MACRF=R,RECFM=U
INFILE DCB DSORG=PS,DDNAME=SYSUT1,MACRF=GL,EODAD=ENDFILE,EXLST=JFCBPTRI
PRINT  DCB DSORG=PS,DDNAME=PRINT,MACRF=PM,LRECL=80
*
        DSECT
        IEFJFCBN         ADDRESSIBILITY
*
        END
/*
//G.SYSUT1  DD  DSN=AAAAA.BBBBBBBB.CCCCC,DISP=SHR
//G.PRINT   DD  SYSOUT=*
//
