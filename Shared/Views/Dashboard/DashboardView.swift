//
//  DashboardView.swift
//  Potori
//
//  Created by Lucka on 20/1/2021.
//

import SwiftUI

struct DashboardView: View {
    
    #if os(macOS)
    @Binding var listConfig: NominationList.Configuration
    #else
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
                    #if os(macOS)
                    DashboardHighlightView(listConfig: $listConfig)
                    DashboardGalleryView(listConfig: $listConfig)
                    DashboardReasonsView(listConfig: $listConfig)
                    #else
                    DashboardHighlightView()
                    DashboardGalleryView()
                    DashboardReasonsView()
                    #endif
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
                .disabled(service.status != .idle)
            }
        }
        .navigationTitle("view.dashboard")
    }
}

#if DEBUG
struct DashboardView_Previews: PreviewProvider {
    
    static let service = Service.preview
    
    static var previews: some View {
        #if os(macOS)
        DashboardView(listConfig: .constant(.init("")))
            .environmentObject(service)
            .environment(\.managedObjectContext, service.containerContext)
        #else
        DashboardView()
            .environmentObject(service)
            .environment(\.managedObjectContext, service.containerContext)
        #endif
    }
}
#endif
