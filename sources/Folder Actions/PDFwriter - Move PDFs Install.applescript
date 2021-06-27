(*

Install a Folder Action that automatically installs the Move PDFs Folder Action
when a subfolder is created whose name is the current user.

Can be run in 2 ways:

1. Automatically, by a Folder Action:
   - The Folder Action provides the parent Folder and the list of newly-added items.
   - Installs the Move PDFs Folder Action on the subfolder whose name is the current
     user, if found in the newly-added items.

2. Manually, by a user:
   - Installs this script as a Folder Action on /var/spool/pdfwriter
   - Installs the Move PDFs Folder Action on the subfolder whose name is the current
     user, if exists.

*)

(* Run automatically by a Folder Action *)
on adding folder items to theAttachedFolder after receiving theNewItems
  tell application "System Events"
    set theUserName to name of current user
    repeat with anItem in theNewItems
      if kind of anItem is "Folder" and name of anItem is theUserName then
        set theUserFolder to folder theUserName of theAttachedFolder
        my InstallFAUser(theUserFolder)
        exit repeat
      end if
    end repeat
  end tell
end adding folder items to

(* Run manually *)
on run argv
  set theFolder to my GetAlias("/var/spool/pdfwriter")
  if not theFolder is missing value then
    my InstallFARoot(theFolder)
  end if
end run

on InstallFARoot(theFolder)
  tell application "System Events"
    -- Add Folder Action
    my InstallFA(theFolder, "pdfwriter", "PDFwriter - Move PDFs Install.scpt")
    -- Run immediately (to add Folder Action to pre-existing user subfolder)
    set theUserName to name of current user
    if theUserName is in (name of every folder of the theFolder) then
      my InstallFAUser(folder theUserName of theFolder)
    end if
  end tell
end InstallFARoot

on InstallFAUser(theFolder)
  tell application "System Events"
    -- Add Folder Action
    my InstallFA(theFolder, "pdfwriter/" & (name of current user), "PDFwriter - Move PDFs.scpt")
    -- Run immediately (to move any pre-existing PDF files)
    my RunScript("PDFwriter - Move PDFs.scpt", {POSIX path of theFolder})
  end tell
end InstallFAUser

on InstallFA(theFolder, theActionName, theScriptName)
  tell application "System Events"
    -- Global enable any Folder Actions
    if folder actions enabled is equal to missing value or not folder actions enabled then
      set folder actions enabled to true
    end if

    -- Add/replace Folder Action on Folder
    set theFolderPath to (the POSIX path of theFolder)
    delete (every folder action whose path is theFolderPath)
    every folder action whose path is theFolderPath -- Needed to refresh in-memory cache
    set theAction to make new folder action at end of folder actions with properties {name:theActionName, path:theFolderPath, enabled:true}

    -- Add Folder Action Script to Folder Action
    tell theAction
      make new script at end of scripts with properties {name:theScriptName, enabled:true}
    end tell
  end tell
end InstallFA

on RunScript(theScriptName, theParams)
  tell application "System Events"
    set theScriptFolderPath to POSIX path of (container of (path to me))
    set theScriptPath to theScriptFolderPath & "/" & theScriptName
    set theScript to my GetAlias(theScriptPath)
    if not theScript is missing value then
      run script theScriptPath with parameters theParams
    end if
  end tell
end RunScript

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
