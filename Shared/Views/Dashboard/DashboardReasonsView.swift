//
//  DashboardReasonsView.swift
//  Potori
//
//  Created by Lucka on 20/1/2021.
//

import SwiftUI

struct DashboardReasonsView: View {
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    @EnvironmentObject private var service: Service
    
    var body: some View {
        HStack {
            Text("view.dashboard.reasons")
        }
        .padding(.top, 3)
        
        LazyVGrid(columns: columns, alignment: .leading) {
            ForEach(Umi.shared.reasonAll, id: \.code) { reason in
                let predicate = reason.predicate
                DashboardCardView(
                    Text("\(service.count(predicate))"),
                    destination: NominationList(reason.title, predicate)
                ) {
                    Label(reason.title, systemImage: reason.icon)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private var columns: [GridItem] {
        #if os(macOS)
        let count = 2
        #else
        let count = horizontalSizeClass == .compact ? 2 : 4
        #endif
        return Array(repeating: .init(.flexible(), spacing: 10), count: count)
    }
}

#if DEBUG
struct DashboardReasonsView_Previews: PreviewProvider {

    static let service = Service.preview

    static var previews: some View {
        DashboardReasonsView()
            .environmentObject(service)
    }
}
#endif
