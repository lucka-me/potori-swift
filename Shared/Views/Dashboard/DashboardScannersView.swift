//
//  DashboardScannersView.swift
//  Potori
//
//  Created by Lucka on 24/1/2021.
//

import SwiftUI

struct DashboardScannersView: View {
    
    #if os(macOS)
    @EnvironmentObject var navigation: Navigation
    #endif
    
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
                    let count = dia.countNominations(predicate)
                    if count > 0 {
                        OpenNominationListLink(.init(scanner.title, predicate)) {
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
    
    static let navigation: Navigation = .init()
    
    static var previews: some View {
        DashboardScannersView()
            .environmentObject(Dia.preview)
            .environmentObject(navigation)
    }
}
#endif
