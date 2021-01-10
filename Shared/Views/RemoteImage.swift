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
    @ObservedObject private var remoteImageModel: RemoteImageModel
    
    init(_ url: String) {
        remoteImageModel = RemoteImageModel(url)
    }
    
    var body: some View {
        #if os(macOS)
        let image = Image(nsImage: remoteImageModel.image ?? NSImage(named: "MissingImage")!)
        #else
        let image = Image(uiImage: remoteImageModel.image ?? UIImage(named: "MissingImage")!)
        #endif
        
        image.resizable()
    }
}

#if DEBUG
struct RemoteImage_Previews: PreviewProvider {
    static var previews: some View {
        RemoteImage("https://s.gravatar.com/avatar/f03d18971cd558e09f51ad19923bf077?s=180")
    }
}
#endif

fileprivate class CachedImage {
    
    static let shared = CachedImage()
    
    private var cache = NSCache<NSString, UNImage>()
    
    func get(_ forKey: String) -> UNImage? {
        return cache.object(forKey: NSString(string: forKey))
    }
    
    func set(forKey: String, image: UNImage) {
        cache.setObject(image, forKey: NSString(string: forKey))
    }
}

fileprivate class RemoteImageModel: ObservableObject {
    
    @Published var image: UNImage?
    var url: String

    private var cache = CachedImage.shared
    
    init(_ url: String) {
        self.url = url
        if !cached {
            fetch()
        }
    }
    
    var cached: Bool {
        guard let cacheImage = cache.get(url) else {
            return false
        }
        image = cacheImage
        return true
    }
    
    private func fetch() {
        
        guard let taskUrl = URL(string: url) else {
            return
        }
        URLSession.shared.dataTask(with: taskUrl) { (data, response, error) in
            guard let solidData = data else {
                return
            }
            DispatchQueue.main.async {
                guard let remoteImage = UNImage(data: solidData) else {
                    return
                }
                self.cache.set(forKey: self.url, image: remoteImage)
                self.image = remoteImage
            }
        }
        .resume()
    }
}
