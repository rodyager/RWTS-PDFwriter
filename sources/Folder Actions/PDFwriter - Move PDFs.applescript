(*

Moves PDF files from a Folder to ~/Library/Application Support/PDFwriter/pdfs

Can be run in 2 ways:

1. Automatically, by a Folder Action:
   - The Folder Action provides the Folder and the list of newly-added items.
   - All PDFs among those items are moved.

2. Manually, by another script:
   - The Folder path can be passed-in as an argument.
   - All PDFs in the Folder are moved.

*)

(* When run automatically by a Folder Action *)
on adding folder items to theAttachedFolder after receiving theNewItems
  tell application "System Events"
    set theDstFolder to my GetAlias(my GetDestinationPath())
    if not theDstFolder is missing value then
      set theDstFolderPath to the POSIX path of theDstFolder
      repeat with anItem in theNewItems
        if (name extension of anItem) is "pdf" then
          move anItem to theDstFolderPath without replacing
        end if
      end repeat
    end if
  end tell
end adding folder items to

(* When run manually *)
on run argv
  tell application "System Events"
    if (count of argv) > 0 then
      set theSrcFolderPath to item 1 of argv
    else
      set theSrcFolderPath to "/var/spool/pdfwriter/" & (name of the current user)
    end if
    set theSrcFolder to my GetAlias(theSrcFolderPath)
    set theDstFolder to my GetAlias(my GetDestinationPath())
    if not theSrcFolder is missing value and not theDstFolder is missing value then
      set theDstFolderPath to the POSIX path of theDstFolder
      set pdfs to (every file in theSrcFolder whose name extension is "pdf")
      repeat with pdf in pdfs
        move pdf to theDstFolderPath without replacing
      end repeat
    end if
  end tell
end run

on GetDestinationPath()
  tell application "System Events"
    return (the POSIX path of (path to application support folder from user domain)) & "/PDFwriter/pdfs"
  end tell
end GetDestinationPath

(* Checks exists, resolves symlinks *)
on GetAlias(thePath)
  tell application "System Events"
    try
      return alias thePath
    on error
      return missing value
    end try
  end tell
end GetAlias
