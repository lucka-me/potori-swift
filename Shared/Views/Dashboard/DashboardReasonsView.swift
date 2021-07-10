//
//  DashboardReasonsView.swift
//  Potori
//
//  Created by Lucka on 20/1/2021.
//

import SwiftUI

struct DashboardReasonsView: View {
    
    @EnvironmentObject private var dia: Dia
    
    @State private var showMore = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("view.dashboard.reasons")
                    .font(.title2)
                    .bold()
                if hasMore {
                    Spacer()
                    Button(showMore ? "view.dashboard.reasons.less" : "view.dashboard.reasons.more") {
                        showMore.toggle()
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            
            LazyVGrid(columns: DashboardView.columns, alignment: .leading) {
                ForEach(reasons) { reason in
                    let predicate = reason.predicate
                    ListLink(.init(reason.title, predicate: predicate)) {
                        DashboardCard(
                            dia.countNominations(matches: predicate), reason.title,
                            systemImage: reason.icon, color: .red
                        )
                    }
                }
            }
            .animation(.easeInOut, value: showMore)
        }
        .padding(.top, 3)
        .padding(.horizontal)
    }
    
    private var hasMore: Bool {
        let predicate = Umi.shared.reason[Umi.Reason.undeclared]!.predicate
        let undeclaredCount = dia.countNominations(matches: predicate) > 0 ? 1 : 0
        return dia.countReasons(matches: Umi.Reason.hasNominationsPredicate) + undeclaredCount > 4
    }
    
    private var reasons: [ Umi.Reason ] {
        var list: [ Umi.Reason ] = []
        for reason in Umi.shared.reasonAll {
            let predicate = reason.predicate
            if dia.countNominations(matches: predicate) > 0 {
                list.append(reason)
            }
            if !showMore && list.count == 4 {
                break
            }
        }
        return list
    }
}

#if DEBUG
struct DashboardReasonsView_Previews: PreviewProvider {

    static var previews: some View {
        DashboardReasonsView()
            .environmentObject(Dia.preview)
    }
}
#endif
