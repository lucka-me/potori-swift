//
//  DashboardReasonsView.swift
//  Potori
//
//  Created by Lucka on 20/1/2021.
//

import SwiftUI

struct DashboardReasonsView: View {
    
    #if os(macOS)
    @Binding var listConfig: NominationList.Configuration
    #else
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @EnvironmentObject private var service: Service
    
    @State private var showMore = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("view.dashboard.reasons")
                    .font(.title2)
                    .bold()
                let undeclaredCount = service.countNominations(Umi.shared.reason[Umi.Reason.undeclared]!.predicate) > 0 ? 1 : 0
                if service.countReasons(Umi.Reason.hasNominationsPredicate) + undeclaredCount > 4 {
                    Spacer()
                    Button(showMore ? "view.dashboard.reasons.less" : "view.dashboard.reasons.more") {
                        showMore.toggle()
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .foregroundColor(.accentColor)
                }
            }
            .padding(.top, 3)
            
            LazyVGrid(columns: columns, alignment: .leading) {
                ForEach(0 ..< Umi.shared.reasonAll.count) { index in
                    let reason = Umi.shared.reasonAll[index]
                    if index < 4 || showMore {
                        let predicate = reason.predicate
                        let count = service.countNominations(predicate)
                        if count > 0 {
                            openNominationList(.init(reason.title, predicate)) {
                                DashboardCardView(Text("\(service.countNominations(predicate))")) {
                                    Label(reason.title, systemImage: reason.icon)
                                        .foregroundColor(.red)
                                }
                            }
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
        _ config: NominationList.Configuration,
        @ViewBuilder _ label: () -> Label
    ) -> some View {
        #if os(macOS)
        let view = Button(action: { listConfig = config }, label: label)
        #else
        let view = NavigationLink(destination: NominationList(config), label: label)
        #endif
        view.buttonStyle(PlainButtonStyle())
    }
}

#if DEBUG
struct DashboardReasonsView_Previews: PreviewProvider {

    static let service = Service.preview

    static var previews: some View {
        #if os(macOS)
        DashboardReasonsView(listConfig: .constant(.init("")))
            .environmentObject(service)
            .environment(\.managedObjectContext, service.containerContext)
        #else
        DashboardReasonsView()
            .environmentObject(service)
            .environment(\.managedObjectContext, service.containerContext)
        #endif
    }
}
#endif
