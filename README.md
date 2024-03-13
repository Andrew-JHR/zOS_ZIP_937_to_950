# A ZIP tool translating CCSID 937 to 950 for z/OS

This is an alteration of Info-ZIP's Zip by Andrew Jan, but based on an earlier version: 'Copyright (c) 1990-1999 Info-ZIP'  

For a most current version of Info-ZIP's Zip source code, please refer to https://infozip.sourceforge.net/

The license of Info-ZIP's Zip is at https://infozip.sourceforge.net/license.html 

This tool can be used for any z/OS shop, in particular, whose CCSID is the double-byte 937 code, or Traditional Chinese character code set. 
By using the argument: '-a', the text source data's EBCDIC single bytes and 937 double bytes will be translated into ASCII and 950 (Big5) respectively during the zipping process.

Updated files:
1. ZIPUP.C
   Code was updated to support DBCS code conversion: Shift-in: 0x0e and Shift-out: 0x0f are used to determine if a block of bytes is Single or Double.
   Including a new header: dbcsh2p.h 
   
   #ifdef MVS
   #include "dbcsh2p.h"
      char odd = 'N'   ;   /* andrewj incomplete dbcs*/
   #endif /* ?MVS */
   
2. ZIP.C
   A small change: 'printf("Translating to ASCII or BIG5 if any...\n");' to indicate that there is also DBCS code conversion.  
    
Newly Added file: 
1. dbcsh2p.h: an array of 65536 bytes is defined as 'const unsigned char dbcsh2p[65536]'

Fixing any inconsistent of invalid pair of 0x0e and 0x0f before the zipping:
Sometimes the source text data may contain inconsistent shift-in/shift-out pairs or unexpected binary codes of 0x0e or 0x0f on each record. As a result, the zip program is confused to translate the data into wrong data codes.
To overcome this, the following two programs in Assembler may be run in front of the zip step to pick up and fix these kinds of errors.
1. CHK0E0F.ASM is used to scrutinize a list -- usually a file containing a list of files to be checked -- of sequential files.
2. CHK0EPDS.ASM is used against a PDS (Partitioned Data Set) whose all members are checked and fixed if there are any invalid 0x0e/0x0f pairs.

JCL files:
1. CMPLZIP.JCL is used to compile all the c programs.
2. LNKZIP.JCL is used to link-edit all the modules from step 1 above.
3. ZIPJCL.JCL is the sample JCL regarding how to execute the zip program. Note that the 'a' in the argument " PARM='-a ...' is lower case, NOT '-A'.
4. ZIPLSTSEQ.JCL is the sample JCL that combines both CHK0E0F and ZIP a list of sequential files.

REXX file:
1. ZIPPDS.REXX can be used to zip a bunch of PDS data sets:
   '%XX ANDREWJ.SOURCE ASM EXEC JCL COB MAC PLI C' means to zip all together ANDREWJ.SOURCE.ASM/ANDREWJ.SOURCE.EXEC/ANDREWJ.SOURCE.JCL/ANDREWJ.SOURCE.COB/
   ANDREWJ.SOURCE.MAC/ANDREWJ.SOURCE.PLI/ANDREWJ.SOURCE.C.  
   
Sampe list:
1. LSTSEQ.JCL is the sample file for use with both CHK0E0F and ZIP.

c programs:
13 files: CMSMVS.C, CRC32.C, CRCTAB.C CRYPT.C DEFLATE.C, FILEIO.C, GLOBAL.C, MVC.C, TREES.C, UTIL.C, ZIP.C, ZIPFILE.C, ZIPUP.C    
  
Header files:
14 files: API.H, CMSMVS.H, CRYPT.H, CSTAT.H, DBCSH2P.H, EBCDIC.H, MVS.H, REVISION.H, STAT.H, TAILOR.H, TTYIO.H, ZIP.H, ZIPERR.H, ZIPUP.H    
