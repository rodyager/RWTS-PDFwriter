/* pdfwriter.m
 *
 * (c) 2016 Rodney I. Yager
 *  GPL version 2 or later
 *
 *  Principal change from earlier versions in the addition of an icon to the user spool folder.
 *
*/

/* pdfwriter.c
 *
 * PDFwriter is a CUPS backend for Mac OS X to save a document as PDF file
 * using the standard printing dialog
 *
 * (c) 2010 by Simone Karin Lehmann, < skl at lisanet dot de >
 * GPL version 2 or later
 *
 * This source is a heavily patched version of CUPS-PDF
 * For more details see the ChangeLog file.
 *
*/ 
/* cups-pdf.c -- CUPS Backend (version 2.5.0, 2009-01-26)
   08.02.2003, Volker C. Behr
   Experimentelle Physik V, Universitaet Wuerzburg 
   behr@physik.uni-wuerzburg.de
   http://www.cups-pdf.de

   This code may be freely distributed as long as this header 
   is preserved. 

   This code is distributed under the GPL.
   (http://www.gnu.org/copyleft/gpl.html)

   ---------------------------------------------------------------------------

   Copyright (C) 2003-2009  Volker C. Behr

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

   ---------------------------------------------------------------------------
  
   If you want to redistribute modified sources/binaries this header
   has to be preserved and all modifications should be clearly 
   indicated.
   In case you want to include this code into your own programs 
   I would appreciate your feedback via email.

  
   HISTORY: see ChangeLog in the parent directory of the source archive
*/

#include <time.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <stddef.h>
#include <pwd.h>
#include <grp.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#import <AppKit/AppKit.h>

#include "pdfwriter.h"

extern int errno;

static FILE *logfp=NULL;

#ifndef LOGTYPE
#define LOGTYPE 3
#endif

static void _set_defaults() {
    conf.anondirname = "anonymous users";
    conf.anonuser = "nobody";
    conf.grp = "_lp";
    conf.log = "/var/log/cups";
    conf.outdir = "/var/spool/pdfwriter";
    conf.cut = 4;
    conf.truncate = 64;
    conf.logtype = LOGTYPE;
    conf.lowercase = 1;
    return;
}

static void log_event(short type, char message[], char *detail) {
    time_t secs;
    char ctype[8], *timestring;
    
    if (strlen(conf.log) && (type & conf.logtype)) { 
        time(&secs);
        timestring=ctime(&secs);
        timestring[strlen(timestring)-1]='\0';
        
        if (type == CPERROR) 
            sprintf(ctype, "ERROR");
        else if (type == CPSTATUS)
            sprintf(ctype, "STATUS");
        else
            sprintf(ctype, "DEBUG");
        if (detail != NULL)  {
            while (detail[strlen(detail)-1] == '\n') 
                detail[strlen(detail)-1]='\0';
            fprintf(logfp,"%s  [%s] %s (%s)\n", timestring, ctype, message, detail);
            if ((conf.logtype & CPDEBUG) && (type & CPERROR)) 
                fprintf(logfp,"%s  [DEBUG] ERRNO: %d\n", timestring, errno);
        }
        else
            fprintf(logfp,"%s  [%s] %s\n", timestring, ctype, message);
    }
    return;
}


static int create_dir(char *dirname, int nolog) {
    struct stat fstatus;
    char buffer[BUFSIZE],*delim;
    int i;
    
    while ((i=strlen(dirname))>1 && dirname[i-1]=='/')
        dirname[i-1]='\0';
    if (stat(dirname, &fstatus) || !S_ISDIR(fstatus.st_mode)) {
        strncpy(buffer,dirname,BUFSIZE);
        delim=strrchr(buffer,'/');
        if (delim!=buffer)
            delim[0]='\0';
        else
            delim[1]='\0';
        if (create_dir(buffer,nolog)!=0)
            return 1;
        stat(buffer, &fstatus);
        if (mkdir(dirname,fstatus.st_mode)!=0) {
            if (!nolog)
                log_event(CPERROR, "failed to create directory", dirname);
            return 1;
        }
        else
            if (!nolog)
                log_event(CPSTATUS, "directory created", dirname);
        
        if (chown(dirname,fstatus.st_uid,fstatus.st_gid)!=0)
            if (!nolog)
                log_event(CPDEBUG, "failed to set owner on directory (non fatal)", dirname);
    }
    return 0;
}
    
static int init() {
    struct stat fstatus;
    struct group *group;
    cp_string logfile;
    
    _set_defaults();

    umask(0077);
    
    group=getgrnam(conf.grp);
    if (group) {
        setgid(group->gr_gid);
        log_event(CPDEBUG, "switching to new gid", conf.grp);
    } else {
        log_event(CPERROR, "Grp not found", conf.grp);
        return 1;
    }

    /* we always use a log file */
    
    if (stat(conf.log, &fstatus) || !S_ISDIR(fstatus.st_mode)) {
        if (create_dir(conf.log, 1)) 
            return 1;
        if (chmod(conf.log, 0700))
            return 1;
    }
    snprintf(logfile,BUFSIZE,"%s%s",conf.log,"/pdfwriter_log");
    logfp=fopen(logfile, "a");

    return 0;
}


static int create_userdir(struct passwd *passwd, char *userdirname) {
    struct stat fstatus;
    mode_t mode;
    int size;
    char *dirname;

    size = strlen(conf.outdir) + strlen(userdirname) + 2;
    dirname = calloc(size, sizeof(char));
    if (dirname == NULL) 
        return 1;
    snprintf(dirname, size, "%s/%s", conf.outdir, userdirname);
    
    umask(0000);
    if (stat(dirname, &fstatus) || !S_ISDIR(fstatus.st_mode)) {
        if (create_dir(dirname, 0)) {
            log_event(CPERROR, "failed to create output directory", dirname);
            free(dirname);
            return 1;
        }
    
        // set icon for userdirname
        [NSWorkspace.sharedWorkspace setIcon:[NSImage.alloc initByReferencingFile:@"/Library/Printers/RWTS/PDFwriter/PDFfolder.icns"] forFile:[NSString stringWithUTF8String:dirname] options:NSExcludeQuickDrawElementsIconCreationOption];
        

        log_event(CPDEBUG, "output directory created", dirname);
        
        if (!strcmp(passwd->pw_name, conf.anonuser)) 
            mode = (mode_t)(0777);
        else 
            mode = (mode_t)(0700);
        
        
        if (chmod(dirname, mode)) {
            log_event(CPERROR, "failed to set mode on output directory", dirname);
            free(dirname);
            return 1;
        }
            
        if (chown(dirname, passwd->pw_uid, passwd->pw_gid)) {
            log_event(CPERROR, "failed to set owner for output directory", passwd->pw_name);
            free(dirname);
            return 1;
        }
        log_event(CPDEBUG, "owner set for output directory", passwd->pw_name);
    }
        
    umask(0077);
    free(dirname);
    return 0;
}


static void replace_string(char *string) {
    int i;
    
    log_event(CPDEBUG, "removing special characters from title", string);
    for (i = 0; i < strlen(string); i++) 
        if ( string[i] == ':' )
            string[i] = ' ';
    return;
}

static int preparetitle(char *title) {
    char *cut;
    
    if (title != NULL) {
        log_event(CPDEBUG, "removing trailing newlines from title", title);
        while (strlen(title) && ((title[strlen(title)-1] == '\n') || (title[strlen(title)-1] == '\r')))
            title[strlen(title)-1]='\0';
    }
    if (strlen(title) && title[0]=='(' && title[strlen(title)-1]==')') {
        log_event(CPDEBUG, "removing enclosing parentheses () from full title", title);
        title[strlen(title)-1]='\0';
        memmove(title, title+1, strlen(title));
    }
    cut=strrchr(title, '/');
    if (cut != NULL) {
        log_event(CPDEBUG, "removing slashes from full title", title);
        memmove(title, cut+1, strlen(cut+1)+1);
    }  
    cut=strrchr(title, '\\');
    if (cut != NULL) {
        log_event(CPDEBUG, "removing backslashes from full title", title);
        memmove(title, cut+1, strlen(cut+1)+1);
    }
    cut=strrchr(title, '.');
    if ((cut != NULL) && ((int)strlen(cut) <= conf.cut+1) && (cut != title)) {
        log_event(CPDEBUG, "removing file name extension", cut);
        cut[0]='\0';
    }

    replace_string(title);
        
    if (strlen(title)>conf.truncate) {
        title[conf.truncate]='\0';
        log_event(CPDEBUG, "truncating title", title);
        
        /* cut at word boundries */
        cut = strrchr(title, ' ');
        if ((cut != NULL) && (cut != title)) {
            cut[0] = '\0';
        }
        while (ispunct(title[strlen(title)-1])) {
            title[strlen(title)-1] = '\0';
        }
        
        /* strip trailing spaces */
        while (title[strlen(title)-1] == ' ') {
            title[strlen(title)-1]='\0';
        }
    }
    return strcmp(title, "");
}

static int write_pdf(FILE *fpsrc, char *outfile, struct passwd *passwd) {
    int c;
    FILE *fpdest;
    mode_t mode;
    char buf[4];
    const char *pdfhead = "%PDF";
    
    
    if (fpsrc == NULL) {
        log_event(CPERROR, "failed to open source stream", NULL);
        return 1;
    }
    log_event(CPDEBUG, "source stream ready", NULL);

    fpdest=fopen(outfile, "w");
    if (fpdest == NULL) {
        log_event(CPERROR, "failed to open outfile", outfile);
        fclose(fpsrc);
        return 1;
    }
    log_event(CPDEBUG, "destination stream ready", outfile);
    if (chown(outfile, passwd->pw_uid, -1)) {
        log_event(CPERROR, "failed to set owner for outfile", outfile);
        return 1;
    }
    log_event(CPDEBUG, "owner set for outfile", outfile);
    
    /* check if we read from a PDF and save input stream */
    fread(buf, sizeof(char) , 4, fpsrc);
    if (!strncmp(buf, pdfhead, 4)) {
        fwrite(pdfhead, sizeof(char), 4, fpdest);
        
        /* simply stream input to outfile */
        while ((c = fgetc(fpsrc)) != EOF) 
            fputc(c, fpdest);
    }
    
    if (feof(fpsrc)) 
        clearerr(fpsrc);
    else 
        log_event(CPERROR, "error in creating pdf from input stream", NULL);
    
    
    fclose(fpdest);
    fclose(fpsrc);
    log_event(CPDEBUG, "all data written to outfile", outfile);    

    if (!strcmp(passwd->pw_name, conf.anonuser)) 
        mode = (mode_t)(0666);
    else 
        mode = (mode_t)(0600);
    if (chmod(outfile, mode))
        log_event(CPERROR, "failed to set file mode for PDF file (non fatal)", outfile);
    
    
    return 0;
}

int main(int argc, char *argv[]) {
    char *user, *userdirname, *outfile, *cmdtitle;
    cp_string title="";
    int size, job;
    struct passwd *passwd;
    
    
    if (setuid(0)) {
        fputs("pdfwriter cannot be called without root privileges!\n", stderr);
        return 0;
    }
    
    if (init()) 
        return 5;
    log_event(CPDEBUG, "initialization finished", VERSION);
    
    if (argc==1) {
        printf("file pdfwriter:/ \"Virtual PDF Printer\" \"PDFwriter\" \"MFG:RWTS;MDL:PDFwriter;DES:RWTS PDFwriter - Prints documents as PDF files;CLS:PRINTER;CMD:POSTSCRIPT;\"\n");
    
        return 0;
    }
    if (argc<6 || argc>7) {
        fputs("Usage: pdfwriter job-id user title copies options [file]\n", stderr);
        log_event(CPERROR, "call contained illegal number of arguments", NULL);
        return 0;
    }

    user = argv[2];
    passwd=getpwnam(user);
    
    if (passwd == NULL && conf.lowercase) {
        log_event(CPDEBUG, "unknown user", user);
        for (size=0;size<(int) strlen(argv[2]);size++) 
            argv[2][size]=tolower(argv[2][size]);
        log_event(CPDEBUG, "trying lower case user name", argv[2]);
        passwd=getpwnam(user);
    } 
                    
    if (passwd == NULL) {
        passwd=getpwnam(conf.anonuser);
        if (passwd == NULL) {
            log_event(CPERROR, "username for anonymous access unknown", conf.anonuser);
            if (logfp!=NULL)
                fclose(logfp);
            return 5;
        }
        log_event(CPDEBUG, "unknown user", user);
        userdirname = conf.anondirname;
    } 
    else {
        log_event(CPDEBUG, "user identified", passwd->pw_name);        
        userdirname = user;
    }
    
    
    if (create_userdir(passwd, userdirname)) {
        if (logfp!=NULL)
            fclose(logfp);
        return 5;
    }
    log_event(CPDEBUG, "user information prepared", NULL);
    
    
/* create title of outputfile 
 * as this is a cups backend and it's appended after filtered pdf 
 * by the PPD config *cupsFilter: application/vnd.cups-pdf
 * there's no filename, only cmdtitle is valid
 * Always use filename with a job id prefix.
 */
        
    cmdtitle = argv[3];
    job = atoi(argv[1]);
    
    if (!strcmp(cmdtitle, "(stdin)")) 
        cmdtitle="";
    
    if (!preparetitle(cmdtitle)) {
        snprintf(title, BUFSIZE, "job_%i untitled_document", job);
        log_event(CPDEBUG, "no title found - using default value", title);
    }
    else {
        snprintf(title, BUFSIZE, "job_%i %s", job, cmdtitle);
        log_event(CPDEBUG, "title successfully retrieved", title);
    }

    /* first create the output filename */
    size = strlen(conf.outdir) + strlen(userdirname) + strlen(title) + 7;
    outfile=calloc(size, sizeof(char));
    if (outfile == NULL) {
        fputs("PDFwriter: failed to allocate memory\n", stderr);
        if (logfp!=NULL)
            fclose(logfp);
        return 5;
    }
    snprintf(outfile, size, "%s/%s/%s.pdf", conf.outdir, userdirname, title);
    log_event(CPDEBUG, "output filename created", outfile);
    
    

    if (write_pdf(stdin, outfile, passwd)) {
        free(outfile);
        if (logfp != NULL)
            fclose(logfp);
        return 5;
    }
    log_event(CPDEBUG, "input data read from stdin", NULL);
    
    free(outfile);

    if (logfp!=NULL) {
        fflush(logfp);
        fclose(logfp);
    }
        
    log_event(CPDEBUG, "all memory has been freed", NULL);    
    log_event(CPSTATUS, "PDF creation successfully finished", passwd->pw_name);
    
    return 0;
} 
