//
//  HighlightsWidget.swift
//  Potori
//
//  Created by Lucka on 25/5/2021.
//

import WidgetKit
import SwiftUI

struct HighlightsWidget: Widget {
    
    struct Provider: TimelineProvider {
        func placeholder(in context: Context) -> Entry {
            .init()
        }

        func getSnapshot(
            in context: Context,
            completion: @escaping (Entry) -> Void
        ) {
            completion(.init())
        }

        func getTimeline(
            in context: Context,
            completion: @escaping (Timeline<Entry>) -> Void
        ) {
            Service.shared.backgroundRefresh {
                completion(.init(entries: [ .init() ], policy: .atEnd))
            }
        }
    }
    
    struct Entry: TimelineEntry {
        let date = Date()
    }
    
    struct EntryView : View {
        
        #if os(macOS)
        private static let countFont = Font.system(.largeTitle, design: .rounded)
        #else
        private static let countFont = Font.system(.title, design: .rounded)
        #endif
        
        let entry: Provider.Entry
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    card(
                        count: Dia.shared.countNominations(),
                        color: .accentColor, icon: "arrow.up.circle"
                    )
                    card(status: Umi.shared.status[.pending]!)
                }
                HStack(spacing: 8) {
                    card(status: Umi.shared.status[.accepted]!)
                    card(status: Umi.shared.status[.rejected]!)
                }
            }
            .padding(8)
        }
        
        @ViewBuilder
        private func card(count: Int, color: Color, icon: String) -> some View {
            ZStack(alignment: .topLeading) {
                ContainerRelativeShape()
                    .fill(gradient(of: color))
                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        Image(systemName: icon)
                        Spacer()
                        Text("\(count)")
                            .font(Self.countFont)
                    }
                }
                .padding(12)
            }
        }
        
        @ViewBuilder
        private func card(status: Umi.Status) -> some View {
            card(
                count: Dia.shared.countNominations(matches: status.predicate),
                color: status.color, icon: status.icon
            )
        }
        
        private func gradient(of color: Color) -> LinearGradient {
            .init(
                gradient: .init(colors: [ color, color.opacity(0.8) ]),
                startPoint: .top, endPoint: .bottom
            )
        }
    }
    
    private static let kind: String = "widget.highlights"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: Provider()) { entry in
            EntryView(entry: entry)
        }
        .supportedFamilies([ .systemMedium ])
        .configurationDisplayName("widget.highlights")
        .description("widget.highlights.desc")
    }
}

#if DEBUG
struct HighlightsWidget_Previews: PreviewProvider {
    static var previews: some View {
        HighlightsWidget.EntryView(entry: .init())
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
#endif
