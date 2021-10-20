//
//  SheetView.swift
//  Potori
//
//  Created by Lucka on 20/10/2021.
//

import SwiftUI

struct SheetView<Content: View>: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let defaultDismiss: Bool
    let content: () -> Content
    
    init(
        _ title: String = "",
        minWidth: CGFloat? = nil,
        minHeight: CGFloat? = nil,
        defaultDismiss: Bool = true,
        content: @escaping () -> Content
    ) {
        self.defaultDismiss = defaultDismiss
        self.content = content
    }
    
    var body: some View {
        NavigationView {
            content()
                .toolbar {
                    if defaultDismiss {
                        Button { dismiss() } label: { Label.dismiss }
                    } else {
                        EmptyView()
                    }
                }
        }
        .navigationViewStyle(.stack)
    }
}

#if DEBUG
struct SheetView_Previews: PreviewProvider {
    static var previews: some View {
        SheetView {
            Text("Hello")
        }
    }
}
#endif
