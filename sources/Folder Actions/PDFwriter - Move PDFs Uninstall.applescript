(*

Uninstall all PDFwriter Folder Actions.

*)

tell application "System Events"
  set theFolder to my GetAlias("/var/spool") -- /var is expanded to /private/var
  if not theFolder is missing value
    set theFolderPath to (the POSIX path of theFolder) & "/pdfwriter"
    repeat with theAction in every folder action whose path starts with theFolderPath
      tell theAction
        delete scripts
      end tell
    end repeat
    delete every folder action whose path starts with theFolderPath
  end if
end tell

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
