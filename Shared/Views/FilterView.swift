//
//  FilterView.swift
//  Potori
//
//  Created by Lucka on 17/1/2021.
//

import SwiftUI

struct FilterView: View {
    
    @EnvironmentObject private var manager: FilterManager
    
    var body: some View {
        Section(header: Text("view.filter.status")) {
            ForEach(Umi.shared.statusAll, id: \.code) { status in
                let index = manager.status.index(forKey: status.code)!
                Toggle(status.title, isOn: $manager.status.values[index].isOn)
            }
        }
    }
}

#if DEBUG
struct FilterView_Previews: PreviewProvider {
    
    static let manager = FilterManager()

    static var previews: some View {
        FilterView()
            .environmentObject(manager)
    }
}
#endif
