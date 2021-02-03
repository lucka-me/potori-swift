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
    @ObservedObject private var model: RemoteImageModel

    private let url: String
    private let sharable: Bool
    
    init(_ url: String, sharable: Bool = false) {
        model = RemoteImageModel(url)
        self.url = url
        self.sharable = sharable
    }
    
    var body: some View {
        if sharable {
            content
                .contextMenu {
                    Button {
                        openURL(URL(string: url)!)
                    } label: {
                        Label("view.image.open", systemImage: "safari")
                    }
                    if let solidImage = model.image {
                        #if os(macOS)
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setData(solidImage.tiffRepresentation, forType: .tiff)
                        } label: {
                            Label("view.image.copy", systemImage: "doc.on.doc")
                        }
                        #else
                        Button {
                            let shareSheet = UIActivityViewController(
                                activityItems: [ solidImage ], applicationActivities: nil
                            )
                            UIApplication.shared.windows.first?.rootViewController?.present(
                                shareSheet, animated: true, completion: nil
                            )
                        } label: {
                            Label("view.image.share", systemImage: "square.and.arrow.up")
                        }
                        #endif
                    }
                }
        } else {
            content
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if let solidImage = model.image {
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
}

#if DEBUG
struct RemoteImage_Previews: PreviewProvider {
    static var previews: some View {
        RemoteImage("https://lh3.googleusercontent.com/16Nd33lsfrmKA2n4SwXSAkRm2SMyMlGaCXQHT7Y33R1rUn799TLhRBj0cS9SFIv1C6OxHt")
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
