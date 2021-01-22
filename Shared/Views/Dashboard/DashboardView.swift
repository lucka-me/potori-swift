//
//  DashboardView.swift
//  Potori
//
//  Created by Lucka on 20/1/2021.
//

import SwiftUI

struct DashboardView: View {
    
    #if os(iOS)
    @EnvironmentObject var appDelegate: AppDelegate
    #endif
    
    @EnvironmentObject private var service: Service
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading) {
                if service.status != .idle || !service.auth.login || service.isNominationsEmpty {
                    DashboardStatusView()
                }
                if service.status == .idle && !service.isNominationsEmpty {
                    DashboardHighlightView()
                    DashboardGalleryView()
                    DashboardReasonsView()
                }
            }
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
    
    static let service = Service.preview
    static let navigationModel: Navigation = .init()
    
    static var previews: some View {
        DashboardView()
            .environmentObject(service)
            .environmentObject(navigationModel)
            .environment(\.managedObjectContext, service.containerContext)
    }
}
#endif
