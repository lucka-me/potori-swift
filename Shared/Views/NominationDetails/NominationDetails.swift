//
//  NominationDetails.swift
//  Potori
//
//  Created by Lucka on 29/12/2020.
//

import SwiftUI
import MapKit

struct NominationDetails: View {

    var nomination: Nomination
    
    var body: some View {
        let list = List {
            RemoteImage(nomination.imageURL)
                .scaledToFill()
                .frame(height: 200)
                .listRowInsets(EdgeInsets())
            
            generalSection
            
            if nomination.statusCode == .rejected {
                reasonsSection
            }
            
            Section(header: Text("view.nominations.details.location")) {
                if nomination.hasLngLat {
                    NominationDetailsMap(location: nomination.location)
                        .frame(height: 200)
                        .listRowInsets(EdgeInsets())
                } else {
                    Text("view.nominations.details.location.notAvailable")
                }
            }
        }
        .toolbar(content: {
            ToolbarItem(placement: .primaryAction) {
                Button(
                    action: {},
                    label: {
                        Image(systemName: "square.and.pencil")
                    }
                )
            }
        })
        .navigationTitle(nomination.title)
        
        #if os(macOS)
        list
            .frame(minWidth: 300)
        #else
        list
            .listStyle(InsetGroupedListStyle())
        #endif
    }
    
    private var generalSection: some View {
        Section {
            HStack {
                Label("view.nominations.details.confirmed", systemImage: "arrow.up.circle")
                Spacer()
                Text(
                    DateFormatter.localizedString(
                        from: nomination.confirmedTime,
                        dateStyle: .medium, timeStyle: .none
                    )
                )
            }
            
            let status = nomination.statusData
            HStack {
                Label(status.title, systemImage: status.icon)
                Spacer()
                if (status.code != .pending) {
                    Text(
                        DateFormatter.localizedString(
                            from: nomination.resultTime,
                            dateStyle: .medium, timeStyle: .none
                        )
                    )
                }
            }
            
            HStack {
                Label("view.nominations.details.scanner", systemImage: "apps.iphone")
                Spacer()
                Text(nomination.scannerData.title)
            }
        }
    }
    
    private var reasonsSection: some View {
        Section(header: Text("view.nominations.details.rejectedFor")) {
            if nomination.reasons.count > 0 {
                ForEach(nomination.reasonsData, id: \.code) { reason in
                    Label(reason.title, systemImage: reason.icon)
                }
            } else {
                let undeclared = Umi.shared.reason[Umi.Reason.undeclared]!
                Label(undeclared.title, systemImage: undeclared.icon)
            }
        }
    }
}

#if DEBUG
struct NominationDetails_Previews: PreviewProvider {
    static var service: Service = Service.preview
    
    static var previews: some View {
        NominationDetails(nomination: service.nominations[0])
    }
}
#endif
