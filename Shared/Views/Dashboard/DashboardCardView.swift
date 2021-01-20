//
//  DashboardCardView.swift
//  Potori
//
//  Created by Lucka on 20/1/2021.
//

import SwiftUI

struct DashboardCardView<Label: View>: View {
    
    var text: Text
    private var label: Label
    
    init(_ text: Text, @ViewBuilder label: @escaping () -> Label) {
        self.text = text
        self.label = label()
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.gray.opacity(0.3))

            VStack(alignment: .leading) {
                HStack {
                    label
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                text
                    .font(.system(.largeTitle, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.top, 3)
            }
            .foregroundColor(.black)
            .padding()
        }
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
