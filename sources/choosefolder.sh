#!/bin/bash -e

dir=`dirname $0`

# Choose folder
target=`osascript -e 'set theFolderPath to (the POSIX path of (choose folder with prompt "Choose PDFwriter output folder"))' 2>/dev/null`

# Create symbolic link
mkdir -p ~/Library/"Application Support"/PDFwriter
ln -shf "$target" ~/Library/"Application Support"/PDFwriter/pdfs

# Spool folder must exist so can add Folder Action to it
if [ ! -d "/var/spool/pdfwriter" ]; then
    sudo mkdir /var/spool/pdfwriter
fi

# Install Folder Action
osascript "$dir/Folder Actions/PDFwriter - Move PDFs Install.applescript"

