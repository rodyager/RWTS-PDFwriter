//
//  main.swift
//  pdfwriter 3.1
//
//  Created by Rod Yager on 18/1/2023.
//

import AppKit
import Darwin

var outDir = "/var/spool/pdfwriter/"
var nobodyName = "anonymous users"
var folderIconPath = "/Library/Printers/RWTS/PDFwriter/PDFfolder.png"

func exit(_ code: cups_backend_t) -> Never { exit(Int32(code.rawValue)) }

if ( setuid(0 ) != 0 ) {
    fputs("ERROR: pdfwriter cannot be called without root privileges!\n", stderr)
    exit(CUPS_BACKEND_OK)
}

switch CommandLine.argc {
case 1: fputs("file pdfwriter:/ \"Virtual PDF Printer\" \"PDFwriter\" \"MFG:RWTS;MDL:PDFwriter;DES:RWTS PDFwriter - Prints documents as PDF files;CLS:PRINTER;CMD:POSTSCRIPT;\"\n", stderr)
    exit(CUPS_BACKEND_OK)
case 6: break
default: fputs("Usage: \(CommandLine.arguments[0]) job-id user title copies options [file]\n", stderr)
    exit(CUPS_BACKEND_OK)
}

// check that it is actually a PDF file
let stdIn: FileHandle = .standardInput
let prefix:Data
do {
    prefix = try stdIn.read(upToCount: 4)!
}
catch {
    fputs("ERROR: Application print output unreadable\n", stderr)
    exit(CUPS_BACKEND_CANCEL)
}
if String(data: prefix, encoding: .utf8)! != "%PDF" {
    fputs("ERROR: Application print output is not compatible\n", stderr)
    exit(CUPS_BACKEND_CANCEL)
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
        fputs("ERROR: Unable to create output directory at \(outDir)\n", stderr)
        exit(CUPS_BACKEND_CANCEL)
    }
    NSWorkspace.shared.setIcon(NSImage(byReferencingFile: folderIconPath), forFile: outDir, options: .excludeQuickDrawElementsIconCreationOption)
    let mode = user == nobodyName ? mode_t(0o777) : mode_t(0o700)
    chmod(outDir, mode)
    chown(outDir, passwd.pw_uid, passwd.pw_gid)
}

var fileName = (CommandLine.arguments[3].replacingOccurrences(of:"/", with: ":") as NSString).deletingPathExtension
if fileName == "(stdin)" {fileName = "Untitled" }

// make sure we have a unique filename
var outFile = outDir + "/" + fileName + ".pdf"
var fileIndex = 0
while ( FileManager.default.fileExists( atPath: outFile )) {
    fileIndex += 1
    outFile = outDir + "/" + fileName + "-\(fileIndex).pdf"
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

exit(CUPS_BACKEND_OK)
