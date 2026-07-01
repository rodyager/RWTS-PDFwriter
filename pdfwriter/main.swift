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
var folderIcon = NSImage(byReferencingFile: "/Library/Printers/RWTS/PDFwriter/PDFfolder.png")

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
var prefix = Data()
do {
    while prefix.count < 4 {
        guard let chunk = try stdIn.read(upToCount: 4 - prefix.count), !chunk.isEmpty else { break }
        prefix.append(chunk)
    }
}
catch {
    fputs("ERROR: Application print output unreadable\n", stderr)
    exit(CUPS_BACKEND_CANCEL)
}
if prefix != Data("%PDF".utf8) {
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
    NSWorkspace.shared.setIcon(folderIcon, forFile: outDir, options: .excludeQuickDrawElementsIconCreationOption)
    let mode = user == nobodyName ? mode_t(0o777) : mode_t(0o700)
    chmod(outDir, mode)
    chown(outDir, passwd.pw_uid, passwd.pw_gid)
}

var fileName = (CommandLine.arguments[3].replacingOccurrences(of:"/", with: ":") as NSString).deletingPathExtension
if fileName == "(stdin)" {fileName = "Untitled" }           //   cat /path/to/file | lpr -P PDFwriter    without -J or -T option.
while fileName.utf8.count > 200 { fileName.removeLast() }

// Atomically create a unique output file using O_CREAT|O_EXCL, eliminating the
// check-then-act race where two simultaneous jobs could overwrite each other.
let fileMode = user == nobodyName ? mode_t(0o666) : mode_t(0o600)
umask(0)
var outFile = outDir + "/" + fileName + ".pdf"
var fileIndex = 0
var fd = Darwin.open(outFile, O_CREAT | O_EXCL | O_WRONLY, fileMode)
while fd == -1 && errno == EEXIST {
    fileIndex += 1
    outFile = outDir + "/" + fileName + "-\(fileIndex).pdf"
    fd = Darwin.open(outFile, O_CREAT | O_EXCL | O_WRONLY, fileMode)
}
guard fd != -1 else {
    fputs("ERROR: Unable to create output file at \(outFile)\n", stderr)
    exit(CUPS_BACKEND_CANCEL)
}
let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
chown(outFile, passwd.pw_uid, passwd.pw_gid)

handle.write(prefix)
while (true ) {
    let data = stdIn.availableData
    if data.isEmpty { break}
    handle.write(data)
}

exit(CUPS_BACKEND_OK)
