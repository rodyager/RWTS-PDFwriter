# RWTS PDFwriter
&copy; 2016 Rodney I. Yager

An OSX print to pdf-file printer driver

### [![](https://raw.githubusercontent.com/rodyager/RWTS-PDFwriter/master/sources/PDFwriter.iconset/icon_256x256.png "Click to download installer pkg") Click to download the installer pkg](https://github.com/rodyager/RWTS-PDFwriter/releases/download/v1.99/RWTS-PDFwriter.pkg)

## About RWTS PDFwriter
**RWTS PDFwriter** in an OSX 11.0 compatible print driver that enables you to “print” your documents directly to a pdf file. It has similar functionality to [CutePDF](http://www.cutepdf.com) on Windows.

## Installation and Usage Instructions
Download the installer package by clicking on the printer icon above and install as usual. The installer will open the **PDFWriter Utility** app which lets you create a destination folder for the PDFs you print. Other users can create their own print destination by using the **PDFWriter Utility** app found in 
    `   /Applications/Utilities/
    
After installation, your new printer will be ready for use.

### Usage

Simply print your documents using **PDFwriter** as your printer. 

The “printed” PDF files produced will be stored in the directory you created on installation.   `


## Removal instructions
If you want to uninstall **PDFwriter**, open Terminal.app, type 

`   /Library/Printers/RWTS/PDFwriter/uninstall.sh   `

and press Return. You will be asked for your admin password. After hitting Return, **PDFwriter** will be entirely removed from your system. 

## Compiling from sources
In the event that you want to compile your own copy, you can clone this repository.  The product installer can then be compiled by executing the script

`   sources/buildscript.sh   `

If you have a DeveloperID, a signed product can be compiled by running 

`   sources/buildscript.sh -s "<Your DeveloperID>"   `

As this project is released under GNU GPL License Version 2, you are welcome to make modifications and improvement and incorporate it in your own software, provided you also release your software under the same licensing system. Read the [License](https://raw.githubusercontent.com/rodyager/RWTS-PDFwriter/master/License) for full details.

## History and acknowlegements
RWTS PDFwriter is closely based on [Lisanet PDFWriter](http://sourceforge.net/projects/pdfwriterformac) by Simone Karin Lehmann. Lisanet PDFwriter was, in turn, based on [CUPS-PDF](http://www.cups-pdf.de).
