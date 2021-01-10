//
//  DashboardView.swift
//  Potori
//
//  Created by Lucka on 7/1/2021.
//

import SwiftUI

struct StatsView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @FetchRequest(entity: Nomination.entity(), sortDescriptors: [
        NSSortDescriptor(keyPath: \Nomination.title, ascending: true)
    ])
    
    private var nominations: FetchedResults<Nomination>
    
    var body: some View {
        let list = List {
            totalSection
            statusSection
            reasonsSection
        }
        .navigationTitle("view.stats")
        #if os(macOS)
        list.frame(minWidth: 250)
        #else
        if horizontalSizeClass == .compact {
            NavigationView {
                list
                    .listStyle(InsetGroupedListStyle())
                    .navigationViewStyle(StackNavigationViewStyle())
            }
        } else {
            list.listStyle(InsetGroupedListStyle())
        }
        #endif
    }
    
    private var totalSection: some View {
        Section(header: Text("view.stats.total")) {
            HStack {
                Label("view.stats.total.nominations", systemImage: "arrow.up.circle")
                Spacer()
                Text("\(nominations.count)")
            }
        }
    }
    
    private var statusSection: some View {
        Section(header: Text("view.stats.status")) {
            let stat = statStatus
            ForEach(StatusKit.shared.statusAll, id: \.code) { status in
                HStack {
                    Label(status.title, systemImage: status.icon)
                    Spacer()
                    Text("\(stat[status.code] ?? 0)")
                }
            }
        }
    }
    
    private var reasonsSection: some View {
        Section(header: Text("view.stats.reasons")) {
            let stat = statReasons
            ForEach(stat, id: \.key) { (key, value) in
                let reason = StatusKit.shared.reason[key]!
                HStack {
                    Label(reason.title, systemImage: reason.icon)
                    Spacer()
                    Text("\(value)")
                }
            }
        }
    }
    
    private var statStatus: [StatusKit.StatusCode : Int] {
        nominations.reduce(into: [:]) { dict, nomination in
            let code = nomination.statusCode
            dict[code] = (dict[code] ?? 0) + 1
        }
    }
    
    private var statReasons: [(key: Int16, value: Int)] {
        nominations
            .filter({ $0.statusCode == .rejected })
            .reduce(into: [:] as [Int16 : Int]) { dict, nomination in
                if nomination.reasons.isEmpty {
                    let code = StatusKit.Reason.undeclared
                    dict[code] = (dict[code] ?? 0) + 1
                } else {
                    for code in nomination.reasons {
                        if StatusKit.shared.reason.keys.contains(code) {
                            dict[code] = (dict[code] ?? 0) + 1
                        } else {
                            let undeclared = StatusKit.Reason.undeclared
                            dict[undeclared] = (dict[undeclared] ?? 0) + 1
                        }
                    }
                }
            }
            .sorted { a, b in
                a.value > b.value
            }
    }
}

#if DEBUG
struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
#endif
