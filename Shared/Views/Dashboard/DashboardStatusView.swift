//
//  DashboardStatusView.swift
//  Potori
//
//  Created by Lucka on 21/1/2021.
//

import SwiftUI

struct DashboardStatusView: View {
    
    #if os(iOS)
    @EnvironmentObject var appDelegate: AppDelegate
    #endif
    
    @EnvironmentObject private var service: Service
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            CardBackground()

            Group {
                if !service.google.auth.login {
                    Button("view.dashboard.status.linkAccount") {
                        #if os(macOS)
                        service.google.auth.logIn()
                        #else
                        service.google.auth.logIn(appDelegate: appDelegate)
                        #endif
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.accentColor)
                } else {
                    switch service.status {
                    case .processingMails:
                        ProgressView(LocalizedStringKey(service.status.rawValue), value: service.progress)
                    default:
                        Text(LocalizedStringKey(service.status.rawValue))
                    }
                }
            }
            .padding(10)
        }
        .padding(.top, 3)
        .padding(.horizontal)
    }
}

#if DEBUG
struct DashboardStatusView_Previews: PreviewProvider {
    
    static let service = Service.preview
    
    static var previews: some View {
        DashboardStatusView()
            .environmentObject(service)
    }
}
#endif
