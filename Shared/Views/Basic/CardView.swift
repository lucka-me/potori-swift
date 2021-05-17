//
//  CardView.swift
//  Potori
//
//  Created by Lucka on 6/5/2021.
//

import SwiftUI

class CardView {
    
    struct Card<Content: View>: View {
        
        private let radius: CGFloat
        private let content: () -> Content
        
        init(radius: CGFloat = CardView.defaultRadius, @ViewBuilder _ content: @escaping () -> Content) {
            self.radius = radius
            self.content = content
        }
        
        var body: some View {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
                VStack(alignment: .leading, content: content)
                    .padding(radius)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    class List {
        
        static var buttonStyle: some PrimitiveButtonStyle {
            #if os(macOS)
            return PlainButtonStyle()
            #else
            return BorderlessButtonStyle()
            #endif
        }
        
        @ViewBuilder
        static func header(_ text: Text) -> some View {
            text
                .font(.headline)
        }
        
        @ViewBuilder
        static func header<Trailing: View>(_ text: Text, _ trailing: Trailing) -> some View {
            HStack {
                text
                Spacer()
                trailing
            }
            .font(.headline)
        }
        
        @ViewBuilder
        static func row<Leading: View>(_ leading: Leading) -> some View {
            row {
                HStack {
                    leading
                }
            }
        }
        
        @ViewBuilder
        static func row<Leading: View, Trailing: View>(_ leading: Leading, _ trailing: Trailing) -> some View {
            row {
                HStack {
                    leading
                    Spacer()
                    trailing
                }
            }
        }
        
        @ViewBuilder
        static func row<Label: View>(
            _ action: @escaping () -> Void,
            @ViewBuilder label: () -> Label
        ) -> some View {
            row {
                Button(action: action, label: label)
                    .buttonStyle(buttonStyle)
                    .foregroundColor(.accentColor)
                    .contentShape(Rectangle())
            }
        }
        
        @ViewBuilder
        static func row<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
            Divider()
            content()
                .labelStyle(FixedWidthIconLabelStyle())
                .lineLimit(1)
        }
    }
    
    static let defaultRadius: CGFloat = 12
}

#if DEBUG
struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CardView.Card {
                CardView.List.header(Text("Header"))
                CardView.List.row(Label("Pencil", systemImage: "pencil.circle"))
                CardView.List.row(Label("Pin", systemImage: "mappin"))
                CardView.List.row(Label("People", systemImage: "figure.stand"))
            }
            
            CardView.Card {
                CardView.List.header(Text("Header"))
                CardView.List.row { } label: {
                    Label("Pencil", systemImage: "pencil.circle")
                    Spacer()
                }
                CardView.List.row { } label: {
                    Label("Pin", systemImage: "mappin")
                    Spacer()
                    Image(systemName: "checkmark")
                }
                CardView.List.row { } label: {
                    Label("People", systemImage: "figure.stand")
                    Spacer()
                }
            }
            
            CardView.Card {
                HStack {
                    Label("Pencil", systemImage: "pencil.circle")
                        .labelStyle(FixedWidthIconLabelStyle())
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                Text("\(2000)")
                    .font(.system(.largeTitle, design: .rounded))
                    .padding(.top, 3)
            }
        }
    }
}
#endif
