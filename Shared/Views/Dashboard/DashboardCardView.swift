//
//  DashboardCardView.swift
//  Potori
//
//  Created by Lucka on 20/1/2021.
//

import SwiftUI

struct DashboardCardView<Label: View>: View {
    
    var text: Text
    private let label: Label
    private let showLinkIndicator: Bool
    
    init(_ text: Text, _ showLinkIndicator: Bool = true, @ViewBuilder label: @escaping () -> Label) {
        self.text = text
        self.label = label()
        self.showLinkIndicator = showLinkIndicator
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            
            DashboardCardBackground()

            VStack(alignment: .leading) {
                HStack {
                    label
                    if showLinkIndicator {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                text
                    .font(.system(.largeTitle, design: .rounded))
                    .padding(.top, 3)
            }
            .lineLimit(1)
            .padding(10)
        }
    }
}

#if DEBUG
struct DashboardCardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardCardView(Text("Number")) {
            Label("Label", systemImage: "info.circle.fill")
                .foregroundColor(.accentColor)
        }
    }
}
#endif

struct DashboardCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.gray.opacity(0.15))
    }
}
