//
//  ContentView.swift
//  PDFWriter Utility
//
//  Created by Rod Yager on 19/6/2022.
//

import SwiftUI

struct ContentView: View {
    @State private var showAlert = false
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
                do {
                    try FileManager().createSymbolicLink(at: panel.url!, withDestinationURL: theOrigURL)
                }
                catch{
                    showAlert = true
                }
                    }
        }.alert(isPresented: $showAlert) {
            Alert(
                title: Text("Save could not be completed"),
                message: Text("Note that replacing an existing location is not supported.")
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
