//
//  DashboardStatusView.swift
//  Potori
//
//  Created by Lucka on 21/1/2021.
//

import SwiftUI

struct DashboardStatusView: View {
    
    @EnvironmentObject private var service: Service
    
    var body: some View {
        HStack {
            Text("view.dashboard.status")
                .font(.title2)
                .bold()
        }
        .padding(.top, 3)
        
        ZStack(alignment: .topLeading) {
            DashboardCardBackground()
            
            Group {
                switch service.status {
                case .processingMails:
                    ProgressView(LocalizedStringKey(service.status.rawValue), value: service.progress)
                default:
                    Text(LocalizedStringKey(service.status.rawValue))
                }
            }
            .padding(10)
        }
    }
}

struct DashboardStatusView_Previews: PreviewProvider {
    
    static let service = Service.preview
    
    static var previews: some View {
        DashboardStatusView()
            .environmentObject(service)
    }
}
