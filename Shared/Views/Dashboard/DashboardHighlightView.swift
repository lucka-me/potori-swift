//
//  DashboardBasicRowView.swift
//  Potori
//
//  Created by Lucka on 20/1/2021.
//

import SwiftUI

struct DashboardHighlightView: View {
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @EnvironmentObject private var service: Service
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("view.dashboard.highlight")
                    .font(.title2)
                    .bold()
            }
            
            LazyVGrid(columns: columns, alignment: .leading) {
                DashboardCardView(
                    Text("\(service.countNominations())"),
                    destination: NominationList("view.dashboard.highlight.nominations")
                ) {
                    Label("view.dashboard.highlight.nominations", systemImage: "arrow.up.circle")
                        .foregroundColor(.accentColor)
                }
                ForEach(Umi.shared.statusAll, id: \.code) { status in
                    let predicate = status.predicate
                    DashboardCardView(
                        Text("\(service.countNominations(predicate))"),
                        destination: NominationList(status.title, predicate)
                    ) {
                        Label(status.title, systemImage: status.icon)
                            .foregroundColor(status.color)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var columns: [GridItem] {
        #if os(macOS)
        let columns = 2
        #else
        let columns = horizontalSizeClass == .compact ? 2 : 4
        #endif
        return Array(repeating: .init(.flexible(), spacing: 10), count: columns)
    }
}

#if DEBUG
struct DashboardHighlightView_Previews: PreviewProvider {
    
    static let service = Service.preview
    
    static var previews: some View {
        DashboardHighlightView()
            .environmentObject(service)
            .environment(\.managedObjectContext, service.containerContext)
    }
}
#endif