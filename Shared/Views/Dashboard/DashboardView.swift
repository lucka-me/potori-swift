//
//  DashboardView.swift
//  Potori
//
//  Created by Lucka on 20/1/2021.
//

import SwiftUI

struct DashboardView: View {
    
    static let columns: [GridItem] = [ .init(.adaptive(minimum: 150, maximum: 200), spacing: 8) ]
    
    @EnvironmentObject private var dia: Dia
    @EnvironmentObject private var service: Service
    #if os(iOS)
    @EnvironmentObject private var navigation: Navigation
    #endif
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading) {
                #if os(iOS)
                if navigation.activeLink == Navigation.nominationWidgetTarget {
                    if let id = navigation.openNominations.selection,
                       let nomination = dia.firstNomination(matches: .init(format: "id == %@", id)) {
                        NavigationLink(
                            destination: NominationDetails(nomination: nomination),
                            tag: Navigation.nominationWidgetTarget,
                            selection: $navigation.activeLink,
                            label: { }
                        )
                    }
                }
                #endif
                DashboardStatusView()
                if service.status == .idle && dia.countNominations() > 0 {
                    DashboardHighlightsView()
                    DashboardGalleryView()
                    DashboardScannersView()
                    DashboardReasonsView()
                }
            }
            .padding(.vertical)
            .animation(.easeInOut)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    service.refresh()
                } label: {
                    Label("view.dashboard.refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut(.init("r", modifiers: .command))
                .disabled(service.status != .idle)
            }
        }
        .navigationTitle("view.dashboard")
    }
}

#if DEBUG
struct DashboardView_Previews: PreviewProvider {
    
    static let navigation: Navigation = .init()
    
    static var previews: some View {
        DashboardView()
            .environmentObject(Dia.preview)
            .environmentObject(Service.shared)
            .environmentObject(navigation)
            .environment(\.managedObjectContext, Dia.preview.viewContext)
    }
}
#endif
