//
//  DetailsSceneView.swift
//  macOS
//
//  Created by Lucka on 31/10/2021.
//

import SwiftUI

struct DetailsSceneView: View {
    
    @EnvironmentObject private var dia: Dia
    @ObservedObject private var alert = AlertInspector()
    @State private var loading = true
    @State private var nomination: Nomination? = nil
    
    var body: some View {
        Group {
            if let solidNomination = nomination {
                NominationDetails(nomination: solidNomination)
                    .environmentObject(alert)
            } else if loading {
                ProgressView()
            } else {
                Text("view.details.notFound")
            }
        }
        .frame(minWidth: 450, minHeight: 500)
        .onOpenURL { url in
            loading = true
            defer {
                loading = false
            }
            guard
                url.scheme == "potori",
                let host = url.host,
                host == "details"
            else {
                return
            }
            let id = url.lastPathComponent
            nomination = dia.firstNomination(matches: .init(format: "id == %@", id))
        }
    }
}

#if DEBUG
struct DetailsSceneView_Previews: PreviewProvider {
    static var previews: some View {
        DetailsSceneView()
    }
}
#endif
