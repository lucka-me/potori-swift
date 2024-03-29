//
//  DashboardGalleryView.swift
//  Potori
//
//  Created by Lucka on 21/1/2021.
//

import SwiftUI

struct DashboardGalleryView: View {
    
    private static var datePast30Days: NSDate {
        .init(timeIntervalSinceNow: -30 * 24 * 3600)
    }
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: Nomination.sortDescriptorsByDate,
        predicate: .init(format: "confirmedTime > %@ || resultTime > %@", datePast30Days, datePast30Days)
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
                            DetailsLink(nomination) {
                                AsyncImage(url: nomination.imageURL, placeholder: nomination.statusData.color)
                                    .scaledToFill()
                                    .frame(width: 100, height: 100, alignment: .center)
                                    .overlay(caption(nomination), alignment: .bottomLeading)
                                    .mask {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    }
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
        HStack {
            Text(nomination.title)
                .lineLimit(1)
                .font(.caption)
                .foregroundColor(nomination.statusData.color)
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#if DEBUG
struct DashboardGalleryView_Previews: PreviewProvider {

    static var previews: some View {
        DashboardGalleryView()
            .environment(\.managedObjectContext, Dia.preview.viewContext)
    }
}
#endif
