//
//  DashboardHighlightsView.swift
//  Potori
//
//  Created by Lucka on 20/1/2021.
//

import SwiftUI

struct DashboardHighlightsView: View {
    
    #if os(macOS)
    @EnvironmentObject var navigation: Navigation
    #endif
    
    @EnvironmentObject private var dia: Dia

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("view.dashboard.highlights")
                    .font(.title2)
                    .bold()
            }
            
            LazyVGrid(columns: DashboardView.columns, alignment: .leading) {
                OpenNominationListLink(.init("view.dashboard.highlights.all")) {
                    DashboardCard(
                        dia.countNominations(),
                        "view.dashboard.highlights.all",
                        systemImage: "arrow.up.circle"
                    )
                }
                
                ForEach(Umi.shared.statusAll) { status in
                    let predicate = status.predicate
                    OpenNominationListLink(.init(status.title, predicate)) {
                        DashboardCard(
                            dia.countNominations(matches: predicate), status.title,
                            systemImage: status.icon, color: status.color
                        )
                    }
                }
            }
        }
        .padding(.top, 3)
        .padding(.horizontal)
    }
}

#if DEBUG
struct DashboardHighlightsView_Previews: PreviewProvider {
    
    static let navigation: Navigation = .init()
    
    static var previews: some View {
        DashboardHighlightsView()
            .environmentObject(Dia.preview)
            .environmentObject(navigation)
    }
}
#endif
