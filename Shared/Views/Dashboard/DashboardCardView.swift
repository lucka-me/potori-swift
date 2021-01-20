//
//  DashboardCardView.swift
//  Potori
//
//  Created by Lucka on 20/1/2021.
//

import SwiftUI

struct DashboardCardView<Label: View, Destination: View>: View {
    
    var text: Text
    private var label: Label
    private var destination: Destination?
    
    init(_ text: Text, @ViewBuilder label: @escaping () -> Label) where Destination == EmptyView {
        self.text = text
        self.destination = nil
        self.label = label()
    }
    
    init(_ text: Text, destination: Destination, @ViewBuilder label: @escaping () -> Label) {
        self.text = text
        self.destination = destination
        self.label = label()
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            
            if let solidDestination = destination {
                NavigationLink(destination: solidDestination) {
                    background
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                background
            }

            VStack(alignment: .leading) {
                HStack {
                    label
                    if destination != nil {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                text
                    .font(.system(.largeTitle, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.top, 3)
            }
            .foregroundColor(.black)
            .padding(10)
        }
    }
    
    @ViewBuilder
    private var background: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.gray.opacity(0.3))
    }
}

#if DEBUG
struct DashboardCardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardCardView(Text("Number")) {
            Label("Label", systemImage: "info.circle.fill")
                .foregroundColor(.accentColor)
        }
    }
}
#endif
