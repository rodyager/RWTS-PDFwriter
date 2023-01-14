//
//  ContentView.swift
//  PDFWriter Utility
//
//  Created by Rod Yager on 19/6/2022.
//

import SwiftUI

struct ContentView: View {
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
                let theOrigURL = NSURL.fileURL(withPath: "/private/var/spool/pdfwriter/\(NSUserName())")
                try! FileManager().createSymbolicLink(at: panel.url!, withDestinationURL: theOrigURL)
                    }
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
