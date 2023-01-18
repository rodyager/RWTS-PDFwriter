//
//  main.swift
//  pdfwriter v3.0
//
//  Created by Rod Yager on 18/1/2023.
//

import AppKit
import Darwin

var outDir = "/var/spool/pdfwriter/"
var nobodyName = "anonaymous users"
var folderIconPath = "/Library/Printers/RWTS/PDFwriter/PDFfolder.png"

if ( setuid(0) != 0 ) {
    fputs("pdfwriter cannot be called without root privileges!\n", stderr)
    exit(0)
}

switch CommandLine.argc {
case 1: fputs("file pdfwriter:/ \"Virtual PDF Printer\" \"PDFwriter\" \"MFG:RWTS;MDL:PDFwriter;DES:RWTS PDFwriter - Prints documents as PDF files;CLS:PRINTER;CMD:POSTSCRIPT;\"\n", stderr)
    exit(0)
case 6: break
default: fputs("Usage: pdfwriter job-id user title copies options [file]\n", stderr)
    exit(0)
}

// check that it is actually a PDF file
let stdIn: FileHandle = .standardInput
let prefix:Data
do {
    prefix = try stdIn.read(upToCount: 4)!
}
catch {
    fputs("Application print output unreadable\n", stderr)
    exit(0)
}
if String(data: prefix, encoding: .utf8)! != "%PDF" {
    fputs("Application print output is not compatible\n", stderr)
    exit(0)
}

// Determine who is printing
var user = CommandLine.arguments[2].lowercased()
var passwd: passwd
if let p = getpwnam(user)?.pointee {
    passwd = p
} else {
    passwd = getpwnam("nobody")!.pointee
    user = nobodyName
}

outDir += user

let group = getgrnam("_lp").pointee
setgid(group.gr_gid)
var isDir: ObjCBool = true

if !FileManager.default.fileExists(atPath: outDir, isDirectory: &isDir) {
    // create output Directory, setting icon, ownership and permissions.
    umask(0o022)
    do {
        try FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
    }
    catch {
        fputs("Unable to create output directory at \(outDir)\n", stderr)
        exit(0)
    }
    NSWorkspace.shared.setIcon(NSImage(byReferencingFile: folderIconPath), forFile: outDir, options: .excludeQuickDrawElementsIconCreationOption)
    let mode = user == nobodyName ? mode_t(0o777) : mode_t(0o700)
    chmod(outDir, mode)
    chown(outDir, passwd.pw_uid, passwd.pw_gid)
}

var title = CommandLine.arguments[3]

// sanititize title
if title == "(stdin)" {title = "Untitled" }
let illegalFileNameCharacters = NSCharacterSet(charactersIn: "/\\?%*|\"<>\r\n: ") as CharacterSet
title = (title as NSString).components(separatedBy: illegalFileNameCharacters).filter{!$0.isEmpty}.joined(separator: " ")
title = (title as NSString).deletingPathExtension

// make sure we have a unique filename
var outFile = outDir + "/" + title + ".pdf"
var fileIndex = 0
while ( FileManager.default.fileExists( atPath: outFile )) {
    fileIndex += 1
    outFile = outDir + "/" + title + "-\(fileIndex).pdf"
}

umask(0o077)
// create output file and set appropriate ownership and permissions
FileManager.default.createFile(atPath: outFile, contents: nil )
chown(outFile, passwd.pw_uid, passwd.pw_gid)
let mode = user == nobodyName ? mode_t(0o666) : mode_t(0o600)

chmod(outFile, mode)

let handle = FileHandle(forWritingAtPath: outFile)!

handle.write(prefix)
while (true ) {
    let data = stdIn.availableData
    if data.isEmpty { break}
    handle.write(data)
}

exit(0)



