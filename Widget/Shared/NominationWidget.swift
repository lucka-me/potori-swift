//
//  NominationWidget.swift
//  Widget Extension iOS
//
//  Created by Lucka on 27/1/2021.
//

import WidgetKit
import SwiftUI
import Intents

struct NominationWidget: Widget {
    
    struct Provider: IntentTimelineProvider {
        func placeholder(in context: Context) -> NominationWidget.Entry {
            .init(Date(), .init())
        }

        func getSnapshot(
            for configuration: NominationWidgetConfigurationIntent,
            in context: Context,
            completion: @escaping (NominationWidget.Entry) -> ()
        ) {
            let entry = NominationWidget.Entry(Date(), .init())
            completion(entry)
        }

        func getTimeline(
            for configuration: NominationWidgetConfigurationIntent,
            in context: Context,
            completion: @escaping (Timeline<Entry>) -> ()
        ) {
            var entries: [NominationWidget.Entry] = []
            let currentDate = Date()
            let predicate: NSPredicate?
            switch configuration.status {
                case .unknown: predicate = nil
                case .pending: predicate = Umi.shared.status[.pending]!.predicate
                case .accepted: predicate = Umi.shared.status[.accepted]!.predicate
                case .rejected: predicate = Umi.shared.status[.rejected]!.predicate
            }
            let nominations = Dia.shared.nominations(matches: predicate)
            if nominations.isEmpty {
                entries.append(.init(currentDate, configuration, empty: true))
            } else {
                for index in 0 ..< 10 {
                    guard let entryDate = Calendar.current.date(
                        byAdding: .minute, value: index * 30, to: currentDate
                    ) else {
                        continue
                    }
                    entries.append(.init(entryDate, configuration, nominations[Int.random(in: 0 ..< nominations.count)]))
                }
            }
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }
    
    struct Entry: TimelineEntry {
        let date: Date
        let configuration: NominationWidgetConfigurationIntent
        
        let empty: Bool
        
        let id: String
        let title: String
        let imageData: Data
        let statusIcon: String
        let statusColor: Color
        
        init(
            _ date: Date,
            _ configuration: NominationWidgetConfigurationIntent,
            _ nomination: Nomination
        ) {
            self.date = date
            self.configuration = configuration
            empty = false
            id = nomination.id
            title = nomination.title
            if let url = URL(string: nomination.imageURL) {
                imageData = (try? Data(contentsOf: url)) ?? Data()
            } else {
                imageData = Data()
            }
            let status = nomination.statusData
            statusIcon = status.icon
            statusColor = status.color
        }
        
        init(
            _ date: Date,
            _ configuration: NominationWidgetConfigurationIntent,
            empty: Bool = false
        ) {
            self.date = date
            self.configuration = configuration
            
            self.empty = empty
            
            id = ""
            title = "Nomination"
            imageData = Data()
            statusIcon = "checkmark.circle"
            statusColor = .green
        }
    }
    
    struct EntryView : View {
        
        let entry: Provider.Entry
        
        var body: some View {
            if entry.empty {
                Text("widget.nomination.empty")
            } else {
                content
            }
        }
        
        @ViewBuilder
        private var content: some View {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer()
                }
                Spacer()
                HStack(spacing: 0) {
                    Label(entry.title, systemImage: entry.statusIcon)
                        .lineLimit(1)
                    Spacer()
                }
                    .padding(8)
                    .background(ContainerRelativeShape().fill(entry.statusColor.opacity(0.5)))
                    .padding(8)
            }
            .background(image.scaledToFill())
            .widgetURL(URL(string: "potori://nomination/\(entry.id)"))
        }
        
        @ViewBuilder
        private var image: some View {
            #if os(macOS)
            if let nsImage = NSImage(data: entry.imageData) {
                Image(nsImage: nsImage)
                    .resizable()
            }
            #else
            if let uiImage = UIImage(data: entry.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
            }
            #endif
        }
    }
    
    let kind: String = "widget.nomination"

    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: NominationWidgetConfigurationIntent.self,
            provider: NominationWidget.Provider()
        ) { entry in
            NominationWidget.EntryView(entry: entry)
        }
        .supportedFamilies([ .systemSmall, .systemMedium ])
        .configurationDisplayName("widget.nomination")
        .description("widget.nomination.desc")
    }
}

#if DEBUG
struct NominationWidget_Previews: PreviewProvider {
    static var previews: some View {
        NominationWidget.EntryView(
            entry: .init(Date(), .init(), Dia.preview.nominations[0])
        )
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
#endif
