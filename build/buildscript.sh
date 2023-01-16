#!/bin/bash

# buildscript.sh
# builds RWTS PDFwriter installer package
#
# Created by Rodney I. Yager on 27.05.16
# Copyright 2016-2022 Rodney I. Yager. All rights reserved

if [ -z "$SDKROOT" ]; then
    export SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
fi
PDFWRITERDIR="pkgroot/Library/Printers/RWTS/PDFwriter"
UTILITIESDIR="pkgroot/Library/Printers/RWTS/Utilities"
PPDDIR="pkgroot/Library/Printers/PPDs/Contents/Resources"
UTILITYAPP="PDFWriter Utility.app"
UTILITYZIP="PDFWriter Utility.zip"
PPDFILE="RWTS PDFwriter"

while getopts "s:n:" opt; do
    case ${opt} in
       s)
        SIGNSTRING=${OPTARG}
        ;;
       n)
        NOTARYSTRING=${OPTARG}
        ;;
       *)
        echo "usage: buildscript [-s \"<your signing identity>\"] [-n \"<your keychain profile>\"]"
        exit 0
        ;;
    esac
done



cd "$(dirname "$0")"

cd ../
echo "### building Utility and printer driver"
xcodebuild -alltargets archive

cd build

echo "### copying binaries from tempory build folder"
cp -r  "Release/$UTILITYAPP"  ./
cp -r "Release/pdfwriter" ./

if [ ! -z "$SIGNSTRING"  ]; then echo "#### notarizing Utility";
    ditto -c -k --keepParent "$UTILITYAPP" "$UTILITYZIP";
    xcrun notarytool submit "$UTILITYZIP" --keychain-profile "$NOTARYSTRING" --wait;
    xcrun stapler staple "$UTILITYAPP;"
    rm "$UTILITYZIP";
fi

echo "### clean up build artefacts"

rm -r EagerLinkingTBDs  PDFWriter.build Release XCBuildData

echo "#### making directory structure"
mkdir pkgroot resources scripts
mkdir -m 775 pkgroot/Library pkgroot/Library/Printers pkgroot/Library/Printers/RWTS
mkdir -m 755 $PDFWRITERDIR pkgroot/Library/Printers/PPDs pkgroot/Library/Printers/PPDs/Contents $PPDDIR
mkdir -m 775 $UTILITIESDIR

echo "#### populating directory structure"
iconutil -c icns -o $PDFWRITERDIR/PDFwriter.icns PDFwriter.iconset
cp pdfwriter  $PDFWRITERDIR/
cp -r "$UTILITYAPP" $UTILITIESDIR/
cp uninstall PDFfolder.png $PDFWRITERDIR/
gzip -c "$PPDFILE".ppd > $PPDDIR/"$PPDFILE".gz

chmod 700 $PDFWRITERDIR/pdfwriter
chmod 755 $PDFWRITERDIR/uninstall    # will be root:admin 750 after postinstall, but this will be ok if permissions are "repaired"
chmod 644 $PPDDIR/"$PPDFILE".gz

cp PDFWriter.iconset/icon_256x256.png resources/background.png
cp ../License resources/
cp postinstall preinstall scripts/

echo "#### building installer package"

pkgbuild --root pkgroot --identifier au.rwts.pdfwriter --ownership recommended --scripts scripts --version 2.0 pdfwriter.pkg > /dev/null

echo "#### building distribution file"
productbuild --synthesize --product requirements  --package pdfwriter.pkg distribution.dist > /dev/null

sed -i '' '3 a\
\    <title>RWTS PDFwriter</title>\
\    <background file="background.png" alignment="bottomleft" scaling="none"/>\
\    <license file="License"/>\
\    <readme file="README.rtfd"  />
' distribution.dist

echo "#### building product"
productbuild --distribution distribution.dist --resources resources product.pkg > /dev/null

# We need to add README to installer separately as productbuild can't handle rtfd resources
pkgutil --expand product.pkg expanded
cp -r README.rtfd expanded/Resources/
pkgutil --flatten expanded RWTS-PDFwriter.pkg

if [ ! -z "$SIGNSTRING"  ]; then echo "#### signing product";
    productsign --sign "$SIGNSTRING" RWTS-PDFwriter.pkg  ../RWTS-PDFwriter.pkg > /dev/null;

    if [ ! -z "$NOTARYSTRING" ]; then echo "#### notarizing product";
        xcrun notarytool submit ../RWTS-PDFwriter.pkg --keychain-profile "$NOTARYSTRING" --wait;
        xcrun stapler staple ../RWTS-PDFwriter.pkg;
    fi
else mv RWTS-PDFwriter.pkg ../RWTS-PDFwriter.pkg; fi

echo "#### cleaning up"
rm -r pkgroot resources scripts expanded *.pkg distribution.dist "$UTILITYAPP" pdfwriter

exit 0
