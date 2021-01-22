//
//  DashboardBasicRowView.swift
//  Potori
//
//  Created by Lucka on 20/1/2021.
//

import SwiftUI

struct DashboardHighlightView: View {
    
    #if os(macOS)
    @EnvironmentObject var navigation: Navigation
    #else
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
            
            LazyVGrid(columns: DashboardView.columns, alignment: .leading) {
                OpenNominationListLink(.init("view.dashboard.highlight.nominations")) {
                    DashboardCardView(Text("\(service.countNominations())")) {
                        Label("view.dashboard.highlight.nominations", systemImage: "arrow.up.circle")
                            .foregroundColor(.accentColor)
                    }
                }
                
                ForEach(Umi.shared.statusAll, id: \.code) { status in
                    let predicate = status.predicate
                    OpenNominationListLink(.init(status.title, predicate)) {
                        DashboardCardView(Text("\(service.countNominations(predicate))")) {
                            Label(status.title, systemImage: status.icon)
                                .foregroundColor(status.color)
                        }
                    }
                }
            }
        }
        .padding(.top, 3)
        .padding(.horizontal)
    }
}

#if DEBUG
struct DashboardHighlightView_Previews: PreviewProvider {
    
    static let service = Service.preview
    static let navigationModel: Navigation = .init()
    
    static var previews: some View {
        DashboardHighlightView()
            .environmentObject(service)
            .environmentObject(navigationModel)
            .environment(\.managedObjectContext, service.containerContext)
    }
}
#endif
