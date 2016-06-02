/* pdfwriter.h
 * PDFwriter is a CUPS backend for Mac OS X to save a document as PDF file
 * using the standard printing dialog
 *
 * (c) 2010 by Simone Karin Lehmann, < skl at lisanet dot de >
 * GPL version 2 or later
 *
 * This source is a heavily patched version of CUPS-PDF
 * For more details see the ChangeLog file.
 *
 
 
 cups-pdf.h -- CUPS Backend Header File (version 2.5.0, 2009-01-26)
   16.05.2003, Volker C. Behr
   Experimentelle Physik V, Universitaet Wuerzburg 
   behr@physik.uni-wuerzburg.de
   http://www.cups-pdf.de


   This code may be freely distributed as long as this header 
   is preserved. Changes to the code should be clearly indicated.   

   This code is distributed under the GPL.
   (http://www.gnu.org/copyleft/gpl.html)

   For more detailed licensing information see cups-pdf.c in the 
   corresponding version number.			             */



#define VERSION "1.2.1"

#define CPERROR         1
#define CPSTATUS        2
#define CPDEBUG         4

#define BUFSIZE 128

typedef char cp_string[BUFSIZE];

static struct {    
    char *anondirname;
    char *anonuser;
    char *grp;
    char *log;
    char *outdir;        
    int		cut;
    int     truncate;
    short 	logtype;
    short	lowercase;
} conf;



