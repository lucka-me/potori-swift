//
//  DashboardGalleryView.swift
//  Potori
//
//  Created by Lucka on 21/1/2021.
//

import SwiftUI

struct DashboardGalleryView: View {
    
    private static let intervalPast30Day = TimeInterval(-30 * 24 * 3600)
    private static let datePast30Days = Date(timeIntervalSinceNow: Self.intervalPast30Day) as NSDate
    
    @FetchRequest(
        entity: Nomination.entity(),
        sortDescriptors: Nomination.sortDescriptorsByDate,
        predicate: NSPredicate(format: "confirmedTime > %@ || resultTime > %@", Self.datePast30Days, Self.datePast30Days)
    ) private var nominations: FetchedResults<Nomination>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("view.dashboard.gallery")
                    .font(.title2)
                    .bold()
            }
            .padding(.top, 3)
            .padding(.horizontal)
            
            if nominations.isEmpty {
                Text("view.dashboard.gallery.empty")
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack {
                        ForEach(nominations) { nomination in
                            NavigationLink(destination: NominationDetails(nomination: nomination)) {
                                RemoteImage(nomination.imageURL)
                                    .scaledToFill()
                                    .frame(width: 100, height: 100, alignment: .center)
                                    .overlay(caption(nomination), alignment: .bottomLeading)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    @ViewBuilder
    private func caption(_ nomination: Nomination) -> some View {
        let status = nomination.statusData
        Text(nomination.title)
            .foregroundColor(.primary)
            .lineLimit(1)
            .font(.caption)
            .padding(8)
            .frame(width: 100, alignment: .leading)
            .background(Rectangle().fill(status.color.opacity(0.5)))
    }
}

struct DashboardGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardGalleryView()
    }
}
