//
//  DashboardBasicRowView.swift
//  Potori
//
//  Created by Lucka on 20/1/2021.
//

import SwiftUI

struct DashboardHighlightView: View {
    
    #if os(macOS)
    @EnvironmentObject var navigation: Navigation
    #else
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @EnvironmentObject private var service: Service

    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("view.dashboard.highlight")
                    .font(.title2)
                    .bold()
            }
            
            LazyVGrid(columns: columns, alignment: .leading) {
                openNominationList(.init("view.dashboard.highlight.nominations", panel: .list)) {
                    DashboardCardView(Text("\(service.countNominations())")) {
                        Label("view.dashboard.highlight.nominations", systemImage: "arrow.up.circle")
                            .foregroundColor(.accentColor)
                    }
                }
                
                ForEach(Umi.shared.statusAll, id: \.code) { status in
                    let predicate = status.predicate
                    openNominationList(.init(status.title, predicate, panel: .list)) {
                        DashboardCardView(Text("\(service.countNominations(predicate))")) {
                            Label(status.title, systemImage: status.icon)
                                .foregroundColor(status.color)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var columns: [GridItem] {
        #if os(macOS)
        let columns = 4
        #else
        let columns = horizontalSizeClass == .compact ? 2 : 4
        #endif
        return Array(repeating: .init(.flexible(), spacing: 10), count: columns)
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
struct DashboardHighlightView_Previews: PreviewProvider {
    
    static let service = Service.preview
    static let navigationModel: Navigation = .init()
    
    static var previews: some View {
        DashboardHighlightView()
            .environmentObject(service)
            .environmentObject(navigationModel)
            .environment(\.managedObjectContext, service.containerContext)
    }
}
#endif
