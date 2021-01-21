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
    
    @State private var showMore = false
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("view.dashboard.reasons")
                .font(.title2)
                .bold()
            Spacer()
            Button(showMore ? "Less" : "More") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showMore.toggle()
                }
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.top, 3)
        
        LazyVGrid(columns: columns, alignment: .leading) {
            ForEach(0 ..< Umi.shared.reasonAll.count) { index in
                let reason = Umi.shared.reasonAll[index]
                if index < 4 || showMore {
                    let predicate = reason.predicate
                    let count = service.count(predicate)
                    if count > 0 {
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
