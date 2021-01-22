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
                            let image = RemoteImage(nomination.imageURL)
                                .scaledToFill()
                                .frame(width: 100, height: 100, alignment: .center)
                                .overlay(caption(nomination), alignment: .bottomLeading)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            #if os(macOS)
                            let view = Button {
                                navigation.openNominations = .init(
                                    "view.dashboard.gallery", Self.predicate, nomination.id, panel: .list
                                )
                            } label: { image }
                            #else
                            let view = NavigationLink(destination: NominationDetails(nomination: nomination)) { image }
                            #endif
                            view.buttonStyle(PlainButtonStyle())
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
    
    @ViewBuilder
    private func openNominationList<Label: View>(
        _ config: Navigation.OpenNominationsConfiguration,
        @ViewBuilder _ label: () -> Label
    ) -> some View {
        #if os(macOS)
        let view = Button(action: { navigation.openNominations = config }, label: label)
        #else
        let view = NavigationLink(destination: NominationList(config), label: label)
        #endif
        view.buttonStyle(PlainButtonStyle())
    }
}

#if DEBUG
struct DashboardGalleryView_Previews: PreviewProvider {
    
    static let service = Service.preview
    static let navigationModel: Navigation = .init()

    static var previews: some View {
        DashboardGalleryView()
            .environmentObject(service)
            .environmentObject(navigationModel)
            .environment(\.managedObjectContext, service.containerContext)
    }
}
#endif
