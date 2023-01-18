# RWTS PDFwriter
&copy; 2016-2023 Rodney I. Yager

An OSX print to pdf-file printer driver

### [![](https://raw.githubusercontent.com/rodyager/RWTS-PDFwriter/master/build/PDFwriter.iconset/icon_256x256.png "Click to download installer pkg") Click to download the installer pkg](https://github.com/rodyager/RWTS-PDFwriter/releases/download/v3.0/RWTS-PDFwriter.pkg)

## About RWTS PDFwriter
**RWTS PDFwriter** is an OSX 11.0+ compatible print driver that enables you to “print” your documents directly to a pdf file. It has similar functionality to [CutePDF](http://www.cutepdf.com) on Windows. 

The provided installer installs a universal binary compatible with both Intel and Apple Silicon processors. 

## Installation and Usage Instructions
Download the installer package by clicking on the printer icon above and install as usual. The installer will open the **PDFWriter Utility** app which lets you create a destination folder for the PDFs you print. (You need to Quit the Utility after creating the destination folder to complete the installation.)

Other users can access this utility to create their own print destination from the ` Options & Supplies ` button for the printer in ` System Preferences > Printers & Scanners  `
    
After installation, your new printer will be ready for use.

### Usage

Simply print your documents using **PDFwriter** as your printer. 

The “printed” PDF files produced will be stored in the directory you created on installation.   `


## Removal instructions
If you want to uninstall **PDFwriter**, open the **PDFWriter Utility** (see above)and click the button to reveal the ` uninstall ` script. When you open this script, you will be asked for your administrative password, after which  **RWTS PDFwriter** will be completely removed from your system.

## Compiling from sources
In the event that you want to compile your own copy, you can clone this repository. 

A signed and notarized product installer can be compiled by executing the script

`   build/buildscript.sh -s "<Your DeveloperID>" -n "<Your Keychain Profile>"   `

Omit the -n if you do not wish to notarize the components, and omit the -s if you do not want to sign the components.

You can create a "Keychain Profile" by generating an app-specific password at https://appleid.apple.com then executing

`   xcrun altool  --username "<Your AppleID>" --password "<Your app-specific password>" --list-providers  ` 

to find your WWDRTeamID. 

Then execute

`   xcrun notarytool store-credentials "<Your Keychain Profile>" --apple-id "<Your AppleID>" --team-id "<Your WWDRTeamID>" --password "<Your app-specific password>”  `

If you have built your own, delete any copies of **PDFWriter Utility** before running your installer, as otherwise, it will be installed over your existing copy and not in the Utilities folder.

As this project is released under GNU GPL License Version 2, you are welcome to make modifications and improvement and incorporate it in your own software, provided you also release your software under the same licensing system. Read the [License](https://raw.githubusercontent.com/rodyager/RWTS-PDFwriter/master/License) for full details.

## History and acknowlegements
RWTS PDFwriter was originally based on [Lisanet PDFWriter](http://sourceforge.net/projects/pdfwriterformac) by Simone Karin Lehmann. Lisanet PDFwriter was, in turn, based on [CUPS-PDF](http://www.cups-pdf.de).
