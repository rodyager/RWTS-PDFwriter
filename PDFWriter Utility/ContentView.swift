//
//  ContentView.swift
//  PDFWriter Utility
//
//  Created by Rod Yager on 19/6/2022.
//

import SwiftUI

struct ContentView: View {
    @State private var showAlert = false
    @State var errorMessage = ""
    
    var body: some View {
        VStack{
        Spacer()
        Image("Printer")
        Button("Create PDF Destination Folder") {
            let panel = NSSavePanel()
            panel.title = "Create PDFWriter Destination Folder"
            panel.canCreateDirectories = false
            panel.nameFieldStringValue = "PDFWriter"
            panel.showsTagField = false
            if panel.runModal() == .OK {
                let theOrigPath = "/private/var/spool/pdfwriter/\(NSUserName())"
                let theOrigURL = NSURL.fileURL(withPath: theOrigPath)
                do {
                    let fileManager = FileManager()
                    if !fileManager.fileExists(atPath: theOrigPath, isDirectory: nil) {
                        errorMessage = "Print one document using PDFWriter to complete OS setup and try again"
                        try fileManager.createDirectory(atPath: theOrigPath,
                                                        withIntermediateDirectories: true)
                    }
                    errorMessage = "Note the replacing an existing location is not supported"
                    try fileManager.createSymbolicLink(at: panel.url!, withDestinationURL: theOrigURL)
                }
                catch{
                    showAlert = true
                }
                    }
        }.alert(isPresented: $showAlert) {
            Alert(
                title: Text("Save could not be completed"),
                message: Text(errorMessage)
            )
        }
            Button("Reveal Uninstall script"){
                let task = Process()
                task.launchPath = "/usr/bin/open"
                task.arguments = ["/Library/Printers/RWTS/PDFwriter/"]
                task.launch()
            }.padding()
        }.frame(width:250, height:230 )
            .onAppear{
                NSApp.activate(ignoringOtherApps: true)}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
