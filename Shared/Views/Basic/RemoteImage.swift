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
    
    @ObservedObject private var model: RemoteImageModel

    private let url: String
    
    init(_ url: String, sharable: Bool = false) {
        model = RemoteImageModel(url)
        self.url = url
    }
    
    var body: some View {
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
    
    var image: UNImage? {
        model.image
    }
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
