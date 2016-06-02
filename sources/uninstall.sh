#!/bin/sh

# uninstall.sh
# unistall RWTS PDFwriter
#
# Created by Simone Karin Lehmann on 30.08.10.
# Copyright 2010 Simone Karin Lehmann. All rights reserved.
# Modified 2016 Rodney I. Yager

sudo rm /Library/Printers/RWTS/PDFwriter/*
sudo rm /usr/libexec/cups/backend/pdfwriter
sudo rm /Library/Printers/PPDs/Contents/Resources/RWTS\ PDFwriter.gz


sudo rmdir /Library/Printers/RWTS/PDFwriter
sudo rmdir /Library/Printers/RWTS

sudo pkgutil --forget au.rwts.pdfwriter 
