//
//  DashboardScannersView.swift
//  Potori
//
//  Created by Lucka on 24/1/2021.
//

import SwiftUI

struct DashboardScannersView: View {
    
    @EnvironmentObject private var dia: Dia
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("view.dashboard.scanners")
                .font(.title2)
                .bold()
            
            LazyVGrid(columns: DashboardView.columns, alignment: .leading) {
                ForEach(0 ..< Umi.shared.scannerAll.count) { index in
                    let scanner = Umi.shared.scannerAll[index]
                    let predicate = scanner.predicate
                    let count = dia.countNominations(matches: predicate)
                    if count > 0 {
                        ListLink(.init(scanner.title, predicate: predicate)) {
                            DashboardCard(
                                count, scanner.title,
                                systemImage: "apps.iphone", color: .purple
                            )
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
struct DashboardScannersView_Previews: PreviewProvider {
    
    static var previews: some View {
        DashboardScannersView()
            .environmentObject(Dia.preview)
    }
}
#endif
