#!/bin/bash

# buildscript.sh
# builds RWTS PDFwriter installer package
#
# Created by Rodney I. Yager on 27.05.16
# Copyright 2016 Rodney I. Yager. All rights reserved

signstring=""

while getopts s: opt; do
	case ${opt} in
	   s)
		signstring=${OPTARG}
		;;
	   *)  
		echo "usage: buildscript [-s \"<your signing identity>\"]"
		exit 0
		;;
	esac
done

cd "$(dirname "$0")"
echo "#### making directory structure"
mkdir temp temp/pkgroot
cd temp
mkdir -m 775 pkgroot/Library pkgroot/Library/Printers pkgroot/Library/Printers/RWTS 
mkdir -m 755 pkgroot/Library/Printers/RWTS/PDFwriter pkgroot/Library/Printers/PPDs pkgroot/Library/Printers/PPDs/Contents pkgroot/Library/Printers/PPDs/Contents/Resources pkgroot/Users 
mkdir -m 775 pkgroot/Users/Shared
mkdir resources scripts 

echo "#### populating directory structure"

iconutil -c icns -o pkgroot/Library/Printers/RWTS/PDFwriter/PDFwriter.icns ../PDFwriter.iconset
cp ../PDFwriterFolder.icns pkgroot/Library/Printers/RWTS/PDFwriter/
clang -Oz -o pkgroot/Library/Printers/RWTS/PDFwriter/pdfwriter -framework appkit ../pdfwriter.m
cp ../uninstall.sh pkgroot/Library/Printers/RWTS/PDFwriter/uninstall.sh
gzip -c ../RWTS\ PDFwriter.ppd > pkgroot/Library/Printers/PPDs/Contents/Resources/RWTS\ PDFwriter.gz
ln -s  /var/spool/pdfwriter pkgroot/Users/Shared/PDFwriter

chmod 700 pkgroot/Library/Printers/RWTS/PDFwriter/pdfwriter
chmod 755 pkgroot/Library/Printers/RWTS/PDFwriter/uninstall.sh           # will be root:admin 750 after postinstall, but this will be ok if permissions are "repaired"
chmod 644 pkgroot/Library/Printers/PPDs/Contents/Resources/RWTS\ PDFwriter.gz

cp ../PDFWriter.iconset/icon_256x256.png resources/background.png
cp ../../License resources/
cp ../postinstall ../preinstall scripts/

echo "#### building installer package"

pkgbuild --root pkgroot --identifier au.rwts.pdfwriter --ownership recommended --scripts scripts --version 1.0 pdfwriter.pkg

echo "#### building distribution file"
productbuild --synthesize --resources resources  --product ../requirements  --package pdfwriter.pkg distribution.dist

sed -i "" '3 a\ 
\    <title>RWTS PDFwriter</title>
' distribution.dist
sed -i "" '4 a\
\    <background file="background.png" alignment="bottomleft" scaling="none"/>
' distribution.dist
sed -i "" '5 a\
\    <license file="License"/>
 ' distribution.dist

echo "#### building product"
productbuild --distribution distribution.dist --resources resources --product requirements  temp.pkg


# Have to add to installer separately as productbuild can't handle rtfd resources
pkgutil --expand temp.pkg  temp-expanded
sed -i "" '6 a\
\    <readme file="README.rtfd"  />
 ' temp-expanded/Distribution

cp -r ../README.rtfd temp-expanded/Resources/
pkgutil --flatten temp-expanded temp2.pkg

if [ "$signstring" != "" ]; then echo "#### signing product"; productsign --sign "$signstring" temp2.pkg  ../../RWTS-PDFwriter.pkg
else mv temp2.pkg ../../RWTS-PDFwriter.pkg; fi

echo "#### cleaning up"
cd ..
rm -r temp
exit 0
