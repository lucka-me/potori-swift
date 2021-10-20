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
    @ObservedObject private var auth = GoogleKit.Auth.shared
    @ObservedObject private var progress = ProgressInspector.shared
    
    @SceneStorage(.scenePresentingMatchSheet) private var presentingMatchSheet = false
    
    var body: some View {
        VStack {
            if !auth.authorized {
                Button("view.dashboard.status.linkAccount", action: auth.link)
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
            } else if service.status == .requestMatch {
                Button("view.dashboard.status.manuallyMatch") { presentingMatchSheet.toggle() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
            } else if showProgress {
                ProgressView(
                    value: Double(progress.done),
                    total: Double(progress.total),
                    label: { Text(statusText) },
                    currentValueLabel: { Text("\(progress.done) / \(progress.total)") }
                )
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text(statusText)
                    Spacer()
                    if service.status == .idle {
                        if let latest = dia.firstNomination(sortedBy: Nomination.sortDescriptorsByDate) {
                            Text(latest.resultTime, style: .date)
                            Text(latest.resultTime, style: .time)
                        } else {
                            Text("view.dashboard.status.empty")
                        }
                    } else {
                        ProgressView()
                    }
                }
                .lineLimit(1)
            }
        }
        .card()
        .padding(.top, 3)
        .padding(.horizontal)
    }
    
    private var showProgress: Bool {
        service.status == .processingMails || service.status == .queryingBrainstorming
    }
    
    private var statusText: LocalizedStringKey {
        switch service.status {
            case .idle: return "view.dashboard.status.latest"
            case .syncing: return "service.status.syncing"
            case .processingMails: return "service.status.processingMails"
            case .queryingBrainstorming: return "service.status.queryingBrainstorming"
            default: return ""
        }
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
