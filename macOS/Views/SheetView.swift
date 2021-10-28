//
//  SheetView.swift
//  macOS
//
//  Created by Lucka on 20/10/2021.
//

import SwiftUI

struct SheetView<Content: View>: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let title: String
    let minWidth: CGFloat?
    let minHeight: CGFloat?
    let defaultDismiss: Bool
    let content: () -> Content
    
    init(
        _ title: String = "",
        minWidth: CGFloat? = nil,
        minHeight: CGFloat? = 300,
        defaultDismiss: Bool = true,
        content: @escaping () -> Content
    ) {
        self.title = title
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.defaultDismiss = defaultDismiss
        self.content = content
    }
    
    init(
        _ titleKey: String.LocalizationValue = "",
        minWidth: CGFloat? = nil,
        minHeight: CGFloat? = 300,
        defaultDismiss: Bool = true,
        content: @escaping () -> Content
    ) {
        self.title = .init(localized: titleKey)
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.defaultDismiss = defaultDismiss
        self.content = content
    }
    
    var body: some View {
        Group {
            HStack {
                Text(title)
                    .font(.largeTitle)
                Spacer()
            }
            .padding([ .top, .horizontal ])
            
            if defaultDismiss {
                content()
                    .toolbar {
                        Button { dismiss() } label: { Label.dismiss }
                    }
            } else {
                content()
            }
        }
        .frame(minWidth: minWidth, minHeight: minHeight)
    }
}

#if DEBUG
struct SheetView_Previews: PreviewProvider {
    static var previews: some View {
        SheetView("Title") {
            Text("Hello")
        }
    }
}
#endif
