//
//  NominationDetails.swift
//  Potori
//
//  Created by Lucka on 29/12/2020.
//

import SwiftUI
import MapKit

struct NominationDetails: View {
    
    let nomination: Nomination
    
    private let radius: CGFloat = 12
    
    var body: some View {
        
        #if os(macOS)
        content.frame(minWidth: 300)
        #else
        content
        #endif
    }
    
    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(alignment: .center) {
                RemoteImage(nomination.imageURL, sharable: true)
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                
                Divider()
                
                LazyVGrid(columns: [ .init(.adaptive(minimum: 200), alignment: .top) ], alignment: .center) {
                    highlight
                    if nomination.statusCode == .rejected {
                        reasons
                    }
                }
                .lineLimit(1)
                
                if nomination.hasLngLat {
                    NominationDetailsMap(nomination: nomination)
                        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                        .frame(height: 200)
                }
            }
            .navigationTitle(nomination.title)
            .padding()
            .toolbar(content: {
                ToolbarItem(placement: .primaryAction) {
                    Button { } label: { Label("edit", systemImage: "square.and.pencil") }
                }
            })
        }
    }
    
    @ViewBuilder
    private var highlight: some View {
        ZStack(alignment: .topLeading) {
            CardBackground(radius: radius)
            
            VStack(alignment: .leading) {
                HStack {
                    Label("view.nominations.details.confirmed", systemImage: "arrow.up.circle")
                        .foregroundColor(.accentColor)
                    Spacer()
                    Text(
                        DateFormatter.localizedString(
                            from: nomination.confirmedTime,
                            dateStyle: .medium, timeStyle: .none
                        )
                    )
                }
                Divider()
                let status = nomination.statusData
                HStack {
                    Label(status.title, systemImage: status.icon)
                        .foregroundColor(status.color)
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
                Divider()
                HStack {
                    Label("view.nominations.details.scanner", systemImage: "apps.iphone")
                    Spacer()
                    Text(nomination.scannerData.title)
                }
            }
            .padding(radius)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    @ViewBuilder
    private var reasons: some View {
        ZStack(alignment: .topLeading) {
            CardBackground(radius: radius)
            
            VStack(alignment: .leading) {
                Text("view.nominations.details.rejectedFor")
                    .foregroundColor(.red)
                    .bold()
                if nomination.reasons.count > 0 {
                    ForEach(nomination.reasonsData, id: \.code) { reason in
                        Divider()
                        Label(reason.title, systemImage: reason.icon)
                            
                    }
                } else {
                    Divider()
                    let undeclared = Umi.shared.reason[Umi.Reason.undeclared]!
                    Label(undeclared.title, systemImage: undeclared.icon)
                }
            }
            .padding(radius)
        }
        .fixedSize(horizontal: false, vertical: true)
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
