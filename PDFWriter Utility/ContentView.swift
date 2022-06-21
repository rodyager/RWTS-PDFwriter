//
//  ContentView.swift
//  PDFWriter Utility
//
//  Created by Rod Yager on 19/6/2022.
//

import SwiftUI

struct ContentView: View {
    @State var filename = "Filename"
    var body: some View {
        VStack{
        Spacer()
        Button("Create PDF Destination Folder") {
            let panel = NSSavePanel()
            panel.title = "Create PDFWriter Destination Folder"
            panel.canCreateDirectories = false
            panel.nameFieldStringValue = "PDFWriter"
            panel.showsTagField = false
            if panel.runModal() == .OK {
                let theOrigURL = NSURL.fileURL(withPath: "/private/var/spool/pdfwriter/\(NSUserName())")
                let theData = try! theOrigURL.bookmarkData(options: [URL.BookmarkCreationOptions.suitableForBookmarkFile], includingResourceValuesForKeys: nil, relativeTo: nil)
                try! URL.writeBookmarkData(theData, to:panel.url!)
                    }
        }.padding()
        Button("Quit"){
            NSApp.terminate(self)
        }.padding()
        }.frame(width:250, height:125 )
            .onAppear{
                NSApp.activate(ignoringOtherApps: true)}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
