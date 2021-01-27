//
//  NominationWidget.swift
//  Widget Extension iOS
//
//  Created by Lucka on 27/1/2021.
//

import WidgetKit
import SwiftUI
import Intents

struct NominationProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> NominationEntry {
        NominationEntry(Date(), .init())
    }

    func getSnapshot(
        for configuration: ConfigurationIntent,
        in context: Context,
        completion: @escaping (NominationEntry) -> ()
    ) {
        let entry = NominationEntry(Date(), .init())
        completion(entry)
    }

    func getTimeline(
        for configuration: ConfigurationIntent,
        in context: Context,
        completion: @escaping (Timeline<Entry>) -> ()
    ) {
        var entries: [NominationEntry] = []
        let currentDate = Date()
        let nominations = NominationWidgetJSON.load()
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

struct NominationEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    
    let empty: Bool
    
    let title: String
    let imageData: Data
    let statusIcon: String
    let statusColor: Color
    
    init(_ date: Date, _ configuration: ConfigurationIntent, _ nomination: NominationWidgetJSON) {
        self.date = date
        self.configuration = configuration
        
        empty = false

        title = nomination.title
        if let url = URL(string: NominationRAW.generateImageURL(nomination.image)) {
            imageData = (try? Data(contentsOf: url)) ?? Data()
        } else {
            imageData = Data()
        }
        let status = Umi.shared.status[Umi.Status.Code(rawValue: nomination.status) ?? .pending]!
        statusIcon = status.icon
        statusColor = status.color
    }
    
    init(_ date: Date, _ configuration: ConfigurationIntent, empty: Bool = false) {
        self.date = date
        self.configuration = configuration
        
        self.empty = empty
        
        title = "Nomination"
        imageData = Data()
        statusIcon = "checkmark.circle"
        statusColor = .green
    }
}

struct NominationWidgetEntryView : View {
    
    let entry: NominationProvider.Entry
    
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
                    .foregroundColor(entry.statusColor)
                    .shadow(color: .black, radius: 1)
                Spacer()
            }
                .padding(8)
                .background(ContainerRelativeShape().fill(Color.black.opacity(0.2)))
                .padding(8)
        }
        .background(image.scaledToFill())
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

struct NominationWidget: Widget {
    let kind: String = "NominationWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind, intent: ConfigurationIntent.self, provider: NominationProvider()
        ) { entry in
            NominationWidgetEntryView(entry: entry)
        }
        .supportedFamilies([ .systemSmall, .systemMedium ])
        .configurationDisplayName("widget.nomination")
        .description("widget.nomination.desc")
    }
}

#if DEBUG
struct NominationWidget_Previews: PreviewProvider {
    static var previews: some View {
        NominationWidgetEntryView(
            entry: NominationEntry(Date(), .init(), previewNomination)
        )
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
    
    static let previewNomination = NominationWidgetJSON(
        id: "69ue0nwnpg", title: "De Wilde Wei",
        image: "16Nd33lsfrmKA2n4SwXSAkRm2SMyMlGaCXQHT7Y33R1rUn799TLhRBj0cS9SFIv1C6OxHt",
        status: Umi.Status.Code.rejected.rawValue
    )
}
#endif
