//
//  DashboardBasicRowView.swift
//  Potori
//
//  Created by Lucka on 20/1/2021.
//

import SwiftUI

struct DashboardBasicRowView: View {
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @EnvironmentObject private var service: Service
    
    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading) {
            DashboardCardView(Text("\(service.count())")) {
                Label("view.dashboard.basic.nominations", systemImage: "arrow.up.circle")
                    .foregroundColor(.accentColor)
            }
            ForEach(Umi.shared.statusAll, id: \.code) { status in
                DashboardCardView(Text("\(service.count(status.predicate))"))  {
                    Label(status.title, systemImage: status.icon)
                        .foregroundColor(status.color)
                }
            }
        }
    }
    
    private var columns: [GridItem] {
        #if os(macOS)
        let count = 4
        #else
        let count = horizontalSizeClass == .compact ? 2 : 4
        #endif
        return Array(repeating: .init(.flexible(), spacing: 10), count: count)
    }
}

#if DEBUG
struct DashboardBasicRowView_Previews: PreviewProvider {
    
    static let service = Service.preview
    
    static var previews: some View {
        DashboardBasicRowView()
            .environmentObject(service)
            .environment(\.managedObjectContext, service.containerContext)
    }
}
#endif
