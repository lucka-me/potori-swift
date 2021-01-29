//
//  DashboardReasonsView.swift
//  Potori
//
//  Created by Lucka on 20/1/2021.
//

import SwiftUI

struct DashboardReasonsView: View {
    
    #if os(macOS)
    @EnvironmentObject var navigation: Navigation
    #endif
    
    @EnvironmentObject private var dia: Dia
    
    @State private var showMore = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("view.dashboard.reasons")
                    .font(.title2)
                    .bold()
                let undeclaredCount = dia.countNominations(Umi.shared.reason[Umi.Reason.undeclared]!.predicate) > 0 ? 1 : 0
                if dia.countReasons(Umi.Reason.hasNominationsPredicate) + undeclaredCount > 4 {
                    Spacer()
                    Button(showMore ? "view.dashboard.reasons.less" : "view.dashboard.reasons.more") {
                        showMore.toggle()
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            
            LazyVGrid(columns: DashboardView.columns, alignment: .leading) {
                ForEach(0 ..< Umi.shared.reasonAll.count) { index in
                    let reason = Umi.shared.reasonAll[index]
                    if index < 4 || showMore {
                        let predicate = reason.predicate
                        let count = dia.countNominations(predicate)
                        if count > 0 {
                            OpenNominationListLink(.init(reason.title, predicate)) {
                                DashboardCardView(Text("\(count)")) {
                                    Label(reason.title, systemImage: reason.icon)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.top, 3)
        .padding(.horizontal)
    }
}

#if DEBUG
struct DashboardReasonsView_Previews: PreviewProvider {
    
    static let navigation: Navigation = .init()

    static var previews: some View {
        DashboardReasonsView()
            .environmentObject(Dia.preview)
            .environmentObject(navigation)
    }
}
#endif
