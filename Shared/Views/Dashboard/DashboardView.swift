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
                DashboardBasicView()
                Text("view.dashboard.reasons")
                    .font(.title)
            }
            .padding(.horizontal)
        }
    }
}

#if DEBUG
struct DashboardView_Previews: PreviewProvider {
    
    static let service = Service.preview
    
    static var previews: some View {
        DashboardView()
            .environmentObject(service)
            .environment(\.managedObjectContext, service.containerContext)
    }
}
#endif