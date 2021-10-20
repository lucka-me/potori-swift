//
//  SheetView.swift
//  macOS
//
//  Created by Lucka on 20/10/2021.
//

import SwiftUI

struct SheetView<Content: View>: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let titleKey: LocalizedStringKey
    let minWidth: CGFloat?
    let minHeight: CGFloat?
    let defaultDismiss: Bool
    let content: () -> Content
    
    init(
        _ titleKey: LocalizedStringKey = "",
        minWidth: CGFloat? = nil,
        minHeight: CGFloat? = 300,
        defaultDismiss: Bool = true,
        content: @escaping () -> Content
    ) {
        self.titleKey = titleKey
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.defaultDismiss = defaultDismiss
        self.content = content
    }
    
    var body: some View {
        Group {
            HStack {
                Text(titleKey)
                    .font(.largeTitle)
                Spacer()
            }
            .padding([ .top, .horizontal ])
            
            content()
                .toolbar {
                    if defaultDismiss {
                        Button { dismiss() } label: { Label.dismiss }
                    } else {
                        EmptyView()
                    }
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
