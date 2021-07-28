//
//  DashboardCard.swift
//  Potori
//
//  Created by Lucka on 20/1/2021.
//

import SwiftUI

struct DashboardCard: View {
    
    private let count: Int
    private let title: LocalizedStringKey
    private let systemImage: String
    private let color: Color
    
    init(_ count: Int, _ title: LocalizedStringKey, systemImage: String, color: Color = .accentColor) {
        self.count = count
        self.title = title
        self.systemImage = systemImage
        self.color = color
    }
    
    var body: some View {
        VStack {
            HStack(alignment: .firstTextBaseline) {
                Label(title, systemImage: systemImage)
                    .lineLimit(1)
                    .foregroundColor(color)
                    .labelStyle(.fixedWidthIcon)
                Spacer()
                Label("action.open", systemImage: "chevron.right")
                    .labelStyle(.iconOnly)
                    .foregroundColor(.secondary)
            }
            Text("\(count)")
                .lineLimit(1)
                .font(.system(.largeTitle, design: .rounded))
                .padding(.top, 3)
        }
        .card()
    }
}

#if DEBUG
struct DashboardCard_Previews: PreviewProvider {
    static var previews: some View {
        DashboardCard(2000, "Title", systemImage: "info.circle")
    }
}
#endif
