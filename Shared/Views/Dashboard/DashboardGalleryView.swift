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
    private static let predicate = NSPredicate(format: "confirmedTime > %@ || resultTime > %@", datePast30Days, datePast30Days)
    
    @Environment(\.managedObjectContext) private var viewContext
    #if os(macOS)
    @EnvironmentObject var navigation: Navigation
    #endif

    @FetchRequest(
        entity: Nomination.entity(),
        sortDescriptors: Nomination.sortDescriptorsByDate,
        predicate: Self.predicate
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
                            OpenNominationDetailsLink(
                                .init("view.dashboard.gallery", Self.predicate),
                                nomination
                            ) {
                                RemoteImage(nomination.imageURL)
                                    .scaledToFill()
                                    .frame(width: 100, height: 100, alignment: .center)
                                    .overlay(caption(nomination), alignment: .bottomLeading)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .contextMenu { NominationContextMenu(nomination: nomination) }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    @ViewBuilder
    private func caption(_ nomination: Nomination) -> some View {
        Text(nomination.title)
            .lineLimit(1)
            .font(.caption)
            .padding(8)
            .frame(width: 100, alignment: .leading)
            .background(Rectangle().fill(nomination.statusData.color.opacity(0.6)))
    }
}

#if DEBUG
struct DashboardGalleryView_Previews: PreviewProvider {
    
    static let navigation: Navigation = .init()

    static var previews: some View {
        DashboardGalleryView()
            .environmentObject(navigation)
            .environment(\.managedObjectContext, Dia.preview.viewContext)
    }
}
#endif
