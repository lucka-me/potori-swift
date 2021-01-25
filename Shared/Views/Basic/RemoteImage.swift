//
//  RemoteImage.swift
//  Potori
//
//  Created by Lucka on 30/12/2020.
//

import SwiftUI

#if os(macOS)
typealias UNImage = NSImage
#else
typealias UNImage = UIImage
#endif

struct RemoteImage: View {
    
    @Environment(\.openURL) private var openURL
    @ObservedObject private var remoteImageModel: RemoteImageModel

    private let url: String
    private let sharable: Bool
    
    init(_ url: String, sharable: Bool = false) {
        remoteImageModel = RemoteImageModel(url)
        self.url = url
        self.sharable = sharable
    }
    
    var body: some View {
        if sharable {
            content.contextMenu { menuItems }
        } else {
            content
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if let solidImage = remoteImageModel.image {
            #if os(macOS)
            Image(nsImage: solidImage)
                .resizable()
            #else
            Image(uiImage: solidImage)
                .resizable()
            #endif
        } else {
            ProgressView()
                .frame(width: 100, height: 100, alignment: .center)
                .padding()
        }
    }
    
    @ViewBuilder
    private var menuItems: some View {
        Button(action: open) {
            Label("view.image.open", systemImage: "safari")
        }
        if (remoteImageModel.image != nil) {
            #if os(macOS)
            Button(action: copy) {
                Label("view.image.copy", systemImage: "doc.on.doc")
            }
            #else
            Button(action: share) {
                Label("view.image.share", systemImage: "square.and.arrow.up")
            }
            #endif
        }
    }
    
    private func open() {
        openURL(URL(string: url)!)
    }
    
    #if os(macOS)
    private func copy() {
        guard let solidImage = remoteImageModel.image else {
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setData(solidImage.tiffRepresentation, forType: .tiff)
    }
    #else
    private func share() {
        guard let solidImage = remoteImageModel.image else {
            return
        }
        let shareSheet = UIActivityViewController(activityItems: [ solidImage ], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(shareSheet, animated: true, completion: nil)
    }
    #endif
}

#if DEBUG
struct RemoteImage_Previews: PreviewProvider {
    static var previews: some View {
        RemoteImage("https://s.gravatar.com/avatar/f03d18971cd558e09f51ad19923bf077?s=180")
    }
}
#endif

fileprivate final class RemoteImageModel: ObservableObject {
    
    @Published var image: UNImage?
    
    init(_ url: String) {
        guard let taskUrl = URL(string: url) else {
            return
        }
        let request = URLRequest(url: taskUrl, cachePolicy: .returnCacheDataElseLoad)
        URLSession.shared.dataTask(with: request) { (data, _, _) in
            guard let solidData = data else {
                return
            }
            DispatchQueue.main.async {
                guard let remoteImage = UNImage(data: solidData) else {
                    return
                }
                self.image = remoteImage
            }
        }
        .resume()
    }
}
