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
    
    typealias ConfigurationIntent = NominationWidgetConfigurationIntent
    typealias GetTimelineCompletionHandler = (Timeline<Entry>) -> Void
    
    struct Provider: IntentTimelineProvider {
        func placeholder(in context: Context) -> Entry {
            .init(.init())
        }

        func getSnapshot(
            for configuration: ConfigurationIntent,
            in context: Context,
            completion: @escaping (Entry) -> Void
        ) {
            getEntry(for: configuration, in: context, completion: completion)
        }

        func getTimeline(
            for configuration: ConfigurationIntent,
            in context: Context,
            completion: @escaping (Timeline<Entry>) -> Void
        ) {
            if UserDefaults.General.backgroundRefresh {
                let started = Service.shared.refresh { status, count in
                    if status == .requestMatch {
                        UNUserNotificationCenter.push(
                            NSLocalizedString("notification.refresh.requiresMatch", comment: "Manually Match Required"),
                            NSLocalizedString("notification.refresh.requiresMatch.desc", comment: "Manually Match Required Description")
                        )
                    } else if count > 0 {
                        UNUserNotificationCenter.push(
                            NSLocalizedString("notification.refresh.refreshFinished", comment: "Refresh Finished"),
                            String(format: NSLocalizedString("notification.refresh.refreshFinished.desc", comment: "Refresh Finished Description"), count)
                        )
                    }
                    getEntry(for: configuration, in: context) { entry in
                        completion(.init(entries: [ entry ], policy: .atEnd))
                    }
                }
                if !started {
                    getEntry(for: configuration, in: context) { entry in
                        completion(.init(entries: [ entry ], policy: .atEnd))
                    }
                }
            } else {
                getEntry(for: configuration, in: context) { entry in
                    completion(.init(entries: [ entry ], policy: .atEnd))
                }
            }
        }
        
        private func getEntry(
            for configuration: ConfigurationIntent,
            in context: Context,
            completion: @escaping (Entry) -> Void
        ) {
            let predicate: NSPredicate?
            switch configuration.status {
                case .pending: predicate = Umi.shared.status[.pending]!.predicate
                case .accepted: predicate = Umi.shared.status[.accepted]!.predicate
                case .rejected: predicate = Umi.shared.status[.rejected]!.predicate
                default: predicate = nil
            }
            let now = Date()
            let nominations = Dia.shared.nominations(matches: predicate)
            guard !nominations.isEmpty else {
                completion(.init(now, empty: true))
                return
            }
            let nomination = nominations[Int.random(in: 0 ..< nominations.count)]
            URLSession.shared.dataTask(with: nomination.imageURL) { data in
                completion(.init(now, image: data ?? .init(), nomination: nomination))
            }
        }
    }
    
    struct Entry: TimelineEntry {
        let date: Date
        
        let empty: Bool
        
        let id: String
        let title: String
        let imageData: Data
        let statusIcon: String
        let statusColor: Color
        
        init(
            _ date: Date,
            image: Data,
            nomination: Nomination
        ) {
            self.date = date
            empty = false
            id = nomination.id
            title = nomination.title
            imageData = image
            let status = nomination.statusData
            statusIcon = status.icon
            statusColor = status.color
        }
        
        init(
            _ date: Date,
            empty: Bool = false
        ) {
            self.date = date
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
            if let image = Image(data: entry.imageData) {
                image
                    .resizable()
            }
        }
    }
    
    let kind: String = "widget.nomination"

    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: ConfigurationIntent.self,
            provider: Provider()
        ) { entry in
            EntryView(entry: entry)
        }
        .supportedFamilies([ .systemSmall, .systemMedium ])
        .configurationDisplayName("widget.nomination")
        .description("widget.nomination.desc")
    }
}

#if DEBUG
struct NominationWidget_Previews: PreviewProvider {
    static var previews: some View {
        let nomination = Dia.preview.nominations[0]
        NominationWidget.EntryView(
            entry: .init(
                Date(),
                image: (try? Data(contentsOf: URL(string: nomination.imageURL)!)) ?? Data(),
                nomination: nomination
            )
        )
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
#endif
