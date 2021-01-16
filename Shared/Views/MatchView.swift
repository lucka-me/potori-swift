//
//  MatchView.swift
//  Potori
//
//  Created by Lucka on 16/1/2021.
//

import SwiftUI

struct MatchView: View {
    
    var pack: MatchManager.Pack
    @EnvironmentObject private var service: Service
    @State var selection: Int? = 0
    @State var confirmed = false
    
    var body: some View {
        #if os(macOS)
        VStack {
            Text("view.match")
                .font(.largeTitle)
            list.listStyle(PlainListStyle())
        }
        .padding()
        .frame(minWidth: 300, minHeight: 350)
        #else
        NavigationView {
            list.listStyle(InsetGroupedListStyle())
        }
        #endif
    }
    
    @ViewBuilder
    private var list: some View {
        List(selection: $selection) {
            Section(header: Text("view.match.target")) {
                #if os(macOS)
                MatchItem(nomination: pack.target)
                #else
                MatchItem(nomination: pack.target, selected: nil)
                #endif
            }
            
            Section(header: Text("view.match.candidates"), footer: Text("view.match.candidates.desc")) {
                ForEach(0 ..< pack.candidates.count) { index in
                    #if os(macOS)
                    MatchItem(nomination: pack.candidates[index])
                        .tag(index)
                    #else
                    MatchItem(nomination: pack.candidates[index], selected: selection == index)
                        .onTapGesture {
                            self.selection = index
                        }
                    #endif
                }
            }
        }
        .navigationTitle("view.match")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("view.match.confirm") {
                    service.match.match(pack, selection)
                    self.confirmed = true
                }
                .disabled(selection == nil)
            }
        }
    }
}

#if DEBUG
struct MatchView_Previews: PreviewProvider {
    static var previews: some View {
        MatchView(pack: MatchManager.preview)
            .environmentObject(Service.preview)
    }
}
#endif

fileprivate struct MatchItem: View {
    let nomination: NominationRAW
    
    #if os(iOS)
    let selected: Bool?
    #endif
    
    var body: some View {
        HStack {
            RemoteImage(NominationRAW.generateImageURL(nomination.image))
                .scaledToFill()
                .frame(width: 80, height: 80)
                .cornerRadius(5)
            VStack(alignment: .leading) {
                Text(nomination.title)
                    .font(.title2)
                    .lineLimit(1)
                let status = Umi.shared.status[nomination.status]!
                let intervalMS = nomination.status == .pending ? nomination.confirmedTime : nomination.resultTime
                let date = Date(timeIntervalSince1970: TimeInterval(intervalMS / 1000))
                let dateString = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
                Text(status.title)
                    .foregroundColor(status.color)
                    .font(.subheadline)
                Text(dateString)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }.frame(height: 80, alignment: .top)
            #if os(iOS)
            if let solidSelected = selected {
                Spacer()
                if solidSelected {
                    Image(systemName: "checkmark.square.fill")
                        .font(.title)
                        .foregroundColor(.accentColor)
                } else {
                    Image(systemName: "square")
                        .font(.title)
                }
            }
            #endif
        }
    }
}
