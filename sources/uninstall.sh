#!/bin/sh

# uninstall.sh
# unistall RWTS PDFwriter
#
# Created by Simone Karin Lehmann on 30.08.10.
# Copyright 2010 Simone Karin Lehmann. All rights reserved.
# Modified 2016 Rodney I. Yager

lpadmin -x pdfwriter

osascript /Library/Printers/RWTS/PDFwriter/"Folder Actions"/"PDFwriter - Move PDFs Uninstall.scpt"
sudo rm /Library/Scripts/"Folder Action Scripts"/"PDFwriter - Move PDFs Install.scpt" 2>/dev/null
sudo rm /Library/Scripts/"Folder Action Scripts"/"PDFwriter - Move PDFs.scpt" 2>/dev/null
sudo rm /Library/Printers/RWTS/PDFwriter/"Folder Actions"/*
sudo rmdir /Library/Printers/RWTS/PDFwriter/"Folder Actions"

sudo rm /Library/Printers/RWTS/PDFwriter/*
sudo rm /usr/libexec/cups/backend/pdfwriter
sudo rm /Library/Printers/PPDs/Contents/Resources/RWTS\ PDFwriter.gz

rm -f ~/Library/"Application Support"/PDFwriter/pdfs 2>/dev/null
rmdir ~/Library/"Application Support"/PDFwriter 2>/dev/null

sudo rmdir /Library/Printers/RWTS/PDFwriter
sudo rmdir /Library/Printers/RWTS

sudo pkgutil --forget au.rwts.pdfwriter
