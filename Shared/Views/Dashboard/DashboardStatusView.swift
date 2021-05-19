//
//  DashboardStatusView.swift
//  Potori
//
//  Created by Lucka on 21/1/2021.
//

import SwiftUI

struct DashboardStatusView: View {
    
    @EnvironmentObject private var dia: Dia
    @EnvironmentObject private var service: Service
    @ObservedObject private var progress = ProgressInspector.shared
    
    var body: some View {
        CardView.Card {
            if !service.google.auth.login {
                Button("view.dashboard.status.linkAccount") { service.google.auth.logIn() }
                    .buttonStyle(CardView.ButtonStyle())
                    .foregroundColor(.accentColor)
            } else if service.status == .idle {
                if let latest = dia.firstNomination(sortBy: Nomination.sortDescriptorsByDate) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("view.dashboard.status.latest")
                        Spacer()
                        Text(DateFormatter.localizedString(from: latest.resultTime, dateStyle: .medium, timeStyle: .short))
                    }
                    .lineLimit(1)
                } else {
                    Text("view.dashboard.status.empty")
                }
            } else if service.status == .requestMatch {
                Button("view.dashboard.status.manuallyMatch") {  }
                    .buttonStyle(CardView.ButtonStyle())
                    .foregroundColor(.accentColor)
            } else {
                switch service.status {
                    case .processingMails:
                        ProgressView(
                            value: Double(progress.done),
                            total: Double(progress.total),
                            label: { Text(LocalizedStringKey(service.status.rawValue)) },
                            currentValueLabel: { Text("\(progress.done) / \(progress.total)") }
                        )
                    default:
                        Text(LocalizedStringKey(service.status.rawValue))
                }
            }
        }
        .padding(.top, 3)
        .padding(.horizontal)
    }
}

#if DEBUG
struct DashboardStatusView_Previews: PreviewProvider {
    
    static var previews: some View {
        DashboardStatusView()
            .environmentObject(Dia.preview)
            .environmentObject(Service.shared)
    }
}
#endif
