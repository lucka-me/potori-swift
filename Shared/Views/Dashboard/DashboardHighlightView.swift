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
    #endif
    
    @EnvironmentObject private var dia: Dia

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("view.dashboard.highlight")
                    .font(.title2)
                    .bold()
            }
            
            LazyVGrid(columns: DashboardView.columns, alignment: .leading) {
                OpenNominationListLink(.init("view.dashboard.highlight.all")) {
                    DashboardCard(
                        dia.countNominations(),
                        "view.dashboard.highlight.all",
                        systemImage: "arrow.up.circle"
                    )
                }
                
                ForEach(Umi.shared.statusAll, id: \.code) { status in
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
struct DashboardHighlightView_Previews: PreviewProvider {
    
    static let navigation: Navigation = .init()
    
    static var previews: some View {
        DashboardHighlightView()
            .environmentObject(Dia.preview)
            .environmentObject(navigation)
    }
}
#endif
