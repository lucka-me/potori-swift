//
//  MatchView.swift
//  Potori
//
//  Created by Lucka on 16/1/2021.
//

import SwiftUI

struct MatchView: View {
    
    @EnvironmentObject private var service: Service
    
    var body: some View {
        #if os(macOS)
        content
            .frame(minWidth: 300, minHeight: 350)
        #else
        NavigationView {
            content
        }
        #endif
    }
    
    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading) {
                #if os(macOS)
                Text("view.match")
                    .font(.largeTitle)
                    .padding(.bottom)
                #endif
                ForEach(0 ..< service.matchData.packs.count) { index in
                    MatchPackView(pack: service.matchData.packs[index])
                }
            }
            .padding()
        }
        .navigationTitle("view.match")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("view.match.confirm") {
                    service.matchData.callback()
                }
            }
        }
    }
    
    private func dateString(_ from: UInt64) -> String {
        DateFormatter.localizedString(from: .init(timeIntervalSince1970: .init(from)), dateStyle: .medium, timeStyle: .none)
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
        CardView.Card {
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
    }
    
    @ViewBuilder
    private func candidateView(_ candidate: NominationRAW) -> some View {
        VStack(alignment: .leading) {
            AsyncImage(url: NominationRAW.generateImageURL(candidate.image))
                .scaledToFill()
                .frame(width: 150, height: 150, alignment: .center)
                .mask {
                    RoundedRectangle(cornerRadius: CardView.defaultRadius, style: .continuous)
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
