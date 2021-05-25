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
    @EnvironmentObject private var navigation: Navigation
    @ObservedObject private var auth = GoogleKit.Auth.shared
    @ObservedObject private var progress = ProgressInspector.shared
    
    var body: some View {
        CardView.Card {
            if !auth.authorized {
                Button("view.dashboard.status.linkAccount", action: auth.link)
                    .buttonStyle(CardView.ButtonStyle())
                    .foregroundColor(.accentColor)
            } else if service.status == .idle {
                if let latest = dia.firstNomination(sortedBy: Nomination.sortDescriptorsByDate) {
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
                Button("view.dashboard.status.manuallyMatch") { navigation.showMatchView.toggle() }
                    .buttonStyle(CardView.ButtonStyle())
                    .foregroundColor(.accentColor)
            } else {
                if showProgress {
                    ProgressView(
                        value: Double(progress.done),
                        total: Double(progress.total),
                        label: { Text(statusText) },
                        currentValueLabel: { Text("\(progress.done) / \(progress.total)") }
                    )
                } else {
                    Text(statusText)
                }
            }
        }
        .padding(.top, 3)
        .padding(.horizontal)
    }
    
    private var showProgress: Bool {
        service.status == .processingMails || service.status == .queryingBrainstorming
    }
    
    private var statusText: LocalizedStringKey {
        switch service.status {
            case .syncing: return "service.status.syncing"
            case .processingMails: return "service.status.processingMails"
            case .queryingBrainstorming: return "service.status.queryingBrainstorming"
            default: return ""
        }
    }
}

#if DEBUG
struct DashboardStatusView_Previews: PreviewProvider {
    
    static let navigation: Navigation = .init()
    
    static var previews: some View {
        DashboardStatusView()
            .environmentObject(Dia.preview)
            .environmentObject(Service.shared)
            .environmentObject(navigation)
    }
}
#endif
