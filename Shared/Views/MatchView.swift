//
//  MatchView.swift
//  Potori
//
//  Created by Lucka on 16/1/2021.
//

import SwiftUI

struct MatchView: View {
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var service: Service
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(service.matchData.packs) { pack in
                    MatchPackView(pack: pack)
                }
            }
        }
        .navigationTitle("view.match")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("view.match.confirm") {
                    service.matchData.callback()
                    dismiss()
                }
            }
        }
    }
}

#if DEBUG
struct MatchView_Previews: PreviewProvider {
    static var previews: some View {
        MatchView()
            .environmentObject(Service.preview)
    }
}
#endif

fileprivate struct MatchPackView: View {
    
    @ObservedObject var pack: Service.MatchPack
    
    var body: some View {
        let scanner = Umi.shared.scanner[pack.target.scanner]!
        let status = Umi.shared.status[pack.target.status]!
        VStack {
            Text(pack.target.title)
                .font(.title2)
            HStack {
                Label(scanner.title, systemImage: "apps.iphone")
                    .foregroundColor(.purple)
                Label(dateString(pack.target.resultTime), systemImage: status.icon)
                    .foregroundColor(status.color)
            }
            .padding(.top, 2)
            Divider()
            LazyVGrid(columns: [ .init(.adaptive(minimum: 150, maximum: 150), spacing: 8) ], alignment: .leading) {
                ForEach(pack.candidates, id: \.id) { candidate in
                    candidateView(candidate)
                        .onTapGesture {
                            pack.selected = candidate.id
                        }
                }
            }
        }
        .card()
    }
    
    @ViewBuilder
    private func candidateView(_ candidate: NominationRAW) -> some View {
        VStack(alignment: .leading) {
            AsyncImage(url: NominationRAW.generateImageURL(candidate.image))
                .scaledToFill()
                .frame(width: 150, height: 150, alignment: .center)
                .mask {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                }
            HStack {
                Label(dateString(candidate.confirmedTime), systemImage: "arrow.up.circle")
                Spacer()
                Image(systemName: pack.selected == candidate.id ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(.accentColor)
            }
            .lineLimit(1)
            .padding(.top, 2)
        }
    }
    
    private func dateString(_ from: UInt64) -> String {
        DateFormatter.localizedString(from: .init(timeIntervalSince1970: .init(from)), dateStyle: .medium, timeStyle: .none)
    }
}
